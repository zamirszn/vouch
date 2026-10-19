/// Branded bootstrap screen: the wordmark set enormous on a dark stage.
library;

import 'package:flutter/widgets.dart';

import '../components/vouch_loader.dart';
import '../components/vouch_scaffold.dart';
import '../components/vouch_top_bar.dart';
import '../core/constants.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return VouchScaffold(
      tone: VouchTone.pending,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VouchSpace.gutter,
            VouchSpace.x3,
            VouchSpace.gutter,
            VouchSpace.x6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const VouchTopBar(annotation: '(EST. MMXXVI)'),
              const Spacer(),
              Text(
                'A SMALL DEAL',
                style: VouchType.label(theme.muted, size: 8.5),
              ),
              const SizedBox(height: VouchSpace.x3),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'VOUCH',
                    style: VouchType.hero(theme.ink).copyWith(
                      fontSize: 118,
                      height: 0.8,
                      letterSpacing: -6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: VouchSpace.x2),
              Text(
                'one promise.',
                style: VouchType.display(theme.accent).copyWith(
                  fontSize: 34,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: VouchSpace.x5),
              Container(
                width: 56,
                height: 2,
                decoration: BoxDecoration(
                  color: theme.lineStrong,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: VouchSpace.x4),
              Text(
                VouchConfig.tagline,
                style: VouchType.body(theme.muted)
                    .copyWith(fontSize: 15, height: 1.4),
              ),
              const Spacer(),
              Row(
                children: <Widget>[
                  VouchLoader(size: 18, color: theme.accent, strokeWidth: 2),
                  const SizedBox(width: VouchSpace.x3),
                  Text(
                    'SYNCING',
                    style: VouchType.label(theme.accent, size: 10),
                  ),
                  const Spacer(),
                  Text(
                    'V.01',
                    style: VouchType.label(theme.faint, size: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
