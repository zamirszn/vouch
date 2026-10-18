const { chromium } = require('playwright-core');
const fs = require('fs');
const rules = fs.readFileSync('/home/z/vouch/firestore.rules', 'utf8');

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

  // Dismiss any toast that might cover the publish control.
  await page.keyboard.press('Escape').catch(() => {});
  await page.mouse.click(700, 500);
  await page.waitForTimeout(800);

  const editor = page.locator('.cm-editor').first();
  await editor.click();
  await page.waitForTimeout(500);
  await page.keyboard.press('Control+A');
  await page.keyboard.press('Backspace');
  await page.keyboard.insertText(rules);
  await page.waitForTimeout(2500);
  await page.mouse.click(700, 140);
  await page.waitForTimeout(1000);

  const publish = page.getByRole('button', { name: /publish/i }).first();
  console.log('publish count', await page.getByRole('button', { name: /publish/i }).count());
  if (await publish.count()) {
    console.log('publish disabled:', await publish.isDisabled().catch(() => 'unknown'));
    await publish.click();
    await page.waitForTimeout(6000);
    const dialogs = await page.getByRole('dialog').allInnerTexts().catch(() => []);
    console.log('DIALOGS:', JSON.stringify(dialogs));
    const confirm = page.getByRole('button', { name: /^(publish|confirm|done)$/i }).last();
    if (await confirm.count() && !(await confirm.isDisabled().catch(() => true))) {
      await confirm.click();
      await page.waitForTimeout(8000);
    }
  }
  console.log('--- after ---');
  console.log((await page.locator('body').innerText().catch(() => '')).slice(-1600));
  await page.screenshot({ path: '/tmp/fb-rules-published.png', fullPage: false });
  await ctx.close();
})();
