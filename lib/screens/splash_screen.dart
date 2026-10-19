/// Branded bootstrap screen: an ink poster with the wordmark set enormous
/// and one acid line beneath it.
library;

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../widgets/poster.dart';
import '../widgets/vouch_loader.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PosterField(
        tone: PosterTone.ink,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const PosterTopBar(right: '(EST. MMXXVI)'),
              const Spacer(),
              const PosterLabel('A small deal', size: 8.5),
              const SizedBox(height: 14),
              const PosterHeadline(
                VouchConfig.appName,
                size: 104,
                height: 0.8,
                color: PosterColors.cream,
              ),
              const SizedBox(height: 8),
              const PosterHeadline(
                'one promise.',
                size: 34,
                height: 0.95,
                color: PosterColors.acid,
              ),
              const SizedBox(height: 22),
              Container(
                width: 56,
                height: 2,
                color: PosterColors.cream.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                VouchConfig.tagline,
                style: TextStyle(
                  fontFamily: 'InstrumentSans',
                  fontSize: 15,
                  height: 1.4,
                  color: PosterColors.cream.withValues(alpha: 0.62),
                ),
              ),
              const Spacer(),
              Row(
                children: <Widget>[
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: VouchLoader(size: 18, color: PosterColors.acid),
                  ),
                  const SizedBox(width: 10),
                  const PosterLabel('Syncing', color: PosterColors.acid),
                  const Spacer(),
                  const PosterLabel('V.01'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
