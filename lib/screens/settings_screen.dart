/// Profile, schedule, notifications, appearance and account controls.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../services/notification_service.dart';
import '../state/auth_controller.dart';
import '../state/theme_controller.dart';
import '../state/track_controller.dart';
import '../theme/vouch_theme.dart';
import '../widgets/contact_sheet.dart';
import '../widgets/notification_permission_card.dart';
import '../widgets/section_header.dart';
import '../widgets/sheet_frame.dart';
import '../widgets/soul.dart';
import '../widgets/status_pill.dart';
import '../widgets/vouch_avatar.dart';
import 'schedule_setup_screen.dart';
import '../widgets/vouch_loader.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  VouchNotificationStatus? _notificationStatus;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStatus());
  }

  Future<void> _loadStatus() async {
    if (!mounted) return;
    final status = await context.read<NotificationService>().status();
    if (!mounted) return;
    setState(() => _notificationStatus = status);
  }

  Future<void> _sendTest(TrackController controller) async {
    final track = controller.track;
    if (track == null || _testing) return;
    setState(() => _testing = true);
    final service = context.read<NotificationService>();
    if (!(_notificationStatus?.notificationsEnabled ?? true)) {
      await service.requestPermissions();
    }
    await service.showTest(track: track, asPartner: controller.isPartner);
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _testing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test reminder sent.')),
    );
    _loadStatus();
  }

  Future<void> _editPhone(TrackController controller) async {
    final track = controller.track;
    final auth = context.read<AuthController>();
    final current = controller.isOwner
        ? (track?.ownerPhone ?? auth.profile?.phone)
        : (track?.partnerPhone ?? auth.profile?.phone);
    final saved = await showVouchSheet<bool>(
      context,
      _PhoneSheet(
        initial: current,
        onSave: controller.saveMyPhone,
      ),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone number updated.')),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    bool destructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _endOrLeave(TrackController controller) async {
    final partner = controller.isPartner;
    final ok = await _confirm(
      title: partner ? 'Leave this promise?' : 'End this promise?',
      message: partner
          ? 'You will stop witnessing this promise. The owner keeps their record and can invite someone else.'
          : 'This ends the promise for both of you. Your history stays saved, but today stops counting.',
      action: partner ? 'Leave' : 'End promise',
    );
    if (!ok || !mounted) return;
    final error =
        partner ? await controller.leaveTrack() : await controller.endTrack();
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _signOut() async {
    final ok = await _confirm(
      title: 'Sign out?',
      message:
          'Your promise stays in Firebase. Sign back in with the same Google account to pick it up.',
      action: 'Sign out',
      destructive: false,
    );
    if (!ok || !mounted) return;
    await context.read<AuthController>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrackController>();
    final auth = context.watch<AuthController>();
    final theme = context.watch<ThemeController>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final track = controller.track;
    final isPartner = controller.isPartner;
    final partnerName = isPartner
        ? (track?.ownerName ?? 'Owner')
        : (track?.partnerName ?? 'Partner');
    final partnerPhoto =
        isPartner ? track?.ownerPhotoUrl : track?.partnerPhotoUrl;
    final partnerPhone =
        isPartner ? track?.ownerPhone : track?.partnerPhone;
    final myPhone = isPartner ? track?.partnerPhone : track?.ownerPhone;
    final roleLabel = isPartner ? 'Witness' : 'Promise owner';
    final notificationStatus = _notificationStatus;

    return TopFade(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 118),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Asterisk(size: 11, color: scheme.secondary),
                const SizedBox(width: 7),
                Text(
                  'YOUR VOUCH',
                  style: text.labelSmall?.copyWith(
                    color: scheme.primary,
                    letterSpacing: 1.9,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              'You.',
              style: text.displaySmall?.copyWith(
                fontSize: 34,
                height: 1.0,
                letterSpacing: -0.9,
              ),
            ),
            const SizedBox(height: 24),
            InkCard(
              child: Row(
                children: <Widget>[
                  VouchAvatar(
                    name: auth.displayName,
                    photoUrl: auth.photoUrl,
                    size: 62,
                    ring: true,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(auth.displayName, style: text.titleLarge),
                        if (auth.email.isNotEmpty)
                          Text(
                            auth.email,
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 8),
                        StatusPill(
                          label: roleLabel,
                          color: isPartner
                              ? VouchColors.coral
                              : VouchColors.indigo,
                          icon: isPartner
                              ? Icons.visibility_rounded
                              : Icons.flag_rounded,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.phone_rounded,
              title: 'Phone number',
              subtitle: (myPhone?.trim().isNotEmpty ?? false)
                  ? myPhone!
                  : (auth.profile?.phone?.trim().isNotEmpty ?? false)
                      ? auth.profile!.phone!
                      : 'Add a number so ${isPartner ? 'the owner' : 'your witness'} can reach you',
              onTap: () => _editPhone(controller),
              trailing: const Icon(Icons.edit_outlined, size: 20),
            ),
            const SizedBox(height: 30),
            const SectionHeader(
              index: '01',
              title: 'The rhythm',
            ),
          InkCard(
            onTap: isPartner
                ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ScheduleSetupScreen(),
                      ),
                    )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: VouchColors.indigo.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.schedule_rounded,
                        color: VouchColors.indigo,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            track?.schedule?.summary ?? 'No schedule yet',
                            style: text.titleMedium,
                          ),
                          Text(
                            track?.schedule == null
                                ? 'Waiting for the witness'
                                : '${track!.schedule!.kind.describe()} in ${track.schedule!.zoneLabel}',
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPartner)
                      const Icon(Icons.chevron_right_rounded)
                    else
                      Text(
                        'Set by\nwitness',
                        textAlign: TextAlign.center,
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          SectionHeader(
            index: '02',
            title: 'Notifications',
            subtitle: notificationStatus == null
                ? 'Checking this phone…'
                : notificationStatus.notificationsEnabled
                    ? '${notificationStatus.pendingCount} reminder${notificationStatus.pendingCount == 1 ? '' : 's'} scheduled'
                    : 'Reminders are off',
            trailing: IconButton(
              tooltip: 'Refresh status',
              onPressed: _loadStatus,
              icon: const Icon(Icons.refresh_rounded, size: 20),
            ),
          ),
          const NotificationPermissionCard(),
          _SettingsTile(
            icon: Icons.notification_add_outlined,
            title: 'Send a test reminder',
            subtitle: null,
            onTap: _testing ? null : () => _sendTest(controller),
            trailing: _testing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: VouchLoader(size: 22),
                  )
                : const Icon(Icons.chevron_right_rounded),
          ),
          const SizedBox(height: 30),
          SectionHeader(
            index: '03',
            title: isPartner ? 'The promise owner' : 'Your witness',
          ),
          InkCard(
            child: Row(
              children: <Widget>[
                VouchAvatar(
                  name: partnerName,
                  photoUrl: partnerPhoto,
                  size: 50,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(partnerName, style: text.titleMedium),
                      Text(
                        (partnerPhone?.trim().isNotEmpty ?? false)
                            ? partnerPhone!
                            : 'No phone number shared yet',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Contact',
                  onPressed: () => showContactSheet(
                    context,
                    name: partnerName.split(RegExp(r'\s+')).first,
                    phone: partnerPhone,
                    message:
                        'Checking in on our Vouch promise: ${track?.promise ?? ''}',
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const SectionHeader(index: '04', title: 'Appearance'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final mode in <ThemeMode>[
                ThemeMode.system,
                ThemeMode.light,
                ThemeMode.dark,
              ])
                ChoiceChip(
                  selected: theme.mode == mode,
                  onSelected: (_) => theme.setMode(mode),
                  avatar: Icon(
                    switch (mode) {
                      ThemeMode.system => Icons.brightness_auto_rounded,
                      ThemeMode.light => Icons.light_mode_rounded,
                      ThemeMode.dark => Icons.dark_mode_rounded,
                    },
                    size: 18,
                  ),
                  label: Text(
                    switch (mode) {
                      ThemeMode.system => 'System',
                      ThemeMode.light => 'Light',
                      ThemeMode.dark => 'Dark',
                    },
                  ),
                ),
            ],
          ),
          if (controller.isDemo) ...<Widget>[
            const SizedBox(height: 30),
            const SectionHeader(
              index: '05',
              title: 'Demo preview',
            ),
            Wrap(
              spacing: 8,
              children: <Widget>[
                ChoiceChip(
                  selected: !isPartner,
                  onSelected: (_) => controller.switchDemoRole(false),
                  avatar: const Icon(Icons.flag_rounded, size: 18),
                  label: const Text('Owner'),
                ),
                ChoiceChip(
                  selected: isPartner,
                  onSelected: (_) => controller.switchDemoRole(true),
                  avatar: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('Witness'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 30),
          if (!auth.demoMode) ...<Widget>[
            _SettingsTile(
              icon: Icons.logout_rounded,
              title: 'Sign out',
              subtitle: null,
              onTap: _signOut,
              tint: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
          ],
          _SettingsTile(
            icon: isPartner ? Icons.exit_to_app_rounded : Icons.stop_circle_outlined,
            title: isPartner ? 'Leave as witness' : 'End this promise',
            subtitle: isPartner
                ? 'Stop witnessing. Their record stays.'
                : 'End it for both of you.',
            onTap: () => _endOrLeave(controller),
            tint: scheme.error,
          ),
          const SizedBox(height: 26),
          Center(
            child: Text(
              '${VouchConfig.appName} 1.0.0',
              style: text.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
    this.tint,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final color = tint ?? VouchColors.indigo;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: text.titleSmall),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneSheet extends StatefulWidget {
  const _PhoneSheet({required this.initial, required this.onSave});

  final String? initial;
  final Future<String?> Function(String? phone) onSave;

  @override
  State<_PhoneSheet> createState() => _PhoneSheetState();
}

class _PhoneSheetState extends State<_PhoneSheet> {
  late final TextEditingController _phone =
      TextEditingController(text: widget.initial ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(_phone.text.trim());
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return SheetFrame(
      title: 'Your phone number',
      subtitle:
          'Only your partner sees it. It powers the call, WhatsApp and SMS shortcuts.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _phone,
            autofocus: true,
            keyboardType: TextInputType.phone,
            maxLength: VouchConfig.maxPhoneLength,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Phone (optional)',
              hintText: '+234 801 234 5678',
              prefixIcon: Icon(Icons.phone_rounded),
            ),
          ),
          if (_error != null) ...<Widget>[
            Text(
              _error!,
              style: text.bodySmall?.copyWith(color: scheme.error),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: VouchLoader(size: 22),
                    )
                  : const Text('Save number'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _saving
                ? null
                : () async {
                    _phone.clear();
                    await _save();
                  },
            child: const Text('Remove number'),
          ),
        ],
      ),
    );
  }
}
