// ============================================================
// YECO - حالة المتجر (كتالوج + سلة + مفضلة) بـ ChangeNotifier واحد
// + AppScope: InheritedNotifier يوفّر Session و Store لكل الشجرة
//   بدون حزمة Provider (اختلاف بنيوي عن المشاريع السابقة)
// ============================================================

import 'package:flutter/widgets.dart';

import '../data/repos.dart';
import '../models/models.dart';
import 'session.dart';

class Store extends ChangeNotifier {
  Store({
    CatalogRepo? catalog,
    CartRepo? cart,
    FavoriteRepo? favorites,
    SettingsRepo? settings,
  }) : _catalog = catalog ?? const CatalogRepo(),
       _cart = cart ?? const CartRepo(),
       _fav = favorites ?? const FavoriteRepo(),
       _settings = settings ?? const SettingsRepo();

  final CatalogRepo _catalog;
  final CartRepo _cart;
  final FavoriteRepo _fav;
  final SettingsRepo _settings;

  CatalogRepo get catalog => _catalog;

  List<Category> _categories = const [];
  List<Product> _products = const [];
  Map<int, int> _countByCat = const {};
  List<CartLine> _cartLines = const [];
  Set<int> _favIds = const {};
  int _uid = 0;
  String _developerName = SettingsRepo.defaultDeveloper;
  String _storeName = SettingsRepo.defaultStore;
  bool _loaded = false;

  List<Category> get categories => _categories;
  List<Product> get products => _products;
  List<Product> get featured => _products.where((p) => p.featured).toList();
  List<Product> get discounted =>
      _products.where((p) => p.hasDiscount).toList();
  List<Product> get newest {
    final l = [..._products]..sort((a, b) => b.id.compareTo(a.id));
    return l.take(8).toList();
  }

  Map<int, int> get countByCategory => _countByCat;
  List<CartLine> get cart => _cartLines;
  int get cartCount => _cartLines.fold(0, (s, l) => s + l.qty);
  double get cartSubtotal => _cartLines.fold(0.0, (s, l) => s + l.total);
  Set<int> get favoriteIds => _favIds;
  bool get loaded => _loaded;
  String get developerName => _developerName;
  String get storeName => _storeName;

  Category? categoryOf(int id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Product? productOf(int id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool isFavorite(int productId) => _favIds.contains(productId);
  bool inCart(int productId) =>
      _cartLines.any((l) => l.product.id == productId);

  // ------------------------------------------------------------ تحميل
  Future<void> load() async {
    _categories = await _catalog.categories();
    _products = await _catalog.products();
    _countByCat = await _catalog.countByCategory();
    _developerName = await _settings.get(
      SettingsRepo.developerName,
      SettingsRepo.defaultDeveloper,
    );
    _storeName = await _settings.get(
      SettingsRepo.storeName,
      SettingsRepo.defaultStore,
    );
    _loaded = true;
    notifyListeners();
  }

  Future<void> refreshCatalog() async {
    _products = await _catalog.products();
    _categories = await _catalog.categories();
    _countByCat = await _catalog.countByCategory();
    if (_uid != 0) _cartLines = await _cart.lines(_uid);
    notifyListeners();
  }

  /// ربط السلة والمفضلة بالمستخدم الحالي
  Future<void> bind(int uid) async {
    _uid = uid;
    if (uid == 0) {
      _cartLines = const [];
      _favIds = const {};
    } else {
      _cartLines = await _cart.lines(uid);
      _favIds = await _fav.ids(uid);
    }
    notifyListeners();
  }

  // ------------------------------------------------------------ السلة
  Future<void> addToCart(Product p, {int qty = 1}) async {
    if (_uid == 0) return;
    await _cart.add(_uid, p.id, qty: qty);
    _cartLines = await _cart.lines(_uid);
    notifyListeners();
  }

  Future<void> setQty(CartLine line, int qty) async {
    await _cart.setQty(line.id, qty);
    _cartLines = await _cart.lines(_uid);
    notifyListeners();
  }

  Future<void> removeLine(CartLine line) async {
    await _cart.remove(line.id);
    _cartLines = await _cart.lines(_uid);
    notifyListeners();
  }

  Future<void> clearCart() async {
    await _cart.clear(_uid);
    _cartLines = const [];
    notifyListeners();
  }

  // ------------------------------------------------------------ المفضلة
  Future<bool> toggleFavorite(Product p) async {
    if (_uid == 0) return false;
    final added = await _fav.toggle(_uid, p.id);
    _favIds = await _fav.ids(_uid);
    notifyListeners();
    return added;
  }

  Future<List<Product>> favoriteProducts() => _fav.products(_uid);

  // ------------------------------------------------------------ منتجات البائع
  Future<Product> addProduct(Product p) async {
    final saved = await _catalog.insertProduct(p);
    await refreshCatalog();
    return saved;
  }

  Future<void> updateProduct(Product p) async {
    await _catalog.updateProduct(p);
    await refreshCatalog();
  }

  Future<void> deleteProduct(int id) async {
    await _catalog.deleteProduct(id);
    await refreshCatalog();
  }

  // ------------------------------------------------------------ إعدادات
  Future<void> setDeveloperName(String v) async {
    await _settings.set(SettingsRepo.developerName, v);
    _developerName = v.trim();
    notifyListeners();
  }

  Future<void> setStoreName(String v) async {
    await _settings.set(SettingsRepo.storeName, v);
    _storeName = v.trim();
    notifyListeners();
  }
}

/// حاوية الحالة: تُبنى مرة واحدة فوق MaterialApp وتُقرأ بـ AppScope.of(context)
class AppScope extends InheritedNotifier<_ScopeNotifier> {
  AppScope({
    super.key,
    required Session session,
    required Store store,
    required super.child,
  }) : super(notifier: _ScopeNotifier(session, store));

  static Session sessionOf(BuildContext c, {bool listen = true}) =>
      _get(c, listen).session;
  static Store storeOf(BuildContext c, {bool listen = true}) =>
      _get(c, listen).store;

  static _ScopeNotifier _get(BuildContext c, bool listen) {
    final w = listen
        ? c.dependOnInheritedWidgetOfExactType<AppScope>()
        : c.getInheritedWidgetOfExactType<AppScope>();
    assert(w != null, 'AppScope غير موجود في الشجرة');
    return w!.notifier!;
  }
}

/// يجمع إشعارات Session و Store في مُخطِر واحد
class _ScopeNotifier extends ChangeNotifier {
  _ScopeNotifier(this.session, this.store) {
    session.addListener(notifyListeners);
    store.addListener(notifyListeners);
  }
  final Session session;
  final Store store;

  @override
  void dispose() {
    session.removeListener(notifyListeners);
    store.removeListener(notifyListeners);
    super.dispose();
  }
}
