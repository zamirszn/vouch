const { chromium } = require('playwright-core');
(async () => {
  const ctx = await chromium.launchPersistentContext('/tmp/chrome-fb', {
    executablePath: '/usr/bin/google-chrome', headless: true,
    viewport: { width: 1440, height: 1000 },
    ignoreDefaultArgs: ['--use-mock-keychain', '--password-store=basic'],
    args: ['--profile-directory=Default', '--password-store=gnome-libsecret', '--no-first-run'],
  });
  const page = ctx.pages()[0] || (await ctx.newPage());
  await page.goto('https://console.firebase.google.com/u/0/project/vouch-tracker/firestore', { waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(10000);
  await page.getByRole('tab', { name: /^Rules$/ }).click();
  await page.waitForTimeout(9000);
  const html = await page.content();
  let i = -1;
  let n = 0;
  while ((i = html.toLowerCase().indexOf('publish', i + 1)) >= 0 && n < 5) {
    console.log('--- occurrence', n, '---');
    console.log(html.slice(Math.max(0, i - 500), i + 500));
    n++;
  }
  // Elements whose DOM node mentions publish
  const els = await page.locator('*').evaluateAll(nodes => nodes
    .filter(el => el.getAttribute && /publish/i.test(el.getAttribute('aria-label') || '') || /publish/i.test(el.getAttribute && (el.getAttribute('title')||'')))
    .map(el => ({tag: el.tagName, aria: el.getAttribute('aria-label'), title: el.getAttribute('title')})));
  console.log('PUBLISH LABELED:', JSON.stringify(els));
  await ctx.close();
})();
