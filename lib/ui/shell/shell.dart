// ============================================================
// YECO - الهيكل الرئيسي: 4 تبويبات سفلية، كل تبويب بـ Navigator مستقل
// زر الرجوع: يعود صفحة داخل التبويب → ثم إلى الرئيسية → ثم حوار خروج
// للبائع يظهر تبويب "متجري" بدل "المفضلة"
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../state/store.dart';
import '../account/account_page.dart';
import '../cart/cart_page.dart';
import '../catalog/categories_page.dart';
import '../catalog/home_page.dart';
import '../favorites/favorites_page.dart';
import '../seller/seller_dashboard_page.dart';

enum ShellTab { home, categories, cart, fourth }

/// يتيح لأي صفحة عميقة التبديل إلى تبويب آخر (مثل: "اشترِ الآن" → السلة)
class ShellController extends InheritedWidget {
  const ShellController({super.key, required this.go, required super.child});
  final void Function(ShellTab tab) go;

  static ShellController? maybeOf(BuildContext c) =>
      c.getInheritedWidgetOfExactType<ShellController>();

  @override
  bool updateShouldNotify(ShellController old) => false;
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  ShellTab _tab = ShellTab.home;
  final _keys = {
    for (final t in ShellTab.values) t: GlobalKey<NavigatorState>(),
  };

  void _go(ShellTab t) {
    if (t == _tab) {
      _keys[t]!.currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _tab = t);
    }
  }

  Future<void> _onBack() async {
    final nav = _keys[_tab]!.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return;
    }
    if (_tab != ShellTab.home) {
      setState(() => _tab = ShellTab.home);
      return;
    }
    final exit = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('الخروج من YECO؟'),
        content: const Text('هل تريد إغلاق التطبيق؟ سلتك ومفضلتك محفوظة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('البقاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (exit == true) SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.sessionOf(context);
    final store = AppScope.storeOf(context);
    final seller = session.isSeller;

    return ShellController(
      go: _go,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onBack();
        },
        child: Scaffold(
          body: IndexedStack(
            index: _tab.index,
            children: [
              _tabNav(ShellTab.home, const HomePage()),
              _tabNav(ShellTab.categories, const CategoriesPage()),
              _tabNav(ShellTab.cart, const CartPage()),
              _tabNav(
                ShellTab.fourth,
                seller ? const SellerDashboardPage() : const FavoritesPage(),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab.index,
            onDestinationSelected: (i) => _go(ShellTab.values[i]),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'الرئيسية',
              ),
              const NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'التصنيفات',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: store.cartCount > 0,
                  label: Text('${store.cartCount}'),
                  backgroundColor: YecoColors.accent,
                  textColor: YecoColors.ink,
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: store.cartCount > 0,
                  label: Text('${store.cartCount}'),
                  backgroundColor: YecoColors.accent,
                  textColor: YecoColors.ink,
                  child: const Icon(Icons.shopping_cart_rounded),
                ),
                label: 'السلة',
              ),
              seller
                  ? const NavigationDestination(
                      icon: Icon(Icons.storefront_outlined),
                      selectedIcon: Icon(Icons.storefront_rounded),
                      label: 'متجري',
                    )
                  : NavigationDestination(
                      icon: Badge(
                        isLabelVisible: store.favoriteIds.isNotEmpty,
                        label: Text('${store.favoriteIds.length}'),
                        child: const Icon(Icons.favorite_outline_rounded),
                      ),
                      selectedIcon: const Icon(Icons.favorite_rounded),
                      label: 'المفضلة',
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabNav(ShellTab t, Widget root) => Navigator(
    key: _keys[t],
    onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => root),
  );
}

/// زر الحساب في أعلى الصفحات (يفتح صفحة حسابي داخل التبويب الحالي)
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});
  @override
  Widget build(BuildContext context) {
    final u = AppScope.sessionOf(context).user;
    final initial = (u?.name.isNotEmpty ?? false)
        ? u!.name.characters.first
        : '?';
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountPage()),
        ),
        child: CircleAvatar(
          radius: 19,
          backgroundColor: YecoColors.primaryLight,
          child: Text(
            initial,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: YecoColors.primaryDark,
            ),
          ),
        ),
      ),
    );
  }
}
