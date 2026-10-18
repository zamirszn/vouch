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
  await page.keyboard.press('Control+End');
  await page.keyboard.press('Enter');
  await page.waitForTimeout(900);
  const publish = page.getByRole('button', { name: /^Publish$/ }).first();
  console.log('publish visible:', await publish.isVisible().catch(() => false));
  if (!(await publish.isVisible().catch(() => false))) {
    console.log('buttons:', JSON.stringify(await page.getByRole('button').allInnerTexts()));
    await ctx.close();
    return;
  }
  await page.screenshot({ path: '/tmp/fb-rules-before-publish.png' });
  await publish.click();
  await page.waitForTimeout(3500);
  const dialogs = await page.getByRole('dialog').allInnerTexts().catch(() => []);
  console.log('dialogs:', JSON.stringify(dialogs));
  const dialogPublish = page.getByRole('dialog').getByRole('button', { name: /publish/i }).last();
  if (await dialogPublish.count()) {
    await dialogPublish.click();
    await page.waitForTimeout(9000);
  }
  const body = await page.locator('body').innerText().catch(() => '');
  console.log('unpublished visible:', /unpublished changes/i.test(body));
  console.log('body tail:', body.slice(-600).replace(/\n+/g, ' | '));
  await page.screenshot({ path: '/tmp/fb-rules-published8.png' });

  // Copy the editor's content back so the checked-in rules match what is live.
  await editor.click();
  await page.keyboard.press('Control+A');
  await page.keyboard.press('Control+C');
  await page.waitForTimeout(800);
  const live = await page.evaluate(async () => navigator.clipboard.readText().catch(e => 'ERR:' + e));
  console.log('live length:', live.length, 'file length:', rules.length);
  console.log('live equals file+nl:', live === rules + '\n');
  console.log('live tail:', JSON.stringify(live.slice(-80)));
  fs.writeFileSync('/tmp/vouch-live-rules.txt', live);
  await ctx.close();
})();
