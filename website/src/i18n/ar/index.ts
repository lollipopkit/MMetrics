import type { Translation } from '../i18n-types.js'

const ar: Translation = {
  meta: {
    lang: 'ar',
    dir: 'rtl',
    title: 'MMetrics — مراقب النظام لشرائح Apple Silicon',
    description:
      'MMetrics — مراقب النظام لشرائح Apple Silicon في شريط القوائم. مجموعات CPU وGPU والطاقة ودرجات الحرارة والذاكرة والبطارية والشبكة والقرص، تُقرأ من واجهات macOS الأصلية.',
  },
  nav: {
    features: 'الميزات',
    sources: 'مصادر البيانات',
    install: 'التثبيت',
    download: 'تنزيل',
    languageLabel: 'اللغة',
  },
  hero: {
    titlePrefix: 'كل قياسات جهاز Mac،',
    titleSuffix: 'في شريط القوائم.',
    subtitle:
      'يعرض MMetrics مجموعات CPU وGPU والطاقة ودرجات الحرارة والذاكرة والبطارية والشبكة والقرص لشرائح Apple Silicon، مقروءة من SMC وIOReport وMach، دون الحاجة إلى powermetrics.',
    primaryAction: 'تنزيل لنظام macOS',
    secondaryAction: 'عرض الميزات',
    screenshotAlt: 'لوحة MMetrics على شريحة M5 Pro',
    menubarAlt: 'عنصر MMetrics في شريط القوائم يعرض CPU والذاكرة ودرجة الحرارة والطاقة',
  },
  features: {
    title: 'كل ما تُبلغ عنه الشريحة، بنظرة واحدة.',
    subtitle: 'القيم التي تتابعها في شريط القوائم، والباقي في اللوحة.',
    menuBar: {
      title: 'شريط قوائم قابل للتخصيص',
      description:
        'خلايا من سطرين: القيمة فوق التسمية. اختر أيًّا من CPU والذاكرة وGPU ودرجة حرارة CPU وطاقة النظام والتنزيل والرفع.',
    },
    clusters: {
      title: 'CPU لكل مجموعة ولكل نواة',
      description:
        'الاستخدام والتردد لكل فئة في الشريحة — Efficiency وPerformance وأنوية Super في M5 — ولكل نواة على حدة.',
    },
    power: {
      title: 'الطاقة ودرجات الحرارة',
      description:
        'طاقة النظام وCPU وGPU بالواط، ودرجات حرارة CPU وGPU، وأسخن نقطة في الشريحة، وسرعة المروحة.',
    },
    dashboard: {
      title: 'لوحة تختار محتواها',
      description:
        'GPU والذاكرة وswap وعرض نطاق DRAM وصحة البطارية والشبكة وإدخال/إخراج القرص وأكثر العمليات استهلاكًا. يمكن إخفاء أي قسم، ويتوقف أخذ العينات للعمليات والشبكة والقرص والبطارية عند إخفائها.',
    },
    widget: {
      title: 'أداة سطح المكتب',
      description: 'أداتان بحجم صغير ومتوسط تعرضان CPU والذاكرة والحالة الحرارية.',
    },
    appearance: {
      title: 'فاتح أو داكن أو تلقائي',
      description: 'يتبع مظهر النظام، أو يمكن تثبيته على أحدهما.',
    },
  },
  sources: {
    title: 'مقروء مباشرةً من macOS.',
    subtitle:
      'واجهات أصلية فقط: لا powermetrics ولا امتدادات للنواة. يأخذ helper اختياري عينات من IOReport وSMC بصلاحيات root، ويعمل التطبيق بدونه.',
    chipsLabel: 'الشرائح المدعومة',
    sourceHeader: 'المصدر',
    dataHeader: 'البيانات',
    mach: 'استخدام CPU والذاكرة وswap',
    ioreport: 'نسبة النشاط والتردد لمجموعات CPU وGPU، وعدادات الطاقة، وعرض نطاق DRAM',
    smc: 'درجات الحرارة، وأسخن نقطة في الشريحة، والمروحة، وطاقة النظام',
    system: 'البطارية، وإدخال/إخراج القرص، والشبكة',
  },
  install: {
    title: 'التثبيت',
    subtitle: 'يتطلب جهاز Mac بشريحة Apple Silicon ونظام macOS 13 Ventura أو أحدث.',
    tapPrompt: '# أضف الـ tap',
    caskPrompt: '# ثبّت MMetrics',
    note: 'أو نزّل ملف DMG من GitHub Releases واسحب MMetrics إلى مجلد التطبيقات. الإصدارات موقّعة بـ Developer ID وموثّقة من Apple.',
  },
  cta: {
    title: 'MMetrics مجاني ومفتوح المصدر بموجب ترخيص MIT.',
    subtitle: 'نرحب على GitHub بالتقارير من الشرائح التي لم تُختبر بعد.',
    homebrewAction: 'التثبيت عبر Homebrew',
    githubAction: 'التنزيل من GitHub Releases',
  },
  footer: {
    features: 'الميزات',
    sources: 'مصادر البيانات',
    releases: 'الإصدارات',
  },
}

export default ar
