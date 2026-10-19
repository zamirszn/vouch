/// In-app permission nudge (never requested at cold start).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/notification_service.dart';
import 'poster.dart';

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

    final style = PosterStyle.of(context);
    final exactOnly = status.notificationsEnabled && !status.exactAlarmsAllowed;

    return PosterCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: PosterColors.coral,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: PosterColors.cream,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  exactOnly ? 'Allow exact reminders' : 'Turn on reminders',
                  style: TextStyle(
                    fontFamily: 'InstrumentSans',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: style.cardInk,
                    fontVariations: const <FontVariation>[
                      FontVariation('wght', 600),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  exactOnly
                      ? 'Android may deliver reminders late until exact alarms are allowed.'
                      : 'Android needs permission before Vouch can nudge you.',
                  style: TextStyle(
                    fontFamily: 'InstrumentSans',
                    fontSize: 11.5,
                    height: 1.4,
                    color: style.cardMuted,
                  ),
                ),
                const SizedBox(height: 12),
                PosterPill(
                  label: _asking ? 'Opening…' : 'Allow',
                  compact: true,
                  expand: false,
                  arrow: false,
                  height: 38,
                  color: style.pill,
                  foreground: style.pillInk,
                  onPressed: _asking ? null : _enable,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
