// ============================================================
// YECO - المستودعات (طبقة الوصول إلى SQLite: CRUD كامل)
// كل مستودع يتعامل مع جدول أو جدولين ويُرجع نماذج جاهزة للواجهة
// ============================================================

import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import 'db.dart';

Database get _db => YecoDb.instance.db;
String _now() => DateTime.now().toIso8601String();

// ------------------------------------------------------------ Users
class UserRepo {
  const UserRepo();

  Future<AppUser?> byEmail(String email) async {
    final r = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    return r.isEmpty ? null : AppUser.fromMap(r.first);
  }

  Future<AppUser?> byId(int id) async {
    final r = await _db.query('users', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : AppUser.fromMap(r.first);
  }

  Future<bool> emailExists(String email) async =>
      (await byEmail(email)) != null;

  /// يُرجع كلمة المرور المجزّأة لمقارنتها في طبقة المصادقة
  Future<String?> passwordHashOf(String email) async {
    final r = await _db.query(
      'users',
      columns: ['password'],
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    return r.isEmpty ? null : r.first['password'] as String;
  }

  Future<AppUser> create({
    required String name,
    required String email,
    required String passwordHash,
    required String phone,
    required String city,
    required UserRole role,
  }) async {
    final id = await _db.insert('users', {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': passwordHash,
      'phone': phone.trim(),
      'city': city.trim(),
      'role': role.db,
      'created_at': _now(),
    });
    return (await byId(id))!;
  }

  Future<void> updateProfile(AppUser u) => _db.update(
    'users',
    {'name': u.name, 'phone': u.phone, 'city': u.city},
    where: 'id = ?',
    whereArgs: [u.id],
  );

  Future<int> updatePassword(String email, String newHash) => _db.update(
    'users',
    {'password': newHash},
    where: 'email = ?',
    whereArgs: [email.trim().toLowerCase()],
  );

  Future<void> delete(int id) =>
      _db.delete('users', where: 'id = ?', whereArgs: [id]);

  Future<int> count() async =>
      Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM users')) ??
      0;
}

// ------------------------------------------------------------ Catalog
class CatalogRepo {
  const CatalogRepo();

  Future<List<Category>> categories() async => (await _db.query(
    'categories',
    orderBy: 'id',
  )).map(Category.fromMap).toList();

  Future<Category?> category(int id) async {
    final r = await _db.query('categories', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : Category.fromMap(r.first);
  }

  Future<List<Product>> products({
    int? categoryId,
    int? sellerId,
    String? search,
    bool onlyFeatured = false,
    bool onlyInStock = false,
  }) async {
    final where = <String>[];
    final args = <Object?>[];
    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }
    if (sellerId != null) {
      where.add('seller_id = ?');
      args.add(sellerId);
    }
    if (onlyFeatured) where.add('featured = 1');
    if (onlyInStock) where.add('stock > 0');
    if (search != null && search.trim().isNotEmpty) {
      where.add('(name LIKE ? OR brand LIKE ? OR description LIKE ?)');
      final q = '%${search.trim()}%';
      args.addAll([q, q, q]);
    }
    final r = await _db.query(
      'products',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'featured DESC, id DESC',
    );
    return r.map(Product.fromMap).toList();
  }

  Future<Product?> product(int id) async {
    final r = await _db.query('products', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : Product.fromMap(r.first);
  }

  Future<Product> insertProduct(Product p) async {
    final id = await _db.insert('products', p.toMap(withId: false));
    return (await product(id))!;
  }

  Future<void> updateProduct(Product p) => _db.update(
    'products',
    p.toMap(withId: false),
    where: 'id = ?',
    whereArgs: [p.id],
  );

  Future<void> deleteProduct(int id) =>
      _db.delete('products', where: 'id = ?', whereArgs: [id]);

  Future<void> adjustStock(DatabaseExecutor d, int productId, int delta) =>
      d.rawUpdate(
        'UPDATE products SET stock = MAX(0, stock + ?) WHERE id = ?',
        [delta, productId],
      );

  Future<Map<int, int>> countByCategory() async {
    final r = await _db.rawQuery(
      'SELECT category_id, COUNT(*) c FROM products GROUP BY category_id',
    );
    return {for (final m in r) m['category_id'] as int: m['c'] as int};
  }

  Future<int> productCount({int? sellerId}) async {
    final r = sellerId == null
        ? await _db.rawQuery('SELECT COUNT(*) FROM products')
        : await _db.rawQuery(
            'SELECT COUNT(*) FROM products WHERE seller_id = ?',
            [sellerId],
          );
    return Sqflite.firstIntValue(r) ?? 0;
  }
}

// ------------------------------------------------------------ Cart
class CartRepo {
  const CartRepo();

  Future<List<CartLine>> lines(int userId) async {
    final r = await _db.rawQuery(
      '''
      SELECT c.id AS cid, c.qty AS cqty, p.*
      FROM cart_items c JOIN products p ON p.id = c.product_id
      WHERE c.user_id = ? ORDER BY c.id DESC''',
      [userId],
    );
    return r
        .map(
          (m) => CartLine(
            id: m['cid'] as int,
            product: Product.fromMap(m),
            qty: m['cqty'] as int,
          ),
        )
        .toList();
  }

  Future<void> add(int userId, int productId, {int qty = 1}) async {
    await _db.rawInsert(
      '''
      INSERT INTO cart_items(user_id, product_id, qty) VALUES(?, ?, ?)
      ON CONFLICT(user_id, product_id) DO UPDATE SET qty = qty + excluded.qty''',
      [userId, productId, qty],
    );
  }

  Future<void> setQty(int lineId, int qty) => qty <= 0
      ? remove(lineId)
      : _db.update(
          'cart_items',
          {'qty': qty},
          where: 'id = ?',
          whereArgs: [lineId],
        );

  Future<void> remove(int lineId) =>
      _db.delete('cart_items', where: 'id = ?', whereArgs: [lineId]);

  Future<void> clear(int userId) =>
      _db.delete('cart_items', where: 'user_id = ?', whereArgs: [userId]);

  Future<int> count(int userId) async =>
      Sqflite.firstIntValue(
        await _db.rawQuery(
          'SELECT COALESCE(SUM(qty),0) FROM cart_items WHERE user_id = ?',
          [userId],
        ),
      ) ??
      0;
}

// ------------------------------------------------------------ Favorites
class FavoriteRepo {
  const FavoriteRepo();

  Future<Set<int>> ids(int userId) async {
    final r = await _db.query(
      'favorites',
      columns: ['product_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return r.map((m) => m['product_id'] as int).toSet();
  }

  Future<List<Product>> products(int userId) async {
    final r = await _db.rawQuery(
      '''
      SELECT p.* FROM favorites f JOIN products p ON p.id = f.product_id
      WHERE f.user_id = ? ORDER BY f.rowid DESC''',
      [userId],
    );
    return r.map(Product.fromMap).toList();
  }

  /// يُرجع true إذا أُضيف، false إذا أُزيل
  Future<bool> toggle(int userId, int productId) async {
    final removed = await _db.delete(
      'favorites',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
    );
    if (removed > 0) return false;
    await _db.insert('favorites', {'user_id': userId, 'product_id': productId});
    return true;
  }
}

// ------------------------------------------------------------ Orders
class OrderRepo {
  const OrderRepo();

  static const deliveryFee = 25.0;
  static const freeDeliveryFrom = 300.0;

  Future<Order> checkout({
    required AppUser user,
    required List<CartLine> lines,
    required String address,
    required String phone,
    required String payment,
    Coupon? coupon,
  }) async {
    final subtotal = lines.fold(0.0, (s, l) => s + l.total);
    final discount = (coupon != null && subtotal >= coupon.minSubtotal)
        ? subtotal * coupon.percent / 100
        : 0.0;
    final delivery = subtotal >= freeDeliveryFrom ? 0.0 : deliveryFee;
    final total = subtotal - discount + delivery;
    late int orderId;
    await _db.transaction((t) async {
      orderId = await t.insert('orders', {
        'user_id': user.id,
        'customer_name': user.name,
        'address': address.trim(),
        'phone': phone.trim(),
        'payment': payment,
        'subtotal': subtotal,
        'discount': discount,
        'delivery': delivery,
        'total': total,
        'status': OrderStatus.pending.index,
        'created_at': _now(),
      });
      for (final l in lines) {
        await t.insert('order_items', {
          'order_id': orderId,
          'product_id': l.product.id,
          'name': l.product.name,
          'image': l.product.image,
          'price': l.product.price,
          'qty': l.qty,
        });
        await const CatalogRepo().adjustStock(t, l.product.id, -l.qty);
      }
      await t.delete('cart_items', where: 'user_id = ?', whereArgs: [user.id]);
    });
    return (await byId(orderId))!;
  }

  Future<Order?> byId(int id) async {
    final r = await _db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (r.isEmpty) return null;
    final items = await _db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [id],
    );
    return Order.fromMap(r.first, items.map(OrderLine.fromMap).toList());
  }

  Future<List<Order>> forUser(int userId) async {
    final r = await _db.query(
      'orders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return _withLines(r);
  }

  /// كل الطلبات (للبائع) — مع إمكانية التصفية بالحالة
  Future<List<Order>> all({OrderStatus? status}) async {
    final r = await _db.query(
      'orders',
      where: status == null ? null : 'status = ?',
      whereArgs: status == null ? null : [status.index],
      orderBy: 'id DESC',
    );
    return _withLines(r);
  }

  Future<List<Order>> _withLines(List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return const [];
    final ids = rows.map((m) => m['id'] as int).toList();
    final items = await _db.query(
      'order_items',
      where: 'order_id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
    final grouped = <int, List<OrderLine>>{};
    for (final m in items) {
      final l = OrderLine.fromMap(m);
      grouped.putIfAbsent(l.orderId, () => []).add(l);
    }
    return rows
        .map((m) => Order.fromMap(m, grouped[m['id'] as int] ?? const []))
        .toList();
  }

  Future<void> setStatus(int orderId, OrderStatus s) => _db.update(
    'orders',
    {'status': s.index},
    where: 'id = ?',
    whereArgs: [orderId],
  );

  /// إلغاء طلب مع إعادة الكمية إلى المخزون
  Future<void> cancel(int orderId) async {
    final o = await byId(orderId);
    if (o == null || !o.canCancel) return;
    await _db.transaction((t) async {
      for (final l in o.lines) {
        await const CatalogRepo().adjustStock(t, l.productId, l.qty);
      }
      await t.update(
        'orders',
        {'status': OrderStatus.cancelled.index},
        where: 'id = ?',
        whereArgs: [orderId],
      );
    });
  }

  Future<void> delete(int orderId) =>
      _db.delete('orders', where: 'id = ?', whereArgs: [orderId]);

  /// إحصاءات لوحة البائع
  Future<SellerStats> stats() async {
    final rows = await _db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM orders) AS orders_count,
        (SELECT COUNT(*) FROM orders WHERE status = 0) AS pending_count,
        (SELECT COALESCE(SUM(total),0) FROM orders WHERE status != 4) AS revenue,
        (SELECT COUNT(*) FROM products) AS products_count,
        (SELECT COUNT(*) FROM products WHERE stock = 0) AS out_of_stock,
        (SELECT COUNT(*) FROM users WHERE role = 0) AS customers_count
    ''');
    final m = rows.first;
    final top = await _db.rawQuery('''
      SELECT name, SUM(qty) AS sold FROM order_items oi
      JOIN orders o ON o.id = oi.order_id WHERE o.status != 4
      GROUP BY product_id ORDER BY sold DESC LIMIT 5''');
    return SellerStats(
      orders: m['orders_count'] as int,
      pending: m['pending_count'] as int,
      revenue: (m['revenue'] as num).toDouble(),
      products: m['products_count'] as int,
      outOfStock: m['out_of_stock'] as int,
      customers: m['customers_count'] as int,
      topProducts: top
          .map(
            (r) =>
                (name: r['name'] as String, sold: (r['sold'] as num).toInt()),
          )
          .toList(),
    );
  }
}

class SellerStats {
  final int orders;
  final int pending;
  final double revenue;
  final int products;
  final int outOfStock;
  final int customers;
  final List<({String name, int sold})> topProducts;
  const SellerStats({
    required this.orders,
    required this.pending,
    required this.revenue,
    required this.products,
    required this.outOfStock,
    required this.customers,
    required this.topProducts,
  });
}

// ------------------------------------------------------------ Reviews
class ReviewRepo {
  const ReviewRepo();

  Future<List<Review>> forProduct(int productId) async => (await _db.query(
    'reviews',
    where: 'product_id = ?',
    whereArgs: [productId],
    orderBy: 'id DESC',
  )).map(Review.fromMap).toList();

  /// إضافة أو تعديل مراجعة المستخدم ثم إعادة حساب تقييم المنتج
  Future<void> upsert({
    required int productId,
    required AppUser user,
    required int stars,
    required String comment,
  }) async {
    await _db.transaction((t) async {
      await t.rawInsert(
        '''
        INSERT INTO reviews(product_id, user_id, user_name, stars, comment, created_at)
        VALUES(?, ?, ?, ?, ?, ?)
        ON CONFLICT(product_id, user_id) DO UPDATE SET
          stars = excluded.stars, comment = excluded.comment, created_at = excluded.created_at''',
        [productId, user.id, user.name, stars, comment.trim(), _now()],
      );
      await _recalc(t, productId);
    });
  }

  Future<void> delete(int reviewId) async {
    final r = await _db.query(
      'reviews',
      where: 'id = ?',
      whereArgs: [reviewId],
    );
    if (r.isEmpty) return;
    final pid = r.first['product_id'] as int;
    await _db.transaction((t) async {
      await t.delete('reviews', where: 'id = ?', whereArgs: [reviewId]);
      await _recalc(t, pid);
    });
  }

  Future<void> _recalc(DatabaseExecutor t, int productId) async {
    final agg = await t.rawQuery(
      'SELECT AVG(stars) a, COUNT(*) c FROM reviews WHERE product_id = ?',
      [productId],
    );
    final c = agg.first['c'] as int;
    if (c == 0) return; // أبقِ التقييم الابتدائي إن لم تبق مراجعات
    await t.update(
      'products',
      {'rating': (agg.first['a'] as num).toDouble(), 'rating_count': c},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }
}

// ------------------------------------------------------------ Settings
/// إعدادات قابلة للتعديل من داخل التطبيق ومحفوظة في SQLite
class SettingsRepo {
  const SettingsRepo();

  static const developerName = 'developer_name';
  static const storeName = 'store_name';
  static const defaultDeveloper = 'جواد';
  static const defaultStore = 'YECO';

  Future<String> get(String key, String fallback) async {
    final r = await _db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return r.isEmpty ? fallback : (r.first['value'] as String);
  }

  Future<void> set(String key, String value) => _db.insert('app_settings', {
    'key': key,
    'value': value.trim(),
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}
