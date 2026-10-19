/// Component gallery for design QA. Enabled with
/// `--dart-define=VOUCH_GALLERY=true`.
library;

import 'package:flutter/widgets.dart';

import '../components/day_detail_sheet.dart';
import '../components/dot_matrix_number.dart';
import '../components/glass_card.dart';
import '../components/mark_sheet.dart';
import '../components/note_editor_sheet.dart';
import '../components/pressable.dart';
import '../components/section_label.dart';
import '../components/stat_tile.dart';
import '../components/vertical_ruler.dart';
import '../components/vouch_button.dart';
import '../components/vouch_dialog.dart';
import '../components/vouch_field.dart';
import '../components/vouch_icon.dart';
import '../components/vouch_loader.dart';
import '../components/vouch_scaffold.dart';
import '../components/vouch_sheet.dart';
import '../components/vouch_switch.dart';
import '../components/vouch_time_wheel.dart';
import '../components/vouch_toast.dart';
import '../components/vouch_top_bar.dart';
import '../components/week_strip.dart';
import '../core/date_utils.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import '../models/day_entry.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _field = TextEditingController(text: 'Walked the canal loop');
  bool _switch = true;
  VouchTone _tone = VouchTone.pending;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _toast(String message) =>
      VouchToast.show(context, message, glyph: VouchGlyph.checkCircle);

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final today = DateTime.now();

    return VouchScaffold(
      tone: _tone,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            VouchSpace.gutter,
            VouchSpace.x2,
            VouchSpace.gutter,
            MediaQuery.viewPaddingOf(context).bottom + VouchSpace.x10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const VouchTopBar(annotation: '(G) / COMPONENTS'),
              const SizedBox(height: VouchSpace.x5),
              Text(
                'The kit.',
                style: VouchType.hero(theme.ink).copyWith(
                  fontSize: 48,
                  height: 0.94,
                ),
              ),
              const SizedBox(height: VouchSpace.x2),
              Text(
                'Every surface, state and glyph in one place.',
                style: VouchType.body(theme.muted).copyWith(fontSize: 14),
              ),
              const SizedBox(height: VouchSpace.x6),
              const SectionLabel(index: '01', title: 'tones'),
              const SizedBox(height: VouchSpace.x2),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final tone in VouchTone.values)
                    _GalleryChip(
                      label: tone.name,
                      selected: _tone == tone,
                      onTap: () => setState(() => _tone = tone),
                    ),
                ],
              ),
              const SizedBox(height: VouchSpace.x6),
              const SectionLabel(index: '02', title: 'type'),
              const SizedBox(height: VouchSpace.x2),
              Text('Hero 64', style: VouchType.hero(theme.ink)),
              Text('Display 42', style: VouchType.display(theme.ink)),
              Text('Title 27', style: VouchType.title(theme.ink)),
              Text('Card title 19', style: VouchType.cardTitle(theme.ink)),
              Text(
                'Body copy sits at fifteen with a generous line height.',
                style: VouchType.body(theme.muted),
              ),
              Text('Label / mono', style: VouchType.label(theme.faint)),
              Text(
                '{01} · 20:00 · AFRICA/LAGOS',
                style: VouchType.mono(theme.muted, size: 10),
              ),
              const SizedBox(height: VouchSpace.x6),
              const SectionLabel(index: '03', title: 'colour'),
              const SizedBox(height: VouchSpace.x2),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final swatch in <(String, Color)>[
                    ('canvas', theme.canvas),
                    ('raised', theme.raised),
                    ('ink', theme.ink),
                    ('muted', theme.muted),
                    ('accent', theme.accent),
                    ('kept', theme.kept),
                    ('missed', theme.missed),
                    ('pending', theme.pending),
                  ])
                    _Swatch(name: swatch.$1, color: swatch.$2),
                ],
              ),
              const SizedBox(height: VouchSpace.x6),
              const SectionLabel(index: '04', title: 'numbers'),
              const SizedBox(height: VouchSpace.x3),
              GlassCard(
                radius: VouchRadius.card,
                child: Row(
                  children: <Widget>[
                    DotMatrixNumber(
                      7,
                      height: 58,
                      color: theme.ink,
                      dim: theme.ink,
                      semanticLabel: '7 day streak',
                    ),
                    const SizedBox(width: VouchSpace.x4),
                    VerticalRuler(
                      value: 0.83,
                      height: 84,
                      color: theme.kept,
                    ),
                    const SizedBox(width: VouchSpace.x3),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('83%', style: VouchType.title(theme.ink)),
                        Text(
                          'KEPT',
                          style: VouchType.label(theme.muted, size: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VouchSpace.x3),
              Row(
                children: <Widget>[
                  Expanded(
                    child: StatTile(
                      value: '07',
                      label: 'day streak',
                      tone: VouchTone.pending,
                      height: 96,
                    ),
                  ),
                  const SizedBox(width: VouchSpace.x2),
                  Expanded(
                    child: StatTile(
                      value: '24',
                      label: 'days kept',
                      tone: VouchTone.kept,
                      height: 96,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VouchSpace.x3),
              WeekStrip(
                days: <WeekStripDay>[
                  for (var i = 6; i >= 0; i--)
                    WeekStripDay(
                      date: dateAt(today, -i),
                      state: i % 3 == 0
                          ? VouchDayState.missed
                          : VouchDayState.completed,
                    ),
                ],
                today: today,
                onTap: (day) => _toast('${day.state.name} on '
                    '${day.date.day}'),
              ),
              const SizedBox(height: VouchSpace.x2),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  const StatusChip(label: 'Kept', tone: VouchTone.kept),
                  const StatusChip(label: 'Missed', tone: VouchTone.missed),
                  const StatusChip(label: 'Pending', tone: VouchTone.pending),
                  const StatusChip(label: 'Rest', tone: VouchTone.rest),
                ],
              ),
              const SizedBox(height: VouchSpace.x6),
              const SectionLabel(index: '05', title: 'buttons'),
              const SizedBox(height: VouchSpace.x3),
              VouchButton(
                label: 'Signal',
                glyph: VouchGlyph.check,
                expand: true,
                onPressed: () => _toast('Signal pressed.'),
              ),
              const SizedBox(height: VouchSpace.x2),
              VouchButton(
                label: 'Glass',
                style: VouchButtonStyle.glass,
                trailingGlyph: VouchGlyph.arrowRight,
                expand: true,
                onPressed: () => _toast('Glass pressed.'),
              ),
              const SizedBox(height: VouchSpace.x2),
              VouchButton(
                label: 'Ghost',
                style: VouchButtonStyle.ghost,
                expand: true,
                onPressed: () => _toast('Ghost pressed.'),
              ),
              const SizedBox(height: VouchSpace.x2),
              VouchButton(
                label: 'Danger',
                style: VouchButtonStyle.danger,
                expand: true,
                onPressed: () => _toast('Danger pressed.'),
              ),
              const SizedBox(height: VouchSpace.x2),
              const VouchButton(
                label: 'Loading',
                expand: true,
                loading: true,
              ),
              const SizedBox(height: VouchSpace.x3),
              Row(
                children: <Widget>[
                  CircleAction(
                    glyph: VouchGlyph.close,
                    onTap: () => _toast('Close pressed.'),
                  ),
                  const SizedBox(width: VouchSpace.x2),
                  CircleAction(
                    glyph: VouchGlyph.plus,
                    background: theme.ink,
                    foreground: theme.canvas,
                    border: theme.ink,
                    onTap: () => _toast('Plus pressed.'),
                  ),
                  const SizedBox(width: VouchSpace.x2),
                  CircleAction(
                    glyph: VouchGlyph.check,
                    background: theme.accent,
                    foreground: VouchColors.paperInk,
                    border: theme.accent,
                    onTap: () => _toast('Check pressed.'),
                  ),
                  const Spacer(),
                  VouchLoader(size: 20, color: theme.ink),
                  const SizedBox(width: VouchSpace.x3),
                  VouchSwitch(
                    value: _switch,
                    semanticLabel: 'Demo switch',
                    onChanged: (value) => setState(() => _switch = value),
                  ),
                ],
              ),
              const SizedBox(height: VouchSpace.x6),
              const SectionLabel(index: '06', title: 'field'),
              const SizedBox(height: VouchSpace.x3),
              VouchField(
                controller: _field,
                hint: 'What did you do today?',
                label: 'Daily note',
                showCount: true,
                maxLength: 240,
                minLines: 2,
                maxLines: 4,
                suffix: VouchIcon(
                  VouchGlyph.edit,
                  size: 16,
                  color: theme.faint,
                ),
              ),
              const SizedBox(height: VouchSpace.x6),
              const SectionLabel(index: '07', title: 'sheets'),
              const SizedBox(height: VouchSpace.x3),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _GalleryChip(
                    label: 'time wheel',
                    onTap: () async {
                      final picked = await showVouchTimeWheel(
                        context,
                        hour: 19,
                        minute: 30,
                      );
                      if (picked != null) {
                        _toast(
                          vouchClockLabel(picked.hour, picked.minute),
                        );
                      }
                    },
                  ),
                  _GalleryChip(
                    label: 'confirm',
                    onTap: () async {
                      final ok = await showVouchConfirm(
                        context,
                        title: 'End the promise?',
                        message: 'This removes it for both of you.',
                        action: 'End it',
                      );
                      if (ok) _toast('Confirmed.');
                    },
                  ),
                  _GalleryChip(
                    label: 'mark',
                    onTap: () => showMarkSheet(
                      context,
                      ownerName: 'Zamir',
                      ownerPhone: '+2348012345678',
                      promise: 'Walk 30 minutes before sunset',
                      initialStatus: DayStatus.pending,
                      initialMethod: MarkMethod.call,
                      initialNote: null,
                      onSave: (status, method, note) async => null,
                    ),
                  ),
                  _GalleryChip(
                    label: 'note',
                    onTap: () => showNoteEditorSheet(
                      context,
                      promise: 'Walk 30 minutes before sunset',
                      initialNote: null,
                      onSave: (note) async => null,
                    ),
                  ),
                  _GalleryChip(
                    label: 'day detail',
                    onTap: () => showDayDetailSheet(
                      context,
                      date: today,
                      entry: null,
                      state: VouchDayState.pending,
                      today: today,
                    ),
                  ),
                  _GalleryChip(
                    label: 'sheet',
                    onTap: () => showVouchPanel<void>(
                      context,
                      (_) => VouchSheet(
                        title: 'Plain sheet',
                        subtitle: 'A frosted panel for anything.',
                        child: Text(
                          'The grab handle, close circle and header are '
                          'shared by every sheet.',
                          style: VouchType.body(theme.muted),
                        ),
                      ),
                    ),
                  ),
                  _GalleryChip(
                    label: 'toast',
                    onTap: () => _toast('Invite code copied.'),
                  ),
                ],
              ),
              const SizedBox(height: VouchSpace.x6),
              const SectionLabel(index: '08', title: 'glyphs'),
              const SizedBox(height: VouchSpace.x3),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: <Widget>[
                  for (final glyph in VouchGlyph.values)
                    SizedBox(
                      width: 54,
                      child: Column(
                        children: <Widget>[
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.glass,
                              borderRadius:
                                  BorderRadius.circular(VouchRadius.small),
                              border: Border.all(color: theme.line),
                            ),
                            child: VouchIcon(glyph, size: 19),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            glyph.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VouchType.mono(theme.faint, size: 7),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: VouchSpace.x8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return Container(
      width: 78,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.glass,
        borderRadius: BorderRadius.circular(VouchRadius.small),
        border: Border.all(color: theme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.line),
            ),
          ),
          const SizedBox(height: 5),
          Text(name, style: VouchType.mono(theme.muted, size: 8)),
        ],
      ),
    );
  }
}

class _GalleryChip extends StatelessWidget {
  const _GalleryChip({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return Pressable(
      onTap: onTap,
      scale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.ink : theme.glass,
          borderRadius: BorderRadius.circular(VouchRadius.pill),
          border: Border.all(
            color: selected ? theme.ink : theme.line,
          ),
        ),
        child: Text(
          label,
          style: VouchType.bodyStrong(
            selected ? theme.canvas : theme.muted,
          ).copyWith(fontSize: 12),
        ),
      ),
    );
  }
}
