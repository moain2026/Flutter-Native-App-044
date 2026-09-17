// ============================================================
// YECO - قاعدة البيانات المحلية SQLite
// المسار: getDatabasesPath()/yeco.db (المسار الافتراضي لأندرويد)
// الجداول: users, categories, products, cart_items, favorites,
//          orders, order_items, reviews, app_settings
// ============================================================

import 'package:sqflite/sqflite.dart';

import 'seed.dart';

class YecoDb {
  YecoDb._();
  static final YecoDb instance = YecoDb._();

  static const version = 1;
  Database? _db;
  Database get db => _db!;
  bool get isOpen => _db != null;

  /// مسار مخصص (للاختبارات: inMemoryDatabasePath)
  String? pathOverride;

  Future<void> open() async {
    if (_db != null) return;
    final path = pathOverride ?? '${await getDatabasesPath()}/yeco.db';
    _db = await openDatabase(
      path,
      version: version,
      onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: (d, _) async {
        await createSchema(d);
        await seedCatalog(d);
      },
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  static Future<void> createSchema(DatabaseExecutor d) async {
    await d.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        city TEXT NOT NULL DEFAULT '',
        role INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )''');
    await d.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        slug TEXT NOT NULL,
        color INTEGER NOT NULL,
        image TEXT NOT NULL DEFAULT '',
        icon INTEGER NOT NULL DEFAULT 0
      )''');
    await d.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL REFERENCES categories(id),
        seller_id INTEGER NOT NULL DEFAULT 0,
        name TEXT NOT NULL,
        brand TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        price REAL NOT NULL,
        old_price REAL,
        stock INTEGER NOT NULL DEFAULT 0,
        rating REAL NOT NULL DEFAULT 0,
        rating_count INTEGER NOT NULL DEFAULT 0,
        image TEXT NOT NULL DEFAULT '',
        featured INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )''');
    await d.execute('''
      CREATE TABLE cart_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
        qty INTEGER NOT NULL DEFAULT 1,
        UNIQUE(user_id, product_id)
      )''');
    await d.execute('''
      CREATE TABLE favorites(
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
        PRIMARY KEY(user_id, product_id)
      )''');
    await d.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        customer_name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT NOT NULL,
        payment TEXT NOT NULL DEFAULT 'cash',
        subtotal REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        delivery REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )''');
    await d.execute('''
      CREATE TABLE order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
        product_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        image TEXT NOT NULL DEFAULT '',
        price REAL NOT NULL,
        qty INTEGER NOT NULL
      )''');
    await d.execute('''
      CREATE TABLE reviews(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        user_name TEXT NOT NULL,
        stars INTEGER NOT NULL,
        comment TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        UNIQUE(product_id, user_id)
      )''');
    // إعدادات قابلة للتعديل من داخل التطبيق (مثل اسم المطوّر)
    await d.execute('''
      CREATE TABLE app_settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )''');
    await d.execute('CREATE INDEX idx_products_cat ON products(category_id)');
    await d.execute('CREATE INDEX idx_orders_user ON orders(user_id)');
  }
}
