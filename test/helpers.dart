// أدوات مشتركة للاختبارات: قاعدة في الذاكرة، ناقل بريد وهمي، غلاف MaterialApp عربي
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:yeco_market/core/theme.dart';
import 'package:yeco_market/data/db.dart';
import 'package:yeco_market/security/mailer_service.dart';
import 'package:yeco_market/security/otp_engine.dart';
import 'package:yeco_market/state/session.dart';
import 'package:yeco_market/state/store.dart';

/// يفتح قاعدة SQLite في الذاكرة (بيانات ابتدائية كاملة)
Future<void> openTestDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await YecoDb.instance.close();
  YecoDb.instance.pathOverride = inMemoryDatabasePath;
  await YecoDb.instance.open();
}

Future<void> resetPrefs() async {
  SharedPreferences.setMockInitialValues({});
}

/// ناقل بريد وهمي: يسجّل الرسائل ويسمح بمحاكاة الفشل
class FakeTransport implements MailTransport {
  final sent = <({String to, String subject, String text})>[];
  bool fail = false;

  @override
  Future<MailResult> send({
    required String to,
    required String subject,
    required String text,
    required String html,
  }) async {
    if (fail) return const MailResult.fail('smtp down');
    sent.add((to: to, subject: subject, text: text));
    return const MailResult.ok();
  }

  /// يستخرج الرمز من آخر رسالة (نفس ما يفعله المستخدم من بريده)
  String lastCode() =>
      RegExp(r'رمز التحقق: (\d{6})').firstMatch(sent.last.text)!.group(1)!;
}

/// عميل HTTP وهمي لبوابة الترخيص
http.Client licenseClient({
  int status = 200,
  String body = '{"active": true, "code": "YECO-2026"}',
}) {
  return MockClient((req) async {
    if (req.url.host == 'api.github.com') {
      // نجعل API يفشل حتى نختبر مسار raw أيضاً، إلا إن أردنا 404
      if (status == 404) return http.Response('', 404);
      return http.Response('', 500);
    }
    return http.Response(body, status);
  });
}

http.Client offlineClient() =>
    MockClient((_) async => throw const SocketException('offline'));

/// يغلّف شاشة بـ MaterialApp عربي RTL بحجم جوال 360×780
Widget wrapApp(Widget child, {Session? session, Store? store}) => AppScope(
  session: session ?? Session(),
  store: store ?? Store(),
  child: MaterialApp(
    theme: buildYecoTheme(),
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (c, w) =>
        Directionality(textDirection: TextDirection.rtl, child: w!),
    home: child,
  ),
);

void setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// يُشغّل عمليات SQLite (isolate حقيقي) داخل اختبار الواجهة
Future<T> real<T>(WidgetTester t, Future<T> Function() fn) async =>
    (await t.runAsync(fn)) as T;

FakeTransport installFakeMail() {
  final f = FakeTransport();
  OtpEngine.transport = f;
  return f;
}
