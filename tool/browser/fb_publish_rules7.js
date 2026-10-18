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
  await ctx.grantPermissions(['clipboard-read', 'clipboard-write'], { origin: 'https://console.firebase.google.com' });
  const page = ctx.pages()[0] || (await ctx.newPage());
  await page.goto('https://console.firebase.google.com/u/0/project/vouch-tracker/firestore', { waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(10000);
  await page.getByRole('tab', { name: /^Rules$/ }).click();
  await page.waitForTimeout(9000);

  const editor = page.locator('.cm-editor').first();
  await editor.click();
  await page.waitForTimeout(500);
  await page.keyboard.press('Control+A');
  await page.keyboard.press('Control+C');
  await page.waitForTimeout(800);
  const copied = await page.evaluate(async () => navigator.clipboard.readText().catch(e => 'ERR:' + e));
  console.log('copied length:', copied.length, 'file length:', rules.length);
  console.log('matches file:', copied === rules);
  console.log('copied head:', JSON.stringify(copied.slice(0, 80)));
  console.log('copied tail:', JSON.stringify(copied.slice(-120)));

  // Nudge the editor with a real key so the publish toolbar appears, then undo
  // the keystroke so the document matches the file exactly.
  await page.keyboard.press('Control+End');
  await page.keyboard.type('x');
  await page.keyboard.press('Backspace');
  await page.waitForTimeout(600);
  const publish = page.getByRole('button', { name: /^Publish$/ }).first();
  console.log('publish visible:', await publish.isVisible().catch(() => false));
  if (await publish.isVisible().catch(() => false)) {
    await page.screenshot({ path: '/tmp/fb-rules-before-publish.png' });
    await publish.click();
    await page.waitForTimeout(3500);
    console.log('dialogs:', JSON.stringify(await page.getByRole('dialog').allInnerTexts().catch(() => [])));
    const dialogPublish = page.getByRole('dialog').getByRole('button', { name: /publish/i }).last();
    if (await dialogPublish.count()) {
      await dialogPublish.click();
      await page.waitForTimeout(9000);
    }
    const body = await page.locator('body').innerText().catch(() => '');
    console.log('unpublished visible:', /unpublished changes/i.test(body));
    console.log('body tail:', body.slice(-700).replace(/\n+/g, ' | '));
    await page.screenshot({ path: '/tmp/fb-rules-published7.png' });
  } else {
    console.log('buttons:', JSON.stringify(await page.getByRole('button').allInnerTexts()));
  }
  await ctx.close();
})();
