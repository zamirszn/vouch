/// The signed-in shell: Today, History and Settings.
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
import 'history_screen.dart';
import 'settings_screen.dart';
import '../widgets/vouch_loader.dart';

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
          22,
          16,
          22,
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
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Asterisk(size: 11, color: scheme.secondary),
                  const SizedBox(width: 7),
                  Text(
                    eyebrow.toUpperCase(),
                    style: text.labelSmall?.copyWith(
                      color: scheme.primary,
                      letterSpacing: 1.9,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                name,
                style: text.displaySmall?.copyWith(
                  fontSize: 34,
                  height: 1.0,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                DateFormat('EEEE d MMMM').format(date).toUpperCase(),
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Transform.rotate(
              angle: 0.05,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.onSurface.withValues(alpha: 0.8),
                    width: 1.4,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: scheme.shadow.withValues(
                        alpha: dark ? 0.5 : 0.20,
                      ),
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
            ),
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: VouchColors.coral,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 2),
                ),
              ),
            ),
          ],
        ),
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
          height: 44,
          color: scheme.outlineVariant.withValues(alpha: 0.6),
        );

    return InkCard(
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
              color: const Color(0xFF4C7A16),
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
      children: <Widget>[
        Text(
          value,
          style: text.displaySmall?.copyWith(
            color: shown,
            fontSize: 30,
            height: 1,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: text.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.8,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

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

    return Row(
      children: <Widget>[
        for (final date in dates)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
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
                      shortWeekday(date).substring(0, 1),
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _DayDot(state: controller.dayState(date)),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: text.labelSmall?.copyWith(
                        color: dayKey(date) == controller.todayKey
                            ? VouchColors.indigo
                            : scheme.onSurfaceVariant,
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

class _DayDot extends StatelessWidget {
  const _DayDot({required this.state});

  final VouchDayState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color color, IconData? icon) = switch (state) {
      VouchDayState.completed => (
          const Color(0xFF7FCB32),
          Icons.check_rounded,
        ),
      VouchDayState.missed => (VouchColors.coral, Icons.close_rounded),
      VouchDayState.pending => (VouchColors.indigo, Icons.bolt_rounded),
      VouchDayState.rest => (scheme.surfaceContainerHighest, null),
      VouchDayState.upcoming => (
          scheme.surfaceContainerHighest,
          Icons.hourglass_empty_rounded,
        ),
    };

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: icon == null
          ? null
          : Icon(
              icon,
              size: 17,
              color: state == VouchDayState.missed
                  ? VouchColors.coral
                  : state == VouchDayState.completed
                      ? const Color(0xFF3E7A12)
                      : VouchColors.indigo,
            ),
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

    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: enabled ? 0.12 : 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: enabled ? 0.34 : 0.10),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: enabled
                      ? color
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: text.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        const DashRule(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.notifications_none_rounded,
                size: 19,
                color: scheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (remaining != null)
                Text(
                  countdownLabel(remaining),
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const DashRule(),
      ],
    );
  }
}

class _PromiseHero extends StatelessWidget {
  const _PromiseHero({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return InkCard(
      color: VouchColors.indigo,
      borderColor: const Color(0xFF241765),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            right: -34,
            top: -26,
            child: Asterisk(
              size: 130,
              strokeWidth: 9,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Sticker(
                'The promise',
                color: VouchColors.lime,
                foreground: VouchColors.ink,
                rotation: -0.05,
              ),
              const SizedBox(height: 18),
              Text(
                track.promise,
                style: text.displaySmall?.copyWith(
                  color: VouchColors.cream,
                  fontSize: 34,
                  height: 1.06,
                  letterSpacing: -0.9,
                ),
              ),
              if (track.promiseNote?.trim().isNotEmpty ?? false) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  '“${track.promiseNote!.trim()}”',
                  style: text.bodyMedium?.copyWith(
                    color: VouchColors.cream.withValues(alpha: 0.78),
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ],
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
          const SizedBox(height: 26),
          Reveal(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  track.promise,
                  style: text.displaySmall?.copyWith(
                    fontSize: 36,
                    height: 1.06,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 4),
                const Squiggle(width: 96, color: VouchColors.coral),
                if (track.promiseNote?.trim().isNotEmpty ?? false) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    '“${track.promiseNote!.trim()}”',
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: PromiseOrb(
              state: state,
              streak: stats.currentStreak,
              completion: stats.completionRate,
              caption: caption,
              size: 238,
            ),
          ),
          const SizedBox(height: 14),
          _ReminderLine(controller: controller),
          const SizedBox(height: 12),
          const NotificationPermissionCard(),
          const SizedBox(height: 30),
          SectionHeader(
            index: '01',
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
            const _NoteCallout(
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
          SectionHeader(
            index: '02',
            title: 'Witness',
            subtitle: (entry?.isMarked ?? false) ? 'Settled.' : null,
          ),
          _WitnessStatus(
            controller: controller,
            track: track,
            entry: entry,
            state: state,
          ),
          const SizedBox(height: 12),
          ExpressiveCard(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: <Widget>[
                _ContactAction(
                  icon: Icons.call_rounded,
                  label: 'Call',
                  color: VouchColors.indigo,
                  enabled: track.partnerPhone?.trim().isNotEmpty ?? false,
                  onTap: () => showContactSheet(
                    context,
                    name: track.partnerFirstName,
                    phone: track.partnerPhone,
                    message:
                        'Hey ${track.partnerFirstName}, checking in on my Vouch promise — ${track.promise}.',
                  ),
                ),
                _ContactAction(
                  icon: Icons.chat_bubble_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  enabled: track.partnerPhone?.trim().isNotEmpty ?? false,
                  onTap: () => showContactSheet(
                    context,
                    name: track.partnerFirstName,
                    phone: track.partnerPhone,
                    message:
                        'Hey ${track.partnerFirstName}, checking in on my Vouch promise — ${track.promise}.',
                  ),
                ),
                _ContactAction(
                  icon: Icons.sms_rounded,
                  label: 'SMS',
                  color: VouchColors.coral,
                  enabled: track.partnerPhone?.trim().isNotEmpty ?? false,
                  onTap: () => showContactSheet(
                    context,
                    name: track.partnerFirstName,
                    phone: track.partnerPhone,
                    message:
                        'Hey ${track.partnerFirstName}, checking in on my Vouch promise — ${track.promise}.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const SectionHeader(
            index: '03',
            title: 'This week',
          ),
          ExpressiveCard(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: _WeekStrip(controller: controller),
          ),
          const SizedBox(height: 12),
          _StatsRow(controller: controller),
          const SizedBox(height: 22),
          Center(
            child: Text(
              partner == 'Your partner'
                  ? 'One promise. One witness.'
                  : 'Witnessed by $partner.',
              style: text.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WitnessStatus extends StatelessWidget {
  const _WitnessStatus({
    required this.controller,
    required this.track,
    required this.entry,
    required this.state,
  });

  final TrackController controller;
  final Track track;
  final DayEntry? entry;
  final VouchDayState state;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final marked = entry?.isMarked ?? false;
    final completed = entry?.status == DayStatus.completed;

    final color = completed
        ? const Color(0xFF5F9E1F)
        : marked
            ? VouchColors.coral
            : VouchColors.indigo;

    return ExpressiveCard(
      color: color.withValues(alpha: 0.08),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          VouchAvatar(
            name: track.partnerName ?? 'Partner',
            photoUrl: track.partnerPhotoUrl,
            size: 46,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        track.partnerName ?? 'Your partner',
                        style: text.titleSmall,
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
                const SizedBox(height: 5),
                Text(
                  !marked
                      ? (state == VouchDayState.rest
                          ? 'No mark needed today.'
                          : 'Waiting on their mark.')
                      : <String?>[
                          entry?.method?.label,
                          entry?.markedAt == null
                              ? null
                              : DateFormat('h:mm a')
                                  .format(entry!.markedAt!.toLocal()),
                        ].whereType<String>().join(' · '),
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (entry?.partnerNote?.trim().isNotEmpty ?? false) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    '“${entry!.partnerNote!.trim()}”',
                    style: text.bodyMedium?.copyWith(height: 1.45),
                  ),
                ],
              ],
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
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final entry = controller.todayEntry;
    final state = controller.dayState(controller.today);
    final marked = entry?.isMarked ?? false;
    final completed = entry?.status == DayStatus.completed;
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
          const SizedBox(height: 26),
          _PromiseHero(track: track),
          const SizedBox(height: 32),
          SectionHeader(
            index: '01',
            title: 'Today',
            subtitle: marked ? null : 'Check in, then mark it.',
          ),
          if (!marked)
            InkCard(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: VouchColors.indigo.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          state == VouchDayState.rest
                              ? Icons.nights_stay_rounded
                              : Icons.visibility_rounded,
                          color: VouchColors.indigo,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              state == VouchDayState.rest
                                  ? 'Rest day'
                                  : 'Did ${track.ownerFirstName} keep it?',
                              style: text.titleLarge,
                            ),
                            const SizedBox(height: 2),
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
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      _ContactAction(
                        icon: Icons.call_rounded,
                        label: 'Call',
                        color: VouchColors.indigo,
                        enabled: track.ownerPhone?.trim().isNotEmpty ?? false,
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
                        color: const Color(0xFF25D366),
                        enabled: track.ownerPhone?.trim().isNotEmpty ?? false,
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
                        enabled: track.ownerPhone?.trim().isNotEmpty ?? false,
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
              borderColor: (completed
                      ? const Color(0xFF5F9E1F)
                      : VouchColors.coral)
                  .withValues(alpha: 0.45),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        completed
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: completed
                            ? const Color(0xFF4C7A16)
                            : VouchColors.coral,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              completed ? 'Kept' : 'Missed',
                              style: text.titleLarge,
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
                          icon: const Icon(Icons.edit_rounded, size: 19),
                          label: const Text('Change mark'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
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
          const SizedBox(height: 12),
          const NotificationPermissionCard(),
          const SizedBox(height: 30),
          SectionHeader(
            index: (entry?.hasNote ?? false) ? '03' : '02',
            title: 'This week',
          ),
          ExpressiveCard(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: _WeekStrip(controller: controller),
          ),
          const SizedBox(height: 12),
          _StatsRow(controller: controller),
          const SizedBox(height: 22),
          Center(
            child: Text(
              'Witness, not judge.',
              style: text.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small layout helper
// ---------------------------------------------------------------------------

class _NoteCallout extends StatelessWidget {
  const _NoteCallout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: child,
    );
  }
}
