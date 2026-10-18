const { chromium } = require('playwright-core');

(async () => {
  const ctx = await chromium.launchPersistentContext('/tmp/brave-fb', {
    executablePath: '/usr/bin/brave-browser',
    headless: false,
    viewport: { width: 1280, height: 900 },
    args: [
      '--no-first-run',
      '--no-default-browser-check',
      '--disable-blink-features=AutomationControlled',
    ],
  });
  const page = ctx.pages()[0] || (await ctx.newPage());
  await page.goto(
    'https://console.firebase.google.com/project/vouch-tracker/authentication/providers',
    { waitUntil: 'domcontentloaded', timeout: 60000 },
  );
  await page.waitForTimeout(8000);
  console.log('URL', page.url());
  console.log('TITLE', await page.title());
  await page.screenshot({ path: '/tmp/fb-console.png', fullPage: false });
  const text = await page.locator('body').innerText().catch(() => '');
  console.log(text.slice(0, 4000));
  await ctx.close();
})();
