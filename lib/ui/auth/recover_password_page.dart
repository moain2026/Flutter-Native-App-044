// ============================================================
// YECO - استعادة كلمة المرور (3 خطوات)
//   1) البريد → هل هو مسجّل؟ → إرسال رمز إلى البريد
//   2) إدخال الرمز → مطابق؟ نعم: الخطوة 3 · لا: رسالة فشل ويبقى هنا
//   3) كلمة مرور جديدة → UPDATE فعلي في SQLite → رجوع إلى الدخول
// ============================================================

import 'package:flutter/material.dart';

import '../../data/repos.dart';
import '../../security/otp_engine.dart';
import '../../state/session.dart';
import '../../state/store.dart';
import '../shared/widgets.dart';
import 'auth_shell.dart';
import 'otp_panel.dart';

class RecoverPasswordPage extends StatefulWidget {
  const RecoverPasswordPage({super.key, this.initialEmail});
  final String? initialEmail;

  @override
  State<RecoverPasswordPage> createState() => _RecoverPasswordPageState();
}

class _RecoverPasswordPageState extends State<RecoverPasswordPage> {
  final _emailForm = GlobalKey<FormState>();
  final _passForm = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  int _step = 0;
  bool _busy = false;
  OtpIssue? _otp;
  String? _name;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_emailForm.currentState!.validate()) return;
    setState(() => _busy = true);
    final session = AppScope.sessionOf(context, listen: false);
    if ((await session.lookup(_email.text)) == EmailLookup.notFound) {
      if (!mounted) return;
      setState(() => _busy = false);
      notify(context, 'لا يوجد حساب بهذا البريد', error: true);
      return;
    }
    _name = (await const UserRepo().byEmail(_email.text))?.name;
    final issue = await _issue();
    if (!mounted) return;
    setState(() {
      _otp = issue;
      _step = 1;
      _busy = false;
    });
  }

  Future<OtpIssue> _issue() =>
      OtpEngine.issue(_email.text, OtpPurpose.reset, recipientName: _name);

  Future<void> _save() async {
    if (!_passForm.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await AppScope.sessionOf(
      context,
      listen: false,
    ).resetPassword(_email.text, _pass.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      notify(context, 'تعذّر تحديث كلمة المرور', error: true);
      return;
    }
    notify(
      context,
      'تم تغيير كلمة المرور بنجاح، سجّل الدخول الآن',
      icon: Icons.lock_reset_rounded,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: switch (_step) {
        0 => 'نسيت كلمة المرور؟',
        1 => 'أدخل رمز التحقق',
        _ => 'كلمة مرور جديدة',
      },
      subtitle: switch (_step) {
        0 =>
          'أدخل بريدك المسجّل وسنرسل إليه رمز تحقق لإعادة تعيين كلمة المرور.',
        1 => 'إن كان الرمز مطابقاً للمُرسل ستنتقل لتعيين كلمة مرور جديدة.',
        _ => 'اختر كلمة مرور قوية (6 أحرف على الأقل وتحوي رقماً).',
      },
      onBack: () => _step == 0
          ? Navigator.pop(context)
          : setState(() {
              _step--;
              if (_step == 0) _otp = null;
            }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepDots(count: 3, current: _step),
          const SizedBox(height: 18),
          switch (_step) {
            0 => _emailStep(),
            1 => OtpPanel(
              issue: _otp!,
              verifyLabel: 'تحقق من الرمز',
              onResend: _issue,
              onVerified: () async => setState(() => _step = 2),
            ),
            _ => _passwordStep(),
          },
        ],
      ),
    );
  }

  Widget _emailStep() => Form(
    key: _emailForm,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.done,
          validator: V.email,
          onFieldSubmitted: (_) => _sendCode(),
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _busy ? null : _sendCode,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded),
          label: const Text('إرسال الرمز'),
        ),
      ],
    ),
  );

  Widget _passwordStep() => Form(
    key: _passForm,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PasswordField(
          controller: _pass,
          label: 'كلمة المرور الجديدة',
          autofocus: true,
          validator: V.password,
        ),
        const SizedBox(height: 12),
        PasswordField(
          controller: _confirm,
          label: 'تأكيد كلمة المرور',
          textInputAction: TextInputAction.done,
          validator: (v) => V.confirmPassword(v, _pass.text),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _busy ? null : _save,
          icon: const Icon(Icons.save_rounded),
          label: const Text('حفظ كلمة المرور'),
        ),
      ],
    ),
  );
}
