/// Deep links used for the "confirm out loud" half of accountability.
library;

import 'package:url_launcher/url_launcher.dart';

class ContactService {
  const ContactService();

  Future<bool> call(String? phone) async {
    final number = _dialable(phone);
    if (number.isEmpty) return false;
    return _launch(Uri(scheme: 'tel', path: number));
  }

  Future<bool> sms(String? phone, {String? body}) async {
    final number = _dialable(phone);
    if (number.isEmpty) return false;
    return _launch(
      Uri(
        scheme: 'sms',
        path: number,
        queryParameters: body == null || body.isEmpty ? null : {'body': body},
      ),
    );
  }

  Future<bool> whatsApp(String? phone, {String? message}) async {
    final digits = _digits(phone);
    if (digits.isEmpty) return false;

    final web = Uri.https(
      'wa.me',
      '/$digits',
      message == null || message.isEmpty ? null : {'text': message},
    );
    if (await _launch(web)) return true;

    final query = <String, String>{'phone': digits};
    if (message != null && message.isNotEmpty) query['text'] = message;
    return _launch(Uri(scheme: 'whatsapp', host: 'send', queryParameters: query));
  }

  Future<bool> _launch(Uri uri) async {
    try {
      if (!await canLaunchUrl(uri)) return false;
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  String _digits(String? phone) =>
      (phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');

  String _dialable(String? phone) {
    final trimmed = (phone ?? '').trim();
    if (trimmed.isEmpty) return '';
    return trimmed.startsWith('+') ? '+${_digits(trimmed)}' : _digits(trimmed);
  }
}
