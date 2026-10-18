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
  const publish = page.getByRole('button', { name: /^Publish$/ }).first();
  console.log('before focus:', await publish.isVisible().catch(() => false));
  const editor = page.locator('.cm-editor').first();
  await editor.click();
  for (let i = 0; i < 8; i++) {
    await page.waitForTimeout(400);
    console.log('t+' + (i * 400), 'visible:', await publish.isVisible().catch(() => false), 'active:', await page.evaluate(() => document.activeElement && document.activeElement.className && document.activeElement.className.toString().slice(0, 50)));
  }
  await page.keyboard.type('x');
  for (let i = 0; i < 6; i++) {
    await page.waitForTimeout(400);
    console.log('xtyped+' + (i * 400), 'visible:', await publish.isVisible().catch(() => false));
  }
  console.log('buttons:', JSON.stringify(await page.getByRole('button').allInnerTexts()));
  await page.screenshot({ path: '/tmp/fb-rules-min.png' });
  await ctx.close();
})();
