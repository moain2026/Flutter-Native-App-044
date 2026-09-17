// ============================================================
// YECO - تفاصيل المنتج: صورة Hero، سعر/خصم/مخزون، وصف، مراجعات (CRUD)،
// إضافة إلى السلة بكمية، "اشترِ الآن" → السلة. للبائع: تعديل/حذف.
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/repos.dart';
import '../../models/models.dart';
import '../../state/store.dart';
import '../seller/product_form_page.dart';
import '../shared/widgets.dart';
import '../shell/shell.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.productId});
  final int productId;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _qty = 1;
  List<Review> _reviews = const [];
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final r = await const ReviewRepo().forProduct(widget.productId);
    if (!mounted) return;
    setState(() {
      _reviews = r;
      _loadingReviews = false;
    });
  }

  Future<void> _addToCart(Store store, Product p) async {
    await store.addToCart(p, qty: _qty);
    if (!mounted) return;
    notify(
      context,
      'أُضيف $_qty × "${p.name}" إلى السلة',
      icon: Icons.add_shopping_cart_rounded,
    );
  }

  Future<void> _buyNow(Store store, Product p) async {
    if (!store.inCart(p.id)) await store.addToCart(p, qty: _qty);
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    ShellController.maybeOf(context)?.go(ShellTab.cart);
  }

  Future<void> _writeReview(AppUser user, Product p) async {
    final mine = _reviews.where((r) => r.userId == user.id).firstOrNull;
    final result = await showModalBottomSheet<(int, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReviewSheet(
        initialStars: mine?.stars ?? 5,
        initialText: mine?.comment ?? '',
      ),
    );
    if (result == null) return;
    await const ReviewRepo().upsert(
      productId: p.id,
      user: user,
      stars: result.$1,
      comment: result.$2,
    );
    if (!mounted) return;
    await AppScope.storeOf(context, listen: false).refreshCatalog();
    await _loadReviews();
    if (mounted) {
      notify(
        context,
        mine == null ? 'شكراً! أُضيفت مراجعتك' : 'تم تحديث مراجعتك',
      );
    }
  }

  Future<void> _deleteReview(Review r) async {
    final ok = await confirm(
      context,
      title: 'حذف المراجعة',
      message: 'هل تريد حذف مراجعتك لهذا المنتج؟',
      okLabel: 'حذف',
      danger: true,
    );
    if (!ok) return;
    await const ReviewRepo().delete(r.id);
    if (!mounted) return;
    await AppScope.storeOf(context, listen: false).refreshCatalog();
    await _loadReviews();
    if (mounted) notify(context, 'تم حذف المراجعة');
  }

  Future<void> _deleteProduct(Store store, Product p) async {
    final ok = await confirm(
      context,
      title: 'حذف المنتج',
      message: 'سيُحذف "${p.name}" نهائياً من المتجر. هل أنت متأكد؟',
      okLabel: 'حذف',
      danger: true,
    );
    if (!ok) return;
    await store.deleteProduct(p.id);
    if (!mounted) return;
    notify(context, 'تم حذف المنتج', icon: Icons.delete_outline_rounded);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.storeOf(context);
    final session = AppScope.sessionOf(context);
    final p = store.productOf(widget.productId);
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'هذا المنتج لم يعد متاحاً',
        ),
      );
    }
    final cat = store.categoryOf(p.categoryId);
    final fav = store.isFavorite(p.id);
    final seller = session.isSeller;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.white,
            leading: _circleBtn(
              context,
              Icons.arrow_back_rounded,
              () => Navigator.pop(context),
            ),
            actions: [
              if (seller) ...[
                _circleBtn(
                  context,
                  Icons.edit_outlined,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductFormPage(product: p),
                    ),
                  ),
                ),
                _circleBtn(
                  context,
                  Icons.delete_outline_rounded,
                  () => _deleteProduct(store, p),
                  color: YecoColors.danger,
                ),
              ] else
                _circleBtn(
                  context,
                  fav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  () async {
                    final added = await store.toggleFavorite(p);
                    if (context.mounted) {
                      notify(
                        context,
                        added ? 'أُضيف إلى المفضلة' : 'أُزيل من المفضلة',
                      );
                    }
                  },
                  color: fav ? YecoColors.danger : null,
                ),
              const SizedBox(width: 6),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFFF0F2F0),
                padding: const EdgeInsets.fromLTRB(24, 90, 24, 24),
                child: ProductImage(
                  p.image,
                  fit: BoxFit.contain,
                  heroTag: 'p${p.id}',
                  radius: 20,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: YecoColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (cat != null)
                        Pill(
                          cat.name,
                          color: Color(cat.colorValue),
                          icon: categoryIcon(cat.iconCode),
                        ),
                      Pill(
                        p.brand,
                        color: YecoColors.inkSoft,
                        icon: Icons.sell_outlined,
                      ),
                      if (p.featured)
                        const Pill(
                          'مميز',
                          color: YecoColors.accent,
                          icon: Icons.star_rounded,
                        ),
                      p.inStock
                          ? Pill(
                              'متوفر · ${p.stock}',
                              color: YecoColors.success,
                              icon: Icons.check_circle_outline,
                            )
                          : const Pill(
                              'نفدت الكمية',
                              color: YecoColors.danger,
                              icon: Icons.remove_circle_outline,
                            ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Stars(p.rating, size: 18, count: p.ratingCount),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: PriceText(p, size: 24)),
                      if (p.hasDiscount) DiscountBadge(p.discountPercent),
                    ],
                  ),
                  const Divider(height: 28),
                  const Text(
                    'الوصف',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.description,
                    style: const TextStyle(
                      height: 1.7,
                      color: Color(0xFF3A4652),
                    ),
                  ),
                  const Divider(height: 28),
                  _specs(p, cat),
                  const Divider(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'المراجعات (${_reviews.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!seller && session.user != null)
                        TextButton.icon(
                          onPressed: () => _writeReview(session.user!, p),
                          icon: const Icon(
                            Icons.rate_review_outlined,
                            size: 18,
                          ),
                          label: Text(
                            _reviews.any((r) => r.userId == session.uid)
                                ? 'تعديل مراجعتي'
                                : 'أضف مراجعة',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_loadingReviews)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_reviews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'لا توجد مراجعات بعد — كن أول من يقيّم هذا المنتج.',
                        style: TextStyle(color: YecoColors.inkSoft),
                      ),
                    )
                  else
                    for (final r in _reviews)
                      _reviewTile(r, mine: r.userId == session.uid),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: seller
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: YecoColors.line)),
                ),
                child: Row(
                  children: [
                    _QtyStepper(
                      value: _qty,
                      max: p.stock,
                      onChanged: (v) => setState(() => _qty = v),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: p.inStock
                            ? () => _addToCart(store, p)
                            : null,
                        icon: const Icon(
                          Icons.add_shopping_cart_rounded,
                          size: 20,
                        ),
                        label: const Text('أضف'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: p.inStock ? () => _buyNow(store, p) : null,
                        child: const Text('اشترِ الآن'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _specs(Product p, Category? cat) {
    final rows = <(IconData, String, String)>[
      (Icons.category_outlined, 'التصنيف', cat?.name ?? '—'),
      (Icons.sell_outlined, 'الماركة', p.brand),
      (Icons.inventory_outlined, 'المخزون', '${p.stock} قطعة'),
      (Icons.tag_rounded, 'رقم المنتج', '#${p.id.toString().padLeft(4, '0')}'),
      (Icons.calendar_today_outlined, 'أُضيف في', fmtShortDate(p.createdAt)),
    ];
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            ListTile(
              dense: true,
              leading: Icon(rows[i].$1, size: 20),
              title: Text(
                rows[i].$2,
                style: const TextStyle(color: YecoColors.inkSoft, fontSize: 13),
              ),
              trailing: Text(
                rows[i].$3,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            if (i < rows.length - 1) const Divider(indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }

  Widget _reviewTile(Review r, {required bool mine}) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: YecoColors.primaryLight,
                child: Text(
                  r.userName.characters.firstOrNull ?? '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: YecoColors.primaryDark,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      fmtShortDate(r.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: YecoColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Stars(r.stars.toDouble(), size: 14),
              if (mine)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _deleteReview(r),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: YecoColors.danger,
                  ),
                ),
            ],
          ),
          if (r.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r.comment,
              style: const TextStyle(height: 1.5, fontSize: 13.5),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _circleBtn(
    BuildContext c,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
    child: Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: YecoColors.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 21, color: color ?? YecoColors.ink),
        ),
      ),
    ),
  );
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.value,
    required this.max,
    required this.onChanged,
  });
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    decoration: BoxDecoration(
      border: Border.all(color: YecoColors.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_rounded),
        ),
        SizedBox(
          width: 24,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    ),
  );
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.initialStars, required this.initialText});
  final int initialStars;
  final String initialText;
  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late int _stars = widget.initialStars;
  late final _text = TextEditingController(text: widget.initialText);
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'قيّم هذا المنتج',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Center(
            child: Stars(
              _stars.toDouble(),
              size: 38,
              onTap: (v) => setState(() => _stars = v),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _text,
            maxLines: 3,
            maxLength: 300,
            validator: (v) => V.minLen(v, 5, 'التعليق'),
            decoration: const InputDecoration(
              labelText: 'تعليقك',
              hintText: 'ما رأيك في المنتج؟',
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {
              if (_form.currentState!.validate()) {
                Navigator.pop(context, (_stars, _text.text));
              }
            },
            icon: const Icon(Icons.send_rounded),
            label: const Text('نشر المراجعة'),
          ),
        ],
      ),
    ),
  );
}
