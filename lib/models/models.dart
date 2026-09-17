// ============================================================
// YECO - نماذج البيانات (تطابق جداول SQLite واحداً لواحد)
// ============================================================

/// دور المستخدم: زبون أو بائع
enum UserRole {
  customer,
  seller;

  static UserRole fromDb(int v) => v == 1 ? seller : customer;
  int get db => this == seller ? 1 : 0;
  String get label => this == seller ? 'بائع' : 'زبون';
}

class AppUser {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String city;
  final UserRole role;
  final String createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.role,
    required this.createdAt,
  });

  bool get isSeller => role == UserRole.seller;

  factory AppUser.fromMap(Map<String, Object?> m) => AppUser(
    id: m['id'] as int,
    name: (m['name'] as String?) ?? '',
    email: (m['email'] as String?) ?? '',
    phone: (m['phone'] as String?) ?? '',
    city: (m['city'] as String?) ?? '',
    role: UserRole.fromDb((m['role'] as int?) ?? 0),
    createdAt: (m['created_at'] as String?) ?? '',
  );

  AppUser copyWith({String? name, String? phone, String? city}) => AppUser(
    id: id,
    name: name ?? this.name,
    email: email,
    phone: phone ?? this.phone,
    city: city ?? this.city,
    role: role,
    createdAt: createdAt,
  );
}

class Category {
  final int id;
  final String name;
  final String slug;
  final int colorValue;
  final String image;
  final int iconCode;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.colorValue,
    required this.image,
    required this.iconCode,
  });

  factory Category.fromMap(Map<String, Object?> m) => Category(
    id: m['id'] as int,
    name: (m['name'] as String?) ?? '',
    slug: (m['slug'] as String?) ?? '',
    colorValue: (m['color'] as int?) ?? 0xFF0F9D6E,
    image: (m['image'] as String?) ?? '',
    iconCode: (m['icon'] as int?) ?? 0,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'slug': slug,
    'color': colorValue,
    'image': image,
    'icon': iconCode,
  };
}

class Product {
  final int id;
  final int categoryId;
  final int sellerId; // 0 = منتج ابتدائي من المتجر
  final String name;
  final String brand;
  final String description;
  final double price;
  final double? oldPrice;
  final int stock;
  final double rating;
  final int ratingCount;
  final String image; // asset path أو مسار ملف على الجهاز
  final bool featured;
  final String createdAt;

  const Product({
    required this.id,
    required this.categoryId,
    required this.sellerId,
    required this.name,
    required this.brand,
    required this.description,
    required this.price,
    this.oldPrice,
    required this.stock,
    required this.rating,
    required this.ratingCount,
    required this.image,
    required this.featured,
    required this.createdAt,
  });

  bool get hasDiscount => oldPrice != null && oldPrice! > price;
  int get discountPercent =>
      hasDiscount ? (((oldPrice! - price) / oldPrice!) * 100).round() : 0;
  bool get inStock => stock > 0;
  bool get isAsset => image.startsWith('assets/');

  factory Product.fromMap(Map<String, Object?> m) => Product(
    id: m['id'] as int,
    categoryId: (m['category_id'] as int?) ?? 0,
    sellerId: (m['seller_id'] as int?) ?? 0,
    name: (m['name'] as String?) ?? '',
    brand: (m['brand'] as String?) ?? '',
    description: (m['description'] as String?) ?? '',
    price: ((m['price'] as num?) ?? 0).toDouble(),
    oldPrice: (m['old_price'] as num?)?.toDouble(),
    stock: (m['stock'] as int?) ?? 0,
    rating: ((m['rating'] as num?) ?? 0).toDouble(),
    ratingCount: (m['rating_count'] as int?) ?? 0,
    image: (m['image'] as String?) ?? '',
    featured: ((m['featured'] as int?) ?? 0) == 1,
    createdAt: (m['created_at'] as String?) ?? '',
  );

  Map<String, Object?> toMap({bool withId = true}) => {
    if (withId) 'id': id,
    'category_id': categoryId,
    'seller_id': sellerId,
    'name': name,
    'brand': brand,
    'description': description,
    'price': price,
    'old_price': oldPrice,
    'stock': stock,
    'rating': rating,
    'rating_count': ratingCount,
    'image': image,
    'featured': featured ? 1 : 0,
    'created_at': createdAt,
  };

  Product copyWith({
    int? categoryId,
    String? name,
    String? brand,
    String? description,
    double? price,
    double? oldPrice,
    bool clearOldPrice = false,
    int? stock,
    String? image,
    bool? featured,
    double? rating,
    int? ratingCount,
  }) => Product(
    id: id,
    categoryId: categoryId ?? this.categoryId,
    sellerId: sellerId,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    description: description ?? this.description,
    price: price ?? this.price,
    oldPrice: clearOldPrice ? null : (oldPrice ?? this.oldPrice),
    stock: stock ?? this.stock,
    rating: rating ?? this.rating,
    ratingCount: ratingCount ?? this.ratingCount,
    image: image ?? this.image,
    featured: featured ?? this.featured,
    createdAt: createdAt,
  );
}

class CartLine {
  final int id;
  final Product product;
  final int qty;
  const CartLine({required this.id, required this.product, required this.qty});
  double get total => product.price * qty;
}

enum OrderStatus {
  pending('قيد المراجعة'),
  confirmed('تم التأكيد'),
  shipped('جارٍ التوصيل'),
  delivered('تم التسليم'),
  cancelled('ملغي');

  const OrderStatus(this.label);
  final String label;
  static OrderStatus fromDb(int i) => values[i.clamp(0, values.length - 1)];
}

class Order {
  final int id;
  final int userId;
  final String customerName;
  final String address;
  final String phone;
  final String payment; // cash | card
  final double subtotal;
  final double discount;
  final double delivery;
  final double total;
  final OrderStatus status;
  final String createdAt;
  final List<OrderLine> lines;

  const Order({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.payment,
    required this.subtotal,
    required this.discount,
    required this.delivery,
    required this.total,
    required this.status,
    required this.createdAt,
    this.lines = const [],
  });

  int get itemCount => lines.fold(0, (s, l) => s + l.qty);
  bool get canCancel =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  factory Order.fromMap(Map<String, Object?> m, [List<OrderLine>? lines]) =>
      Order(
        id: m['id'] as int,
        userId: (m['user_id'] as int?) ?? 0,
        customerName: (m['customer_name'] as String?) ?? '',
        address: (m['address'] as String?) ?? '',
        phone: (m['phone'] as String?) ?? '',
        payment: (m['payment'] as String?) ?? 'cash',
        subtotal: ((m['subtotal'] as num?) ?? 0).toDouble(),
        discount: ((m['discount'] as num?) ?? 0).toDouble(),
        delivery: ((m['delivery'] as num?) ?? 0).toDouble(),
        total: ((m['total'] as num?) ?? 0).toDouble(),
        status: OrderStatus.fromDb((m['status'] as int?) ?? 0),
        createdAt: (m['created_at'] as String?) ?? '',
        lines: lines ?? const [],
      );
}

class OrderLine {
  final int id;
  final int orderId;
  final int productId;
  final String name;
  final String image;
  final double price;
  final int qty;
  const OrderLine({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.qty,
  });
  double get total => price * qty;

  factory OrderLine.fromMap(Map<String, Object?> m) => OrderLine(
    id: m['id'] as int,
    orderId: (m['order_id'] as int?) ?? 0,
    productId: (m['product_id'] as int?) ?? 0,
    name: (m['name'] as String?) ?? '',
    image: (m['image'] as String?) ?? '',
    price: ((m['price'] as num?) ?? 0).toDouble(),
    qty: (m['qty'] as int?) ?? 1,
  );
}

class Review {
  final int id;
  final int productId;
  final int userId;
  final String userName;
  final int stars;
  final String comment;
  final String createdAt;
  const Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.stars,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, Object?> m) => Review(
    id: m['id'] as int,
    productId: (m['product_id'] as int?) ?? 0,
    userId: (m['user_id'] as int?) ?? 0,
    userName: (m['user_name'] as String?) ?? '',
    stars: (m['stars'] as int?) ?? 5,
    comment: (m['comment'] as String?) ?? '',
    createdAt: (m['created_at'] as String?) ?? '',
  );
}

/// كوبونات الخصم المتاحة (ثابتة داخل التطبيق)
class Coupon {
  final String code;
  final int percent;
  final double minSubtotal;
  const Coupon(this.code, this.percent, this.minSubtotal);

  static const all = [
    Coupon('YECO10', 10, 0),
    Coupon('WELCOME', 15, 100),
    Coupon('BIG25', 25, 500),
  ];

  static Coupon? find(String code) {
    final c = code.trim().toUpperCase();
    for (final k in all) {
      if (k.code == c) return k;
    }
    return null;
  }
}
