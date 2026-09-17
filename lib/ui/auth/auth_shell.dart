// ============================================================
// YECO - هيكل شاشات المصادقة (رأس بالشعار + بطاقة المحتوى)
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../shared/keyboard_resume_fix.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return KeyboardResumeFix(
      child: Scaffold(
        backgroundColor: YecoColors.primaryDark,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight - 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (onBack != null)
                          IconButton(
                            onPressed: onBack,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                          ),
                        const Spacer(),
                        Image.asset(
                          'assets/brand/logo_rounded.png',
                          width: 44,
                          height: 44,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: 18),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// خطوات صغيرة أعلى البطاقة (1 ● ● ●)
class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.count, required this.current});
  final int count;
  final int current;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < count; i++) ...[
        Expanded(
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: i <= current ? YecoColors.primary : YecoColors.line,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        if (i < count - 1) const SizedBox(width: 6),
      ],
    ],
  );
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.onSubmitted,
    this.textInputAction = TextInputAction.next,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;
  final bool autofocus;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: _hidden,
    autofocus: widget.autofocus,
    textInputAction: widget.textInputAction,
    validator: widget.validator,
    onFieldSubmitted: widget.onSubmitted,
    decoration: InputDecoration(
      labelText: widget.label,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: IconButton(
        onPressed: () => setState(() => _hidden = !_hidden),
        icon: Icon(
          _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
  );
}
