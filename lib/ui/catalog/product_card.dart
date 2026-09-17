// ============================================================
// YECO - بطاقة المنتج (شبكة/قائمة أفقية) + بطاقة صف
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/store.dart';
import '../shared/widgets.dart';
import 'product_detail_page.dart';

void openProduct(BuildContext context, Product p) => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => ProductDetailPage(productId: p.id)),
);

class ProductCard extends StatelessWidget {
  const ProductCard(this.product, {super.key, this.width});
  final Product product;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.storeOf(context);
    final session = AppScope.sessionOf(context, listen: false);
    final fav = store.isFavorite(product.id);
    final p = product;

    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openProduct(context, p),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1.25,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImage(p.image, radius: 0, heroTag: 'p${p.id}'),
                    if (p.hasDiscount)
                      PositionedDirectional(
                        top: 8,
                        start: 8,
                        child: DiscountBadge(p.discountPercent),
                      ),
                    if (!p.inStock)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.55),
                          alignment: Alignment.center,
                          child: const Pill(
                            'نفدت الكمية',
                            color: YecoColors.danger,
                          ),
                        ),
                      ),
                    if (!session.isSeller)
                      PositionedDirectional(
                        top: 4,
                        end: 4,
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.9,
                            ),
                          ),
                          onPressed: () async {
                            final added = await store.toggleFavorite(p);
                            if (context.mounted) {
                              notify(
                                context,
                                added
                                    ? 'أُضيف إلى المفضلة'
                                    : 'أُزيل من المفضلة',
                                icon: added
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_outline_rounded,
                              );
                            }
                          },
                          icon: Icon(
                            fav
                                ? Icons.favorite_rounded
                                : Icons.favorite_outline_rounded,
                            color: fav ? YecoColors.danger : YecoColors.inkSoft,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        p.brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: YecoColors.inkSoft,
                        ),
                      ),
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: YecoColors.accent,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            p.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '(${p.ratingCount})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: YecoColors.inkSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: PriceText(p, size: 14)),
                          if (!session.isSeller)
                            SizedBox(
                              width: 34,
                              height: 34,
                              child: IconButton.filled(
                                padding: EdgeInsets.zero,
                                onPressed: p.inStock
                                    ? () async {
                                        await store.addToCart(p);
                                        if (context.mounted) {
                                          notify(
                                            context,
                                            'أُضيف "${p.name}" إلى السلة',
                                            icon:
                                                Icons.add_shopping_cart_rounded,
                                          );
                                        }
                                      }
                                    : null,
                                icon: const Icon(Icons.add_rounded, size: 20),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// صف منتج أفقي (للقوائم الطويلة والمفضلة)
class ProductRow extends StatelessWidget {
  const ProductRow(this.product, {super.key, this.trailing, this.onTap});
  final Product product;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ?? () => openProduct(context, p),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: ProductImage(p.image, heroTag: 'p${p.id}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.brand,
                      style: const TextStyle(
                        fontSize: 11,
                        color: YecoColors.inkSoft,
                      ),
                    ),
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(child: PriceText(p, size: 14)),
                        if (p.hasDiscount) DiscountBadge(p.discountPercent),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 6), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
