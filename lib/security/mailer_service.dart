// ============================================================
// YECO - إرسال البريد عبر SMTP (أندرويد)
// التطبيق أندرويد فقط، لذا لا حاجة إلى conditional import للويب.
// ============================================================

import 'dart:async';
import 'dart:io';

import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';

import 'mail_config.dart';

/// نتيجة محاولة الإرسال
class MailResult {
  final bool sent;
  final String error;
  const MailResult.ok() : sent = true, error = '';
  const MailResult.fail(this.error) : sent = false;
}

/// واجهة قابلة للاستبدال في الاختبارات
abstract class MailTransport {
  Future<MailResult> send({
    required String to,
    required String subject,
    required String text,
    required String html,
  });
}

class SmtpTransport implements MailTransport {
  const SmtpTransport({this.timeout = const Duration(seconds: 25)});
  final Duration timeout;

  @override
  Future<MailResult> send({
    required String to,
    required String subject,
    required String text,
    required String html,
  }) async {
    if (!MailConfig.configured) {
      return const MailResult.fail('خدمة البريد غير مضبوطة في هذا البناء');
    }
    final server = SmtpServer(
      MailConfig.host,
      port: MailConfig.port,
      username: MailConfig.user,
      password: MailConfig.password,
      ssl: MailConfig.port == 465,
      allowInsecure: false,
    );
    final msg = mailer.Message()
      ..from = mailer.Address(MailConfig.user, MailConfig.senderName)
      ..recipients.add(to)
      ..subject = subject
      ..text = text
      ..html = html;
    try {
      await mailer.send(msg, server).timeout(timeout);
      return const MailResult.ok();
    } on TimeoutException {
      return const MailResult.fail(
        'انتهت مهلة الاتصال بخادم البريد، تحقق من الإنترنت وأعد المحاولة',
      );
    } on mailer.SmtpClientAuthenticationException {
      return const MailResult.fail(
        'رُفض الدخول إلى خادم البريد (تحقق من كلمة مرور التطبيق)',
      );
    } on SocketException {
      return const MailResult.fail(
        'لا يمكن الوصول إلى خادم البريد، تحقق من اتصال الإنترنت',
      );
    } on mailer.MailerException catch (e) {
      final detail = e.problems.map((p) => p.msg).join('، ');
      return MailResult.fail(
        detail.isEmpty ? 'فشل إرسال البريد' : 'فشل إرسال البريد: $detail',
      );
    } catch (_) {
      return const MailResult.fail('حدث خطأ غير متوقع أثناء الإرسال');
    }
  }
}
