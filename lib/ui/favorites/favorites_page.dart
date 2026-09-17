// ============================================================
// YECO - المفضلة (زبون)
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/store.dart';
import '../catalog/product_card.dart';
import '../shared/widgets.dart';
import '../shell/shell.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.storeOf(context);
    final items = store.products.where((p) => store.isFavorite(p.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('المفضلة${items.isEmpty ? '' : ' (${items.length})'}'),
        actions: const [AccountButton()],
      ),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.favorite_outline_rounded,
              title: 'لا توجد منتجات مفضلة',
              subtitle: 'اضغط على ♥ في أي منتج ليظهر هنا',
              action: FilledButton.icon(
                onPressed: () =>
                    ShellController.maybeOf(context)?.go(ShellTab.home),
                style: FilledButton.styleFrom(minimumSize: const Size(180, 46)),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('تصفّح المنتجات'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _FavRow(items[i]),
            ),
    );
  }
}

class _FavRow extends StatelessWidget {
  const _FavRow(this.p);
  final Product p;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.storeOf(context, listen: false);
    return ProductRow(
      p,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'إزالة من المفضلة',
            onPressed: () async {
              await store.toggleFavorite(p);
              if (context.mounted) {
                notify(context, 'أُزيل "${p.name}" من المفضلة');
              }
            },
            icon: const Icon(Icons.favorite_rounded, color: YecoColors.danger),
          ),
          IconButton.filledTonal(
            visualDensity: VisualDensity.compact,
            tooltip: 'أضف إلى السلة',
            onPressed: p.inStock
                ? () async {
                    await store.addToCart(p);
                    if (context.mounted) {
                      notify(
                        context,
                        'أُضيف إلى السلة',
                        icon: Icons.add_shopping_cart_rounded,
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
