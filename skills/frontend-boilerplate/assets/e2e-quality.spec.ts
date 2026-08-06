import { expect, test, type Page } from '@playwright/test'
import budgets from './budgets.json' with { type: 'json' }

const BASE = process.env.BASE_URL ?? 'http://localhost:3000'

type Rgb = [number, number, number]

/* Vite 系の開発サーバーは CSS を JS で注入するため、goto 直後はトークンが未適用のことがある */
async function ready(page: Page) {
  await page.waitForLoadState('networkidle')
  await page.waitForFunction(
    () => getComputedStyle(document.documentElement).getPropertyValue('--fg').trim() !== '',
  )
}

/** oklch を含む任意の CSS 色を sRGB へ解決する。canvas の色解析をブラウザに任せる */
async function resolveVar(page: Page, name: string): Promise<Rgb> {
  return page.evaluate((v) => {
    const raw = getComputedStyle(document.documentElement).getPropertyValue(v).trim()
    if (!raw) throw new Error(`変数が未定義です: ${v}`)
    const canvas = document.createElement('canvas')
    canvas.width = canvas.height = 1
    const ctx = canvas.getContext('2d')
    if (!ctx) throw new Error('canvas 2d を取得できません')
    ctx.fillStyle = '#ff00ff'
    const sentinel = ctx.fillStyle
    ctx.fillStyle = raw
    if (ctx.fillStyle === sentinel) throw new Error(`色を解決できません: ${v} = ${raw}`)
    ctx.fillRect(0, 0, 1, 1)
    const d = ctx.getImageData(0, 0, 1, 1).data
    return [d[0], d[1], d[2]] as [number, number, number]
  }, name)
}

function luminance([r, g, b]: Rgb): number {
  const f = (v: number) => {
    const c = v / 255
    return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4
  }
  return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)
}

function contrast(a: Rgb, b: Rgb): number {
  const la = luminance(a)
  const lb = luminance(b)
  const hi = Math.max(la, lb)
  const lo = Math.min(la, lb)
  return (hi + 0.05) / (lo + 0.05)
}

async function applyTheme(page: Page, theme: string) {
  await page.evaluate((t) => {
    const root = document.documentElement
    root.removeAttribute('data-theme')
    root.removeAttribute('data-contrast')
    if (t === 'light' || t === 'dark') root.setAttribute('data-theme', t)
    if (t === 'high-contrast') root.setAttribute('data-contrast', 'high')
  }, theme)
}

// 段6（--line）と段7（--edge）は装飾の罫線。12段体系はこれらに 3:1 を保証しない。
// 部品の識別に必要な境界は --edge-control として分けており、そちらを測る
// --fg-muted は段11の補足文字。淡く落として階層を作るため AA より緩い基準を当てている
const PAIRS: Array<{ fg: string; bg: string; kind: 'text' | 'secondaryText' | 'ui' }> = [
  { fg: '--fg', bg: '--bg', kind: 'text' },
  { fg: '--fg-muted', bg: '--bg', kind: 'secondaryText' },
  { fg: '--fg', bg: '--bg-subtle', kind: 'text' },
  { fg: '--fg', bg: '--comp', kind: 'text' },
  { fg: '--on-solid', bg: '--acc-solid', kind: 'text' },
  { fg: '--acc-fg', bg: '--bg', kind: 'text' },
  { fg: '--danger-11', bg: '--danger-bg', kind: 'text' },
  { fg: '--success-11', bg: '--success-bg', kind: 'text' },
  { fg: '--edge-control', bg: '--bg', kind: 'ui' },
]

// 生成式は測定の代わりにならないため、導出後の実値を全テーマで測る
for (const theme of budgets.themes) {
  test(`コントラスト比 (${theme})`, async ({ page }) => {
    await page.goto(BASE)
    await ready(page)
    await applyTheme(page, theme)

    for (const { fg, bg, kind } of PAIRS) {
      const required =
        kind === 'text'
          ? budgets.contrast.text
          : kind === 'secondaryText'
            ? budgets.contrast.secondaryText
            : budgets.contrast.largeTextAndUi
      const ratio = contrast(await resolveVar(page, fg), await resolveVar(page, bg))
      expect(ratio, `${fg} on ${bg} (${theme})`).toBeGreaterThanOrEqual(required)
    }
  })

  test(`視覚回帰 (${theme})`, async ({ page }) => {
    await page.goto(BASE)
    await ready(page)
    await applyTheme(page, theme)
    await page.waitForLoadState('networkidle')
    await expect(page).toHaveScreenshot(`home-${theme}.png`, { maxDiffPixelRatio: 0.01 })
  })
}

test('LCP と CLS', async ({ page }) => {
  await page.goto(BASE)
  await ready(page)
  await page.waitForLoadState('networkidle')

  const metrics = await page.evaluate(
    () =>
      new Promise<{ lcp: number; cls: number }>((resolve) => {
        let lcp = 0
        let cls = 0
        new PerformanceObserver((list) => {
          for (const e of list.getEntries()) lcp = Math.max(lcp, e.startTime)
        }).observe({ type: 'largest-contentful-paint', buffered: true })
        new PerformanceObserver((list) => {
          for (const e of list.getEntries()) {
            const shift = e as PerformanceEntry & { hadRecentInput: boolean; value: number }
            if (!shift.hadRecentInput) cls += shift.value
          }
        }).observe({ type: 'layout-shift', buffered: true })
        setTimeout(() => resolve({ lcp, cls }), 3000)
      }),
  )

  expect(metrics.lcp).toBeLessThanOrEqual(budgets.webVitals.lcpMs)
  expect(metrics.cls).toBeLessThanOrEqual(budgets.webVitals.cls)
})

test('操作対象の寸法', async ({ page }) => {
  await page.goto(BASE)
  await ready(page)
  const small = await page.evaluate((m) => {
    const targets = document.querySelectorAll('button, a, input, select, [role="button"]')
    const out: string[] = []
    for (const el of Array.from(targets)) {
      const r = el.getBoundingClientRect()
      if (r.width === 0 && r.height === 0) continue
      // 本文中のインラインリンクは行高に従うため下限を満たせない。SC 2.5.8 の除外規定に当たる
      if (el.tagName === 'A' && getComputedStyle(el).display === 'inline') continue
      if (r.width < m || r.height < m) {
        out.push(`${el.tagName.toLowerCase()} ${Math.round(r.width)}x${Math.round(r.height)}`)
      }
    }
    return out
  }, budgets.target.minPx)
  expect(small, `操作対象が ${budgets.target.minPx}px を下回っています`).toEqual([])
})

test('最小対応幅で横スクロールが出ない', async ({ browser }) => {
  const context = await browser.newContext({
    viewport: { width: budgets.viewport.minSupportedPx, height: 900 },
  })
  const page = await context.newPage()
  await page.goto(BASE)
  await ready(page)
  const overflow = await page.evaluate(() => {
    const root = document.scrollingElement
    if (!root) return null
    // 1px の差は端数の丸めで生じるため許容する
    if (root.scrollWidth - root.clientWidth <= 1) return null
    const wide: string[] = []
    for (const el of Array.from(document.body.querySelectorAll('*'))) {
      const r = el.getBoundingClientRect()
      if (r.right > root.clientWidth + 1) {
        // SVG 要素の className は文字列ではないため型で分岐する
        const cls = typeof el.className === 'string' ? el.className : ''
        wide.push(`${el.tagName.toLowerCase()}.${cls} right=${Math.round(r.right)}`)
      }
    }
    return { scrollWidth: root.scrollWidth, clientWidth: root.clientWidth, wide: wide.slice(0, 5) }
  })
  await context.close()
  expect(overflow, '最小対応幅で横スクロールが発生しています').toBeNull()
})

test('内容の極端値で崩れない', async ({ page }) => {
  await page.goto(BASE)
  await ready(page)
  const escaped = await page.evaluate(() => {
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT)
    const texts: Text[] = []
    while (walker.nextNode()) texts.push(walker.currentNode as Text)
    for (const node of texts) {
      const t = node.textContent ?? ''
      if (!t.trim()) continue
      // SVG 内の文字は座標指定で配置され、膨張させても箱の外へ出たかを判定できない
      if (node.parentElement?.closest('svg')) continue
      if (/[0-9０-９]/.test(t)) node.textContent = '9,999,999,999,999'
      else node.textContent = t + t
    }
    const out: string[] = []
    const root = document.scrollingElement
    if (root && root.scrollWidth - root.clientWidth > 1) {
      out.push(`document ${root.scrollWidth}>${root.clientWidth}`)
    }
    for (const el of Array.from(document.body.querySelectorAll('*'))) {
      if (!(el instanceof HTMLElement)) continue
      if (el.clientWidth === 0) continue
      if (getComputedStyle(el).overflowX !== 'visible') continue
      // 8px は境界と端数の許容。overflow が visible のまま内容が箱を越えたら設計漏れ
      if (el.scrollWidth > el.clientWidth + 8) {
        const cls = el.className.split(' ').slice(0, 3).join('.')
        out.push(`${el.tagName.toLowerCase()}.${cls} ${el.scrollWidth}>${el.clientWidth}`)
      }
    }
    return out.slice(0, 10)
  })
  expect(
    escaped,
    '長い内容がはみ出しています。切り詰めるか、スクロールする区画の内側に閉じてください',
  ).toEqual([])
})
