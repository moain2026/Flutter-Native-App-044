// ============================================================
// YECO - تفاصيل الطلب: خط زمني للحالة، المنتجات، الفاتورة، العنوان
// زبون: إلغاء (قيد المراجعة/مؤكد) · بائع: تغيير الحالة + حذف
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/repos.dart';
import '../../models/models.dart';
import '../../state/store.dart';
import '../shared/widgets.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.orderId,
    this.sellerView = false,
  });
  final int orderId;
  final bool sellerView;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Order? _o;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final o = await const OrderRepo().byId(widget.orderId);
    if (!mounted) return;
    setState(() {
      _o = o;
      _loading = false;
    });
  }

  Future<void> _cancel() async {
    final ok = await confirm(
      context,
      title: 'إلغاء الطلب',
      message: 'سيُلغى الطلب #${_o!.id} وتُعاد الكميات إلى المخزون.',
      okLabel: 'إلغاء الطلب',
      danger: true,
    );
    if (!ok) return;
    await const OrderRepo().cancel(_o!.id);
    if (!mounted) return;
    await AppScope.storeOf(context, listen: false).refreshCatalog();
    await _load();
    if (mounted) notify(context, 'تم إلغاء الطلب', icon: Icons.cancel_outlined);
  }

  Future<void> _setStatus(OrderStatus s) async {
    if (s == OrderStatus.cancelled) {
      await const OrderRepo().cancel(_o!.id);
      if (mounted) {
        await AppScope.storeOf(context, listen: false).refreshCatalog();
      }
    } else {
      await const OrderRepo().setStatus(_o!.id, s);
    }
    await _load();
    if (mounted) notify(context, 'حالة الطلب الآن: ${s.label}');
  }

  Future<void> _delete() async {
    final ok = await confirm(
      context,
      title: 'حذف الطلب',
      message: 'سيُحذف الطلب #${_o!.id} نهائياً من السجل.',
      okLabel: 'حذف',
      danger: true,
    );
    if (!ok) return;
    await const OrderRepo().delete(_o!.id);
    if (!mounted) return;
    notify(context, 'تم حذف الطلب');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final o = _o;
    if (o == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'الطلب غير موجود',
        ),
      );
    }
    final color = statusColor(o.status);
    return Scaffold(
      appBar: AppBar(
        title: Text('طلب #${o.id}'),
        actions: [
          if (widget.sellerView)
            IconButton(
              tooltip: 'حذف',
              onPressed: _delete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: YecoColors.danger,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------------- الحالة
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(statusIcon(o.status), color: color, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.status.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: color,
                              ),
                            ),
                            Text(
                              fmtDate(o.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: YecoColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (o.status != OrderStatus.cancelled) ...[
                    const SizedBox(height: 16),
                    _Timeline(o.status),
                  ],
                ],
              ),
            ),
          ),
          // ---------------- تحكّم البائع
          if (widget.sellerView) ...[
            const SectionHeader('تغيير الحالة'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in OrderStatus.values)
                  ChoiceChip(
                    label: Text(s.label),
                    avatar: Icon(
                      statusIcon(s),
                      size: 16,
                      color: o.status == s ? Colors.white : statusColor(s),
                    ),
                    selected: o.status == s,
                    selectedColor: statusColor(s),
                    onSelected:
                        o.status == s || o.status == OrderStatus.cancelled
                        ? null
                        : (_) => _setStatus(s),
                    labelStyle: TextStyle(
                      color: o.status == s ? Colors.white : YecoColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
          // ---------------- المنتجات
          SectionHeader('المنتجات (${o.itemCount})'),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < o.lines.length; i++) ...[
                  ListTile(
                    leading: SizedBox(
                      width: 48,
                      height: 48,
                      child: ProductImage(o.lines[i].image, radius: 10),
                    ),
                    title: Text(
                      o.lines[i].name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${fmtMoney(o.lines[i].price)} × ${o.lines[i].qty}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      fmtMoney(o.lines[i].total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: YecoColors.primaryDark,
                      ),
                    ),
                  ),
                  if (i < o.lines.length - 1)
                    const Divider(indent: 16, endIndent: 16),
                ],
              ],
            ),
          ),
          // ---------------- الفاتورة
          const SectionHeader('الفاتورة'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _row('المجموع الفرعي', fmtMoney(o.subtotal)),
                  if (o.discount > 0)
                    _row(
                      'الخصم',
                      '- ${fmtMoney(o.discount)}',
                      color: YecoColors.success,
                    ),
                  _row(
                    'التوصيل',
                    o.delivery == 0 ? 'مجاني' : fmtMoney(o.delivery),
                  ),
                  _row(
                    'طريقة الدفع',
                    o.payment == 'cash' ? 'عند الاستلام' : 'بطاقة',
                  ),
                  const Divider(),
                  _row('الإجمالي', fmtMoney(o.total), bold: true),
                ],
              ),
            ),
          ),
          // ---------------- التوصيل
          const SectionHeader('بيانات التوصيل'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(o.customerName),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.phone_android_rounded),
                  title: Text(
                    o.phone,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(o.address),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!widget.sellerView && o.canCancel)
            OutlinedButton.icon(
              onPressed: _cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: YecoColors.danger,
                side: const BorderSide(color: YecoColors.danger),
              ),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('إلغاء الطلب'),
            ),
        ],
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
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

/// خط زمني أفقي: قيد المراجعة → مؤكد → جارٍ التوصيل → تم التسليم
class _Timeline extends StatelessWidget {
  const _Timeline(this.status);
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    const steps = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.shipped,
      OrderStatus.delivered,
    ];
    final idx = steps.indexOf(status);
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= idx ? YecoColors.primary : YecoColors.line,
                  ),
                  child: Icon(
                    i < idx ? Icons.check_rounded : statusIcon(steps[i]),
                    size: 15,
                    color: i <= idx ? Colors.white : YecoColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[i].label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: i == idx ? FontWeight.w800 : FontWeight.w500,
                    color: i <= idx
                        ? YecoColors.primaryDark
                        : YecoColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          if (i < steps.length - 1)
            Container(
              width: 18,
              height: 3,
              margin: const EdgeInsets.only(bottom: 26),
              color: i < idx ? YecoColors.primary : YecoColors.line,
            ),
        ],
      ],
    );
  }
}
