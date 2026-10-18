const { chromium } = require('playwright-core');
(async () => {
  const ctx = await chromium.launchPersistentContext('/tmp/chrome-fb', {
    executablePath: '/usr/bin/google-chrome', headless: true,
    viewport: { width: 1440, height: 1000 },
    ignoreDefaultArgs: ['--use-mock-keychain', '--password-store=basic'],
    args: ['--profile-directory=Default', '--password-store=gnome-libsecret', '--no-first-run'],
  });
  const page = ctx.pages()[0] || (await ctx.newPage());
  await page.goto('https://console.cloud.google.com/apis/credentials/consent?project=vouch-tracker', { waitUntil: 'domcontentloaded', timeout: 120000 });
  await page.waitForTimeout(12000);
  console.log('URL', page.url());
  const text = await page.locator('body').innerText().catch(() => '');
  console.log(text.slice(0, 4500));
  await page.screenshot({ path: '/tmp/gcp-consent.png', fullPage: false });
  await ctx.close();
})();
