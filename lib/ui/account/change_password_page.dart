// ============================================================
// YECO - تغيير كلمة المرور من داخل الحساب
// ============================================================

import 'package:flutter/material.dart';

import '../../state/store.dart';
import '../auth/auth_shell.dart';
import '../shared/widgets.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final err = await AppScope.sessionOf(
      context,
      listen: false,
    ).changePassword(_current.text, _next.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      notify(context, err, error: true);
      return;
    }
    notify(
      context,
      'تم تغيير كلمة المرور بنجاح',
      icon: Icons.lock_reset_rounded,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تغيير كلمة المرور')),
    body: Form(
      key: _form,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PasswordField(
            controller: _current,
            label: 'كلمة المرور الحالية',
            validator: (v) => V.required(v, 'كلمة المرور الحالية'),
          ),
          const SizedBox(height: 12),
          PasswordField(
            controller: _next,
            label: 'كلمة المرور الجديدة',
            validator: V.password,
          ),
          const SizedBox(height: 12),
          PasswordField(
            controller: _confirm,
            label: 'تأكيد كلمة المرور الجديدة',
            textInputAction: TextInputAction.done,
            validator: (v) => V.confirmPassword(v, _next.text),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('حفظ'),
          ),
        ],
      ),
    ),
  );
}
