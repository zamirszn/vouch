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
  const editor = page.locator('.cm-editor').first();
  await editor.click();
  await page.waitForTimeout(600);
  await page.keyboard.type('// touch');
  await page.waitForTimeout(1500);
  console.log('publish text count after typing:', await page.getByText(/publish/i).count());
  const vis = [];
  for (const b of await page.getByRole('button').all()) {
    if (await b.isVisible().catch(() => false)) {
      const t = (await b.innerText().catch(() => '')).trim();
      const aria = await b.getAttribute('aria-label');
      if (t || aria) vis.push(t || `aria:${aria}`);
    }
  }
  console.log('visible buttons after typing:', JSON.stringify(vis));
  const html = await page.content();
  console.log('html has publish word:', /publish/i.test(html));
  await page.screenshot({ path: '/tmp/fb-rules-typed.png' });
  await ctx.close();
})();
