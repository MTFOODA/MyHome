# رابط بيتي الثابت على Cloudflare — 2026-11-15

رابط المشروع المنشور والمختبَر: **https://myhome.mohamed-fooda-mtf.workers.dev**.

تم تحديث Worker `myhome` الموجود في الحساب الذي حدده صاحب المشروع، دون إنشاء خدمة مدفوعة أو نقل قاعدة البيانات. الـWorker بوابة HTTPS ثابتة؛ ملفات Flutter والـFastAPI وPostgreSQL تظل على الكمبيوتر داخل حاويات التجربة المنفصلة. **يجب بقاء الكمبيوتر وDocker والإنترنت شغّالين لفتح الويب واستخدام التطبيق.** هذا نشر للتجربة، وليس استضافة مستقلة تعمل عند إغلاق الكمبيوتر.

## التشغيل اليومي

```cmd
Start_MyHome.cmd
```

بعد الربط الأول، يعيد الملف توصيل الـWorker تلقائيًا إذا تغير عنوان النفق المحلي. يتحقق من صحة الاتصال قبل عرض الرابط، ويعيد استخدام النشر إذا كان سليمًا ولم تتغير المدخلات. عند انتهاء صلاحية نفق مؤقت قديم، يعيد إنشاء حاوية النفق وحدها، دون مسح قاعدة البيانات أو إعادة بيانات المستخدمين.

لإعادة النشر صراحةً، أو إعداد نسخة جديدة من المشروع على هذا الكمبيوتر:

```cmd
Deploy_Cloudflare.cmd
Deploy_Cloudflare.cmd -Android -NoBrowser
```

يتطلب النشر Node.js 22.12+ وحساب Cloudflare مخوّلًا للـWorker. يعتمد المشروع إصدار Wrangler المثبت في `infrastructure/cloudflare/package-lock.json`. إذا انتهت جلسة تسجيل الدخول، نفّذ داخل `infrastructure/cloudflare`:

```cmd
node_modules\.bin\wrangler.cmd login
```

لا تُنسخ جلسة Wrangler أو مفاتيح الحساب إلى المستودع. `-Local` يوقف المشاركة الخارجية ولا يجتمع مع `-Cloudflare` أو `-Android`.

- رابط المشروع النهائي محفوظ في `artifacts/project-url.txt`.
- `artifacts/share-url.txt` عنوان النفق الداخلي المؤقت، وقد يتغير؛ أرسل للمجرّبين رابط الـWorker الثابت.
- `Start_MyHome.cmd -Android` يبني `artifacts/MyHome-demo.apk` بعنوان الـWorker. تغيير النفق لاحقًا لا يحتاج بناء APK جديد ما دام عنوان الـWorker نفسه ثابتًا.
- الحسابات العشوائية موجودة محليًا في `artifacts/demo-accounts.json`، ولا تُرفع إلى Cloudflare أو GitHub.
- `Stop_MyHome.cmd` يوقف الويب وDemo API والنفق، ويحافظ على البيانات. سيظل عنوان Worker موجودًا، لكن البوابة تعيد خطأ 503 عند تعذر الوصول للكمبيوتر.

## التنفيذ وحدود التشغيل

`infrastructure/cloudflare/src/worker.js` يمرّر الويب و`/api/v1` إلى عنوان HTTPS محدد يديره ملف التشغيل. لا يقبل عنوان وجهة من المستخدم. يحفظ المسار والاستعلام وBearer، ويمنع إعادة توجيه بيانات الدخول إلى مضيف آخر. مسارات المستودع والملفات الخاصة مثل `.env` و`.git` و`artifacts` محجوبة، وطلبات API لا ترجع صفحة HTML بديلة.

الردود لا تُخزّن مؤقتًا. الحد الأعلى لجسم الطلب في البوابة 10 MiB، ومهلة بدء رد المصدر 30 ثانية. فشل الاتصال أو غياب الإعداد ينتج خطأ واضحًا، دون بيانات بديلة مصطنعة. جلسات الدخول وصلاحيات العقارات والمستندات والمحادثات ما زالت تُفرض في FastAPI. لا تُعرَض PostgreSQL أو API التطبيق الرئيسية عبر النفق.

يُنشر كود البوابة الصغير فقط؛ لا يوجد ASSETS binding في الإعداد المنشور. إعداد النفق ليس سرًا ولا يمنح صلاحيات دخول. لا توجد شهادات معطّلة أو تغييرات عامة في DNS أو إعدادات الشبكة. هذا المسار يستخدم [Quick Tunnels المخصصة للتطوير والتجربة](https://developers.cloudflare.com/tunnel/get-started/quick-tunnels/)، وتظل حدودها وخطط Cloudflare الحالية سارية. تشغيل إنتاج مستقل يحتاج استضافة دائمة للويب والـAPI والبيانات.

## التحقق الفعلي

- 11 اختبار Worker ناجحًا: توجيه الويب والـAPI، حفظ المصادقة، حدود الطلب، وجهة ثابتة، إعادة التوجيه، الملفات الخاصة، وانقطاع المصدر. فحص JavaScript وWrangler dry-run ناجحان.
- نشر فعلي على الرابط أعلاه؛ النسخة المنشورة `1e88c0e6-f10d-4250-9e1a-c7a3ea3d4e3c`.
- الصفحة الرئيسية وملف JavaScript والـhealth أعادت 200؛ بصمة ملف الويب العام تطابق آخر بناء محلي. المسارات الخاصة ونسخة API غير المعروفة أعادت 404. الردود `no-store`.
- تسجيل دخول لأدوار متعددة، قراءة/كتابة محادثة، رفض الهاتف، عزل الجروب والصفقة، صفحات المالك 3+2، وحالات المفضلة وتسجيل خروج نجحت عبر الـWorker.
- خمس حالات حاسبة حية نجحت: بيع، إيجار سنة، إيجار 3 سنوات، جماعي وقديم. طلبات HTTP بتعريف عميل Android ومتصفح نجحت؛ هذا لا يعادل تجربة هاتف فعلي.
- `Deploy_Cloudflare.cmd -Android -NoBrowser` بنى APK بالرابط الثابت. إعادة `Start_MyHome.cmd -NoBrowser` حافظت على الرابط وأعادت استخدام النشر السليم.
- لم تتوفر جلسة تحكم بالمتصفح؛ لا يُدَّعى اختبار GUI أو هاتف حقيقي أو بناء iOS من Windows.

أدلة محلية متجاهلة من Git: `cloudflare-deploy.log`، `cloudflare-gateway-deploy.log`، `cloudflare-repeat-start.log`، `cloudflare-public-smoke.json`، `cloudflare-calculator-smoke.json` و`all-in-demo-runtime.json` داخل `artifacts/`.

## الرجوع والتوثيق

قبل التحديث حُفظت إصدارات الخدمة وإعداداتها ومصدرها محليًا. الإصدار الأصلي: `f3726b64-ec75-4727-9c56-8218ab3f058f`. توجد النسخ في `artifacts/cloudflare-original-api/` وجرد النشر في `artifacts/cloudflare-before-deployments.json`. يحفظ سكربت النشر جرد الإصدارات قبل كل تحديث فعلي أيضًا. لإرجاع النسخة الأصلية عند الحاجة، من `infrastructure/cloudflare`:

```cmd
node_modules\.bin\wrangler.cmd rollback f3726b64-ec75-4727-9c56-8218ab3f058f
```

الرجوع يعيد سلوك الـWorker السابق، ولا يغير البيانات المحلية. [أوامر Wrangler الرسمية](https://developers.cloudflare.com/workers/wrangler/commands/) و[إعدادات Workers](https://developers.cloudflare.com/workers/wrangler/configuration/) مرجع التشغيل. تعديل أول دخول وحاسبة السعر موثق في [الدليل 37](37_ONBOARDING_AND_PRICE_CALCULATOR.md).
