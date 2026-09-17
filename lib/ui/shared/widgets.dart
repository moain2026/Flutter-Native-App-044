// ============================================================
// YECO - عناصر مشتركة: صورة المنتج، السعر، النجوم، الشارات،
// SnackBar/Dialog موحّدة، مُدقّقات النماذج، تنسيق المبالغ
// ============================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/models.dart';

// ------------------------------------------------------------ تنسيق
final _money = NumberFormat('#,##0.##', 'en');
String fmtMoney(double v) => '${_money.format(v)} ر.س';
String fmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return DateFormat('yyyy/MM/dd — HH:mm', 'en').format(d);
}

String fmtShortDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return DateFormat('d MMM yyyy', 'ar').format(d);
}

// ------------------------------------------------------------ أيقونات التصنيفات
IconData categoryIcon(int code) => switch (code) {
  1 => Icons.shopping_basket_rounded,
  2 => Icons.devices_rounded,
  3 => Icons.checkroom_rounded,
  4 => Icons.kitchen_rounded,
  5 => Icons.sports_soccer_rounded,
  _ => Icons.chair_rounded,
};

// ------------------------------------------------------------ صورة المنتج
class ProductImage extends StatelessWidget {
  const ProductImage(
    this.path, {
    super.key,
    this.fit = BoxFit.cover,
    this.radius = 14,
    this.heroTag,
  });
  final String path;
  final BoxFit fit;
  final double radius;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    Widget img;
    if (path.isEmpty) {
      img = _placeholder();
    } else if (path.startsWith('assets/')) {
      img = Image.asset(
        path,
        fit: fit,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    } else {
      img = Image.file(
        File(path),
        fit: fit,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    img = ClipRRect(borderRadius: BorderRadius.circular(radius), child: img);
    return heroTag == null ? img : Hero(tag: heroTag!, child: img);
  }

  Widget _placeholder() => Container(
    color: YecoColors.primaryLight,
    alignment: Alignment.center,
    child: const Icon(
      Icons.image_outlined,
      color: YecoColors.primaryDark,
      size: 36,
    ),
  );
}

// ------------------------------------------------------------ السعر
class PriceText extends StatelessWidget {
  const PriceText(
    this.product, {
    super.key,
    this.size = 16,
    this.showOld = true,
  });
  final Product product;
  final double size;
  final bool showOld;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 6,
      children: [
        Text(
          fmtMoney(product.price),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: YecoColors.primaryDark,
          ),
        ),
        if (showOld && product.hasDiscount)
          Text(
            fmtMoney(product.oldPrice!),
            style: TextStyle(
              fontSize: size * 0.75,
              color: YecoColors.inkSoft,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }
}

class DiscountBadge extends StatelessWidget {
  const DiscountBadge(this.percent, {super.key});
  final int percent;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: YecoColors.accent,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '-$percent%',
      style: const TextStyle(
        color: YecoColors.ink,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
    ),
  );
}

// ------------------------------------------------------------ النجوم
class Stars extends StatelessWidget {
  const Stars(this.value, {super.key, this.size = 14, this.count, this.onTap});
  final double value;
  final double size;
  final int? count;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: onTap == null ? null : () => onTap!(i),
            child: Icon(
              i <= value.round()
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: size,
              color: YecoColors.accent,
            ),
          ),
        if (count != null) ...[
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${value.toStringAsFixed(1)} ($count)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: size * 0.85,
                color: YecoColors.inkSoft,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------ شارة صغيرة
class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.color = YecoColors.primary,
    this.icon,
  });
  final String text;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}

Color statusColor(OrderStatus s) => switch (s) {
  OrderStatus.pending => YecoColors.accent,
  OrderStatus.confirmed => YecoColors.info,
  OrderStatus.shipped => const Color(0xFF8E24AA),
  OrderStatus.delivered => YecoColors.success,
  OrderStatus.cancelled => YecoColors.danger,
};

IconData statusIcon(OrderStatus s) => switch (s) {
  OrderStatus.pending => Icons.hourglass_top_rounded,
  OrderStatus.confirmed => Icons.check_circle_outline_rounded,
  OrderStatus.shipped => Icons.local_shipping_outlined,
  OrderStatus.delivered => Icons.inventory_2_outlined,
  OrderStatus.cancelled => Icons.cancel_outlined,
};

// ------------------------------------------------------------ عنوان قسم
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: YecoColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

// ------------------------------------------------------------ حالة فارغة
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: YecoColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 42, color: YecoColors.primaryDark),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: YecoColors.inkSoft),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    ),
  );
}

// ------------------------------------------------------------ بطاقة إحصاء
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = YecoColors.primary,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  label,
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
        ],
      ),
    ),
  );
}

// ------------------------------------------------------------ تفاعل
void notify(
  BuildContext context,
  String msg, {
  bool error = false,
  IconData? icon,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: error ? YecoColors.danger : YecoColors.ink,
        content: Row(
          children: [
            Icon(
              icon ??
                  (error
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
      ),
    );
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String okLabel = 'تأكيد',
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(
                  backgroundColor: YecoColors.danger,
                  minimumSize: const Size(90, 44),
                )
              : FilledButton.styleFrom(minimumSize: const Size(90, 44)),
          onPressed: () => Navigator.pop(c, true),
          child: Text(okLabel),
        ),
      ],
    ),
  );
  return r ?? false;
}

// ------------------------------------------------------------ مُدقّقات
abstract final class V {
  static final _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]{2,}$');
  static final _phone = RegExp(r'^(\+?\d{9,15})$');

  static String? required(String? v, [String label = 'هذا الحقل']) =>
      (v == null || v.trim().isEmpty) ? '$label مطلوب' : null;

  static String? name(String? v) {
    if (v == null || v.trim().isEmpty) return 'الاسم مطلوب';
    if (v.trim().length < 3) return 'الاسم قصير جداً (3 أحرف على الأقل)';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'البريد الإلكتروني مطلوب';
    if (!_email.hasMatch(v.trim())) {
      return 'صيغة البريد غير صحيحة (مثال: name@mail.com)';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
    if (v.length < 6) return 'كلمة المرور قصيرة (6 أحرف على الأقل)';
    if (!RegExp(r'\d').hasMatch(v)) {
      return 'يجب أن تحتوي على رقم واحد على الأقل';
    }
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'أعد كتابة كلمة المرور';
    if (v != original) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'رقم الجوال مطلوب';
    if (!_phone.hasMatch(v.trim().replaceAll(' ', ''))) {
      return 'رقم الجوال غير صحيح (9–15 رقماً)';
    }
    return null;
  }

  static String? price(String? v) {
    if (v == null || v.trim().isEmpty) return 'السعر مطلوب';
    final d = double.tryParse(v.trim());
    if (d == null) return 'أدخل رقماً صحيحاً';
    if (d <= 0) return 'السعر يجب أن يكون أكبر من صفر';
    return null;
  }

  static String? intNonNegative(String? v, [String label = 'القيمة']) {
    if (v == null || v.trim().isEmpty) return '$label مطلوبة';
    final n = int.tryParse(v.trim());
    if (n == null || n < 0) return '$label يجب أن تكون عدداً صحيحاً ≥ 0';
    return null;
  }

  static String? minLen(String? v, int n, String label) {
    if (v == null || v.trim().isEmpty) return '$label مطلوب';
    if (v.trim().length < n) return '$label قصير جداً ($n أحرف على الأقل)';
    return null;
  }

  static String? otp(String? v) {
    if (v == null || v.trim().isEmpty) return 'أدخل رمز التحقق';
    if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) return 'الرمز مكوّن من 6 أرقام';
    return null;
  }
}
