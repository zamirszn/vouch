const { chromium } = require('playwright-core');
(async () => {
  const ctx = await chromium.launchPersistentContext('/tmp/chrome-fb', {
    executablePath: '/usr/bin/google-chrome', headless: true,
    viewport: { width: 1440, height: 1000 },
    ignoreDefaultArgs: ['--use-mock-keychain', '--password-store=basic'],
    args: ['--profile-directory=Default', '--password-store=gnome-libsecret', '--no-first-run'],
  });
  const page = ctx.pages()[0] || (await ctx.newPage());
  await page.goto('https://console.firebase.google.com/u/0/project/vouch-tracker/authentication/providers', { waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(7000);
  await page.getByText('Google', { exact: true }).first().click({ timeout: 20000 });
  await page.waitForTimeout(2500);
  const sw = page.getByRole('switch', { name: /enable google sign-in/i }).first();
  if ((await sw.getAttribute('aria-checked')) !== 'true') {
    await sw.click();
    await page.waitForTimeout(2500);
  }
  // Set public-facing project name.
  const nameInput = page.locator('#fbc_k');
  if (await nameInput.count()) {
    await nameInput.fill('Vouch');
    await nameInput.dispatchEvent('input');
    await page.waitForTimeout(500);
  }
  // Choose a support email.
  const combos = page.getByRole('combobox');
  console.log('combobox count', await combos.count());
  for (let i = 0; i < await combos.count(); i++) {
    const c = combos.nth(i);
    console.log('combo', i, await c.getAttribute('aria-label'), (await c.innerText().catch(()=>'')).slice(0,60));
  }
  const support = page.getByRole('combobox', { name: /support email/i }).first();
  if (await support.count()) {
    await support.click();
    await page.waitForTimeout(1500);
    const options = await page.getByRole('option').allInnerTexts().catch(() => []);
    console.log('options', options);
    const preferred = page.getByRole('option', { name: /smithjacobsmith0077@gmail.com/i }).first();
    if (await preferred.count()) {
      await preferred.click();
    } else if (options.length) {
      await page.getByRole('option').first().click();
    }
    await page.waitForTimeout(1200);
  }
  const save = page.getByRole('button', { name: /^save$/i }).first();
  console.log('save disabled:', await save.isDisabled());
  if (!(await save.isDisabled())) {
    await save.click();
    await page.waitForTimeout(7000);
    console.log('SAVED');
  }
  const text = await page.locator('body').innerText().catch(() => '');
  console.log(text.slice(0, 1800));
  await page.screenshot({ path: '/tmp/fb-google-after.png', fullPage: false });
  await ctx.close();
})();
