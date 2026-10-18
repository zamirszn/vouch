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
import '../widgets/pressable_spring.dart';
import '../widgets/section_header.dart';
import '../widgets/sheet_frame.dart';
import '../widgets/soul.dart';
import '../widgets/vouch_avatar.dart';
import '../widgets/vouch_loader.dart';

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
        body: Center(child: VouchLoader(size: 22)),
      );
    }

    final now = DateTime.now();
    final expired = !track.inviteIsLive(now);
    final expiry = track.inviteExpiresAt;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      'VOUCH / INVITE',
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const Spacer(),
                    VouchAvatar(
                      name: track.ownerName,
                      photoUrl: track.ownerPhotoUrl,
                      size: 40,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                PageHeader(
                  eyebrow: 'The invite',
                  title: 'Ready to be',
                  titleMuted: 'seen.',
                  index: '(002)',
                  subtitle:
                      'Send this to your witness. Vouch switches on when they join.',
                  titleSize: 44,
                ),
                const SizedBox(height: 24),
                InkCard(
                  color: VouchColors.lime,
                  border: false,
                  padding: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: CropMarks(
                    color: VouchColors.ink.withValues(alpha: 0.45),
                    inset: 10,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'INVITE CODE · ONE USE',
                            style: text.labelSmall?.copyWith(
                              color: VouchColors.ink.withValues(alpha: 0.62),
                              letterSpacing: 1.5,
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(height: 14),
                          PressableSpring(
                            onTap: () => _copy(track.inviteCode),
                            pressedScale: 0.97,
                            child: Row(
                              children: <Widget>[
                                for (var i = 0;
                                    i < track.inviteCode.length;
                                    i++)
                                  Expanded(
                                    child: Container(
                                      height: 54,
                                      margin: EdgeInsets.only(
                                        right: i == track.inviteCode.length - 1
                                            ? 0
                                            : 5,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: VouchColors.cream,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: VouchColors.ink.withValues(
                                            alpha: 0.18,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        track.inviteCode[i],
                                        style: text.headlineSmall?.copyWith(
                                          color: VouchColors.ink,
                                          fontSize: 24,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Container(
                                width: 6,
                                height: 6,
                                color: expired
                                    ? VouchColors.coral
                                    : VouchColors.keptDeep,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  expired
                                      ? 'Expired. Generate a fresh one below.'
                                      : expiry == null
                                          ? 'Does not expire.'
                                          : 'Valid until ${DateFormat('d MMM, h:mm a').format(expiry.toLocal())}.',
                                  style: text.labelSmall?.copyWith(
                                    color: VouchColors.ink.withValues(
                                      alpha: 0.72,
                                    ),
                                    letterSpacing: 0.4,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: SoulButton(
                                  label: 'Share the code',
                                  onPressed: () => _share(track),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PressableSpring(
                                onTap: () => _copy(track.inviteCode),
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: VouchColors.cream
                                        .withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: VouchColors.ink.withValues(
                                        alpha: 0.18,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.content_copy_rounded,
                                    color: VouchColors.ink,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const SectionHeader(
                  index: '01',
                  title: 'While you wait',
                  subtitle: 'Three small steps, then it is live.',
                ),
                const _WaitingRow(
                  index: '01',
                  title: 'They join with the code',
                  subtitle: 'One code, one witness.',
                  color: VouchColors.indigo,
                ),
                const _WaitingRow(
                  index: '02',
                  title: 'They choose the rhythm',
                  subtitle: 'Days and time. You both get nudged.',
                  color: VouchColors.coral,
                ),
                const _WaitingRow(
                  index: '03',
                  title: 'They mark, you write',
                  subtitle: 'You record it. They confirm.',
                  color: VouchColors.kept,
                ),
                const SizedBox(height: 4),
                const SheetNote(
                  icon: Icons.lock_outline_rounded,
                  text: 'One-time key. It stops working once someone joins.',
                ),
                const SizedBox(height: 16),
                SoulButton(
                  label: _refreshing ? 'Generating…' : 'Generate a new code',
                  color: VouchColors.cream,
                  foreground: VouchColors.ink,
                  icon: Icons.refresh_rounded,
                  height: 52,
                  onPressed: _refreshing ? null : _refresh,
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
    required this.index,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String index;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(width: 7, height: 7, color: color),
              const SizedBox(height: 4),
              Text(
                index,
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 8.5,
                  letterSpacing: 0.8,
                ),
              ),
            ],
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
