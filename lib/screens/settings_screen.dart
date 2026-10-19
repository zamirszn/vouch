/// You: the account, the rhythm, the person on the other side and the quiet
/// switches. A glass list, one signal action at a time.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../components/glass_card.dart';
import '../components/pressable.dart';
import '../components/reveal.dart';
import '../components/section_label.dart';
import '../components/stat_tile.dart';
import '../components/vouch_button.dart';
import '../components/vouch_dialog.dart';
import '../components/vouch_field.dart';
import '../components/vouch_icon.dart';
import '../components/vouch_loader.dart';
import '../components/vouch_sheet.dart';
import '../components/vouch_toast.dart';
import '../components/vouch_top_bar.dart';
import '../core/constants.dart';
import '../design/vouch_route.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import '../services/notification_service.dart';
import '../state/auth_controller.dart';
import '../state/theme_controller.dart';
import '../state/track_controller.dart';
import '../components/contact_panel.dart';
import '../widgets/notification_permission_card.dart';
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
    VouchToast.show(
      context,
      'Test reminder sent.',
      accent: VouchScope.of(context).kept,
    );
    _loadStatus();
  }

  Future<void> _editPhone(TrackController controller) async {
    final track = controller.track;
    final auth = context.read<AuthController>();
    final current = controller.isOwner
        ? (track?.ownerPhone ?? auth.profile?.phone)
        : (track?.partnerPhone ?? auth.profile?.phone);
    final saved = await showVouchPanel<bool>(
      context,
      (context) => _PhoneSheet(
        initial: current,
        onSave: controller.saveMyPhone,
      ),
    );
    if (!mounted || saved != true) return;
    VouchToast.show(
      context,
      'Phone number updated.',
      accent: VouchScope.of(context).kept,
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    bool destructive = true,
  }) {
    return showVouchConfirm(
      context,
      title: title,
      message: message,
      action: action,
      destructive: destructive,
    );
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
      VouchToast.show(
        context,
        error,
        glyph: VouchGlyph.closeCircle,
        accent: VouchScope.of(context).missed,
      );
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
    final themeController = context.watch<ThemeController>();
    final theme = VouchScope.of(context);
    final track = controller.track;
    final isPartner = controller.isPartner;
    final partnerName = isPartner
        ? (track?.ownerName ?? 'Owner')
        : (track?.partnerName ?? 'Partner');
    final partnerPhone = isPartner ? track?.ownerPhone : track?.partnerPhone;
    final myPhone = isPartner ? track?.partnerPhone : track?.ownerPhone;
    final roleLabel = isPartner ? 'Witness' : 'Promise owner';
    final notificationStatus = _notificationStatus;
    final statusLine = notificationStatus == null
        ? 'Checking this phone…'
        : notificationStatus.notificationsEnabled
            ? '${notificationStatus.pendingCount} reminder'
                '${notificationStatus.pendingCount == 1 ? '' : 's'} scheduled'
            : 'Reminders are off';

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          VouchSpace.gutter,
          VouchSpace.x2,
          VouchSpace.gutter,
          VouchSpace.navHeight +
              MediaQuery.viewPaddingOf(context).bottom +
              VouchSpace.x10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Reveal(
              index: 0,
              child: VouchTopBar(annotation: 'You / (003)'),
            ),
            const SizedBox(height: VouchSpace.x6),
            Reveal(
              index: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'You\n& them.',
                    style: VouchType.hero(theme.ink)
                        .copyWith(fontSize: 52, height: 0.92),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Account, rhythm and the person on the other side.',
                    style: VouchType.caption(theme.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VouchSpace.x6),
            Reveal(
              index: 2,
              child: GlassCard(
                radius: VouchRadius.card,
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: <Widget>[
                    VouchAvatar(
                      initials: _initials(auth.displayName),
                      size: 54,
                    ),
                    const SizedBox(width: VouchSpace.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            auth.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VouchType.cardTitle(theme.ink)
                                .copyWith(fontSize: 19),
                          ),
                          if (auth.email.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 2),
                            Text(
                              auth.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: VouchType.caption(theme.muted)
                                  .copyWith(fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 9),
                          StatusChip(
                            label: roleLabel,
                            tone: isPartner
                                ? VouchTone.pending
                                : VouchTone.kept,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: VouchSpace.x2),
            Reveal(
              index: 3,
              child: _RowCard(
                glyph: VouchGlyph.phone,
                title: 'Phone number',
                subtitle: (myPhone?.trim().isNotEmpty ?? false)
                    ? myPhone!
                    : (auth.profile?.phone?.trim().isNotEmpty ?? false)
                        ? auth.profile!.phone!
                        : 'Add a number so your partner can reach you',
                onTap: () => _editPhone(controller),
                trailing: VouchIcon(
                  VouchGlyph.edit,
                  size: 16,
                  color: theme.muted,
                ),
              ),
            ),
            const SizedBox(height: VouchSpace.x6),
            const Reveal(
              index: 4,
              child: SectionLabel(index: '01', title: 'the rhythm'),
            ),
            const SizedBox(height: VouchSpace.x3),
            Reveal(
              index: 5,
              child: _RowCard(
                glyph: VouchGlyph.clock,
                title: track?.schedule?.summary ?? 'No schedule yet',
                subtitle: track?.schedule == null
                    ? 'Waiting for the witness'
                    : '${track!.schedule!.kind.describe()} in '
                        '${track.schedule!.zoneLabel}',
                onTap: isPartner
                    ? () => pushVouch(
                          context,
                          (context) => const ScheduleSetupScreen(),
                        )
                    : null,
                trailing: isPartner
                    ? VouchIcon(
                        VouchGlyph.chevronRight,
                        size: 16,
                        color: theme.muted,
                      )
                    : Text(
                        'SET BY\nWITNESS',
                        textAlign: TextAlign.right,
                        style: VouchType.label(theme.faint, size: 8),
                      ),
              ),
            ),
            const SizedBox(height: VouchSpace.x6),
            Reveal(
              index: 6,
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: SectionLabel(index: '02', title: 'notifications'),
                  ),
                  const SizedBox(width: VouchSpace.x2),
                  Pressable(
                    haptic: false,
                    semanticLabel: 'Refresh status',
                    onTap: _loadStatus,
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.glassStrong,
                        border: Border.all(color: theme.line, width: 1),
                      ),
                      child: VouchIcon(
                        VouchGlyph.refresh,
                        size: 14,
                        color: theme.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VouchSpace.x2),
            Reveal(
              index: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(statusLine, style: VouchType.caption(theme.muted)),
                  const SizedBox(height: VouchSpace.x3),
                  const NotificationPermissionCard(),
                  const SizedBox(height: VouchSpace.x2),
                  _RowCard(
                    glyph: VouchGlyph.bell,
                    title: 'Send a test reminder',
                    onTap: _testing ? null : () => _sendTest(controller),
                    tint: theme.kept,
                    trailing: _testing
                        ? VouchLoader(size: 16, color: theme.ink)
                        : VouchIcon(
                            VouchGlyph.chevronRight,
                            size: 16,
                            color: theme.muted,
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VouchSpace.x6),
            Reveal(
              index: 8,
              child: SectionLabel(
                index: '03',
                title: isPartner ? 'the promise owner' : 'your witness',
              ),
            ),
            const SizedBox(height: VouchSpace.x3),
            Reveal(
              index: 9,
              child: GlassCard(
                radius: VouchRadius.medium,
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Row(
                  children: <Widget>[
                    VouchAvatar(initials: _initials(partnerName), size: 46),
                    const SizedBox(width: VouchSpace.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            partnerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VouchType.bodyStrong(theme.ink)
                                .copyWith(fontSize: 15.5),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            (partnerPhone?.trim().isNotEmpty ?? false)
                                ? partnerPhone!
                                : 'No phone number shared yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VouchType.caption(theme.muted)
                                .copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: VouchSpace.x2),
                    CircleAction(
                      glyph: VouchGlyph.message,
                      size: 42,
                      background: theme.ink,
                      foreground: theme.canvas,
                      border: theme.ink,
                      semanticLabel: 'Contact',
                      onTap: () => showContactSheet(
                        context,
                        name: partnerName.split(RegExp(r'\s+')).first,
                        phone: partnerPhone,
                        message:
                            'Checking in on our Vouch promise: ${track?.promise ?? ''}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: VouchSpace.x6),
            const Reveal(
              index: 10,
              child: SectionLabel(index: '04', title: 'appearance'),
            ),
            const SizedBox(height: VouchSpace.x3),
            Reveal(
              index: 11,
              child: Wrap(
                spacing: VouchSpace.x2,
                runSpacing: VouchSpace.x2,
                children: <Widget>[
                  for (final mode in <VouchThemeMode>[
                    VouchThemeMode.system,
                    VouchThemeMode.light,
                    VouchThemeMode.dark,
                  ])
                    _ChoicePill(
                      selected: themeController.mode == mode,
                      glyph: switch (mode) {
                        VouchThemeMode.system => VouchGlyph.eye,
                        VouchThemeMode.light => VouchGlyph.sun,
                        VouchThemeMode.dark => VouchGlyph.moon,
                      },
                      label: switch (mode) {
                        VouchThemeMode.system => 'System',
                        VouchThemeMode.light => 'Light',
                        VouchThemeMode.dark => 'Dark',
                      },
                      onTap: () => themeController.setMode(mode),
                    ),
                ],
              ),
            ),
            if (controller.isDemo) ...<Widget>[
              const SizedBox(height: VouchSpace.x6),
              const Reveal(
                index: 12,
                child: SectionLabel(
                  index: '05',
                  title: 'Demo preview',
                  preserveCase: true,
                ),
              ),
              const SizedBox(height: VouchSpace.x3),
              Reveal(
                index: 13,
                child: Wrap(
                  spacing: VouchSpace.x2,
                  runSpacing: VouchSpace.x2,
                  children: <Widget>[
                    _ChoicePill(
                      selected: !isPartner,
                      glyph: VouchGlyph.star,
                      label: 'Owner',
                      onTap: () => controller.switchDemoRole(false),
                    ),
                    _ChoicePill(
                      selected: isPartner,
                      glyph: VouchGlyph.eye,
                      label: 'Witness',
                      onTap: () => controller.switchDemoRole(true),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: VouchSpace.x6),
            if (!auth.demoMode) ...<Widget>[
              Reveal(
                index: 14,
                child: _RowCard(
                  glyph: VouchGlyph.logout,
                  title: 'Sign out',
                  tint: theme.muted,
                  onTap: _signOut,
                  trailing: const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: VouchSpace.x2),
            ],
            Reveal(
              index: 15,
              child: _RowCard(
                glyph: VouchGlyph.logout,
                title: isPartner ? 'Leave as witness' : 'End this promise',
                subtitle: isPartner
                    ? 'Stop witnessing. Their record stays.'
                    : 'End it for both of you.',
                tint: theme.missed,
                onTap: () => _endOrLeave(controller),
                trailing: const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: VouchSpace.x6),
            Container(height: 1, color: theme.line),
            const SizedBox(height: VouchSpace.x4),
            Text('Vouch', style: VouchType.body(theme.muted)),
            const SizedBox(height: 4),
            Text('Version 1.0.0', style: VouchType.caption(theme.faint)),
          ],
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

class _RowCard extends StatelessWidget {
  const _RowCard({
    required this.glyph,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.tint,
  });

  final VouchGlyph glyph;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final color = tint ?? theme.pending;
    return GlassCard(
      radius: VouchRadius.medium,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(VouchRadius.small),
              border: Border.all(
                color: color.withValues(alpha: 0.26),
                width: 1,
              ),
            ),
            child: VouchIcon(glyph, size: 18, color: color),
          ),
          const SizedBox(width: VouchSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VouchType.bodyStrong(theme.ink)
                      .copyWith(fontSize: 14.5),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: VouchType.caption(theme.muted)
                        .copyWith(fontSize: 11.5, height: 1.3),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: VouchSpace.x2),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.selected,
    required this.glyph,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final VouchGlyph glyph;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final foreground = selected ? theme.canvas : theme.ink;
    return Pressable(
      onTap: onTap,
      scale: 0.96,
      child: AnimatedContainer(
        duration: VouchDurations.fast,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? theme.ink : const Color(0x00000000),
          borderRadius: BorderRadius.circular(VouchRadius.pill),
          border: Border.all(
            color: selected ? theme.ink : theme.lineStrong,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            VouchIcon(glyph, size: 15, color: foreground),
            const SizedBox(width: 6),
            Text(
              label,
              style: VouchType.bodyStrong(foreground).copyWith(fontSize: 13),
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
    final theme = VouchScope.of(context);
    return VouchSheet(
      title: 'Your phone number',
      subtitle:
          'Only your partner sees it. It powers the call, WhatsApp and SMS shortcuts.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          VouchField(
            controller: _phone,
            autofocus: true,
            keyboardType: TextInputType.phone,
            maxLength: VouchConfig.maxPhoneLength,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]')),
            ],
            hint: '+234 801 234 5678',
            label: 'Phone (optional)',
            prefix: VouchIcon(
              VouchGlyph.phone,
              size: 17,
              color: theme.faint,
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: VouchSpace.x2),
            Text(
              _error!,
              style: VouchType.caption(theme.missed),
            ),
          ],
          const SizedBox(height: VouchSpace.x4),
          VouchButton(
            label: 'Save number',
            expand: true,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: VouchSpace.x2),
          VouchButton(
            label: 'Remove number',
            style: VouchButtonStyle.ghost,
            expand: true,
            onPressed: _saving
                ? null
                : () async {
                    _phone.clear();
                    await _save();
                  },
          ),
        ],
      ),
    );
  }
}
