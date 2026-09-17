// ============================================================
// YECO - حسابي: بيانات المستخدم، طلباتي، تعديل البيانات، كلمة المرور،
// الإعدادات، حول التطبيق، تسجيل الخروج، حذف الحساب
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../state/store.dart';
import '../orders/orders_page.dart';
import '../shared/widgets.dart';
import 'about_page.dart';
import 'change_password_page.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.sessionOf(context);
    final u = session.user;
    if (u == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------------- رأس المستخدم
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [YecoColors.primary, YecoColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    u.name.characters.first,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: YecoColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        u.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          Pill(
                            u.role.label,
                            color: Colors.white,
                            icon: u.isSeller
                                ? Icons.storefront_outlined
                                : Icons.shopping_bag_outlined,
                          ),
                          if (u.city.isNotEmpty)
                            Pill(
                              u.city,
                              color: Colors.white,
                              icon: Icons.location_on_outlined,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('الطلبات'),
          Card(
            child: Column(
              children: [
                _tile(
                  context,
                  Icons.receipt_long_outlined,
                  u.isSeller ? 'إدارة الطلبات' : 'طلباتي',
                  u.isSeller
                      ? 'كل طلبات الزبائن وتغيير حالتها'
                      : 'تتبع طلباتك وإلغاؤها',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrdersPage(sellerView: u.isSeller),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('الحساب'),
          Card(
            child: Column(
              children: [
                _tile(
                  context,
                  Icons.edit_outlined,
                  'تعديل البيانات',
                  'الاسم، الجوال، المدينة',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  ),
                ),
                const Divider(indent: 56),
                _tile(
                  context,
                  Icons.lock_outline_rounded,
                  'تغيير كلمة المرور',
                  null,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordPage(),
                    ),
                  ),
                ),
                const Divider(indent: 56),
                _tile(
                  context,
                  Icons.settings_outlined,
                  'الإعدادات',
                  'التحقق بخطوتين، اسم المتجر، اسم المطوّر',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ),
                ),
                const Divider(indent: 56),
                _tile(
                  context,
                  Icons.info_outline_rounded,
                  'حول التطبيق',
                  null,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutPage()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await confirm(
                context,
                title: 'تسجيل الخروج',
                message: 'هل تريد تسجيل الخروج من حسابك؟',
                okLabel: 'خروج',
              );
              if (ok) await session.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('تسجيل الخروج'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              final ok = await confirm(
                context,
                title: 'حذف الحساب',
                message:
                    'سيُحذف حسابك وسلتك ومفضلتك وطلباتك نهائياً. لا يمكن التراجع.',
                okLabel: 'حذف نهائي',
                danger: true,
              );
              if (ok) {
                await session.deleteAccount();
                if (context.mounted) notify(context, 'تم حذف الحساب');
              }
            },
            style: TextButton.styleFrom(foregroundColor: YecoColors.danger),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('حذف الحساب'),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext c,
    IconData icon,
    String title,
    String? sub,
    VoidCallback onTap,
  ) => ListTile(
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: YecoColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: YecoColors.primaryDark, size: 22),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: sub == null
        ? null
        : Text(sub, style: const TextStyle(fontSize: 12)),
    trailing: const Icon(Icons.chevron_left_rounded),
    onTap: onTap,
  );
}
