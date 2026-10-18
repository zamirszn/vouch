/// Branded bootstrap screen.
library;

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../widgets/animated_background.dart';
import '../widgets/brand_mark.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: AnimatedBackground(
        intensity: 1.25,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const BrandMark(size: 124),
                const SizedBox(height: 28),
                Text(
                  VouchConfig.appName,
                  style: text.displayMedium?.copyWith(
                    letterSpacing: -1.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  VouchConfig.tagline,
                  style: text.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 44),
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
