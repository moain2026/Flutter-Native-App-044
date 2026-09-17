// ============================================================
// YECO - لوحة إدخال رمز التحقق (مشتركة بين الدخول/الإنشاء/الاستعادة)
// عدّاد الصلاحية، المحاولات المتبقية، إعادة الإرسال، لصق من الحافظة،
// وعرض الرمز داخل التطبيق مع زر نسخ عند تعذّر الإرسال (وضع المعاينة)
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../security/otp_engine.dart';
import '../shared/widgets.dart';

class OtpPanel extends StatefulWidget {
  const OtpPanel({
    super.key,
    required this.issue,
    required this.onVerified,
    required this.onResend,
    this.verifyLabel = 'تحقق',
  });

  final OtpIssue issue;
  final Future<void> Function() onVerified;
  final Future<OtpIssue> Function() onResend;
  final String verifyLabel;

  @override
  State<OtpPanel> createState() => _OtpPanelState();
}

class _OtpPanelState extends State<OtpPanel> {
  late OtpIssue _issue = widget.issue;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _tick;
  bool _busy = false;
  int _attemptsLeft = OtpTicket.maxAttempts;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void didUpdateWidget(covariant OtpPanel old) {
    super.didUpdateWidget(old);
    if (old.issue != widget.issue) _issue = widget.issue;
  }

  @override
  void dispose() {
    _tick?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  OtpTicket get _t => _issue.ticket;

  String _mmss(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  Future<void> _verify() async {
    final err = V.otp(_ctrl.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await OtpEngine.verify(_t.email, _t.purpose, _ctrl.text);
    if (!mounted) return;
    switch (r) {
      case OtpVerify.ok:
        await widget.onVerified();
        if (mounted) setState(() => _busy = false);
      case OtpVerify.wrong:
        _attemptsLeft--;
        setState(() {
          _busy = false;
          _error =
              'الرمز غير مطابق للرمز المُرسل. المحاولات المتبقية: $_attemptsLeft';
        });
        _ctrl.clear();
        _focus.requestFocus();
      case OtpVerify.expired:
        setState(() {
          _busy = false;
          _error = 'انتهت صلاحية الرمز. اطلب رمزاً جديداً.';
        });
      case OtpVerify.locked:
        setState(() {
          _busy = false;
          _attemptsLeft = 0;
          _error = 'تجاوزت عدد المحاولات المسموح. اطلب رمزاً جديداً.';
        });
      case OtpVerify.none:
        setState(() {
          _busy = false;
          _error = 'لا يوجد رمز نشط. اطلب رمزاً جديداً.';
        });
    }
  }

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await widget.onResend();
    if (!mounted) return;
    setState(() {
      _issue = r;
      _attemptsLeft = OtpTicket.maxAttempts;
      _busy = false;
    });
    _ctrl.clear();
    _focus.requestFocus();
    notify(
      context,
      r.delivered ? 'أُرسل رمز جديد إلى ${_t.email}' : 'تم إصدار رمز جديد',
      icon: Icons.mark_email_read_outlined,
    );
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) notify(context, 'تم نسخ الرمز');
  }

  Future<void> _paste() async {
    final d = await Clipboard.getData('text/plain');
    final digits = (d?.text ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 6) {
      _ctrl.text = digits.substring(0, 6);
      setState(() => _error = null);
    } else if (mounted) {
      notify(context, 'لا يوجد رمز مكوّن من 6 أرقام في الحافظة', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expired = _t.isExpired;
    final dead = expired || _attemptsLeft <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        if (!_issue.delivered) _preview(),
        const SizedBox(height: 18),
        TextField(
          controller: _ctrl,
          focusNode: _focus,
          enabled: !dead && !_busy,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 28,
            letterSpacing: 12,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••',
            hintStyle: const TextStyle(
              letterSpacing: 12,
              color: Color(0xFFB8C2CC),
            ),
            errorText: _error,
            suffixIcon: IconButton(
              tooltip: 'لصق',
              onPressed: dead ? null : _paste,
              icon: const Icon(Icons.content_paste_rounded),
            ),
          ),
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => dead ? null : _verify(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              expired ? Icons.timer_off_outlined : Icons.timer_outlined,
              size: 16,
              color: expired ? YecoColors.danger : YecoColors.inkSoft,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                expired
                    ? 'انتهت صلاحية الرمز'
                    : 'صالح لمدة ${_mmss(_t.remaining)}',
                style: TextStyle(
                  color: expired ? YecoColors.danger : YecoColors.inkSoft,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              'المحاولات: $_attemptsLeft/${OtpTicket.maxAttempts}',
              style: const TextStyle(color: YecoColors.inkSoft, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: dead || _busy ? null : _verify,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.verified_rounded),
          label: Text(widget.verifyLabel),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: (_t.canResend || dead) && !_busy ? _resend : null,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(
            _t.canResend || dead
                ? 'إعادة إرسال الرمز'
                : 'إعادة الإرسال بعد ${_mmss(_t.resendIn)}',
          ),
        ),
      ],
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: YecoColors.primaryLight,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.mark_email_unread_outlined,
          color: YecoColors.primaryDark,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _issue.delivered
                    ? 'أرسلنا رمزاً من 6 أرقام إلى بريدك'
                    : 'تم إصدار رمز التحقق',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                _t.email,
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: YecoColors.inkSoft, fontSize: 13),
              ),
              if (_issue.delivered)
                const Text(
                  'لم يصل؟ تحقّق من مجلد الرسائل غير المرغوبة (Spam).',
                  style: TextStyle(color: YecoColors.inkSoft, fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  /// وضع المعاينة: تعذّر الإرسال (بناء بلا SMTP أو خطأ شبكة) → نعرض الرمز
  Widget _preview() {
    final code = _t.previewCode ?? '';
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: YecoColors.accentLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: YecoColors.accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF9A6A00),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _issue.error.isEmpty
                      ? 'خدمة البريد غير متاحة في هذا البناء؛ الرمز معروض هنا:'
                      : 'تعذّر الإرسال (${_issue.error}). الرمز معروض هنا:',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B4A00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  code,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w800,
                    color: YecoColors.ink,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'نسخ الرمز',
                onPressed: () => _copy(code),
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
