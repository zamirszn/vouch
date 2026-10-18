/// In-app permission nudge (never requested at cold start).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/notification_service.dart';
import '../theme/vouch_theme.dart';
import 'section_header.dart';

class NotificationPermissionCard extends StatefulWidget {
  const NotificationPermissionCard({super.key});

  @override
  State<NotificationPermissionCard> createState() =>
      _NotificationPermissionCardState();
}

class _NotificationPermissionCardState
    extends State<NotificationPermissionCard> {
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

    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final exactOnly = status.notificationsEnabled && !status.exactAlarmsAllowed;

    return ExpressiveCard(
      color: VouchColors.coral.withValues(alpha: 0.10),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: VouchColors.coral.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: VouchColors.coral,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  exactOnly
                      ? 'Allow exact reminders'
                      : 'Turn on reminders',
                  style: text.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  exactOnly
                      ? 'Android may deliver reminders a little late until exact alarms are allowed for Vouch.'
                      : 'Both you and your partner get a nudge at the chosen time. Android needs permission first.',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: _asking ? null : _enable,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Text(_asking ? 'Opening…' : 'Allow'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
