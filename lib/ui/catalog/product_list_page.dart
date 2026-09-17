// ============================================================
// YECO - قائمة المنتجات: بحث حي، تصفية بالتصنيف، ترتيب، عرض شبكة/قائمة
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/store.dart';
import '../shared/widgets.dart';
import 'product_card.dart';

enum _Sort {
  featured('الأكثر تميّزاً'),
  priceAsc('السعر: من الأقل'),
  priceDesc('السعر: من الأعلى'),
  rating('الأعلى تقييماً'),
  newest('الأحدث');

  const _Sort(this.label);
  final String label;
}

class ProductListPage extends StatefulWidget {
  const ProductListPage({
    super.key,
    this.category,
    this.title,
    this.onlyFeatured = false,
    this.onlyDiscounted = false,
    this.autofocusSearch = false,
  });

  final Category? category;
  final String? title;
  final bool onlyFeatured;
  final bool onlyDiscounted;
  final bool autofocusSearch;

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _search = TextEditingController();
  late int? _catId = widget.category?.id;
  _Sort _sort = _Sort.featured;
  bool _grid = true;
  bool _inStockOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Product> _apply(List<Product> all) {
    final q = _search.text.trim().toLowerCase();
    var l = all.where((p) {
      if (_catId != null && p.categoryId != _catId) return false;
      if (widget.onlyFeatured && !p.featured) return false;
      if (widget.onlyDiscounted && !p.hasDiscount) return false;
      if (_inStockOnly && !p.inStock) return false;
      if (q.isNotEmpty &&
          !p.name.toLowerCase().contains(q) &&
          !p.brand.toLowerCase().contains(q) &&
          !p.description.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
    switch (_sort) {
      case _Sort.featured:
        l.sort((a, b) {
          final f = (b.featured ? 1 : 0) - (a.featured ? 1 : 0);
          return f != 0 ? f : b.rating.compareTo(a.rating);
        });
      case _Sort.priceAsc:
        l.sort((a, b) => a.price.compareTo(b.price));
      case _Sort.priceDesc:
        l.sort((a, b) => b.price.compareTo(a.price));
      case _Sort.rating:
        l.sort((a, b) => b.rating.compareTo(a.rating));
      case _Sort.newest:
        l.sort((a, b) => b.id.compareTo(a.id));
    }
    return l;
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.storeOf(context);
    final items = _apply(store.products);
    final title =
        widget.title ??
        (_catId != null
            ? (store.categoryOf(_catId!)?.name ?? 'المنتجات')
            : 'كل المنتجات');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: _grid ? 'عرض قائمة' : 'عرض شبكة',
            onPressed: () => setState(() => _grid = !_grid),
            icon: Icon(
              _grid ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
            ),
          ),
          PopupMenuButton<_Sort>(
            tooltip: 'ترتيب',
            icon: const Icon(Icons.sort_rounded),
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => [
              for (final s in _Sort.values)
                PopupMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Icon(
                        s == _sort
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 18,
                        color: s == _sort
                            ? YecoColors.primary
                            : YecoColors.inkSoft,
                      ),
                      const SizedBox(width: 8),
                      Text(s.label),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              autofocus: widget.autofocusSearch,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج، ماركة...',
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
                if (widget.category == null) ...[
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
                ],
                FilterChip(
                  label: const Text('المتوفر فقط'),
                  selected: _inStockOnly,
                  onSelected: (v) => setState(() => _inStockOnly = v),
                  labelStyle: TextStyle(
                    color: _inStockOnly ? Colors.white : YecoColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Text(
                  '${items.length} منتج',
                  style: const TextStyle(
                    color: YecoColors.inkSoft,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  _sort.label,
                  style: const TextStyle(
                    color: YecoColors.inkSoft,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'لا توجد نتائج',
                    subtitle: 'جرّب كلمة أخرى أو غيّر التصنيف',
                  )
                : _grid
                ? GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.58,
                        ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => ProductCard(items[i]),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => ProductRow(items[i]),
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
