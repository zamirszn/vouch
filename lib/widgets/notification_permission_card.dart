/// In-app permission nudge (never requested at cold start).
library;

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../components/glass_card.dart';
import '../components/vouch_button.dart';
import '../components/vouch_icon.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import '../services/notification_service.dart';

class NotificationPermissionCard extends StatefulWidget {
  const NotificationPermissionCard({super.key});

  @override
  State<NotificationPermissionCard> createState() =>
      _NotificationPermissionCardState();
}

class _NotificationPermissionCardState extends State<NotificationPermissionCard> {
  VouchNotificationStatus? _status;
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final service = context.read<NotificationService>();
    final status = await service.status();
    if (!mounted) return;
    setState(() => _status = status);
  }

  Future<void> _enable() async {
    setState(() => _asking = true);
    final service = context.read<NotificationService>();
    final status = await service.requestPermissions();
    if (!mounted) return;
    setState(() {
      _status = status;
      _asking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null) return const SizedBox.shrink();
    if (status.notificationsEnabled && status.exactAlarmsAllowed) {
      return const SizedBox.shrink();
    }

    final theme = VouchScope.of(context);
    final exactOnly = status.notificationsEnabled && !status.exactAlarmsAllowed;

    return GlassCard(
      radius: VouchRadius.medium,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      tint: theme.missed,
      borderColor: theme.missed.withValues(alpha: 0.24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.missed.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(VouchRadius.small),
                  border: Border.all(
                    color: theme.missed.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: VouchIcon(
                  VouchGlyph.bell,
                  size: 19,
                  color: theme.missed,
                ),
              ),
              const SizedBox(width: VouchSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      exactOnly ? 'Allow exact reminders' : 'Turn on reminders',
                      style: VouchType.bodyStrong(theme.ink)
                          .copyWith(fontSize: 14.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      exactOnly
                          ? 'Android may deliver reminders late until exact alarms are allowed.'
                          : 'Android needs permission before Vouch can nudge you.',
                      style: VouchType.caption(theme.muted)
                          .copyWith(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VouchSpace.x3),
          VouchButton(
            label: 'Allow',
            style: VouchButtonStyle.signal,
            height: 42,
            compact: true,
            loading: _asking,
            onPressed: _asking ? null : _enable,
          ),
        ],
      ),
    );
  }
}
