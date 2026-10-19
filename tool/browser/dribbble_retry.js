const { chromium } = require('playwright-core');
const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');

const ROOT = '/home/z/vouch/design-reference';
const UA =
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36';

const slug = (s) =>
  s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 60) || 'shot';

async function download(url, dest) {
  if (!url) return false;
  try {
    const stat = await fsp.stat(dest).catch(() => null);
    if (stat && stat.size > 1000) return true;
    const res = await fetch(url, { headers: { 'User-Agent': UA, Referer: 'https://dribbble.com/' } });
    if (!res.ok) return false;
    const buf = Buffer.from(await res.arrayBuffer());
    if (buf.length < 1000) return false;
    await fsp.writeFile(dest, buf);
    return true;
  } catch (_) {
    return false;
  }
}

(async () => {
  const manifestPath = path.join(ROOT, 'manifest.json');
  const manifest = JSON.parse(await fsp.readFile(manifestPath, 'utf8'));
  const missing = manifest.shots.filter((s) => !s.still);
  console.log('RETRY', missing.length);

  const browser = await chromium.launch({
    executablePath: '/usr/bin/google-chrome',
    headless: true,
    args: ['--no-first-run', '--no-default-browser-check', '--disable-blink-features=AutomationControlled'],
  });
  const ctx = await browser.newContext({ viewport: { width: 1440, height: 1000 }, userAgent: UA, locale: 'en-US' });
  const page = await ctx.newPage();

  for (let i = 0; i < missing.length; i++) {
    const s = missing[i];
    console.log('RETRY', i + 1, '/', missing.length, s.id, s.href);
    let ok = false;
    for (let attempt = 1; attempt <= 2 && !ok; attempt++) {
      try {
        await page.goto(s.href, { waitUntil: 'domcontentloaded', timeout: 90000 });
        await page.waitForTimeout(attempt === 1 ? 9000 : 14000);
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
            videos: Array.from(document.querySelectorAll('video, video source'))
              .map((x) => x.src || x.currentSrc)
              .filter((x) => x && x.includes('.mp4')),
          };
        });
        if (!meta.ogImage) throw new Error('no og:image');
        const name = `${s.id}-${slug(s.slugPart || meta.title || 'shot')}`;
        const base = meta.ogImage.split('?')[0];
        const stillPath = path.join(ROOT, 'stills', name + '.png');
        const got = await download(base + '?resize=2400x2400', stillPath) || (await download(base, stillPath));
        if (!got) throw new Error('still download failed');
        await page.screenshot({ path: path.join(ROOT, 'pages', name + '.png'), fullPage: false });
        const video = (meta.videos && meta.videos[0]) || meta.ogVideo || '';
        let videoPath = '';
        if (video) {
          videoPath = path.join(ROOT, 'video', name + '.mp4');
          await download(video, videoPath);
        }
        s.title = meta.title;
        s.description = meta.description;
        s.still = path.relative(ROOT, stillPath);
        s.video = videoPath;
        s.videoOk = videoPath ? fs.existsSync(videoPath) : false;
        delete s.error;
        ok = true;
        console.log('  ok', name);
      } catch (e) {
        console.log('  attempt', attempt, 'failed', e.message);
      }
    }
    await fsp.writeFile(manifestPath, JSON.stringify(manifest, null, 2));
  }
  console.log('DONE');
  await browser.close();
})().catch((e) => {
  console.error('FATAL', e);
  process.exit(1);
});
