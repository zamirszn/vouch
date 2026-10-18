/// Owner's live waiting room while the invite is unclaimed.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/track.dart';
import '../state/track_controller.dart';
import '../theme/vouch_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/brand_mark.dart';
import '../widgets/pressable_spring.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/sheet_frame.dart';
import '../widgets/vouch_avatar.dart';

class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  bool _refreshing = false;

  Future<void> _share(Track track) async {
    final message =
        'I made a promise on Vouch: “${track.promise}”.\n\n'
        'Be my accountability partner. Open Vouch and join with code '
        '${track.inviteCode}.';
    try {
      await SharePlus.instance.share(
        ShareParams(text: message, subject: 'Be my Vouch witness'),
      );
    } catch (_) {
      await _copy(track.inviteCode);
    }
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    await HapticFeedback.selectionClick();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied.')),
    );
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final error = await context.read<TrackController>().refreshInvite();
    if (!mounted) return;
    setState(() => _refreshing = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    await HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrackController>();
    final track = controller.track;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (track == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final expired = !track.inviteIsLive(now);
    final expiry = track.inviteExpiresAt;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const BrandMark(size: 42, animate: false, showShadow: false),
                    const SizedBox(width: 10),
                    Text('Vouch', style: text.titleLarge),
                    const Spacer(),
                    VouchAvatar(
                      name: track.ownerName,
                      photoUrl: track.ownerPhotoUrl,
                      size: 42,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Reveal(child: BrandMark(size: 84)),
                const SizedBox(height: 22),
                Reveal(
                  child: Text(
                    'Your promise is\nready to be seen.',
                    style: text.displaySmall?.copyWith(
                      fontSize: 42,
                      height: 1.02,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Send this code to the one person who will keep you honest. The app switches on the moment they join.',
                  style: text.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),
                ExpressiveCard(
                  color: VouchColors.indigo,
                  border: false,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  child: Column(
                    children: <Widget>[
                      Text(
                        'INVITE CODE',
                        style: text.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      PressableSpring(
                        onTap: () => _copy(track.inviteCode),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            for (final char in track.inviteCode.split(''))
                              Container(
                                width: 30,
                                height: 42,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.13),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Text(
                                  char,
                                  style: text.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontSize: 22,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        expired
                            ? 'This code has expired. Generate a fresh one.'
                            : expiry == null
                                ? 'Does not expire'
                                : 'Valid until ${DateFormat('d MMM, h:mm a').format(expiry.toLocal())}',
                        style: text.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: VouchColors.indigoDeep,
                              ),
                              onPressed: () => _share(track),
                              icon: const Icon(Icons.ios_share_rounded),
                              label: const Text('Share code'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            tooltip: 'Copy code',
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.16),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _copy(track.inviteCode),
                            icon: const Icon(Icons.copy_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                const SectionHeader(title: 'While you wait'),
                const _WaitingRow(
                  icon: Icons.person_search_rounded,
                  title: 'They join with the code',
                  subtitle:
                      'No account hunting, no email invites. One code, one witness.',
                ),
                const _WaitingRow(
                  icon: Icons.tune_rounded,
                  title: 'They choose the rhythm',
                  subtitle:
                      'Days, time and timezone are theirs to set — you both get nudged together.',
                ),
                const _WaitingRow(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'They mark, you write',
                  subtitle:
                      'You record what you did. They confirm it and mark the day.',
                ),
                const SizedBox(height: 20),
                const SheetNote(
                  icon: Icons.lock_outline_rounded,
                  text:
                      'The invite is a one-time key. Once someone joins, the code stops working.',
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _refreshing ? null : _refresh,
                        icon: _refreshing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: const Text('New code'),
                      ),
                    ),
                  ],
                ),
                if (controller.error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    controller.error!,
                    style: text.bodySmall?.copyWith(color: scheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaitingRow extends StatelessWidget {
  const _WaitingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: VouchColors.indigo.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: VouchColors.indigo, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
