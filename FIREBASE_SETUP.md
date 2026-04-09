# إعداد Firebase لـ KMS Fleet
# Firebase Setup Guide for KMS Fleet

## المتطلبات | Prerequisites
- Node.js (لتحميل Firebase CLI)
- حساب Google
- FlutterFire CLI

---

## الخطوة 1: تثبيت الأدوات | Install Tools

```bash
# 1. تثبيت Firebase CLI
npm install -g firebase-tools

# 2. تسجيل الدخول
firebase login

# 3. تثبيت FlutterFire CLI
dart pub global activate flutterfire_cli
```

> **ملاحظة:** تأكد أن `dart` و `flutter` في PATH

---

## الخطوة 2: إنشاء مشروع Firebase | Create Firebase Project

### الطريقة السهلة (موصى بها): Firebase Console
1. افتح https://console.firebase.google.com
2. اضغط "إضافة مشروع" (Add project)
3. اسم المشروع: `kms-fleet`
4. اختر المنطقة: `me-central2` (السعودية) أو أي منطقة قريبة
5. اضغط "إنشاء مشروع"

### الطريقة السريعة: Terminal
```bash
firebase projects:create kms-fleet
```

---

## الخطوة 3: إضافة تطبيق Android | Add Android App

```bash
# من مجلد المشروع kms_fleet
cd C:\Users\Bobab\AndroidStudioProjects\kms_fleet

# تشغيل FlutterFire Configure
flutterfire configure
```

**اختر:**
- Project: `kms-fleet`
- Platforms: `android` (و `windows` إذا أردت)
- Android Package: `com.example.kmsFleet` (أو كما في android/app/build.gradle)

هذا الأمر سيُنشئ:
- ✅ `android/app/google-services.json`
- ✅ `lib/firebase_options.dart` (يستبدل الملف الحالي)

---

## الخطوة 4: تفعيل المصادقة | Enable Authentication

### من Firebase Console:
1. اذهب إلى **Authentication** → **Sign-in method**
2. اضغط على **Email/Password**
3. فعّل **Enable** → **Save**

### أو من Terminal:
```bash
firebase auth:enable email-password --project kms-fleet
```

---

## الخطوة 5: إنشاء قاعدة بيانات Firestore | Create Firestore Database

### من Firebase Console:
1. اذهب إلى **Firestore Database**
2. اضغط **Create database**
3. اختر **Start in test mode** (للتطوير)
4. اختر المنطقة الأقرب (مثلاً `me-central2`)

### أو من Terminal:
```bash
# إنشاء قاعدة بيانات Firestore
firebase firestore:databases:create --project kms-fleet --location me-central2
```

---

## الخطوة 6: إعداد قواعد الأمان | Security Rules

من Firebase Console → Firestore → Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // فقط المسجلين يمكنهم القراءة والكتابة
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## الخطوة 7: تفعيل Firebase في التطبيق | Enable Firebase in App

بعد تشغيل `flutterfire configure`، افتح `lib/firebase_options.dart` وغيّر:

```dart
static const bool isConfigured = true;  // ← غيّر false إلى true
```

---

## الخطوة 8: تشغيل التطبيق | Run App

```bash
# احذف البيانات القديمة (اختياري - لإعادة زراعة البيانات)
# من الهاتف: إعدادات → التطبيقات → KMS Fleet → مسح البيانات

# شغّل التطبيق
flutter run
```

---

## أول مرة: إنشاء حساب المدير

عند فتح التطبيق لأول مرة:
1. ستظهر شاشة "إنشاء حساب المدير"
2. أدخل اسمك وبريدك الإلكتروني وكلمة المرور
3. اضغط "إنشاء حساب المدير"
4. هذا الحساب هو **المدير الوحيد** الذي يستطيع الدخول

---

## استكشاف الأخطاء | Troubleshooting

### خطأ: `google-services.json` not found
```bash
# تأكد أن الملف موجود في:
android/app/google-services.json

# إذا لم يكن موجوداً، أعد تشغيل:
flutterfire configure
```

### خطأ: `Firebase not configured`
```dart
// افتح lib/firebase_options.dart وغيّر:
static const bool isConfigured = true;
```

### خطأ: Windows CMake Warning
هذا تحذير فقط وليس خطأ - التطبيق يعمل بشكل طبيعي.

### خطأ: `Unhandled Exception: [core/not-initialized]`
تأكد أن `Firebase.initializeApp()` يُنفذ في `main.dart` قبل أي استخدام لـ Firebase.

---

## الوضع الأوفلاين | Offline Mode

التطبيق يعمل **100% بدون إنترنت** باستخدام Hive المحلي.
- البيانات تُحفظ محلياً دائماً
- عند اتصال Firebase: البيانات تُزامن مع السحابة
- عند فقدان الاتصال: التطبيق يستمر بالعمل محلياً
