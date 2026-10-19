/// Owner creates the single promise and an invite.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../state/track_controller.dart';
import '../widgets/poster.dart';
import '../widgets/reveal.dart';
import '../widgets/sheet_frame.dart';

class CreateTrackScreen extends StatefulWidget {
  const CreateTrackScreen({super.key});

  @override
  State<CreateTrackScreen> createState() => _CreateTrackScreenState();
}

class _CreateTrackScreenState extends State<CreateTrackScreen> {
  final _formKey = GlobalKey<FormState>();
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final controller = context.read<TrackController>();
    final error = await controller.createTrack(
      promise: _promise.text.trim(),
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
    final text = Theme.of(context).textTheme;
    final busy = context.watch<TrackController>().busy;

    return Scaffold(
      body: PosterField(
        tone: PosterTone.butter,
        child: Builder(
          builder: (context) {
            final style = PosterStyle.of(context);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const PosterBackBar(right: '(001)'),
                    const SizedBox(height: 30),
                    const Reveal(
                      child: PosterHeadline(
                        'What is\nthe one thing?',
                        size: 44,
                        accentTail: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Small enough to do on a bad day.',
                      style: TextStyle(
                        fontFamily: 'InstrumentSans',
                        fontSize: 14,
                        height: 1.4,
                        color: style.muted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const PosterSectionLabel('01', 'the promise'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _promise,
                      autofocus: true,
                      maxLength: VouchConfig.maxPromiseLength,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      style: text.titleLarge?.copyWith(
                        fontSize: 20,
                        color: style.ink,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'The promise',
                        hintText: 'Walk 30 minutes before sunset',
                        prefixIcon: Icon(Icons.flag_rounded),
                      ),
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.length < 4) {
                          return 'Give the promise a little more detail.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _why,
                      maxLength: VouchConfig.maxPromiseNoteLength,
                      minLines: 2,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Why this one? (optional)',
                        hintText: 'For my knees, my head, and tomorrow’s me.',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      maxLength: VouchConfig.maxPhoneLength,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9+\s()-]'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Your phone (optional)',
                        hintText: '+234 801 234 5678',
                        prefixIcon: Icon(Icons.phone_rounded),
                        helperText: 'For call, text or WhatsApp.',
                        helperMaxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SheetNote(
                      icon: Icons.tune_rounded,
                      text:
                          'Your partner picks the days and the reminder time.',
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontFamily: 'InstrumentSans',
                          fontSize: 13,
                          height: 1.4,
                          color: Color(0xFF8E2A22),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    PosterPill(
                      label: busy ? 'Creating…' : 'Create promise',
                      onPressed: busy ? null : _create,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
