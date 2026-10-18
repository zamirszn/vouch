/// The owner's daily "what I did" editor.
library;

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../theme/vouch_theme.dart';
import 'section_header.dart';
import 'sheet_frame.dart';
import 'soul.dart';

Future<bool?> showNoteEditorSheet(
  BuildContext context, {
  required String promise,
  required String? initialNote,
  required Future<String?> Function(String note) onSave,
}) {
  return showVouchSheet<bool>(
    context,
    NoteEditorSheet(
      promise: promise,
      initialNote: initialNote,
      onSave: onSave,
    ),
  );
}

class NoteEditorSheet extends StatefulWidget {
  const NoteEditorSheet({
    super.key,
    required this.promise,
    required this.initialNote,
    required this.onSave,
  });

  final String promise;
  final String? initialNote;
  final Future<String?> Function(String note) onSave;

  @override
  State<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<NoteEditorSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialNote ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(_controller.text.trim());
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return SheetFrame(
      title: 'What did you do today?',
      subtitle: widget.promise,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 5,
            maxLines: 9,
            maxLength: VouchConfig.maxDailyNoteLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Walked the canal loop at sunset. Legs tired, head clear.',
              alignLabelWithHint: true,
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
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          const SheetNote(
            icon: Icons.visibility_outlined,
            text:
                'Your witness sees this. You can edit until they mark the day.',
          ),
          const SizedBox(height: 18),
          SoulButton(
            label: _saving
                ? 'Saving…'
                : widget.initialNote == null ||
                        widget.initialNote!.trim().isEmpty
                    ? 'Save note'
                    : 'Update note',
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// Compact preview of the owner's note used on Home and History.
class NotePreview extends StatelessWidget {
  const NotePreview({
    super.key,
    required this.note,
    this.maxLines = 4,
    this.emptyLabel = 'No note yet.',
  });

  final String? note;
  final int maxLines;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final value = note?.trim();
    final empty = value == null || value.isEmpty;

    return ExpressiveCard(
      color: empty
          ? scheme.surfaceContainerHigh
          : VouchColors.indigo.withValues(alpha: 0.06),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.notes_rounded,
            color: VouchColors.indigo,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              empty ? emptyLabel : value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: empty
                  ? text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    )
                  : text.bodyLarge?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
