// اختبارات SQLite CRUD: المستخدمون، الكتالوج، السلة، المفضلة، الطلبات، المراجعات، الإعدادات
import 'package:flutter_test/flutter_test.dart';
import 'package:yeco_market/data/repos.dart';
import 'package:yeco_market/models/models.dart';
import 'package:yeco_market/state/session.dart';
import 'package:yeco_market/state/store.dart';

import 'helpers.dart';

void main() {
  setUp(() async {
    await resetPrefs();
    await openTestDb();
  });

  test('البذر: 6 تصنيفات و24 منتجاً بصور Assets', () async {
    const repo = CatalogRepo();
    final cats = await repo.categories();
    final products = await repo.products();
    expect(cats, hasLength(6));
    expect(products, hasLength(24));
    expect(
      products.every((p) => p.image.startsWith('assets/products/')),
      isTrue,
    );
    expect((await repo.countByCategory()).values.every((n) => n == 4), isTrue);
  });

  test('Session: إنشاء حساب → دخول بكلمة المرور → استعادة → تغيير', () async {
    final s = Session();
    expect(await s.lookup('j@yeco.app'), EmailLookup.notFound);
    final u = await s.signUp(
      name: 'جواد',
      email: 'J@yeco.app',
      password: 'Pass123',
      phone: '0500000000',
      city: 'صنعاء',
      role: UserRole.seller,
    );
    expect(u.email, 'j@yeco.app'); // يُخزَّن بحروف صغيرة
    expect(u.isSeller, isTrue);
    expect(await s.lookup('j@yeco.app'), EmailLookup.exists);
    expect(await s.checkPassword('j@yeco.app', 'Pass123'), PasswordCheck.ok);
    expect(await s.checkPassword('j@yeco.app', 'nope'), PasswordCheck.wrong);
    expect(await s.checkPassword('none@x.com', 'x'), PasswordCheck.noUser);

    // نسيت كلمة المرور → UPDATE فعلي
    expect(await s.resetPassword('j@yeco.app', 'New456'), isTrue);
    expect(await s.checkPassword('j@yeco.app', 'Pass123'), PasswordCheck.wrong);
    expect(await s.checkPassword('j@yeco.app', 'New456'), PasswordCheck.ok);

    // تغيير من داخل الحساب
    expect(await s.changePassword('bad', 'Zzz789'), isNotNull);
    expect(await s.changePassword('New456', 'Zzz789'), isNull);

    // تعديل الملف
    await s.updateProfile(name: 'جواد العبسي', city: 'عدن');
    expect((await const UserRepo().byId(u.id))!.city, 'عدن');

    // الجلسة تُستعاد بعد إعادة التشغيل
    final s2 = Session();
    await s2.restore();
    expect(s2.uid, u.id);

    await s.deleteAccount();
    expect(await s.lookup('j@yeco.app'), EmailLookup.notFound);
  });

  test('البريد فريد: إنشاء حساب مكرر يفشل', () async {
    final s = Session();
    await s.signUp(
      name: 'أ',
      email: 'a@a.com',
      password: 'Pass123',
      phone: '1',
      city: 'x',
      role: UserRole.customer,
    );
    expect(
      () => s.signUp(
        name: 'ب',
        email: 'a@a.com',
        password: 'Pass123',
        phone: '1',
        city: 'x',
        role: UserRole.customer,
      ),
      throwsA(anything),
    );
  });

  test('Store: سلة (إضافة/كمية/حذف/تفريغ) + مفضلة', () async {
    final s = Session();
    final u = await s.signUp(
      name: 'ز',
      email: 'c@c.com',
      password: 'Pass123',
      phone: '1',
      city: 'x',
      role: UserRole.customer,
    );
    final st = Store();
    await st.load();
    await st.bind(u.id);
    final p1 = st.products.first;
    final p2 = st.products[1];

    await st.addToCart(p1, qty: 2);
    await st.addToCart(p1); // نفس المنتج → تُجمع الكمية
    await st.addToCart(p2);
    expect(st.cart, hasLength(2));
    expect(st.cartCount, 4);
    expect(st.cartSubtotal, closeTo(p1.price * 3 + p2.price, 0.01));

    await st.setQty(st.cart.firstWhere((l) => l.product.id == p1.id), 1);
    expect(st.cartCount, 2);
    await st.setQty(
      st.cart.firstWhere((l) => l.product.id == p2.id),
      0,
    ); // 0 = حذف
    expect(st.cart, hasLength(1));
    await st.clearCart();
    expect(st.cart, isEmpty);

    expect(await st.toggleFavorite(p1), isTrue);
    expect(st.isFavorite(p1.id), isTrue);
    expect(await st.toggleFavorite(p1), isFalse);
    expect(st.isFavorite(p1.id), isFalse);

    // مستخدم آخر لا يرى سلة الأول
    await st.addToCart(p1);
    await st.bind(999);
    expect(st.cart, isEmpty);
  });

  test(
    'Orders: checkout يخصم المخزون ويفرغ السلة، الكوبون والتوصيل، الإلغاء يُعيد المخزون',
    () async {
      final s = Session();
      final u = await s.signUp(
        name: 'ز',
        email: 'o@o.com',
        password: 'Pass123',
        phone: '1',
        city: 'x',
        role: UserRole.customer,
      );
      final st = Store();
      await st.load();
      await st.bind(u.id);
      final p = st.products.firstWhere((p) => p.price < 100 && p.stock >= 3);
      await st.addToCart(p, qty: 2);
      final sub = p.price * 2;

      const orders = OrderRepo();
      final o = await orders.checkout(
        user: u,
        lines: st.cart,
        address: 'صنعاء، شارع حدة',
        phone: '777',
        payment: 'cash',
        coupon: Coupon.find('yeco10'),
      );
      expect(o.status, OrderStatus.pending);
      expect(o.subtotal, closeTo(sub, 0.01));
      expect(o.discount, closeTo(sub * 0.10, 0.01));
      expect(
        o.delivery,
        sub >= OrderRepo.freeDeliveryFrom ? 0 : OrderRepo.deliveryFee,
      );
      expect(o.total, closeTo(o.subtotal - o.discount + o.delivery, 0.01));
      expect(o.lines, hasLength(1));
      expect(o.lines.first.qty, 2);

      await st.refreshCatalog();
      expect(st.cart, isEmpty);
      expect(st.productOf(p.id)!.stock, p.stock - 2);

      expect(await orders.forUser(u.id), hasLength(1));
      expect(await orders.all(status: OrderStatus.pending), hasLength(1));

      await orders.setStatus(o.id, OrderStatus.shipped);
      expect((await orders.byId(o.id))!.status, OrderStatus.shipped);
      expect((await orders.byId(o.id))!.canCancel, isFalse);

      await orders.setStatus(o.id, OrderStatus.confirmed);
      await orders.cancel(o.id);
      expect((await orders.byId(o.id))!.status, OrderStatus.cancelled);
      await st.refreshCatalog();
      expect(st.productOf(p.id)!.stock, p.stock); // عاد المخزون

      final stats = await orders.stats();
      expect(stats.orders, 1);
      expect(stats.customers, 1);
      expect(stats.revenue, 0); // الملغي لا يُحسب

      await orders.delete(o.id);
      expect(await orders.byId(o.id), isNull);
    },
  );

  test('كوبون WELCOME يتطلب حداً أدنى', () async {
    final c = Coupon.find('WELCOME')!;
    expect(c.percent, 15);
    expect(c.minSubtotal, 100);
    expect(Coupon.find('nope'), isNull);
  });

  test('Products CRUD للبائع + المراجعات تُحدّث التقييم', () async {
    final s = Session();
    final seller = await s.signUp(
      name: 'ب',
      email: 's@s.com',
      password: 'Pass123',
      phone: '1',
      city: 'x',
      role: UserRole.seller,
    );
    final st = Store();
    await st.load();

    final added = await st.addProduct(
      Product(
        id: 0,
        categoryId: 2,
        sellerId: seller.id,
        name: 'قهوة يمنية 250 جم',
        brand: 'Mocha',
        description: 'بن يمني أصلي من حراز',
        price: 45,
        oldPrice: 60,
        stock: 20,
        rating: 0,
        ratingCount: 0,
        image: 'assets/categories/grocery.jpg',
        featured: true,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    expect(added.id, greaterThan(24));
    expect(st.products, hasLength(25));
    expect(added.discountPercent, 25);
    expect(st.countByCategory[2], 5);

    await st.updateProduct(
      added.copyWith(price: 40, stock: 0, clearOldPrice: true),
    );
    final up = st.productOf(added.id)!;
    expect(up.price, 40);
    expect(up.oldPrice, isNull);
    expect(up.inStock, isFalse);

    // مراجعة زبون
    final cust = await s.signUp(
      name: 'ز',
      email: 'r@r.com',
      password: 'Pass123',
      phone: '1',
      city: 'x',
      role: UserRole.customer,
    );
    const reviews = ReviewRepo();
    await reviews.upsert(
      productId: added.id,
      user: cust,
      stars: 4,
      comment: 'ممتاز جداً',
    );
    await reviews.upsert(
      productId: added.id,
      user: cust,
      stars: 2,
      comment: 'غيّرت رأيي',
    ); // تعديل لا تكرار
    var list = await reviews.forProduct(added.id);
    expect(list, hasLength(1));
    expect(list.first.stars, 2);
    await st.refreshCatalog();
    expect(st.productOf(added.id)!.rating, 2);
    expect(st.productOf(added.id)!.ratingCount, 1);
    await reviews.delete(list.first.id);
    expect(await reviews.forProduct(added.id), isEmpty);

    await st.deleteProduct(added.id);
    expect(st.products, hasLength(24));
    expect(await const CatalogRepo().product(added.id), isNull);
  });

  test('البحث والتصفية في CatalogRepo', () async {
    const repo = CatalogRepo();
    expect(await repo.products(search: 'عسل'), hasLength(1));
    expect(await repo.products(categoryId: 3), hasLength(4));
    expect(
      (await repo.products(onlyFeatured: true)).every((p) => p.featured),
      isTrue,
    );
  });

  test('الإعدادات: اسم المطوّر يُحفظ في SQLite ويُستعاد', () async {
    final st = Store();
    await st.load();
    expect(st.developerName, 'جواد');
    await st.setDeveloperName('جواد العبسي');
    final st2 = Store();
    await st2.load();
    expect(st2.developerName, 'جواد العبسي');
    await st2.setStoreName('متجر YECO');
    expect(
      (await const SettingsRepo().get(SettingsRepo.storeName, '')),
      'متجر YECO',
    );
  });
}
