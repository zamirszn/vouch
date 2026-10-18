const { chromium } = require('playwright-core');
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
  console.log('getByText publish count:', await page.getByText(/publish/i).count());
  console.log('getByText deploy count:', await page.getByText(/deploy/i).count());
  // Scroll inside the rules editor to its end.
  await page.locator('.cm-scroller').first().evaluate(el => { el.scrollTop = el.scrollHeight; });
  await page.waitForTimeout(1000);
  await page.screenshot({ path: '/tmp/fb-rules-bottom.png', fullPage: false });
  // Also try scrolling the page.
  await page.mouse.move(900, 700);
  await page.mouse.wheel(0, 1200);
  await page.waitForTimeout(1200);
  await page.screenshot({ path: '/tmp/fb-rules-bottom2.png', fullPage: false });
  const visibleButtons = [];
  for (const b of await page.getByRole('button').all()) {
    if (await b.isVisible().catch(() => false)) {
      const t = (await b.innerText().catch(() => '')).trim();
      const box = await b.boundingBox().catch(() => null);
      if (t) visibleButtons.push({ t, box });
    }
  }
  console.log(JSON.stringify(visibleButtons, null, 1));
  await ctx.close();
})();
