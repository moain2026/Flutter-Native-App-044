// ============================================================
// YECO - إتمام الطلب: عنوان/هاتف (Form)، طريقة الدفع، ملخص، تأكيد → طلب في SQLite
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/repos.dart';
import '../../models/models.dart';
import '../../state/store.dart';
import '../orders/order_detail_page.dart';
import '../shared/widgets.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.user, this.coupon});
  final AppUser user;
  final Coupon? coupon;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _form = GlobalKey<FormState>();
  late final _address = TextEditingController(
    text: widget.user.city.isEmpty ? '' : '${widget.user.city}، ',
  );
  late final _phone = TextEditingController(text: widget.user.phone);
  String _payment = 'cash';
  bool _busy = false;

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _place() async {
    if (!_form.currentState!.validate()) return;
    final store = AppScope.storeOf(context, listen: false);
    if (store.cart.isEmpty) return;
    final ok = await confirm(
      context,
      title: 'تأكيد الطلب',
      message:
          'سيتم إرسال طلبك بقيمة ${fmtMoney(_total(store))} والدفع ${_payment == 'cash' ? 'عند الاستلام' : 'بالبطاقة'}.',
      okLabel: 'تأكيد الطلب',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final order = await const OrderRepo().checkout(
        user: widget.user,
        lines: store.cart,
        address: _address.text,
        phone: _phone.text,
        payment: _payment,
        coupon: widget.coupon,
      );
      await store.refreshCatalog();
      if (!mounted) return;
      notify(
        context,
        'تم إرسال طلبك رقم #${order.id} بنجاح 🎉',
        icon: Icons.check_circle_rounded,
      );
      Navigator.pop(context, true);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.id)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      notify(context, 'تعذّر إتمام الطلب: $e', error: true);
    }
  }

  double _total(Store store) {
    final sub = store.cartSubtotal;
    final c = widget.coupon;
    final disc = (c != null && sub >= c.minSubtotal)
        ? sub * c.percent / 100
        : 0.0;
    final del = sub >= OrderRepo.freeDeliveryFrom ? 0.0 : OrderRepo.deliveryFee;
    return sub - disc + del;
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.storeOf(context);
    final sub = store.cartSubtotal;
    final c = widget.coupon;
    final disc = (c != null && sub >= c.minSubtotal)
        ? sub * c.percent / 100
        : 0.0;
    final del = sub >= OrderRepo.freeDeliveryFrom ? 0.0 : OrderRepo.deliveryFee;

    return Scaffold(
      appBar: AppBar(title: const Text('إتمام الطلب')),
      body: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeader('بيانات التوصيل'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: widget.user.name,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'اسم المستلم',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      validator: V.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم الجوال',
                        prefixIcon: Icon(Icons.phone_android_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address,
                      maxLines: 2,
                      validator: (v) => V.minLen(v, 8, 'العنوان'),
                      decoration: const InputDecoration(
                        labelText: 'العنوان التفصيلي',
                        hintText: 'المدينة، الحي، الشارع، رقم المنزل',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SectionHeader('طريقة الدفع'),
            Card(
              child: RadioGroup<String>(
                groupValue: _payment,
                onChanged: (v) => setState(() => _payment = v ?? 'cash'),
                child: const Column(
                  children: [
                    RadioListTile<String>(
                      value: 'cash',
                      title: Text('الدفع عند الاستلام'),
                      subtitle: Text('نقداً أو بالشبكة لمندوب التوصيل'),
                      secondary: Icon(Icons.payments_outlined),
                    ),
                    Divider(indent: 16, endIndent: 16),
                    RadioListTile<String>(
                      value: 'card',
                      title: Text('بطاقة ائتمانية (محاكاة)'),
                      subtitle: Text('لن يتم خصم أي مبلغ فعلي'),
                      secondary: Icon(Icons.credit_card_rounded),
                    ),
                  ],
                ),
              ),
            ),
            const SectionHeader('ملخص الطلب'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    for (final l in store.cart)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: ProductImage(l.product.image, radius: 8),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${l.product.name} × ${l.qty}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              fmtMoney(l.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Divider(),
                    _row('المجموع الفرعي', fmtMoney(sub)),
                    if (disc > 0)
                      _row(
                        'الخصم (${c!.code})',
                        '- ${fmtMoney(disc)}',
                        color: YecoColors.success,
                      ),
                    _row(
                      'التوصيل',
                      del == 0 ? 'مجاني' : fmtMoney(del),
                      color: del == 0 ? YecoColors.success : null,
                    ),
                    const Divider(),
                    _row('الإجمالي', fmtMoney(sub - disc + del), bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy || store.cart.isEmpty ? null : _place,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: const Text('تأكيد الطلب'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text(
          k,
          style: TextStyle(
            color: bold ? YecoColors.ink : YecoColors.inkSoft,
            fontWeight: bold ? FontWeight.w800 : null,
          ),
        ),
        const Spacer(),
        Text(
          v,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: bold ? 17 : 14,
            color: color ?? (bold ? YecoColors.primaryDark : YecoColors.ink),
          ),
        ),
      ],
    ),
  );
}
