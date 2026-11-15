## One-click demo startup and HTTPS sharing - 2026-11-15

Implemented `Start_MyHome.cmd` and `Stop_MyHome.cmd`, backed by `tools/run_myhome.ps1`, optional Caddy/cloudflared Docker services and same-origin Web API configuration. The default launcher starts PostgreSQL and the isolated demo, builds/caches Web and prints a public HTTPS mobile/test link. `-Android` builds an APK for that link; `-Local` disables sharing. Daily startup seeds only if empty and preserves edits/preferences. Stopping sharing preserves the database and the main API.

Verified: actual CMD start/stop/restart, Web release/Android debug builds, cached repeated launch with changed account preference retained, 46 Flutter tests and analyzer clean; public HTTPS HTTP login/chat/permission/pricing/logout smoke and private-path 404 checks. Browser GUI/physical-phone testing is not claimed. Read [the launcher guide and limits](36_ONE_CLICK_DEMO.md). Previous reports remain as history; no whole marketplace phase is declared complete.

---

## Approved all-in pricing, supervised deals and moderated chat - 2026-11-15

This section supersedes the preview-only and E2EE-message statements below, retained as history. The owner approved fixed original-price fees split equally, server-inspected text encrypted at rest, and mandatory legal eligibility for old rent. Read [the current implementation and operating guide](35_ALL_IN_SUPERVISED_DEALS.md).

Verified: 56 real PostgreSQL tests, 43 Flutter tests, 6 preview-render tests; analyzer/Ruff clean; Web and Android debug builds passed. Main/demo additive migrations applied after a private DB backup, both APIs healthy. Isolated demo: 10 accounts, 13 listings, one shared group, an open deal and two encrypted conversations; actual restricted-role HTTP smoke passed. iOS requires macOS. No full marketplace phase is declared complete.

Calls, roommate matching and production banking/signature integrations remain pending. Explicit consent is recorded, not a certified signature. Operators supply reviewed terms, qualified staff and the real InstaPay QR through admin UI. The server can inspect messages; this is not E2EE.

---

## Owner portfolio, lifecycle and demo - 2026-11-14

Current increment: grouped owner counts; remote quick search; exactly 3 listings per cursor page; pause/restore; sold/rented history; safe saved-property status cards; own-photo access and group membership list. Pricing proposal is configurable, preview-only and disabled pending approval. See [owner/demo guide](33_OWNER_PORTFOLIO_AND_DEMO.md) and [fee proposal](34_COMMISSION_PROPOSAL.md).

Verified: 33 Flutter tests, analyzer clean; 25 real PostgreSQL tests, Ruff clean; Web/Android debug builds. Separate myhome_demo fixtures: 8 accounts, 13 listings, one owner/two-tenant group and private random credentials. Actual Docker runtime smoke passed. E2EE communication/calls and real conversations remain unimplemented; membership metadata is not chat.

---

## Branding/search/cleanup update - 2026-11-14

Product: بيتي / MyHome. The old NestJS backend was removed after migration and explicit user authorization. Search now follows the supplied capsule/filter-panel reference and supports server-side text queries. Four logo proposals await selection. See [increment details](31_BRANDING_CLEANUP_AND_SEARCH.md) and [logo options](../design/branding/README.md).

Flutter: 28 tests passed; analyzer clean. FastAPI: 19 PostgreSQL tests passed; Ruff clean. AR/EN light/dark screenshots are in docs/screenshots/. iOS localized labels were checked structurally, not built on Windows. E2EE, calls and roommate matching remain pending.

---

# الوضع الحالي — ١٤ نوفمبر ٢٠٢٦
<!-- CURRENT_AUDIT_2026_11_14 -->
التحديث ده هو الحالة الحالية؛ الملخص القديم أسفله محفوظ كسجل سابق.

## اتنفذ واتختبر
- الباك إند الحالي Python/FastAPI في backend_fastapi/ مع PostgreSQL محلي وDocker. كود NestJS محفوظ كمرجع فقط.
- الرئيسية مفتوحة للزائر، وتعرض العقارات المعتمدة وفلاترها من السيرفر. التفاصيل والحفظ يحتاجان تسجيل دخول.
- حساب واحد بأكثر من صفة، ووضع استخدام نشط بعد التسجيل؛ طالب/مغترب مستقل عن كونه مالكًا.
- البحث المنفصل لشركاء السكن يظهر فقط لو المستخدم في وضع الإيجار الجماعي، ويتمنع على السيرفر عند تغيير الوضع.
- فورم عقار متعدد الصفحات: بيانات وموقع ومساحة ومرافق وتشطيب وسعر وفصال ومدة وتقسيط وأسرّة حسب النوع. نعم/لا بدون إجابات افتراضية.
- صور العقار وغلاف وترتيب، وبطاقة ورقم قومي وتاريخ ميلاد وإثبات ملكية في تخزين خاص مشفّر.
- مقارنة الرقم والتاريخ وOCR محلي، ثم مراجعة بشرية منفصلة لكل عقار. OCR لا يثبت أصالة البطاقة أو الملكية.
- شاشة مراجع، منع الاعتماد الذاتي، وتسجيل قرارات المراجعة والوصول للمستندات.
- طلب سكن وقبول مع حماية آخر سرير من الطلبات المتزامنة، وتجهيز جروب يحتاج مستأجرًا مقبولًا كأدمن مع المالك.
- عربي/إنجليزي وRTL ودارك/لايت، أرقام عربية وحركة تراعي إعدادات الجهاز.

## نتائج التحقق
نجح ٢٥ اختبار Flutter و١٩ اختبار FastAPI على PostgreSQL حقيقي، واختبار Flutter متصل بالباك إند، وتجربة OCR حقيقية على صورة رقم مصطنعة.
الويب وأندرويد اتبنوا بنجاح. iOS ما زال محتاج Mac/Xcode واختبار جهاز.

## لسه مطلوب
المراسلات والمكالمات المشفرة من طرف لطرف لم تُنفذ. الجروب الحالي يجهز العضوية فقط ولا ينقل رسائل.
البحث الحقيقي عن شركاء السكن وملفاتهم ما زال مطلوبًا؛ التبويب الحالي يختبر صلاحية المستخدم ويعرض حالة فارغة.
استئناف/تعديل/حذف المسودات من الواجهة، وبقية الحقول الموسعة القديمة، وتوثيق البريد واستعادة الحساب والنسخ الاحتياطي المجدول وسياسات الاحتفاظ بالمستندات لسه مطلوبين.
القائمة فيها المحافظات الـ٢٧ ومجموعة مناطق كبداية؛ ليست قائمة شاملة لكل مناطق مصر.

التفاصيل المعتمدة: 29_PRODUCT_REQUIREMENTS_2026_11_14.md. التشغيل الحالي: 30_FASTAPI_LOCAL_SETUP.md. نتائج الاختبارات: 25_BUILD_TEST_RESULTS.md.

---

## الملخص السابق — للتاريخ

# الوضع الحالي والخطوات القادمة
آخر مراجعة: ٩ نوفمبر ٢٠٢٦

## نتيجة مراجعة الموجود
الكود كان أقل بكثير من الوصف الموجود في تقارير التقدم القديمة. لم يكن هناك تنفيذ فعلي لشاشات الدخول أو إدارة العقارات، كما أن إعدادات Flutter وNestJS كانت تمنع البناء. تم الاحتفاظ بالسجل القديم مع إضافة حالة مراجعة حديثة في بداية المستندات الأساسية.

## ما تم تنفيذه في هذه الدفعة
- إصلاح إعدادات المشروع والاعتماديات، وإنشاء ملفات تشغيل المنصات الست.
- تسجيل حساب ودخول وخروج واستعادة الجلسة، متصلين بـ API فعلي.
- أدوار التسجيل: مستخدم، طالب، مغترب، مالك ومقدم صيانة. لا يمكن إنشاء حساب أدمن عن طريق طلب تسجيل عادي.
- جلسات محفوظة في قاعدة البيانات، كلمات مرور مجزأة، وتجديد أحادي الاستخدام للرموز، وإلغاء الجلسة على الخروج.
- منع اعتبار اختيار حساب مالك توثيقًا للملكية، وتجهيز حارس تحقق للمالك.
- شاشات دخول وتسجيل وحساب، وصفحة رئيسية وتنقل وقائمة جانبية ودليل مختصر وتعريف بالمشروع.
- ترجمة عربية وإنجليزية، RTL، ومظهر فاتح/داكن/النظام مع حفظ الاختيار.
- PostgreSQL محلي، migrations واضحة، Dockerfile وCompose، واختبارات تلقائية.

## الحدود الحالية
واجهة البحث والمفضلة والمقارنة تمهيدية فقط. لا توجد API للعقارات أو بيانات عقارات معروضة، ولا يوجد بعد نشر إعلانات أو رفع صور أو مراسلات أو مكالمات أو مجموعات.
توثيق البريد واستعادة كلمة المرور وتعديل الملف الشخصي ورفع مستندات توثيق المالك ومراجعتها ما زالت مهام مطلوبة. تسجيل الحساب لا يمنح توثيقًا تلقائيًا.
المشروع ما زال في مرحلتي الأساس والمصادقة؛ لا يصح وصف المرحلة الثالثة أو المشروع كاملًا بأنه منتهٍ.

## الخطوة التالية حسب ترتيب docs
1. استكمال متطلبات الأساس التشغيلية واختبارات المنصات.
2. استكمال التحقق من البريد واسترجاع الحساب والملف الشخصي وتوثيق المالك.
3. بناء العقارات: الجداول والفورم متعدد الخطوات والتحقق الإجباري والصور والتقسيط والسكن المشترك وصلاحيات التعديل.
4. ربط البحث والفلاتر والتفاصيل والمفضلة ببيانات عقارات معتمدة من السيرفر.
5. السكن المشترك، ثم التواصل والتشفير والخدمات والإدارة.

تفاصيل التشغيل في 28_LOCAL_DEVELOPMENT.md، والمهام في 04_IMPLEMENTATION_ROADMAP.md، ونتائج التحقق في 25_BUILD_TEST_RESULTS.md.
