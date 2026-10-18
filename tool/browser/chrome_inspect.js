const { chromium } = require('playwright-core');
(async () => {
  const ctx = await chromium.launchPersistentContext('/tmp/chrome-fb', {
    executablePath: '/usr/bin/google-chrome', headless: false,
    viewport: { width: 1440, height: 1000 },
    ignoreDefaultArgs: ['--use-mock-keychain', '--password-store=basic'],
    args: ['--profile-directory=Default', '--password-store=gnome-libsecret', '--no-first-run'],
  });
  const page = ctx.pages()[0] || (await ctx.newPage());
  await page.goto('https://console.firebase.google.com/u/0/project/vouch-tracker/authentication/providers', { waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(7000);
  await page.getByText('Google', { exact: true }).first().click({ timeout: 20000 });
  await page.waitForTimeout(2500);
  const buttons = await page.getByRole('button').evaluateAll(els => els.map(e => ({text:(e.innerText||'').trim().slice(0,60), aria:e.getAttribute('aria-label'), cls:e.className.toString().slice(0,80)})).filter(b => b.text || b.aria));
  console.log('BUTTONS', JSON.stringify(buttons, null, 1));
  const switches = await page.getByRole('switch').evaluateAll(els => els.map(e => ({text:(e.innerText||'').trim(), aria:e.getAttribute('aria-label'), checked:e.getAttribute('aria-checked')})));
  console.log('SWITCHES', JSON.stringify(switches));
  const checks = await page.locator('input[type=checkbox]').evaluateAll(els => els.map(e => ({id:e.id, name:e.name, checked:e.checked, aria:e.getAttribute('aria-label')})));
  console.log('CHECKS', JSON.stringify(checks));
  await ctx.close();
})();
