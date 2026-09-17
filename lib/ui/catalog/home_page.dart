// ============================================================
// YECO - الرئيسية: بحث، بانر عروض، شرائح التصنيفات، المميزة، العروض، الجديد
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/store.dart';
import '../shared/widgets.dart';
import '../shell/shell.dart';
import 'product_card.dart';
import 'product_list_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.storeOf(context);
    final session = AppScope.sessionOf(context);
    final u = session.user;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: store.refreshCatalog,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              // ---------------- الرأس
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/brand/logo_rounded.png',
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرحباً ${u?.name.split(' ').first ?? ''} 👋',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            u?.city.isNotEmpty == true
                                ? 'التوصيل إلى ${u!.city}'
                                : store.storeName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: YecoColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const AccountButton(),
                  ],
                ),
              ),
              // ---------------- البحث
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ProductListPage(autofocusSearch: true),
                    ),
                  ),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: YecoColors.line),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search_rounded, color: YecoColors.inkSoft),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ابحث عن منتج، ماركة...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Color(0xFF9AA6B2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ---------------- البانر
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _PromoBanner(),
              ),
              // ---------------- التصنيفات
              SectionHeader(
                'تسوّق حسب التصنيف',
                action: 'الكل',
                onAction: () =>
                    ShellController.maybeOf(context)?.go(ShellTab.categories),
              ),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: store.categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _CategoryChip(store.categories[i]),
                ),
              ),
              // ---------------- المميزة
              if (store.featured.isNotEmpty) ...[
                SectionHeader(
                  'منتجات مميزة',
                  action: 'عرض الكل',
                  onAction: () =>
                      _openList(context, 'منتجات مميزة', featured: true),
                ),
                _HScroll(store.featured),
              ],
              // ---------------- العروض
              if (store.discounted.isNotEmpty) ...[
                SectionHeader(
                  'عروض وخصومات',
                  action: 'عرض الكل',
                  onAction: () =>
                      _openList(context, 'عروض وخصومات', discounted: true),
                ),
                _HScroll(store.discounted),
              ],
              // ---------------- الجديد
              SectionHeader(
                'وصل حديثاً',
                action: 'عرض الكل',
                onAction: () => _openList(context, 'كل المنتجات'),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.58,
                ),
                itemCount: store.newest.length.clamp(0, 4),
                itemBuilder: (_, i) => ProductCard(store.newest[i]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openList(
    BuildContext context,
    String title, {
    bool featured = false,
    bool discounted = false,
  }) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProductListPage(
        title: title,
        onlyFeatured: featured,
        onlyDiscounted: discounted,
      ),
    ),
  );
}

class _HScroll extends StatelessWidget {
  const _HScroll(this.items);
  final List<Product> items;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 290,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, i) => ProductCard(items[i], width: 160),
    ),
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(this.c);
  final Category c;
  @override
  Widget build(BuildContext context) {
    final color = Color(c.colorValue);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductListPage(category: c)),
      ),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(categoryIcon(c.iconCode), color: color, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              c.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 120),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [YecoColors.primary, YecoColors.primaryDark],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          left: -30,
          top: -30,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
        Positioned(
          left: 20,
          bottom: -40,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: YecoColors.accent.withValues(alpha: 0.25),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Pill(
                      'كوبون WELCOME',
                      color: YecoColors.accent,
                      icon: Icons.local_offer_rounded,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'خصم 15% على طلبك الأول',
                      maxLines: 2,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'للطلبات فوق 100 ر.س · توصيل مجاني فوق 300 ر.س',
                      maxLines: 2,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.shopping_bag_rounded,
                color: Colors.white,
                size: 54,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
