/// The partner chooses days, time and timezone; the owner sees a waiting state.
library;

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/date_utils.dart';
import '../models/schedule.dart';
import '../models/track.dart';
import '../services/notification_service.dart';
import '../state/track_controller.dart';
import '../theme/vouch_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/contact_sheet.dart';
import '../widgets/pressable_spring.dart';
import '../widgets/section_header.dart';
import '../widgets/sheet_frame.dart';
import '../widgets/soul.dart';
import '../widgets/vouch_avatar.dart';
import '../widgets/vouch_loader.dart';

class ScheduleSetupScreen extends StatefulWidget {
  const ScheduleSetupScreen({super.key});

  @override
  State<ScheduleSetupScreen> createState() => _ScheduleSetupScreenState();
}

class _ScheduleSetupScreenState extends State<ScheduleSetupScreen> {
  late ScheduleKind _kind;
  late TimeOfDay _time;
  late String _timeZone;
  bool _saving = false;
  String? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final track = context.read<TrackController>().track;
    final schedule = track?.schedule;
    _kind = schedule?.kind ?? ScheduleKind.daily;
    _time = schedule == null
        ? const TimeOfDay(hour: 19, minute: 30)
        : TimeOfDay(hour: schedule.hour, minute: schedule.minute);
    _timeZone = schedule?.timeZone ??
        context.read<NotificationService>().localTimeZone;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'When should both phones buzz?',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _time = picked);
    }
  }

  Future<void> _pickTimeZone() async {
    List<String> zones;
    try {
      final available = await FlutterTimezone.getAvailableTimezones();
      zones = available.map((zone) => zone.identifier).toList()..sort();
    } catch (_) {
      zones = <String>[_timeZone, 'UTC', 'Africa/Lagos', 'Europe/London'];
    }
    if (!mounted) return;
    final picked = await showVouchSheet<String>(
      context,
      _TimeZonePicker(zones: zones, current: _timeZone),
    );
    if (picked != null && mounted) {
      setState(() => _timeZone = picked);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final schedule = VouchSchedule(
      kind: _kind,
      hour: _time.hour,
      minute: _time.minute,
      timeZone: _timeZone,
    );
    final error = await context.read<TrackController>().saveSchedule(schedule);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    setState(() => _saving = false);
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrackController>();
    final track = controller.track;
    if (track == null) {
      return const Scaffold(
        body: Center(child: VouchLoader(size: 22)),
      );
    }
    if (!controller.isPartner) {
      return _OwnerWaiting(track: track);
    }

    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final schedule = VouchSchedule(
      kind: _kind,
      hour: _time.hour,
      minute: _time.minute,
      timeZone: _timeZone,
    );
    final next = nextReminderAt(schedule);

    return Scaffold(
      body: AnimatedBackground(
        intensity: 0.8,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (Navigator.of(context).canPop())
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      )
                    else
                      const SizedBox(width: 48),
                    const Spacer(),
                    Text(
                      '(003) / THE RHYTHM',
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PageHeader(
                  eyebrow: 'Witness duty',
                  title: 'Set the',
                  titleMuted: 'rhythm.',
                  subtitle:
                      'Witnessing ${track.ownerFirstName}’s promise. Both phones buzz together.',
                  titleSize: 44,
                ),
                const SizedBox(height: 24),
                InkCard(
                  color: VouchColors.indigo,
                  border: false,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: CropMarks(
                    color: VouchColors.cream.withValues(alpha: 0.35),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        VouchAvatar(
                          name: track.ownerName,
                          photoUrl: track.ownerPhotoUrl,
                          size: 40,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'THE PROMISE',
                                style: text.labelSmall?.copyWith(
                                  color: VouchColors.cream.withValues(
                                    alpha: 0.62,
                                  ),
                                  letterSpacing: 1.6,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                track.promise,
                                style: text.titleMedium?.copyWith(
                                  color: VouchColors.cream,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const SectionHeader(
                  index: '01',
                  title: 'Which days?',
                  subtitle: 'The same pattern on both phones.',
                ),
                Row(
                  children: <Widget>[
                    for (final kind in ScheduleKind.values) ...<Widget>[
                      Expanded(
                        child: _KindCard(
                          kind: kind,
                          selected: _kind == kind,
                          onTap: () => setState(() => _kind = kind),
                        ),
                      ),
                      if (kind != ScheduleKind.values.last)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 28),
                const SectionHeader(index: '02', title: 'What time?'),
                InkCard(
                  onTap: _pickTime,
                  padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'REMINDER · BOTH PHONES',
                              style: text.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                letterSpacing: 1.4,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _time.format(context),
                              style: text.displaySmall?.copyWith(
                                fontSize: 36,
                                height: 0.95,
                                letterSpacing: -1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _RoundArrow(color: VouchColors.indigo),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                InkCard(
                  onTap: _pickTimeZone,
                  padding: const EdgeInsets.fromLTRB(18, 15, 16, 15),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'TIMEZONE',
                              style: text.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                letterSpacing: 1.4,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _timeZone.replaceAll('_', ' '),
                              style: text.titleMedium,
                            ),
                            Text(
                              '${DateTime.now().timeZoneName} on this phone',
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _RoundArrow(color: VouchColors.mist),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                InkCard(
                  color: VouchColors.ink,
                  border: false,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: VouchColors.lime,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              next == null
                                  ? 'No upcoming reminder'
                                  : 'NEXT · ${DateFormat('EEE d MMM · h:mm a').format(next).toUpperCase()}',
                              style: text.labelSmall?.copyWith(
                                color: VouchColors.cream.withValues(alpha: 0.72),
                                letterSpacing: 1.1,
                                fontSize: 9.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Both phones buzz in ${_timeZone.replaceAll('_', ' ')}.',
                              style: text.bodySmall?.copyWith(
                                color: VouchColors.cream,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: text.bodyMedium?.copyWith(color: scheme.error),
                  ),
                ],
                const SizedBox(height: 22),
                SoulButton(
                  label: _saving
                      ? 'Saving…'
                      : track.schedule == null
                          ? 'Activate the promise'
                          : 'Update the schedule',
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundArrow extends StatelessWidget {
  const _RoundArrow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const Icon(
        Icons.arrow_outward_rounded,
        color: VouchColors.cream,
        size: 19,
      ),
    );
  }
}

class _OwnerWaiting extends StatelessWidget {
  const _OwnerWaiting({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final controller = context.watch<TrackController>();

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                PageHeader(
                  eyebrow: 'Witness duty',
                  title: '${track.partnerFirstName} is',
                  titleMuted: 'setting the rhythm.',
                  index: '(003)',
                  subtitle:
                      'They choose the days and the time. Then both phones start reminding together.',
                  titleSize: 40,
                ),
                const SizedBox(height: 26),
                InkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                Text(
                                  'Choosing the days',
                                  style: text.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          LetterBadge(
                            letter: '?',
                            color: VouchColors.lime,
                            foreground: VouchColors.ink,
                            size: 34,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const DashRule(),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Container(
                            width: 6,
                            height: 6,
                            color: VouchColors.coral,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Nothing buzzes until the rhythm is set.',
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SoulButton(
                  label: 'Message ${track.partnerFirstName}',
                  compact: true,
                  expand: false,
                  height: 52,
                  onPressed: () => showContactSheet(
                    context,
                    name: track.partnerFirstName,
                    phone: track.partnerPhone,
                    message:
                        'Hey ${track.partnerFirstName}, can you set our Vouch schedule when you get a minute?',
                  ),
                ),
                if (controller.error != null) ...<Widget>[
                  const SizedBox(height: 14),
                  Text(
                    controller.error!,
                    style: text.bodySmall?.copyWith(color: scheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final ScheduleKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? VouchColors.cream : scheme.onSurface;
    final accent = selected ? VouchColors.lime : VouchColors.indigo;
    // 1 Jan 2024 was a Monday, so this walks the week from Mon to Sun.
    final week = <DateTime>[
      for (var i = 0; i < 7; i++) DateTime(2024, 1, 1 + i),
    ];

    return PressableSpring(
      onTap: onTap,
      pressedScale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 104,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
        decoration: BoxDecoration(
          color: selected ? VouchColors.ink : VouchColors.cream,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? VouchColors.ink
                : scheme.onSurface.withValues(alpha: 0.14),
            width: 1.2,
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.2),
                    offset: const Offset(3, 3),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  for (final day in week) ...<Widget>[
                    Container(
                      width: 3,
                      height: kind.includes(day)
                          ? 22
                          : 10,
                      color: kind.includes(day)
                          ? accent
                          : fg.withValues(alpha: 0.22),
                    ),
                    if (day != week.last) const SizedBox(width: 3),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              kind.shortLabel,
              maxLines: 1,
              style: text.titleSmall?.copyWith(color: fg, fontSize: 13),
            ),
            const SizedBox(height: 1),
            Text(
              '${week.where(kind.includes).length} days',
              style: text.labelSmall?.copyWith(
                color: fg.withValues(alpha: 0.55),
                fontSize: 8.5,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeZonePicker extends StatefulWidget {
  const _TimeZonePicker({required this.zones, required this.current});

  final List<String> zones;
  final String current;

  @override
  State<_TimeZonePicker> createState() => _TimeZonePickerState();
}

class _TimeZonePickerState extends State<_TimeZonePicker> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zones = widget.zones
        .where((zone) => zone.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final text = Theme.of(context).textTheme;

    return SheetFrame(
      title: 'Timezone',
      subtitle: 'Use the timezone the reminder should follow.',
      child: Column(
        children: <Widget>[
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              hintText: 'Search timezones',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 360,
            child: ListView.builder(
              itemCount: zones.length,
              itemBuilder: (context, index) {
                final zone = zones[index];
                final selected = zone == widget.current;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  selected: selected,
                  title: Text(zone.replaceAll('_', ' ')),
                  trailing: selected
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: VouchColors.indigo,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(zone),
                );
              },
            ),
          ),
          if (zones.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No timezone matches “$_query”.',
                style: text.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}
