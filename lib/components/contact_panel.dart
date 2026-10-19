/// Call / WhatsApp / SMS shortcut panel. Replaces the poster-era sheet.
library;

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import '../models/day_entry.dart';
import '../services/contact_service.dart';
import 'pressable.dart';
import 'vouch_icon.dart';
import 'vouch_sheet.dart';
import 'vouch_toast.dart';

Future<MarkMethod?> showContactSheet(
  BuildContext context, {
  required String name,
  required String? phone,
  String? message,
}) {
  return showVouchPanel<MarkMethod>(
    context,
    (_) => ContactPanel(name: name, phone: phone, message: message),
  );
}

class ContactPanel extends StatelessWidget {
  const ContactPanel({
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
    final theme = VouchScope.of(context);
    final hasPhone = phone?.trim().isNotEmpty ?? false;

    Future<void> launch(Future<bool> Function(ContactService) action) async {
      final service = context.read<ContactService>();
      final ok = await action(service);
      if (!context.mounted) return;
      if (!ok) {
        VouchToast.show(
          context,
          hasPhone
              ? 'No app on this phone could handle that.'
              : 'Add $name’s phone number in Settings first.',
          glyph: VouchGlyph.closeCircle,
          accent: theme.missed,
        );
      }
    }

    return VouchSheet(
      title: 'Reach $name',
      subtitle: 'Confirm out loud before you mark the day.',
      child: Column(
        children: <Widget>[
          _ContactRow(
            glyph: VouchGlyph.phone,
            title: 'Phone call',
            subtitle: hasPhone ? phone! : 'No number yet',
            color: theme.pending,
            onTap: hasPhone ? () => launch((s) => s.call(phone)) : null,
          ),
          const SizedBox(height: VouchSpace.x2),
          _ContactRow(
            glyph: VouchGlyph.message,
            title: 'WhatsApp',
            subtitle: 'Send a message or voice note',
            color: theme.kept,
            onTap: hasPhone
                ? () => launch((s) => s.whatsApp(phone, message: message))
                : null,
          ),
          const SizedBox(height: VouchSpace.x2),
          _ContactRow(
            glyph: VouchGlyph.note,
            title: 'SMS',
            subtitle: 'Plain text message',
            color: theme.missed,
            onTap: hasPhone
                ? () => launch((s) => s.sms(phone, body: message))
                : null,
          ),
          const SizedBox(height: VouchSpace.x2),
          _ContactRow(
            glyph: VouchGlyph.people,
            title: 'In person',
            subtitle: 'Ask face to face, then come back and mark it',
            color: theme.accent,
            onTap: () => Navigator.of(context).pop(MarkMethod.inPerson),
          ),
          if (!hasPhone) ...<Widget>[
            const SizedBox(height: VouchSpace.x4),
            Text(
              'Ask $name to add their number in Settings — or exchange '
              'numbers in person.',
              style: VouchType.caption(theme.faint).copyWith(
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.glyph,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final VouchGlyph glyph;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final enabled = onTap != null;

    return Pressable(
      onTap: onTap,
      enabled: enabled,
      scale: enabled ? 0.985 : 1,
      child: Opacity(
        opacity: enabled ? 1 : 0.42,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: theme.glass,
            borderRadius: BorderRadius.circular(VouchRadius.small),
            border: Border.all(color: theme.line),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: VouchIcon(glyph, size: 19, color: color),
              ),
              const SizedBox(width: VouchSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: VouchType.bodyStrong(theme.ink)
                          .copyWith(fontSize: 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: VouchType.caption(theme.muted)
                          .copyWith(fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: VouchSpace.x2),
              VouchIcon(
                VouchGlyph.chevronRight,
                size: 15,
                color: theme.faint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
