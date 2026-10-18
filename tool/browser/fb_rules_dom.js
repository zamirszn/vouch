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
  const html = await page.content();
  const lower = html.toLowerCase();
  for (const term of ['publish', 'deploy', 'save', 'discard', 'unsaved', 'draft']) {
    const i = lower.indexOf(term);
    console.log(term, i >= 0 ? 'FOUND' : 'absent');
  }
  const labeled = await page.locator('button, [role="button"], a').evaluateAll(els => els.map(el => ({
    tag: el.tagName,
    text: (el.innerText || '').trim().slice(0, 40),
    aria: el.getAttribute('aria-label'),
    title: el.getAttribute('title'),
    testid: el.getAttribute('data-test-id'),
    cls: (el.className || '').toString().slice(0, 60),
  })).filter(x => x.aria || x.title || /publish|deploy|save|draft/i.test(x.text)).slice(0, 60));
  console.log(JSON.stringify(labeled, null, 1));
  await ctx.close();
})();
