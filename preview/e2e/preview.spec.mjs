import { mkdirSync } from 'node:fs';
import { test, expect } from '@playwright/test';

const baseUrl = process.env.PREVIEW_URL || 'http://127.0.0.1:4173/';
const screenshotDir = 'artifacts/ui';
const storageKey = 'cashtally-preview-v5';

test.beforeAll(() => mkdirSync(screenshotDir, { recursive: true }));

test('desktop phone preview starts with country flags, Eurozone drilldown and full English app', async ({ browser }) => {
  test.setTimeout(60_000);
  const page = await browser.newPage({ viewport: { width: 1440, height: 1100 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto(baseUrl, { waitUntil: 'domcontentloaded' });
  await expect(page).toHaveTitle(/Aardvarkland/);
  const frame = page.frameLocator('iframe[title="Aardvarkland"]');
  await expect(frame.locator('.country-logo-image')).toBeVisible({ timeout: 30_000 });
  await expect(frame.locator('.country-grid .country-card')).toHaveCount(32);
  await expect(frame.locator('.country-grid .flag-icon')).toHaveCount(32);
  await expect(frame.locator('.country-grid .country-name')).toHaveText([
    'भारत', 'Eurozone', 'United States', 'Indonesia', 'پاکستان', 'Nigeria',
    'Brasil', 'Россия', 'México', '日本', 'مصر', 'Türkiye', 'ประเทศไทย',
    'United Kingdom', 'South Africa', '대한민국', 'الجزائر', 'Argentina',
    'Canada', 'Україна', 'Polska', 'Malaysia', 'السعودية', 'Australia',
    'الإمارات', 'Česko', 'Sverige', 'ישראל', 'Magyarország', 'Schweiz',
    'Danmark', 'Norge',
  ]);
  await page.screenshot({ path: `${screenshotDir}/01-cashtally-country-picker.png`, fullPage: true });

  await frame.locator('[data-euro="true"]').click();
  await expect(frame.getByRole('heading', { name: /Eurozone/ })).toBeVisible();
  await expect(frame.locator('.country-grid .country-card')).toHaveCount(21);
  await expect(frame.locator('.country-grid .country-name')).toHaveText([
    'Deutschland', 'France', 'Italia', 'España', 'Nederland', 'België',
    'Österreich', 'България', 'Portugal', 'Ελλάδα', 'Suomi', 'Ireland',
    'Slovensko', 'Hrvatska', 'Lietuva', 'Slovenija', 'Latvija', 'Eesti',
    'Κύπρος', 'Lëtzebuerg', 'Malta',
  ]);
  await page.screenshot({ path: `${screenshotDir}/02-cashtally-eurozone-picker.png`, fullPage: true });
  await frame.locator('.country-back').click();
  await frame.locator('[data-country="US"]').click();

  await expect(page.getByText('Aardvarkland · mobile preview')).toBeVisible();
  await expect(page.getByRole('link', { name: 'Open standalone' })).toHaveAttribute('href', './app/?country-picker=1&entry=mobile-preview-v1');
  await expect(frame.locator('body[data-ready="true"]')).toBeVisible({ timeout: 15000 });
  await expect(frame.locator('.appbar-title')).toContainText('Aardvarkland Cash Tally');
  await expect(frame.locator('.filled.big')).toContainText('New count');
  const desktopIconWidths = await frame.locator('.mi').evaluateAll((icons) => icons.map((icon) => icon.getBoundingClientRect().width));
  expect(Math.max(...desktopIconWidths)).toBeLessThanOrEqual(32);
  await page.screenshot({ path: `${screenshotDir}/03-cashtally-full-demo.png`, fullPage: true });
  expect(errors).toEqual([]);
});

test('Czech overview keeps its controls and layout usable', async ({ browser }) => {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('pageerror', (error) => errors.push(error.message));
  await page.goto(baseUrl, { waitUntil: 'domcontentloaded' });
  const frame = page.frameLocator('iframe[title="Aardvarkland"]');
  await frame.locator('[data-country="CZ"]').click();
  await expect(frame.locator('.appbar-title')).toContainText('Aardvarkland Výčetka');
  await expect(frame.locator('.filled.big')).toContainText('Nová výčetka');
  await expect(frame.locator('.info-banner')).toHaveCount(0);
  const iconWidths = await frame.locator('.mi').evaluateAll((icons) => icons.map((icon) => icon.getBoundingClientRect().width));
  expect(Math.max(...iconWidths)).toBeLessThanOrEqual(32);
  expect(errors).toEqual([]);
});

test('mobile phone preview starts with country selection and core counting flow works', async ({ browser }) => {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto(baseUrl, { waitUntil: 'domcontentloaded' });
  const frame = page.frameLocator('iframe[title="Aardvarkland"]');
  await expect(frame.locator('.country-logo-image')).toBeVisible();
  await expect(frame.locator('.country-grid .country-card')).toHaveCount(32);
  await expect(frame.locator('.country-grid .flag-icon')).toHaveCount(32);
  await page.screenshot({ path: `${screenshotDir}/04-cashtally-mobile-country-picker.png` });
  await frame.locator('[data-country="US"]').click();
  await expect(frame.locator('body[data-ready="true"]')).toBeVisible({ timeout: 15000 });
  await page.screenshot({ path: `${screenshotDir}/05-dashboard-mobile.png` });

  await frame.getByRole('button', { name: /New count/ }).click();
  await expect(frame.locator('.sheet')).toContainText('Choose counting mode');
  await frame.getByRole('button', { name: /Professional close/ }).click();
  await expect(frame.locator('.section-head .title-large').filter({ hasText: 'Banknotes' })).toBeVisible();
  const oneHundred = frame.locator('.denom').filter({ hasText: '$100' });
  await oneHundred.locator('.step-btn').last().click();
  await expect(frame.locator('.count-bottom')).toContainText(/100/);
  await page.screenshot({ path: `${screenshotDir}/06-professional-count.png` });
  await frame.getByRole('button', { name: /Save/ }).click();
  await expect(frame.getByText('Latest count')).toBeVisible();
  await frame.locator('.nav button').filter({ hasText: 'History' }).click();
  await expect(frame.locator('.history-card')).toHaveCount(1);
  await frame.locator('.history-card').click();
  await frame.getByRole('button', { name: /Report preview/ }).click();
  await expect(frame.getByText(/SHA-256 proof fingerprint/)).toBeVisible();
  await frame.getByRole('button', { name: 'Back', exact: true }).click();
  await frame.locator('.nav button').filter({ hasText: 'Settings' }).click();
  const themeSection = frame.locator('.settings-section').filter({ hasText: 'Colour mode' });
  await themeSection.locator('select').selectOption('dark');
  await expect(frame.locator('html')).toHaveAttribute('data-theme', 'dark');
  await page.screenshot({ path: `${screenshotDir}/07-settings-dark.png` });
  expect(errors).toEqual([]);
});

test('English settings subpages, favourites and backup controls remain interactive', async ({ browser }) => {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.goto(`${baseUrl}app/`, { waitUntil: 'domcontentloaded' });
  await page.evaluate((key) => { localStorage.clear(); localStorage.setItem(key, JSON.stringify({ lang: 'en', country: 'CZ', currency: 'CZK' })); }, storageKey);
  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.locator('.nav button').filter({ hasText: 'Settings' }).click();
  await expect(page.locator('.currency-settings-icon').first()).toBeVisible();
  await expect(page.locator('.currency-settings-icon').first()).toHaveText(/\S+/);
  await expect(page.locator('.currency-settings-icon')).toHaveCount(32);
  const languageSection = page.locator('.settings-section').filter({ hasText: 'Default language' });
  await expect(languageSection.locator('option')).toHaveCount(36);
  const businessSection = page.locator('.settings-section').filter({ hasText: 'Business profile' });
  await businessSection.locator('.card').click();
  await expect(page.locator('.appbar-title')).toContainText('Business profile');
  const fields = page.locator('.field input');
  await expect(fields).toHaveCount(8);
  await fields.nth(0).fill('Demo Retail Ltd.');
  await fields.nth(3).fill('Prague 10');
  await fields.nth(4).fill('Till 1');
  await page.getByRole('button', { name: /Save/ }).click();
  await expect(page.locator('.settings-section').filter({ hasText: 'Business profile' }).locator('.list-title')).toHaveText('Demo Retail Ltd.');
  const countingSection = page.locator('.settings-section').filter({ hasText: 'Counting setup' });
  await countingSection.locator('.list-tile').filter({ hasText: 'Backup and restore' }).click();
  await expect(page.locator('.appbar-title')).toContainText('Backup and restore');
  await expect(page.getByRole('button', { name: /Export backup/ })).toBeVisible();
  await expect(page.getByText('Reset demo data')).toBeVisible();
});

test('professional preview exposes POS, signatures and report controls', async ({ browser }) => {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.goto(`${baseUrl}app/`, { waitUntil: 'domcontentloaded' });
  await page.evaluate((key) => { localStorage.clear(); localStorage.setItem(key, JSON.stringify({ lang: 'en', country: 'CZ', currency: 'CZK' })); }, storageKey);
  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.getByRole('button', { name: /New count/ }).click();
  await page.getByRole('button', { name: /Professional close/ }).click();
  await page.locator('.list-tile.clickable').filter({ hasText: 'Closing details' }).click();
  await page.getByRole('button', { name: /Use demo POS/ }).click();
  await expect(page.getByText(/POS \/ EFTPOS reconciliation/)).toBeVisible();
  await page.locator('.card.list-tile.clickable').filter({ hasText: 'Cashier signature' }).click({ force: true });
  await expect(page.locator('#signature-pad')).toBeVisible();
  const signatureBox = await page.locator('#signature-pad').boundingBox();
  await page.mouse.move(signatureBox.x + 40, signatureBox.y + 90);
  await page.mouse.down();
  await page.mouse.move(signatureBox.x + 90, signatureBox.y + 55);
  await page.mouse.move(signatureBox.x + 140, signatureBox.y + 105);
  await page.mouse.up();
  await page.getByRole('button', { name: /Use signature/ }).click();
  await expect(page.locator('.card.list-tile.clickable').filter({ hasText: 'Cashier signature' }).locator('.list-sub')).toHaveText('Signature');
  await page.getByRole('button', { name: /Save/ }).click();
  await page.getByRole('button', { name: 'History', exact: true }).click();
  await page.locator('.history-card').click();
  await expect(page.locator('.hash-text')).toBeVisible();
  await expect(page.getByText(/POS \/ EFTPOS reconciliation/)).toBeVisible();
  await expect(page.locator('.signature-preview')).toHaveCount(1);
  await page.getByRole('button', { name: /Report preview/ }).click();
  await expect(page.getByText(/POS \/ EFTPOS reconciliation/)).toBeVisible();
  await expect(page.locator('.report-paper img[alt="Cashier signature"]')).toBeVisible();
  await expect(page.getByRole('button', { name: /PDF \/ Print/ })).toBeVisible();
  await expect(page.getByRole('button', { name: /Copy final text/ })).toBeVisible();
  await expect(page.getByRole('button', { name: /Share CSV/ })).toBeVisible();
  const fallbackIcons = await page.locator('.mi').evaluateAll((icons) => icons.filter((icon) => icon.textContent?.codePointAt(0) === 0xe24e).length);
  expect(fallbackIcons).toBe(0);
});

test('currency catalog keeps zero-decimal denominations usable', async ({ browser }) => {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.goto(`${baseUrl}app/?country-picker=1`, { waitUntil: 'domcontentloaded' });
  await page.locator('[data-country="CZ"]').click();
  await expect(page.locator('.currency-pair')).toHaveCount(32);
  await page.locator('button.chip').filter({ hasText: 'HUF' }).click();
  await page.getByRole('button', { name: /New count|Nová výčetka/ }).click();
  await page.locator('.mode-card').first().click();
  await expect(page.locator('.denom')).toHaveCount(12);
  await expect(page.locator('.denom').first()).toContainText('500 Ft');
  await expect(page.locator('.denom').first()).toContainText('≈ 1 g');
  await page.locator('.denom').first().locator('.step-btn').last().click();
  await expect(page.locator('.count-bottom')).toContainText(/500/);
});

test('browser preview secondary settings, backup, blind count and exports remain usable', async ({ browser }) => {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.goto(`${baseUrl}app/?country-picker=1`, { waitUntil: 'domcontentloaded' });
  await page.locator('[data-country="US"]').click();
  await page.goto(`${baseUrl}app/`, { waitUntil: 'domcontentloaded' });

  await page.getByRole('button', { name: /New count/ }).click();
  await page.getByRole('button', { name: /Quick count/ }).click();
  await page.locator('.denom').first().click();
  await page.getByRole('button', { name: /Save/ }).click();
  await page.getByRole('button', { name: 'History', exact: true }).click();
  await expect(page.locator('.history-card')).toHaveCount(1);
  await page.getByRole('button', { name: 'Count', exact: true }).click();
  await page.getByRole('button', { name: 'Settings', exact: true }).click();

  let dialogValues = ['Night till', '100', 'Downtown'];
  const templateDialogHandler = async (dialog) => dialog.accept(dialogValues.shift() || '');
  page.on('dialog', templateDialogHandler);
  const setup = page.locator('.settings-section').filter({ hasText: 'Counting setup' });
  await setup.locator('.list-tile').filter({ hasText: 'Till templates' }).click();
  await page.getByRole('button', { name: 'Add', exact: true }).click();
  page.off('dialog', templateDialogHandler);
  await expect(page.locator('.list-title').filter({ hasText: 'Night till' })).toHaveCount(1);
  await page.locator('.appbar .icon-btn').click();

  dialogValues = ['Demo token', '25'];
  const denomDialogHandler = async (dialog) => dialog.accept(dialogValues.shift() || '');
  page.on('dialog', denomDialogHandler);
  await page.locator('.settings-section').filter({ hasText: 'Counting setup' }).locator('.list-tile').filter({ hasText: 'Denominations' }).click();
  await page.getByRole('button', { name: 'Add', exact: true }).click();
  page.off('dialog', denomDialogHandler);
  await expect(page.locator('.list-title').filter({ hasText: 'Demo token' })).toHaveCount(1);
  await page.locator('.appbar .icon-btn').click();

  await page.locator('.settings-section').filter({ hasText: 'Counting setup' }).locator('.list-tile').filter({ hasText: 'Backup and restore' }).click();
  const backupDialog = page.waitForEvent('dialog').then((dialog) => dialog.accept('1234'));
  const backupDownload = page.waitForEvent('download');
  await page.getByRole('button', { name: /Export backup/ }).click();
  const [backup] = await Promise.all([backupDownload, backupDialog]);
  const backupPath = await backup.path();
  expect(backupPath).toBeTruthy();
  page.once('dialog', (dialog) => dialog.accept('1234'));
  await page.locator('input[type="file"]').setInputFiles(backupPath);
  await expect(page.locator('.toast.show')).toContainText(/saved/i);

  await page.getByRole('button', { name: 'Settings', exact: true }).click();
  const privacy = page.locator('.settings-section').filter({ hasText: 'Privacy' });
  page.once('dialog', (dialog) => dialog.accept('1234'));
  await privacy.locator('.list-tile.clickable').filter({ hasText: 'App lock' }).click();
  await expect(privacy.locator('.switch.on')).toBeVisible();
  await page.evaluate(() => sessionStorage.clear());
  await page.reload({ waitUntil: 'domcontentloaded' });
  await expect(page.locator('.lock-screen')).toBeVisible();
  page.once('dialog', (dialog) => dialog.accept('1234'));
  await page.getByRole('button', { name: /^Unlock$/ }).click();
  await expect(page.locator('.nav')).toBeVisible();

  await page.locator('.nav button').first().click();
  await page.getByRole('button', { name: /New count/ }).click();
  await page.getByRole('button', { name: /Professional close/ }).click();
  await page.locator('.list-tile.clickable').filter({ hasText: 'Blind count' }).click();
  await expect(page.getByRole('button', { name: /Finish blind count/ })).toBeVisible();
  await page.locator('.denom').first().click();
  page.once('dialog', (dialog) => dialog.accept());
  await page.getByRole('button', { name: /Finish blind count/ }).click();
  await expect(page.locator('.pill')).toContainText(/Count locked/);
  await page.getByRole('button', { name: /Save/ }).click();
  await page.getByRole('button', { name: 'History', exact: true }).click();
  await expect(page.locator('.history-card')).toHaveCount(2);
  await page.locator('.history-card').first().click();

  const csvDownload = page.waitForEvent('download');
  await page.locator('.subpage-actions button').filter({ hasText: /CSV/ }).first().click();
  const csv = await csvDownload;
  expect(csv.suggestedFilename()).toMatch(/cashtally-closing\.csv/);
  await page.getByRole('button', { name: /Report preview/ }).click();
  await page.evaluate(() => { window.__cashTallyPrintCalled = false; window.print = () => { window.__cashTallyPrintCalled = true; }; });
  await page.getByRole('button', { name: /PDF \/ Print/ }).click();
  await expect.poll(() => page.evaluate(() => window.__cashTallyPrintCalled)).toBe(true);
});

test('all 36 interface languages keep the overview controls rendered', async ({ browser }) => {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.goto(`${baseUrl}app/`, { waitUntil: 'domcontentloaded' });
  await page.evaluate((key) => {
    localStorage.clear();
    localStorage.setItem(key, JSON.stringify({ lang: 'cs', country: 'CZ', currency: 'CZK' }));
  }, storageKey);
  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.locator('.nav button').last().click();
  const codes = ['cs', 'en', 'de', 'fr', 'it', 'nl', 'bg', 'hr', 'el', 'et', 'fi', 'lv', 'lt', 'lb', 'mt', 'pt', 'sk', 'sl', 'es', 'sv', 'nb', 'uk', 'ru', 'da', 'hu', 'pl', 'tr', 'id', 'hi', 'ms', 'th', 'ur', 'ar', 'he', 'ja', 'ko'];
  for (const code of codes) {
    await page.locator('select').nth(1).selectOption(code);
    await page.locator('.nav button').first().click();
    await expect(page.locator('.filled.big')).toBeVisible();
    const checks = await page.locator('body').evaluate(() => {
      const button = document.querySelector('.filled.big');
      const feature = document.querySelector('.feature');
      const icons = Array.from(document.querySelectorAll('.mi'));
      return {
        lang: document.documentElement.lang,
        dir: document.documentElement.dir,
        buttonText: button?.innerText || '',
        buttonOverflow: button ? button.scrollWidth > button.clientWidth + 2 : true,
        featureOverflow: feature ? feature.scrollWidth > feature.clientWidth + 2 : false,
        iconMax: Math.max(...icons.map((icon) => icon.getBoundingClientRect().width), 0),
      };
    });
    expect(checks.lang).toBe(code);
    expect(checks.dir).toBe(['ar', 'he', 'ur'].includes(code) ? 'rtl' : 'ltr');
    expect(checks.buttonText.length).toBeGreaterThan(1);
    expect(checks.buttonOverflow).toBe(false);
    expect(checks.featureOverflow).toBe(false);
    expect(checks.iconMax).toBeLessThanOrEqual(32);
    await page.locator('.nav button').last().click();
  }
  const localeCoverage = await page.evaluate(() => {
    const codes = window.cashTallyLocales.codes;
    const sources = [
      window.cashTallyLocales.messages,
      window.cashTallyLocaleOverrides,
      window.cashTallyLocaleExtras,
      window.cashTallyLocaleDetailExtras,
      window.cashTallyLocaleActions,
      window.cashTallyLocaleReportExtras,
      window.cashTallyLocaleFunctionalExtras,
    ];
    const required = ['shift', 'posReconciliation', 'posCard', 'posSales', 'posHash', 'deposit', 'weightUnavailable', 'pieces'];
    const dictionaries = Object.fromEntries(codes.map((code) => [code, Object.assign({}, ...sources.map((source) => source?.[code] || {}))]));
    const missing = codes.flatMap((code) => required.filter((key) => !dictionaries[code][key]).map((key) => `${code}:${key}`));
    const untranslated = codes.flatMap((code) => required.filter((key) => code !== 'en' && dictionaries[code][key] === dictionaries.en[key]).map((key) => `${code}:${key}`));
    return { missing, untranslated };
  });
  expect(localeCoverage).toEqual({ missing: [], untranslated: [] });
});
