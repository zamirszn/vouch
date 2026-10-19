/// The partner chooses days, time and timezone; the owner sees a waiting state.
/// Rebuilt on the atmospheric dashboard language, no Material.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../components/contact_panel.dart';
import '../components/glass_card.dart';
import '../components/pressable.dart';
import '../components/reveal.dart';
import '../components/section_label.dart';
import '../components/vouch_button.dart';
import '../components/vouch_field.dart';
import '../components/vouch_icon.dart';
import '../components/vouch_loader.dart';
import '../components/vouch_scaffold.dart';
import '../components/vouch_sheet.dart';
import '../components/vouch_time_wheel.dart';
import '../components/vouch_top_bar.dart';
import '../core/date_utils.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import '../models/schedule.dart';
import '../models/track.dart';
import '../services/notification_service.dart';
import '../state/track_controller.dart';

class ScheduleSetupScreen extends StatefulWidget {
  const ScheduleSetupScreen({super.key});

  @override
  State<ScheduleSetupScreen> createState() => _ScheduleSetupScreenState();
}

class _ScheduleSetupScreenState extends State<ScheduleSetupScreen> {
  late ScheduleKind _kind;
  late int _hour;
  late int _minute;
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
    _hour = schedule?.hour ?? 19;
    _minute = schedule?.minute ?? 30;
    _timeZone =
        schedule?.timeZone ?? context.read<NotificationService>().localTimeZone;
  }

  Future<void> _pickTime() async {
    final picked = await showVouchTimeWheel(
      context,
      hour: _hour,
      minute: _minute,
    );
    if (picked != null && mounted) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
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
    final picked = await showVouchPanel<String>(
      context,
      (_) => _TimeZonePicker(zones: zones, current: _timeZone),
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
      hour: _hour,
      minute: _minute,
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
    final theme = VouchScope.of(context);

    if (track == null) {
      return VouchScaffold(
        tone: VouchTone.pending,
        body: Center(child: VouchLoader(size: 22, color: theme.ink)),
      );
    }
    if (!controller.isPartner) {
      return _OwnerWaiting(track: track);
    }

    final schedule = VouchSchedule(
      kind: _kind,
      hour: _hour,
      minute: _minute,
      timeZone: _timeZone,
    );
    final next = nextReminderAt(schedule);
    final canPop = Navigator.of(context).canPop();

    return VouchScaffold(
      tone: VouchTone.pending,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            VouchSpace.gutter,
            VouchSpace.x2,
            VouchSpace.gutter,
            MediaQuery.viewPaddingOf(context).bottom + VouchSpace.x8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (canPop)
                const VouchCloseBar(annotation: '(003) / RHYTHM')
              else
                const VouchTopBar(annotation: '(003) / RHYTHM'),
              const SizedBox(height: VouchSpace.x6),
              Reveal(
                index: 0,
                child: Text(
                  'Set the\nrhythm.',
                  style: VouchType.hero(theme.ink).copyWith(
                    fontSize: 46,
                    height: 0.94,
                  ),
                ),
              ),
              const SizedBox(height: VouchSpace.x3),
              Reveal(
                index: 1,
                child: Text(
                  'Witnessing ${track.ownerFirstName}’s promise. '
                  'Both phones buzz together.',
                  style: VouchType.body(theme.muted)
                      .copyWith(fontSize: 14, height: 1.4),
                ),
              ),
              const SizedBox(height: VouchSpace.x5),
              Reveal(
                index: 2,
                child: GlassCard(
                  radius: VouchRadius.card,
                  padding: const EdgeInsets.all(16),
                  tint: theme.pending,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      VouchAvatar(
                        initials: _initials(track.ownerName),
                        size: 40,
                      ),
                      const SizedBox(width: VouchSpace.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'THE PROMISE',
                              style: VouchType.label(theme.muted, size: 8.5),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              track.promise,
                              style: VouchType.bodyStrong(theme.ink)
                                  .copyWith(fontSize: 15, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: VouchSpace.x6),
              const Reveal(
                index: 3,
                child: SectionLabel(
                  index: '01',
                  title: 'Which days?',
                  preserveCase: true,
                ),
              ),
              const SizedBox(height: VouchSpace.x3),
              Reveal(
                index: 4,
                child: _DayPattern(
                  kind: _kind,
                  onKind: (kind) => setState(() => _kind = kind),
                ),
              ),
              const SizedBox(height: VouchSpace.x6),
              const Reveal(
                index: 5,
                child: SectionLabel(
                  index: '02',
                  title: 'What time?',
                  preserveCase: true,
                ),
              ),
              const SizedBox(height: VouchSpace.x3),
              Reveal(
                index: 6,
                child: GlassCard(
                  radius: VouchRadius.card,
                  padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                  onTap: _pickTime,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'REMINDER · BOTH PHONES',
                              style: VouchType.label(theme.muted, size: 8.5),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              vouchClockLabel(_hour, _minute),
                              style: VouchType.hero(theme.ink).copyWith(
                                fontSize: 38,
                                height: 1,
                                letterSpacing: -1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircleAction(
                        glyph: VouchGlyph.clock,
                        size: 46,
                        background: theme.ink,
                        foreground: theme.canvas,
                        border: theme.ink,
                        semanticLabel: 'Change time',
                        onTap: _pickTime,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: VouchSpace.x2),
              Reveal(
                index: 7,
                child: GlassCard(
                  radius: VouchRadius.medium,
                  padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                  onTap: _pickTimeZone,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'TIMEZONE',
                              style: VouchType.label(theme.muted, size: 8.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _timeZone.replaceAll('_', ' '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: VouchType.bodyStrong(theme.ink)
                                  .copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${DateTime.now().timeZoneName} on this phone',
                              style: VouchType.caption(theme.muted)
                                  .copyWith(fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      CircleAction(
                        glyph: VouchGlyph.arrowUpRight,
                        size: 40,
                        background: theme.glassStrong,
                        foreground: theme.ink,
                        border: theme.line,
                        semanticLabel: 'Change timezone',
                        onTap: _pickTimeZone,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: VouchSpace.x4),
              Reveal(
                index: 8,
                child: GlassCard(
                  radius: VouchRadius.medium,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  tint: theme.kept,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: theme.kept,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: VouchSpace.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              next == null
                                  ? 'NO UPCOMING REMINDER'
                                  : 'NEXT · ${DateFormat('EEE d MMM · h:mm a').format(next).toUpperCase()}',
                              style: VouchType.label(theme.ink, size: 9),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Both phones buzz in '
                              '${_timeZone.replaceAll('_', ' ')}.',
                              style: VouchType.caption(theme.muted)
                                  .copyWith(fontSize: 12.5, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: VouchSpace.x3),
                Text(
                  _error!,
                  style: VouchType.caption(theme.missed)
                      .copyWith(fontSize: 12.5, height: 1.4),
                ),
              ],
              const SizedBox(height: VouchSpace.x5),
              Reveal(
                index: 9,
                child: VouchButton(
                  label: _saving
                      ? 'Saving…'
                      : track.schedule == null
                          ? 'Activate the promise'
                          : 'Update the schedule',
                  expand: true,
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ),
              const SizedBox(height: VouchSpace.x6),
              Container(height: 1, color: theme.line),
              const SizedBox(height: VouchSpace.x4),
              Text('Witness, not judge.', style: VouchType.body(theme.muted)),
              const SizedBox(height: 4),
              Text(
                'You set the rhythm together.',
                style: VouchType.caption(theme.faint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A week strip that shows the active days, with the three patterns below it.
class _DayPattern extends StatelessWidget {
  const _DayPattern({required this.kind, required this.onKind});

  final ScheduleKind kind;
  final ValueChanged<ScheduleKind> onKind;

  static const List<String> _letters = <String>[
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];
  static const List<String> _names = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    // 1 Jan 2024 was a Monday, so this walks the week from Mon to Sun.
    final week = <DateTime>[
      for (var i = 0; i < 7; i++) DateTime(2024, 1, 1 + i),
    ];

    return GlassCard(
      radius: VouchRadius.card,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              for (var i = 0; i < week.length; i++)
                Expanded(
                  child: Semantics(
                    label: _names[i],
                    selected: kind.includes(week[i]),
                    child: Column(
                      children: <Widget>[
                        Text(
                          _letters[i],
                          style: VouchType.mono(
                            kind.includes(week[i])
                                ? theme.ink
                                : theme.faint,
                            size: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          width: 26,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: kind.includes(week[i])
                                ? theme.accent
                                : theme.glass,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: kind.includes(week[i])
                                  ? theme.accent
                                  : theme.line,
                            ),
                          ),
                          child: Container(
                            width: 4,
                            height: kind.includes(week[i]) ? 18 : 6,
                            decoration: BoxDecoration(
                              color: kind.includes(week[i])
                                  ? VouchColors.paperInk
                                  : theme.faint,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: VouchSpace.x4),
          Row(
            children: <Widget>[
              for (final option in ScheduleKind.values) ...<Widget>[
                Expanded(
                  child: _KindPill(
                    kind: option,
                    selected: option == kind,
                    onTap: () => onKind(option),
                  ),
                ),
                if (option != ScheduleKind.values.last)
                  const SizedBox(width: VouchSpace.x2),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _KindPill extends StatelessWidget {
  const _KindPill({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final ScheduleKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return Pressable(
      onTap: onTap,
      scale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? theme.ink : theme.glass,
          borderRadius: BorderRadius.circular(VouchRadius.pill),
          border: Border.all(
            color: selected ? theme.ink : theme.line,
          ),
        ),
        child: Text(
          kind.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: VouchType.bodyStrong(
            selected ? theme.canvas : theme.muted,
          ).copyWith(fontSize: 12),
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
    final controller = context.watch<TrackController>();
    final theme = VouchScope.of(context);

    return VouchScaffold(
      tone: VouchTone.pending,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            VouchSpace.gutter,
            VouchSpace.x2,
            VouchSpace.gutter,
            MediaQuery.viewPaddingOf(context).bottom + VouchSpace.x8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (Navigator.of(context).canPop())
                const VouchCloseBar(annotation: '(003) / RHYTHM')
              else
                const VouchTopBar(annotation: '(003) / RHYTHM'),
              const SizedBox(height: VouchSpace.x6),
              Reveal(
                index: 0,
                child: Text(
                  '${track.partnerFirstName} is\nsetting the rhythm.',
                  style: VouchType.hero(theme.ink).copyWith(
                    fontSize: 40,
                    height: 0.96,
                  ),
                ),
              ),
              const SizedBox(height: VouchSpace.x3),
              Reveal(
                index: 1,
                child: Text(
                  'They choose the days and the time. Then both phones start '
                  'reminding together.',
                  style: VouchType.body(theme.muted)
                      .copyWith(fontSize: 14, height: 1.4),
                ),
              ),
              const SizedBox(height: VouchSpace.x5),
              Reveal(
                index: 2,
                child: GlassCard(
                  radius: VouchRadius.card,
                  padding: const EdgeInsets.all(16),
                  tint: theme.pending,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          VouchAvatar(
                            initials: _initials(
                              track.partnerName ?? 'Partner',
                            ),
                            size: 44,
                          ),
                          const SizedBox(width: VouchSpace.x3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  track.partnerName ?? 'Your partner',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: VouchType.bodyStrong(theme.ink)
                                      .copyWith(fontSize: 16),
                                ),
                                Text(
                                  'Choosing the days',
                                  style: VouchType.caption(theme.muted)
                                      .copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '?',
                              style: VouchType.title(VouchColors.paperInk)
                                  .copyWith(fontSize: 17),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: VouchSpace.x4),
                      Container(height: 1, color: theme.line),
                      const SizedBox(height: VouchSpace.x4),
                      Row(
                        children: <Widget>[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.missed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: VouchSpace.x3),
                          Expanded(
                            child: Text(
                              'Nothing buzzes until the rhythm is set.',
                              style: VouchType.caption(theme.muted)
                                  .copyWith(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: VouchSpace.x4),
              Reveal(
                index: 3,
                child: VouchButton(
                  label: 'Message ${track.partnerFirstName}',
                  style: VouchButtonStyle.glass,
                  expand: true,
                  height: 52,
                  glyph: VouchGlyph.message,
                  onPressed: () => showContactSheet(
                    context,
                    name: track.partnerFirstName,
                    phone: track.partnerPhone,
                    message:
                        'Hey ${track.partnerFirstName}, can you set our Vouch '
                        'schedule when you get a minute?',
                  ),
                ),
              ),
              if (controller.error != null) ...<Widget>[
                const SizedBox(height: VouchSpace.x3),
                Text(
                  controller.error!,
                  style: VouchType.caption(theme.missed)
                      .copyWith(fontSize: 12, height: 1.4),
                ),
              ],
              const SizedBox(height: VouchSpace.x6),
              Container(height: 1, color: theme.line),
              const SizedBox(height: VouchSpace.x4),
              Text('Witness, not judge.', style: VouchType.body(theme.muted)),
              const SizedBox(height: 4),
              Text(
                'The rhythm is their call.',
                style: VouchType.caption(theme.faint),
              ),
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
    final theme = VouchScope.of(context);
    final zones = widget.zones
        .where((zone) => zone.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return VouchSheet(
      title: 'Timezone',
      subtitle: 'Use the timezone the reminder should follow.',
      child: Column(
        children: <Widget>[
          VouchField(
            controller: _search,
            hint: 'Search timezones',
            prefix: VouchIcon(
              VouchGlyph.clock,
              size: 17,
              color: theme.faint,
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: VouchSpace.x3),
          SizedBox(
            height: 360,
            child: ListView.builder(
              itemCount: zones.length,
              itemBuilder: (context, index) {
                final zone = zones[index];
                final selected = zone == widget.current;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Pressable(
                    onTap: () => Navigator.of(context).pop(zone),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.accent.withValues(alpha: 0.12)
                            : theme.glass,
                        borderRadius:
                            BorderRadius.circular(VouchRadius.small),
                        border: Border.all(
                          color: selected
                              ? theme.accent.withValues(alpha: 0.45)
                              : theme.line,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              zone
                                  .replaceAll('_', ' ')
                                  .replaceAll('/', ' / '),
                              style: VouchType.bodyStrong(theme.ink)
                                  .copyWith(fontSize: 14),
                            ),
                          ),
                          if (selected)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (zones.isEmpty)
            Padding(
              padding: const EdgeInsets.all(VouchSpace.x5),
              child: Text(
                'No timezone matches “$_query”.',
                style: VouchType.body(theme.muted),
              ),
            ),
        ],
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
