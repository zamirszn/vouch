/// The owner's daily "what I did" editor.
library;

import 'package:flutter/widgets.dart';

import '../core/constants.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import 'vouch_button.dart';
import 'vouch_field.dart';
import 'vouch_icon.dart';
import 'vouch_sheet.dart';

Future<bool?> showNoteEditorSheet(
  BuildContext context, {
  required String promise,
  required String? initialNote,
  required Future<String?> Function(String note) onSave,
}) {
  return showVouchPanel<bool>(
    context,
    (_) => NoteEditorSheet(
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
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialNote ?? '',
  );
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
    final theme = VouchScope.of(context);

    return VouchSheet(
      title: 'What did you do today?',
      subtitle: widget.promise,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          VouchField(
            controller: _controller,
            autofocus: true,
            minLines: 5,
            maxLines: 9,
            maxLength: VouchConfig.maxDailyNoteLength,
            hint: 'Walked the canal loop at sunset. '
                'Legs tired, head clear.',
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
          const SizedBox(height: VouchSpace.x3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              VouchIcon(VouchGlyph.eye, size: 15, color: theme.faint),
              const SizedBox(width: VouchSpace.x2),
              Expanded(
                child: Text(
                  'Your witness sees this. You can edit until they mark '
                  'the day.',
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
                : widget.initialNote == null ||
                        widget.initialNote!.trim().isEmpty
                    ? 'Save note'
                    : 'Update note',
            expand: true,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
