// ============================================================
// YECO - طلباتي (زبون) / كل الطلبات (بائع) مع تصفية بالحالة
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/repos.dart';
import '../../models/models.dart';
import '../../state/store.dart';
import '../shared/widgets.dart';
import 'order_detail_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, this.sellerView = false});
  final bool sellerView;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Order> _orders = const [];
  bool _loading = true;
  OrderStatus? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final uid = AppScope.sessionOf(context, listen: false).uid;
    final r = widget.sellerView
        ? await const OrderRepo().all(status: _filter)
        : await const OrderRepo().forUser(uid);
    if (!mounted) return;
    setState(() {
      _orders = widget.sellerView || _filter == null
          ? r
          : r.where((o) => o.status == _filter).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sellerView ? 'إدارة الطلبات' : 'طلباتي'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip('الكل', null),
                for (final s in OrderStatus.values) _chip(s.label, s),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: _filter == null
                        ? 'لا توجد طلبات بعد'
                        : 'لا توجد طلبات "${_filter!.label}"',
                    subtitle: widget.sellerView
                        ? 'ستظهر طلبات الزبائن هنا'
                        : 'أتمم طلبك الأول من السلة',
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _OrderTile(
                        _orders[i],
                        sellerView: widget.sellerView,
                        onChanged: _load,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, OrderStatus? s) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _filter == s,
      onSelected: (_) {
        setState(() => _filter = s);
        _load();
      },
      labelStyle: TextStyle(
        color: _filter == s ? Colors.white : YecoColors.ink,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _OrderTile extends StatelessWidget {
  const _OrderTile(this.o, {required this.sellerView, required this.onChanged});
  final Order o;
  final bool sellerView;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(o.status);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OrderDetailPage(orderId: o.id, sellerView: sellerView),
            ),
          );
          onChanged();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon(o.status), color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلب #${o.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          sellerView
                              ? '${o.customerName} · ${fmtDate(o.createdAt)}'
                              : fmtDate(o.createdAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: YecoColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Pill(o.status.label, color: color),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: o.lines.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (_, i) => SizedBox(
                          width: 44,
                          child: ProductImage(o.lines[i].image, radius: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          fmtMoney(o.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: YecoColors.primaryDark,
                          ),
                        ),
                        Text(
                          '${o.itemCount} قطعة',
                          style: const TextStyle(
                            fontSize: 11,
                            color: YecoColors.inkSoft,
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
}
