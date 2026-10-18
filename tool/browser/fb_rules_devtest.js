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
  await page.getByRole('button', { name: /Develop and Test/i }).first().click().catch(e => console.log('click err', e.message));
  await page.waitForTimeout(2500);
  console.log('after click text tail:', (await page.locator('body').innerText()).slice(-700));
  console.log('publish count:', await page.getByText(/publish/i).count());
  console.log('buttons:', JSON.stringify(await page.getByRole('button').allInnerTexts()));
  await page.screenshot({ path: '/tmp/fb-rules-devtest.png' });
  await ctx.close();
})();
