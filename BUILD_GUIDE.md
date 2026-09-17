# دليل البناء — YECO

> لأي شخص يحمّل المستودع ويريد **تشغيل التطبيق أو إنتاج ملف APK بنفسه** خطوة بخطوة.
> آخر APK جاهز موجود في [`releases/YECO-v1.0.0.apk`](releases/YECO-v1.0.0.apk) — إن أردت التثبيت فقط بلا بناء، حمّله من هناك.

---

## 0. ما الموجود في المستودع؟

| المسار | الغرض |
|---|---|
| `releases/YECO-v1.0.0.apk` | **آخر إصدار جاهز للتثبيت** (android-arm64، موقّع بمفتاح الإصدار، مع إعداد SMTP) |
| `lib/` | كود التطبيق (40 ملف Dart) — انظر [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) |
| `lib/security/` | الترخيص البعيد، محرك OTP، SMTP، تجزئة كلمات المرور |
| `tool/build_release.sh` | يبني APK ويمرّر إعدادات البريد من `android/smtp.properties` (§3.د) |
| `android/smtp.properties.example` | نموذج إعدادات البريد — انسخه إلى `android/smtp.properties` (مُتجاهَل في git) |
| `test/` | 3 ملفات اختبار (33 اختباراً): `security_test`, `repos_test`, `screens_test` + `helpers` + `live_license_test` (يدوي ضد GitHub الحقيقي) |
| `assets/` | 24 صورة منتج + 6 صور تصنيف + شعار + خط Tajawal |
| `android/` | مشروع أندرويد (الحزمة `com.yecomarket.shop`) — **أندرويد فقط، لا iOS ولا ويب** |
| `license.json` | **ملف التحكم عن بُعد** — يقرأه التطبيق عند كل تشغيل (§6) |
| `docs/make_assets.py` | سكربت توليد صور المنتجات وأيقونة الإطلاق المتكيّفة (وقت التطوير فقط) |
| `docs/SESSION_LOG.md` | سجل التطوير: الطلبات، القرارات، المشاكل وحلولها، ما تم التحقق منه |
| `docs/RELEASE_NOTES_1.0.0.md` | ملاحظات الإصدار |
| `CHANGELOG.md` | سجل كل الإصدارات |

---

## 1. المتطلبات

| الأداة | الإصدار | ملاحظة |
|---|---|---|
| Flutter | **3.35.4** (stable) | أي 3.35.x يعمل |
| Dart | 3.9.2 | يأتي مع Flutter |
| Java (JDK) | **17** | لا تستخدم 21 |
| Android SDK | compileSdk 36 / Build-Tools 35.0.0 | من Android Studio → SDK Manager |

```bash
flutter --version && java -version && flutter doctor
```

---

## 2. تحميل وتشغيل

```bash
git clone https://github.com/moain2026/Flutter-Native-App-044.git
cd Flutter-Native-App-044
flutter pub get
flutter analyze          # No issues found!
flutter test             # 33 tests passed
flutter run              # جهاز/محاكي أندرويد
```

> المشروع أندرويد فقط؛ `flutter run -d chrome` لن يعمل (حزمتا `sqflite` و`mailer` تعتمدان على المنصة). هذا مقصود لتقليل حجم التطبيق.

---

## 3. بناء APK

### 3.أ — بمفتاح التوقيع الأصلي (نفس مفتاح الإصدار المنشور)
يلزمك ملفان **غير مضمّنين في المستودع** (في `.gitignore`):
```
android/release-key.jks
android/key.properties
```
شكل `android/key.properties`:
```properties
storePassword=********
keyPassword=********
keyAlias=release
storeFile=../release-key.jks
```
> اطلبهما من صاحب المشروع. **لتثبيت تحديث فوق نسخة مثبّتة يجب نفس المفتاح**، وإلا يطلب أندرويد حذف التطبيق أولاً.

### 3.ب — بلا مفتاح؟ أنشئ واحداً
```bash
keytool -genkey -v -keystore android/release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release
```
ثم أنشئ `android/key.properties` كما أعلاه.

### 3.ج — للتجربة فقط
```bash
flutter build apk --debug
```

### 3.د — إعدادات البريد (مطلوبة لإرسال رموز التحقق)
التطبيق يرسل رموز OTP عبر Gmail SMTP. البيانات **لا تُكتب في الكود** بل تُمرّر وقت البناء:
```bash
cp android/smtp.properties.example android/smtp.properties   # ثم ضع بريد Gmail + App Password
./tool/build_release.sh            # pub get + analyze + build apk --release (arm64) مع --dart-define
./tool/build_release.sh --all      # كل المعالجات في ملف واحد (أكبر حجماً)
./tool/build_release.sh --split    # ملف لكل معمارية
```
أو يدوياً:
```bash
flutter build apk --release --target-platform android-arm64 \
  --dart-define=SMTP_USER=you@gmail.com --dart-define="SMTP_PASS=xxxx xxxx xxxx xxxx" \
  --dart-define=SMTP_PORT=465 --dart-define=SMTP_NAME=YECO
```
> **App Password**: Google Account → Security → 2-Step Verification → App passwords. لا تستخدم كلمة مرور الحساب.
> بدون هذه الإعدادات يُبنى التطبيق ويعمل كاملاً، لكن الرمز **يُعرض داخل التطبيق مع زر نسخ** بدل إرساله بالبريد (وضع المعاينة) — التدفق لا يتعطل أبداً.

### التحقق والتثبيت
```bash
$ANDROID_HOME/build-tools/35.0.0/apksigner verify --print-certs releases/YECO-v1.0.0.apk
$ANDROID_HOME/build-tools/35.0.0/aapt dump badging releases/YECO-v1.0.0.apk | grep -E "^package|application-label"
adb install -r releases/YECO-v1.0.0.apk
```

---

## 4. إصدار نسخة جديدة

1. عدّل الكود.
2. `pubspec.yaml` → `version: X.Y.Z+N` — **N (versionCode) يجب أن يزيد** كل إصدار.
3. حدّث `appVersion`/`appBuild` في `lib/ui/account/about_page.dart`.
4. `flutter analyze && flutter test`.
5. `./tool/build_release.sh` → ينسخ الناتج تلقائياً إلى `releases/YECO-vX.Y.Z.apk`.
6. حدّث `docs/RELEASE_NOTES_X.Y.Z.md` + `CHANGELOG.md` + `README.md`.
7. `git add -A && git commit -m "vX.Y.Z: ..." && git tag vX.Y.Z && git push origin main --tags`.

---

## 5. أخطاء شائعة

| الخطأ | السبب | الحل |
|---|---|---|
| `Keystore file not found` | ملفا التوقيع غير موجودين | §3.أ أو §3.ب |
| Gradle يفشل بـ `Unsupported class file major version` | JDK 21 | ثبّت JDK 17 واضبط `JAVA_HOME` |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | مفتاح توقيع مختلف | احذف القديم أو استخدم المفتاح الأصلي |
| `INSTALL_FAILED_VERSION_DOWNGRADE` | versionCode لم يزد | ارفع الرقم بعد `+` |
| شاشة "النسخة موقوفة نهائياً" | `license.json` غير موجود على GitHub (404) | أعِد الملف إلى جذر `main` |
| "التطبيق يحتاج تفعيل" | `active: false` في `license.json` | أدخل `code` أو غيّره إلى `true` |
| الرمز يُعرض داخل التطبيق بدل البريد | APK بُني بدون `--dart-define=SMTP_*` | §3.د |
| "رُفض الدخول إلى خادم البريد" | كلمة مرور الحساب بدل App Password أو أُلغيت | أنشئ App Password جديدة وأعِد البناء |
| الرمز لم يصل | تأخر Gmail / مجلد Spam | انتظر دقيقة، تحقّق من Spam، أو "إعادة الإرسال" بعد 45 ث |
| الكاميرا لا تعمل في نموذج المنتج | الإذن مرفوض | امنح إذن الكاميرا من إعدادات التطبيق، أو اختر من المعرض |

---

## 6. التحكم عن بُعد (`license.json`)

يقرأ التطبيق `https://github.com/moain2026/Flutter-Native-App-044/blob/main/license.json` عند كل تشغيل (GitHub Contents API أولاً — بلا كاش — ثم الملف الخام كاحتياط).

```json
{ "active": true, "code": "YECO-2026", "message": "رسالة تظهر عند القفل" }
```

| تريد | افعل | النتيجة |
|---|---|---|
| تشغيل عادي | `"active": true` | يدخل مباشرة |
| إيقاف مع كود | `"active": false` + `code` | شاشة قفل تطلب الكود؛ بعد نجاحه يُحفظ ويفتح تلقائياً **ما لم تغيّر الكود** |
| تغيير كلمة التفعيل | غيّر `code` | كل من فتح بالكود القديم يُقفل مجدداً حتى يُدخل الجديد |
| إيقاف نهائي | **احذف الملف** | "موقوف نهائياً" — لا يقبل أي كود |
| بلا إنترنت | — | آخر حالة محفوظة (أول تشغيل بلا إنترنت = مفعّل) |

التعديل يصل خلال ثوانٍ. الشيفرة في `lib/security/license_gate.dart` ومغطّاة بـ 6 اختبارات.

---

## 7. رموز التحقق عبر البريد

| العنصر | القيمة |
|---|---|
| الرمز | 6 أرقام عشوائية (`Random.secure`) |
| الصلاحية | 10 دقائق |
| المحاولات | 5 ثم يُلغى الرمز |
| إعادة الإرسال | بعد 45 ثانية |
| التخزين | SHA-256(salt\|code\|email\|purpose) في SharedPreferences — يبقى صالحاً بعد الخروج إلى تطبيق البريد والعودة |
| المُرسِل | Gmail SMTP `smtp.gmail.com:465` (SSL) بحزمة `mailer` |
| الاستخدام | **تسجيل الدخول** (تحقق ثانٍ، قابل للإيقاف من الإعدادات) + **إنشاء الحساب** (الحساب لا يُنشأ قبل التحقق) + **استعادة كلمة المرور** |

الشيفرة: `lib/security/otp_engine.dart` (المحرك + قالب HTML/نص)، `lib/security/mailer_service.dart` (النقل)، `lib/ui/auth/otp_panel.dart` (الواجهة).
