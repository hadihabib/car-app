# تطبيق لوحة المحل

المشروع يستخدم نفس قاعدة Supabase الحالية، لكن لا يتم حفظ أي مفتاح داخل ملفات GitHub.

## قبل البناء على GitHub

في Repository افتح:

Settings → Secrets and variables → Actions

أنشئ Repository Secrets بالاسمين التاليين:

1. `SUPABASE_URL`
   - القيمة: Project URL الخاص بمشروع Supabase.

2. `SUPABASE_PUBLISHABLE_KEY`
   - القيمة: Publishable key من Supabase.

لا تستخدم أي مفتاح إداري أو مفتاح بصلاحيات مرتفعة داخل التطبيق.

## إعداد Supabase

1. أنشئ مستخدم لصاحب المحل من:
   Authentication → Users

2. شغّل الملف:
   `sql/android_app_rls.sql`
   داخل SQL Editor.

## بناء APK

افتح:
Actions → Build Android APK → Run workflow

بعد نجاح العملية، افتح الـRun ثم انزل إلى Artifacts وحمّل:

`shop-dashboard-apk`

داخله ستجد ملف APK.
