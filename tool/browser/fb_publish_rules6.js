const { chromium } = require('playwright-core');
const fs = require('fs');
const rules = fs.readFileSync('/home/z/vouch/firestore.rules', 'utf8');
(async () => {
  const started = Date.now();
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
  await page.waitForTimeout(400);
  await page.keyboard.press('Control+A');
  await page.keyboard.press('Backspace');
  console.log('cleared at', Date.now() - started, 'ms');
  await page.keyboard.type(rules, { delay: 0 });
  console.log('typed at', Date.now() - started, 'ms');

  const publish = page.getByRole('button', { name: /^Publish$/ }).first();
  let seen = false;
  for (let i = 0; i < 12; i++) {
    if (await publish.isVisible().catch(() => false)) { seen = true; break; }
    await page.waitForTimeout(250);
  }
  console.log('publish seen:', seen);
  if (seen) {
    await page.screenshot({ path: '/tmp/fb-rules-before-publish.png' });
    await publish.click();
    await page.waitForTimeout(3000);
    console.log('dialogs:', JSON.stringify(await page.getByRole('dialog').allInnerTexts().catch(() => [])));
    const dialogPublish = page.getByRole('dialog').getByRole('button', { name: /publish/i }).last();
    if (await dialogPublish.count()) {
      await dialogPublish.click();
      await page.waitForTimeout(8000);
    }
    console.log('body tail:', (await page.locator('body').innerText().catch(() => '')).slice(-600).replace(/\n+/g, ' | '));
    await page.screenshot({ path: '/tmp/fb-rules-published6.png' });
  } else {
    console.log('buttons:', JSON.stringify(await page.getByRole('button').allInnerTexts()));
  }
  await ctx.close();
})();
