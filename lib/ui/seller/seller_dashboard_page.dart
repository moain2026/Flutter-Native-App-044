// ============================================================
// YECO - لوحة البائع: إحصاءات، الأكثر مبيعاً، توزيع التصنيفات، اختصارات
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/repos.dart';
import '../../state/store.dart';
import '../orders/orders_page.dart';
import '../shared/widgets.dart';
import '../shell/shell.dart';
import 'product_form_page.dart';
import 'seller_products_page.dart';

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  SellerStats? _stats;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final s = await const OrderRepo().stats();
    if (mounted) setState(() => _stats = s);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.storeOf(context);
    final s = _stats;
    return Scaffold(
      appBar: AppBar(
        title: const Text('متجري'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const AccountButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormPage()),
          );
          _load();
        },
        backgroundColor: YecoColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('منتج جديد'),
      ),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                children: [
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          mainAxisExtent: 86,
                        ),
                    children: [
                      StatCard(
                        label: 'الإيرادات',
                        value: fmtMoney(s.revenue),
                        icon: Icons.payments_outlined,
                        color: YecoColors.success,
                      ),
                      StatCard(
                        label: 'الطلبات',
                        value: '${s.orders}',
                        icon: Icons.receipt_long_outlined,
                        color: YecoColors.info,
                      ),
                      StatCard(
                        label: 'قيد المراجعة',
                        value: '${s.pending}',
                        icon: Icons.hourglass_top_rounded,
                        color: YecoColors.accent,
                      ),
                      StatCard(
                        label: 'المنتجات',
                        value: '${s.products}',
                        icon: Icons.inventory_2_outlined,
                      ),
                      StatCard(
                        label: 'نفدت الكمية',
                        value: '${s.outOfStock}',
                        icon: Icons.remove_shopping_cart_outlined,
                        color: YecoColors.danger,
                      ),
                      StatCard(
                        label: 'الزبائن',
                        value: '${s.customers}',
                        icon: Icons.people_outline_rounded,
                        color: const Color(0xFF8E24AA),
                      ),
                    ],
                  ),
                  const SectionHeader('إجراءات سريعة'),
                  Row(
                    children: [
                      Expanded(
                        child: _Action(
                          icon: Icons.inventory_2_outlined,
                          label: 'إدارة المنتجات',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SellerProductsPage(),
                              ),
                            );
                            _load();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Action(
                          icon: Icons.receipt_long_outlined,
                          label: 'إدارة الطلبات',
                          badge: s.pending,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const OrdersPage(sellerView: true),
                              ),
                            );
                            _load();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SectionHeader('الأكثر مبيعاً'),
                  Card(
                    child: s.topProducts.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: Text(
                              'لا توجد مبيعات بعد',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: YecoColors.inkSoft),
                            ),
                          )
                        : Column(
                            children: [
                              for (var i = 0; i < s.topProducts.length; i++)
                                ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: i == 0
                                        ? YecoColors.accent
                                        : YecoColors.primaryLight,
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: YecoColors.ink,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    s.topProducts[i].name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Pill(
                                    '${s.topProducts[i].sold} قطعة',
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const SectionHeader('توزيع المنتجات على التصنيفات'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          for (final c in store.categories) ...[
                            _Bar(
                              label: c.name,
                              value: store.countByCategory[c.id] ?? 0,
                              max: s.products == 0 ? 1 : s.products,
                              color: Color(c.colorValue),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge'),
              backgroundColor: YecoColors.accent,
              textColor: YecoColors.ink,
              child: Icon(icon, size: 30, color: YecoColors.primaryDark),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });
  final String label;
  final int value;
  final int max;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 92,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value / max,
            minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.12),
            color: color,
          ),
        ),
      ),
      SizedBox(
        width: 30,
        child: Text(
          '$value',
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ),
    ],
  );
}
