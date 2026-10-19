/// Partner joins with the owner's 8-character invite code.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../models/track.dart';
import '../state/track_controller.dart';
import '../widgets/poster.dart';
import '../widgets/reveal.dart';
import '../widgets/vouch_avatar.dart';

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
    final text = Theme.of(context).textTheme;
    final preview = _preview;

    return Scaffold(
      body: PosterField(
        tone: PosterTone.cream,
        child: Builder(
          builder: (context) {
            final style = PosterStyle.of(context);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const PosterBackBar(right: '(002)'),
                  const SizedBox(height: 30),
                  const Reveal(
                    child: PosterHeadline(
                      'Got a\ncode?',
                      size: 46,
                      accentTail: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter the 8-character code from your person.',
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      fontSize: 14,
                      height: 1.4,
                      color: style.muted,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const PosterSectionLabel('01', 'the invite'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _code,
                    maxLength: VouchConfig.inviteLength,
                    textCapitalization: TextCapitalization.characters,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: text.headlineMedium?.copyWith(
                      letterSpacing: 5,
                      color: PosterColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      _UpperCaseFormatter(),
                    ],
                    decoration: InputDecoration(
                      hintText: 'ABCD1234',
                      counterText: '',
                      filled: true,
                      fillColor: PosterColors.butter,
                      hintStyle: TextStyle(
                        color: PosterColors.ink.withValues(alpha: 0.28),
                        letterSpacing: 5,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: PosterColors.ink,
                          width: 1.6,
                        ),
                      ),
                    ),
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
                  const SizedBox(height: 12),
                  PosterPill(
                    label: _looking ? 'Looking…' : 'Find the promise',
                    icon: Icons.search_rounded,
                    onPressed: _looking ? null : _find,
                  ),
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 14),
                    PosterCard(
                      color: PosterColors.coral,
                      foreground: PosterColors.cream,
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontFamily: 'InstrumentSans',
                          fontSize: 13,
                          height: 1.4,
                          color: PosterColors.cream,
                        ),
                      ),
                    ),
                  ],
                  if (preview != null) ...<Widget>[
                    const SizedBox(height: 28),
                    const PosterSectionLabel('02', 'is this them?'),
                    const SizedBox(height: 10),
                    PosterCard(
                      color: PosterColors.cobalt,
                      foreground: PosterColors.cream,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              VouchAvatar(
                                name: preview.ownerName,
                                photoUrl: preview.ownerPhotoUrl,
                                size: 48,
                                ring: true,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      preview.ownerName,
                                      style: const TextStyle(
                                        fontFamily: 'InstrumentSans',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.4,
                                        color: PosterColors.cream,
                                      ),
                                    ),
                                    Text(
                                      'asked you to witness',
                                      style: TextStyle(
                                        fontFamily: 'InstrumentSans',
                                        fontSize: 12,
                                        color: PosterColors.cream.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: PosterColors.cream.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: PosterColors.cream.withValues(
                                  alpha: 0.22,
                                ),
                              ),
                            ),
                            child: Text(
                              '“${preview.promise}”',
                              style: const TextStyle(
                                fontFamily: 'InstrumentSans',
                                fontSize: 15,
                                height: 1.4,
                                color: PosterColors.cream,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          PosterPill(
                            label: _joining ? 'Joining…' : 'Join as partner',
                            onPressed: _joining ? null : _join,
                            color: PosterColors.cream,
                            foreground: PosterColors.ink,
                            arrowColor: PosterColors.acid,
                            arrowForeground: PosterColors.ink,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
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
