// ============================================================
// YECO - جلسة المستخدم (ChangeNotifier بلا حزم خارجية)
// تسجيل الدخول بخطوتين: كلمة المرور ثم رمز يُرسل إلى البريد
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repos.dart';
import '../models/models.dart';
import '../security/otp_engine.dart';
import '../security/password_hasher.dart';

/// نتيجة فحص البريد في خطوة الدخول الأولى
enum EmailLookup { exists, notFound }

/// نتيجة التحقق من كلمة المرور
enum PasswordCheck { ok, wrong, noUser }

class Session extends ChangeNotifier {
  Session({UserRepo? users}) : _users = users ?? const UserRepo();

  final UserRepo _users;
  static const _kUid = 'session.uid';
  static const _kTwoFactor = 'session.two_factor';

  AppUser? _user;
  bool _twoFactor = true;

  AppUser? get user => _user;
  bool get signedIn => _user != null;
  bool get isSeller => _user?.isSeller ?? false;
  int get uid => _user?.id ?? 0;

  /// هل يُطلب رمز البريد عند كل تسجيل دخول؟ (قابل للتبديل من الإعدادات)
  bool get twoFactor => _twoFactor;

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    _twoFactor = p.getBool(_kTwoFactor) ?? true;
    final id = p.getInt(_kUid);
    if (id != null) _user = await _users.byId(id);
    notifyListeners();
  }

  Future<void> setTwoFactor(bool v) async {
    _twoFactor = v;
    (await SharedPreferences.getInstance()).setBool(_kTwoFactor, v);
    notifyListeners();
  }

  // ------------------------------------------------------------ الدخول
  Future<EmailLookup> lookup(String email) async =>
      (await _users.emailExists(email))
      ? EmailLookup.exists
      : EmailLookup.notFound;

  Future<PasswordCheck> checkPassword(String email, String password) async {
    final stored = await _users.passwordHashOf(email);
    if (stored == null) return PasswordCheck.noUser;
    return PasswordHasher.verify(password, stored)
        ? PasswordCheck.ok
        : PasswordCheck.wrong;
  }

  /// يُستدعى بعد نجاح كلمة المرور (ورمز البريد إن كان مفعّلاً)
  Future<AppUser?> completeSignIn(String email) async {
    final u = await _users.byEmail(email);
    if (u == null) return null;
    await _persist(u);
    return u;
  }

  // ------------------------------------------------------------ الإنشاء
  /// يُنشئ الحساب — يُستدعى فقط بعد تأكيد رمز البريد
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String city,
    required UserRole role,
  }) async {
    final u = await _users.create(
      name: name,
      email: email,
      passwordHash: PasswordHasher.hash(password),
      phone: phone,
      city: city,
      role: role,
    );
    await _persist(u);
    return u;
  }

  // ------------------------------------------------------------ كلمة المرور
  /// يُستدعى بعد تأكيد رمز الاستعادة: UPDATE فعلي في SQLite
  Future<bool> resetPassword(String email, String newPassword) async {
    final n = await _users.updatePassword(
      email,
      PasswordHasher.hash(newPassword),
    );
    await OtpEngine.clear(email, OtpPurpose.reset);
    return n > 0;
  }

  Future<String?> changePassword(String current, String next) async {
    final u = _user;
    if (u == null) return 'لا توجد جلسة';
    final check = await checkPassword(u.email, current);
    if (check != PasswordCheck.ok) return 'كلمة المرور الحالية غير صحيحة';
    await _users.updatePassword(u.email, PasswordHasher.hash(next));
    return null;
  }

  // ------------------------------------------------------------ الملف الشخصي
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? city,
  }) async {
    final u = _user;
    if (u == null) return;
    final next = u.copyWith(name: name, phone: phone, city: city);
    await _users.updateProfile(next);
    _user = next;
    notifyListeners();
  }

  Future<void> signOut() async {
    _user = null;
    (await SharedPreferences.getInstance()).remove(_kUid);
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final u = _user;
    if (u == null) return;
    await _users.delete(u.id);
    await signOut();
  }

  Future<void> _persist(AppUser u) async {
    _user = u;
    (await SharedPreferences.getInstance()).setInt(_kUid, u.id);
    notifyListeners();
  }
}
