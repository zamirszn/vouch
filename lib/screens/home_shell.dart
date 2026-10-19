/// The signed-in shell: Today, History and You.
///
/// Today is an atmospheric dashboard. The background, hero and accents shift
/// with the day state; both roles share the same frame but the hero and
/// actions change with what they are allowed to do.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../components/dot_matrix_number.dart';
import '../components/glass_card.dart';
import '../components/reveal.dart';
import '../components/stat_tile.dart';
import '../components/vertical_ruler.dart';
import '../components/vouch_button.dart';
import '../components/vouch_icon.dart';
import '../components/vouch_loader.dart';
import '../components/vouch_nav_shell.dart';
import '../components/vouch_scaffold.dart';
import '../components/vouch_top_bar.dart';
import '../components/vouch_toast.dart';
import '../components/week_strip.dart';
import '../core/date_utils.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import '../models/day_entry.dart';
import '../models/track.dart';
import '../services/notification_service.dart';
import '../state/track_controller.dart';
import '../components/celebration.dart';
import '../components/contact_panel.dart';
import '../components/day_detail_sheet.dart';
import '../components/mark_sheet.dart';
import '../components/note_editor_sheet.dart';
import '../components/notification_permission_card.dart';
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
    final todayTone = toneForDay(controller.dayState(controller.today));
    final tone = _index == 0 ? todayTone : VouchTone.rest;

    return VouchScaffold(
      tone: tone,
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          TickerMode(
            enabled: _index == 0,
            child: isPartner ? const _WitnessHome() : const _OwnerHome(),
          ),
          TickerMode(
            enabled: _index == 1,
            child: const HistoryScreen(),
          ),
          TickerMode(
            enabled: _index == 2,
            child: const SettingsScreen(),
          ),
        ],
      ),
      bottomBar: VouchNavShell(
        index: _index,
        onSelect: _select,
        items: const <VouchNavItem>[
          VouchNavItem(label: 'Today', glyph: VouchGlyph.calendar),
          VouchNavItem(label: 'History', glyph: VouchGlyph.clock),
          VouchNavItem(label: 'You', glyph: VouchGlyph.person),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

class _HomeScroll extends StatelessWidget {
  const _HomeScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          VouchSpace.gutter,
          VouchSpace.x2,
          VouchSpace.gutter,
          VouchSpace.navHeight + bottom + VouchSpace.x10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            child,
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

class _Footer extends StatelessWidget {
  const _Footer({required this.line, required this.caption});

  final String line;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(height: 1, color: theme.line),
        const SizedBox(height: 16),
        Text(line, style: VouchType.body(theme.muted)),
        const SizedBox(height: 4),
        Text(caption, style: VouchType.caption(theme.faint)),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.controller, required this.caption});

  final TrackController controller;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final stats = controller.stats;
    final tone = toneForDay(controller.dayState(controller.today));
    final accent = toneColor(context, tone);
    final percent = stats.elapsed == 0 ? 0 : stats.completionPercent;

    return GlassCard(
      radius: VouchRadius.card,
      padding: const EdgeInsets.fromLTRB(20, 20, 18, 18),
      glow: true,
      tint: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'DAY STREAK',
                      style: VouchType.label(theme.muted, size: 9.5),
                    ),
                    const SizedBox(height: 12),
                    DotMatrixNumber(
                      stats.currentStreak,
                      height: 54,
                      color: theme.ink,
                      dim: accent,
                    ),
                    const SizedBox(height: 14),
                    StatusChip(label: caption, tone: tone),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  VerticalRuler(
                    value: stats.completionRate,
                    height: 86,
                    color: accent,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$percent%',
                    style: VouchType.title(theme.ink).copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'KEPT',
                    style: VouchType.label(theme.faint, size: 8.5),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Sparkline(controller: controller),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.controller});

  final TrackController controller;

  @override
  Widget build(BuildContext context) {
    final days = <DateTime>[
      for (var offset = 6; offset >= 0; offset--)
        dateAt(controller.today, -offset),
    ];
    return SizedBox(
      height: 34,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (final date in days)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: ColoredBox(
                  color: const Color(0x00000000),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: VouchDurations.base,
                      curve: Curves.easeOutCubic,
                      height: _height(controller.dayState(date)),
                      decoration: BoxDecoration(
                        color: toneColor(
                          context,
                          toneForDay(controller.dayState(date)),
                        ).withValues(
                          alpha: controller.dayState(date) ==
                                  VouchDayState.upcoming
                              ? 0.14
                              : 0.85,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _height(VouchDayState state) => switch (state) {
        VouchDayState.completed => 34,
        VouchDayState.missed => 18,
        VouchDayState.pending => 11,
        VouchDayState.rest => 6,
        VouchDayState.upcoming => 4,
      };
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.controller, required this.height});

  final TrackController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final days = <WeekStripDay>[
      for (var offset = 6; offset >= 0; offset--)
        WeekStripDay(
          date: dateAt(controller.today, -offset),
          state: controller.dayState(dateAt(controller.today, -offset)),
        ),
    ];
    return GlassCard(
      radius: VouchRadius.medium,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                'THIS WEEK',
                style: VouchType.label(theme.muted, size: 9),
              ),
            ),
            const Spacer(),
            WeekStrip(
              days: days,
              today: controller.today,
              onTap: (day) => showDayDetailSheet(
                context,
                date: day.date,
                entry: controller.days[dayKey(day.date)],
                state: day.state,
                today: controller.today,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.height,
    required this.note,
    required this.fallback,
    required this.onEdit,
  });

  final double height;
  final String? note;
  final String fallback;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final hasNote = note?.trim().isNotEmpty ?? false;
    return GlassCard(
      radius: VouchRadius.medium,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      onTap: onEdit,
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'NOTE',
                  style: VouchType.label(theme.muted, size: 9),
                ),
                const Spacer(),
                if (hasNote)
                  Text(
                    'Edit',
                    style: VouchType.bodyStrong(theme.ink)
                        .copyWith(fontSize: 12),
                  )
                else
                  const VouchIcon(
                    VouchGlyph.plus,
                    size: 14,
                    color: Color(0xFFA2A5AE),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              hasNote ? note!.trim() : fallback,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: (hasNote
                      ? VouchType.body(theme.ink)
                      : VouchType.caption(theme.faint))
                  .copyWith(fontSize: hasNote ? 14 : 12.5, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _WitnessTile extends StatelessWidget {
  const _WitnessTile({
    required this.height,
    required this.name,
    required this.status,
    required this.tone,
    this.onTap,
  });

  final double height;
  final String name;
  final String status;
  final VouchTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return GlassCard(
      radius: VouchRadius.medium,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'WITNESS',
                  style: VouchType.label(theme.muted, size: 9),
                ),
                const Spacer(),
                VouchAvatar(initials: _initials(name), size: 24),
              ],
            ),
            const Spacer(),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VouchType.cardTitle(theme.ink).copyWith(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: toneColor(context, tone),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VouchType.caption(theme.muted).copyWith(fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReachActions extends StatelessWidget {
  const _ReachActions({
    required this.name,
    required this.phone,
    required this.message,
  });

  final String name;
  final String? phone;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final enabled = phone?.trim().isNotEmpty ?? false;

    Widget action(VouchGlyph glyph, String label) => Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAction(
              glyph: glyph,
              size: 46,
              onTap: enabled
                  ? () => showContactSheet(
                        context,
                        name: name,
                        phone: phone,
                        message: message,
                      )
                  : null,
            ),
            const SizedBox(height: 6),
            Text(label, style: VouchType.label(theme.faint, size: 8)),
          ],
        );

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          action(VouchGlyph.phone, 'CALL'),
          action(VouchGlyph.message, 'WHATSAPP'),
          action(VouchGlyph.mail, 'SMS'),
        ],
      ),
    );
  }
}

class _ReminderLine extends StatelessWidget {
  const _ReminderLine({required this.controller});

  final TrackController controller;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
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
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: theme.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: VouchType.caption(theme.muted).copyWith(fontSize: 12),
          ),
        ),
        if (remaining != null)
          Text(
            countdownLabel(remaining),
            style: VouchType.label(theme.ink, size: 9),
          ),
      ],
    );
  }
}

class _StatusAction extends StatelessWidget {
  const _StatusAction({required this.controller, required this.caption});

  final TrackController controller;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return CircleAction(
      glyph: controller.todayEntry?.isMarked ?? false
          ? VouchGlyph.check
          : VouchGlyph.dots,
      size: 54,
      foreground: theme.accent,
      onTap: () => VouchToast.show(
        context,
        caption,
        glyph: controller.todayEntry?.isMarked ?? false
            ? VouchGlyph.checkCircle
            : VouchGlyph.clock,
        accent: theme.accent,
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
    final theme = VouchScope.of(context);
    if (track == null) {
      return Center(child: VouchLoader(color: theme.ink));
    }
    final state = controller.dayState(controller.today);
    final entry = controller.todayEntry;
    final stats = controller.stats;
    final partner = track.partnerName ?? 'Your partner';
    final partnerFirst = track.partnerFirstName;
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

    final marked = entry?.isMarked ?? false;
    final witnessTone = !marked
        ? VouchTone.pending
        : entry?.status == DayStatus.completed
            ? VouchTone.kept
            : VouchTone.missed;
    final witnessStatus = !marked
        ? 'Waiting on their mark.'
        : <String?>[
            entry?.method?.label,
            entry?.markedAt == null
                ? null
                : DateFormat('h:mm a').format(entry!.markedAt!.toLocal()),
          ].whereType<String>().join(' · ');

    return _HomeScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Reveal(
            index: 0,
            child: VouchTopBar(
              annotation:
                  '${DateFormat('d MMM').format(controller.today).toUpperCase()} / (001)',
              trailing: VouchAvatar(
                initials: _initials(track.ownerFirstName),
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Reveal(
            index: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(track.promise, style: VouchType.hero(theme.ink)),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Container(
                      width: 26,
                      height: 3,
                      decoration: BoxDecoration(
                        color: theme.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'every day',
                      style: VouchType.body(theme.muted)
                          .copyWith(fontSize: 15),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        schedule == null
                            ? 'NO CLOCK'
                            : '${schedule.kind.shortLabel.toUpperCase()} / ${schedule.clockLabel.toUpperCase()}',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VouchType.label(theme.faint, size: 8.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Reveal(index: 2, child: _HeroCard(controller: controller, caption: caption)),
          const SizedBox(height: 14),
          Reveal(
            index: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: StatTile(
                    value: '${stats.completed}',
                    label: 'days kept',
                    tone: VouchTone.kept,
                    height: 112,
                    trailing: Text(
                      'of ${stats.elapsed}',
                      style: VouchType.mono(theme.faint, size: 9),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WitnessTile(
                    height: 82,
                    name: partner,
                    status: witnessStatus,
                    tone: witnessTone,
                    onTap: () => showContactSheet(
                      context,
                      name: partnerFirst,
                      phone: track.partnerPhone,
                      message:
                          'Hey $partnerFirst, checking in on my Vouch promise — ${track.promise}.',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Reveal(
            index: 4,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _NoteCard(
                    height: 82,
                    note: note,
                    fallback: state == VouchDayState.rest
                        ? 'Rest day. Add a note if you did it anyway.'
                        : 'Write it before $partnerFirst checks in.',
                    onEdit: () => _editNote(controller, track),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WeekCard(controller: controller, height: 82),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Reveal(
            index: 5,
            child: Row(
              children: <Widget>[
                CircleAction(
                  glyph: VouchGlyph.close,
                  size: 54,
                  onTap: () => showContactSheet(
                    context,
                    name: partnerFirst,
                    phone: track.partnerPhone,
                    message:
                        'Hey $partnerFirst, checking in on my Vouch promise — ${track.promise}.',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: VouchButton(
                    label: hasNote ? 'Edit note' : 'Add a note',
                    glyph: hasNote ? VouchGlyph.edit : VouchGlyph.plus,
                    onPressed: () => _editNote(controller, track),
                  ),
                ),
                const SizedBox(width: 12),
                _StatusAction(controller: controller, caption: caption),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Reveal(
            index: 6,
            child: Row(
              children: <Widget>[
                Expanded(child: _ReminderLine(controller: controller)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const NotificationPermissionCard(),
          const SizedBox(height: 28),
          Reveal(
            index: 7,
            child: _Footer(
              line: partner == 'Your partner'
                  ? 'One promise. One witness.'
                  : 'Witnessed by $partner.',
              caption: 'Only the witness closes the day.',
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Witness home
// ---------------------------------------------------------------------------

class _WitnessHome extends StatelessWidget {
  const _WitnessHome();

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
    final theme = VouchScope.of(context);
    if (track == null) {
      return Center(child: VouchLoader(color: theme.ink));
    }
    final entry = controller.todayEntry;
    final state = controller.dayState(controller.today);
    final marked = entry?.isMarked ?? false;
    final completed = entry?.status == DayStatus.completed;
    final ownerFirst = track.ownerFirstName;
    final hasNote = entry?.hasNote ?? false;
    final caption = switch (state) {
      VouchDayState.completed => 'Kept today',
      VouchDayState.missed => 'Missed today',
      VouchDayState.pending => 'Awaiting your mark',
      VouchDayState.rest => 'Rest day',
      VouchDayState.upcoming => 'Upcoming',
    };

    return _HomeScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Reveal(
            index: 0,
            child: VouchTopBar(
              annotation:
                  '${DateFormat('d MMM').format(controller.today).toUpperCase()} / (002)',
              trailing: VouchAvatar(
                initials: _initials(ownerFirst),
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Reveal(
            index: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text('WITNESSING', style: VouchType.label(theme.accent, size: 9.5)),
                    const Spacer(),
                    Text(
                      track.schedule == null
                          ? 'NO CLOCK'
                          : track.schedule!.clockLabel.toUpperCase(),
                      style: VouchType.label(theme.faint, size: 8.5),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  state == VouchDayState.rest
                      ? 'Rest day.'
                      : 'Did $ownerFirst keep it?',
                  style: VouchType.hero(theme.ink),
                ),
                const SizedBox(height: 12),
                Text(
                  state == VouchDayState.rest
                      ? 'No promise is scheduled today.'
                      : 'Ask, then record the answer.',
                  style: VouchType.body(theme.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Reveal(index: 2, child: _HeroCard(controller: controller, caption: caption)),
          const SizedBox(height: 16),
          Reveal(
            index: 3,
            child: marked
                ? GlassCard(
                    tint: completed ? theme.kept : theme.missed,
                    glow: true,
                    child: _MarkedCard(
                      completed: completed,
                      entry: entry,
                      onChange: () => _mark(context),
                    ),
                  )
                : GlassCard(
                    tint: toneColor(context, VouchTone.pending),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'TODAY',
                          style: VouchType.label(theme.muted, size: 9),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Close the day',
                          style: VouchType.title(theme.ink).copyWith(fontSize: 24),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Only you can close the day.',
                          style: VouchType.caption(theme.muted),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            CircleAction(
                              glyph: VouchGlyph.check,
                              size: 50,
                              foreground: theme.kept,
                              onTap: () => _mark(context),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: VouchButton(
                                label: 'Mark today',
                                onPressed: () => _mark(context),
                              ),
                            ),
                            const SizedBox(width: 10),
                            CircleAction(
                              glyph: VouchGlyph.close,
                              size: 50,
                              foreground: theme.missed,
                              onTap: () => _mark(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Reveal(
            index: 4,
            child: _ReachActions(
              name: ownerFirst,
              phone: track.ownerPhone,
              message:
                  'Hey $ownerFirst, checking in on your Vouch promise: ${track.promise}. Did you get it done today?',
            ),
          ),
          const SizedBox(height: 22),
          if (hasNote) ...<Widget>[
            Reveal(
              index: 5,
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'THEIR NOTE',
                      style: VouchType.label(theme.muted, size: 9),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      entry!.note!.trim(),
                      style: VouchType.body(theme.ink).copyWith(
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Reveal(
            index: 6,
            child: _WitnessTile(
              height: 78,
              name: ownerFirst,
              status: '${controller.stats.completed} days kept · '
                  '${controller.stats.currentStreak} in a row',
              tone: VouchTone.kept,
              onTap: () => showContactSheet(
                context,
                name: ownerFirst,
                phone: track.ownerPhone,
                message:
                    'Hey $ownerFirst, checking in on your Vouch promise: ${track.promise}. Did you get it done today?',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Reveal(
            index: 7,
            child: _WeekCard(controller: controller, height: 82),
          ),
          const SizedBox(height: 18),
          const NotificationPermissionCard(),
          const SizedBox(height: 24),
          Reveal(
            index: 8,
            child: const _Footer(
              line: 'Witness, not judge.',
              caption: 'Only the witness closes the day.',
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkedCard extends StatelessWidget {
  const _MarkedCard({
    required this.completed,
    required this.entry,
    required this.onChange,
  });

  final bool completed;
  final DayEntry? entry;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final accent = completed ? theme.kept : theme.missed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: VouchIcon(
                  completed ? VouchGlyph.check : VouchGlyph.close,
                  size: 20,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    completed ? 'Kept' : 'Missed',
                    style: VouchType.title(theme.ink).copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    <String?>[
                      entry?.method?.label,
                      entry?.markedAt == null
                          ? null
                          : DateFormat('h:mm a').format(
                              entry!.markedAt!.toLocal(),
                            ),
                    ].whereType<String>().join(' · '),
                    style: VouchType.caption(theme.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (entry?.partnerNote?.trim().isNotEmpty ?? false) ...<Widget>[
          const SizedBox(height: 14),
          Text(
            entry!.partnerNote!.trim(),
            style: VouchType.body(theme.ink),
          ),
        ],
        const SizedBox(height: 16),
        VouchButton(
          label: 'Change mark',
          glyph: VouchGlyph.edit,
          style: VouchButtonStyle.glass,
          compact: true,
          height: 44,
          onPressed: onChange,
        ),
      ],
    );
  }
}
