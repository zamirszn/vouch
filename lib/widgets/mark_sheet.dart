/// The partner's completion check: confirm, choose a method, mark the day.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../models/day_entry.dart';
import '../services/contact_service.dart';
import '../theme/vouch_theme.dart';
import 'pressable_spring.dart';
import 'sheet_frame.dart';
import 'soul.dart';

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
  ) onSave,
}) {
  return showVouchSheet<DayStatus>(
    context,
    MarkSheet(
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
  ) onSave;

  @override
  State<MarkSheet> createState() => _MarkSheetState();
}

class _MarkSheetState extends State<MarkSheet> {
  late DayStatus _status = widget.initialStatus == DayStatus.pending
      ? DayStatus.completed
      : widget.initialStatus;
  late MarkMethod _method = widget.initialMethod;
  late final TextEditingController _note =
      TextEditingController(text: widget.initialNote ?? '');
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
    final service = context.read<ContactService>();
    final ok = await action(service);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          (widget.ownerPhone?.trim().isNotEmpty ?? false)
              ? 'No app on this phone could handle that.'
              : '${widget.ownerName} has not added a phone number yet.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final hasPhone = widget.ownerPhone?.trim().isNotEmpty ?? false;
    final message =
        'Hey ${widget.ownerName}, checking in on your promise: ${widget.promise}. Did you get it done today?';

    return SheetFrame(
      title: 'How did it go?',
      subtitle: widget.promise,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Confirm with ${widget.ownerName} first',
            style: text.titleSmall,
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: hasPhone
                      ? () => _contact((s) => s.call(widget.ownerPhone))
                      : null,
                  icon: const Icon(Icons.call_rounded, size: 20),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: hasPhone
                      ? () => _contact(
                            (s) => s.whatsApp(
                              widget.ownerPhone,
                              message: message,
                            ),
                          )
                      : null,
                  icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                  label: const Text('WhatsApp'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'SMS',
                onPressed: hasPhone
                    ? () => _contact(
                          (s) => s.sms(widget.ownerPhone, body: message),
                        )
                    : null,
                icon: const Icon(Icons.sms_rounded),
              ),
            ],
          ),
          if (!hasPhone) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'No number for ${widget.ownerName}. Confirm in person.',
              style: text.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatusChoice(
                  selected: _status == DayStatus.completed,
                  icon: Icons.check_circle_rounded,
                  title: 'Kept',
                  subtitle: 'They did it',
                  color: VouchColors.kept,
                  onTap: () => setState(() => _status = DayStatus.completed),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatusChoice(
                  selected: _status == DayStatus.missed,
                  icon: Icons.cancel_rounded,
                  title: 'Missed',
                  subtitle: 'Not today',
                  color: VouchColors.coral,
                  onTap: () => setState(() => _status = DayStatus.missed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text('How did you confirm it?', style: text.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final method in MarkMethod.values)
                ChoiceChip(
                  selected: _method == method,
                  onSelected: (_) => setState(() => _method = method),
                  avatar: Icon(
                    switch (method) {
                      MarkMethod.inPerson => Icons.people_alt_rounded,
                      MarkMethod.call => Icons.call_rounded,
                      MarkMethod.message => Icons.chat_bubble_rounded,
                      MarkMethod.other => Icons.more_horiz_rounded,
                    },
                    size: 18,
                  ),
                  label: Text(method.shortLabel),
                ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 4,
            maxLength: VouchConfig.maxPartnerNoteLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: _status == DayStatus.completed
                  ? 'Optional: what convinced you?'
                  : 'Optional: what happened?',
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          if (_error != null) ...<Widget>[
            Text(
              _error!,
              style: text.bodySmall?.copyWith(color: scheme.error),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          const SheetNote(
            icon: Icons.handshake_outlined,
            text: 'A witness, not a judge. Say what happened.',
          ),
          const SizedBox(height: 18),
          SoulButton(
            label: _saving
                ? 'Saving…'
                : _status == DayStatus.completed
                    ? 'Mark kept'
                    : 'Mark missed',
            onPressed: _saving ? null : _save,
            color: _status == DayStatus.completed
                ? VouchColors.kept
                : VouchColors.coral,
            foreground: VouchColors.cream,
            arrowColor: VouchColors.cream,
            arrowForeground: VouchColors.ink,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _StatusChoice extends StatelessWidget {
  const _StatusChoice({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return PressableSpring(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.13)
              : (scheme.brightness == Brightness.dark
                  ? scheme.surfaceContainerHigh
                  : VouchColors.cream),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? color
                : scheme.onSurface.withValues(alpha: 0.13),
            width: selected ? 1.6 : 1.1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(width: 8, height: 8, color: color),
                const Spacer(),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selected ? color : scheme.onSurfaceVariant,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 16),
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
    );
  }
}
