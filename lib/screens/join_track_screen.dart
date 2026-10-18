/// Partner joins with the owner's 8-character invite code.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../models/track.dart';
import '../state/track_controller.dart';
import '../theme/vouch_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/vouch_avatar.dart';
import '../widgets/vouch_loader.dart';

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
      setState(() => _error = 'Enter the full ${VouchConfig.inviteLength}-character code.');
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
          _error = 'No promise matches that code. Check the letters and digits.';
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
    final scheme = Theme.of(context).colorScheme;
    final preview = _preview;

    return Scaffold(
      body: AnimatedBackground(
        intensity: 0.8,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Spacer(),
                    Text(
                      'PARTNER',
                      style: text.labelSmall?.copyWith(
                        color: VouchColors.coral,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Reveal(
                  child: Text(
                    'Got a code?',
                    style: text.displaySmall?.copyWith(
                      fontSize: 42,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 8-character code from your person.',
                  style: text.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 26),
                TextField(
                  controller: _code,
                  maxLength: VouchConfig.inviteLength,
                  textCapitalization: TextCapitalization.characters,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: text.headlineMedium?.copyWith(letterSpacing: 5),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    _UpperCaseFormatter(),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'ABCD1234',
                    counterText: '',
                    labelText: 'Invite code',
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
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.tonalIcon(
                    onPressed: _looking ? null : _find,
                    icon: _looking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: VouchLoader(size: 22),
                          )
                        : const Icon(Icons.search_rounded),
                    label: Text(_looking ? 'Looking…' : 'Find the promise'),
                  ),
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      _error!,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
                if (preview != null) ...<Widget>[
                  const SizedBox(height: 28),
                  const SectionHeader(
                    index: '01',
                    title: 'Is this them?',
                  ),
                  ExpressiveCard(
                    color: scheme.primaryContainer.withValues(alpha: 0.55),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            VouchAvatar(
                              name: preview.ownerName,
                              photoUrl: preview.ownerPhotoUrl,
                              size: 52,
                              ring: true,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    preview.ownerName,
                                    style: text.titleLarge,
                                  ),
                                  Text(
                                    'asked you to witness',
                                    style: text.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '“${preview.promise}”',
                            style: text.titleMedium?.copyWith(height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: VouchColors.coral,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _joining ? null : _join,
                            icon: _joining
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: VouchLoader(size: 22, color: Colors.white),
                                  )
                                : const Icon(Icons.handshake_rounded),
                            label: Text(
                              _joining ? 'Joining…' : 'Join as partner',
                            ),
                          ),
                        ),
                      ],
                    ),
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
