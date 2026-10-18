const { chromium } = require('playwright-core');
(async () => {
  const ctx = await chromium.launchPersistentContext('/tmp/chrome-fb', {
    executablePath: '/usr/bin/google-chrome', headless: true,
    viewport: { width: 1440, height: 1000 },
    ignoreDefaultArgs: ['--use-mock-keychain', '--password-store=basic'],
    args: ['--profile-directory=Default', '--password-store=gnome-libsecret', '--no-first-run'],
  });
  const page = ctx.pages()[0] || (await ctx.newPage());
  await page.goto('https://console.firebase.google.com/u/0/project/vouch-tracker/firestore/databases', { waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(8000);
  const cands = await page.locator('button, [role="button"], a[role="button"]').evaluateAll(els =>
    els.map(e => ({ text: (e.innerText || '').trim().slice(0, 60), aria: e.getAttribute('aria-label'), id: e.id, cls: (e.className || '').toString().slice(0, 60) }))
       .filter(x => x.text || x.aria)
  );
  console.log(JSON.stringify(cands.filter(c => /add|database|create/i.test((c.text||'') + ' ' + (c.aria||''))), null, 1).slice(0, 3000));
  await ctx.close();
})();
