import type { Translation } from '../i18n-types.js'

const hi: Translation = {
  meta: {
    lang: 'hi',
    dir: 'ltr',
    title: 'MMetrics — Apple Silicon सिस्टम मॉनिटर',
    description:
      'MMetrics — मेन्यू बार के लिए Apple Silicon सिस्टम मॉनिटर। CPU क्लस्टर, GPU, पावर, तापमान, मेमोरी, बैटरी, नेटवर्क और डिस्क, सीधे macOS के नेटिव इंटरफ़ेस से।',
  },
  nav: {
    features: 'फ़ीचर',
    sources: 'डेटा स्रोत',
    install: 'इंस्टॉल',
    download: 'डाउनलोड',
    languageLabel: 'भाषा',
  },
  hero: {
    titlePrefix: 'आपके Mac के सारे आँकड़े,',
    titleSuffix: 'सीधे मेन्यू बार में।',
    subtitle:
      'MMetrics, Apple Silicon के CPU क्लस्टर, GPU, पावर, तापमान, मेमोरी, बैटरी, नेटवर्क और डिस्क दिखाता है — डेटा SMC, IOReport और Mach से पढ़ा जाता है, powermetrics के बिना।',
    primaryAction: 'macOS के लिए डाउनलोड करें',
    secondaryAction: 'फ़ीचर देखें',
    screenshotAlt: 'M5 Pro पर MMetrics डैशबोर्ड',
    menubarAlt: 'मेन्यू बार में MMetrics, CPU, मेमोरी, तापमान और पावर दिखाते हुए',
  },
  features: {
    title: 'चिप जो भी बताती है, एक नज़र में।',
    subtitle: 'जिन आँकड़ों पर आप नज़र रखते हैं वे मेन्यू बार में, बाकी सब डैशबोर्ड में।',
    menuBar: {
      title: 'कॉन्फ़िगर करने योग्य मेन्यू बार',
      description:
        'दो पंक्तियों वाले सेल, ऊपर मान और नीचे लेबल। CPU, मेमोरी, GPU, CPU तापमान, सिस्टम पावर, डाउनलोड और अपलोड में से कोई भी चुनें।',
    },
    clusters: {
      title: 'क्लस्टर और कोर के अनुसार CPU',
      description:
        'चिप के हर स्तर — Efficiency, Performance और M5 के Super कोर — का उपयोग और फ़्रीक्वेंसी, साथ ही हर कोर अलग से।',
    },
    power: {
      title: 'पावर और तापमान',
      description: 'सिस्टम, CPU और GPU की पावर वॉट में; CPU और GPU तापमान, die hotspot और फ़ैन की गति।',
    },
    dashboard: {
      title: 'अपनी ज़रूरत के हिसाब से डैशबोर्ड',
      description:
        'GPU, मेमोरी और swap, DRAM बैंडविड्थ, बैटरी की सेहत, नेटवर्क, डिस्क I/O और शीर्ष प्रोसेस। कोई भी सेक्शन छिपाएँ; छिपाए गए प्रोसेस, नेटवर्क, डिस्क और बैटरी की सैंपलिंग भी रुक जाती है।',
    },
    widget: {
      title: 'डेस्कटॉप विजेट',
      description: 'छोटे और मध्यम विजेट, CPU, मेमोरी और थर्मल स्थिति के साथ।',
    },
    appearance: {
      title: 'लाइट, डार्क या ऑटोमैटिक',
      description: 'सिस्टम की दिखावट के अनुसार चलता है, या किसी एक पर तय करें।',
    },
  },
  sources: {
    title: 'सीधे macOS से पढ़ा गया।',
    subtitle:
      'केवल नेटिव इंटरफ़ेस: न powermetrics, न कर्नेल एक्सटेंशन। एक वैकल्पिक helper, root के रूप में IOReport और SMC का सैंपल लेता है; ऐप इसके बिना भी काम करता है।',
    chipsLabel: 'समर्थित चिप',
    sourceHeader: 'स्रोत',
    dataHeader: 'डेटा',
    mach: 'CPU उपयोग, मेमोरी, swap',
    ioreport: 'क्लस्टर और GPU की residency व फ़्रीक्वेंसी, ऊर्जा काउंटर, DRAM बैंडविड्थ',
    smc: 'तापमान, die hotspot, फ़ैन, सिस्टम पावर',
    system: 'बैटरी, डिस्क I/O, नेटवर्क',
  },
  install: {
    title: 'इंस्टॉल करें',
    subtitle: 'Apple Silicon वाला Mac और macOS 13 Ventura या उसके बाद का संस्करण आवश्यक है।',
    tapPrompt: '# tap जोड़ें',
    caskPrompt: '# MMetrics इंस्टॉल करें',
    note: 'या GitHub Releases से DMG डाउनलोड करके MMetrics को Applications में खींचें। रिलीज़ Developer ID से साइन और notarize की गई हैं।',
  },
  cta: {
    title: 'MMetrics, MIT लाइसेंस के तहत मुफ़्त और ओपन सोर्स है।',
    subtitle: 'जिन चिप पर अभी परीक्षण नहीं हुआ है, उनकी रिपोर्ट GitHub पर भेजें।',
    homebrewAction: 'Homebrew से इंस्टॉल करें',
    githubAction: 'GitHub Releases से डाउनलोड करें',
  },
  footer: {
    features: 'फ़ीचर',
    sources: 'डेटा स्रोत',
    releases: 'रिलीज़',
  },
}

export default hi
