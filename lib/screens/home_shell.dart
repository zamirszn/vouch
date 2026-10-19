/// The signed-in shell — three posters: Today, History and You.
///
/// Each tab is a full-bleed colour field with an oversized promise headline,
/// a printed dial, flat cards and one black pill. Witnesses get the butter
/// edition, owners the blush one.
library;

import 'dart:async';

import 'package:expressive_m3/expressive_m3.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/date_utils.dart';
import '../models/day_entry.dart';
import '../models/track.dart';
import '../services/notification_service.dart';
import '../state/track_controller.dart';
import '../theme/vouch_theme.dart';
import '../widgets/celebration.dart';
import '../widgets/contact_sheet.dart';
import '../widgets/day_detail_sheet.dart';
import '../widgets/mark_sheet.dart';
import '../widgets/note_editor_sheet.dart';
import '../widgets/notification_permission_card.dart';
import '../widgets/poster.dart';
import '../widgets/pressable_spring.dart';
import '../widgets/promise_orb.dart';
import '../widgets/soul.dart';
import '../widgets/vouch_avatar.dart';
import '../widgets/vouch_dock.dart';
import '../widgets/vouch_loader.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  StreamSubscription<String>? _taps;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _taps = context.read<NotificationService>().taps.listen((payload) {
      if (!mounted) return;
      _select(0);
    });
  }

  @override
  void dispose() {
    _taps?.cancel();
    super.dispose();
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrackController>();
    final isPartner = controller.isPartner;
    final tone = switch (_index) {
      0 => isPartner ? PosterTone.butter : PosterTone.blush,
      1 => PosterTone.sage,
      _ => PosterTone.clay,
    };

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: PosterField(
        tone: tone,
        bottom: false,
        child: TabSwitchTransition(
          index: _index,
          child: IndexedStack(
            index: _index,
            children: <Widget>[
              isPartner ? const _PartnerHome() : const _OwnerHome(),
              const HistoryScreen(),
              const SettingsScreen(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: VouchDock(
        index: _index,
        onSelected: _select,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

class _PosterScroll extends StatelessWidget {
  const _PosterScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TopFade(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          114 + MediaQuery.paddingOf(context).bottom,
        ),
        child: child,
      ),
    );
  }
}

/// The promise, set as the poster's statement. The last word takes the
/// field's accent colour.
class _PromiseHead extends StatelessWidget {
  const _PromiseHead({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    final schedule = track.schedule;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            PosterLabel('the promise', color: style.ink),
            const Spacer(),
            PosterLabel(
              schedule == null
                  ? 'no clock'
                  : '${schedule.kind.shortLabel.toUpperCase()} / ${schedule.clockLabel.toUpperCase()}',
              size: 8.5,
              tracking: 1.1,
            ),
          ],
        ),
        const SizedBox(height: 13),
        PosterHeadline(
          track.promise,
          size: 46,
          accentTail: 1,
          maxLines: 4,
        ),
        if (track.promiseNote?.trim().isNotEmpty ?? false) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            '“${track.promiseNote!.trim()}”',
            style: TextStyle(
              fontFamily: 'InstrumentSans',
              fontSize: 14,
              height: 1.4,
              color: style.muted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Two metadata columns under the headline, as on the posters.
class _MetaPair extends StatelessWidget {
  const _MetaPair({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);

    Widget cell(String label, String value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            PosterLabel(label, color: style.muted, size: 8.5, tracking: 1.2),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'InstrumentSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
                letterSpacing: -0.1,
                color: style.ink,
                fontVariations: const <FontVariation>[
                  FontVariation('wght', 600),
                ],
              ),
            ),
          ],
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: cell(leftLabel, leftValue)),
        const SizedBox(width: 16),
        Expanded(child: cell(rightLabel, rightValue)),
      ],
    );
  }
}

Color _stateColor(VouchDayState state) => switch (state) {
      VouchDayState.completed => PosterColors.kelly,
      VouchDayState.missed => PosterColors.coral,
      VouchDayState.pending => PosterColors.cobalt,
      VouchDayState.rest => VouchColors.mist,
      VouchDayState.upcoming => VouchColors.mist,
    };

String _stateCode(VouchDayState state) => switch (state) {
      VouchDayState.completed => 'kept',
      VouchDayState.missed => 'missed',
      VouchDayState.pending => 'open',
      VouchDayState.rest => 'rest',
      VouchDayState.upcoming => 'next',
    };

/// Three solid-colour shortcuts — the flat email cards from the posters,
/// reduced to call, WhatsApp and SMS.
class _ReachStrip extends StatelessWidget {
  const _ReachStrip({
    required this.name,
    required this.phone,
    required this.message,
  });

  final String name;
  final String? phone;
  final String message;

  @override
  Widget build(BuildContext context) {
    final enabled = (phone?.trim().isNotEmpty ?? false);

    Widget tile(IconData icon, String label, Color color) => Expanded(
          child: Opacity(
            opacity: enabled ? 1 : 0.38,
            child: PressableSpring(
              onTap: enabled
                  ? () => showContactSheet(
                        context,
                        name: name,
                        phone: phone,
                        message: message,
                      )
                  : null,
              enabled: enabled,
              pressedScale: 0.96,
              child: Container(
                height: 62,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(icon, size: 18, color: PosterColors.cream),
                    const SizedBox(height: 5),
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 7.5,
                        letterSpacing: 1.1,
                        color: PosterColors.cream,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    return Row(
      children: <Widget>[
        tile(Icons.call_rounded, 'call', PosterColors.cobalt),
        const SizedBox(width: 8),
        tile(Icons.chat_bubble_rounded, 'whatsapp', PosterColors.kelly),
        const SizedBox(width: 8),
        tile(Icons.sms_rounded, 'sms', PosterColors.coral),
      ],
    );
  }
}

/// Seven measured days — each one a tick on the card.
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.controller});

  final TrackController controller;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    final dates = <DateTime>[
      for (var offset = 6; offset >= 0; offset--)
        dateAt(controller.today, -offset),
    ];

    return PosterCard(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (final date in dates)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => showDayDetailSheet(
                  context,
                  date: date,
                  entry: controller.days[dayKey(date)],
                  state: controller.dayState(date),
                  today: controller.today,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: <Widget>[
                      Text(
                        shortWeekday(date).substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 8,
                          letterSpacing: 0.5,
                          color: style.cardMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: dayKey(date) == controller.todayKey ? 5 : 4,
                        height: 30,
                        decoration: BoxDecoration(
                          color: dayKey(date) == controller.todayKey
                              ? style.accent == PosterColors.cream
                                  ? PosterColors.cobalt
                                  : style.accent
                              : controller.dayState(date) ==
                                      VouchDayState.pending
                                  ? style.cardInk.withValues(alpha: 0.2)
                                  : _stateColor(controller.dayState(date)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontFamily: 'InstrumentSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: dayKey(date) == controller.todayKey
                              ? style.cardInk
                              : style.cardMuted,
                          fontVariations: const <FontVariation>[
                            FontVariation('wght', 600),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsCards extends StatelessWidget {
  const _StatsCards({required this.controller});

  final TrackController controller;

  @override
  Widget build(BuildContext context) {
    final stats = controller.stats;

    return Row(
      children: <Widget>[
        Expanded(
          child: PosterStatCard(
            value: '${stats.bestStreak}',
            label: 'best streak',
            color: PosterColors.acid,
            foreground: PosterColors.ink,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PosterStatCard(
            value: '${stats.completed}',
            label: 'days kept',
            color: PosterColors.kelly,
            foreground: PosterColors.cream,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PosterStatCard(
            value: stats.elapsed == 0 ? '—' : '${stats.completionPercent}%',
            label: 'kept rate',
          ),
        ),
      ],
    );
  }
}

class _ReminderLine extends StatelessWidget {
  const _ReminderLine({required this.controller});

  final TrackController controller;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    final schedule = controller.track?.schedule;
    final next = controller.nextReminder;
    final remaining = controller.timeToNextReminder;

    final label = schedule == null
        ? 'No reminder set'
        : next == null
            ? 'No upcoming reminder'
            : 'Next buzz · ${DateFormat('EEE d MMM · h:mm a').format(next)}';

    return Row(
      children: <Widget>[
        Container(width: 7, height: 7, color: style.accent),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'InstrumentSans',
              fontSize: 12,
              height: 1.3,
              color: style.muted,
            ),
          ),
        ),
        if (remaining != null)
          PosterLabel(countdownLabel(remaining), color: style.ink, size: 8.5),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Owner home
// ---------------------------------------------------------------------------

class _OwnerHome extends StatefulWidget {
  const _OwnerHome();

  @override
  State<_OwnerHome> createState() => _OwnerHomeState();
}

class _OwnerHomeState extends State<_OwnerHome> {
  DayStatus? _lastStatus;
  bool _primed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<TrackController>();
    final status = controller.todayEntry?.status;
    if (!_primed) {
      _primed = true;
      _lastStatus = status;
      return;
    }
    if (_lastStatus != DayStatus.completed && status == DayStatus.completed) {
      final name = controller.track?.partnerFirstName ?? 'Your partner';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showCelebration(
          context,
          title: 'Kept.',
          message: '$name confirmed today’s promise. The streak lives.',
        );
      });
    }
    _lastStatus = status;
  }

  Future<void> _editNote(TrackController controller, Track track) async {
    await showNoteEditorSheet(
      context,
      promise: track.promise,
      initialNote: controller.todayEntry?.note,
      onSave: controller.saveNote,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrackController>();
    final track = controller.track;
    if (track == null) {
      return const Center(child: VouchLoader());
    }
    final style = PosterStyle.of(context);
    final state = controller.dayState(controller.today);
    final entry = controller.todayEntry;
    final stats = controller.stats;
    final partner = track.partnerName ?? 'Your partner';
    final partnerFirst = track.partnerFirstName;
    final phone = track.partnerPhone;
    final schedule = track.schedule;
    final note = entry?.note?.trim();
    final hasNote = note?.isNotEmpty ?? false;

    final caption = switch (state) {
      VouchDayState.completed => 'Kept today',
      VouchDayState.missed => 'Missed today',
      VouchDayState.pending => 'Today is open',
      VouchDayState.rest => 'Rest day',
      VouchDayState.upcoming => 'Upcoming',
    };

    return _PosterScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PosterTopBar(
            right:
                '${DateFormat('d MMM').format(controller.today).toUpperCase()} / (001)',
            trailing: VouchAvatar(
              name: track.ownerFirstName,
              photoUrl: track.ownerPhotoUrl,
              size: 32,
            ),
          ),
          const SizedBox(height: 28),
          _PromiseHead(track: track),
          const SizedBox(height: 20),
          _MetaPair(
            leftLabel: 'witness',
            leftValue: partner,
            rightLabel: 'rhythm',
            rightValue: schedule == null
                ? 'Not set'
                : '${schedule.kind.shortLabel} · ${schedule.clockLabel}',
          ),
          const SizedBox(height: 24),
          Center(
            child: PromiseOrb(
              state: state,
              streak: stats.currentStreak,
              completion: stats.completionRate,
              caption: caption,
            ),
          ),
          const SizedBox(height: 26),
          PosterCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    PosterLabel('today / ${_stateCode(state)}',
                        color: style.cardMuted, size: 8.5, tracking: 1.2),
                    const Spacer(),
                    PosterTag(
                      caption,
                      color: _stateColor(state).withValues(alpha: 0.14),
                      foreground: _stateColor(state),
                    ),
                    if (hasNote) ...<Widget>[
                      const SizedBox(width: 4),
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(40, 30),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: style.cardInk,
                          textStyle: const TextStyle(
                            fontFamily: 'InstrumentSans',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => _editNote(controller, track),
                        child: const Text('Edit'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                if (hasNote)
                  Text(
                    '“$note”',
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      fontSize: 16,
                      height: 1.38,
                      letterSpacing: -0.2,
                      color: style.cardInk,
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Nothing logged yet.',
                        style: TextStyle(
                          fontFamily: 'InstrumentSans',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          height: 1.1,
                          color: style.cardInk,
                          fontVariations: const <FontVariation>[
                            FontVariation('wght', 700),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state == VouchDayState.rest
                            ? 'No promise today. Add a note if you did it anyway.'
                            : 'Write it before $partnerFirst checks in.',
                        style: TextStyle(
                          fontFamily: 'InstrumentSans',
                          fontSize: 12.5,
                          height: 1.35,
                          color: style.cardMuted,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                if (!hasNote)
                  PosterPill(
                    label: 'Write today’s note',
                    icon: Icons.edit_note_rounded,
                    compact: true,
                    arrow: false,
                    onPressed: () => _editNote(controller, track),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ReachStrip(
            name: partnerFirst,
            phone: phone,
            message:
                'Hey $partnerFirst, checking in on my Vouch promise — ${track.promise}.',
          ),
          const SizedBox(height: 28),
          PosterSectionLabel(
            '01',
            'the witness',
            trailing: PosterTag(
              !(entry?.isMarked ?? false)
                  ? 'waiting'
                  : entry!.status == DayStatus.completed
                      ? 'kept'
                      : 'missed',
              color: !(entry?.isMarked ?? false)
                  ? style.soft
                  : _stateColor(
                      entry!.status == DayStatus.completed
                          ? VouchDayState.completed
                          : VouchDayState.missed,
                    )
                      .withValues(alpha: 0.14),
              foreground: !(entry?.isMarked ?? false)
                  ? style.muted
                  : _stateColor(
                      entry!.status == DayStatus.completed
                          ? VouchDayState.completed
                          : VouchDayState.missed,
                    ),
            ),
          ),
          const SizedBox(height: 10),
          PosterCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    VouchAvatar(
                      name: partner,
                      photoUrl: track.partnerPhotoUrl,
                      size: 44,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            partner,
                            style: TextStyle(
                              fontFamily: 'InstrumentSans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: style.cardInk,
                              fontVariations: const <FontVariation>[
                                FontVariation('wght', 700),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            !(entry?.isMarked ?? false)
                                ? 'Waiting on their mark.'
                                : <String?>[
                                    entry?.method?.label,
                                    entry?.markedAt == null
                                        ? null
                                        : DateFormat('h:mm a').format(
                                            entry!.markedAt!.toLocal(),
                                          ),
                                  ].whereType<String>().join(' · '),
                            style: TextStyle(
                              fontFamily: 'InstrumentSans',
                              fontSize: 12.5,
                              color: style.cardMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (entry?.partnerNote?.trim().isNotEmpty ?? false) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    '“${entry!.partnerNote!.trim()}”',
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      fontSize: 14.5,
                      height: 1.4,
                      color: style.cardInk,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 26),
          const PosterSectionLabel('02', 'this week'),
          const SizedBox(height: 10),
          _WeekCard(controller: controller),
          const SizedBox(height: 16),
          _StatsCards(controller: controller),
          const SizedBox(height: 22),
          _ReminderLine(controller: controller),
          const SizedBox(height: 12),
          const NotificationPermissionCard(),
          const SizedBox(height: 26),
          PosterFooter(
            lead: 'Vouch',
            muted: 'One promise, one witness.',
          ),
          const SizedBox(height: 10),
          Text(
            partner == 'Your partner'
                ? 'One promise. One witness.'
                : 'Witnessed by $partner.',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9.5,
              letterSpacing: 0.6,
              color: style.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Partner home
// ---------------------------------------------------------------------------

class _PartnerHome extends StatelessWidget {
  const _PartnerHome();

  Future<void> _mark(BuildContext context) async {
    final controller = context.read<TrackController>();
    final track = controller.track;
    if (track == null) return;
    final entry = controller.todayEntry;
    final result = await showMarkSheet(
      context,
      ownerName: track.ownerFirstName,
      ownerPhone: track.ownerPhone,
      promise: track.promise,
      initialStatus: entry?.status ?? DayStatus.pending,
      initialMethod: entry?.method ?? MarkMethod.call,
      initialNote: entry?.partnerNote,
      onSave: (status, method, note) => controller.markDay(
        day: controller.todayKey,
        status: status,
        method: method,
        partnerNote: note,
      ),
    );
    if (!context.mounted || result == null) return;
    if (result == DayStatus.completed) {
      await showCelebration(
        context,
        title: 'Witnessed.',
        message:
            '${track.ownerFirstName} kept the promise. You made sure of it.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrackController>();
    final track = controller.track;
    if (track == null) {
      return const Center(child: VouchLoader());
    }
    final style = PosterStyle.of(context);
    final entry = controller.todayEntry;
    final state = controller.dayState(controller.today);
    final marked = entry?.isMarked ?? false;
    final completed = entry?.status == DayStatus.completed;
    final ownerFirst = track.ownerFirstName;
    final schedule = track.schedule;
    final hasNote = entry?.hasNote ?? false;
    final accent = completed ? PosterColors.kelly : PosterColors.coral;

    return _PosterScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PosterTopBar(
            right:
                '${DateFormat('d MMM').format(controller.today).toUpperCase()} / (002)',
            trailing: VouchAvatar(
              name: ownerFirst,
              photoUrl: track.ownerPhotoUrl,
              size: 32,
            ),
          ),
          const SizedBox(height: 28),
          _PromiseHead(track: track),
          const SizedBox(height: 20),
          _MetaPair(
            leftLabel: 'witnessing',
            leftValue: ownerFirst,
            rightLabel: 'rhythm',
            rightValue: schedule == null
                ? 'Not set'
                : '${schedule.kind.shortLabel} · ${schedule.clockLabel}',
          ),
          const SizedBox(height: 26),
          PosterSectionLabel(
            '01',
            'today',
            trailing: PosterTag(
              !marked ? 'waiting' : completed ? 'kept' : 'missed',
              color: marked
                  ? accent.withValues(alpha: 0.14)
                  : style.soft,
              foreground: marked ? accent : style.muted,
            ),
          ),
          const SizedBox(height: 10),
          if (!marked)
            PosterCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: style.cardInk,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '?',
                          style: TextStyle(
                            fontFamily: 'InstrumentSans',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: PosterColors.cream,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              state == VouchDayState.rest
                                  ? 'Rest day.'
                                  : 'Did $ownerFirst keep it?',
                              style: TextStyle(
                                fontFamily: 'InstrumentSans',
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                                letterSpacing: -0.6,
                                color: style.cardInk,
                                fontVariations: const <FontVariation>[
                                  FontVariation('wght', 700),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              state == VouchDayState.rest
                                  ? 'No promise is scheduled today.'
                                  : 'Ask, then record the answer.',
                              style: TextStyle(
                                fontFamily: 'InstrumentSans',
                                fontSize: 12.5,
                                color: style.cardMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PosterPill(
                    label: 'Mark today',
                    icon: Icons.fact_check_rounded,
                    color: style.cardInk,
                    foreground: PosterColors.cream,
                    arrowColor: PosterColors.acid,
                    arrowForeground: PosterColors.ink,
                    onPressed: () => _mark(context),
                  ),
                ],
              ),
            )
          else
            PosterCard(
              color: accent,
              foreground: PosterColors.cream,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: PosterColors.cream.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          completed
                              ? Icons.check_rounded
                              : Icons.close_rounded,
                          color: PosterColors.cream,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              completed ? 'Kept' : 'Missed',
                              style: const TextStyle(
                                fontFamily: 'InstrumentSans',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1.05,
                                color: PosterColors.cream,
                                fontVariations: <FontVariation>[
                                  FontVariation('wght', 700),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              <String?>[
                                entry?.method?.label,
                                entry?.markedAt == null
                                    ? null
                                    : DateFormat('h:mm a').format(
                                        entry!.markedAt!.toLocal(),
                                      ),
                              ].whereType<String>().join(' · '),
                              style: TextStyle(
                                fontFamily: 'InstrumentSans',
                                fontSize: 12.5,
                                color: PosterColors.cream.withValues(
                                  alpha: 0.72,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (entry?.partnerNote?.trim().isNotEmpty ?? false) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      '“${entry!.partnerNote!.trim()}”',
                      style: const TextStyle(
                        fontFamily: 'InstrumentSans',
                        fontSize: 14.5,
                        height: 1.4,
                        color: PosterColors.cream,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: PosterPill(
                          label: 'Change mark',
                          icon: Icons.edit_rounded,
                          compact: true,
                          arrow: false,
                          color: PosterColors.cream,
                          foreground: PosterColors.ink,
                          onPressed: () => _mark(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          _ReachStrip(
            name: ownerFirst,
            phone: track.ownerPhone,
            message:
                'Hey $ownerFirst, checking in on your Vouch promise: ${track.promise}. Did you get it done today?',
          ),
          if (hasNote) ...<Widget>[
            const SizedBox(height: 26),
            const PosterSectionLabel('02', 'their words'),
            const SizedBox(height: 10),
            PosterCard(
              child: Text(
                '“${entry!.note!.trim()}”',
                style: TextStyle(
                  fontFamily: 'InstrumentSans',
                  fontSize: 16.5,
                  height: 1.4,
                  letterSpacing: -0.2,
                  color: style.cardInk,
                ),
              ),
            ),
          ],
          const SizedBox(height: 26),
          PosterSectionLabel(hasNote ? '03' : '02', 'this week'),
          const SizedBox(height: 10),
          _WeekCard(controller: controller),
          const SizedBox(height: 16),
          _StatsCards(controller: controller),
          const SizedBox(height: 22),
          _ReminderLine(controller: controller),
          const SizedBox(height: 12),
          const NotificationPermissionCard(),
          const SizedBox(height: 26),
          PosterFooter(
            lead: 'Witness, not judge.',
            muted: 'Only the witness closes the day.',
          ),
        ],
      ),
    );
  }
}
