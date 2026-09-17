# YECO — الوثيقة المعمارية (Architecture)

> تطبيق تسويق وبيع منتجات — مشروع مقرر Flutter — الطالب: **جواد**
> الحزمة: `com.yecomarket.shop` · Flutter 3.35.4 / Dart 3.9.2 · Material 3 · RTL · **أندرويد فقط**

---

## 1. الفكرة

متجر إلكتروني محلي بالكامل (SQLite) بدورَين:

| الدور | القدرات |
|---|---|
| **زبون** | تصفح 6 تصنيفات (أثاث، مواد غذائية، إلكترونيات، ملابس، منزل ومطبخ، رياضة)، بحث وتصفية وترتيب، تفاصيل المنتج، مفضلة، سلة بكوبونات، إتمام طلب، تتبع/إلغاء الطلبات، مراجعات، حسابي |
| **بائع** | كل ما سبق للعرض + لوحة إحصاءات، إضافة/تعديل/حذف منتجات (مع صورة من المعرض/الكاميرا)، إدارة كل الطلبات وتغيير حالتها |

المصادقة بالبريد الإلكتروني: **يُدخل المستخدم بريده أولاً** — إن كان مسجّلاً يُطلب كلمة المرور ثم يُرسل رمز تحقق إلى بريده؛ وإن لم يكن مسجّلاً ينتقل تلقائياً لإنشاء حساب بالبريد نفسه (الحساب لا يُنشأ قبل تأكيد الرمز). "نسيت كلمة المرور" ترسل رمزاً إلى البريد ثم تُحدّث كلمة المرور فعلياً في SQLite.

---

## 2. خريطة الشاشات (20 شاشة + القفل)

```
بوابة الترخيص (LockedPage)
   └─► تسجيل الدخول (بريد → كلمة مرور → رمز)  ──► إنشاء حساب (بيانات → رمز → إنشاء)
                                              └─► نسيت كلمة المرور (بريد → رمز → كلمة جديدة)
                                                        ▼
                     Shell (4 تبويبات سفلية، كل تبويب Navigator مستقل + PopScope)
   ├─ الرئيسية ── بحث ── قائمة المنتجات ── تفاصيل المنتج (+ مراجعات CRUD) ── السلة
   │        └─ حسابي ── طلباتي ── تفاصيل الطلب / تعديل البيانات / كلمة المرور / الإعدادات / حول
   ├─ التصنيفات ── قائمة منتجات التصنيف ── التفاصيل
   ├─ السلة ── إتمام الطلب ── تفاصيل الطلب
   └─ المفضلة (زبون)  |  متجري (بائع) ── إدارة المنتجات ── نموذج منتج · إدارة الطلبات ── تفاصيل الطلب
```

**غير المصادقة:** الرئيسية، التصنيفات، قائمة المنتجات، تفاصيل المنتج، السلة، إتمام الطلب، الطلبات، تفاصيل الطلب، المفضلة، حسابي، تعديل البيانات، تغيير كلمة المرور، الإعدادات، حول، لوحة البائع، إدارة المنتجات، نموذج المنتج = **17 شاشة** (المطلوب ≥ 5).

---

## 3. طبقات الكود (40 ملف Dart)

```
lib/
├── main.dart                      YecoApp + Gate (ترخيص ← جلسة ← Shell) + Splash
├── core/theme.dart                YecoColors (زمردي/كهرماني) + buildYecoTheme() + خط Tajawal
├── models/models.dart             AppUser, UserRole, Category, Product, CartLine, Order, OrderLine, OrderStatus, Review, Coupon
├── data/
│   ├── db.dart                    YecoDb — المخطط (9 جداول) + البذر عند onCreate
│   ├── seed.dart                  6 تصنيفات × 4 = 24 منتجاً بأوصاف وأسعار واقعية
│   └── repos.dart                 UserRepo, CatalogRepo, CartRepo, FavoriteRepo, OrderRepo (+stats), ReviewRepo, SettingsRepo
├── state/
│   ├── session.dart               Session (ChangeNotifier): lookup/checkPassword/signUp/reset/change/profile
│   └── store.dart                 Store (ChangeNotifier): كتالوج + سلة + مفضلة + إعدادات · AppScope (InheritedNotifier)
├── security/
│   ├── license_gate.dart          بوابة الترخيص عن بُعد (record + enum) — GitHub API → raw
│   ├── otp_engine.dart            OTP 6 أرقام / 10 دقائق / 5 محاولات، SHA-256 مع salt، قوالب البريد
│   ├── mail_config.dart           إعدادات SMTP من --dart-define (لا أسرار في المستودع)
│   ├── mailer_service.dart        SmtpTransport (حزمة mailer) + MailTransport للاختبارات
│   └── password_hasher.dart       PBKDF2-HMAC-SHA256 (12000 دورة) — لا كلمات مرور نصية
└── ui/
    ├── shell/shell.dart           IndexedStack + Navigator/تبويب + PopScope + NavigationBar بشارات + ShellController
    ├── shared/widgets.dart        ProductImage, PriceText, Stars, Pill, StatCard, EmptyState, notify(), confirm(), V (مُدقّقات)
    ├── shared/keyboard_resume_fix.dart
    ├── auth/                      auth_shell, sign_in (3 مراحل), sign_up, recover_password (Stepper), otp_panel
    ├── lock/locked_page.dart
    ├── catalog/                   home, categories, product_list (بحث/تصفية/ترتيب/شبكة-قائمة), product_detail, product_card
    ├── cart/                      cart (Dismissible + كوبون), checkout (Form + RadioGroup)
    ├── orders/                    orders (تصفية بالحالة), order_detail (خط زمني + إلغاء/تغيير الحالة/حذف)
    ├── favorites/favorites_page.dart
    ├── account/                   account, edit_profile, change_password, settings (اسم المطوّر), about
    └── seller/                    seller_dashboard (إحصاءات), seller_products (CRUD), product_form (image_picker)
```

### إدارة الحالة — بلا Provider
`AppScope` هو `InheritedNotifier` يجمع `Session` و`Store` في مُخطِر واحد. أي ويدجت يقرأ `AppScope.storeOf(context)` يُعاد بناؤه عند أي تغيير. هذا اختلاف بنيوي مقصود عن المشاريع السابقة (خدمة واحدة في 011/022، Provider في 033).

---

## 4. قاعدة البيانات SQLite

**المسار:** `getDatabasesPath()/yeco.db` ⇒ `/data/data/com.yecomarket.shop/databases/yeco.db`

| الجدول | الحقول الأساسية | ملاحظات |
|---|---|---|
| `users` | id, name, email UNIQUE, password (PBKDF2), phone, city, role, created_at | role: 0 زبون · 1 بائع |
| `categories` | id, name, slug, color, image, icon | 6 صفوف مبذورة |
| `products` | id, category_id FK, seller_id, name, brand, description, price, old_price, stock, rating, rating_count, image, featured, created_at | 24 مبذورة؛ البائع يضيف/يعدّل/يحذف |
| `cart_items` | user_id FK, product_id FK, qty — UNIQUE(user, product) | UPSERT يجمع الكمية |
| `favorites` | PK(user_id, product_id) | |
| `orders` | user_id FK, customer_name, address, phone, payment, subtotal, discount, delivery, total, status, created_at | status 0..4 |
| `order_items` | order_id FK CASCADE, product_id, name, image, price, qty | لقطة من المنتج وقت الشراء |
| `reviews` | product_id FK, user_id FK, user_name, stars, comment — UNIQUE(product, user) | يُعيد حساب rating للمنتج |
| `app_settings` | key PK, value | `developer_name`, `store_name` — قابلة للتعديل من الإعدادات |

**CRUD موثّق بالاختبارات** (`test/repos_test.dart`): إنشاء/قراءة/تعديل/حذف للمستخدمين والمنتجات والسلة والمفضلة والطلبات والمراجعات والإعدادات، مع `transaction` في checkout/cancel لضبط المخزون.

---

## 5. سلوك زر الرجوع

```
PopScope(canPop:false).onPopInvokedWithResult → Shell._onBack()
  1) Navigator التبويب الحالي يستطيع pop؟ → ارجع صفحة
  2) التبويب ≠ الرئيسية؟                 → انتقل إلى الرئيسية
  3) في الرئيسية                         → حوار "الخروج من YECO؟" → SystemNavigator.pop()
```
مُغطّى باختبار `screens_test.dart › Shell: زر الرجوع خطوة بخطوة ثم حوار خروج`.

---

## 6. الأمان

| العنصر | التنفيذ |
|---|---|
| كلمات المرور | PBKDF2-HMAC-SHA256 × 12000 مع salt عشوائي، مقارنة بزمن ثابت |
| OTP | 6 أرقام `Random.secure`، 10 دقائق، 5 محاولات، إعادة إرسال بعد 45 ث، يُحفظ SHA-256(salt\|code\|email\|purpose) فقط، استخدام لمرة واحدة، عزل الغرض (دخول/إنشاء/استعادة) |
| بيانات SMTP | `--dart-define` وقت البناء من `android/smtp.properties` (مُتجاهَل في git) |
| الترخيص | `license.json` من GitHub — API أولاً (بلا كاش، مع `User-Agent` وإلا 403) ثم raw؛ 404 = قفل نهائي |
| التحقق بخطوتين | مفعّل افتراضياً، قابل للإيقاف من الإعدادات |

---

## 7. الأصول وحجم التطبيق

- 24 صورة منتج JPEG 512×512 (~490 KB إجمالاً) + 6 صور تصنيف (44 KB) + شعار (244 KB) + خط Tajawal بأربع أوزان (248 KB).
- بناء **أندرويد فقط** (`--platforms android`)، `android-arm64` افتراضياً، `minifyEnabled` + `shrinkResources` في release.
- الأيقونة متكيّفة (`mipmap-anydpi-v26`) بطبقتي خلفية/مقدمة — بلا مربعات سوداء.

---

## 8. الاختبارات (33)

| الملف | يغطي |
|---|---|
| `security_test.dart` (15) | الترخيص (6 حالات)، OTP (8)، PBKDF2 |
| `repos_test.dart` (9) | البذر، Session كامل، تفرّد البريد، سلة/مفضلة، checkout/إلغاء/إحصاءات، كوبونات، CRUD منتجات + مراجعات، بحث، إعدادات |
| `screens_test.dart` (9) | لا Overflow على 360×780 لكل الشاشات، تحقق النماذج، الدخول الكامل حتى Shell، زر الرجوع، إضافة إلى السلة |
