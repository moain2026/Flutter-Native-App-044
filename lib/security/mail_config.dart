// ============================================================
// YECO - إعدادات خادم البريد (SMTP) لإرسال رموز التحقق
//
// ⚠️ لا تُكتب بيانات الدخول هنا لأن المستودع عام. تُمرَّر وقت البناء:
//    flutter build apk --release \
//      --dart-define=SMTP_USER=you@gmail.com \
//      --dart-define=SMTP_PASS="xxxx xxxx xxxx xxxx"
//    أو ضع android/smtp.properties (مُتجاهَل في git) واستخدم
//    tool/build_release.sh الذي يقرأه ويمرّره تلقائياً.
//
// Gmail يلزمه "App Password" (16 حرفاً) مع تفعيل التحقق بخطوتين؛
// كلمة مرور الحساب العادية لا تعمل مع SMTP.
// ============================================================

abstract final class MailConfig {
  static const host = String.fromEnvironment(
    'SMTP_HOST',
    defaultValue: 'smtp.gmail.com',
  );

  /// 465 = SSL مباشر (الافتراضي) · 587 = STARTTLS
  static const port = int.fromEnvironment('SMTP_PORT', defaultValue: 465);
  static const user = String.fromEnvironment('SMTP_USER', defaultValue: '');
  static const _pass = String.fromEnvironment('SMTP_PASS', defaultValue: '');
  static const senderName = String.fromEnvironment(
    'SMTP_NAME',
    defaultValue: 'YECO',
  );

  /// كلمة مرور تطبيق Google تأتي بمسافات؛ نزيلها لتُقبل بأي شكل كُتبت
  static String get password => _pass.replaceAll(' ', '');

  static bool get configured => user.trim().isNotEmpty && password.isNotEmpty;
}
