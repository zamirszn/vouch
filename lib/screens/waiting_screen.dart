/// Owner's live waiting room while the invite is unclaimed.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/track.dart';
import '../state/track_controller.dart';
import '../widgets/poster.dart';
import '../widgets/pressable_spring.dart';
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
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Invite code copied.')));
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final error = await context.read<TrackController>().refreshInvite();
    if (!mounted) return;
    setState(() => _refreshing = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    await HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrackController>();
    final track = controller.track;

    if (track == null) {
      return const Scaffold(
        body: PosterField(
          tone: PosterTone.butter,
          child: Center(child: VouchLoader(size: 22, color: PosterColors.ink)),
        ),
      );
    }

    final now = DateTime.now();
    final expired = !track.inviteIsLive(now);
    final expiry = track.inviteExpiresAt;

    return Scaffold(
      body: PosterField(
        tone: PosterTone.butter,
        child: Builder(
          builder: (context) {
            final style = PosterStyle.of(context);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  PosterTopBar(
                    right: '(003) / invite',
                    trailing: VouchAvatar(
                      name: track.ownerName,
                      photoUrl: track.ownerPhotoUrl,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const PosterHeadline(
                    'Ready to be\nseen.',
                    size: 46,
                    accentTail: 1,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Send this to your witness. Vouch switches on when they join.',
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      fontSize: 14,
                      height: 1.4,
                      color: style.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const PosterSectionLabel('01', 'the invite code'),
                  const SizedBox(height: 10),
                  PosterCard(
                    color: PosterColors.cobalt,
                    foreground: PosterColors.cream,
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        PosterLabel(
                          'Invite code · one use',
                          color: PosterColors.cream.withValues(alpha: 0.62),
                        ),
                        const SizedBox(height: 12),
                        PressableSpring(
                          onTap: () => _copy(track.inviteCode),
                          pressedScale: 0.97,
                          child: Row(
                            children: <Widget>[
                              for (var i = 0; i < track.inviteCode.length; i++)
                                Expanded(
                                  child: Container(
                                    height: 50,
                                    margin: EdgeInsets.only(
                                      right: i == track.inviteCode.length - 1
                                          ? 0
                                          : 5,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: PosterColors.cream,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Text(
                                      track.inviteCode[i],
                                      style: const TextStyle(
                                        fontFamily: 'InstrumentSans',
                                        fontSize: 23,
                                        fontWeight: FontWeight.w700,
                                        height: 1.0,
                                        letterSpacing: 0,
                                        color: PosterColors.ink,
                                        fontVariations: <FontVariation>[
                                          FontVariation('wght', 700),
                                          FontVariation('wdth', 94),
                                        ],
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
                              decoration: BoxDecoration(
                                color: expired
                                    ? PosterColors.coral
                                    : const Color(0xFF74E39A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                expired
                                    ? 'Expired. Generate a fresh one below.'
                                    : expiry == null
                                    ? 'Does not expire.'
                                    : 'Valid until ${DateFormat('d MMM, h:mm a').format(expiry.toLocal())}.',
                                style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  fontSize: 9,
                                  height: 1.4,
                                  letterSpacing: 0.3,
                                  color: PosterColors.cream.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: PosterPill(
                                label: 'Share the code',
                                onPressed: () => _share(track),
                                color: PosterColors.cream,
                                foreground: PosterColors.ink,
                                arrowColor: PosterColors.acid,
                                arrowForeground: PosterColors.ink,
                                height: 52,
                              ),
                            ),
                            const SizedBox(width: 8),
                            PressableSpring(
                              onTap: () => _copy(track.inviteCode),
                              pressedScale: 0.92,
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: PosterColors.cream.withValues(
                                    alpha: 0.14,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: PosterColors.cream.withValues(
                                      alpha: 0.28,
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.content_copy_rounded,
                                  color: PosterColors.cream,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const PosterSectionLabel('02', 'while you wait'),
                  const SizedBox(height: 6),
                  const _WaitingRow(
                    index: '01',
                    title: 'They join with the code',
                    subtitle: 'One code, one witness.',
                    color: PosterColors.cobalt,
                  ),
                  const _WaitingRow(
                    index: '02',
                    title: 'They choose the rhythm',
                    subtitle: 'Days and time. You both get nudged.',
                    color: PosterColors.coral,
                  ),
                  const _WaitingRow(
                    index: '03',
                    title: 'They mark, you write',
                    subtitle: 'You record it. They confirm.',
                    color: PosterColors.kelly,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: style.muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'One-time key. It stops working once someone joins.',
                          style: TextStyle(
                            fontFamily: 'InstrumentSans',
                            fontSize: 11.5,
                            height: 1.4,
                            color: style.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  PosterPill(
                    label: _refreshing ? 'Generating…' : 'Generate a new code',
                    color: PosterColors.cream,
                    foreground: PosterColors.ink,
                    arrowColor: PosterColors.coral,
                    arrowForeground: PosterColors.cream,
                    icon: Icons.refresh_rounded,
                    onPressed: _refreshing ? null : _refresh,
                  ),
                  if (controller.error != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      controller.error!,
                      style: const TextStyle(
                        fontFamily: 'InstrumentSans',
                        fontSize: 12.5,
                        height: 1.4,
                        color: Color(0xFF8E2A22),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  const PosterFooter(
                    lead: 'Wait for them.',
                    muted: 'The promise starts when they do.',
                  ),
                ],
              ),
            );
          },
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
    final style = PosterStyle.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(height: 4),
              Text(
                index,
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 8.5,
                  letterSpacing: 0.8,
                  color: style.muted,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'InstrumentSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: style.ink,
                    fontVariations: const <FontVariation>[
                      FontVariation('wght', 600),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'InstrumentSans',
                    fontSize: 12,
                    height: 1.4,
                    color: style.muted,
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
