const { chromium } = require('playwright-core');
const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');

const ROOT = '/home/z/vouch/design-reference';
const PROFILE = 'https://dribbble.com/slavakornilov';
const UA =
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36';

const slug = (s) =>
  s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 60) || 'shot';

async function download(url, dest) {
  if (!url) return false;
  try {
    const stat = await fsp.stat(dest).catch(() => null);
    if (stat && stat.size > 1000) return true;
    const res = await fetch(url, {
      headers: { 'User-Agent': UA, Referer: 'https://dribbble.com/' },
    });
    if (!res.ok) {
      console.error('  download failed', res.status, url);
      return false;
    }
    const buf = Buffer.from(await res.arrayBuffer());
    if (buf.length < 1000) {
      console.error('  download too small', buf.length, url);
      return false;
    }
    await fsp.writeFile(dest, buf);
    console.log('  saved', path.basename(dest), (buf.length / 1024).toFixed(0) + 'KB');
    return true;
  } catch (e) {
    console.error('  download error', e.message, url);
    return false;
  }
}

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
    userAgent: UA,
    locale: 'en-US',
  });
  const page = await ctx.newPage();

  // 1. Collect shot links from profile + pages + collections.
  const shots = new Map();
  const sources = [
    PROFILE,
    PROFILE + '?page=2',
    PROFILE + '?page=3',
    PROFILE + '/collections',
  ];
  const collections = new Set();

  for (const url of sources) {
    console.log('SOURCE', url);
    try {
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 90000 });
      await page.waitForTimeout(4000);
      for (let i = 0; i < 3; i++) {
        await page.mouse.wheel(0, 1600);
        await page.waitForTimeout(900);
      }
      const found = await page.evaluate(() => {
        const links = [];
        for (const a of document.querySelectorAll('a[href*="/shots/"]')) {
          const href = a.getAttribute('href') || '';
          const m = href.match(/\/shots\/(\d+)(?:-([^/?#]+))?/);
          if (!m) continue;
          links.push({ id: m[1], slugPart: m[2] || '', href: 'https://dribbble.com/shots/' + m[1] + (m[2] ? '-' + m[2] : '') });
        }
        const cols = [];
        for (const a of document.querySelectorAll('a[href*="/collections/"]')) {
          const href = a.getAttribute('href') || '';
          if (href.includes('/slavakornilov/collections/')) cols.push('https://dribbble.com' + href.split('?')[0]);
        }
        return { links, cols };
      });
      for (const l of found.links) if (!shots.has(l.id)) shots.set(l.id, { ...l, sources: [url] });
      for (const c of found.cols) collections.add(c);
      console.log('  links', found.links.length, 'new total', shots.size, 'collections', found.cols.length);
    } catch (e) {
      console.error('  source error', e.message);
    }
  }

  // Collections often hold many more shots; crawl each collection page.
  for (const c of collections) {
    console.log('COLLECTION', c);
    try {
      await page.goto(c, { waitUntil: 'domcontentloaded', timeout: 90000 });
      await page.waitForTimeout(3500);
      for (let i = 0; i < 2; i++) {
        await page.mouse.wheel(0, 1600);
        await page.waitForTimeout(800);
      }
      const found = await page.evaluate(() => {
        const links = [];
        for (const a of document.querySelectorAll('a[href*="/shots/"]')) {
          const href = a.getAttribute('href') || '';
          const m = href.match(/\/shots\/(\d+)(?:-([^/?#]+))?/);
          if (!m) continue;
          links.push({ id: m[1], slugPart: m[2] || '', href: 'https://dribbble.com/shots/' + m[1] + (m[2] ? '-' + m[2] : '') });
        }
        return links;
      });
      for (const l of found.links) if (!shots.has(l.id)) shots.set(l.id, { ...l, sources: [c] });
      console.log('  new total', shots.size);
    } catch (e) {
      console.error('  collection error', e.message);
    }
  }

  const list = [...shots.values()];
  console.log('TOTAL SHOTS', list.length);
  await fsp.writeFile(
    path.join(ROOT, 'manifest.json'),
    JSON.stringify({ collectedAt: new Date().toISOString(), shots: list }, null, 2),
  );

  // 2. Visit each shot, capture metadata, screenshot, download still + video.
  const manifest = [];
  for (let i = 0; i < list.length; i++) {
    const s = list[i];
    const label = `${i + 1}/${list.length} ${s.id}`;
    console.log('SHOT', label, s.href);
    try {
      await page.goto(s.href, { waitUntil: 'domcontentloaded', timeout: 90000 });
      await page.waitForTimeout(3500);
      const meta = await page.evaluate(() => {
        const get = (p) =>
          document.querySelector(`meta[property="${p}"]`)?.content ||
          document.querySelector(`meta[name="${p}"]`)?.content ||
          '';
        return {
          title: document.title.replace(/ on Dribbble$/, ''),
          description: get('description'),
          ogImage: get('og:image'),
          ogVideo: get('og:video'),
          twitterImage: get('twitter:image'),
          images: Array.from(document.querySelectorAll('img'))
            .map((x) => x.currentSrc || x.src)
            .filter((x) => x.includes('cdn.dribbble.com/userupload')),
          videos: Array.from(document.querySelectorAll('video, video source'))
            .map((x) => x.src || x.currentSrc)
            .filter((x) => x && x.includes('.mp4')),
        };
      });
      const name = `${s.id}-${slug(s.slugPart || meta.title || 'shot')}`;
      const still = meta.ogImage || meta.images[0] || '';
      const stillBase = still.split('?')[0];
      const stillHi = stillBase ? stillBase + '?resize=2400x2400' : '';
      const stillPath = path.join(ROOT, 'stills', name + '.png');
      const gotStill = stillHi
        ? (await download(stillHi, stillPath)) || (await download(stillBase, stillPath))
        : false;

      await page.screenshot({
        path: path.join(ROOT, 'pages', name + '.png'),
        fullPage: false,
      });

      const video = (meta.videos && meta.videos[0]) || meta.ogVideo || '';
      let videoPath = '';
      if (video) {
        videoPath = path.join(ROOT, 'video', name + '.mp4');
        await download(video, videoPath);
      }

      manifest.push({
        ...s,
        title: meta.title,
        description: meta.description,
        still: gotStill ? path.relative(ROOT, stillPath) : '',
        video: videoPath,
        videoOk: videoPath ? fs.existsSync(videoPath) : false,
      });
      await fsp.writeFile(
        path.join(ROOT, 'manifest.json'),
        JSON.stringify({ collectedAt: new Date().toISOString(), shots: manifest }, null, 2),
      );
    } catch (e) {
      console.error('  shot error', e.message);
      manifest.push({ ...s, error: e.message });
    }
  }

  console.log('DONE', manifest.length);
  await browser.close();
})().catch((e) => {
  console.error('FATAL', e);
  process.exit(1);
});
