const { chromium } = require('playwright-core');

(async () => {
  const browser = await chromium.launch({
    executablePath: '/usr/bin/google-chrome',
    headless: true,
    args: [
      '--no-first-run',
      '--no-default-browser-check',
      '--disable-blink-features=AutomationControlled',
    ],
  });
  const ctx = await browser.newContext({
    viewport: { width: 1440, height: 1000 },
    userAgent:
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36',
    locale: 'en-US',
  });
  const page = await ctx.newPage();
  await page.goto('https://dribbble.com/slavakornilov', {
    waitUntil: 'domcontentloaded',
    timeout: 90000,
  });
  await page.waitForTimeout(6000);
  for (let i = 0; i < 3; i++) {
    await page.mouse.wheel(0, 1400);
    await page.waitForTimeout(1200);
  }
  console.log('TITLE', await page.title());
  console.log('URL', page.url());
  const body = await page.locator('body').innerText().catch(() => '');
  console.log('BODY', body.slice(0, 600).replace(/\n+/g, ' | '));

  const shots = await page.evaluate(() => {
    const out = [];
    const seen = new Set();
    for (const a of document.querySelectorAll('a[href*="/shots/"]')) {
      const href = a.getAttribute('href') || '';
      const m = href.match(/\/shots\/(\d+)/);
      if (!m || seen.has(m[1])) continue;
      seen.add(m[1]);
      const img = a.querySelector('img');
      out.push({
        id: m[1],
        href: 'https://dribbble.com' + href.split('?')[0],
        title:
          (img && (img.getAttribute('alt') || img.getAttribute('title'))) || '',
        src: img ? img.currentSrc || img.src || '' : '',
      });
    }
    return out;
  });
  console.log('SHOTS', shots.length);
  console.log(JSON.stringify(shots, null, 1));

  if (shots.length) {
    const shot = await ctx.newPage();
    await shot.goto(shots[0].href, {
      waitUntil: 'domcontentloaded',
      timeout: 90000,
    });
    await shot.waitForTimeout(6000);
    const meta = await shot.evaluate(() => {
      const get = (p) =>
        document.querySelector(`meta[property="${p}"]`)?.content ||
        document.querySelector(`meta[name="${p}"]`)?.content ||
        '';
      return {
        title: document.title,
        ogImage: get('og:image'),
        ogVideo: get('og:video'),
        twitterImage: get('twitter:image'),
        imgs: Array.from(document.querySelectorAll('img'))
          .map((i) => i.currentSrc || i.src)
          .filter((s) => s.includes('cdn.dribbble.com'))
          .slice(0, 12),
        videos: Array.from(document.querySelectorAll('video source, video'))
          .map((v) => v.src || v.currentSrc)
          .filter(Boolean)
          .slice(0, 8),
      };
    });
    console.log('SHOT_META', JSON.stringify(meta, null, 1));
    await shot.screenshot({ path: '/tmp/dribbble-shot.png', fullPage: false });
  }
  await browser.close();
})().catch((e) => {
  console.error('ERR', e.message);
  process.exit(1);
});
