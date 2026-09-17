// اختبارات الأمان: بوابة الترخيص، محرك OTP، تجزئة كلمات المرور
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeco_market/security/license_gate.dart';
import 'package:yeco_market/security/mail_config.dart';
import 'package:yeco_market/security/otp_engine.dart';
import 'package:yeco_market/security/password_hasher.dart';

import 'helpers.dart';

void main() {
  setUp(resetPrefs);

  group('LicenseGate', () {
    test('active=true → دخول مباشر', () async {
      LicenseGate.client = licenseClient(
        body: '{"active": true, "code": "YECO-2026"}',
      );
      final v = await LicenseGate.check();
      expect(v.state, LicenseState.active);
      expect(v.offline, isFalse);
    });

    test('active=false → قفل، كود خاطئ مرفوض، الصحيح يفتح ويبقى', () async {
      LicenseGate.client = licenseClient(
        body: '{"active": false, "code": "YECO-2026", "message": "m"}',
      );
      var v = await LicenseGate.check();
      expect(v.state, LicenseState.locked);
      expect(v.message, 'm');
      expect(await LicenseGate.unlock('WRONG'), isFalse);
      expect(
        await LicenseGate.unlock('yeco-2026'),
        isTrue,
      ); // غير حساس لحالة الأحرف
      // إعادة تشغيل: يبقى مفتوحاً ما دام الكود نفسه
      v = await LicenseGate.check();
      expect(v.state, LicenseState.active);
    });

    test('تغيير الكود في الملف بعد الفتح → قفل جديد', () async {
      LicenseGate.client = licenseClient(
        body: '{"active": false, "code": "A1"}',
      );
      await LicenseGate.check();
      expect(await LicenseGate.unlock('A1'), isTrue);
      LicenseGate.client = licenseClient(
        body: '{"active": false, "code": "B2"}',
      );
      final v = await LicenseGate.check();
      expect(v.state, LicenseState.locked);
    });

    test('404 → موقوف نهائياً ولا يقبل أي كود', () async {
      LicenseGate.client = licenseClient(status: 404);
      final v = await LicenseGate.check();
      expect(v.state, LicenseState.revoked);
      expect(await LicenseGate.unlock('YECO-2026'), isFalse);
    });

    test('بلا إنترنت → آخر حالة محفوظة', () async {
      LicenseGate.client = licenseClient(
        body: '{"active": false, "code": "X"}',
      );
      await LicenseGate.check();
      LicenseGate.client = offlineClient();
      final v = await LicenseGate.check();
      expect(v.state, LicenseState.locked);
      expect(v.offline, isTrue);
    });

    test(
      'بلا إنترنت عند أول تشغيل → مفعّل (لا نقفل مستخدماً جديداً بلا سبب)',
      () async {
        LicenseGate.client = offlineClient();
        final v = await LicenseGate.check();
        expect(v.state, LicenseState.active);
        expect(v.offline, isTrue);
      },
    );
  });

  group('OtpEngine', () {
    late FakeTransport mail;
    setUp(() => mail = installFakeMail());

    test('بلا إعداد SMTP في الاختبار → previewCode يُعرض', () async {
      expect(MailConfig.configured, isFalse);
      final r = await OtpEngine.issue('a@b.com', OtpPurpose.signUp);
      expect(r.delivered, isFalse);
      expect(r.ticket.previewCode, hasLength(6));
      expect(mail.sent, isEmpty);
    });

    test('الرمز الصحيح يُقبل مرة واحدة فقط', () async {
      final r = await OtpEngine.issue('a@b.com', OtpPurpose.reset);
      final code = r.ticket.previewCode!;
      expect(
        await OtpEngine.verify('a@b.com', OtpPurpose.reset, code),
        OtpVerify.ok,
      );
      expect(
        await OtpEngine.verify('a@b.com', OtpPurpose.reset, code),
        OtpVerify.none,
      );
    });

    test('الرمز الخاطئ 5 مرات → locked ويُلغى', () async {
      await OtpEngine.issue('a@b.com', OtpPurpose.signIn);
      for (var i = 0; i < 4; i++) {
        expect(
          await OtpEngine.verify('a@b.com', OtpPurpose.signIn, '000000'),
          OtpVerify.wrong,
        );
      }
      expect(
        await OtpEngine.verify('a@b.com', OtpPurpose.signIn, '000000'),
        OtpVerify.locked,
      );
      expect(await OtpEngine.current('a@b.com', OtpPurpose.signIn), isNull);
    });

    test('رمز التسجيل لا يفتح الاستعادة (عزل الغرض) ولا بريداً آخر', () async {
      final r = await OtpEngine.issue('a@b.com', OtpPurpose.signUp);
      final code = r.ticket.previewCode!;
      expect(
        await OtpEngine.verify('a@b.com', OtpPurpose.reset, code),
        OtpVerify.none,
      );
      expect(
        await OtpEngine.verify('x@b.com', OtpPurpose.signUp, code),
        OtpVerify.none,
      );
      expect(
        await OtpEngine.verify('A@B.COM', OtpPurpose.signUp, code),
        OtpVerify.ok,
      );
    });

    test('الرمز منتهي الصلاحية → expired', () async {
      await OtpEngine.issue('a@b.com', OtpPurpose.signIn);
      final p = await SharedPreferences.getInstance();
      await p.setInt(
        'otp.signIn.a@b.com.exp',
        DateTime.now().millisecondsSinceEpoch - 1000,
      );
      expect(
        await OtpEngine.verify('a@b.com', OtpPurpose.signIn, '123456'),
        OtpVerify.expired,
      );
    });

    test('current() يستعيد التذكرة بعد "إغلاق" التطبيق', () async {
      await OtpEngine.issue('a@b.com', OtpPurpose.signIn);
      final t = await OtpEngine.current('a@b.com', OtpPurpose.signIn);
      expect(t, isNotNull);
      expect(t!.remaining.inMinutes, greaterThanOrEqualTo(9));
      expect(t.canResend, isFalse);
    });

    test('لا يُخزَّن الرمز نصاً في SharedPreferences', () async {
      final r = await OtpEngine.issue('a@b.com', OtpPurpose.signUp);
      final p = await SharedPreferences.getInstance();
      final all = p.getKeys().map((k) => '${p.get(k)}').join(' ');
      expect(all.contains(r.ticket.previewCode!), isFalse);
    });

    test('قالب البريد يحمل الرمز والمدة والغرض', () {
      final txt = OtpEngine.plainText('123456', OtpPurpose.reset, 'جواد');
      expect(txt, contains('رمز التحقق: 123456'));
      expect(txt, contains('10 دقائق'));
      expect(txt, contains('مرحباً جواد'));
      final html = OtpEngine.htmlBody('123456', OtpPurpose.signUp, null);
      expect(html, contains('dir="rtl"'));
      for (final d in '123456'.split('')) {
        expect(html, contains('>$d</td>'));
      }
    });
  });

  group('PasswordHasher', () {
    test('يتحقق من الصحيحة ويرفض الخاطئة والملح عشوائي', () {
      final h1 = PasswordHasher.hash('Secret1');
      final h2 = PasswordHasher.hash('Secret1');
      expect(h1, isNot(h2));
      expect(h1, startsWith('pbkdf2\$'));
      expect(PasswordHasher.verify('Secret1', h1), isTrue);
      expect(PasswordHasher.verify('secret1', h1), isFalse);
      expect(PasswordHasher.verify('Secret1', 'garbage'), isFalse);
    });
  });
}
