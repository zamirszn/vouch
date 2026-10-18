const { chromium } = require('playwright-core');
(async () => {
  const ctx = await chromium.launchPersistentContext('/tmp/chrome-fb', {
    executablePath: '/usr/bin/google-chrome', headless: true,
    viewport: { width: 1440, height: 1000 },
    ignoreDefaultArgs: ['--use-mock-keychain', '--password-store=basic'],
    args: ['--profile-directory=Default', '--password-store=gnome-libsecret', '--no-first-run'],
  });
  const page = ctx.pages()[0] || (await ctx.newPage());
  await page.goto('https://console.firebase.google.com/u/0/project/vouch-tracker/firestore/rules', { waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(9000);
  console.log('URL:', page.url());
  const text = await page.locator('body').innerText().catch(() => '');
  console.log(text.slice(0, 2500));
  console.log('EDITORS:', await page.locator('.monaco-editor, .cm-editor, [contenteditable="true"], textarea').count());
  const buttons = await page.getByRole('button').allInnerTexts().catch(() => []);
  console.log('BUTTONS:', JSON.stringify(buttons));
  await page.screenshot({ path: '/tmp/fb-rules.png', fullPage: false });
  await ctx.close();
})();
