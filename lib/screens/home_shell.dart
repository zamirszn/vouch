/// The signed-in shell: Today, History and Settings.
library;

import 'dart:async';

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
import '../widgets/status_pill.dart';
import '../widgets/vouch_avatar.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final PageController _pages = PageController();
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
    _pages.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _index) {
      if (_pages.hasClients) {
        _pages.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }
    setState(() => _index = index);
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
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
          child: PageView(
            controller: _pages,
            onPageChanged: (index) => setState(() => _index = index),
            children: <Widget>[
              isPartner ? const _PartnerHome() : const _OwnerHome(),
              const HistoryScreen(),
              const SettingsScreen(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt_rounded),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'You',
          ),
        ],
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 118),
      child: child,
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow({
    required this.eyebrow,
    required this.title,
    required this.name,
    required this.photoUrl,
  });

  final String eyebrow;
  final String title;
  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                eyebrow.toUpperCase(),
                style: text.labelSmall?.copyWith(
                  color: VouchColors.indigo,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(title, style: text.headlineSmall),
              if (name.isNotEmpty)
                Text(
                  name,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        VouchAvatar(name: name, photoUrl: photoUrl, size: 46, ring: true),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: text.headlineSmall?.copyWith(color: color, fontSize: 26),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: text.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.controller});

  final TrackController controller;

  @override
  Widget build(BuildContext context) {
    final stats = controller.stats;
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatTile(
            label: 'Best streak',
            value: '${stats.bestStreak}',
            color: VouchColors.indigo,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Days kept',
            value: '${stats.completed}',
            color: const Color(0xFF4C7A16),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Kept rate',
            value: stats.elapsed == 0 ? '—' : '${stats.completionPercent}%',
            color: VouchColors.coral,
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
                  color: color.withValues(alpha: enabled ? 0.14 : 0.06),
                  shape: BoxShape.circle,
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

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.controller});

  final TrackController controller;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final schedule = controller.track?.schedule;
    final next = controller.nextReminder;
    final remaining = controller.timeToNextReminder;

    return ExpressiveCard(
      color: VouchColors.indigo.withValues(alpha: 0.08),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: VouchColors.indigo.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: VouchColors.indigo,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  schedule == null
                      ? 'No reminder set'
                      : '${schedule.kind.label} · ${schedule.clockLabel}',
                  style: text.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  next == null || remaining == null
                      ? 'Both phones buzz together once a schedule is set.'
                      : 'Next ${DateFormat('EEE d MMM').format(next)} · ${countdownLabel(remaining)}',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (schedule != null)
            Text(
              schedule.zoneLabel,
              style: text.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
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
      return const Center(child: CircularProgressIndicator());
    }
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final state = controller.dayState(controller.today);
    final entry = controller.todayEntry;
    final stats = controller.stats;
    final hour = nowIn(track.schedule?.timeZone).hour;
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
          _GreetingRow(
            eyebrow: greetingForHour(hour),
            title: track.ownerFirstName,
            name: 'Vouch · one promise',
            photoUrl: track.ownerPhotoUrl,
          ),
          const SizedBox(height: 26),
          Reveal(
            child: Text(
              track.promise,
              style: text.displaySmall?.copyWith(
                fontSize: 34,
                height: 1.09,
                letterSpacing: -0.8,
              ),
            ),
          ),
          if (track.promiseNote?.trim().isNotEmpty ?? false) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              '“${track.promiseNote!.trim()}”',
              style: text.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Center(
            child: PromiseOrb(
              state: state,
              streak: stats.currentStreak,
              completion: stats.completionRate,
              caption: caption,
              size: 238,
            ),
          ),
          const SizedBox(height: 18),
          _ReminderCard(controller: controller),
          const SizedBox(height: 12),
          const NotificationPermissionCard(),
          const SizedBox(height: 26),
          SectionHeader(
            title: 'What I did today',
            subtitle: 'Write it before ${track.partnerFirstName} checks in.',
            trailing: entry?.hasNote ?? false
                ? TextButton(
                    onPressed: () => _editNote(controller, track),
                    child: const Text('Edit'),
                  )
                : null,
          ),
          if (state == VouchDayState.rest)
            const _NoteCallout(
              child: SheetNote(
                icon: Icons.self_improvement_rounded,
                text:
                    'No promise is scheduled today. You can still add a note if you did it anyway.',
              ),
            ),
          if (entry?.hasNote ?? false)
            NotePreview(note: entry?.note)
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _editNote(controller, track),
                icon: const Icon(Icons.edit_note_rounded, size: 22),
                label: const Text('Write today’s note'),
              ),
            ),
          const SizedBox(height: 26),
          SectionHeader(
            title: 'Witness',
            subtitle: entry?.isMarked ?? false
                ? 'Today is settled.'
                : '${track.partnerFirstName} has the final word.',
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
            title: 'This week',
            subtitle: 'Tap a day to see the full story.',
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
                          ? 'No mark needed on a rest day.'
                          : 'Hasn’t marked today yet. They may call or message first.')
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
      return const Center(child: CircularProgressIndicator());
    }
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final entry = controller.todayEntry;
    final state = controller.dayState(controller.today);
    final marked = entry?.isMarked ?? false;
    final completed = entry?.status == DayStatus.completed;
    final hour = nowIn(track.schedule?.timeZone).hour;
    final message =
        'Hey ${track.ownerFirstName}, checking in on your Vouch promise: ${track.promise}. Did you get it done today?';

    return _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _GreetingRow(
            eyebrow: 'Witnessing · ${greetingForHour(hour)}',
            title: track.ownerFirstName,
            name: 'Your promise partner',
            photoUrl: track.ownerPhotoUrl,
          ),
          const SizedBox(height: 24),
          ExpressiveCard(
            color: VouchColors.indigo,
            border: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'THE PROMISE',
                  style: text.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  track.promise,
                  style: text.headlineMedium?.copyWith(
                    color: Colors.white,
                    height: 1.12,
                  ),
                ),
                if (track.promiseNote?.trim().isNotEmpty ?? false) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    '“${track.promiseNote!.trim()}”',
                    style: text.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Today',
            subtitle: marked
                ? 'Your mark is in. You can change it if something new comes up.'
                : 'Check in first. Then mark what actually happened.',
          ),
          if (!marked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    VouchColors.indigo.withValues(alpha: 0.16),
                    VouchColors.indigo.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: VouchColors.indigo.withValues(alpha: 0.22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: VouchColors.indigo.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.visibility_rounded,
                          color: VouchColors.indigo,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              state == VouchDayState.rest
                                  ? 'Rest day'
                                  : 'Waiting on your witness',
                              style: text.titleMedium,
                            ),
                            Text(
                              state == VouchDayState.rest
                                  ? 'No promise is scheduled today.'
                                  : 'Ask ${track.ownerFirstName} about it, then record the answer.',
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
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _mark(context),
                      icon: const Icon(Icons.fact_check_rounded),
                      label: const Text('Mark today'),
                    ),
                  ),
                ],
              ),
            )
          else
            ExpressiveCard(
              color: (completed ? const Color(0xFF5F9E1F) : VouchColors.coral)
                  .withValues(alpha: 0.09),
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
                        size: 34,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              completed ? 'Marked kept' : 'Marked missed',
                              style: text.titleMedium,
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
                      StatusPill.mark(entry!.status, dense: true),
                    ],
                  ),
                  if (entry.partnerNote?.trim().isNotEmpty ?? false) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      '“${entry.partnerNote!.trim()}”',
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
          const SizedBox(height: 26),
          SectionHeader(
            title: 'In their words',
            subtitle: entry?.hasNote ?? false
                ? 'Updated ${entry?.noteUpdatedAt == null ? 'recently' : DateFormat('h:mm a').format(entry!.noteUpdatedAt!.toLocal())}'
                : 'Nothing written down yet.',
          ),
          NotePreview(
            note: entry?.note,
            emptyLabel:
                '${track.ownerFirstName} hasn’t written what they did today.',
          ),
          const SizedBox(height: 24),
          _ReminderCard(controller: controller),
          const SizedBox(height: 12),
          const NotificationPermissionCard(),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'This week',
            subtitle: 'Seven days of keeping your word.',
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
