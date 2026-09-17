// اختبارات الواجهة على جوال 360×780: لا Overflow، التدفقات الأساسية تعمل
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeco_market/main.dart';
import 'package:yeco_market/models/models.dart';
import 'package:yeco_market/security/license_gate.dart';
import 'package:yeco_market/state/session.dart';
import 'package:yeco_market/state/store.dart';
import 'package:yeco_market/ui/account/about_page.dart';
import 'package:yeco_market/ui/account/account_page.dart';
import 'package:yeco_market/ui/account/settings_page.dart';
import 'package:yeco_market/ui/auth/recover_password_page.dart';
import 'package:yeco_market/ui/auth/sign_in_page.dart';
import 'package:yeco_market/ui/auth/sign_up_page.dart';
import 'package:yeco_market/ui/cart/cart_page.dart';
import 'package:yeco_market/ui/catalog/categories_page.dart';
import 'package:yeco_market/ui/catalog/home_page.dart';
import 'package:yeco_market/ui/catalog/product_detail_page.dart';
import 'package:yeco_market/ui/catalog/product_list_page.dart';
import 'package:yeco_market/ui/lock/locked_page.dart';
import 'package:yeco_market/ui/orders/orders_page.dart';
import 'package:yeco_market/ui/seller/product_form_page.dart';
import 'package:yeco_market/ui/seller/seller_dashboard_page.dart';
import 'package:yeco_market/ui/shell/shell.dart';

import 'helpers.dart';

Future<(Session, Store)> signedIn(
  WidgetTester t, {
  UserRole role = UserRole.customer,
}) async {
  return real(t, () async {
    final s = Session();
    await s.signUp(
      name: 'جواد العبسي',
      email: 'j@yeco.app',
      password: 'Pass123',
      phone: '0500000000',
      city: 'صنعاء',
      role: role,
    );
    final st = Store();
    await st.load();
    await st.bind(s.uid);
    return (s, st);
  });
}

Future<void> pumpAll(
  WidgetTester t,
  Widget w, {
  Session? session,
  Store? store,
}) async {
  await t.pumpWidget(wrapApp(w, session: session, store: store));
  await t.pump(const Duration(milliseconds: 100));
  await t.pump(const Duration(milliseconds: 400));
}

void main() {
  setUp(() async {
    await resetPrefs();
    await openTestDb();
    installFakeMail();
  });

  group('تخطيط بلا Overflow على 360×780', () {
    testWidgets('شاشات المصادقة', (t) async {
      setPhoneSize(t);
      await pumpAll(t, const SignInPage());
      expect(find.text('مرحباً بك في YECO'), findsOneWidget);
      await pumpAll(t, const SignUpPage());
      expect(find.text('إنشاء حساب جديد'), findsOneWidget);
      await pumpAll(t, const RecoverPasswordPage(initialEmail: 'a@b.com'));
      expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('شاشة القفل (مقفول وموقوف)', (t) async {
      setPhoneSize(t);
      await pumpAll(
        t,
        LockedPage(
          verdict: (
            state: LicenseState.locked,
            message: 'رسالة القفل',
            offline: false,
          ),
          onGranted: () {},
        ),
      );
      expect(find.text('تفعيل'), findsOneWidget);
      await pumpAll(
        t,
        LockedPage(
          verdict: (state: LicenseState.revoked, message: 'x', offline: true),
          onGranted: () {},
        ),
      );
      expect(find.text('النسخة موقوفة نهائياً'), findsOneWidget);
      expect(find.text('تفعيل'), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets(
      'شاشات الزبون: رئيسية، تصنيفات، قائمة، تفاصيل، سلة، حسابي، حول، إعدادات',
      (t) async {
        setPhoneSize(t);
        final (s, st) = await signedIn(t);
        await pumpAll(t, const HomePage(), session: s, store: st);
        expect(find.textContaining('مرحباً جواد'), findsOneWidget);
        expect(find.text('منتجات مميزة'), findsOneWidget);
        await pumpAll(t, const CategoriesPage(), session: s, store: st);
        expect(find.text('الأثاث'), findsOneWidget);
        await pumpAll(
          t,
          ProductListPage(category: st.categories[1]),
          session: s,
          store: st,
        );
        expect(find.text('4 منتج'), findsOneWidget);
        await pumpAll(
          t,
          ProductDetailPage(productId: st.products.first.id),
          session: s,
          store: st,
        );
        expect(find.text('اشترِ الآن'), findsOneWidget);
        await pumpAll(t, const CartPage(), session: s, store: st);
        expect(find.text('سلتك فارغة'), findsOneWidget);
        await pumpAll(t, const AccountPage(), session: s, store: st);
        expect(find.text('طلباتي'), findsOneWidget);
        await pumpAll(t, const AboutPage(), session: s, store: st);
        expect(
          find.text('الإصدار $appVersion (build $appBuild)'),
          findsOneWidget,
        );
        expect(find.text('جواد'), findsOneWidget);
        await pumpAll(t, const SettingsPage(), session: s, store: st);
        expect(find.text('اسم المطوّر'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets('شاشات البائع: لوحة، نموذج منتج، طلبات', (t) async {
      setPhoneSize(t);
      final (s, st) = await signedIn(t, role: UserRole.seller);
      await t.pumpWidget(
        wrapApp(const SellerDashboardPage(), session: s, store: st),
      );
      await real(
        t,
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await t.pumpAndSettle();
      expect(find.text('الإيرادات'), findsOneWidget);
      await pumpAll(t, const ProductFormPage(), session: s, store: st);
      expect(find.text('منتج جديد'), findsOneWidget);
      expect(find.text('إضافة المنتج', skipOffstage: false), findsOneWidget);
      await pumpAll(
        t,
        ProductFormPage(product: st.products.first),
        session: s,
        store: st,
      );
      expect(find.text('تعديل المنتج'), findsOneWidget);
      expect(find.text('حفظ التعديلات', skipOffstage: false), findsOneWidget);
      await t.pumpWidget(
        wrapApp(const OrdersPage(sellerView: true), session: s, store: st),
      );
      await real(
        t,
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await t.pumpAndSettle();
      expect(find.text('لا توجد طلبات بعد'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('التدفقات', () {
    testWidgets('التحقق من صحة نموذج إنشاء الحساب', (t) async {
      setPhoneSize(t);
      await pumpAll(t, const SignUpPage());
      await t.ensureVisible(find.text('إرسال رمز التحقق'));
      await t.pumpAndSettle();
      await t.tap(find.text('إرسال رمز التحقق'));
      await t.pump();
      await t.ensureVisible(find.widgetWithText(TextFormField, 'الاسم الكامل'));
      await t.pumpAndSettle();
      expect(find.text('الاسم مطلوب'), findsOneWidget);
      expect(find.text('البريد الإلكتروني مطلوب'), findsOneWidget);
      expect(find.text('كلمة المرور مطلوبة'), findsOneWidget);
      await t.enterText(
        find.widgetWithText(TextFormField, 'البريد الإلكتروني'),
        'bad-email',
      );
      await t.enterText(
        find.widgetWithText(TextFormField, 'كلمة المرور'),
        '123',
      );
      await t.pump();
      expect(find.textContaining('صيغة البريد غير صحيحة'), findsOneWidget);
      expect(find.textContaining('كلمة المرور قصيرة'), findsOneWidget);
    });

    testWidgets('الدخول: بريد غير مسجّل → إنشاء حساب بالبريد نفسه', (t) async {
      setPhoneSize(t);
      await pumpAll(t, const SignInPage());
      await t.enterText(find.byType(TextFormField), 'new@yeco.app');
      await real(t, () async {
        await t.tap(find.text('متابعة'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await t.pumpAndSettle();
      expect(find.text('إنشاء حساب جديد'), findsOneWidget);
      final email = t.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'البريد الإلكتروني'),
      );
      expect(email.controller!.text, 'new@yeco.app');
    });

    testWidgets('الدخول الكامل: بريد → كلمة مرور → رمز (معاينة) → Shell', (
      t,
    ) async {
      setPhoneSize(t);
      final s = await real(t, () async {
        final s = Session();
        await s.signUp(
          name: 'جواد',
          email: 'j@yeco.app',
          password: 'Pass123',
          phone: '1',
          city: 'x',
          role: UserRole.customer,
        );
        await s.signOut();
        return s;
      });
      final st = Store();
      await real(t, st.load);
      await t.pumpWidget(YecoApp(session: s, store: st, skipLicense: true));
      await real(
        t,
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await t.pumpAndSettle();
      expect(find.text('مرحباً بك في YECO'), findsOneWidget);

      await t.enterText(find.byType(TextFormField), 'j@yeco.app');
      await real(t, () async {
        await t.tap(find.text('متابعة'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await t.pumpAndSettle();
      expect(find.text('أهلاً بعودتك'), findsOneWidget);

      await t.enterText(find.byType(TextFormField), 'Pass123');
      await real(t, () async {
        await t.tap(find.text('تسجيل الدخول'));
        await Future<void>.delayed(const Duration(milliseconds: 600));
      });
      await t.pumpAndSettle();
      expect(find.text('تحقق من بريدك'), findsOneWidget);
      // بلا SMTP في الاختبار → الرمز معروض داخل التطبيق
      final codeText = t
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .firstWhere((d) => RegExp(r'^\d{6}$').hasMatch(d));
      await t.enterText(find.byType(TextField).first, codeText);
      await real(t, () async {
        await t.tap(find.text('تأكيد والدخول'));
        await Future<void>.delayed(const Duration(milliseconds: 600));
      });
      await t.pumpAndSettle();
      expect(find.byType(Shell), findsOneWidget);
      expect(s.signedIn, isTrue);
    });

    testWidgets('Shell: زر الرجوع خطوة بخطوة ثم حوار خروج', (t) async {
      setPhoneSize(t);
      final (s, st) = await signedIn(t);
      await t.pumpWidget(YecoApp(session: s, store: st, skipLicense: true));
      await real(
        t,
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await t.pumpAndSettle();
      expect(find.byType(Shell), findsOneWidget);

      // تبويب التصنيفات → افتح تصنيفاً
      await t.tap(find.text('التصنيفات'));
      await t.pumpAndSettle();
      await t.tap(find.text('الإلكترونيات'));
      await t.pumpAndSettle();
      expect(find.text('4 منتج'), findsOneWidget);

      // رجوع 1: يعود إلى شبكة التصنيفات (لا يخرج)
      final shell = find.byWidgetPredicate((w) => w is PopScope && w.canPop == false).first;
      (t.widget(shell) as PopScope).onPopInvokedWithResult!(false, null);
      await t.pumpAndSettle();
      expect(find.text('4 منتج'), findsNothing);
      expect(find.text('الأثاث'), findsOneWidget);

      // رجوع 2: إلى الرئيسية
      (t.widget(shell) as PopScope).onPopInvokedWithResult!(false, null);
      await t.pumpAndSettle();
      expect(find.text('منتجات مميزة'), findsOneWidget);

      // رجوع 3: حوار الخروج
      (t.widget(shell) as PopScope).onPopInvokedWithResult!(false, null);
      await t.pumpAndSettle();
      expect(find.text('الخروج من YECO؟'), findsOneWidget);
      await t.tap(find.text('البقاء'));
      await t.pumpAndSettle();
      expect(find.byType(Shell), findsOneWidget);
    });

    testWidgets('سلة: إضافة من التفاصيل → السلة تعرض المنتج والإجمالي', (
      t,
    ) async {
      setPhoneSize(t);
      final (s, st) = await signedIn(t);
      final p = st.products.first;
      await pumpAll(
        t,
        ProductDetailPage(productId: p.id),
        session: s,
        store: st,
      );
      await real(t, () async {
        await t.tap(find.text('أضف'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await t.pump();
      expect(find.textContaining('إلى السلة'), findsOneWidget); // SnackBar
      expect(st.cartCount, 1);
      await pumpAll(t, const CartPage(), session: s, store: st);
      expect(find.text('السلة (1)'), findsOneWidget);
      expect(find.text('إتمام الطلب'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });
}
