/// Owner creates the single promise and an invite.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

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
import '../state/track_controller.dart';

class CreateTrackScreen extends StatefulWidget {
  const CreateTrackScreen({super.key});

  @override
  State<CreateTrackScreen> createState() => _CreateTrackScreenState();
}

class _CreateTrackScreenState extends State<CreateTrackScreen> {
  final _promise = TextEditingController();
  final _why = TextEditingController();
  final _phone = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _promise.dispose();
    _why.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final promise = _promise.text.trim();
    if (promise.length < 4) {
      setState(() => _error = 'Give the promise a little more detail.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    final controller = context.read<TrackController>();
    final error = await controller.createTrack(
      promise: promise,
      promiseNote: _why.text.trim(),
      phone: _phone.text.trim(),
    );
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final busy = context.watch<TrackController>().busy;

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
              const VouchBackBar(annotation: '(001)'),
              const SizedBox(height: VouchSpace.x6),
              Reveal(
                index: 0,
                child: Text(
                  'What is\nthe one thing?',
                  style: VouchType.hero(theme.ink).copyWith(
                    fontSize: 44,
                    height: 0.94,
                  ),
                ),
              ),
              const SizedBox(height: VouchSpace.x3),
              Reveal(
                index: 1,
                child: Text(
                  'Small enough to do on a bad day.',
                  style: VouchType.body(theme.muted)
                      .copyWith(fontSize: 14, height: 1.4),
                ),
              ),
              const SizedBox(height: VouchSpace.x6),
              const Reveal(
                index: 2,
                child: SectionLabel(index: '01', title: 'the promise'),
              ),
              const SizedBox(height: VouchSpace.x3),
              Reveal(
                index: 3,
                child: Column(
                  children: <Widget>[
                    VouchField(
                      controller: _promise,
                      autofocus: true,
                      maxLength: VouchConfig.maxPromiseLength,
                      showCount: true,
                      textInputAction: TextInputAction.next,
                      style: VouchType.cardTitle(theme.ink).copyWith(
                        fontSize: 18,
                        height: 1.3,
                      ),
                      hint: 'Walk 30 minutes before sunset',
                      label: 'The promise',
                      prefix: VouchIcon(
                        VouchGlyph.star,
                        size: 17,
                        color: theme.faint,
                      ),
                    ),
                    const SizedBox(height: VouchSpace.x3),
                    VouchField(
                      controller: _why,
                      maxLength: VouchConfig.maxPromiseNoteLength,
                      minLines: 2,
                      maxLines: 4,
                      hint: 'For my knees, my head, and tomorrow’s me.',
                      label: 'Why this one? (optional)',
                    ),
                    const SizedBox(height: VouchSpace.x3),
                    VouchField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      maxLength: VouchConfig.maxPhoneLength,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9+\s()-]'),
                        ),
                      ],
                      hint: '+234 801 234 5678',
                      label: 'Your phone (optional)',
                      prefix: VouchIcon(
                        VouchGlyph.phone,
                        size: 17,
                        color: theme.faint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VouchSpace.x3),
              Reveal(
                index: 4,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    VouchIcon(
                      VouchGlyph.calendar,
                      size: 15,
                      color: theme.faint,
                    ),
                    const SizedBox(width: VouchSpace.x2),
                    Expanded(
                      child: Text(
                        'Your partner picks the days and the reminder time. '
                        'Your number is only shown to them.',
                        style: VouchType.caption(theme.faint)
                            .copyWith(fontSize: 11.5, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: VouchSpace.x4),
                Text(
                  _error!,
                  style: VouchType.caption(theme.missed)
                      .copyWith(fontSize: 13, height: 1.4),
                ),
              ],
              const SizedBox(height: VouchSpace.x6),
              Reveal(
                index: 5,
                child: VouchButton(
                  label: busy ? 'Creating…' : 'Create promise',
                  expand: true,
                  loading: busy,
                  onPressed: busy ? null : _create,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
