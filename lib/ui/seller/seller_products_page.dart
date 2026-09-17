// ============================================================
// YECO - إدارة المنتجات (بائع): بحث، تصفية، تعديل، حذف بالسحب، تبديل "مميز"
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/store.dart';
import '../catalog/product_card.dart';
import '../shared/widgets.dart';
import 'product_form_page.dart';

class SellerProductsPage extends StatefulWidget {
  const SellerProductsPage({super.key});

  @override
  State<SellerProductsPage> createState() => _SellerProductsPageState();
}

class _SellerProductsPageState extends State<SellerProductsPage> {
  final _search = TextEditingController();
  int? _catId;
  bool _lowStockOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _delete(Store store, Product p) async {
    await store.deleteProduct(p.id);
    if (mounted) {
      notify(context, 'تم حذف "${p.name}"', icon: Icons.delete_outline_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.storeOf(context);
    final q = _search.text.trim().toLowerCase();
    final items = store.products.where((p) {
      if (_catId != null && p.categoryId != _catId) return false;
      if (_lowStockOnly && p.stock > 5) return false;
      if (q.isNotEmpty &&
          !p.name.toLowerCase().contains(q) &&
          !p.brand.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('المنتجات (${items.length})')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductFormPage()),
        ),
        backgroundColor: YecoColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ابحث في منتجاتك...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => setState(_search.clear),
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip(
                  'الكل',
                  _catId == null,
                  () => setState(() => _catId = null),
                ),
                for (final c in store.categories)
                  _chip(
                    c.name,
                    _catId == c.id,
                    () => setState(() => _catId = c.id),
                  ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('مخزون منخفض ≤5'),
                  selected: _lowStockOnly,
                  onSelected: (v) => setState(() => _lowStockOnly = v),
                  labelStyle: TextStyle(
                    color: _lowStockOnly ? Colors.white : YecoColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'لا توجد منتجات مطابقة',
                    subtitle: 'أضف منتجاً جديداً من زر +',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final p = items[i];
                      return Dismissible(
                        key: ValueKey('sp-${p.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: AlignmentDirectional.centerEnd,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: YecoColors.danger,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                          ),
                        ),
                        confirmDismiss: (_) => confirm(
                          context,
                          title: 'حذف المنتج',
                          message: 'حذف "${p.name}" نهائياً؟',
                          okLabel: 'حذف',
                          danger: true,
                        ),
                        onDismissed: (_) => _delete(store, p),
                        child: _SellerRow(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: selected ? Colors.white : YecoColors.ink,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _SellerRow extends StatelessWidget {
  const _SellerRow(this.p);
  final Product p;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.storeOf(context, listen: false);
    final low = p.stock <= 5;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openProduct(context, p),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(width: 70, height: 70, child: ProductImage(p.image)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${store.categoryOf(p.categoryId)?.name ?? ''} · ${p.brand}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: YecoColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          fmtMoney(p.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: YecoColors.primaryDark,
                          ),
                        ),
                        Pill(
                          p.inStock ? 'مخزون ${p.stock}' : 'نفد',
                          color: p.inStock
                              ? (low ? YecoColors.accent : YecoColors.success)
                              : YecoColors.danger,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: p.featured ? 'إزالة من المميزة' : 'تمييز',
                    onPressed: () async {
                      await store.updateProduct(
                        p.copyWith(featured: !p.featured),
                      );
                      if (context.mounted) {
                        notify(
                          context,
                          p.featured ? 'أُزيل من المميزة' : 'أُضيف إلى المميزة',
                        );
                      }
                    },
                    icon: Icon(
                      p.featured
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: YecoColors.accent,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'تعديل',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductFormPage(product: p),
                      ),
                    ),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: YecoColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
