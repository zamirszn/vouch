/// Call / WhatsApp / SMS shortcut sheet.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/day_entry.dart';
import '../services/contact_service.dart';
import 'poster.dart';
import 'sheet_frame.dart';

Future<MarkMethod?> showContactSheet(
  BuildContext context, {
  required String name,
  required String? phone,
  String? message,
}) {
  return showVouchSheet<MarkMethod>(
    context,
    ContactSheet(name: name, phone: phone, message: message),
  );
}

class ContactSheet extends StatelessWidget {
  const ContactSheet({
    super.key,
    required this.name,
    required this.phone,
    this.message,
  });

  final String name;
  final String? phone;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final hasPhone = (phone?.trim().isNotEmpty ?? false);

    Future<void> launch(Future<bool> Function(ContactService) action) async {
      final service = context.read<ContactService>();
      final ok = await action(service);
      if (!context.mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasPhone
                  ? 'No app on this phone could handle that.'
                  : 'Add $name’s phone number in Settings first.',
            ),
          ),
        );
      }
    }

    return SheetFrame(
      title: 'Reach $name',
      subtitle: 'Confirm out loud before you mark the day.',
      child: Column(
        children: <Widget>[
          _ContactTile(
            icon: Icons.call_rounded,
            title: 'Phone call',
            subtitle: phone?.trim().isNotEmpty == true
                ? phone!
                : 'No number yet',
            color: PosterColors.cobalt,
            onTap: hasPhone ? () => launch((s) => s.call(phone)) : null,
          ),
          const SizedBox(height: 10),
          _ContactTile(
            icon: Icons.chat_bubble_rounded,
            title: 'WhatsApp',
            subtitle: 'Send a message or voice note',
            color: const Color(0xFF1FA855),
            onTap: hasPhone
                ? () => launch((s) => s.whatsApp(phone, message: message))
                : null,
          ),
          const SizedBox(height: 10),
          _ContactTile(
            icon: Icons.sms_rounded,
            title: 'SMS',
            subtitle: 'Plain text message',
            color: PosterColors.coral,
            onTap: hasPhone
                ? () => launch((s) => s.sms(phone, body: message))
                : null,
          ),
          const SizedBox(height: 10),
          _ContactTile(
            icon: Icons.people_alt_rounded,
            title: 'In person',
            subtitle: 'Ask face to face, then come back and mark it',
            color: PosterColors.kelly,
            onTap: () => Navigator.of(context).pop(MarkMethod.inPerson),
          ),
          if (!hasPhone) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              'Ask $name to add their number in Settings — or exchange numbers in person.',
              style: text.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = PosterStyle.of(context);
    final enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: style.soft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: style.line),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: enabled ? 0.14 : 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: enabled ? color : style.muted),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(
                        color: enabled ? style.ink : style.muted,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: text.bodySmall?.copyWith(color: style.muted),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: style.muted.withValues(alpha: enabled ? 1 : 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
