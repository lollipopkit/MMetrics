<script>
  import { onMount } from 'svelte'
  import LL, { setLocale } from './i18n/i18n-svelte'
  import { loadLocale } from './i18n/i18n-util.sync'
  import { getInitialLocale, locales, localeStorageKey, syncLocaleToUrl } from './lib/i18n.js'
  import dashboard from './assets/dashboard.png'
  import menubar from './assets/menubar.png'

  const repo = 'https://github.com/lollipopkit/MMetrics'
  const chips = ['M1', 'M2', 'M3', 'M4', 'M5']

  /** @type {{ key: 'menuBar' | 'clusters' | 'power' | 'dashboard' | 'widget' | 'appearance', wide: boolean }[]} */
  const features = [
    { key: 'menuBar', wide: false },
    { key: 'clusters', wide: true },
    { key: 'dashboard', wide: true },
    { key: 'power', wide: false },
    { key: 'widget', wide: false },
    { key: 'appearance', wide: true },
  ]

  /** @type {{ name: string, key: 'mach' | 'ioreport' | 'smc' | 'system' }[]} */
  const sources = [
    { name: 'Mach', key: 'mach' },
    { name: 'IOReport', key: 'ioreport' },
    { name: 'SMC', key: 'smc' },
    { name: 'pmset / ioreg / netstat', key: 'system' },
  ]

  function getLocaleBeforeRender() {
    if (typeof window === 'undefined') return undefined

    return getInitialLocale()
  }

  const initialLocale = getLocaleBeforeRender()

  if (initialLocale) {
    loadLocale(initialLocale)
    setLocale(initialLocale)
  }

  let locale = $state(initialLocale)
  let isMounted = $state(false)

  function applyLocale(nextLocale) {
    locale = nextLocale
    loadLocale(nextLocale)
    setLocale(nextLocale)
    localStorage.setItem(localeStorageKey, nextLocale)
  }

  onMount(() => {
    const nextLocale = locale || getInitialLocale()
    applyLocale(nextLocale)
    syncLocaleToUrl(nextLocale)

    isMounted = true
  })

  $effect(() => {
    if (!isMounted) return

    document.documentElement.lang = $LL.meta.lang()
    document.documentElement.dir = $LL.meta.dir()
    document.title = $LL.meta.title()
    document
      .querySelector('meta[name="description"]')
      ?.setAttribute('content', $LL.meta.description())
  })

  function handleLocaleChange(event) {
    const nextLocale = event.currentTarget.value
    applyLocale(nextLocale)
    syncLocaleToUrl(nextLocale)
  }
</script>

{#if locale && isMounted}
  <main class="site">
    <header class="site-nav" id="top">
      <a class="brand" href="#top">
        <img src="/favicon.svg" alt="" width="22" height="22" />
        MMetrics
      </a>
      <nav>
        <a href="#features">{$LL.nav.features()}</a>
        <a href="#sources">{$LL.nav.sources()}</a>
        <a href="#install">{$LL.nav.install()}</a>
      </nav>
      <div class="nav-actions">
        <label class="language-switcher">
          <span class="sr-only">{$LL.nav.languageLabel()}</span>
          <select
            id="locale"
            name="locale"
            aria-label={$LL.nav.languageLabel()}
            value={locale}
            onchange={handleLocaleChange}
          >
            {#each locales as item}
              <option value={item.code}>{item.label}</option>
            {/each}
          </select>
        </label>
        <a class="nav-cta" href="#install">{$LL.nav.download()}</a>
      </div>
    </header>

    <section class="hero" id="hero">
      <div class="hero-copy">
        <h1>{$LL.hero.titlePrefix()}<br />{$LL.hero.titleSuffix()}</h1>
        <p class="hero-subtitle">{$LL.hero.subtitle()}</p>
        <div class="hero-actions">
          <a class="btn btn-primary" href="#install">{$LL.hero.primaryAction()}</a>
          <a class="btn btn-secondary" href="#features">{$LL.hero.secondaryAction()}</a>
        </div>
      </div>
      <figure class="hero-shot">
        <img class="menubar-shot" src={menubar} alt={$LL.hero.menubarAlt()} width="314" height="60" />
        <img class="dashboard-shot" src={dashboard} alt={$LL.hero.screenshotAlt()} width="412" height="712" />
      </figure>
    </section>

    <section class="page-section" id="features">
      <div class="section-head">
        <h2>{$LL.features.title()}</h2>
        <p>{$LL.features.subtitle()}</p>
      </div>

      <div class="feature-grid">
        {#each features as feature}
          <article class="feature-card" class:wide={feature.wide}>
            <h3>{$LL.features[feature.key].title()}</h3>
            <p>{$LL.features[feature.key].description()}</p>
          </article>
        {/each}
      </div>
    </section>

    <section class="page-section" id="sources">
      <div class="section-head">
        <h2>{$LL.sources.title()}</h2>
        <p>{$LL.sources.subtitle()}</p>
      </div>

      <p class="badge-label">{$LL.sources.chipsLabel()}</p>
      <div class="badges">
        {#each chips as chip}
          <span class="badge">{chip}</span>
        {/each}
      </div>

      <div class="table-wrap">
        <table class="source-table">
          <thead>
            <tr>
              <th>{$LL.sources.sourceHeader()}</th>
              <th>{$LL.sources.dataHeader()}</th>
            </tr>
          </thead>
          <tbody>
            {#each sources as source}
              <tr>
                <td><code dir="ltr">{source.name}</code></td>
                <td>{$LL.sources[source.key]()}</td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>
    </section>

    <section class="page-section" id="install">
      <div class="section-head">
        <h2>{$LL.install.title()}</h2>
        <p>{$LL.install.subtitle()}</p>
      </div>

      <div class="code-block" dir="ltr">
        <span class="prompt">{$LL.install.tapPrompt()}</span>
        <span class="command">brew tap lollipopkit/mmetrics {repo}</span>
        <span class="prompt">{$LL.install.caskPrompt()}</span>
        <span class="command">brew install --cask mmetrics</span>
      </div>
      <p class="install-note">{$LL.install.note()}</p>
    </section>

    <section class="cta-section" id="download">
      <div class="cta-block">
        <h2>{$LL.cta.title()}</h2>
        <p>{$LL.cta.subtitle()}</p>
        <div class="cta-actions">
          <a class="btn btn-secondary" href="#install">{$LL.cta.homebrewAction()}</a>
          <a class="btn btn-primary" href="{repo}/releases/latest">{$LL.cta.githubAction()}</a>
        </div>
      </div>
    </section>

    <footer class="site-footer">
      <span>© 2026 MMetrics</span>
      <div class="footer-links">
        <a href="#features">{$LL.footer.features()}</a>
        <a href="#sources">{$LL.footer.sources()}</a>
        <a href={repo}>GitHub</a>
        <a href="{repo}/releases">{$LL.footer.releases()}</a>
      </div>
    </footer>
  </main>
{/if}
