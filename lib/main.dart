// ============================================================
// YECO - تطبيق تسويق وبيع منتجات
// أثاث · مواد غذائية · إلكترونيات · ملابس · منزل ومطبخ · رياضة
// بدورَي زبون وبائع، سلة وطلبات، قاعدة بيانات SQLite محلية
//
// المسار عند التشغيل: ترخيص بعيد → جلسة → الهيكل الرئيسي
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme.dart';
import 'data/db.dart';
import 'security/license_gate.dart';
import 'state/session.dart';
import 'state/store.dart';
import 'ui/auth/sign_in_page.dart';
import 'ui/lock/locked_page.dart';
import 'ui/shell/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  await YecoDb.instance.open();
  runApp(YecoApp(session: Session(), store: Store()));
}

class YecoApp extends StatelessWidget {
  const YecoApp({
    super.key,
    required this.session,
    required this.store,
    this.skipLicense = false,
  });
  final Session session;
  final Store store;

  /// للاختبارات: تجاوز بوابة الترخيص
  final bool skipLicense;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      session: session,
      store: store,
      child: MaterialApp(
        title: 'YECO',
        debugShowCheckedModeBanner: false,
        theme: buildYecoTheme(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: Gate(skipLicense: skipLicense),
      ),
    );
  }
}

/// البوابة: ترخيص → جلسة → الهيكل
class Gate extends StatefulWidget {
  const Gate({super.key, this.skipLicense = false});
  final bool skipLicense;

  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  LicenseVerdict? _verdict;
  bool _ready = false;
  int _boundUid = -1;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final verdict = widget.skipLicense
        ? (state: LicenseState.active, message: '', offline: false)
        : await LicenseGate.check();
    if (!mounted) return;
    final session = AppScope.sessionOf(context, listen: false);
    final store = AppScope.storeOf(context, listen: false);
    await session.restore();
    await store.load();
    if (!mounted) return;
    setState(() {
      _verdict = verdict;
      _ready = true;
    });
  }

  void _bind(Session s, Store store) {
    final uid = s.signedIn ? s.uid : 0;
    if (uid == _boundUid) return;
    _boundUid = uid;
    store.bind(uid);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SplashView();
    if (_verdict!.state != LicenseState.active) {
      return LockedPage(
        verdict: _verdict!,
        onGranted: () => setState(
          () => _verdict = (
            state: LicenseState.active,
            message: '',
            offline: false,
          ),
        ),
      );
    }
    final session = AppScope.sessionOf(context);
    final store = AppScope.storeOf(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bind(session, store));
    if (!session.signedIn) return const SignInPage();
    return const Shell();
  }
}

class SplashView extends StatelessWidget {
  const SplashView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: YecoColors.primaryDark,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/brand/logo_rounded.png', width: 110, height: 110),
          const SizedBox(height: 18),
          const Text(
            'YECO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          Text(
            'تسوّق بذكاء',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 28),
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}
