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
  const text = await page.locator('body').innerText().catch(() => '');
  const idx = text.toLowerCase().indexOf('published');
  console.log('has published:', idx >= 0, idx >= 0 ? text.slice(Math.max(0, idx - 200), idx + 300) : '');
  const first = text.slice(0, 1200);
  console.log('TOP:', first);
  const allButtons = await page.getByRole('button').allInnerTexts().catch(() => []);
  console.log('BUTTONS:', JSON.stringify(allButtons));
  const history = await page.locator('[role="button"], button').allInnerTexts().catch(() => []);
  console.log('HISTORY-ish:', JSON.stringify(history.filter(t => /today|yesterday|am|pm/i.test(t))));
  await page.screenshot({ path: '/tmp/fb-rules-verify.png', fullPage: false });
  await ctx.close();
})();
