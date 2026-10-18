/// The signed-in shell: Today, History and Settings.
///
/// Laid out like a printed ledger — a measured header, one big statement,
/// instrument-style gauges and numbered sections.
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
import '../widgets/animated_background.dart';
import '../widgets/celebration.dart';
import '../widgets/contact_sheet.dart';
import '../widgets/day_detail_sheet.dart';
import '../widgets/mark_sheet.dart';
import '../widgets/note_editor_sheet.dart';
import '../widgets/notification_permission_card.dart';
import '../widgets/promise_orb.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/sheet_frame.dart';
import '../widgets/soul.dart';
import '../widgets/status_pill.dart';
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

    return Scaffold(
      extendBody: true,
      body: AnimatedBackground(
        child: SafeArea(
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

class _PagePadding extends StatelessWidget {
  const _PagePadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TopFade(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          108 + MediaQuery.paddingOf(context).bottom,
        ),
        child: child,
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead({
    required this.eyebrow,
    required this.name,
    required this.date,
    this.photoUrl,
  });

  final String eyebrow;
  final String name;
  final DateTime date;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    return PageHeader(
      eyebrow: eyebrow,
      title: name,
      titleSize: 36,
      index: '(001)',
      subtitle: DateFormat('EEEE d MMMM').format(date).toUpperCase(),
      trailing: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: dark ? scheme.surfaceContainerHigh : VouchColors.cream,
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.onSurface.withValues(alpha: 0.8),
                width: 1.3,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: dark ? 0.5 : 0.16),
                  offset: const Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: VouchAvatar(
              name: name,
              photoUrl: photoUrl,
              size: 46,
            ),
          ),
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: VouchColors.lime,
                shape: BoxShape.circle,
                border: Border.all(
                  color: scheme.onSurface.withValues(alpha: 0.85),
                  width: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The promise, set as the page's statement with a technical meta line.
class _PromiseStatement extends StatelessWidget {
  const _PromiseStatement({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final schedule = track.schedule;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              color: VouchColors.coral,
            ),
            const SizedBox(width: 8),
            Text(
              'THE ONE THING',
              style: text.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1.6,
              ),
            ),
            const Spacer(),
            Text(
              schedule == null
                  ? 'NO CLOCK'
                  : '${schedule.kind.shortLabel.toUpperCase()} · ${schedule.clockLabel.toUpperCase()}',
              style: text.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.8,
                fontSize: 9,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          track.promise,
          style: text.displaySmall?.copyWith(
            fontSize: 38,
            height: 0.98,
            letterSpacing: -1.7,
          ),
        ),
        if (track.promiseNote?.trim().isNotEmpty ?? false) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            '“${track.promiseNote!.trim()}”',
            style: text.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.controller});

  final TrackController controller;

  @override
  Widget build(BuildContext context) {
    final stats = controller.stats;
    final scheme = Theme.of(context).colorScheme;

    Widget divider() => Container(
          width: 1,
          height: 52,
          color: scheme.onSurface.withValues(alpha: 0.14),
        );

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: scheme.onSurface.withValues(alpha: 0.22)),
          bottom: BorderSide(color: scheme.onSurface.withValues(alpha: 0.22)),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _StatCell(
              label: 'Best streak',
              value: '${stats.bestStreak}',
              color: VouchColors.indigo,
            ),
          ),
          divider(),
          Expanded(
            child: _StatCell(
              label: 'Days kept',
              value: '${stats.completed}',
              color: VouchColors.kept,
            ),
          ),
          divider(),
          Expanded(
            child: _StatCell(
              label: 'Kept rate',
              value: stats.elapsed == 0 ? '—' : '${stats.completionPercent}%',
              color: VouchColors.coral,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final shown = isDark ? Color.lerp(color, Colors.white, 0.42)! : color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(
            label.toUpperCase(),
            style: text.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.0,
              fontSize: 9,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            value,
            style: text.displaySmall?.copyWith(
              color: shown,
              fontSize: 34,
              height: 0.95,
              letterSpacing: -1.6,
            ),
          ),
        ),
      ],
    );
  }
}

/// Seven measured columns — each day is a tick. Today carries a coral needle.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.controller});

  final TrackController controller;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final dates = <DateTime>[
      for (var offset = 6; offset >= 0; offset--)
        dateAt(controller.today, -offset),
    ];

    Color stateColor(VouchDayState state) => switch (state) {
          VouchDayState.completed => VouchColors.kept,
          VouchDayState.missed => VouchColors.coral,
          VouchDayState.pending => VouchColors.indigo,
          VouchDayState.rest ||
          VouchDayState.upcoming =>
            scheme.onSurface.withValues(alpha: 0.18),
        };

    return Row(
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
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: <Widget>[
                    Text(
                      shortWeekday(date).substring(0, 1).toUpperCase(),
                      style: text.labelSmall?.copyWith(
                        color: dayKey(date) == controller.todayKey
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                        fontSize: 9,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      width: dayKey(date) == controller.todayKey ? 3 : 2,
                      height: 24,
                      color: dayKey(date) == controller.todayKey
                          ? VouchColors.coral
                          : stateColor(controller.dayState(date)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${date.day}',
                      style: text.labelSmall?.copyWith(
                        color: dayKey(date) == controller.todayKey
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                        fontSize: 10,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ContactAction extends StatelessWidget {
  const _ContactAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: enabled
                      ? color.withValues(alpha: 0.12)
                      : scheme.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: enabled
                        ? color.withValues(alpha: 0.4)
                        : scheme.onSurface.withValues(alpha: 0.08),
                    width: 1.1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: enabled ? color : scheme.onSurfaceVariant,
                  size: 21,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label.toUpperCase(),
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 8.5,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderLine extends StatelessWidget {
  const _ReminderLine({required this.controller});

  final TrackController controller;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final schedule = controller.track?.schedule;
    final next = controller.nextReminder;
    final remaining = controller.timeToNextReminder;

    final label = schedule == null
        ? 'No reminder set'
        : next == null
            ? 'No upcoming reminder'
            : 'Next buzz · ${DateFormat('EEE d MMM · h:mm a').format(next)}';

    return Column(
      children: <Widget>[
        Container(
          height: 1,
          color: scheme.onSurface.withValues(alpha: 0.16),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.notifications_none_rounded,
                size: 17,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (remaining != null)
                Text(
                  countdownLabel(remaining),
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurface,
                    letterSpacing: 0.6,
                  ),
                ),
            ],
          ),
        ),
        Container(
          height: 1,
          color: scheme.onSurface.withValues(alpha: 0.16),
        ),
      ],
    );
  }
}

/// The cobalt poster the witness sees at the top of their page.
class _PromisePoster extends StatelessWidget {
  const _PromisePoster({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return InkCard(
      color: VouchColors.indigo,
      borderColor: VouchColors.indigoDeep,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
      child: CropMarks(
        color: VouchColors.cream.withValues(alpha: 0.4),
        inset: 7,
        length: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Sticker(
                  'The promise',
                  color: VouchColors.lime,
                  foreground: VouchColors.ink,
                  rotation: -0.04,
                ),
                const Spacer(),
                Text(
                  '(002)',
                  style: text.labelSmall?.copyWith(
                    color: VouchColors.cream.withValues(alpha: 0.6),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              track.promise,
              style: text.displaySmall?.copyWith(
                color: VouchColors.cream,
                fontSize: 33,
                height: 0.98,
                letterSpacing: -1.4,
              ),
            ),
            if (track.promiseNote?.trim().isNotEmpty ?? false) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                '“${track.promiseNote!.trim()}”',
                style: text.bodyMedium?.copyWith(
                  color: VouchColors.cream.withValues(alpha: 0.72),
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
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
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final state = controller.dayState(controller.today);
    final entry = controller.todayEntry;
    final stats = controller.stats;
    final partner = track.partnerName ?? 'Your partner';

    final caption = switch (state) {
      VouchDayState.completed => 'Kept today',
      VouchDayState.missed => 'Missed today',
      VouchDayState.pending => 'Today is open',
      VouchDayState.rest => 'Rest day',
      VouchDayState.upcoming => 'Upcoming',
    };

    return _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Masthead(
            eyebrow: 'Keeping',
            name: track.ownerFirstName,
            date: controller.today,
            photoUrl: track.ownerPhotoUrl,
          ),
          const SizedBox(height: 30),
          Reveal(child: _PromiseStatement(track: track)),
          const SizedBox(height: 16),
          Center(
            child: PromiseOrb(
              state: state,
              streak: stats.currentStreak,
              completion: stats.completionRate,
              caption: caption,
              size: 244,
            ),
          ),
          const SizedBox(height: 10),
          _ReminderLine(controller: controller),
          const SizedBox(height: 10),
          const NotificationPermissionCard(),
          const SizedBox(height: 32),
          const SectionHeader(
            index: '01',
            title: 'The witness',
            subtitle: 'Only they can close the day.',
          ),
          _WitnessTile(controller: controller, track: track, entry: entry),
          const SizedBox(height: 30),
          SectionHeader(
            index: '02',
            title: 'Today’s note',
            subtitle: entry?.hasNote ?? false
                ? null
                : 'Write it before ${track.partnerFirstName} checks in.',
            trailing: entry?.hasNote ?? false
                ? TextButton(
                    onPressed: () => _editNote(controller, track),
                    child: const Text('Edit'),
                  )
                : null,
          ),
          if (state == VouchDayState.rest && !(entry?.hasNote ?? false))
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SheetNote(
                icon: Icons.self_improvement_rounded,
                text: 'No promise today. Add a note if you did it anyway.',
              ),
            ),
          if (entry?.hasNote ?? false)
            NotePreview(note: entry?.note)
          else
            SoulButton(
              label: 'Write today’s note',
              icon: Icons.edit_note_rounded,
              onPressed: () => _editNote(controller, track),
            ),
          const SizedBox(height: 30),
          const SectionHeader(index: '03', title: 'This week'),
          ExpressiveCard(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
            child: _WeekStrip(controller: controller),
          ),
          const SizedBox(height: 16),
          _StatsRow(controller: controller),
          const SizedBox(height: 22),
          Center(
            child: Text(
              partner == 'Your partner'
                  ? 'One promise. One witness.'
                  : 'Witnessed by $partner.',
              style: text.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WitnessTile extends StatelessWidget {
  const _WitnessTile({
    required this.controller,
    required this.track,
    required this.entry,
  });

  final TrackController controller;
  final Track track;
  final DayEntry? entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final marked = entry?.isMarked ?? false;
    final completed = entry?.status == DayStatus.completed;
    final phone = track.partnerPhone?.trim() ?? '';
    final message =
        'Hey ${track.partnerFirstName}, checking in on my Vouch promise — ${track.promise}.';

    final color = completed
        ? VouchColors.kept
        : marked
            ? VouchColors.coral
            : VouchColors.indigo;

    return InkCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              VouchAvatar(
                name: track.partnerName ?? 'Partner',
                photoUrl: track.partnerPhotoUrl,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      track.partnerName ?? 'Your partner',
                      style: text.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      !marked
                          ? 'Waiting on their mark.'
                          : <String?>[
                              entry?.method?.label,
                              entry?.markedAt == null
                                  ? null
                                  : DateFormat('h:mm a')
                                      .format(entry!.markedAt!.toLocal()),
                            ].whereType<String>().join(' · '),
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: !marked
                    ? 'Waiting'
                    : completed
                        ? 'Kept'
                        : 'Missed',
                color: color,
                icon: !marked
                    ? Icons.schedule_rounded
                    : completed
                        ? Icons.check_rounded
                        : Icons.close_rounded,
                dense: true,
              ),
            ],
          ),
          if (entry?.partnerNote?.trim().isNotEmpty ?? false) ...<Widget>[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '“${entry!.partnerNote!.trim()}”',
                style: text.bodyMedium?.copyWith(height: 1.45),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: scheme.onSurface.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              _ContactAction(
                icon: Icons.call_rounded,
                label: 'Call',
                color: VouchColors.indigo,
                enabled: phone.isNotEmpty,
                onTap: () => showContactSheet(
                  context,
                  name: track.partnerFirstName,
                  phone: track.partnerPhone,
                  message: message,
                ),
              ),
              _ContactAction(
                icon: Icons.chat_bubble_rounded,
                label: 'WhatsApp',
                color: const Color(0xFF1FA855),
                enabled: phone.isNotEmpty,
                onTap: () => showContactSheet(
                  context,
                  name: track.partnerFirstName,
                  phone: track.partnerPhone,
                  message: message,
                ),
              ),
              _ContactAction(
                icon: Icons.sms_rounded,
                label: 'SMS',
                color: VouchColors.coral,
                enabled: phone.isNotEmpty,
                onTap: () => showContactSheet(
                  context,
                  name: track.partnerFirstName,
                  phone: track.partnerPhone,
                  message: message,
                ),
              ),
            ],
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
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final entry = controller.todayEntry;
    final state = controller.dayState(controller.today);
    final marked = entry?.isMarked ?? false;
    final completed = entry?.status == DayStatus.completed;
    final phone = track.ownerPhone?.trim() ?? '';
    final message =
        'Hey ${track.ownerFirstName}, checking in on your Vouch promise: ${track.promise}. Did you get it done today?';

    return _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Masthead(
            eyebrow: 'Witnessing',
            name: track.ownerFirstName,
            date: controller.today,
            photoUrl: track.ownerPhotoUrl,
          ),
          const SizedBox(height: 30),
          _PromisePoster(track: track),
          const SizedBox(height: 30),
          SectionHeader(
            index: '01',
            title: 'Today',
            subtitle: marked ? null : 'Check in, then mark it.',
          ),
          if (!marked)
            InkCard(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      LetterBadge(
                        letter: '?',
                        color: VouchColors.indigo,
                        size: 44,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              state == VouchDayState.rest
                                  ? 'Rest day'
                                  : 'Did ${track.ownerFirstName} keep it?',
                              style: text.headlineSmall,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              state == VouchDayState.rest
                                  ? 'No promise is scheduled today.'
                                  : 'Ask, then record the answer.',
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      _ContactAction(
                        icon: Icons.call_rounded,
                        label: 'Call',
                        color: VouchColors.indigo,
                        enabled: phone.isNotEmpty,
                        onTap: () => showContactSheet(
                          context,
                          name: track.ownerFirstName,
                          phone: track.ownerPhone,
                          message: message,
                        ),
                      ),
                      _ContactAction(
                        icon: Icons.chat_bubble_rounded,
                        label: 'WhatsApp',
                        color: const Color(0xFF1FA855),
                        enabled: phone.isNotEmpty,
                        onTap: () => showContactSheet(
                          context,
                          name: track.ownerFirstName,
                          phone: track.ownerPhone,
                          message: message,
                        ),
                      ),
                      _ContactAction(
                        icon: Icons.sms_rounded,
                        label: 'SMS',
                        color: VouchColors.coral,
                        enabled: phone.isNotEmpty,
                        onTap: () => showContactSheet(
                          context,
                          name: track.ownerFirstName,
                          phone: track.ownerPhone,
                          message: message,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SoulButton(
                    label: 'Mark today',
                    icon: Icons.fact_check_rounded,
                    onPressed: () => _mark(context),
                  ),
                ],
              ),
            )
          else
            InkCard(
              borderColor: (completed ? VouchColors.kept : VouchColors.coral)
                  .withValues(alpha: 0.55),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      LetterBadge(
                        letter: completed ? 'K' : 'M',
                        color: completed ? VouchColors.kept : VouchColors.coral,
                        size: 44,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              completed ? 'Kept' : 'Missed',
                              style: text.headlineSmall,
                            ),
                            Text(
                              <String?>[
                                entry?.method?.label,
                                entry?.markedAt == null
                                    ? null
                                    : DateFormat('h:mm a').format(
                                        entry!.markedAt!.toLocal(),
                                      ),
                              ].whereType<String>().join(' · '),
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
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
                      style: text.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _mark(context),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Change mark'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.outlined(
                        tooltip: 'Contact ${track.ownerFirstName}',
                        onPressed: () => showContactSheet(
                          context,
                          name: track.ownerFirstName,
                          phone: track.ownerPhone,
                          message: message,
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (entry?.hasNote ?? false) ...<Widget>[
            const SizedBox(height: 30),
            const SectionHeader(index: '02', title: 'Their words'),
            NotePreview(note: entry?.note),
          ],
          const SizedBox(height: 26),
          _ReminderLine(controller: controller),
          const SizedBox(height: 10),
          const NotificationPermissionCard(),
          const SizedBox(height: 30),
          SectionHeader(
            index: (entry?.hasNote ?? false) ? '03' : '02',
            title: 'This week',
          ),
          ExpressiveCard(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
            child: _WeekStrip(controller: controller),
          ),
          const SizedBox(height: 16),
          _StatsRow(controller: controller),
          const SizedBox(height: 22),
          Center(
            child: Text(
              'Witness, not judge.',
              style: text.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
