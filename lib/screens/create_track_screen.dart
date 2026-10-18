/// Owner creates the single promise and an invite.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../state/track_controller.dart';
import '../widgets/animated_background.dart';
import '../widgets/reveal.dart';
import '../widgets/sheet_frame.dart';
import '../widgets/vouch_loader.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final busy = context.watch<TrackController>().busy;

    return Scaffold(
      body: AnimatedBackground(
        intensity: 0.8,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Spacer(),
                    Text(
                      'STEP 1 OF 2',
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Reveal(
                          child: Text(
                            'What is the\none thing?',
                            style: text.displaySmall?.copyWith(
                              fontSize: 40,
                              height: 1.03,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Small enough to do on a bad day.',
                          style: text.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _promise,
                          autofocus: true,
                          maxLength: VouchConfig.maxPromiseLength,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          style: text.titleLarge?.copyWith(fontSize: 20),
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
                            style: text.bodyMedium?.copyWith(
                              color: scheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: FilledButton.icon(
                            onPressed: busy ? null : _create,
                            icon: busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: VouchLoader(size: 22, color: Colors.white),
                                  )
                                : const Icon(Icons.arrow_forward_rounded),
                            label: Text(busy ? 'Creating…' : 'Create promise'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
