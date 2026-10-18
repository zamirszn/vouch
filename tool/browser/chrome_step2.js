const { chromium } = require('playwright-core');
(async () => {
  const ctx = await chromium.launchPersistentContext('/tmp/chrome-fb', {
    executablePath: '/usr/bin/google-chrome', headless: false,
    viewport: { width: 1440, height: 1000 },
    ignoreDefaultArgs: ['--use-mock-keychain', '--password-store=basic'],
    args: ['--profile-directory=Default', '--password-store=gnome-libsecret', '--no-first-run'],
  });
  const page = ctx.pages()[0] || (await ctx.newPage());
  await page.goto('https://console.firebase.google.com/u/0/project/vouch-tracker/authentication/providers', { waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(7000);
  await page.getByText('Google', { exact: true }).first().click({ timeout: 20000 });
  await page.waitForTimeout(4000);
  console.log('URL', page.url());
  const text = await page.locator('body').innerText().catch(() => '');
  console.log(text.slice(0, 4500));
  await page.screenshot({ path: '/tmp/fb-step2.png', fullPage: false });
  await ctx.close();
})();
