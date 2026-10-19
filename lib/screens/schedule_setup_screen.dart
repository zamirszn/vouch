/// The partner chooses days, time and timezone; the owner sees a waiting state.
/// Both are printed on sage.
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
import '../widgets/contact_sheet.dart';
import '../widgets/poster.dart';
import '../widgets/pressable_spring.dart';
import '../widgets/sheet_frame.dart';
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
    _timeZone =
        schedule?.timeZone ?? context.read<NotificationService>().localTimeZone;
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
        body: PosterField(
          tone: PosterTone.sage,
          child: Center(child: VouchLoader(size: 22, color: PosterColors.ink)),
        ),
      );
    }
    if (!controller.isPartner) {
      return _OwnerWaiting(track: track);
    }

    final schedule = VouchSchedule(
      kind: _kind,
      hour: _time.hour,
      minute: _time.minute,
      timeZone: _timeZone,
    );
    final next = nextReminderAt(schedule);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      body: PosterField(
        tone: PosterTone.sage,
        child: Builder(
          builder: (context) {
            final style = PosterStyle.of(context);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (canPop)
                    const PosterBackBar(
                      right: '(003) / the rhythm',
                      icon: Icons.close_rounded,
                    )
                  else
                    const PosterTopBar(right: '(003) / the rhythm'),
                  const SizedBox(height: 28),
                  PosterHeadline('Set the\nrhythm.', size: 46, accentTail: 1),
                  const SizedBox(height: 12),
                  Text(
                    'Witnessing ${track.ownerFirstName}’s promise. Both phones buzz together.',
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      fontSize: 14,
                      height: 1.4,
                      color: style.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PosterCard(
                    color: PosterColors.cobalt,
                    foreground: PosterColors.cream,
                    padding: const EdgeInsets.all(16),
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
                              PosterLabel(
                                'The promise',
                                color: PosterColors.cream.withValues(
                                  alpha: 0.62,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                track.promise,
                                style: const TextStyle(
                                  fontFamily: 'InstrumentSans',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                  letterSpacing: -0.2,
                                  color: PosterColors.cream,
                                  fontVariations: <FontVariation>[
                                    FontVariation('wght', 600),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const PosterSectionLabel(
                    '01',
                    'Which days?',
                    uppercase: false,
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 26),
                  const PosterSectionLabel(
                    '02',
                    'What time?',
                    uppercase: false,
                  ),
                  const SizedBox(height: 10),
                  PosterCard(
                    onTap: _pickTime,
                    padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              PosterLabel(
                                'Reminder · both phones',
                                color: style.cardMuted,
                                size: 8.5,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _time.format(context),
                                style: TextStyle(
                                  fontFamily: 'InstrumentSans',
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  height: 0.95,
                                  letterSpacing: -1.6,
                                  color: style.cardInk,
                                  fontVariations: const <FontVariation>[
                                    FontVariation('wght', 700),
                                    FontVariation('wdth', 94),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _RoundArrow(
                          color: style.cardInk,
                          foreground: style.card,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  PosterCard(
                    onTap: _pickTimeZone,
                    padding: const EdgeInsets.fromLTRB(16, 13, 10, 13),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              PosterLabel(
                                'Timezone',
                                color: style.cardMuted,
                                size: 8.5,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _timeZone.replaceAll('_', ' '),
                                style: TextStyle(
                                  fontFamily: 'InstrumentSans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                  color: style.cardInk,
                                  fontVariations: const <FontVariation>[
                                    FontVariation('wght', 600),
                                  ],
                                ),
                              ),
                              Text(
                                '${DateTime.now().timeZoneName} on this phone',
                                style: TextStyle(
                                  fontFamily: 'InstrumentSans',
                                  fontSize: 11.5,
                                  color: style.cardMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _RoundArrow(
                          color: style.soft,
                          foreground: style.cardInk,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PosterCard(
                    color: style.pill,
                    foreground: style.pillInk,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: style.dark
                                ? PosterColors.cobalt
                                : PosterColors.acid,
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
                                style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  fontSize: 9,
                                  letterSpacing: 1.1,
                                  color: style.pillInk.withValues(alpha: 0.72),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Both phones buzz in ${_timeZone.replaceAll('_', ' ')}.',
                                style: TextStyle(
                                  fontFamily: 'InstrumentSans',
                                  fontSize: 12.5,
                                  height: 1.35,
                                  color: style.pillInk,
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
                      style: TextStyle(
                        fontFamily: 'InstrumentSans',
                        fontSize: 12.5,
                        height: 1.4,
                        color: style.dark
                            ? PosterColors.coral
                            : const Color(0xFF8E2A22),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  PosterPill(
                    label: _saving
                        ? 'Saving…'
                        : track.schedule == null
                        ? 'Activate the promise'
                        : 'Update the schedule',
                    onPressed: _saving ? null : _save,
                  ),
                  const SizedBox(height: 22),
                  const PosterFooter(
                    lead: 'Witness, not judge.',
                    muted: 'You set the rhythm together.',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoundArrow extends StatelessWidget {
  const _RoundArrow({required this.color, required this.foreground});

  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(Icons.arrow_outward_rounded, color: foreground, size: 19),
    );
  }
}

class _OwnerWaiting extends StatelessWidget {
  const _OwnerWaiting({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrackController>();

    return Scaffold(
      body: PosterField(
        tone: PosterTone.sage,
        child: Builder(
          builder: (context) {
            final style = PosterStyle.of(context);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const PosterTopBar(right: '(003) / the rhythm'),
                  const SizedBox(height: 28),
                  PosterHeadline(
                    '${track.partnerFirstName} is\nsetting the rhythm.',
                    size: 40,
                    accentTail: 1,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'They choose the days and the time. Then both phones start reminding together.',
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      fontSize: 14,
                      height: 1.4,
                      color: style.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PosterCard(
                    padding: const EdgeInsets.all(16),
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
                                    style: TextStyle(
                                      fontFamily: 'InstrumentSans',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                      color: style.cardInk,
                                      fontVariations: const <FontVariation>[
                                        FontVariation('wght', 600),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Choosing the days',
                                    style: TextStyle(
                                      fontFamily: 'InstrumentSans',
                                      fontSize: 12,
                                      color: style.cardMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: PosterColors.acid,
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                '?',
                                style: TextStyle(
                                  fontFamily: 'InstrumentSans',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: PosterColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(height: 1, color: style.line),
                        const SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: PosterColors.coral,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Nothing buzzes until the rhythm is set.',
                                style: TextStyle(
                                  fontFamily: 'InstrumentSans',
                                  fontSize: 12,
                                  color: style.cardMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PosterPill(
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
                      style: const TextStyle(
                        fontFamily: 'InstrumentSans',
                        fontSize: 12,
                        color: Color(0xFF8E2A22),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const PosterFooter(
                    lead: 'Witness, not judge.',
                    muted: 'The rhythm is their call.',
                  ),
                ],
              ),
            );
          },
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
    final style = PosterStyle.of(context);
    final fg = selected ? style.pillInk : style.cardInk;
    final accent = selected
        ? (style.dark ? PosterColors.cobalt : PosterColors.acid)
        : PosterColors.cobalt;
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
          color: selected ? style.pill : style.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? style.pill : style.line,
            width: 1,
          ),
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
                      height: kind.includes(day) ? 22 : 10,
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
              style: TextStyle(
                fontFamily: 'InstrumentSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: fg,
                fontVariations: const <FontVariation>[
                  FontVariation('wght', 600),
                ],
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '${week.where(kind.includes).length} days',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 8.5,
                letterSpacing: 0.8,
                color: fg.withValues(alpha: 0.55),
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
                            color: PosterColors.cobalt,
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
                style: const TextStyle(
                  fontFamily: 'InstrumentSans',
                  fontSize: 13,
                  color: PosterColors.ink,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
