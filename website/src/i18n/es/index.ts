import type { Translation } from '../i18n-types.js'

const es: Translation = {
  meta: {
    lang: 'es',
    dir: 'ltr',
    title: 'MMetrics — Monitor del sistema para Apple Silicon',
    description:
      'MMetrics — Monitor del sistema para Apple Silicon en la barra de menús. Clústeres de CPU, GPU, consumo, temperaturas, memoria, batería, red y disco, leídos de las interfaces nativas de macOS.',
  },
  nav: {
    features: 'Funciones',
    sources: 'Fuentes de datos',
    install: 'Instalar',
    download: 'Descargar',
    languageLabel: 'Idioma',
  },
  hero: {
    titlePrefix: 'Tu Mac, medido.',
    titleSuffix: 'En la barra de menús.',
    subtitle:
      'MMetrics muestra los clústeres de CPU, GPU, consumo, temperaturas, memoria, batería, red y disco de Apple Silicon, leídos de SMC, IOReport y Mach, sin powermetrics.',
    primaryAction: 'Descargar para macOS',
    secondaryAction: 'Ver funciones',
    screenshotAlt: 'Panel de MMetrics en un M5 Pro',
    menubarAlt: 'Elemento de MMetrics en la barra de menús con CPU, memoria, temperatura y consumo',
  },
  features: {
    title: 'Todo lo que informa el chip, de un vistazo.',
    subtitle: 'La barra de menús para los valores que vigilas; el panel para el resto.',
    menuBar: {
      title: 'Barra de menús configurable',
      description:
        'Celdas de dos líneas, valor sobre etiqueta. Elige entre CPU, memoria, GPU, temperatura de CPU, consumo del sistema, descarga y subida.',
    },
    clusters: {
      title: 'CPU por clúster y por núcleo',
      description:
        'Uso y frecuencia de cada nivel que tenga el chip —Efficiency, Performance y los núcleos Super del M5— y de cada núcleo por separado.',
    },
    power: {
      title: 'Consumo y temperaturas',
      description:
        'Consumo del sistema, CPU y GPU en vatios; temperaturas de CPU y GPU, punto más caliente del die y velocidad del ventilador.',
    },
    dashboard: {
      title: 'Un panel a tu medida',
      description:
        'GPU, memoria y swap, ancho de banda DRAM, salud de la batería, red, E/S de disco y procesos principales. Oculta cualquier sección; los procesos, la red, el disco y la batería ocultos dejan de muestrearse.',
    },
    widget: {
      title: 'Widget de escritorio',
      description: 'Widgets pequeño y mediano con CPU, memoria y estado térmico.',
    },
    appearance: {
      title: 'Claro, oscuro o automático',
      description: 'Sigue la apariencia del sistema o fíjala en una.',
    },
  },
  sources: {
    title: 'Leído directamente de macOS.',
    subtitle:
      'Solo interfaces nativas: sin powermetrics ni extensiones del kernel. Un helper opcional muestrea IOReport y SMC como root; la app funciona sin él.',
    chipsLabel: 'Chips compatibles',
    sourceHeader: 'Fuente',
    dataHeader: 'Datos',
    mach: 'Uso de CPU, memoria, swap',
    ioreport: 'Residencia y frecuencia de clústeres y GPU, contadores de energía, ancho de banda DRAM',
    smc: 'Temperaturas, punto más caliente del die, ventilador, consumo del sistema',
    system: 'Batería, E/S de disco, red',
  },
  install: {
    title: 'Instalar',
    subtitle: 'Requiere un Mac con Apple Silicon y macOS 13 Ventura o posterior.',
    tapPrompt: '# añade el tap',
    caskPrompt: '# instala MMetrics',
    note: 'También puedes descargar el DMG desde GitHub Releases y arrastrar MMetrics a Aplicaciones. Las versiones están firmadas con Developer ID y notarizadas.',
  },
  cta: {
    title: 'MMetrics es gratuito y de código abierto bajo la licencia MIT.',
    subtitle: 'Los informes de chips aún no probados son bienvenidos en GitHub.',
    homebrewAction: 'Instalar con Homebrew',
    githubAction: 'Descargar desde GitHub Releases',
  },
  footer: {
    features: 'Funciones',
    sources: 'Fuentes de datos',
    releases: 'Versiones',
  },
}

export default es
