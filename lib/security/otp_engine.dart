// ============================================================
// YECO - محرك رموز التحقق (OTP) عبر البريد
//
// - رمز 6 أرقام (Random.secure)، صالح 10 دقائق، 5 محاولات،
//   إعادة إرسال بعد 45 ثانية.
// - لا يُحفظ الرمز نصاً: تُحفظ SHA-256(salt|code|email|purpose) مع
//   وقت الانتهاء في SharedPreferences، فيبقى صالحاً إذا خرج المستخدم
//   إلى تطبيق البريد لنسخ الرمز ثم عاد (حتى لو أُغلق التطبيق).
// - يُستخدم في: الدخول (تحقق ثانٍ)، إنشاء الحساب، استعادة كلمة المرور.
// ============================================================

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mail_config.dart';
import 'mailer_service.dart';

enum OtpPurpose {
  signIn('تأكيد تسجيل الدخول'),
  signUp('تأكيد البريد الإلكتروني'),
  reset('استعادة كلمة المرور');

  const OtpPurpose(this.title);
  final String title;
}

enum OtpVerify { ok, wrong, expired, locked, none }

/// حالة الرمز الحالي (لعرض العدّاد والمحاولات في الواجهة)
class OtpTicket {
  final String email;
  final OtpPurpose purpose;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final int attempts;

  /// الرمز الصريح — متاح فقط لحظة الإصدار عندما يتعذّر الإرسال (وضع المعاينة)
  final String? previewCode;

  const OtpTicket({
    required this.email,
    required this.purpose,
    required this.issuedAt,
    required this.expiresAt,
    required this.attempts,
    this.previewCode,
  });

  static const maxAttempts = 5;
  static const validity = Duration(minutes: 10);
  static const resendCooldown = Duration(seconds: 45);

  int get attemptsLeft => maxAttempts - attempts;
  bool get isLocked => attempts >= maxAttempts;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get remaining {
    final d = expiresAt.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  Duration get resendIn {
    final d = issuedAt.add(resendCooldown).difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  bool get canResend => resendIn == Duration.zero;
}

/// نتيجة الإصدار: التذكرة + هل أُرسل بالبريد فعلاً + سبب الفشل إن وجد
class OtpIssue {
  final OtpTicket ticket;
  final bool delivered;
  final String error;
  const OtpIssue(this.ticket, {required this.delivered, this.error = ''});
}

class OtpEngine {
  OtpEngine._();

  /// قابل للاستبدال في الاختبارات
  static MailTransport transport = const SmtpTransport();
  static Random rng = Random.secure();

  /// يُخبر الواجهة هل الإرسال الفعلي ممكن في هذا البناء
  static bool get canDeliver => MailConfig.configured;

  static const codeLength = 6;

  static String _k(String email, OtpPurpose p, String f) =>
      'otp.${p.name}.${email.trim().toLowerCase()}.$f';

  static String _digest(String salt, String code, String email, OtpPurpose p) =>
      sha256
          .convert(
            utf8.encode('$salt|$code|${email.trim().toLowerCase()}|${p.name}'),
          )
          .toString();

  /// يولّد رمزاً، يحفظه مجزّأً، ويرسله إلى البريد.
  /// إن تعذّر الإرسال يُرجع delivered=false مع previewCode ليُعرض داخل التطبيق.
  static Future<OtpIssue> issue(
    String email,
    OtpPurpose purpose, {
    String? recipientName,
  }) async {
    final e = email.trim().toLowerCase();
    final code = List.generate(codeLength, (_) => rng.nextInt(10)).join();
    final salt = List.generate(
      16,
      (_) => rng.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final now = DateTime.now();
    final exp = now.add(OtpTicket.validity);

    final p = await SharedPreferences.getInstance();
    await p.setString(_k(e, purpose, 'salt'), salt);
    await p.setString(_k(e, purpose, 'hash'), _digest(salt, code, e, purpose));
    await p.setInt(_k(e, purpose, 'issued'), now.millisecondsSinceEpoch);
    await p.setInt(_k(e, purpose, 'exp'), exp.millisecondsSinceEpoch);
    await p.setInt(_k(e, purpose, 'att'), 0);

    var delivered = false;
    var error = '';
    if (canDeliver) {
      final r = await transport.send(
        to: e,
        subject: '${purpose.title} — رمز التحقق $code',
        text: plainText(code, purpose, recipientName),
        html: htmlBody(code, purpose, recipientName),
      );
      delivered = r.sent;
      error = r.error;
    }
    return OtpIssue(
      OtpTicket(
        email: e,
        purpose: purpose,
        issuedAt: now,
        expiresAt: exp,
        attempts: 0,
        previewCode: delivered ? null : code,
      ),
      delivered: delivered,
      error: error,
    );
  }

  /// يستعيد التذكرة الحالية (إن وُجدت ولم تنتهِ) — لعرضها بعد العودة إلى التطبيق
  static Future<OtpTicket?> current(String email, OtpPurpose purpose) async {
    final e = email.trim().toLowerCase();
    final p = await SharedPreferences.getInstance();
    final exp = p.getInt(_k(e, purpose, 'exp'));
    final issued = p.getInt(_k(e, purpose, 'issued'));
    if (exp == null || issued == null) return null;
    final t = OtpTicket(
      email: e,
      purpose: purpose,
      issuedAt: DateTime.fromMillisecondsSinceEpoch(issued),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(exp),
      attempts: p.getInt(_k(e, purpose, 'att')) ?? 0,
    );
    return t.isExpired ? null : t;
  }

  /// يتحقق من الرمز المُدخل. عند النجاح يُلغى الرمز (استخدام لمرة واحدة).
  static Future<OtpVerify> verify(
    String email,
    OtpPurpose purpose,
    String typed,
  ) async {
    final e = email.trim().toLowerCase();
    final p = await SharedPreferences.getInstance();
    final salt = p.getString(_k(e, purpose, 'salt'));
    final hash = p.getString(_k(e, purpose, 'hash'));
    final exp = p.getInt(_k(e, purpose, 'exp'));
    if (salt == null || hash == null || exp == null) return OtpVerify.none;

    final attempts = p.getInt(_k(e, purpose, 'att')) ?? 0;
    if (attempts >= OtpTicket.maxAttempts) {
      await clear(e, purpose);
      return OtpVerify.locked;
    }
    if (DateTime.now().millisecondsSinceEpoch > exp) {
      await clear(e, purpose);
      return OtpVerify.expired;
    }
    final t = typed.trim();
    if (t.length == codeLength &&
        _constEq(_digest(salt, t, e, purpose), hash)) {
      await clear(e, purpose);
      return OtpVerify.ok;
    }
    final next = attempts + 1;
    await p.setInt(_k(e, purpose, 'att'), next);
    if (next >= OtpTicket.maxAttempts) {
      await clear(e, purpose);
      return OtpVerify.locked;
    }
    return OtpVerify.wrong;
  }

  static Future<void> clear(String email, OtpPurpose purpose) async {
    final e = email.trim().toLowerCase();
    final p = await SharedPreferences.getInstance();
    for (final f in const ['salt', 'hash', 'issued', 'exp', 'att']) {
      await p.remove(_k(e, purpose, f));
    }
  }

  /// مقارنة بزمن ثابت
  static bool _constEq(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  // ------------------------------------------------------------ قوالب الرسالة
  static String _intro(OtpPurpose p) => switch (p) {
    OtpPurpose.signIn =>
      'وصلنا طلب تسجيل دخول إلى حسابك في YECO. أدخل الرمز التالي في التطبيق لإتمام الدخول.',
    OtpPurpose.signUp =>
      'أهلاً بك في YECO! أدخل الرمز التالي في التطبيق لتأكيد بريدك الإلكتروني وإنشاء حسابك.',
    OtpPurpose.reset =>
      'وصلنا طلب لإعادة تعيين كلمة مرور حسابك في YECO. أدخل الرمز التالي في التطبيق للمتابعة.',
  };

  static String plainText(String code, OtpPurpose p, String? name) {
    final hello = (name == null || name.trim().isEmpty)
        ? 'مرحباً،'
        : 'مرحباً ${name.trim()}،';
    return '''
$hello

${_intro(p)}

رمز التحقق: $code

الرمز صالح لمدة ${OtpTicket.validity.inMinutes} دقائق ويُستخدم مرة واحدة.
إن لم تطلب هذا الرمز فتجاهل هذه الرسالة.

YECO — تسوّق بذكاء
''';
  }

  static String htmlBody(String code, OtpPurpose p, String? name) {
    final hello = (name == null || name.trim().isEmpty)
        ? 'مرحباً،'
        : 'مرحباً ${_esc(name.trim())}،';
    final digits = code
        .split('')
        .map(
          (d) =>
              '<td style="width:44px;height:56px;border:1.5px solid #cfe8dc;border-radius:12px;background:#fff;font:700 26px/56px Tahoma,Arial;color:#0b7a55;text-align:center;">$d</td>',
        )
        .join('<td style="width:8px"></td>');
    return '''
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f2f6f3;font-family:Segoe UI,Tahoma,Arial,sans-serif;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="padding:28px 12px;">
<tr><td align="center">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:520px;background:#fff;border-radius:18px;overflow:hidden;box-shadow:0 6px 24px rgba(15,157,110,.12);">
<tr><td style="background:linear-gradient(135deg,#0f9d6e,#0b7a55);padding:22px 26px;color:#fff;">
  <div style="font-size:26px;font-weight:800;letter-spacing:1px;">YECO</div>
  <div style="font-size:14px;opacity:.9;margin-top:4px;">${p.title}</div>
</td></tr>
<tr><td style="padding:26px 26px 8px;color:#17212b;font-size:16px;line-height:1.8;">
  <p style="margin:0 0 10px;">$hello</p>
  <p style="margin:0 0 18px;">${_intro(p)}</p>
  <table role="presentation" cellspacing="0" cellpadding="0" align="center" dir="ltr" style="margin:6px auto 18px;"><tr>$digits</tr></table>
  <p style="margin:0 0 6px;font-size:14px;color:#5b6b7a;">الرمز صالح لمدة <b>${OtpTicket.validity.inMinutes} دقائق</b> ويُستخدم مرة واحدة.</p>
  <p style="margin:0;font-size:14px;color:#5b6b7a;">إن لم تطلب هذا الرمز فتجاهل هذه الرسالة ولن يتغيّر شيء في حسابك.</p>
</td></tr>
<tr><td style="padding:16px 26px 24px;border-top:1px solid #e4e8e3;color:#9aa6b2;font-size:12px;">YECO — تسوّق بذكاء · رسالة آلية، لا ترد عليها.</td></tr>
</table></td></tr></table></body></html>''';
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
