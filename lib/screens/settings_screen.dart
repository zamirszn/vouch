/// You, printed on clay: the account, the rhythm, the person on the other
/// side and the quiet switches. Flat cards, one black pill at a time.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../services/notification_service.dart';
import '../state/auth_controller.dart';
import '../state/theme_controller.dart';
import '../state/track_controller.dart';
import '../widgets/contact_sheet.dart';
import '../widgets/notification_permission_card.dart';
import '../widgets/poster.dart';
import '../widgets/sheet_frame.dart';
import '../widgets/vouch_avatar.dart';
import '../widgets/vouch_loader.dart';
import 'schedule_setup_screen.dart';

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
    final style = PosterStyle.of(context);
    final track = controller.track;
    final isPartner = controller.isPartner;
    final partnerName = isPartner
        ? (track?.ownerName ?? 'Owner')
        : (track?.partnerName ?? 'Partner');
    final partnerPhoto =
        isPartner ? track?.ownerPhotoUrl : track?.partnerPhotoUrl;
    final partnerPhone = isPartner ? track?.ownerPhone : track?.partnerPhone;
    final myPhone = isPartner ? track?.partnerPhone : track?.ownerPhone;
    final roleLabel = isPartner ? 'Witness' : 'Promise owner';
    final notificationStatus = _notificationStatus;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        114 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const PosterTopBar(right: 'You / (003)'),
          const SizedBox(height: 28),
          const PosterHeadline(
            'You\n& them.',
            size: 50,
            accentTail: 2,
          ),
          const SizedBox(height: 10),
          Text(
            'Account, rhythm and the person on the other side.',
            style: TextStyle(
              fontFamily: 'InstrumentSans',
              fontSize: 13,
              height: 1.35,
              color: style.muted,
            ),
          ),
          const SizedBox(height: 24),
          PosterCard(
            child: Row(
              children: <Widget>[
                VouchAvatar(
                  name: auth.displayName,
                  photoUrl: auth.photoUrl,
                  size: 54,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        auth.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'InstrumentSans',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          height: 1.1,
                          color: style.cardInk,
                          fontVariations: const <FontVariation>[
                            FontVariation('wght', 700),
                          ],
                        ),
                      ),
                      if (auth.email.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          auth.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'InstrumentSans',
                            fontSize: 12,
                            color: style.cardMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      PosterTag(
                        roleLabel,
                        color: (isPartner ? PosterColors.coral : PosterColors.cobalt)
                            .withValues(alpha: 0.13),
                        foreground:
                            isPartner ? PosterColors.coral : PosterColors.cobalt,
                        icon: isPartner
                            ? Icons.visibility_rounded
                            : Icons.flag_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _Tile(
            icon: Icons.phone_rounded,
            title: 'Phone number',
            subtitle: (myPhone?.trim().isNotEmpty ?? false)
                ? myPhone!
                : (auth.profile?.phone?.trim().isNotEmpty ?? false)
                    ? auth.profile!.phone!
                    : 'Add a number so your partner can reach you',
            onTap: () => _editPhone(controller),
            trailing: const Icon(Icons.edit_outlined, size: 18),
          ),
          const SizedBox(height: 28),
          const PosterSectionLabel('01', 'the rhythm'),
          const SizedBox(height: 10),
          PosterCard(
            onTap: isPartner
                ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ScheduleSetupScreen(),
                      ),
                    )
                : null,
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: PosterColors.cobalt.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: PosterColors.cobalt,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        track?.schedule?.summary ?? 'No schedule yet',
                        style: TextStyle(
                          fontFamily: 'InstrumentSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: style.cardInk,
                          fontVariations: const <FontVariation>[
                            FontVariation('wght', 700),
                          ],
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        track?.schedule == null
                            ? 'Waiting for the witness'
                            : '${track!.schedule!.kind.describe()} in ${track.schedule!.zoneLabel}',
                        style: TextStyle(
                          fontFamily: 'InstrumentSans',
                          fontSize: 12,
                          height: 1.3,
                          color: style.cardMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPartner)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: style.cardMuted,
                  )
                else
                  PosterLabel(
                    'set by\nwitness',
                    color: style.cardMuted,
                    size: 8,
                    tracking: 0.8,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          PosterSectionLabel(
            '02',
            'notifications',
            trailing: IconButton(
              tooltip: 'Refresh status',
              onPressed: _loadStatus,
              icon: Icon(
                Icons.refresh_rounded,
                size: 19,
                color: style.ink,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            notificationStatus == null
                ? 'Checking this phone…'
                : notificationStatus.notificationsEnabled
                    ? '${notificationStatus.pendingCount} reminder${notificationStatus.pendingCount == 1 ? '' : 's'} scheduled'
                    : 'Reminders are off',
            style: TextStyle(
              fontFamily: 'InstrumentSans',
              fontSize: 12,
              color: style.muted,
            ),
          ),
          const SizedBox(height: 10),
          const NotificationPermissionCard(),
          _Tile(
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
                : const Icon(Icons.chevron_right_rounded, size: 18),
          ),
          const SizedBox(height: 28),
          PosterSectionLabel(
            '03',
            isPartner ? 'the promise owner' : 'your witness',
          ),
          const SizedBox(height: 10),
          PosterCard(
            child: Row(
              children: <Widget>[
                VouchAvatar(
                  name: partnerName,
                  photoUrl: partnerPhoto,
                  size: 46,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        partnerName,
                        style: TextStyle(
                          fontFamily: 'InstrumentSans',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: style.cardInk,
                          fontVariations: const <FontVariation>[
                            FontVariation('wght', 700),
                          ],
                        ),
                      ),
                      Text(
                        (partnerPhone?.trim().isNotEmpty ?? false)
                            ? partnerPhone!
                            : 'No phone number shared yet',
                        style: TextStyle(
                          fontFamily: 'InstrumentSans',
                          fontSize: 12,
                          color: style.cardMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  tooltip: 'Contact',
                  style: IconButton.styleFrom(
                    backgroundColor: style.cardInk,
                    foregroundColor: PosterColors.acid,
                  ),
                  onPressed: () => showContactSheet(
                    context,
                    name: partnerName.split(RegExp(r'\s+')).first,
                    phone: partnerPhone,
                    message:
                        'Checking in on our Vouch promise: ${track?.promise ?? ''}',
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const PosterSectionLabel('04', 'appearance'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final mode in <ThemeMode>[
                ThemeMode.system,
                ThemeMode.light,
                ThemeMode.dark,
              ])
                _ChoicePill(
                  selected: theme.mode == mode,
                  icon: switch (mode) {
                    ThemeMode.system => Icons.brightness_auto_rounded,
                    ThemeMode.light => Icons.light_mode_rounded,
                    ThemeMode.dark => Icons.dark_mode_rounded,
                  },
                  label: switch (mode) {
                    ThemeMode.system => 'System',
                    ThemeMode.light => 'Light',
                    ThemeMode.dark => 'Dark',
                  },
                  onTap: () => theme.setMode(mode),
                ),
            ],
          ),
          if (controller.isDemo) ...<Widget>[
            const SizedBox(height: 28),
            const PosterSectionLabel(
              '05',
              'Demo preview',
              uppercase: false,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _ChoicePill(
                  selected: !isPartner,
                  icon: Icons.flag_rounded,
                  label: 'Owner',
                  onTap: () => controller.switchDemoRole(false),
                ),
                _ChoicePill(
                  selected: isPartner,
                  icon: Icons.visibility_rounded,
                  label: 'Witness',
                  onTap: () => controller.switchDemoRole(true),
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          if (!auth.demoMode) ...<Widget>[
            _Tile(
              icon: Icons.logout_rounded,
              title: 'Sign out',
              subtitle: null,
              onTap: _signOut,
              tint: style.muted,
            ),
            const SizedBox(height: 8),
          ],
          _Tile(
            icon: isPartner
                ? Icons.exit_to_app_rounded
                : Icons.stop_circle_outlined,
            title: isPartner ? 'Leave as witness' : 'End this promise',
            subtitle: isPartner
                ? 'Stop witnessing. Their record stays.'
                : 'End it for both of you.',
            onTap: () => _endOrLeave(controller),
            tint: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 24),
          PosterFooter(
            lead: 'Vouch',
            muted: 'Version 1.0.0',
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
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
    final style = PosterStyle.of(context);
    final color = tint ?? PosterColors.cobalt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PosterCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      color: style.cardInk,
                      fontVariations: const <FontVariation>[
                        FontVariation('wght', 600),
                      ],
                    ),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      style: TextStyle(
                        fontFamily: 'InstrumentSans',
                        fontSize: 11.5,
                        height: 1.3,
                        color: style.cardMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 8),
              IconTheme(
                data: IconThemeData(color: style.cardMuted, size: 18),
                child: trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    final fg = selected ? style.pillInk : style.ink;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? style.pill : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? style.pill : style.ink.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'InstrumentSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
                fontVariations: const <FontVariation>[
                  FontVariation('wght', 600),
                ],
              ),
            ),
          ],
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
