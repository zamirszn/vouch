const { chromium } = require('playwright-core');
const fs = require('fs');
const rules = fs.readFileSync('/home/z/vouch/firestore.rules', 'utf8');
const marker = '\n// Published from the Vouch repository.';
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
  await page.waitForTimeout(400);
  await page.keyboard.press('Control+A');
  await page.keyboard.press('Backspace');
  await page.keyboard.insertText(rules);
  await page.waitForTimeout(700);
  // A real keystroke reveals the publish toolbar; the marker is a harmless
  // trailing comment that keeps the document syntactically valid.
  await page.keyboard.type(marker);
  await page.waitForTimeout(900);

  const publish = page.getByRole('button', { name: /^Publish$/ }).first();
  console.log('publish visible:', await publish.isVisible().catch(() => false));
  if (!(await publish.isVisible().catch(() => false))) {
    console.log('buttons:', JSON.stringify(await page.getByRole('button').allInnerTexts()));
    await ctx.close();
    return;
  }

  await page.keyboard.press('Control+A');
  await page.keyboard.press('Control+C');
  await page.waitForTimeout(700);
  const content = await page.evaluate(async () => navigator.clipboard.readText().catch(e => 'ERR:' + e));
  const expected = rules + marker;
  console.log('content length:', content.length, 'expected:', expected.length);
  console.log('matches expected:', content === expected);
  console.log('matches expected+nl:', content === expected + '\n');
  console.log('head:', JSON.stringify(content.slice(0, 60)));
  console.log('tail:', JSON.stringify(content.slice(-90)));
  if (content !== expected && content !== expected + '\n') {
    console.log('REFUSING TO PUBLISH — content mismatch');
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
  console.log('body tail:', body.slice(-500).replace(/\n+/g, ' | '));
  await page.screenshot({ path: '/tmp/fb-rules-published-final.png' });
  if (content === expected + '\n') {
    fs.writeFileSync('/home/z/vouch/firestore.rules', content);
    console.log('local rules file updated to match the published document');
  }
  await ctx.close();
})();
