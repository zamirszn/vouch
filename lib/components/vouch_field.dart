/// Text input built on [EditableText]. Vouch does not use TextField, so the
/// shell, selection chrome and focus states are entirely ours.
library;

import 'package:flutter/cupertino.dart' show CupertinoTextSelectionControls;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';

class VouchField extends StatefulWidget {
  const VouchField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.style,
    this.hintStyle,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.autofocus = false,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.prefix,
    this.suffix,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textAlign = TextAlign.start,
    this.padding = const EdgeInsets.symmetric(
      horizontal: VouchSpace.x4,
      vertical: VouchSpace.x3,
    ),
    this.radius = VouchRadius.medium,
    this.showCount = false,
  });

  final TextEditingController controller;
  final String hint;
  final String? label;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final bool readOnly;
  final bool obscureText;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final Widget? prefix;
  final Widget? suffix;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextAlign textAlign;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool showCount;

  @override
  State<VouchField> createState() => _VouchFieldState();
}

class _VouchFieldState extends State<VouchField> {
  late final FocusNode _node;
  bool _ownsNode = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node = widget.focusNode ?? FocusNode();
    _ownsNode = widget.focusNode == null;
    _node.addListener(_onFocus);
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(VouchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _node.removeListener(_onFocus);
      if (_ownsNode) _node.dispose();
      _ownsNode = widget.focusNode == null;
      _node = widget.focusNode ?? FocusNode();
      _node.addListener(_onFocus);
      _focused = _node.hasFocus;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _node.removeListener(_onFocus);
    if (_ownsNode) _node.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focused == _node.hasFocus) return;
    setState(() => _focused = _node.hasFocus);
  }

  void _onText() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final textStyle = widget.style ??
        VouchType.body(theme.ink).copyWith(fontSize: 16, height: 1.35);
    final empty = widget.controller.text.isEmpty;
    final multi = widget.maxLines != 1 || (widget.minLines ?? 1) > 1;

    final field = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: theme.glass,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: _focused ? theme.ink.withValues(alpha: 0.55) : theme.line,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            multi ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: <Widget>[
          if (widget.prefix != null) ...<Widget>[
            widget.prefix!,
            const SizedBox(width: VouchSpace.x3),
          ],
          Expanded(
            child: Stack(
              children: <Widget>[
                if (empty)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      widget.hint,
                      textAlign: widget.textAlign,
                      style: (widget.hintStyle ?? textStyle).copyWith(
                        color: theme.faint,
                      ),
                    ),
                  ),
                EditableText(
                  controller: widget.controller,
                  focusNode: _node,
                  style: textStyle,
                  cursorColor: theme.accent,
                  backgroundCursorColor: theme.faint,
                  cursorWidth: 1.6,
                  cursorRadius: const Radius.circular(2),
                  selectionColor: theme.accent.withValues(alpha: 0.28),
                  selectionControls: CupertinoTextSelectionControls(),
                  keyboardType: widget.keyboardType ??
                      (multi ? TextInputType.multiline : TextInputType.text),
                  textInputAction: widget.textInputAction,
                  textCapitalization: widget.textCapitalization,
                  textAlign: widget.textAlign,
                  autofocus: widget.autofocus,
                  readOnly: widget.readOnly,
                  obscureText: widget.obscureText,
                  maxLines: widget.maxLines,
                  minLines: widget.minLines,
                  inputFormatters: <TextInputFormatter>[
                    ...?widget.inputFormatters,
                    if (widget.maxLength != null)
                      LengthLimitingTextInputFormatter(widget.maxLength),
                  ],
                  autocorrect: widget.autocorrect,
                  enableSuggestions: widget.enableSuggestions,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                ),
              ],
            ),
          ),
          if (widget.suffix != null) ...<Widget>[
            const SizedBox(width: VouchSpace.x2),
            widget.suffix!,
          ],
        ],
      ),
    );

    if (widget.label == null && !widget.showCount) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.label != null) ...<Widget>[
          Text(
            widget.label!.toUpperCase(),
            style: VouchType.label(theme.muted).copyWith(letterSpacing: 1.8),
          ),
          const SizedBox(height: VouchSpace.x2),
        ],
        field,
        if (widget.showCount) ...<Widget>[
          const SizedBox(height: VouchSpace.x2),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${widget.controller.text.length}'
              '${widget.maxLength == null ? '' : ' / ${widget.maxLength}'}',
              style: VouchType.label(theme.faint, size: 10),
            ),
          ),
        ],
      ],
    );
  }
}

