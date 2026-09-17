// ============================================================
// YECO - إصلاح اختفاء لوحة المفاتيح بعد العودة إلى التطبيق
//
// المشكلة (Android): عند الخروج إلى تطبيق البريد لنسخ الرمز ثم العودة،
// يبقى الحقل مُركَّزاً لكن لوحة المفاتيح (IME) لا تظهر.
// الحل: عند resumed → إلغاء التركيز → إطار → إعادة التركيز + TextInput.show
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardResumeFix extends StatefulWidget {
  const KeyboardResumeFix({super.key, required this.child});
  final Widget child;

  @override
  State<KeyboardResumeFix> createState() => _KeyboardResumeFixState();
}

class _KeyboardResumeFixState extends State<KeyboardResumeFix>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final focused = FocusManager.instance.primaryFocus;
    if (focused == null || focused.context == null) return;
    // نتأكد أن الحقل ينتمي إلى هذه الشاشة (المرئية حالياً)
    if (!ModalRoute.of(context)!.isCurrent) return;
    focused.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      focused.requestFocus();
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
