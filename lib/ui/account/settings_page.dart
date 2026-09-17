// ============================================================
// YECO - الإعدادات: التحقق بخطوتين، اسم المتجر، اسم المطوّر (يُحفظ في SQLite)
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../state/store.dart';
import '../shared/widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _editText(
    BuildContext context, {
    required String title,
    required String initial,
    required Future<void> Function(String) onSave,
  }) async {
    final ctrl = TextEditingController(text: initial);
    final form = GlobalKey<FormState>();
    final v = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Form(
          key: form,
          child: TextFormField(
            controller: ctrl,
            autofocus: true,
            validator: (x) => V.minLen(x, 2, title),
            decoration: const InputDecoration(),
            onFieldSubmitted: (_) {
              if (form.currentState!.validate()) Navigator.pop(c, ctrl.text);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(c, ctrl.text);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (v == null) return;
    await onSave(v);
    if (context.mounted) notify(context, 'تم الحفظ');
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.sessionOf(context);
    final store = AppScope.storeOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader('الأمان'),
          Card(
            child: SwitchListTile(
              value: session.twoFactor,
              onChanged: (v) {
                session.setTwoFactor(v);
                notify(
                  context,
                  v
                      ? 'سيُطلب رمز البريد عند كل تسجيل دخول'
                      : 'تم إيقاف رمز البريد عند الدخول',
                );
              },
              secondary: const Icon(
                Icons.verified_user_outlined,
                color: YecoColors.primaryDark,
              ),
              title: const Text(
                'التحقق بخطوتين عند الدخول',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'إرسال رمز إلى البريد بعد كلمة المرور',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SectionHeader('التطبيق'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.storefront_outlined,
                    color: YecoColors.primaryDark,
                  ),
                  title: const Text(
                    'اسم المتجر',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(store.storeName),
                  trailing: const Icon(Icons.edit_outlined, size: 20),
                  onTap: () => _editText(
                    context,
                    title: 'اسم المتجر',
                    initial: store.storeName,
                    onSave: store.setStoreName,
                  ),
                ),
                const Divider(indent: 56),
                ListTile(
                  leading: const Icon(
                    Icons.code_rounded,
                    color: YecoColors.primaryDark,
                  ),
                  title: const Text(
                    'اسم المطوّر',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(store.developerName),
                  trailing: const Icon(Icons.edit_outlined, size: 20),
                  onTap: () => _editText(
                    context,
                    title: 'اسم المطوّر',
                    initial: store.developerName,
                    onSave: store.setDeveloperName,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'تُحفظ هذه الإعدادات في قاعدة البيانات المحلية وتظهر في شاشة "حول التطبيق".',
              style: TextStyle(fontSize: 12, color: YecoColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}
