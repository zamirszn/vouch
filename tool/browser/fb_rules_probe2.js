const { chromium } = require('playwright-core');
(async () => {
  const ctx = await chromium.launchPersistentContext('/tmp/chrome-fb', {
    executablePath: '/usr/bin/google-chrome', headless: true,
    viewport: { width: 1440, height: 1000 },
    ignoreDefaultArgs: ['--use-mock-keychain', '--password-store=basic'],
    args: ['--profile-directory=Default', '--password-store=gnome-libsecret', '--no-first-run'],
  });
  const page = ctx.pages()[0] || (await ctx.newPage());
  await page.goto('https://console.firebase.google.com/u/0/project/vouch-tracker/overview', { waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(8000);
  console.log('URL0:', page.url());
  const fs = page.getByRole('link', { name: /firestore/i }).first();
  console.log('firestore link count', await page.getByRole('link', { name: /firestore/i }).count());
  if (await fs.count()) {
    await fs.click();
    await page.waitForTimeout(10000);
  }
  console.log('URL1:', page.url());
  console.log((await page.locator('body').innerText().catch(() => '')).slice(0, 1500));
  const tabs = await page.getByRole('tab').allInnerTexts().catch(() => []);
  console.log('TABS:', JSON.stringify(tabs));
  await page.screenshot({ path: '/tmp/fb-rules2.png', fullPage: false });
  await ctx.close();
})();
