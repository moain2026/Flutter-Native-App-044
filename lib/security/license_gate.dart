// ============================================================
// YECO - بوابة الترخيص عن بُعد (Remote Kill-Switch)
//
// يقرأ التطبيق ملف license.json من جذر مستودع GitHub عند كل تشغيل:
//   { "active": true|false, "code": "YECO-XXXX", "message": "..." }
//
//   active = true   → دخول مباشر
//   active = false  → شاشة قفل تطلب الكود؛ بعد نجاحه يُحفظ ويُفتح تلقائياً
//                     ما دام نفس الكود في الملف (تغيير الكود = قفل جديد)
//   الملف محذوف 404 → إيقاف نهائي، لا يقبل أي كود
//   بلا إنترنت      → آخر حالة محفوظة
//
// نقرأ من GitHub Contents API أولاً (بيانات حيّة بلا كاش CDN) ثم الملف
// الخام كاحتياط. النتيجة سجل (record) من Dart 3.
// ============================================================

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum LicenseState {
  active('مفعّل'),
  locked('يلزم كود التفعيل'),
  revoked('موقوف نهائياً');

  const LicenseState(this.label);
  final String label;
}

/// نتيجة التحقق: الحالة + الرسالة + هل جاءت من الذاكرة (بلا إنترنت)
typedef LicenseVerdict = ({LicenseState state, String message, bool offline});

class LicenseGate {
  LicenseGate._();

  /// قابل للاستبدال في الاختبارات
  static http.Client client = http.Client();

  static const repoOwner = 'moain2026';
  static const repoName = 'Flutter-Native-App-044';
  static const fileName = 'license.json';

  static Uri get apiUri => Uri.https(
    'api.github.com',
    '/repos/$repoOwner/$repoName/contents/$fileName',
    {'ref': 'main'},
  );
  static Uri rawUri() => Uri.https(
    'raw.githubusercontent.com',
    '/$repoOwner/$repoName/main/$fileName',
    {'t': '${DateTime.now().millisecondsSinceEpoch}'},
  );

  static const _kState = 'lic.state';
  static const _kMessage = 'lic.message';
  static const _kRemoteCode = 'lic.remote_code';
  static const _kUnlockedWith = 'lic.unlocked_with';
  static const _timeout = Duration(seconds: 8);

  static const _revokedMsg = 'تم إيقاف هذه النسخة نهائياً. تواصل مع المطوّر.';
  static const _defaultLockedMsg =
      'هذه النسخة تحتاج تفعيل. يرجى التواصل مع المطوّر للحصول على كود التفعيل.';

  /// تُستدعى عند بدء التطبيق وعند الضغط على "إعادة التحقق"
  static Future<LicenseVerdict> check() async {
    final prefs = await SharedPreferences.getInstance();
    final remote = await _fetch();

    if (remote == null) {
      // بلا إنترنت → آخر حالة معروفة (الافتراضي: مفعّل عند أول تشغيل)
      final idx = prefs.getInt(_kState) ?? LicenseState.active.index;
      return (
        state: LicenseState.values[idx],
        message: prefs.getString(_kMessage) ?? '',
        offline: true,
      );
    }

    if (remote.revoked) {
      await _save(prefs, LicenseState.revoked, _revokedMsg, '');
      return (
        state: LicenseState.revoked,
        message: _revokedMsg,
        offline: false,
      );
    }

    if (remote.active) {
      await _save(prefs, LicenseState.active, remote.message, remote.code);
      return (
        state: LicenseState.active,
        message: remote.message,
        offline: false,
      );
    }

    // غير مفعّل: هل فُتح سابقاً بنفس الكود الحالي؟
    final unlockedWith = prefs.getString(_kUnlockedWith) ?? '';
    final stillValid = remote.code.isNotEmpty && unlockedWith == remote.code;
    final state = stillValid ? LicenseState.active : LicenseState.locked;
    final msg = remote.message.isEmpty ? _defaultLockedMsg : remote.message;
    await _save(prefs, state, msg, remote.code);
    return (state: state, message: msg, offline: false);
  }

  /// محاولة فتح القفل بالكود؛ true عند التطابق (ويُحفظ الكود)
  static Future<bool> unlock(String typed) async {
    final code = typed.trim().toUpperCase();
    if (code.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final remote = await _fetch();
    if (remote != null && remote.revoked) return false;
    final reference = remote?.code ?? prefs.getString(_kRemoteCode) ?? '';
    if (reference.isEmpty || code != reference) return false;
    await prefs.setString(_kUnlockedWith, reference);
    await prefs.setInt(_kState, LicenseState.active.index);
    return true;
  }

  // ------------------------------------------------------------ داخلي
  static Future<void> _save(
    SharedPreferences p,
    LicenseState s,
    String msg,
    String code,
  ) async {
    await p.setInt(_kState, s.index);
    await p.setString(_kMessage, msg);
    await p.setString(_kRemoteCode, code);
  }

  static Future<_Remote?> _fetch() async =>
      (await _viaApi()) ?? (await _viaRaw());

  static Future<_Remote?> _viaApi() async {
    try {
      final r = await client
          .get(
            apiUri,
            headers: const {
              'Accept': 'application/vnd.github+json',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(_timeout);
      if (r.statusCode == 404) return _Remote.revokedFile;
      if (r.statusCode != 200) return null;
      final meta = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final b64 = (meta['content'] as String? ?? '').replaceAll(
        RegExp(r'\s'),
        '',
      );
      if (b64.isEmpty) return null;
      return _Remote.parse(utf8.decode(base64Decode(b64)));
    } catch (_) {
      return null;
    }
  }

  static Future<_Remote?> _viaRaw() async {
    try {
      final r = await client
          .get(rawUri(), headers: const {'Cache-Control': 'no-cache'})
          .timeout(_timeout);
      if (r.statusCode == 404) return _Remote.revokedFile;
      if (r.statusCode != 200) return null;
      return _Remote.parse(utf8.decode(r.bodyBytes));
    } catch (_) {
      return null;
    }
  }
}

class _Remote {
  final bool active;
  final String code;
  final String message;
  final bool revoked;
  const _Remote(this.active, this.code, this.message, {this.revoked = false});

  static const revokedFile = _Remote(false, '', '', revoked: true);

  static _Remote? parse(String body) {
    try {
      final j = jsonDecode(body) as Map<String, dynamic>;
      return _Remote(
        j['active'] == true,
        (j['code'] ?? '').toString().trim().toUpperCase(),
        (j['message'] ?? '').toString(),
      );
    } catch (_) {
      return null;
    }
  }
}
