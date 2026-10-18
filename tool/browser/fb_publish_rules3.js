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
  await page.waitForTimeout(9000);

  const editor = page.locator('.cm-editor').first();
  await editor.click();
  await page.waitForTimeout(500);
  await page.keyboard.press('Control+A');
  await page.keyboard.press('Backspace');
  await page.keyboard.insertText(rules);
  await page.waitForTimeout(800);
  console.log('content length:', (await page.locator('.cm-content').first().innerText()).length);
  // A real key event marks the editor dirty and reveals the floating toolbar.
  await page.keyboard.press('End');
  await page.keyboard.type(' ');
  await page.keyboard.press('Backspace');
  await page.waitForTimeout(2000);
  const publish = page.getByRole('button', { name: /^Publish$/ }).first();
  console.log('publish visible:', await publish.isVisible().catch(() => false));
  if (await publish.isVisible().catch(() => false)) {
    console.log('toolbar:', (await page.locator('body').innerText()).slice(0, 0));
    await page.screenshot({ path: '/tmp/fb-rules-before-publish.png' });
    await publish.click();
    await page.waitForTimeout(4000);
    const dialogs = await page.getByRole('dialog').allInnerTexts().catch(() => []);
    console.log('DIALOGS:', JSON.stringify(dialogs));
    if (dialogs.length) {
      const confirm = page.getByRole('dialog').getByRole('button', { name: /publish|confirm|ok/i }).last();
      if (await confirm.count()) {
        await confirm.click();
        await page.waitForTimeout(8000);
      }
    }
    console.log('unpublished visible:', /unpublished changes/i.test(await page.locator('body').innerText().catch(() => '')));
    console.log('tail:', (await page.locator('body').innerText().catch(() => '')).slice(-700).replace(/\n+/g, ' | '));
    await page.screenshot({ path: '/tmp/fb-rules-published3.png' });
  } else {
    console.log('buttons:', JSON.stringify(await page.getByRole('button').allInnerTexts()));
  }
  await ctx.close();
})();
