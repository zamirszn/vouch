/// Owner's live waiting room while the invite is unclaimed.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../components/glass_card.dart';
import '../components/pressable.dart';
import '../components/reveal.dart';
import '../components/section_label.dart';
import '../components/vouch_button.dart';
import '../components/vouch_icon.dart';
import '../components/vouch_loader.dart';
import '../components/vouch_scaffold.dart';
import '../components/vouch_toast.dart';
import '../components/vouch_top_bar.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import '../models/track.dart';
import '../state/track_controller.dart';

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
    VouchToast.show(context, 'Invite code copied.');
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final error = await context.read<TrackController>().refreshInvite();
    if (!mounted) return;
    setState(() => _refreshing = false);
    if (error != null) {
      VouchToast.show(
        context,
        error,
        glyph: VouchGlyph.closeCircle,
        accent: VouchScope.of(context).missed,
      );
      return;
    }
    await HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrackController>();
    final track = controller.track;
    final theme = VouchScope.of(context);

    if (track == null) {
      return VouchScaffold(
        tone: VouchTone.pending,
        body: Center(child: VouchLoader(size: 22, color: theme.ink)),
      );
    }

    final now = DateTime.now();
    final expired = !track.inviteIsLive(now);
    final expiry = track.inviteExpiresAt;
    final statusColor = expired ? theme.missed : theme.kept;

    return VouchScaffold(
      tone: VouchTone.pending,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            VouchSpace.gutter,
            VouchSpace.x2,
            VouchSpace.gutter,
            MediaQuery.viewPaddingOf(context).bottom + VouchSpace.x8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Reveal(
                index: 0,
                child: VouchTopBar(
                  annotation: '(003) / INVITE',
                  trailing: VouchAvatar(
                    initials: _initials(track.ownerName),
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: VouchSpace.x6),
              Reveal(
                index: 1,
                child: Text(
                  'Ready to be\nseen.',
                  style: VouchType.hero(theme.ink).copyWith(
                    fontSize: 46,
                    height: 0.94,
                  ),
                ),
              ),
              const SizedBox(height: VouchSpace.x3),
              Reveal(
                index: 2,
                child: Text(
                  'Send this to your witness. Vouch switches on when they join.',
                  style: VouchType.body(theme.muted)
                      .copyWith(fontSize: 14, height: 1.4),
                ),
              ),
              const SizedBox(height: VouchSpace.x6),
              const Reveal(
                index: 3,
                child: SectionLabel(index: '01', title: 'the invite code'),
              ),
              const SizedBox(height: VouchSpace.x3),
              Reveal(
                index: 4,
                child: GlassCard(
                  radius: VouchRadius.card,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  tint: theme.pending,
                  glow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'INVITE CODE · ONE USE',
                        style: VouchType.label(theme.muted, size: 8.5),
                      ),
                      const SizedBox(height: VouchSpace.x3),
                      Pressable(
                        haptic: false,
                        onTap: () => _copy(track.inviteCode),
                        semanticLabel: 'Copy invite code',
                        child: Row(
                          children: <Widget>[
                            for (var i = 0;
                                i < track.inviteCode.length;
                                i++)
                              Expanded(
                                child: Container(
                                  height: 52,
                                  margin: EdgeInsets.only(
                                    right: i == track.inviteCode.length - 1
                                        ? 0
                                        : 5,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: theme.ink,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    track.inviteCode[i],
                                    style: VouchType.title(theme.canvas)
                                        .copyWith(
                                      fontSize: 23,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: VouchSpace.x3),
                      Row(
                        children: <Widget>[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: VouchSpace.x2),
                          Expanded(
                            child: Text(
                              expired
                                  ? 'Expired. Generate a fresh one below.'
                                  : expiry == null
                                      ? 'Does not expire.'
                                      : 'Valid until '
                                          '${DateFormat('d MMM, h:mm a').format(expiry.toLocal())}.',
                              style: VouchType.mono(theme.muted, size: 9.5)
                                  .copyWith(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: VouchSpace.x4),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: VouchButton(
                              label: 'Share the code',
                              glyph: VouchGlyph.share,
                              height: 50,
                              onPressed: () => _share(track),
                            ),
                          ),
                          const SizedBox(width: VouchSpace.x2),
                          CircleAction(
                            glyph: VouchGlyph.copy,
                            size: 50,
                            onTap: () => _copy(track.inviteCode),
                            semanticLabel: 'Copy code',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: VouchSpace.x6),
              const Reveal(
                index: 5,
                child: SectionLabel(index: '02', title: 'while you wait'),
              ),
              const SizedBox(height: VouchSpace.x3),
              const Reveal(index: 6, child: _WaitingList()),
              const SizedBox(height: VouchSpace.x4),
              Reveal(
                index: 7,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    VouchIcon(VouchGlyph.lock, size: 14, color: theme.muted),
                    const SizedBox(width: VouchSpace.x2),
                    Expanded(
                      child: Text(
                        'One-time key. It stops working once someone joins.',
                        style: VouchType.caption(theme.muted)
                            .copyWith(fontSize: 11.5, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VouchSpace.x5),
              Reveal(
                index: 8,
                child: VouchButton(
                  label: _refreshing ? 'Generating…' : 'Generate a new code',
                  style: VouchButtonStyle.glass,
                  expand: true,
                  glyph: VouchGlyph.refresh,
                  loading: _refreshing,
                  onPressed: _refreshing ? null : _refresh,
                ),
              ),
              if (controller.error != null) ...<Widget>[
                const SizedBox(height: VouchSpace.x3),
                Text(
                  controller.error!,
                  style: VouchType.caption(theme.missed)
                      .copyWith(fontSize: 12.5, height: 1.4),
                ),
              ],
              const SizedBox(height: VouchSpace.x6),
              Container(height: 1, color: theme.line),
              const SizedBox(height: VouchSpace.x4),
              Text('Wait for them.', style: VouchType.body(theme.muted)),
              const SizedBox(height: 4),
              Text(
                'The promise starts when they do.',
                style: VouchType.caption(theme.faint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaitingList extends StatelessWidget {
  const _WaitingList();

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return GlassCard(
      radius: VouchRadius.card,
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
      child: Column(
        children: <Widget>[
          _WaitingRow(
            index: '01',
            title: 'They join with the code',
            subtitle: 'One code, one witness.',
            color: theme.pending,
            last: false,
          ),
          _WaitingRow(
            index: '02',
            title: 'They choose the rhythm',
            subtitle: 'Days and time. You both get nudged.',
            color: theme.missed,
            last: false,
          ),
          _WaitingRow(
            index: '03',
            title: 'They mark, you write',
            subtitle: 'You record it. They confirm.',
            color: theme.kept,
            last: true,
          ),
        ],
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
    required this.last,
  });

  final String index;
  final String title;
  final String subtitle;
  final Color color;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: theme.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(height: 4),
              Text(index, style: VouchType.mono(theme.faint, size: 8.5)),
            ],
          ),
          const SizedBox(width: VouchSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: VouchType.bodyStrong(theme.ink)
                      .copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: VouchType.caption(theme.muted)
                      .copyWith(fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
