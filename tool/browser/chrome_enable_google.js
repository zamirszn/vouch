const { chromium } = require('playwright-core');
(async () => {
  const ctx = await chromium.launchPersistentContext('/tmp/chrome-fb', {
    executablePath: '/usr/bin/google-chrome',
    headless: true,
    viewport: { width: 1440, height: 1000 },
    ignoreDefaultArgs: ['--use-mock-keychain', '--password-store=basic'],
    args: ['--profile-directory=Default', '--password-store=gnome-libsecret', '--no-first-run'],
  });
  const page = ctx.pages()[0] || (await ctx.newPage());
  await page.goto('https://console.firebase.google.com/u/0/project/vouch-tracker/authentication/providers', { waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(7000);
  const bodyBefore = await page.locator('body').innerText();
  if (bodyBefore.includes('Google') && /Enabled/i.test(bodyBefore)) {
    console.log('Google provider may already be enabled');
  }
  await page.getByText('Google', { exact: true }).first().click({ timeout: 20000 });
  await page.waitForTimeout(3000);
  const sw = page.getByRole('switch', { name: /enable google sign-in/i }).first();
  const checked = (await sw.getAttribute('aria-checked')) === 'true';
  console.log('toggle before:', checked);
  if (!checked) {
    await sw.click();
    await page.waitForTimeout(3500);
  }
  console.log('toggle after:', await sw.getAttribute('aria-checked'));
  const save = page.getByRole('button', { name: /^save$/i }).first();
  console.log('save disabled:', await save.isDisabled());
  const dialogText = await page.locator('mat-dialog-container, .cdk-overlay-pane').last().innerText().catch(() => '(none)');
  console.log('DIALOG:\n', dialogText.slice(0, 3000));
  await page.screenshot({ path: '/tmp/fb-google-panel.png', fullPage: false });
  // Print any input labels/values that exist (e.g. support email / client id).
  const inputs = await page.locator('input').evaluateAll(els => els.map(e => ({type:e.type, id:e.id, name:e.name, value:e.value, placeholder:e.placeholder, aria:e.getAttribute('aria-label'), disabled:e.disabled})).filter(x => x.type !== 'hidden'));
  console.log('INPUTS', JSON.stringify(inputs, null, 1));
  await ctx.close();
})();
