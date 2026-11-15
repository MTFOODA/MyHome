import 'package:flutter/material.dart';

const salesLabels = <String, (String, String)>{
  'eligibilityPending': (
    'Reference amounts only · no financial commitment before legal eligibility approval.',
    'مبالغ مرجعية فقط · لا التزام مالي قبل اعتماد الأهلية القانونية.',
  ),
  'chatPrivacy': (
    'Messages are checked for contact details, then encrypted in platform storage. Use the offer form for prices and booking forms for appointments.',
    'تُفحص الرسائل لمنع بيانات الاتصال، ثم تُحفظ مشفّرة لدى المنصة. استخدم نموذج العرض للأسعار ونموذج الحجز للمواعيد.',
  ),
  'olderMessages': ('Older messages', 'رسائل أقدم'),
  'messageHint': (
    'Write a message · no contact details',
    'اكتب رسالة · بدون بيانات اتصال',
  ),
  'sendMessage': ('Send', 'إرسال'),
  'CHAT_ACCESS_REVOKED': (
    'Conversation access is no longer available.',
    'لم يعد الوصول إلى المحادثة متاحًا.',
  ),
  'CONVERSATION_NOT_FOUND': (
    'Conversation is unavailable for this account.',
    'المحادثة غير متاحة لهذا الحساب.',
  ),
  'DEAL_NOT_FOUND': (
    'Transaction is unavailable for this account.',
    'المعاملة غير متاحة لهذا الحساب.',
  ),
  'QR_MAX_2MB': (
    'Choose an image no larger than 2 MB.',
    'اختَر صورة لا تتجاوز 2 ميجابايت.',
  ),
  'FUTURE_HOURLY_SLOT_REQUIRED': (
    'Choose a future booking on a whole hour.',
    'اختَر موعدًا مستقبليًا على رأس الساعة.',
  ),
  'CONFIRMED_DUE_VIEWING_REQUIRED': (
    'The viewing must be confirmed and its scheduled time reached.',
    'يلزم تأكيد المعاينة وحلول موعدها المحدد.',
  ),
  'MESSAGE_RATE_LIMITED': (
    'Please wait briefly before sending more messages.',
    'انتظر قليلًا قبل إرسال رسائل أخرى.',
  ),
  'deals': ('Deals and viewings', 'الصفقات والمعاينات'),
  'financeHistory': ('Financial history', 'السجل المالي'),
  'salesAdmin': ('Team and brokerage settings', 'الفريق وإعدادات الوساطة'),
  'eligibility': (
    'Old-rent eligibility reviews',
    'مراجعات أهلية الإيجار القديم',
  ),
  'start': ('Start a supervised transaction', 'بدء معاملة بإشراف المنصة'),
  'open': ('Negotiation open', 'التفاوض متاح'),
  'accepted': ('Offer accepted', 'العرض مقبول'),
  'completed': ('Completed', 'مكتملة'),
  'cancelled': ('Cancelled', 'ملغاة'),
  'pending': ('Pending', 'قيد الانتظار'),
  'requested': ('Requested', 'مطلوبة'),
  'confirmed': ('Confirmed', 'مؤكدة'),
  'approved': ('Approved', 'معتمدة'),
  'rejected': ('Rejected', 'مرفوضة'),
  'superseded': ('Replaced by a newer offer', 'استُبدل بعرض أحدث'),
  'unpaid': ('Not paid', 'لم يُدفع'),
  'reported': (
    'Transfer reported · awaiting verification',
    'تم الإبلاغ عن التحويل · بانتظار التحقق',
  ),
  'verified': ('Payment verified', 'تم التحقق من الدفع'),
  'applied': ('Applied after both consents', 'مطبق بموافقة الطرفين'),
  'eligible': (
    'Transaction eligible after review',
    'المعاملة مؤهلة بعد المراجعة',
  ),
  'ineligible': (
    'Not eligible for this transaction',
    'غير مؤهلة لهذه المعاملة',
  ),
  'financialBreakdown': (
    'Transparent final price',
    'تفاصيل السعر النهائي الشامل',
  ),
  'original': ('Original commission reference', 'السعر المرجعي الأصلي للعمولة'),
  'propertyPart': ('Negotiated property amount', 'قيمة العقار بعد التفاوض'),
  'buyerFee': ('Buyer / tenant share', 'نصيب المشتري / المستأجر'),
  'sellerFee': ('Seller / landlord share', 'نصيب البائع / المؤجر'),
  'totalFee': ('Total platform commission', 'إجمالي عمولة المنصة'),
  'buyerTotal': (
    'Buyer / tenant total',
    'إجمالي المطلوب من المشتري / المستأجر',
  ),
  'sellerNet': ('Seller / landlord net', 'صافي مستحقات البائع / المؤجر'),
  'monthlyAllIn': (
    'Monthly price including the allocated share',
    'السعر الشهري شامل الحصة الموزعة',
  ),
  'firstPayment': (
    'First payment including the one-time share',
    'الدفعة الأولى شاملة الحصة لمرة واحدة',
  ),
  'subsequentRent': (
    'Subsequent monthly rent · no new platform fee',
    'الإيجار الشهري التالي · بلا عمولة منصة جديدة',
  ),
  'fixedHint': (
    'Commission stays fixed when the property price is reduced. No extra platform fee is added at completion.',
    'العمولة ثابتة عند تخفيض قيمة العقار. لا تُضاف عمولة منصة أخرى عند إتمام الصفقة.',
  ),
  'oldReference': (
    '12 months is a commission reference only. It does not define the legal contract term or transfer any tenancy rights. Eligibility requires an assigned legal review.',
    '12 شهرًا مرجع لحساب العمولة فقط، وليست مدة العقد القانونية ولا تُنشئ نقلًا لحقوق الإيجار. أهلية المعاملة تحتاج مراجعة قانونية معيّنة.',
  ),
  'policy': (
    'Sale: 1% of the original price. Private rent: ½ / ¾ / 1 month for 1 / 3 / 5+ years. Shared rent: ¼ / ⅜ / ½ month per occupied bed for those terms. Shorter custom terms are prorated. Old rent: ¾ month, with 12 months as a fee reference only and mandatory legal eligibility review. All fees are split equally and fixed on the original reference, even after discounts. The displayed price includes the buyer / tenant share. Each side explicitly accepts before committing.',
    'البيع: 1% من السعر الأصلي. الإيجار الفردي: نصف / ثلاثة أرباع / شهر لمدة سنة / 3 / 5 سنوات فأكثر. الجماعي: ربع / ثلاثة أثمان / نصف شهر لكل سرير مشغول لنفس المدد. المدد الخاصة الأقصر تُحسب تناسبيًا. الإيجار القديم: ثلاثة أرباع شهر، مع مرجع 12 شهرًا للعمولة فقط ومراجعة أهلية قانونية إلزامية. تُقسم العمولة مناصفة وتثبت على المرجع الأصلي حتى بعد الخصم. السعر المعروض شامل حصة المشتري / المستأجر. يوافق كل طرف صراحة قبل الالتزام.',
  ),
  'chat': ('Internal conversation', 'المحادثة الداخلية'),
  'viewing': ('Supervised viewing', 'المعاينة بإشراف المنصة'),
  'book': ('Request a viewing', 'طلب معاينة'),
  'date': ('Date', 'التاريخ'),
  'hour': ('Hour', 'الساعة'),
  'confirmViewing': ('Confirm the proposed time', 'تأكيد الموعد المقترح'),
  'assignAgent': ('Assign a field supervisor', 'تعيين مشرف معاينة'),
  'completeViewing': ('Record completed viewing', 'تسجيل إتمام المعاينة'),
  'offers': ('Price offers', 'العروض والتفاوض'),
  'newOffer': ('Submit an all-in offer', 'تقديم عرض شامل العمولة'),
  'offerAmount': (
    'Final all-in price · monthly for fixed-term rentals',
    'السعر النهائي شامل الحصة · شهري للإيجار محدد المدة',
  ),
  'accept': ('Accept', 'موافقة'),
  'reject': ('Reject', 'رفض'),
  'confirm': ('Confirm', 'تأكيد'),
  'cancel': ('Cancel', 'إلغاء'),
  'agreement': ('Brokerage agreement', 'اتفاق الوساطة'),
  'explicitConsent': (
    'I read and accept this version and its disclosed fixed fee amounts.',
    'قرأت وأوافق على هذه النسخة ومبالغ العمولة الثابتة الموضحة.',
  ),
  'recordConsent': ('Record my acceptance', 'تسجيل موافقتي'),
  'consentNotice': (
    'This records explicit acceptance. It is not described as a qualified electronic signature. Contract verification remains a separate legal-review step.',
    'هذا سجل موافقة صريحة، ولا يُعرض كتوقيع إلكتروني معتمد. توثيق التعاقد يظل خطوة مستقلة للمختص.',
  ),
  'buyerConsent': ('Buyer / tenant accepted', 'موافقة المشتري / المستأجر'),
  'sellerConsent': ('Seller / landlord accepted', 'موافقة البائع / المؤجر'),
  'legalReview': ('Documents and contract review', 'مراجعة المستندات والتعاقد'),
  'assignReviewer': (
    'Assign a document reviewer',
    'تعيين مختص مراجعة المستندات',
  ),
  'documents': ('Private review documents', 'مستندات المراجعة الخاصة'),
  'recordReview': ('Record review decision', 'تسجيل نتيجة المراجعة'),
  'reference': (
    'External contract / review reference',
    'مرجع التعاقد / المراجعة الخارجي',
  ),
  'note': ('Review note', 'ملاحظات المراجعة'),
  'payment': ('Commission payment', 'دفع حصة العمولة'),
  'pay': ('View payment QR', 'عرض QR الدفع'),
  'paymentCredit': (
    'Your verified platform payment is credited against the all-in total. It is not a second fee.',
    'حصة المنصة التي يتم التحقق من سدادها تُحتسب من الإجمالي الشامل، وليست عمولة ثانية.',
  ),
  'transferReference': (
    'Bank / InstaPay transfer reference',
    'مرجع التحويل البنكي / إنستاباي',
  ),
  'reportTransfer': (
    'I transferred · submit for verification',
    'قمت بالتحويل · إرسال للتحقق',
  ),
  'verifyTransfer': (
    'Verify against the bank record',
    'مراجعة التحويل بالسجل البنكي',
  ),
  'completeDeal': ('Record completed transaction', 'تسجيل إتمام الصفقة'),
  'preparePayment': (
    'Attach configured payment destination',
    'ربط حساب الدفع المعدّ بالإدارة',
  ),
  'remaining': (
    'Remaining within the all-in total',
    'المتبقي ضمن الإجمالي الشامل',
  ),
  'paidPlatform': (
    'Verified buyer / tenant platform payment',
    'حصة المشتري / المستأجر المسددة والمتحقق منها',
  ),
  'staff': ('Internal team', 'الفريق الداخلي'),
  'newStaff': ('Create an internal account', 'إنشاء حساب داخلي'),
  'field_agent': ('Viewing supervisor', 'مشرف المعاينة'),
  'document_reviewer': ('Document specialist', 'مختص المستندات'),
  'name': ('Name', 'الاسم'),
  'email': ('Email', 'البريد الإلكتروني'),
  'password': (
    'Initial strong password · 12+ characters',
    'كلمة مرور أولية قوية · 12 حرفًا فأكثر',
  ),
  'professionalRef': (
    'Verified professional reference',
    'مرجع الصفة المهنية المتحقق منه',
  ),
  'deactivate': ('Deactivate staff authority', 'إيقاف صلاحيات الموظف'),
  'activate': ('Activate staff authority', 'تفعيل صلاحيات الموظف'),
  'terms': ('Publish reviewed terms', 'نشر شروط تمت مراجعتها'),
  'version': ('Unique terms version', 'رقم نسخة شروط جديد'),
  'termsAr': (
    'Arabic terms · at least 100 characters',
    'الشروط العربية · 100 حرف على الأقل',
  ),
  'termsEn': (
    'English terms · at least 100 characters',
    'الشروط الإنجليزية · 100 حرف على الأقل',
  ),
  'dueCondition': (
    'Explicit commission due condition',
    'شرط استحقاق العمولة بوضوح',
  ),
  'legalReviewed': (
    'The specialist reviewed this exact wording.',
    'راجع المختص هذه الصيغة بعينها.',
  ),
  'qrSettings': ('Configure our InstaPay QR', 'إعداد QR إنستاباي الخاص بنا'),
  'recipient': (
    'Verified recipient / account label',
    'اسم المستفيد / الحساب المتحقق منه',
  ),
  'uploadQr': (
    'Choose and upload the actual QR image',
    'اختيار ورفع صورة QR الفعلية',
  ),
  'success': ('Saved successfully', 'تم الحفظ'),
  'specialFee': (
    'Special old-rent fee agreement',
    'اتفاق عمولة خاص للإيجار القديم',
  ),
  'proposeFee': ('Propose a documented exception', 'اقتراح استثناء موثّق'),
  'reason': ('Reason and conditions', 'السبب والشروط'),
  'specialTotal': ('Total fee for both sides', 'إجمالي العمولة للطرفين'),
  'NETWORK_ERROR': (
    'Could not finish. Check the connection and retry.',
    'تعذر إتمام العملية. راجع الاتصال وحاول مجددًا.',
  ),
  'CONTACT_DETAILS_BLOCKED': (
    'Contact details and long number sequences are blocked. Use the offer form for prices.',
    'بيانات الاتصال وتسلسلات الأرقام الطويلة ممنوعة. استخدم نموذج العروض للأسعار.',
  ),
  'OLD_RENT_ELIGIBILITY_REQUIRED': (
    'This transaction needs legal eligibility approval first.',
    'تحتاج المعاملة اعتماد الأهلية القانونية أولًا.',
  ),
  'RENTAL_FEE_AGREEMENT_REQUIRED': (
    'The legal / fee agreement must be approved first.',
    'يجب اعتماد الأهلية أو اتفاق العمولة أولًا.',
  ),
  'REVIEWED_TERMS_NOT_CONFIGURED': (
    'Administration must publish reviewed brokerage terms before acceptance.',
    'على الإدارة نشر شروط وساطة مراجَعة قبل قبول العرض.',
  ),
  'COMPLETED_VIEWING_REQUIRED': (
    'Complete the supervised viewing before submitting an offer.',
    'أكمل المعاينة بإشراف المنصة قبل تقديم عرض.',
  ),
  'SPECIAL_FEE_CONSENTS_REQUIRED': (
    'Both parties must decide on the pending special fee agreement.',
    'يلزم قرار الطرفين بشأن اتفاق العمولة الخاص المعلّق.',
  ),
  'PAYMENT_NOT_READY': (
    'Payment is not ready. Complete the agreement and document review first.',
    'الدفع غير جاهز. أكمل الاتفاق ومراجعة المستندات أولًا.',
  ),
  'STAFF_SLOT_UNAVAILABLE': (
    'This supervisor already has a booking at that hour.',
    'لدى المشرف حجز آخر في هذه الساعة.',
  ),
  'empty': ('No records yet.', 'لا توجد سجلات بعد.'),
  'retry': ('Retry', 'إعادة المحاولة'),
};

String salesText(BuildContext context, String key) {
  final pair = salesLabels[key] ?? salesLabels['NETWORK_ERROR']!;
  return Localizations.localeOf(context).languageCode == 'ar'
      ? pair.$2
      : pair.$1;
}
