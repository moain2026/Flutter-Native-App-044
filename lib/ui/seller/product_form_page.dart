// ============================================================
// YECO - نموذج إضافة/تعديل منتج (بائع)
// تحقق كامل، صورة من المعرض/الكاميرا (تُنسخ إلى مجلد التطبيق) أو صورة افتراضية
// ============================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/store.dart';
import '../shared/widgets.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.product});
  final Product? product;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name ?? '');
  late final _brand = TextEditingController(text: widget.product?.brand ?? '');
  late final _desc = TextEditingController(
    text: widget.product?.description ?? '',
  );
  late final _price = TextEditingController(
    text: widget.product?.price.toStringAsFixed(0) ?? '',
  );
  late final _oldPrice = TextEditingController(
    text: widget.product?.oldPrice?.toStringAsFixed(0) ?? '',
  );
  late final _stock = TextEditingController(
    text: widget.product?.stock.toString() ?? '10',
  );
  late int? _catId = widget.product?.categoryId;
  late bool _featured = widget.product?.featured ?? false;
  late String _image = widget.product?.image ?? '';
  bool _busy = false;

  bool get _editing => widget.product != null;

  @override
  void dispose() {
    for (final c in [_name, _brand, _desc, _price, _oldPrice, _stock]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    try {
      final x = await ImagePicker().pickImage(
        source: src,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (x == null) return;
      final dir = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/product_images',
      );
      await dir.create(recursive: true);
      final dest =
          '${dir.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(x.path).copy(dest);
      if (mounted) setState(() => _image = dest);
    } catch (e) {
      if (mounted) notify(context, 'تعذّر اختيار الصورة: $e', error: true);
    }
  }

  void _chooseImage() {
    final store = AppScope.storeOf(context, listen: false);
    showModalBottomSheet<void>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('من المعرض'),
              onTap: () {
                Navigator.pop(c);
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('من الكاميرا'),
              onTap: () {
                Navigator.pop(c);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('صورة افتراضية من التصنيف'),
              subtitle: const Text('تُستخدم صورة التصنيف المختار'),
              onTap: () {
                Navigator.pop(c);
                final cat = _catId == null ? null : store.categoryOf(_catId!);
                setState(
                  () =>
                      _image = cat?.image ?? 'assets/categories/furniture.jpg',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_catId == null) {
      notify(context, 'اختر التصنيف', error: true);
      return;
    }
    final store = AppScope.storeOf(context, listen: false);
    final session = AppScope.sessionOf(context, listen: false);
    final price = double.parse(_price.text.trim());
    final old = _oldPrice.text.trim().isEmpty
        ? null
        : double.parse(_oldPrice.text.trim());
    final image = _image.isEmpty
        ? (store.categoryOf(_catId!)?.image ?? '')
        : _image;

    setState(() => _busy = true);
    try {
      if (_editing) {
        await store.updateProduct(
          widget.product!.copyWith(
            categoryId: _catId,
            name: _name.text.trim(),
            brand: _brand.text.trim(),
            description: _desc.text.trim(),
            price: price,
            oldPrice: old,
            clearOldPrice: old == null,
            stock: int.parse(_stock.text.trim()),
            image: image,
            featured: _featured,
          ),
        );
        if (!mounted) return;
        notify(context, 'تم تحديث المنتج');
      } else {
        await store.addProduct(
          Product(
            id: 0,
            categoryId: _catId!,
            sellerId: session.uid,
            name: _name.text.trim(),
            brand: _brand.text.trim(),
            description: _desc.text.trim(),
            price: price,
            oldPrice: old,
            stock: int.parse(_stock.text.trim()),
            rating: 0,
            ratingCount: 0,
            image: image,
            featured: _featured,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
        if (!mounted) return;
        notify(
          context,
          'تمت إضافة "${_name.text.trim()}" إلى المتجر',
          icon: Icons.add_box_outlined,
        );
      }
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      notify(context, 'تعذّر الحفظ: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.storeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'تعديل المنتج' : 'منتج جديد')),
      body: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---------------- الصورة
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _chooseImage,
                child: Stack(
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: YecoColors.line),
                        color: Colors.white,
                      ),
                      child: _image.isEmpty
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: YecoColors.inkSoft,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'صورة المنتج',
                                  style: TextStyle(
                                    color: YecoColors.inkSoft,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : ProductImage(_image, radius: 17),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: YecoColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // ---------------- التصنيف
            DropdownButtonFormField<int>(
              initialValue: _catId,
              isExpanded: true,
              validator: (v) => v == null ? 'اختر التصنيف' : null,
              decoration: const InputDecoration(
                labelText: 'التصنيف',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                for (final c in store.categories)
                  DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          categoryIcon(c.iconCode),
                          size: 18,
                          color: Color(c.colorValue),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _catId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              validator: (v) => V.minLen(v, 3, 'اسم المنتج'),
              decoration: const InputDecoration(
                labelText: 'اسم المنتج',
                prefixIcon: Icon(Icons.shopping_bag_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brand,
              validator: (v) => V.required(v, 'الماركة'),
              decoration: const InputDecoration(
                labelText: 'الماركة / الشركة',
                prefixIcon: Icon(Icons.sell_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textDirection: TextDirection.ltr,
                    validator: V.price,
                    decoration: const InputDecoration(
                      labelText: 'السعر (ر.س)',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _oldPrice,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textDirection: TextDirection.ltr,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final o = double.tryParse(v.trim());
                      final p = double.tryParse(_price.text.trim());
                      if (o == null) return 'رقم غير صحيح';
                      if (p != null && o <= p) {
                        return 'يجب أن يكون أكبر من السعر';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'قبل الخصم (اختياري)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stock,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              validator: (v) => V.intNonNegative(v, 'الكمية'),
              decoration: const InputDecoration(
                labelText: 'الكمية في المخزون',
                prefixIcon: Icon(Icons.inventory_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLines: 4,
              maxLength: 600,
              validator: (v) => V.minLen(v, 10, 'الوصف'),
              decoration: const InputDecoration(
                labelText: 'الوصف',
                alignLabelWithHint: true,
              ),
            ),
            SwitchListTile(
              value: _featured,
              onChanged: (v) => setState(() => _featured = v),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'منتج مميز',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'يظهر في قسم "منتجات مميزة" بالرئيسية',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _editing ? Icons.save_outlined : Icons.add_box_outlined,
                    ),
              label: Text(_editing ? 'حفظ التعديلات' : 'إضافة المنتج'),
            ),
          ],
        ),
      ),
    );
  }
}
