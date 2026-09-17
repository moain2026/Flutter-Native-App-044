// ============================================================
// YECO - حول التطبيق (الإصدار، المطوّر، المزايا، التقنيات)
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../state/store.dart';

/// المصدر: pubspec.yaml → version: 1.0.0+1
const appVersion = '1.0.0';
const appBuild = 1;

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.storeOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('حول التطبيق')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/brand/logo_rounded.png',
                  width: 96,
                  height: 96,
                ),
                const SizedBox(height: 12),
                Text(
                  store.storeName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const Text(
                  'تسوّق بذكاء',
                  style: TextStyle(color: YecoColors.inkSoft),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: YecoColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'الإصدار $appVersion (build $appBuild)',
                    style: const TextStyle(
                      color: YecoColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.code_rounded,
                    color: YecoColors.primaryDark,
                  ),
                  title: const Text(
                    'المطوّر',
                    style: TextStyle(fontSize: 12, color: YecoColors.inkSoft),
                  ),
                  subtitle: Text(
                    store.developerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: YecoColors.ink,
                    ),
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                const ListTile(
                  leading: Icon(
                    Icons.school_outlined,
                    color: YecoColors.primaryDark,
                  ),
                  title: Text(
                    'المقرر',
                    style: TextStyle(fontSize: 12, color: YecoColors.inkSoft),
                  ),
                  subtitle: Text(
                    'تطوير تطبيقات الهاتف — Flutter',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: YecoColors.ink,
                    ),
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                const ListTile(
                  leading: Icon(
                    Icons.android_rounded,
                    color: YecoColors.primaryDark,
                  ),
                  title: Text(
                    'المنصة',
                    style: TextStyle(fontSize: 12, color: YecoColors.inkSoft),
                  ),
                  subtitle: Text(
                    'Android · com.yecomarket.shop',
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: YecoColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ماذا يقدّم التطبيق؟',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: const [
                _Feature(
                  Icons.grid_view_rounded,
                  'ستة تصنيفات',
                  'أثاث، مواد غذائية، إلكترونيات، ملابس، منزل ومطبخ، رياضة',
                ),
                _Feature(
                  Icons.shopping_cart_outlined,
                  'سلة وطلبات',
                  'كوبونات خصم، توصيل مجاني فوق 300 ر.س، تتبّع حالة الطلب',
                ),
                _Feature(
                  Icons.storefront_outlined,
                  'دور البائع',
                  'إضافة وتعديل وحذف المنتجات، إدارة الطلبات، إحصاءات',
                ),
                _Feature(
                  Icons.mark_email_read_outlined,
                  'تحقق بالبريد',
                  'رمز 6 أرقام يُرسل إلى بريدك عند الدخول والتسجيل والاستعادة',
                ),
                _Feature(
                  Icons.storage_rounded,
                  'SQLite محلية',
                  'كل البيانات محفوظة على الجهاز وتبقى بعد إغلاق التطبيق',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'التقنيات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              Chip(label: Text('Flutter 3.35')),
              Chip(label: Text('Dart 3.9')),
              Chip(label: Text('Material 3')),
              Chip(label: Text('sqflite')),
              Chip(label: Text('shared_preferences')),
              Chip(label: Text('mailer (SMTP)')),
              Chip(label: Text('crypto')),
              Chip(label: Text('image_picker')),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '© ${DateTime.now().year} ${store.storeName} — تطوير ${store.developerName}',
              style: const TextStyle(color: YecoColors.inkSoft, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.title, this.sub);
  final IconData icon;
  final String title;
  final String sub;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: YecoColors.primaryDark),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
    subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
  );
}
