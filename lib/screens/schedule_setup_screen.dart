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
import '../widgets/brand_mark.dart';
import '../widgets/contact_sheet.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/sheet_frame.dart';
import '../widgets/vouch_avatar.dart';

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
        body: Center(child: CircularProgressIndicator()),
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
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const BrandMark(size: 42, animate: false, showShadow: false),
                    const SizedBox(width: 10),
                    Text('Vouch', style: text.titleLarge),
                    const Spacer(),
                    if (Navigator.of(context).canPop())
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                Reveal(
                  child: Text(
                    'Set the rhythm.',
                    style: text.displaySmall?.copyWith(
                      fontSize: 40,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You are the witness for ${track.ownerFirstName}. Both phones will be nudged at the same moment.',
                  style: text.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                ExpressiveCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          VouchAvatar(
                            name: track.ownerName,
                            photoUrl: track.ownerPhotoUrl,
                            size: 42,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              track.promise,
                              style: text.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                const SectionHeader(
                  title: 'Which days?',
                  subtitle: 'Only these days count toward the streak.',
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final kind in ScheduleKind.values)
                      ChoiceChip(
                        selected: _kind == kind,
                        onSelected: (_) => setState(() => _kind = kind),
                        label: Text(kind.label),
                        avatar: Icon(
                          switch (kind) {
                            ScheduleKind.daily => Icons.calendar_view_day_rounded,
                            ScheduleKind.weekdays => Icons.work_rounded,
                            ScheduleKind.weekends => Icons.weekend_rounded,
                          },
                          size: 18,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 26),
                const SectionHeader(title: 'What time?'),
                _SettingTile(
                  icon: Icons.schedule_rounded,
                  title: _time.format(context),
                  subtitle: 'Reminder time',
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: _pickTime,
                ),
                const SizedBox(height: 10),
                _SettingTile(
                  icon: Icons.public_rounded,
                  title: _timeZone.replaceAll('_', ' '),
                  subtitle:
                      'Timezone · ${DateTime.now().timeZoneName} on this phone',
                  trailing: const Icon(Icons.unfold_more_rounded),
                  onTap: _pickTimeZone,
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: VouchColors.indigo.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.notifications_active_rounded,
                        color: VouchColors.indigo,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              next == null
                                  ? 'No upcoming reminder'
                                  : 'Next: ${DateFormat('EEE d MMM · h:mm a').format(next)}',
                              style: text.titleSmall,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Both phones schedule locally in ${_timeZone.replaceAll('_', ' ')}. The owner’s phone updates when they next open Vouch.',
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.bolt_rounded),
                    label: Text(
                      _saving
                          ? 'Saving…'
                          : track.schedule == null
                              ? 'Activate the promise'
                              : 'Update the schedule',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'You can change this later in Settings.',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: <Widget>[
                const Spacer(),
                const BrandMark(size: 96),
                const SizedBox(height: 26),
                Text(
                  '${track.partnerFirstName} is setting\nthe rhythm.',
                  textAlign: TextAlign.center,
                  style: text.displaySmall?.copyWith(
                    fontSize: 36,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'They’ll choose the days and the time. Then both phones start reminding together.',
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                ExpressiveCard(
                  child: Row(
                    children: <Widget>[
                      VouchAvatar(
                        name: track.partnerName ?? 'Partner',
                        photoUrl: track.partnerPhotoUrl,
                        size: 44,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          track.partnerName ?? 'Your partner',
                          style: text.titleMedium,
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => showContactSheet(
                          context,
                          name: track.partnerFirstName,
                          phone: track.partnerPhone,
                          message:
                              'Hey ${track.partnerFirstName}, can you set our Vouch schedule when you get a minute?',
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (controller.error != null)
                  Text(
                    controller.error!,
                    style: text.bodySmall?.copyWith(color: scheme.error),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: VouchColors.indigo),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: text.titleMedium),
                    Text(
                      subtitle,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  selected: selected,
                  title: Text(zone.replaceAll('_', ' ')),
                  trailing: selected
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.of(context).pop(zone),
                );
              },
            ),
          ),
          if (zones.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No timezone matches “$_query”.', style: text.bodyMedium),
            ),
        ],
      ),
    );
  }
}
