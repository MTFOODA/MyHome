import 'package:flutter/material.dart';

const operatorLabels = <String, (String, String)>{
  'dashboard': ('Dashboard', 'لوحة الإدارة'),
  'properties': ('All properties', 'كل العقارات'),
  'published_properties': ('Published properties', 'العقارات المنشورة'),
  'owners': ('Property owners', 'الملاك'),
  'buyers': ('Buyers', 'المشترون'),
  'renters': ('Tenants', 'المستأجرون'),
  'property_reviews': ('Ownership reviews', 'مراجعة الملكية'),
  'eligibility_reviews': (
    'Old-rent legal reviews',
    'مراجعات أهلية الإيجار القديم',
  ),
  'payment_reviews': ('Payment confirmations', 'تأكيدات الدفع'),
  'contract_reviews': ('Contract reviews', 'مراجعة التعاقد'),
  'viewing_assignments': (
    'Viewings awaiting assignment',
    'معاينات تنتظر التعيين',
  ),
  'pending_total': ('Requests awaiting action', 'طلبات تحتاج إجراء'),
  'roleCountNote': (
    'A person with several needs counts once in each relevant category. Team/admin accounts are excluded.',
    'صاحب الأدوار المتعددة يُحسب مرة في كل فئة تخصه. حسابات الإدارة والفريق مستبعدة.',
  ),
  'dashboardFailed': (
    'Counts could not be loaded. Retry to get current review requests.',
    'تعذر تحميل الأعداد. أعد المحاولة لعرض طلبات المراجعة الحالية.',
  ),
  'refresh': ('Refresh', 'تحديث'),
  'pending': ('Pending requests', 'طلبات معلّقة'),
  'loginIdentifier': (
    'Email or admin username',
    'البريد الإلكتروني أو اسم مستخدم الأدمن',
  ),
  'invalidIdentifier': (
    'Use your email, or fooda / amr for an administrator.',
    'أدخل بريدك الإلكتروني، أو fooda / amr للأدمن.',
  ),
  'username': ('Username', 'اسم المستخدم'),
  'changePassword': ('Change password', 'تغيير كلمة المرور'),
  'currentPassword': ('Current password', 'كلمة المرور الحالية'),
  'newPassword': ('New password', 'كلمة المرور الجديدة'),
  'confirmPassword': ('Confirm new password', 'تأكيد كلمة المرور الجديدة'),
  'passwordChanged': (
    'Password changed. Other sessions have been signed out.',
    'تم تغيير كلمة المرور وتسجيل خروج الجلسات الأخرى.',
  ),
  'passwordMismatch': (
    'The new password and confirmation do not match.',
    'كلمة المرور الجديدة وتأكيدها غير متطابقين.',
  ),
  'currentPasswordRequired': (
    'Enter the current password (maximum 72 UTF-8 bytes).',
    'أدخل كلمة المرور الحالية بحد أقصى 72 بايت.',
  ),
  'showPassword': ('Show password', 'إظهار كلمة المرور'),
  'hidePassword': ('Hide password', 'إخفاء كلمة المرور'),
  'PASSWORD_INVALID': (
    'Use at least 8 characters and at most 72 UTF-8 bytes.',
    'أدخل 8 أحرف على الأقل وبحد أقصى 72 بايت.',
  ),
  'CURRENT_PASSWORD_INCORRECT': (
    'The current password is incorrect.',
    'كلمة المرور الحالية غير صحيحة.',
  ),
  'NEW_PASSWORD_SAME': (
    'Choose a password different from the current one.',
    'اختر كلمة مرور مختلفة عن الحالية.',
  ),
  'NETWORK_ERROR': (
    'Could not reach the server. Check the connection and retry.',
    'تعذر الوصول إلى السيرفر. راجع الاتصال وأعد المحاولة.',
  ),
  'SESSION_EXPIRED': (
    'Your session expired. Sign in again to change the password.',
    'انتهت جلسة الدخول. سجّل الدخول مجددًا لتغيير كلمة المرور.',
  ),
  'save': ('Save', 'حفظ'),
  'RATE_LIMITED': (
    'Too many attempts. Wait one minute and try again.',
    'محاولات كثيرة. انتظر دقيقة ثم حاول مجددًا.',
  ),
};

String operatorText(BuildContext context, String key) {
  final pair = operatorLabels[key] ?? operatorLabels['NETWORK_ERROR']!;
  return Localizations.localeOf(context).languageCode == 'ar'
      ? pair.$2
      : pair.$1;
}
