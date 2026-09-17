// ============================================================
// YECO - شاشة القفل (الترخيص غير مفعّل أو موقوف نهائياً)
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../security/license_gate.dart';
import '../shared/widgets.dart';

class LockedPage extends StatefulWidget {
  const LockedPage({super.key, required this.verdict, required this.onGranted});
  final LicenseVerdict verdict;
  final VoidCallback onGranted;

  @override
  State<LockedPage> createState() => _LockedPageState();
}

class _LockedPageState extends State<LockedPage> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  late LicenseVerdict _v = widget.verdict;

  bool get _revoked => _v.state == LicenseState.revoked;

  @override
  void didUpdateWidget(covariant LockedPage old) {
    super.didUpdateWidget(old);
    if (old.verdict != widget.verdict) _v = widget.verdict;
  }

  Future<void> _unlock() async {
    if (_code.text.trim().isEmpty) {
      setState(() => _error = 'أدخل كود التفعيل');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await LicenseGate.unlock(_code.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      notify(context, 'تم التفعيل بنجاح', icon: Icons.lock_open_rounded);
      widget.onGranted();
    } else {
      setState(() => _error = 'كود التفعيل غير صحيح');
    }
  }

  Future<void> _recheck() async {
    setState(() => _busy = true);
    final v = await LicenseGate.check();
    if (!mounted) return;
    setState(() {
      _v = v;
      _busy = false;
    });
    if (v.state == LicenseState.active) {
      widget.onGranted();
    } else {
      notify(
        context,
        v.offline
            ? 'لا يوجد اتصال — الحالة المحفوظة: ${v.state.label}'
            : 'الحالة: ${v.state.label}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YecoColors.ink,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: (_revoked ? YecoColors.danger : YecoColors.accent)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _revoked ? Icons.block_rounded : Icons.lock_outline_rounded,
                    size: 46,
                    color: _revoked ? YecoColors.danger : YecoColors.accent,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _revoked ? 'النسخة موقوفة نهائياً' : 'التطبيق يحتاج تفعيل',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _v.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    height: 1.6,
                  ),
                ),
                if (_v.offline) ...[
                  const SizedBox(height: 8),
                  const Pill(
                    'بلا اتصال — آخر حالة محفوظة',
                    color: YecoColors.accent,
                    icon: Icons.wifi_off_rounded,
                  ),
                ],
                const SizedBox(height: 26),
                if (!_revoked) ...[
                  TextField(
                    controller: _code,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'YECO-XXXX',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        letterSpacing: 2,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      errorText: _error,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _unlock(),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _busy ? null : _unlock,
                    style: FilledButton.styleFrom(
                      backgroundColor: YecoColors.accent,
                      foregroundColor: YecoColors.ink,
                    ),
                    icon: const Icon(Icons.key_rounded),
                    label: const Text('تفعيل'),
                  ),
                  const SizedBox(height: 8),
                ],
                OutlinedButton.icon(
                  onPressed: _busy ? null : _recheck,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة التحقق من الترخيص'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
