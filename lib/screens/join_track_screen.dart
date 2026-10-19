/// Partner joins with the owner's 8-character invite code.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../components/glass_card.dart';
import '../components/reveal.dart';
import '../components/section_label.dart';
import '../components/vouch_button.dart';
import '../components/vouch_field.dart';
import '../components/vouch_icon.dart';
import '../components/vouch_scaffold.dart';
import '../components/vouch_top_bar.dart';
import '../core/constants.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import '../models/track.dart';
import '../state/track_controller.dart';

class JoinTrackScreen extends StatefulWidget {
  const JoinTrackScreen({super.key});

  @override
  State<JoinTrackScreen> createState() => _JoinTrackScreenState();
}

class _JoinTrackScreenState extends State<JoinTrackScreen> {
  final _code = TextEditingController();
  InvitePreview? _preview;
  bool _looking = false;
  bool _joining = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final code = _code.text.trim().toUpperCase();
    if (code.length != VouchConfig.inviteLength) {
      setState(
        () => _error =
            'Enter the full ${VouchConfig.inviteLength}-character code.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _looking = true;
      _error = null;
      _preview = null;
    });
    try {
      final preview = await context.read<TrackController>().previewInvite(code);
      if (!mounted) return;
      if (preview == null) {
        setState(() {
          _looking = false;
          _error =
              'No promise matches that code. Check the letters and digits.';
        });
        return;
      }
      if (preview.isExpired(DateTime.now())) {
        setState(() {
          _looking = false;
          _error = 'That invite has expired. Ask for a fresh code.';
        });
        return;
      }
      setState(() {
        _looking = false;
        _preview = preview;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _looking = false;
        _error = 'Could not look up that code right now. Try again.';
      });
    }
  }

  Future<void> _join() async {
    final preview = _preview;
    if (preview == null || _joining) return;
    setState(() {
      _joining = true;
      _error = null;
    });
    final error = await context.read<TrackController>().joinTrack(preview.code);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _joining = false;
        _error = error;
      });
      return;
    }
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final preview = _preview;

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
              const VouchBackBar(annotation: '(002)'),
              const SizedBox(height: VouchSpace.x6),
              Reveal(
                index: 0,
                child: Text(
                  'Got a\ncode?',
                  style: VouchType.hero(theme.ink).copyWith(
                    fontSize: 46,
                    height: 0.94,
                  ),
                ),
              ),
              const SizedBox(height: VouchSpace.x3),
              Reveal(
                index: 1,
                child: Text(
                  'Enter the ${VouchConfig.inviteLength}-character code '
                  'from your person.',
                  style: VouchType.body(theme.muted)
                      .copyWith(fontSize: 14, height: 1.4),
                ),
              ),
              const SizedBox(height: VouchSpace.x6),
              const Reveal(
                index: 2,
                child: SectionLabel(index: '01', title: 'the invite'),
              ),
              const SizedBox(height: VouchSpace.x3),
              Reveal(
                index: 3,
                child: VouchField(
                  controller: _code,
                  maxLength: VouchConfig.inviteLength,
                  textCapitalization: TextCapitalization.characters,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: VouchType.mono(theme.ink, size: 24).copyWith(
                    letterSpacing: 5,
                    height: 1.2,
                  ),
                  hintStyle: VouchType.mono(theme.faint, size: 24).copyWith(
                    letterSpacing: 5,
                    height: 1.2,
                  ),
                  hint: 'ABCD1234',
                  keyboardType: TextInputType.visiblePassword,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    _UpperCaseFormatter(),
                  ],
                  onChanged: (_) {
                    if (_error != null || _preview != null) {
                      setState(() {
                        _error = null;
                        _preview = null;
                      });
                    }
                  },
                  onSubmitted: (_) => _find(),
                ),
              ),
              const SizedBox(height: VouchSpace.x3),
              Reveal(
                index: 4,
                child: VouchButton(
                  label: _looking ? 'Looking…' : 'Find the promise',
                  expand: true,
                  loading: _looking,
                  trailingGlyph: VouchGlyph.arrowRight,
                  onPressed: _looking ? null : _find,
                ),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: VouchSpace.x3),
                GlassCard(
                  radius: VouchRadius.medium,
                  padding: const EdgeInsets.all(14),
                  tint: theme.missed,
                  borderColor: theme.missed.withValues(alpha: 0.3),
                  child: Text(
                    _error!,
                    style: VouchType.caption(theme.ink)
                        .copyWith(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
              if (preview != null) ...<Widget>[
                const SizedBox(height: VouchSpace.x6),
                const Reveal(
                  index: 5,
                  child: SectionLabel(index: '02', title: 'is this them?'),
                ),
                const SizedBox(height: VouchSpace.x3),
                Reveal(
                  index: 6,
                  child: GlassCard(
                    radius: VouchRadius.card,
                    padding: const EdgeInsets.all(18),
                    tint: theme.kept,
                    glow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            VouchAvatar(
                              initials: _initials(preview.ownerName),
                              size: 48,
                              background: theme.kept.withValues(alpha: 0.16),
                              foreground: theme.kept,
                            ),
                            const SizedBox(width: VouchSpace.x3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    preview.ownerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: VouchType.cardTitle(theme.ink)
                                        .copyWith(fontSize: 18),
                                  ),
                                  Text(
                                    'asked you to witness',
                                    style: VouchType.caption(theme.muted)
                                        .copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: VouchSpace.x4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.glass,
                            borderRadius:
                                BorderRadius.circular(VouchRadius.small),
                            border: Border.all(color: theme.line),
                          ),
                          child: Text(
                            '“${preview.promise}”',
                            style: VouchType.body(theme.ink)
                                .copyWith(fontSize: 15, height: 1.4),
                          ),
                        ),
                        const SizedBox(height: VouchSpace.x4),
                        VouchButton(
                          label: _joining ? 'Joining…' : 'Join as partner',
                          expand: true,
                          loading: _joining,
                          onPressed: _joining ? null : _join,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
