/// Numbered section rule used across the record screens.
library;

import 'package:flutter/widgets.dart';

import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
    required this.index,
    required this.title,
    this.trailing,
    this.preserveCase = false,
  });

  final String index;
  final String title;
  final String? trailing;
  final bool preserveCase;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return Row(
      children: <Widget>[
        Text(index, style: VouchType.mono(theme.faint, size: 10)),
        const SizedBox(width: VouchSpace.x3),
        Text(
          preserveCase ? title : title.toUpperCase(),
          style: VouchType.label(theme.muted, size: 10),
        ),
        const SizedBox(width: VouchSpace.x3),
        Expanded(child: Container(height: 1, color: theme.line)),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: VouchSpace.x3),
          Text(
            trailing!.toUpperCase(),
            style: VouchType.label(theme.faint, size: 9),
          ),
        ],
      ],
    );
  }
}
