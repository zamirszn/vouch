const { chromium } = require('playwright-core');
(async () => {
  const ctx = await chromium.launchPersistentContext('/tmp/chrome-fb', {
    executablePath: '/usr/bin/google-chrome',
    headless: false,
    viewport: { width: 1440, height: 1000 },
    ignoreDefaultArgs: ['--use-mock-keychain', '--password-store=basic'],
    args: ['--profile-directory=Default', '--password-store=gnome-libsecret', '--no-first-run', '--no-default-browser-check'],
  });
  const page = ctx.pages()[0] || (await ctx.newPage());
  await page.goto('https://console.firebase.google.com/project/vouch-tracker/authentication/providers', { waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(9000);
  console.log('URL', page.url());
  console.log('TITLE', await page.title());
  await page.screenshot({ path: '/tmp/fb-console-chrome.png', fullPage: false });
  const text = await page.locator('body').innerText().catch(() => '');
  console.log(text.slice(0, 3000));
  await ctx.close();
})();
