/// Branded bootstrap screen.
library;

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../theme/vouch_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/brand_mark.dart';
import '../widgets/vouch_loader.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AnimatedBackground(
        intensity: 1.2,
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const BrandMark(size: 112),
                    const SizedBox(height: 30),
                    Text(
                      VouchConfig.appName,
                      style: text.displayLarge?.copyWith(
                        fontSize: 58,
                        height: 0.9,
                        letterSpacing: -3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 26,
                          height: 1,
                          color: scheme.onSurface.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          VouchConfig.tagline.toUpperCase(),
                          style: text.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 1.6,
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 26,
                          height: 1,
                          color: scheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 46),
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: VouchLoader(size: 22),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                bottom: 24,
                child: Text(
                  '(EST. MMXXVI)',
                  style: text.labelSmall?.copyWith(
                    color: VouchColors.mist,
                    fontSize: 9,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
