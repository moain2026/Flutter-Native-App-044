// ============================================================
// YECO - السلة: تعديل الكميات، حذف بالسحب (Dismissible)، كوبون، ملخص، إتمام
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/repos.dart';
import '../../models/models.dart';
import '../../state/store.dart';
import '../catalog/product_card.dart';
import '../shared/widgets.dart';
import '../shell/shell.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _coupon = TextEditingController();
  Coupon? _applied;

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  void _applyCoupon(double subtotal) {
    final c = Coupon.find(_coupon.text);
    if (c == null) {
      notify(context, 'كود الكوبون غير صحيح', error: true);
      return;
    }
    if (subtotal < c.minSubtotal) {
      notify(
        context,
        'هذا الكوبون يتطلب طلباً بقيمة ${fmtMoney(c.minSubtotal)} على الأقل',
        error: true,
      );
      return;
    }
    setState(() => _applied = c);
    notify(
      context,
      'تم تطبيق خصم ${c.percent}%',
      icon: Icons.local_offer_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.storeOf(context);
    final session = AppScope.sessionOf(context);
    final lines = store.cart;
    final subtotal = store.cartSubtotal;
    final coupon = (_applied != null && subtotal >= _applied!.minSubtotal)
        ? _applied
        : null;
    final discount = coupon == null ? 0.0 : subtotal * coupon.percent / 100;
    final delivery = lines.isEmpty || subtotal >= OrderRepo.freeDeliveryFrom
        ? 0.0
        : OrderRepo.deliveryFee;
    final total = subtotal - discount + delivery;

    return Scaffold(
      appBar: AppBar(
        title: Text('السلة${lines.isEmpty ? '' : ' (${store.cartCount})'}'),
        actions: [
          if (lines.isNotEmpty)
            IconButton(
              tooltip: 'تفريغ السلة',
              onPressed: () async {
                final ok = await confirm(
                  context,
                  title: 'تفريغ السلة',
                  message: 'سيتم حذف كل المنتجات من سلتك.',
                  okLabel: 'تفريغ',
                  danger: true,
                );
                if (ok) {
                  await store.clearCart();
                  if (context.mounted) notify(context, 'تم تفريغ السلة');
                }
              },
              icon: const Icon(Icons.remove_shopping_cart_outlined),
            ),
          const AccountButton(),
        ],
      ),
      body: lines.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'سلتك فارغة',
              subtitle: 'أضف منتجات من الرئيسية أو التصنيفات لتظهر هنا',
              action: FilledButton.icon(
                onPressed: () =>
                    ShellController.maybeOf(context)?.go(ShellTab.home),
                style: FilledButton.styleFrom(minimumSize: const Size(180, 46)),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('تصفّح المنتجات'),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: lines.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i == lines.length) {
                        return _couponBox(subtotal, coupon);
                      }
                      final l = lines[i];
                      return Dismissible(
                        key: ValueKey('cart-${l.id}'),
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
                          title: 'حذف من السلة',
                          message: 'إزالة "${l.product.name}" من السلة؟',
                          okLabel: 'إزالة',
                          danger: true,
                        ),
                        onDismissed: (_) async {
                          await store.removeLine(l);
                          if (context.mounted) {
                            notify(
                              context,
                              'أُزيل "${l.product.name}" من السلة',
                            );
                          }
                        },
                        child: _CartTile(l),
                      );
                    },
                  ),
                ),
                _summary(
                  context,
                  subtotal: subtotal,
                  discount: discount,
                  delivery: delivery,
                  total: total,
                  onCheckout: () async {
                    final placed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CheckoutPage(user: session.user!, coupon: coupon),
                      ),
                    );
                    if (placed == true && mounted) {
                      setState(() {
                        _applied = null;
                        _coupon.clear();
                      });
                    }
                  },
                ),
              ],
            ),
    );
  }

  Widget _couponBox(double subtotal, Coupon? active) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 18,
                color: YecoColors.primaryDark,
              ),
              SizedBox(width: 6),
              Text('كوبون خصم', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          if (active != null)
            Row(
              children: [
                Expanded(
                  child: Pill(
                    '${active.code} — خصم ${active.percent}%',
                    color: YecoColors.success,
                    icon: Icons.check_rounded,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _applied = null;
                    _coupon.clear();
                  }),
                  child: const Text('إزالة'),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _coupon,
                    textCapitalization: TextCapitalization.characters,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      hintText: 'YECO10 · WELCOME · BIG25',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _applyCoupon(subtotal),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(80, 48),
                  ),
                  onPressed: () => _applyCoupon(subtotal),
                  child: const Text('تطبيق'),
                ),
              ],
            ),
        ],
      ),
    ),
  );

  Widget _summary(
    BuildContext context, {
    required double subtotal,
    required double discount,
    required double delivery,
    required double total,
    required VoidCallback onCheckout,
  }) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: YecoColors.line)),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row('المجموع الفرعي', fmtMoney(subtotal)),
          if (discount > 0)
            _row('الخصم', '- ${fmtMoney(discount)}', color: YecoColors.success),
          _row(
            'التوصيل',
            delivery == 0 ? 'مجاني' : fmtMoney(delivery),
            color: delivery == 0 ? YecoColors.success : null,
          ),
          const Divider(height: 14),
          _row('الإجمالي', fmtMoney(total), bold: true),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onCheckout,
            icon: const Icon(Icons.payments_outlined),
            label: const Text('إتمام الطلب'),
          ),
        ],
      ),
    ),
  );

  Widget _row(String k, String v, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text(
          k,
          style: TextStyle(
            color: bold ? YecoColors.ink : YecoColors.inkSoft,
            fontWeight: bold ? FontWeight.w800 : null,
            fontSize: bold ? 16 : 14,
          ),
        ),
        const Spacer(),
        Text(
          v,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: bold ? 18 : 14,
            color: color ?? (bold ? YecoColors.primaryDark : YecoColors.ink),
          ),
        ),
      ],
    ),
  );
}

class _CartTile extends StatelessWidget {
  const _CartTile(this.line);
  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.storeOf(context, listen: false);
    final p = line.product;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openProduct(context, p),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 74,
                height: 74,
                child: ProductImage(p.image, heroTag: 'p${p.id}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(
                      '${fmtMoney(p.price)} × ${line.qty}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: YecoColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            fmtMoney(line.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: YecoColors.primaryDark,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        _miniBtn(
                          Icons.remove_rounded,
                          () => store.setQty(line, line.qty - 1),
                        ),
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${line.qty}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        _miniBtn(
                          Icons.add_rounded,
                          line.qty < p.stock
                              ? () => store.setQty(line, line.qty + 1)
                              : () => notify(
                                  context,
                                  'لا يوجد مخزون إضافي لهذا المنتج',
                                  error: true,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap) => Material(
    color: YecoColors.primaryLight,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: SizedBox(
        width: 30,
        height: 30,
        child: Icon(icon, size: 18, color: YecoColors.primaryDark),
      ),
    ),
  );
}
