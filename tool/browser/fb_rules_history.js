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
  const entries = page.getByRole('button', { name: /Today •/ });
  console.log('history entries:', await entries.count());
  for (let i = 0; i < await entries.count(); i++) {
    console.log('entry', i, JSON.stringify(await entries.nth(i).innerText()));
  }
  await entries.first().click();
  await page.waitForTimeout(3000);
  console.log('after click:', (await page.locator('body').innerText()).slice(0, 1500).replace(/\n+/g, ' | '));
  console.log('buttons:', JSON.stringify(await page.getByRole('button').allInnerTexts()));
  await page.screenshot({ path: '/tmp/fb-rules-history.png' });
  await ctx.close();
})();
