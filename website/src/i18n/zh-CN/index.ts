import type { Translation } from '../i18n-types.js'

const zhCN: Translation = {
  meta: {
    lang: 'zh-CN',
    dir: 'ltr',
    title: 'MMetrics — Apple Silicon 系统监控',
    description:
      'MMetrics — 菜单栏里的 Apple Silicon 系统监控。CPU cluster、GPU、功耗、温度、内存、电池、网络和磁盘，数据直接来自 macOS 原生接口。',
  },
  nav: {
    features: '功能',
    sources: '数据来源',
    install: '安装',
    download: '下载',
    languageLabel: '语言',
  },
  hero: {
    titlePrefix: '你的 Mac，',
    titleSuffix: '尽在菜单栏。',
    subtitle:
      'MMetrics 为 Apple Silicon 显示 CPU cluster、GPU、功耗、温度、内存、电池、网络和磁盘，数据读取自 SMC、IOReport 和 Mach，不依赖 powermetrics。',
    primaryAction: '下载 macOS 版',
    secondaryAction: '查看功能',
    screenshotAlt: 'M5 Pro 上的 MMetrics 面板',
    menubarAlt: 'MMetrics 菜单栏项，显示 CPU、内存、温度和功耗',
  },
  features: {
    title: '芯片上报的数据，一眼看全。',
    subtitle: '常看的数值放在菜单栏，其余的放在面板里。',
    menuBar: {
      title: '可配置的菜单栏',
      description: '双行显示，上方数值、下方标签。可从 CPU、内存、GPU、CPU 温度、系统功耗、下载和上传中任选。',
    },
    clusters: {
      title: '按 cluster 和按核心的 CPU',
      description:
        '显示芯片具备的每一层的利用率和频率，包括 Efficiency、Performance 以及 M5 的 Super 核心，也显示每个核心的数值。',
    },
    power: {
      title: '功耗与温度',
      description: '系统、CPU、GPU 功耗（瓦），CPU 与 GPU 温度、die hotspot 和风扇转速。',
    },
    dashboard: {
      title: '可裁剪的面板',
      description:
        'GPU、内存与 swap、DRAM 带宽、电池健康度、网络、磁盘 I/O 和 Top Processes。每个 section 都可隐藏；隐藏后的进程、网络、磁盘和电池同时停止采样。',
    },
    widget: {
      title: '桌面 Widget',
      description: '小号和中号 Widget，显示 CPU、内存和散热状态。',
    },
    appearance: {
      title: '浅色、深色或自动',
      description: '跟随系统外观，或固定为其中一种。',
    },
  },
  sources: {
    title: '直接读取 macOS。',
    subtitle:
      '只使用原生接口：不依赖 powermetrics，也不需要内核扩展。可选的 helper 以 root 身份采样 IOReport 和 SMC；不安装也能正常使用。',
    chipsLabel: '支持的芯片',
    sourceHeader: '来源',
    dataHeader: '数据',
    mach: 'CPU 利用率、内存、swap',
    ioreport: 'Cluster 与 GPU 的 residency 和频率、能耗计数器、DRAM 带宽',
    smc: '温度、die hotspot、风扇、系统功耗',
    system: '电池、磁盘 I/O、网络',
  },
  install: {
    title: '安装',
    subtitle: '需要 Apple Silicon Mac，macOS 13 Ventura 或更高版本。',
    tapPrompt: '# 添加 tap',
    caskPrompt: '# 安装 MMetrics',
    note: '也可以从 GitHub Releases 下载 DMG，将 MMetrics 拖入“应用程序”。发布版本使用 Developer ID 签名并经过公证。',
  },
  cta: {
    title: 'MMetrics 基于 MIT 协议免费开源。',
    subtitle: '欢迎在 GitHub 上反馈尚未测试过的芯片。',
    homebrewAction: '通过 Homebrew 安装',
    githubAction: '从 GitHub Releases 下载',
  },
  footer: {
    features: '功能',
    sources: '数据来源',
    releases: '版本发布',
  },
}

export default zhCN
