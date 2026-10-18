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
  await page.waitForTimeout(8000);
  console.log('URL:', page.url());
  console.log((await page.locator('body').innerText().catch(() => '')).slice(-2200));
  const counts = {
    monaco: await page.locator('.monaco-editor').count(),
    cm: await page.locator('.cm-editor').count(),
    editable: await page.locator('[contenteditable="true"]').count(),
    textarea: await page.locator('textarea').count(),
  };
  console.log('EDITORS:', JSON.stringify(counts));
  const buttons = await page.getByRole('button').allInnerTexts().catch(() => []);
  console.log('BUTTONS:', JSON.stringify(buttons));
  await page.screenshot({ path: '/tmp/fb-rules3.png', fullPage: false });
  await ctx.close();
})();
