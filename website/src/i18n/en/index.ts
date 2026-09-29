import type { BaseTranslation } from '../i18n-types.js'

const en: BaseTranslation = {
  meta: {
    lang: 'en',
    dir: 'ltr',
    title: 'MMetrics — Apple Silicon system monitor',
    description:
      'MMetrics — Apple Silicon system monitor for the menu bar. CPU clusters, GPU, power, temperatures, memory, battery, network and disk, read from native macOS interfaces.',
  },
  nav: {
    features: 'Features',
    sources: 'Data sources',
    install: 'Install',
    download: 'Download',
    languageLabel: 'Language',
  },
  hero: {
    titlePrefix: 'Your Mac, measured.',
    titleSuffix: 'Right in the menu bar.',
    subtitle:
      'MMetrics shows CPU clusters, GPU, power, temperatures, memory, battery, network and disk for Apple Silicon — read from SMC, IOReport and Mach, without powermetrics.',
    primaryAction: 'Download for macOS',
    secondaryAction: 'See features',
    screenshotAlt: 'MMetrics dashboard on an M5 Pro',
    menubarAlt: 'MMetrics menu bar item showing CPU, memory, temperature and power',
  },
  features: {
    title: 'Everything the chip reports, in one glance.',
    subtitle: 'A menu bar item for the numbers you watch, a dashboard for the rest.',
    menuBar: {
      title: 'Configurable menu bar',
      description:
        'Two-row cells, value over caption. Pick any of CPU, memory, GPU, CPU temperature, system power, download and upload.',
    },
    clusters: {
      title: 'Per-cluster and per-core CPU',
      description:
        'Usage and frequency for each tier the chip has — Efficiency, Performance and the M5 Super cores — plus every core individually.',
    },
    power: {
      title: 'Power and temperatures',
      description:
        'System, CPU and GPU power in watts, CPU and GPU temperatures, die hotspot and fan speed.',
    },
    dashboard: {
      title: 'A dashboard you can trim',
      description:
        'GPU, memory and swap, DRAM bandwidth, battery health, network, disk I/O and top processes. Hide any section; hidden processes, network, disk and battery also stop sampling.',
    },
    widget: {
      title: 'Desktop widget',
      description: 'Small and medium widgets with CPU, memory and thermal state.',
    },
    appearance: {
      title: 'Light, dark or automatic',
      description: 'Follows the system appearance, or pin it to one.',
    },
  },
  sources: {
    title: 'Read straight from macOS.',
    subtitle:
      'Native interfaces only: no powermetrics, no kernel extension. An optional helper samples IOReport and SMC as root; the app works without it.',
    chipsLabel: 'Supported chips',
    sourceHeader: 'Source',
    dataHeader: 'Data',
    mach: 'CPU usage, memory, swap',
    ioreport: 'Cluster and GPU residency and frequency, energy counters, DRAM bandwidth',
    smc: 'Temperatures, die hotspot, fan, system power',
    system: 'Battery, disk I/O, network',
  },
  install: {
    title: 'Install',
    subtitle: 'Requires an Apple Silicon Mac and macOS 13 Ventura or later.',
    tapPrompt: '# add the tap',
    caskPrompt: '# install MMetrics',
    note: 'Or download the DMG from GitHub Releases and drag MMetrics to Applications. Releases are signed with Developer ID and notarized.',
  },
  cta: {
    title: 'MMetrics is free and open source under MIT.',
    subtitle: 'Reports from chips not yet tested are welcome on GitHub.',
    homebrewAction: 'Install with Homebrew',
    githubAction: 'Download from GitHub Releases',
  },
  footer: {
    features: 'Features',
    sources: 'Data sources',
    releases: 'Releases',
  },
}

export default en
