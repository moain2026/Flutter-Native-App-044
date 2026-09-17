// ============================================================
// YECO - تسجيل الدخول (بريد → فحص وجوده → كلمة المرور → رمز البريد)
//
//  1) يُدخل المستخدم بريده. التطبيق يبحث عنه في SQLite:
//     - موجود      → خطوة كلمة المرور ثم رمز تحقق يُرسل إلى البريد
//     - غير موجود  → ينتقل تلقائياً إلى إنشاء حساب بالبريد نفسه
//  2) "نسيت كلمة المرور" متاح من خطوة كلمة المرور
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/repos.dart';
import '../../security/otp_engine.dart';
import '../../state/session.dart';
import '../../state/store.dart';
import '../shared/widgets.dart';
import 'auth_shell.dart';
import 'otp_panel.dart';
import 'recover_password_page.dart';
import 'sign_up_page.dart';

enum _Stage { email, password, otp }

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailForm = GlobalKey<FormState>();
  final _passForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  _Stage _stage = _Stage.email;
  bool _busy = false;
  OtpIssue? _otp;
  String? _userName;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Session get _session => AppScope.sessionOf(context, listen: false);

  // ------------------------------------------------------------ الخطوة 1
  Future<void> _checkEmail() async {
    if (!_emailForm.currentState!.validate()) return;
    setState(() => _busy = true);
    final r = await _session.lookup(_email.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r == EmailLookup.exists) {
      setState(() => _stage = _Stage.password);
    } else {
      notify(
        context,
        'هذا البريد غير مسجّل — لننشئ لك حساباً جديداً',
        icon: Icons.person_add_alt_1_rounded,
      );
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => SignUpPage(initialEmail: _email.text.trim()),
        ),
      );
      if (ok == true && mounted) setState(() => _stage = _Stage.email);
    }
  }

  // ------------------------------------------------------------ الخطوة 2
  Future<void> _checkPassword() async {
    if (!_passForm.currentState!.validate()) return;
    setState(() => _busy = true);
    final r = await _session.checkPassword(_email.text, _pass.text);
    if (!mounted) return;
    if (r != PasswordCheck.ok) {
      setState(() => _busy = false);
      notify(context, 'كلمة المرور غير صحيحة', error: true);
      return;
    }
    if (!_session.twoFactor) {
      await _finish();
      return;
    }
    final issue = await _issueOtp();
    if (!mounted) return;
    setState(() {
      _otp = issue;
      _stage = _Stage.otp;
      _busy = false;
    });
  }

  Future<OtpIssue> _issueOtp() async {
    _userName ??= (await const UserRepo().byEmail(_email.text))?.name;
    return OtpEngine.issue(
      _email.text,
      OtpPurpose.signIn,
      recipientName: _userName,
    );
  }

  Future<void> _finish() async {
    final u = await _session.completeSignIn(_email.text);
    if (!mounted) return;
    if (u == null) {
      setState(() => _busy = false);
      notify(context, 'تعذّر إتمام الدخول', error: true);
      return;
    }
    notify(
      context,
      'أهلاً ${u.name}! تم تسجيل الدخول',
      icon: Icons.waving_hand_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: switch (_stage) {
        _Stage.email => 'مرحباً بك في YECO',
        _Stage.password => 'أهلاً بعودتك',
        _Stage.otp => 'تحقق من بريدك',
      },
      subtitle: switch (_stage) {
        _Stage.email =>
          'أدخل بريدك الإلكتروني. إن كان مسجّلاً سنكمل الدخول، وإلا سننشئ لك حساباً جديداً.',
        _Stage.password => 'أدخل كلمة المرور الخاصة بـ ${_email.text.trim()}',
        _Stage.otp => 'أرسلنا رمز تحقق إلى بريدك لتأكيد أنك صاحب الحساب.',
      },
      onBack: _stage == _Stage.email
          ? null
          : () => setState(() {
              _stage = _stage == _Stage.otp ? _Stage.password : _Stage.email;
              _otp = null;
            }),
      footer: _stage == _Stage.email ? _signUpFooter() : null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: switch (_stage) {
          _Stage.email => _emailStage(),
          _Stage.password => _passwordStage(),
          _Stage.otp => _otpStage(),
        },
      ),
    );
  }

  Widget _emailStage() => Form(
    key: _emailForm,
    child: Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepDots(count: 3, current: 0),
        const SizedBox(height: 18),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          textDirection: TextDirection.ltr,
          autofillHints: const [AutofillHints.email],
          validator: V.email,
          onFieldSubmitted: (_) => _checkEmail(),
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني',
            hintText: 'name@example.com',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _busy ? null : _checkEmail,
          icon: _spinnerOr(Icons.arrow_forward_rounded),
          label: const Text('متابعة'),
        ),
      ],
    ),
  );

  Widget _passwordStage() => Form(
    key: _passForm,
    child: Column(
      key: const ValueKey('password'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepDots(count: 3, current: 1),
        const SizedBox(height: 18),
        PasswordField(
          controller: _pass,
          label: 'كلمة المرور',
          autofocus: true,
          textInputAction: TextInputAction.done,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'كلمة المرور مطلوبة' : null,
          onSubmitted: (_) => _checkPassword(),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RecoverPasswordPage(initialEmail: _email.text.trim()),
              ),
            ),
            child: const Text('نسيت كلمة المرور؟'),
          ),
        ),
        const SizedBox(height: 6),
        FilledButton.icon(
          onPressed: _busy ? null : _checkPassword,
          icon: _spinnerOr(Icons.login_rounded),
          label: const Text('تسجيل الدخول'),
        ),
      ],
    ),
  );

  Widget _otpStage() => Column(
    key: const ValueKey('otp'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const StepDots(count: 3, current: 2),
      const SizedBox(height: 18),
      OtpPanel(
        issue: _otp!,
        verifyLabel: 'تأكيد والدخول',
        onResend: _issueOtp,
        onVerified: _finish,
      ),
    ],
  );

  Widget _signUpFooter() => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        'ليس لديك حساب؟',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
      ),
      TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignUpPage()),
        ),
        style: TextButton.styleFrom(foregroundColor: YecoColors.accent),
        child: const Text('إنشاء حساب'),
      ),
    ],
  );

  Widget _spinnerOr(IconData icon) => _busy
      ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
      : Icon(icon);
}
