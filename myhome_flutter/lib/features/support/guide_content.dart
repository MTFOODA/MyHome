import 'package:flutter/material.dart';

const guideCopy = <String, (String, String)>{
  'listIntroBody': (
    'Choose the type and area, then add photos, address and utilities. The final calculator shows the advertised price and your net amount.',
    'اختار النوع والمنطقة، وضيف الصور والعنوان والمرافق. الحاسبة في آخر خطوة توضّح سعر الإعلان وصافي مستحقاتك.',
  ),
  'connectIntroBody': (
    'Message the owner, arrange a supervised viewing and submit an offer. Follow the agreement and document review inside MyHome.',
    'راسل المالك واحجز معاينة بإشراف المنصة وقدّم عرضك. تابع الاتفاق ومراجعة المستندات من جوه بيتي.',
  ),
  'welcome': ('Welcome to MyHome', 'أهلًا بك في بيتي'),
  'skip': ('Skip', 'تخطي'),
  'next': ('Next', 'التالي'),
  'start': ('Find my home', 'ابدأ رحلتك'),
  'browse': ('Choose a home your way', 'اختار بيتك بطريقتك'),
  'browseBody': (
    'Browse before signing in. Choose cash or installment purchase, private rent or shared housing; filter area, budget, finishing and furnishing.',
    'تصفّح قبل تسجيل الدخول. اختار بيع نقدي أو تقسيط أو إيجار فردي أو جماعي، وحدد المنطقة والميزانية والتشطيب والفرش.',
  ),
  'list': ('List with clear choices', 'اعرض عقارك بخيارات واضحة'),
  'listBody': (
    'Choose your role, property type and area. Add photos, a complete address, optional map pin, utilities and extras. The final calculator explains the advertised price and your net amount.',
    'اختار دورك ونوع العقار والمنطقة. ضيف الصور والعنوان الكامل وموقع الخريطة والمرافق والمميزات الاختيارية. الحاسبة في آخر خطوة توضّح سعر الإعلان وصافي مستحقاتك.',
  ),
  'connect': ('Keep every step inside MyHome', 'كل خطوة من جوه بيتي'),
  'connectBody': (
    'Sign in for details, saved homes and internal messages. Request an accompanied viewing, negotiate, read the terms and follow the supervised transaction.',
    'سجّل الدخول للتفاصيل والمفضلة والمحادثات الداخلية. احجز معاينة بإشراف المنصة، وقدّم عرضك وراجع الشروط وتابع الصفقة خطوة بخطوة.',
  ),
  'documents': ('Identity and ownership review', 'مراجعة الهوية والملكية'),
  'documentsBody': (
    'The ID number must match the birth date and can be read from a photo with consent. Private documents still need human review; scanning alone does not prove authenticity.',
    'بنطابق الرقم القومي بتاريخ الميلاد وبنقرأ الرقم من صورة البطاقة بعد موافقتك. المستندات خاصة وتحتاج مراجعة بشرية؛ المسح وحده مش إثبات لصحتها.',
  ),
  'shared': ('Shared housing with clear roles', 'سكن جماعي بأدوار واضحة'),
  'sharedBody': (
    'Shared listings specify capacity and beds. Accepted tenants can join the owner’s group with a tenant co-admin. Roommate matching and calls are still being developed.',
    'إعلانات الجماعي بتحدد الأفراد والأسرّة. المستأجرون المقبولون يشاركوا في جروب ينشئه المالك ويختار مستأجرًا أدمن معاه. مطابقة شركاء السكن والمكالمات لسه قيد التطوير.',
  ),
  'pricing': ('One transparent final price', 'سعر نهائي واضح'),
  'pricingBody': (
    'The displayed price includes the buyer/tenant platform share. Reference fees stay fixed during negotiation. Read the breakdown and accept the agreement before commitment; payment confirmation is reviewed manually.',
    'السعر المعروض شامل حصة المشتري أو المستأجر. العمولة المرجعية ثابتة مع التفاوض. راجع التفصيل ووافق قبل الالتزام؛ تأكيد الدفع تتم مراجعته يدويًا.',
  ),
  'privacy': ('Private conversations', 'تواصل بخصوصية'),
  'privacyBody': (
    'Text is checked by the server to block contact details, then encrypted in storage. Keep communication inside the app. This is not end-to-end encryption.',
    'الرسائل بتتفحص على السيرفر لمنع بيانات الاتصال ثم تتخزن مشفرة. خليك داخل التطبيق للتواصل. التشفير ليس من طرف لطرف.',
  ),
  'about': ('A clearer route to your next home', 'طريق أوضح لبيتك القادم'),
  'aboutBody': (
    'MyHome / بيتي brings owners and people looking to buy or rent into one place. Clear choices, private document review, transparent prices and supervised steps help you follow your next home from discovery to agreement.',
    'بيتي / MyHome بيجمع الملاك والباحثين عن شراء أو إيجار في مكان واحد. خيارات واضحة ومراجعة خاصة للمستندات وسعر شفاف وخطوات بإشراف المنصة تساعدك تتابع بيتك القادم من البحث لحد الاتفاق.',
  ),
  'replay': ('Replay introduction', 'شاهد شرح البداية'),
  'current': ('What you can do today', 'تقدر تعمل إيه دلوقتي؟'),
};
String guideText(BuildContext context, String key) =>
    Localizations.localeOf(context).languageCode == 'ar'
    ? guideCopy[key]!.$2
    : guideCopy[key]!.$1;

class GuidePresenters extends StatelessWidget {
  final double height;
  const GuidePresenters({super.key, this.height = 260});
  @override
  Widget build(BuildContext context) => Semantics(
    label: Localizations.localeOf(context).languageCode == 'ar'
        ? 'شخصيتان توضيحيتان لشرح بيتي'
        : 'MyHome illustrated guides',
    child: Image.asset(
      'assets/illustrations/guide-duo-v1.png',
      height: height,
      fit: BoxFit.contain,
    ),
  );
}

enum GuidePose {
  olivePresent('guide-olive-present-v1', 'olive'),
  blazerExplain('guide-blazer-explain-v1', 'blazer'),
  olivePhone('guide-olive-phone-v1', 'olive'),
  blazerDocument('guide-blazer-document-v1', 'blazer');

  final String filename, character;
  const GuidePose(this.filename, this.character);
  String get asset => 'assets/illustrations/$filename.webp';
  static GuidePose forSection(int index) => values[index % values.length];
}

class GuidePresenter extends StatelessWidget {
  final GuidePose pose;
  final double width;
  const GuidePresenter({super.key, required this.pose, this.width = 160});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 360),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: Image.asset(
        pose.asset,
        width: width,
        height: width * 1.45,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    ),
  );
}

/// Presenters stay beside their own explanation, including on a narrow phone.
/// Alternating characters is driven by section order, not random rebuilds.
class GuideExplanation extends StatelessWidget {
  final String topic;
  final int section;
  final bool compact;
  const GuideExplanation({
    super.key,
    required this.topic,
    required this.section,
    this.compact = false,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, box) {
          final narrow = box.maxWidth < 500;
          final picture = GuidePresenter(
            pose: GuidePose.forSection(section),
            width: (box.maxWidth * .30).clamp(72.0, 190.0),
          );
          final explanation = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guideText(context, topic),
                  style: narrow
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  guideText(
                    context,
                    compact ? '${topic}IntroBody' : '${topic}Body',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.65),
                ),
              ],
            ),
          );
          final space = SizedBox(width: narrow ? 12 : 28);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: section.isEven
                ? [picture, space, explanation]
                : [explanation, space, picture],
          );
        },
      ),
    ),
  );
}
