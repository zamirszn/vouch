/// The partner's completion check: confirm, choose a method, mark the day.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import '../models/day_entry.dart';
import '../services/contact_service.dart';
import 'pressable.dart';
import 'vouch_button.dart';
import 'vouch_field.dart';
import 'vouch_icon.dart';
import 'vouch_sheet.dart';
import 'vouch_toast.dart';

Future<DayStatus?> showMarkSheet(
  BuildContext context, {
  required String ownerName,
  required String? ownerPhone,
  required String promise,
  required DayStatus initialStatus,
  required MarkMethod initialMethod,
  required String? initialNote,
  required Future<String?> Function(
    DayStatus status,
    MarkMethod method,
    String? note,
  )
  onSave,
}) {
  return showVouchPanel<DayStatus>(
    context,
    (_) => MarkSheet(
      ownerName: ownerName,
      ownerPhone: ownerPhone,
      promise: promise,
      initialStatus: initialStatus,
      initialMethod: initialMethod,
      initialNote: initialNote,
      onSave: onSave,
    ),
  );
}

class MarkSheet extends StatefulWidget {
  const MarkSheet({
    super.key,
    required this.ownerName,
    required this.ownerPhone,
    required this.promise,
    required this.initialStatus,
    required this.initialMethod,
    required this.initialNote,
    required this.onSave,
  });

  final String ownerName;
  final String? ownerPhone;
  final String promise;
  final DayStatus initialStatus;
  final MarkMethod initialMethod;
  final String? initialNote;
  final Future<String?> Function(
    DayStatus status,
    MarkMethod method,
    String? note,
  )
  onSave;

  @override
  State<MarkSheet> createState() => _MarkSheetState();
}

class _MarkSheetState extends State<MarkSheet> {
  late DayStatus _status = widget.initialStatus == DayStatus.pending
      ? DayStatus.completed
      : widget.initialStatus;
  late MarkMethod _method = widget.initialMethod;
  late final TextEditingController _note = TextEditingController(
    text: widget.initialNote ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await widget.onSave(_status, _method, _note.text.trim());
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _saving = false;
        _error = result;
      });
      return;
    }
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.of(context).pop(_status);
  }

  Future<void> _contact(Future<bool> Function(ContactService) action) async {
    final theme = VouchScope.of(context);
    final service = context.read<ContactService>();
    final ok = await action(service);
    if (!mounted || ok) return;
    VouchToast.show(
      context,
      (widget.ownerPhone?.trim().isNotEmpty ?? false)
          ? 'No app on this phone could handle that.'
          : '${widget.ownerName} has not added a phone number yet.',
      glyph: VouchGlyph.closeCircle,
      accent: theme.missed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final hasPhone = widget.ownerPhone?.trim().isNotEmpty ?? false;
    final message =
        'Hey ${widget.ownerName}, checking in on your promise: '
        '${widget.promise}. Did you get it done today?';

    return VouchSheet(
      title: 'How did it go?',
      subtitle: widget.promise,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'CONFIRM WITH ${widget.ownerName.toUpperCase()} FIRST',
            style: VouchType.label(theme.muted, size: 8.5),
          ),
          const SizedBox(height: VouchSpace.x3),
          Row(
            children: <Widget>[
              _ContactAction(
                glyph: VouchGlyph.phone,
                label: 'Call',
                tone: theme.pending,
                onTap: hasPhone
                    ? () => _contact((s) => s.call(widget.ownerPhone))
                    : null,
              ),
              const SizedBox(width: VouchSpace.x2),
              _ContactAction(
                glyph: VouchGlyph.message,
                label: 'WhatsApp',
                tone: theme.kept,
                onTap: hasPhone
                    ? () => _contact(
                        (s) => s.whatsApp(widget.ownerPhone, message: message),
                      )
                    : null,
              ),
              const SizedBox(width: VouchSpace.x2),
              _ContactAction(
                glyph: VouchGlyph.note,
                label: 'SMS',
                tone: theme.missed,
                onTap: hasPhone
                    ? () => _contact(
                        (s) => s.sms(widget.ownerPhone, body: message),
                      )
                    : null,
              ),
            ],
          ),
          if (!hasPhone) ...<Widget>[
            const SizedBox(height: VouchSpace.x2),
            Text(
              'No number for ${widget.ownerName}. Confirm in person.',
              style: VouchType.caption(theme.faint)
                  .copyWith(fontSize: 11.5, height: 1.4),
            ),
          ],
          const SizedBox(height: VouchSpace.x5),
          Text(
            'THE MARK',
            style: VouchType.label(theme.muted, size: 8.5),
          ),
          const SizedBox(height: VouchSpace.x3),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatusChoice(
                  selected: _status == DayStatus.completed,
                  glyph: VouchGlyph.check,
                  title: 'Kept',
                  subtitle: 'They did it',
                  color: theme.kept,
                  onTap: () =>
                      setState(() => _status = DayStatus.completed),
                ),
              ),
              const SizedBox(width: VouchSpace.x2),
              Expanded(
                child: _StatusChoice(
                  selected: _status == DayStatus.missed,
                  glyph: VouchGlyph.close,
                  title: 'Missed',
                  subtitle: 'Not today',
                  color: theme.missed,
                  onTap: () => setState(() => _status = DayStatus.missed),
                ),
              ),
            ],
          ),
          const SizedBox(height: VouchSpace.x5),
          Text(
            'HOW DID YOU CONFIRM IT?',
            style: VouchType.label(theme.muted, size: 8.5),
          ),
          const SizedBox(height: VouchSpace.x3),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final method in MarkMethod.values)
                _MethodChip(
                  method: method,
                  selected: _method == method,
                  onTap: () => setState(() => _method = method),
                ),
            ],
          ),
          const SizedBox(height: VouchSpace.x4),
          VouchField(
            controller: _note,
            minLines: 2,
            maxLines: 4,
            maxLength: VouchConfig.maxPartnerNoteLength,
            hint: _status == DayStatus.completed
                ? 'Optional: what convinced you?'
                : 'Optional: what happened?',
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: VouchSpace.x2),
            Text(
              _error!,
              style: VouchType.caption(theme.missed)
                  .copyWith(fontSize: 12.5, height: 1.4),
            ),
          ],
          const SizedBox(height: VouchSpace.x4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              VouchIcon(VouchGlyph.eye, size: 15, color: theme.faint),
              const SizedBox(width: VouchSpace.x2),
              Expanded(
                child: Text(
                  'A witness, not a judge. Say what happened.',
                  style: VouchType.caption(theme.faint)
                      .copyWith(fontSize: 11.5, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: VouchSpace.x5),
          VouchButton(
            label: _saving
                ? 'Saving…'
                : _status == DayStatus.completed
                    ? 'Mark kept'
                    : 'Mark missed',
            style: _status == DayStatus.completed
                ? VouchButtonStyle.signal
                : VouchButtonStyle.danger,
            expand: true,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _ContactAction extends StatelessWidget {
  const _ContactAction({
    required this.glyph,
    required this.label,
    required this.tone,
    this.onTap,
  });

  final VouchGlyph glyph;
  final String label;
  final Color tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final enabled = onTap != null;
    return Expanded(
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Pressable(
          onTap: onTap,
          enabled: enabled,
          scale: 0.96,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(VouchRadius.small),
              border: Border.all(color: tone.withValues(alpha: 0.28)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                VouchIcon(glyph, size: 15, color: tone),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VouchType.bodyStrong(theme.ink)
                        .copyWith(fontSize: 12),
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

class _StatusChoice extends StatelessWidget {
  const _StatusChoice({
    required this.selected,
    required this.glyph,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final bool selected;
  final VouchGlyph glyph;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);

    return Pressable(
      onTap: onTap,
      scale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.13) : theme.glass,
          borderRadius: BorderRadius.circular(VouchRadius.small),
          border: Border.all(
            color: selected ? color : theme.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? color
                        : theme.glassStrong,
                    border: Border.all(
                      color: selected ? color : theme.line,
                    ),
                  ),
                  child: selected
                      ? VouchIcon(
                          VouchGlyph.check,
                          size: 11,
                          color: theme.canvas,
                          strokeWidth: 2.4,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: VouchSpace.x4),
            Text(
              title,
              style: VouchType.title(theme.ink).copyWith(fontSize: 20),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: VouchType.caption(theme.muted).copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final MarkMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final glyph = switch (method) {
      MarkMethod.inPerson => VouchGlyph.people,
      MarkMethod.call => VouchGlyph.phone,
      MarkMethod.message => VouchGlyph.message,
      MarkMethod.other => VouchGlyph.dots,
    };

    return Pressable(
      onTap: onTap,
      scale: 0.95,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            VouchIcon(
              glyph,
              size: 14,
              color: selected ? theme.canvas : theme.muted,
            ),
            const SizedBox(width: 7),
            Text(
              method.shortLabel,
              style: VouchType.bodyStrong(
                selected ? theme.canvas : theme.muted,
              ).copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
