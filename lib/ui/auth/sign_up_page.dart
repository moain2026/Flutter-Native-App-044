// ============================================================
// YECO - إنشاء حساب (البيانات → رمز يُرسل إلى البريد → الحساب يُنشأ بعد التحقق)
// الحساب لا يُكتب في SQLite قبل تأكيد البريد.
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../security/otp_engine.dart';
import '../../state/session.dart';
import '../../state/store.dart';
import '../shared/widgets.dart';
import 'auth_shell.dart';
import 'otp_panel.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key, this.initialEmail});
  final String? initialEmail;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  UserRole _role = UserRole.customer;
  bool _agree = false;
  bool _busy = false;
  OtpIssue? _otp;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _city, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_agree) {
      notify(context, 'يجب الموافقة على الشروط للمتابعة', error: true);
      return;
    }
    setState(() => _busy = true);
    final session = AppScope.sessionOf(context, listen: false);
    if ((await session.lookup(_email.text)) == EmailLookup.exists) {
      if (!mounted) return;
      setState(() => _busy = false);
      notify(
        context,
        'هذا البريد مسجّل مسبقاً — سجّل الدخول بدلاً من ذلك',
        error: true,
      );
      return;
    }
    final issue = await _issue();
    if (!mounted) return;
    setState(() {
      _otp = issue;
      _busy = false;
    });
  }

  Future<OtpIssue> _issue() => OtpEngine.issue(
    _email.text,
    OtpPurpose.signUp,
    recipientName: _name.text,
  );

  Future<void> _create() async {
    final session = AppScope.sessionOf(context, listen: false);
    final u = await session.signUp(
      name: _name.text,
      email: _email.text,
      password: _pass.text,
      phone: _phone.text,
      city: _city.text,
      role: _role,
    );
    if (!mounted) return;
    notify(
      context,
      'تم إنشاء حسابك بنجاح، أهلاً ${u.name}!',
      icon: Icons.celebration_rounded,
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final verifying = _otp != null;
    return AuthShell(
      title: verifying ? 'تأكيد البريد' : 'إنشاء حساب جديد',
      subtitle: verifying
          ? 'أدخل الرمز المُرسل إلى بريدك لإتمام إنشاء الحساب.'
          : 'أنشئ حسابك كزبون للتسوّق، أو كبائع لإدارة منتجاتك وطلباتك.',
      onBack: () =>
          verifying ? setState(() => _otp = null) : Navigator.pop(context),
      child: verifying ? _otpStage() : _formStage(),
    );
  }

  Widget _otpStage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const StepDots(count: 2, current: 1),
      const SizedBox(height: 18),
      OtpPanel(
        issue: _otp!,
        verifyLabel: 'تأكيد وإنشاء الحساب',
        onResend: _issue,
        onVerified: _create,
      ),
    ],
  );

  Widget _formStage() => Form(
    key: _form,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepDots(count: 2, current: 0),
        const SizedBox(height: 18),
        SegmentedButton<UserRole>(
          segments: const [
            ButtonSegment(
              value: UserRole.customer,
              label: Text('زبون'),
              icon: Icon(Icons.shopping_bag_outlined),
            ),
            ButtonSegment(
              value: UserRole.seller,
              label: Text('بائع'),
              icon: Icon(Icons.storefront_outlined),
            ),
          ],
          selected: {_role},
          onSelectionChanged: (s) => setState(() => _role = s.first),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: YecoColors.primary,
            selectedForegroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _name,
          textInputAction: TextInputAction.next,
          validator: V.name,
          decoration: const InputDecoration(
            labelText: 'الاسم الكامل',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          textDirection: TextDirection.ltr,
          validator: V.email,
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          textDirection: TextDirection.ltr,
          validator: V.phone,
          decoration: const InputDecoration(
            labelText: 'رقم الجوال',
            prefixIcon: Icon(Icons.phone_android_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _city,
          textInputAction: TextInputAction.next,
          validator: (v) => V.required(v, 'المدينة'),
          decoration: const InputDecoration(
            labelText: 'المدينة',
            prefixIcon: Icon(Icons.location_city_rounded),
          ),
        ),
        const SizedBox(height: 12),
        PasswordField(
          controller: _pass,
          label: 'كلمة المرور',
          validator: V.password,
        ),
        const SizedBox(height: 12),
        PasswordField(
          controller: _confirm,
          label: 'تأكيد كلمة المرور',
          textInputAction: TextInputAction.done,
          validator: (v) => V.confirmPassword(v, _pass.text),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 6),
        CheckboxListTile(
          value: _agree,
          onChanged: (v) => setState(() => _agree = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'أوافق على شروط الاستخدام وسياسة الخصوصية',
            style: TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _busy ? null : _submit,
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
          label: const Text('إرسال رمز التحقق'),
        ),
      ],
    ),
  );
}
