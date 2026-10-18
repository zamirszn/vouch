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
  console.log('iframes:', page.frames().map(f => f.url()));
  const info = await page.locator('.cm-editor').first().evaluate(el => {
    const chain = [];
    let node = el;
    for (let i = 0; i < 8 && node; i++) {
      chain.push({
        tag: node.tagName,
        cls: (node.className || '').toString().slice(0, 100),
        id: node.id || null,
        text: (node.innerText || '').slice(0, 80).replace(/\n/g, ' | '),
        buttons: Array.from(node.querySelectorAll('button')).map(b => (b.innerText || b.getAttribute('aria-label') || '').trim()).filter(Boolean).slice(0, 10),
      });
      node = node.parentElement;
    }
    return chain;
  });
  console.log(JSON.stringify(info, null, 1));
  await ctx.close();
})();
