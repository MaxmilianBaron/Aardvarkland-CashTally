const STORAGE = 'cashtally-preview-v5';
const APP_VERSION = '0.4.1+23';
const BRAND_NAME = 'Aardvarkland';
const FORCE_COUNTRY_PICKER = new URLSearchParams(window.location.search).get('country-picker') === '1';
let forcedPickerStoredCountry = '';

const currencies = {
  CZK: {
    name: 'Česká koruna', symbol: 'Kč',
    notes: [[500000, '5 000 Kč'], [200000, '2 000 Kč'], [100000, '1 000 Kč'], [50000, '500 Kč'], [20000, '200 Kč'], [10000, '100 Kč']],
    coins: [[5000, '50 Kč'], [2000, '20 Kč'], [1000, '10 Kč'], [500, '5 Kč'], [200, '2 Kč'], [100, '1 Kč']],
  },
  EUR: {
    name: 'Euro', symbol: '€',
    notes: [[50000, '€500'], [20000, '€200'], [10000, '€100'], [5000, '€50'], [2000, '€20'], [1000, '€10'], [500, '€5']],
    coins: [[200, '€2'], [100, '€1'], [50, '50 cent'], [20, '20 cent'], [10, '10 cent'], [5, '5 cent'], [2, '2 cent'], [1, '1 cent']],
  },
  USD: {
    name: 'Americký dolar', symbol: '$',
    notes: [[10000, '$100'], [5000, '$50'], [2000, '$20'], [1000, '$10'], [500, '$5'], [200, '$2'], [100, '$1']],
    coins: [[100, '$1 coin'], [50, '50¢'], [25, '25¢'], [10, '10¢'], [5, '5¢'], [1, '1¢']],
  },
  GBP: {
    name: 'Britská libra', symbol: '£',
    notes: [[5000, '£50'], [2000, '£20'], [1000, '£10'], [500, '£5']],
    coins: [[200, '£2'], [100, '£1'], [50, '50p'], [20, '20p'], [10, '10p'], [5, '5p'], [2, '2p'], [1, '1p']],
  },
};
Object.assign(currencies, window.cashTallyCurrencyCatalog || {});
const currencyCodes = () => (window.cashTallyCurrencyCatalogOrder || Object.keys(currencies)).filter(code => currencies[code]);
const currencyName = code => {
  const stored = window.cashTallyLocales?.currencyNames?.[state.lang]?.[code];
  if (stored) return stored;
  try {
    const locale = state.lang === 'nb' ? 'nb-NO' : state.lang;
    const display = new Intl.DisplayNames([locale], { type: 'currency' }).of(code);
    if (display && display !== code) return display;
  } catch {}
  return currencies[code]?.name || code;
};
const currencyFractionDigits = code => Number.isInteger(currencies[code]?.fractionDigits) ? currencies[code].fractionDigits : 2;
const currencyGlyphs = Object.freeze({ CHF: 'Fr', AED: 'د.إ' });
const currencyGlyph = code => currencyGlyphs[code] || currencies[code]?.symbol || code;

const countryCatalog = {
  top: [
    ['IN', '🇮🇳', 'भारत', 'INR'], ['US', '🇺🇸', 'United States', 'USD'], ['ID', '🇮🇩', 'Indonesia', 'IDR'], ['PK', '🇵🇰', 'پاکستان', 'PKR'],
    ['NG', '🇳🇬', 'Nigeria', 'NGN'], ['BR', '🇧🇷', 'Brasil', 'BRL'], ['RU', '🇷🇺', 'Россия', 'RUB'], ['MX', '🇲🇽', 'México', 'MXN'],
    ['JP', '🇯🇵', '日本', 'JPY'], ['EG', '🇪🇬', 'مصر', 'EGP'], ['TR', '🇹🇷', 'Türkiye', 'TRY'], ['TH', '🇹🇭', 'ประเทศไทย', 'THB'],
    ['GB', '🇬🇧', 'United Kingdom', 'GBP'], ['ZA', '🇿🇦', 'South Africa', 'ZAR'], ['KR', '🇰🇷', '대한민국', 'KRW'], ['DZ', '🇩🇿', 'الجزائر', 'DZD'],
    ['AR', '🇦🇷', 'Argentina', 'ARS'], ['CA', '🇨🇦', 'Canada', 'CAD'], ['UA', '🇺🇦', 'Україна', 'UAH'], ['PL', '🇵🇱', 'Polska', 'PLN'],
    ['MY', '🇲🇾', 'Malaysia', 'MYR'], ['SA', '🇸🇦', 'السعودية', 'SAR'], ['AU', '🇦🇺', 'Australia', 'AUD'], ['AE', '🇦🇪', 'الإمارات', 'AED'],
    ['CZ', '🇨🇿', 'Česko', 'CZK'], ['SE', '🇸🇪', 'Sverige', 'SEK'], ['IL', '🇮🇱', 'ישראל', 'ILS'], ['HU', '🇭🇺', 'Magyarország', 'HUF'],
    ['CH', '🇨🇭', 'Schweiz', 'CHF'], ['DK', '🇩🇰', 'Danmark', 'DKK'], ['NO', '🇳🇴', 'Norge', 'NOK'],
  ],
  euro: [
    ['DE', '🇩🇪', 'Deutschland', 'EUR'], ['FR', '🇫🇷', 'France', 'EUR'], ['IT', '🇮🇹', 'Italia', 'EUR'], ['ES', '🇪🇸', 'España', 'EUR'],
    ['NL', '🇳🇱', 'Nederland', 'EUR'], ['BE', '🇧🇪', 'België', 'EUR'], ['AT', '🇦🇹', 'Österreich', 'EUR'], ['BG', '🇧🇬', 'България', 'EUR'],
    ['PT', '🇵🇹', 'Portugal', 'EUR'], ['GR', '🇬🇷', 'Ελλάδα', 'EUR'], ['FI', '🇫🇮', 'Suomi', 'EUR'], ['IE', '🇮🇪', 'Ireland', 'EUR'],
    ['SK', '🇸🇰', 'Slovensko', 'EUR'], ['HR', '🇭🇷', 'Hrvatska', 'EUR'], ['LT', '🇱🇹', 'Lietuva', 'EUR'], ['SI', '🇸🇮', 'Slovenija', 'EUR'],
    ['LV', '🇱🇻', 'Latvija', 'EUR'], ['EE', '🇪🇪', 'Eesti', 'EUR'], ['CY', '🇨🇾', 'Κύπρος', 'EUR'], ['LU', '🇱🇺', 'Lëtzebuerg', 'EUR'],
    ['MT', '🇲🇹', 'Malta', 'EUR'],
  ],
};
const countryById = Object.fromEntries([...countryCatalog.top, ...countryCatalog.euro].map(([id, flag, name, currency]) => [id, { id, flag, name, currency }]));

const T = {
  cs: {
    app: 'Výčetka', free: 'Free · všechny funkce', adFree: 'Ad-free', currency: 'Měna', newCount: 'Nová výčetka', chooseCountry: 'Vyberte zemi', countrySub: 'Vyberte vlajku a otevřete mobilní náhled.', eurozone: 'Eurozone · EUR', euroSub: 'Vyberte členskou zemi eurozóny', country: 'Země', changeCountry: 'Změnit zemi',
    offlineTitle: 'Počítání funguje offline', offlineBody: 'Historie zůstává lokálně v zařízení.', latest: 'Poslední výčetka', detail: 'Detail',
    nothing: 'Zatím nic uloženo. Můžete spočítat první pokladnu.', count: 'Počítání', history: 'Historie', settings: 'Nastavení',
    chooseMode: 'Vyberte režim počítání', withoutTemplate: 'Bez šablony', quick: 'Rychlá výčetka', quickHelp: 'Rychlé sečtení hotovosti bez uzávěrkových údajů.', professional: 'Profesionální uzávěrka', professionalHelp: 'Výčetka s očekávaným stavem, rozdílem a údaji uzávěrky.',
    blind: 'Slepé počítání', blindHelp: 'Očekávaný stav se zobrazí až po dokončení počítání.', blindLocked: 'Počítání uzamčeno – můžete zobrazit výsledek.', finishBlind: 'Dokončit slepé počítání', finishBlindHelp: 'Po uzamčení už nelze měnit počty.', lockAndContinue: 'Uzamknout a pokračovat',
    tapHelp: 'Klepnutím na nominál přidáte zvolený násobek.', banknotes: 'Bankovky', coins: 'Mince', clear: 'Vymazat', closing: 'Údaje uzávěrky', cashCheck: 'Kontrola hotovosti', expected: 'Očekávaný stav', expectedHelp: 'Částka, která má být v pokladně.', float: 'Ponechat v pokladně', floatHelp: 'Pokladní základ pro další směnu.', deposit: 'Navržený odvod', note: 'Poznámka', difference: 'Rozdíl', total: 'Celkem', save: 'Uložit',
    search: 'Hledat v historii', allCurrencies: 'Všechny měny', dateRange: 'Období', from: 'Od', to: 'Do', differencesOnly: 'Jen s rozdílem', historyEmpty: 'Žádné uložené výčetky.', delete: 'Smazat',
    businessProfile: 'Profil provozovny', notSet: 'Nenastaveno', countingSetup: 'Nastavení počítání', templates: 'Šablony pokladen', templatesHelp: 'Předvyplněné údaje pokladny a základ.', denomSettings: 'Nastavení nominálů', denomHelp: 'Viditelné a vlastní nominály.', backup: 'Záloha a obnova', backupHelp: 'Šifrovaný export a import demonstračních dat.',
    appearance: 'Vzhled', colourMode: 'Barevný režim', system: 'Systém', light: 'Světlý', dark: 'Tmavý', haptics: 'Haptická odezva', hapticsHelp: 'Krátká odezva při změně počtu.', defaultLanguage: 'Výchozí jazyk', defaultCurrency: 'Výchozí měna', supported: 'Podporované měny', favoriteOrder: 'Pořadí oblíbených měn',
    privacy: 'Soukromí a lokální data', localOnly: 'Data zůstávají v zařízení', localOnlyBody: 'Preview ukládá demonstrační data jen do tohoto prohlížeče.', appLock: 'Zámek aplikace', appLockOff: 'Vypnuto', appLockOn: 'Zapnuto', privacyOptions: 'Nastavení soukromí', privacyOptionsBody: 'V preview se nic neposílá mimo zařízení.', updates: 'Aktualizace', stores: 'Obchody s aplikacemi', storesBody: 'Aktualizace aplikace jsou distribuované přes obchod.', licences: 'Licence knihoven',
    businessName: 'Název firmy', registrationId: 'IČO / identifikátor', address: 'Adresa', location: 'Provozovna', till: 'Pokladna', cashier: 'Pokladní', manager: 'Vedoucí', shift: 'Směna',
    importPos: 'Importovat POS report', demoPos: 'Použít demo POS', report: 'Náhled reportu', csv: 'CSV', text: 'Text', pdfPrint: 'PDF / Tisk', back: 'Zpět', exportBackup: 'Exportovat zálohu', importBackup: 'Importovat zálohu', reset: 'Resetovat demo data', saved: 'Výčetka uložena.', deleted: 'Výčetka smazána.', close: 'Zavřít', add: 'Přidat', removeAds: 'Výčetka bez reklam', plan: 'Licence', planFree: 'Free · všechny funkce', planAdFree: 'Ad-free · bez reklam', adFreeHelp: 'Preview simuluje trvalé odemknutí bez reklam. Funkce zůstávají stejné.', buyDemo: 'Vyzkoušet Ad-free', restore: 'Obnovit nákup',
    signature: 'Podpis', signatureHelp: 'Podepište se prstem nebo myší. Podpis zůstane součástí demo uzávěrky.', cashierSignature: 'Podpis pokladního', managerSignature: 'Podpis vedoucího', clearSignature: 'Vymazat podpis', saveSignature: 'Použít podpis', signatureMissing: 'Nepodepsáno', proofHash: 'Kontrolní SHA-256 otisk', posReconciliation: 'Párování POS / EFTPOS', posSource: 'Zdroj', posExpected: 'Očekávaná hotovost POS', posCard: 'Platby kartou', posSales: 'Tržby celkem', posHash: 'SHA-256 zdroje', previewOnly: 'Interaktivní browser preview · lokální demo data', pdfZoom: 'Zvětšení náhledu', zoomOut: 'Zmenšit', zoomIn: 'Zvětšit', resetZoom: 'Reset', unlock: 'Odemknout', wrongPin: 'PIN nesouhlasí.', appLockReason: 'Zadejte demo PIN pro zapnutí zámku.',
  },
  en: {
    app: 'Cash Tally', free: 'Free · all features', adFree: 'Ad-free', currency: 'Currency', newCount: 'New count', chooseCountry: 'Choose your country', countrySub: 'Choose a flag to open the mobile preview.', eurozone: 'Eurozone · EUR', euroSub: 'Choose a euro-area member', country: 'Country', changeCountry: 'Change country', offlineTitle: 'Counting works offline', offlineBody: 'History stays locally on the device.', latest: 'Latest count', detail: 'Detail',
    nothing: 'Nothing saved yet. Count the first till.', count: 'Count', history: 'History', settings: 'Settings', chooseMode: 'Choose counting mode', withoutTemplate: 'Without template', quick: 'Quick count', quickHelp: 'Fast cash total without closing details.', professional: 'Professional close', professionalHelp: 'Count with expected cash, difference and closing details.',
    blind: 'Blind count', blindHelp: 'Expected cash is shown only after counting is finished.', blindLocked: 'Count locked – you can now see the result.', finishBlind: 'Finish blind count', finishBlindHelp: 'Locking prevents further changes.', lockAndContinue: 'Lock and continue', tapHelp: 'Tap a denomination to add the selected multiplier.', banknotes: 'Banknotes', coins: 'Coins', clear: 'Clear', closing: 'Closing details', cashCheck: 'Cash check', expected: 'Expected cash', expectedHelp: 'Amount that should be in the till.', float: 'Leave in till', floatHelp: 'Cash float for the next shift.', deposit: 'Suggested deposit', note: 'Note', difference: 'Difference', total: 'Total', save: 'Save',
    search: 'Search history', allCurrencies: 'All currencies', dateRange: 'Date range', from: 'From', to: 'To', differencesOnly: 'Differences only', historyEmpty: 'No saved counts.', delete: 'Delete', businessProfile: 'Business profile', notSet: 'Not set', countingSetup: 'Counting setup', templates: 'Till templates', templatesHelp: 'Reusable till details and cash float.', denomSettings: 'Denomination settings', denomHelp: 'Visible and custom denominations.', backup: 'Backup and restore', backupHelp: 'Encrypted export and import of demonstration data.', appearance: 'Appearance', colourMode: 'Colour mode', system: 'System', light: 'Light', dark: 'Dark', haptics: 'Haptic feedback', hapticsHelp: 'Short feedback when changing quantities.', defaultLanguage: 'Default language', defaultCurrency: 'Default currency', supported: 'Supported currencies', favoriteOrder: 'Favourite currency order',
    privacy: 'Privacy and local data', localOnly: 'Local data only', localOnlyBody: 'Preview data stays in this browser.', appLock: 'App Lock', appLockOff: 'Off', appLockOn: 'On', privacyOptions: 'Privacy options', privacyOptionsBody: 'The preview sends nothing outside this device.', updates: 'Updates', stores: 'App stores', storesBody: 'App updates are distributed through the store.', licences: 'Library licences', businessName: 'Business name', registrationId: 'Registration ID', address: 'Address', location: 'Location', till: 'Till', cashier: 'Cashier', manager: 'Manager', shift: 'Shift', importPos: 'Import POS report', demoPos: 'Use demo POS', report: 'Report preview', csv: 'CSV', text: 'Text', pdfPrint: 'PDF / Print', back: 'Back', exportBackup: 'Export backup', importBackup: 'Import backup', reset: 'Reset demo data', saved: 'Count saved.', deleted: 'Count deleted.', close: 'Close', add: 'Add', removeAds: 'Ad-free version', plan: 'Licence', planFree: 'Free · all features', planAdFree: 'Ad-free · no ads', adFreeHelp: 'The preview simulates a permanent ad-free unlock. Features stay identical.', buyDemo: 'Try Ad-free', restore: 'Restore purchase',
    signature: 'Signature', signatureHelp: 'Sign with a finger or mouse. The signature becomes part of the demo closing.', cashierSignature: 'Cashier signature', managerSignature: 'Manager signature', clearSignature: 'Clear signature', saveSignature: 'Use signature', signatureMissing: 'Not signed', proofHash: 'SHA-256 proof fingerprint', posReconciliation: 'POS / EFTPOS reconciliation', posSource: 'Source', posExpected: 'POS expected cash', posCard: 'Card payments', posSales: 'Total sales', posHash: 'Source SHA-256', previewOnly: 'Interactive browser preview · local demo data', pdfZoom: 'Preview zoom', zoomOut: 'Zoom out', zoomIn: 'Zoom in', resetZoom: 'Reset', unlock: 'Unlock', wrongPin: 'PIN does not match.', appLockReason: 'Enter a demo PIN to enable App Lock.',
  },
};

const SHORT_APP_NAMES = Object.freeze({
  cs: 'Výčetka', en: 'Cash Tally', de: 'Kassenzählung', fr: 'Comptage de caisse', it: 'Conteggio cassa', nl: 'Kass tellen',
  bg: 'Броене на каса', hr: 'Brojanje blagajne', el: 'Καταμέτρηση ταμείου', et: 'Kassa lugemine', fi: 'Kassan laskenta',
  lv: 'Kases skaitīšana', lt: 'Kasos skaičiavimas', lb: 'Kassenzielung', mt: 'Għadd tal-flus', pt: 'Contagem de caixa',
  sk: 'Výčetka', sl: 'Štetje gotovine', es: 'Conteo de caja', sv: 'Kontanträknare', nb: 'Kontantopptelling',
  uk: 'Підрахунок готівки', ru: 'Подсчёт наличных', da: 'Kasseoptælling', hu: 'Készpénzszámlálás', pl: 'Liczenie gotówki',
  tr: 'Nakit sayımı', id: 'Hitung uang tunai', hi: 'नकद गणना', ms: 'Kiraan tunai', th: 'นับเงินสด', ur: 'نقدی گنتی',
  ar: 'عدّ النقد', he: 'ספירת מזומן', ja: '現金集計', ko: '현금 정산',
});
const appName = () => `${BRAND_NAME} ${SHORT_APP_NAMES[state.lang] || SHORT_APP_NAMES.en}`;

function baseState() {
  return {
    screen: 'dashboard', theme: 'light', lang: 'en', country: '', countryView: 'top', currency: 'EUR', favorites: ['EUR', 'CZK'], sessions: [], templates: [],
    business: { name: '', registrationId: '', address: '', location: '', till: '', cashier: '', manager: '', shift: '' },
    hiddenDenoms: {}, customDenoms: {}, appLock: false, lockPinHash: '', locked: false, haptics: true,
    draft: null, currentSession: null, currentSignatureTarget: null, signatureStrokes: [], reportZoom: 1, modal: null, closingOpen: false,
    search: '', filterCurrency: '', differencesOnly: false, dateFrom: '', dateTo: '', showDateRange: false, templateChoice: '',
  };
}

function loadState() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE) || '{}');
    const fresh = baseState();
    const supportedLanguages = window.cashTallyLocales?.codes || ['cs', 'en'];
    const language = supportedLanguages.includes(saved.lang) ? saved.lang : 'en';
    forcedPickerStoredCountry = saved.country || localStorage.getItem('cashtally-preview-country') || '';
    return Object.assign(fresh, saved, { lang: language, country: FORCE_COUNTRY_PICKER ? '' : forcedPickerStoredCountry, countryView: FORCE_COUNTRY_PICKER ? 'top' : (saved.countryView || 'top'), business: Object.assign(fresh.business, saved.business || {}) });
  } catch {
    return baseState();
  }
}

let state = loadState();
if (state.appLock && !sessionStorage.getItem('cashtally-preview-unlocked')) state.locked = true;

const tr = (key, values = {}) => {
  const dictionary = Object.assign(
    {},
    window.cashTallyLocales?.messages?.[state.lang] || {},
    T[state.lang] || {},
    window.cashTallyLocaleOverrides?.[state.lang] || {},
    window.cashTallyLocaleExtras?.[state.lang] || {},
    window.cashTallyLocaleDetailExtras?.[state.lang] || {},
    window.cashTallyLocaleActions?.[state.lang] || {},
    window.cashTallyLocaleReportExtras?.[state.lang] || {},
    window.cashTallyLocaleFunctionalExtras?.[state.lang] || {},
  );
  const result = dictionary[key] || T[state.lang]?.[key] || T.en[key] || key;
  return Object.entries(values).reduce((text, [name, value]) => text.replaceAll(`{${name}}`, String(value)), result);
};
const $ = id => document.getElementById(id);
const MATERIAL_ICON_CODEPOINTS = Object.freeze({
  add: 0xe047,
  add_circle_outline: 0xe050,
  arrow_back: 0xe092,
  assignment: 0xe0a5,
  assignment_turned_in: 0xe0aa,
  badge: 0xea67,
  business: 0xe11b,
  campaign: 0xef49,
  code: 0xe176,
  content_copy: 0xe14d,
  contrast: 0xf04d8,
  currency_exchange: 0xf04dc,
  date_range: 0xe1b6,
  delete_outline: 0xe1bb,
  delete_sweep: 0xe1bc,
  description: 0xe1bf,
  diamond: 0xf04ed,
  download: 0xe201,
  draw: 0xe746,
  edit: 0xe3c9,
  enhanced_encryption: 0xe235,
  event: 0xe23e,
  expand_less: 0xe5ce,
  expand_more: 0xe5cf,
  fact_check: 0xe256,
  filter_alt_off: 0xf0500,
  flash_on: 0xe293,
  history: 0xe314,
  check: 0xe156,
  check_circle: 0xe159,
  chevron_right: 0xe15f,
  language: 0xe366,
  lock: 0xe3ae,
  lock_open: 0xe3b0,
  lock_outline: 0xe3b1,
  notes: 0xe44c,
  payments: 0xe482,
  person: 0xe7fd,
  picture_as_pdf: 0xe4c0,
  point_of_sale: 0xe4d8,
  place: 0xe55f,
  print: 0xe4ea,
  privacy_tip: 0xe4ed,
  public: 0xe4f0,
  remove: 0xe516,
  restart_alt: 0xe531,
  savings: 0xe553,
  share: 0xe80d,
  schedule: 0xe8b5,
  search: 0xe567,
  security: 0xe569,
  settings: 0xe57f,
  star: 0xe5f9,
  star_border: 0xe5fa,
  store: 0xe8d1,
  supervisor_account: 0xe8d3,
  system_update_alt: 0xe637,
  table_view: 0xe63c,
  title: 0xe668,
  toll: 0xe66d,
  tune: 0xe683,
  upload: 0xe695,
  upload_file: 0xe696,
  verified: 0xe699,
  vibration: 0xe6a0,
  visibility_off: 0xe6be,
  wifi_off: 0xe6eb,
  zoom_in: 0xe6fd,
  zoom_out: 0xe6fe,
});
const mi = icon => `<span class="mi" aria-hidden="true">${String.fromCodePoint(MATERIAL_ICON_CODEPOINTS[icon] || 0xe24e)}</span>`;
const esc = value => String(value ?? '').replace(/[&<>"']/g, char => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' }[char]));

function persist() {
  const copy = JSON.parse(JSON.stringify(Object.assign({}, state, { modal: null, locked: false, signatureStrokes: [] })));
  if (FORCE_COUNTRY_PICKER && !state.country && forcedPickerStoredCountry) copy.country = forcedPickerStoredCountry;
  localStorage.setItem(STORAGE, JSON.stringify(copy));
  applyTheme();
}

function applyTheme() {
  let theme = state.theme;
  if (theme === 'system') theme = matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  document.documentElement.dataset.theme = theme;
  document.documentElement.lang = state.lang;
  document.documentElement.dir = ['ar', 'he', 'ur'].includes(state.lang) ? 'rtl' : 'ltr';
}

function allDenoms(code) {
  const c = currencies[code] || currencies.CZK;
  const builtIn = [...c.notes.map(([valueMinor, label]) => ({ id: `note-${valueMinor}`, kind: 'note', valueMinor, label })), ...c.coins.map(([valueMinor, label]) => ({ id: `coin-${valueMinor}`, kind: 'coin', valueMinor, label }))];
  const custom = (state.customDenoms[code] || []).map(item => Object.assign({ kind: 'custom' }, item));
  return builtIn.concat(custom).filter(item => !(state.hiddenDenoms[code] || []).includes(item.id));
}

function denominationWeight(item, code = state.currency) {
  return window.cashTallyWeightCatalog?.[code]?.[item.id] || null;
}

function weightLabel(item, code = state.currency) {
  const weight = denominationWeight(item, code);
  if (!weight || !Number.isFinite(Number(weight.milligrams))) return '';
  const milligrams = Number(weight.milligrams);
  const kilograms = milligrams >= 1000000;
  const amount = kilograms ? milligrams / 1000000 : milligrams / 1000;
  const locale = state.lang === 'nb' ? 'nb-NO' : (state.lang === 'cs' ? 'cs-CZ' : state.lang);
  const formatted = new Intl.NumberFormat(locale, { maximumFractionDigits: 1, minimumFractionDigits: Number.isInteger(amount) ? 0 : 1 }).format(amount);
  return `${weight.approximate ? '≈ ' : ''}${formatted} ${kilograms ? 'kg' : 'g'}`;
}

function money(minor, code = state.currency) {
  const amount = (Number(minor) || 0) / (10 ** currencyFractionDigits(code));
  const locale = state.lang === 'cs' ? 'cs-CZ' : (state.lang === 'nb' ? 'nb-NO' : state.lang);
  const fractionDigits = currencyFractionDigits(code);
  return new Intl.NumberFormat(locale, { style: 'currency', currency: code, minimumFractionDigits: fractionDigits, maximumFractionDigits: fractionDigits }).format(amount);
}

function countryCard(item) {
  const icon = window.cashTallyFlagSvg ? window.cashTallyFlagSvg(item.id) : item.flag;
  return `<button class="country-card" data-country="${esc(item.id)}" type="button" onclick="selectCountry('${esc(item.id)}')"><span class="country-flag" aria-hidden="true">${icon}</span><span class="country-name">${esc(item.name)}</span><span class="country-currency">${esc(item.currency)}</span></button>`;
}

function countryPicker() {
  const euro = state.countryView === 'euro';
  const euroCard = `<button class="country-card" data-euro="true" type="button" onclick="state.countryView='euro';persist();render()"><span class="country-flag" aria-hidden="true">${window.cashTallyFlagSvg ? window.cashTallyFlagSvg('EU') : '🇪🇺'}</span><span class="country-name">${esc(tr('eurozone').split(' · ')[0])}</span><span class="country-currency">EUR</span></button>`;
  const cards = euro ? countryCatalog.euro.map(([id, flag, name, currency]) => countryCard({ id, flag, name, currency })).join('') : `${countryCard({ id: countryCatalog.top[0][0], flag: countryCatalog.top[0][1], name: countryCatalog.top[0][2], currency: countryCatalog.top[0][3] })}${euroCard}${countryCatalog.top.slice(1).map(([id, flag, name, currency]) => countryCard({ id, flag, name, currency })).join('')}`;
  return `<main class="scaffold country-scaffold"><div class="country-scroll"><div class="country-panel">${euro ? `<div class="country-head"><button class="country-back" type="button" onclick="state.countryView='top';persist();render()" aria-label="${esc(tr('back'))}">${mi('arrow_back')}</button><div><h1 class="country-title country-title-left">${esc(tr('eurozone'))}</h1><p class="country-sub country-sub-left">${esc(tr('euroSub'))}</p></div></div>` : `<div class="country-logo" aria-hidden="true">${window.cashTallyLogoSvg ? window.cashTallyLogoSvg() : 'CT'}</div>`}<div class="country-grid">${cards}</div></div></div></main>`;
}

function parseMinor(value, code = state.currency) {
  let normalized = String(value ?? '').replace(/\s/g, '').replace(/[^0-9,.-]/g, '');
  const comma = normalized.lastIndexOf(',');
  const dot = normalized.lastIndexOf('.');
  if (comma >= 0 && dot >= 0) normalized = comma > dot ? normalized.replaceAll('.', '').replace(',', '.') : normalized.replaceAll(',', '');
  else normalized = normalized.replace(',', '.');
  if (!normalized || !Number.isFinite(Number(normalized))) return null;
  return Math.round(Number(normalized) * (10 ** currencyFractionDigits(code)));
}

function inputMoney(minor, code = state.currency) {
  return minor == null ? '' : String(Number(minor) / (10 ** currencyFractionDigits(code))).replace('.', state.lang === 'cs' ? ',' : '.');
}

function draftTotal() {
  if (!state.draft) return 0;
  return allDenoms(state.draft.currency).reduce((sum, item) => sum + item.valueMinor * Number(state.draft.qty[item.id] || 0), 0);
}

function difference() {
  const d = state.draft;
  if (!d || d.mode !== 'professional' || (d.blind && !d.quantitiesLocked)) return null;
  const expected = parseMinor(d.expected, d.currency);
  return expected == null ? null : draftTotal() - expected;
}

function appbar(title, options = {}) {
  const back = options.back ? `<button class="icon-btn" type="button" onclick="goBack()" aria-label="${esc(tr('back'))}">${mi('arrow_back')}</button>` : '';
  const brand = options.brand ? `<div class="brand-logo">${window.cashTallyLogoSvg ? window.cashTallyLogoSvg() : mi('point_of_sale')}</div>` : '';
  return `<div class="appbar">${back}${brand}<div class="grow appbar-title">${esc(title)}</div>${options.action || ''}</div>`;
}

function nav() {
  return `<nav class="nav" aria-label="${esc(tr('count'))}">${[['dashboard', 'point_of_sale', tr('count')], ['history', 'history', tr('history')], ['settings', 'settings', tr('settings')]].map(([screen, icon, label]) => `<button type="button" class="${state.screen === screen ? 'active' : ''}" onclick="navigate('${screen}')"><span class="nav-indicator">${mi(icon)}</span><span>${esc(label)}</span></button>`).join('')}</nav>`;
}

function modalHtml() {
  if (!state.modal) return '';
  if (state.modal === 'mode') {
    const templates = state.templates.length ? `<div class="field"><label>${esc(tr('templates'))}</label>${mi('point_of_sale')}<select onchange="state.templateChoice=this.value;persist()"><option value="">${esc(tr('withoutTemplate'))}</option>${state.templates.map((item, index) => `<option value="${index}" ${state.templateChoice === String(index) ? 'selected' : ''}>${esc(item.name)} · ${esc(item.currency)} · ${esc(currencyName(item.currency))}</option>`).join('')}</select></div><div class="sp12"></div>` : '';
    return `<div class="modal open" onclick="if(event.target===this){state.modal=null;render()}"><div class="sheet"><div class="drag"></div><div class="title-large">${esc(tr('chooseMode'))}</div><div class="sp12"></div>${templates}<button class="mode-card" type="button" onclick="startCount('quick')"><div class="list-tile"><div class="list-leading">${mi('flash_on')}</div><div class="list-body"><div class="list-title">${esc(tr('quick'))}</div><div class="list-sub">${esc(tr('quickHelp'))}</div></div>${mi('chevron_right')}</div></button><button class="mode-card" type="button" onclick="startCount('professional')"><div class="list-tile"><div class="list-leading">${mi('assignment_turned_in')}</div><div class="list-body"><div class="list-title">${esc(tr('professional'))}</div><div class="list-sub">${esc(tr('professionalHelp'))}</div></div>${mi('chevron_right')}</div></button></div></div>`;
  }
  return '';
}

function layout(body, options = {}) {
  const bottom = options.bottom === false ? '' : nav();
  return `<main class="scaffold">${options.appbarHtml || ''}<div class="scroll ${state.screen === 'count' ? 'count-scroll' : ''}">${body}</div>${bottom}<div class="toast" id="toast"></div>${modalHtml()}</main>`;
}

function dashboard() {
  const latest = state.sessions[0];
  const chips = currencyCodes().map(code => `<div class="currency-pair"><button class="chip ${state.currency === code ? 'selected' : ''}" type="button" onclick="state.currency='${code}';persist();render()"><span class="chip-avatar">${esc(currencyGlyph(code))}</span><span class="chip-code">${esc(code)}</span></button><button class="star ${state.favorites.includes(code) ? 'active' : ''}" type="button" onclick="event.stopPropagation();toggleFavorite('${code}')" aria-label="${esc(code)}">${mi(state.favorites.includes(code) ? 'star' : 'star_border')}</button></div>`).join('');
  const latestCard = latest ? `<div class="card latest clickable" onclick="openSession('${esc(latest.id)}')"><div class="grow"><div class="headline-small">${money(latest.total, latest.currency)}</div><div class="body-small">${esc(latest.currency)} · ${new Date(latest.updatedAt).toLocaleString()}${latest.difference == null ? '' : `<br>${esc(tr('difference'))}: ${money(latest.difference, latest.currency)}`}</div></div>${mi('chevron_right')}</div>` : `<div class="card pad body">${esc(tr('nothing'))}</div>`;
  return layout(`<div class="title-medium">${esc(tr('currency'))}</div><div class="sp8"></div><div class="currency-strip">${chips}</div><div class="sp20"></div><button class="filled big" type="button" onclick="openNewCount()">${mi('add_circle_outline')} ${esc(tr('newCount'))}</button><div class="sp28"></div><div class="row"><div class="grow title-large">${esc(tr('latest'))}</div>${latest ? `<button class="text-btn" type="button" onclick="openSession('${esc(latest.id)}')">${esc(tr('detail'))}</button>` : ''}</div><div class="sp8"></div>${latestCard}<div class="sp24"></div>`, { appbarHtml: appbar(appName(), { brand: true }) });
}

function openNewCount() { state.modal = 'mode'; state.templateChoice = ''; persist(); render(); }

function startCount(mode) {
  const template = state.templateChoice === '' ? null : state.templates[Number(state.templateChoice)];
  const currency = template?.currency && currencies[template.currency] ? template.currency : state.currency;
  const business = Object.assign({}, state.business);
  const qty = {};
  if (template?.quantities) Object.assign(qty, template.quantities);
  state.modal = null;
  state.closingOpen = false;
  state.screen = 'count';
  state.currentSignatureTarget = null;
  state.signatureStrokes = [];
  state.draft = { id: `d${Date.now()}`, editSessionId: null, createdAt: null, documentNumber: `DEMO-${new Date().getFullYear()}-${String(Date.now()).slice(-6)}`, mode, currency, step: 1, blind: false, quantitiesLocked: false, qty, expected: '', float: template ? inputMoney(template.floatMinor || 0, currency) : '', note: '', closingTitle: '', businessName: business.name, registrationId: business.registrationId, address: business.address, location: template?.location || business.location, till: template?.till || business.till, cashier: business.cashier, manager: business.manager, shift: business.shift, cashierSignature: '', managerSignature: '', pos: null };
  persist(); render();
}

let longPressTimer = null;
let longPressTriggered = false;

function startLongPress(event, id, step) {
  if (event.target.closest('button') || state.draft?.quantitiesLocked) return;
  clearTimeout(longPressTimer);
  longPressTriggered = false;
  longPressTimer = setTimeout(() => {
    longPressTriggered = true;
    changeQty(id, -step);
  }, 500);
}

function cancelLongPress() {
  clearTimeout(longPressTimer);
  longPressTimer = null;
}

function denomRow(item) {
  const d = state.draft;
  const quantity = Number(d.qty[item.id] || 0);
  const disabled = d.quantitiesLocked ? 'disabled' : '';
  const weight = weightLabel(item, d.currency);
  return `<div class="card denom clickable" onpointerdown="startLongPress(event,'${esc(item.id)}',${d.step})" onpointerup="cancelLongPress(event)" onpointercancel="cancelLongPress(event)" onclick="if(event.target.closest('button') || longPressTriggered){longPressTriggered=false;return;}changeQty('${esc(item.id)}',${d.step})"><div class="denom-top"><div class="denom-name"><div class="title-medium">${esc(item.label)}</div><div class="body-small">${esc(item.kind === 'note' ? tr('banknotes') : tr('coins'))}</div>${weight ? `<div class="body-small denom-weight">${esc(weight)}</div>` : ''}</div><div class="denom-subtotal">${money(item.valueMinor * quantity, d.currency)}</div></div><div class="stepper"><button class="step-btn" type="button" ${disabled} onclick="event.stopPropagation();changeQty('${esc(item.id)}',-${d.step})">${mi('remove')}</button><button class="qty" type="button" ${disabled} onclick="event.stopPropagation();editQty('${esc(item.id)}')">${quantity}</button><button class="step-btn" type="button" ${disabled} onclick="event.stopPropagation();changeQty('${esc(item.id)}',${d.step})">${mi('add')}</button><span class="step-label">×${d.step}</span></div></div>`;
}

function smallField(key, icon, prop) {
  return `<div class="field" style="margin-bottom:10px"><label>${esc(tr(key))}</label>${mi(icon)}<input name="draft-${esc(prop)}" value="${esc(state.draft[prop])}" oninput="state.draft['${esc(prop)}']=this.value;persist()"></div>`;
}

function signatureButton(target) {
  const has = Boolean(state.draft[target]);
  return `<div class="card list-tile clickable" onclick="openSignature('${target}')"><div class="list-leading">${mi(has ? 'draw' : 'edit')}</div><div class="list-body"><div class="list-title">${esc(tr(target === 'cashierSignature' ? 'cashierSignature' : 'managerSignature'))}</div><div class="list-sub">${has ? esc(tr('signature')) : esc(tr('signatureMissing'))}</div></div>${mi('chevron_right')}</div>`;
}

function professionalFields() {
  const d = state.draft;
  const diff = difference();
  const expectedVisible = !d.blind || d.quantitiesLocked;
  return `<div class="sp24"></div><div class="card"><div class="list-tile clickable" onclick="state.closingOpen=!state.closingOpen;persist();render()"><div class="list-leading">${mi('assignment')}</div><div class="list-body"><div class="list-title">${esc(tr('closing'))}</div><div class="list-sub">${esc(d.documentNumber)}</div></div>${mi(state.closingOpen ? 'expand_less' : 'expand_more')}</div>${state.closingOpen ? `<div class="pad"><div class="field"><label>${esc(tr('closing'))}</label>${mi('title')}<input value="${esc(d.closingTitle)}" oninput="state.draft.closingTitle=this.value;persist()"></div><div class="sp12"></div>${smallField('businessName', 'business', 'businessName')}${smallField('registrationId', 'badge', 'registrationId')}${smallField('address', 'place', 'address')}${smallField('location', 'store', 'location')}${smallField('till', 'point_of_sale', 'till')}${smallField('cashier', 'person', 'cashier')}${smallField('manager', 'supervisor_account', 'manager')}${smallField('shift', 'schedule', 'shift')}<div class="sp8"></div><button class="outlined" type="button" onclick="importPosDemo()">${mi('point_of_sale')} ${esc(tr('demoPos'))}</button><label class="outlined" style="margin-left:8px"><input class="file-input" type="file" accept=".csv,.txt,text/csv,text/plain" onchange="importPosFile(this.files[0])">${mi('upload_file')} ${esc(tr('importPos'))}</label><div class="sp12"></div>${d.pos ? `<div class="info-banner">${mi('check_circle')}<div><strong>${esc(tr('posReconciliation'))}</strong><div class="body-small">${esc(d.pos.sourceFileName)} · ${money(d.pos.expectedMinor, d.currency)}</div></div></div>` : ''}<div class="sp16"></div><div class="title-medium">${esc(tr('signature'))}</div><div class="sp8"></div>${signatureButton('cashierSignature')}${signatureButton('managerSignature')}</div>` : ''}</div><div class="sp24"></div><div class="title-large">${esc(tr('cashCheck'))}</div><div class="sp8"></div>${expectedVisible ? `<div class="field"><label>${esc(tr('expected'))} (${esc(d.currency)})</label>${mi('fact_check')}<input name="draft-expected" inputmode="decimal" value="${esc(d.expected)}" oninput="state.draft.expected=this.value;persist();renderSoft()"></div><div class="helper">${esc(tr('expectedHelp'))}</div>` : `<div class="info-banner">${mi('visibility_off')}<div>${esc(tr('blindHelp'))}</div></div>`}<div class="sp12"></div><div class="field"><label>${esc(tr('float'))} (${esc(d.currency)})</label>${mi('savings')}<input name="draft-float" inputmode="decimal" value="${esc(d.float)}" oninput="state.draft.float=this.value;persist()"></div><div class="helper">${esc(tr('floatHelp'))}</div>${d.blind && !d.quantitiesLocked ? `<div class="sp12"></div><button class="tonal" type="button" onclick="finishBlindCount()">${mi('lock')} ${esc(tr('finishBlind'))}</button>` : ''}${diff == null ? '' : `<div class="sp16"></div><div class="card ${diff === 0 ? 'positive' : 'warning'}"><div class="list-tile"><div class="list-body"><div class="list-title">${esc(tr('difference'))}</div></div><div class="headline-small ${diff < 0 ? 'danger' : ''}">${money(diff, d.currency)}</div></div></div>`}`;
}

function countScreen() {
  if (!state.draft) { state.screen = 'dashboard'; return dashboard(); }
  const d = state.draft;
  const c = currencies[d.currency];
  const notes = allDenoms(d.currency).filter(item => item.kind === 'note' || item.kind === 'custom').map(denomRow).join('');
  const coins = allDenoms(d.currency).filter(item => item.kind === 'coin').map(denomRow).join('');
  const options = currencyCodes().map(code => `<option value="${code}" ${code === d.currency ? 'selected' : ''}>${code} · ${esc(currencyName(code))}</option>`).join('');
  const locked = d.blind && !d.quantitiesLocked;
  return `<main class="scaffold">${appbar(tr('newCount'), { back: true })}<div class="scroll count-scroll"><div class="field"><label>${esc(tr('currency'))}</label>${mi('currency_exchange')}<select onchange="changeDraftCurrency(this.value)">${options}</select></div><div class="sp12"></div><div class="card"><div class="list-tile"><div class="list-leading">${mi(d.mode === 'professional' ? 'assignment_turned_in' : 'flash_on')}</div><div class="list-body"><div class="list-title">${esc(d.mode === 'professional' ? tr('professional') : tr('quick'))}</div><div class="list-sub">${esc(d.mode === 'professional' ? tr('professionalHelp') : tr('quickHelp'))}</div></div>${d.quantitiesLocked ? `<span class="pill">${mi('lock')} ${esc(tr('blindLocked'))}</span>` : ''}</div></div>${d.mode === 'professional' ? `<div class="sp12"></div><div class="card"><div class="list-tile clickable" onclick="dToggleBlind()"><div class="list-leading">${mi('visibility_off')}</div><div class="list-body"><div class="list-title">${esc(tr('blind'))}</div><div class="list-sub">${esc(tr('blindHelp'))}</div></div><div class="switch ${d.blind ? 'on' : ''}"></div></div></div>` : ''}<div class="sp12"></div><div class="segmented">${[1, 10, 50, 100].map(n => `<button type="button" class="${d.step === n ? 'active' : ''}" onclick="state.draft.step=${n};persist();render()">×${n}</button>`).join('')}</div><div class="sp6"></div><div class="body-small">${esc(tr('tapHelp'))}</div><div class="sp24"></div><div class="section-head">${mi('payments')}<div class="title-large">${esc(tr('banknotes'))}</div><button class="text-btn" type="button" ${locked ? 'disabled' : ''} onclick="clearKind('notes')">${esc(tr('clear'))}</button></div><div class="sp8"></div>${notes || `<div class="empty">${mi('payments')}<div>${esc(tr('nothing'))}</div></div>`}<div class="sp24"></div><div class="section-head">${mi('toll')}<div class="title-large">${esc(tr('coins'))}</div><button class="text-btn" type="button" ${locked ? 'disabled' : ''} onclick="clearKind('coins')">${esc(tr('clear'))}</button></div><div class="sp8"></div>${coins || `<div class="empty">${mi('toll')}<div>${esc(tr('nothing'))}</div></div>`}${d.mode === 'professional' ? professionalFields() : ''}<div class="sp12"></div><div class="field"><label>${esc(tr('note'))}</label>${mi('notes')}<textarea name="draft-note" oninput="state.draft.note=this.value;persist()">${esc(d.note)}</textarea></div></div><div class="count-bottom"><div class="grow"><span class="body">${esc(tr('total'))}</span><span class="headline-small">${locked ? '••••' : money(draftTotal(), d.currency)}</span></div><button class="filled" type="button" ${locked ? 'disabled' : ''} onclick="saveCount()">${mi('check')} ${esc(tr('save'))}</button></div><div class="toast" id="toast"></div></main>`;
}

function history() {
  const list = filteredSessions();
  const options = `<option value="">${esc(tr('allCurrencies'))}</option>${currencyCodes().map(code => `<option value="${code}" ${state.filterCurrency === code ? 'selected' : ''}>${code}</option>`).join('')}`;
  const dateFields = state.showDateRange ? `<div class="filter-row"><div class="field"><label>${esc(tr('from'))}</label>${mi('event')}<input type="date" value="${esc(state.dateFrom)}" onchange="state.dateFrom=this.value;persist();render()"></div><div class="field"><label>${esc(tr('to'))}</label>${mi('event')}<input type="date" value="${esc(state.dateTo)}" onchange="state.dateTo=this.value;persist();render()"></div></div>` : '';
  const cards = list.length ? list.map(s => `<div class="card history-card clickable" onclick="openSession('${esc(s.id)}')"><div class="grow"><div class="title-large">${money(s.total, s.currency)}</div><div class="body-small">${esc(s.currency)} · ${new Date(s.updatedAt).toLocaleString()}<br>${esc(s.mode === 'quick' ? tr('quick') : tr('professional'))}${s.difference == null ? '' : `<br>${esc(tr('difference'))}: ${money(s.difference, s.currency)}`}</div></div><button class="icon-btn" type="button" onclick="event.stopPropagation();deleteSession('${esc(s.id)}')" aria-label="${esc(tr('delete'))}">${mi('delete_outline')}</button>${mi('chevron_right')}</div>`).join('') : `<div class="empty">${mi('history')}<div>${esc(tr('historyEmpty'))}</div></div>`;
  return layout(`<div class="filters"><div class="field"><label>${esc(tr('search'))}</label>${mi('search')}<input name="history-search" value="${esc(state.search)}" oninput="state.search=this.value;renderSoftHistory()"></div><div class="filter-row"><div class="field"><label>${esc(tr('currency'))}</label><select onchange="state.filterCurrency=this.value;persist();render()">${options}</select></div><button class="outlined" type="button" onclick="state.showDateRange=!state.showDateRange;persist();render()">${mi('date_range')} ${esc(tr('dateRange'))}</button></div>${dateFields}<label class="check-row"><input type="checkbox" ${state.differencesOnly ? 'checked' : ''} onchange="state.differencesOnly=this.checked;persist();render()">${esc(tr('differencesOnly'))}</label></div><div class="sp16"></div><div class="history-list" id="history-list">${cards}</div>`, { appbarHtml: appbar(tr('history'), { action: `<button class="icon-btn" type="button" onclick="clearFilters()" aria-label="${esc(tr('clear'))}">${mi('filter_alt_off')}</button>` }) });
}

function filteredSessions() {
  return state.sessions.filter(session => {
    const haystack = JSON.stringify(session).toLowerCase();
    const date = session.updatedAt.slice(0, 10);
    return (!state.filterCurrency || session.currency === state.filterCurrency) && (!state.differencesOnly || session.difference !== 0) && (!state.search || haystack.includes(state.search.toLowerCase())) && (!state.dateFrom || date >= state.dateFrom) && (!state.dateTo || date <= state.dateTo);
  });
}

function countrySettingsSection() {
  const selected = countryById[state.country];
  const icon = selected && window.cashTallyFlagSvg ? window.cashTallyFlagSvg(selected.id) : (window.cashTallyFlagSvg ? window.cashTallyFlagSvg('EU') : mi('public'));
  return `<section class="settings-section"><div class="title-large">${esc(tr('country'))}</div><div class="card clickable" onclick="changeCountry()"><div class="list-tile"><div class="list-leading country-setting-flag">${icon}</div><div class="list-body"><div class="list-title">${esc(selected?.name || tr('notSet'))}</div><div class="list-sub">${esc(tr('changeCountry'))}</div></div>${mi('chevron_right')}</div></div></section>`;
}

function settings() {
  return settingsClean();
  const languageCodes = window.cashTallyLocales?.codes || ['cs', 'en'];
  const languageLabels = window.cashTallyLocales?.labels || { cs: 'Čeština', en: 'English' };
  const langOptions = languageCodes.map(value => `<option value="${value}" ${state.lang === value ? 'selected' : ''}>${esc(languageLabels[value] || value)}</option>`).join('');
  const currencyOptions = currencyCodes().map(code => `<option value="${code}" ${state.currency === code ? 'selected' : ''}>${code} · ${esc(currencyName(code))}</option>`).join('');
  const currencyRows = currencyCodes().map((code, index) => `${index ? '<div class="divider"></div>' : ''}<div class="list-tile"><div class="list-leading"><span class="chip-avatar">${esc(currencies[code].symbol.trim().slice(0, 2))}</span></div><div class="list-body"><div class="list-title">${esc(currencyName(code))}</div><div class="list-sub">${code}</div></div><button class="icon-btn ${state.favorites.includes(code) ? 'favorite-star' : ''}" type="button" onclick="toggleFavorite('${code}')" aria-label="${esc(code)}">${mi(state.favorites.includes(code) ? 'star' : 'star_border')}</button></div>`).join('');
  const planTitle = state.adFree ? tr('planAdFree') : tr('planFree');
  return layout(`${countrySettingsSection()}<section class="settings-section"><div class="title-large">${esc(tr('plan'))}</div><div class="card pad"><div class="row gap12">${mi(state.adFree ? 'verified' : 'campaign')}<div class="grow"><div class="title-medium">${esc(planTitle)}</div><div class="body-small">${esc(state.adFree ? tr('adFreeHelp') : tr('adFreeHelp'))}</div></div></div><div class="sp12"></div><div class="subpage-actions"><button class="tonal" type="button" onclick="state.modal='adfree';render()">${mi('diamond')} ${esc(state.adFree ? tr('adFree') : tr('buyDemo'))}</button><button class="text-btn" type="button" onclick="toast(tr('restore'))">${esc(tr('restore'))}</button></div></div></section><section class="settings-section"><div class="title-large">${esc(tr('businessProfile'))}</div><div class="card clickable" onclick="navigate('business')"><div class="list-tile"><div class="list-leading">${mi('business')}</div><div class="list-body"><div class="list-title">${esc(state.business.name || tr('notSet'))}</div><div class="list-sub">${esc([state.business.location, state.business.till].filter(Boolean).join(' · '))}</div></div>${mi('chevron_right')}</div></div></section><section class="settings-section"><div class="title-large">${esc(tr('countingSetup'))}</div><div class="card"><div class="list-tile clickable" onclick="navigate('templates')"><div class="list-leading">${mi('point_of_sale')}</div><div class="list-body"><div class="list-title">${esc(tr('templates'))}</div><div class="list-sub">${esc(tr('templatesHelp'))}</div></div>${mi('chevron_right')}</div><div class="divider"></div><div class="list-tile clickable" onclick="navigate('denoms')"><div class="list-leading">${mi('tune')}</div><div class="list-body"><div class="list-title">${esc(tr('denomSettings'))}</div><div class="list-sub">${esc(tr('denomHelp'))}</div></div>${mi('chevron_right')}</div><div class="divider"></div><div class="list-tile clickable" onclick="navigate('backup')"><div class="list-leading">${mi('enhanced_encryption')}</div><div class="list-body"><div class="list-title">${esc(tr('backup'))}</div><div class="list-sub">${esc(tr('backupHelp'))}</div></div>${mi('chevron_right')}</div></div></section><section class="settings-section"><div class="title-large">${esc(tr('appearance'))}</div><div class="card settings-select"><div class="field"><label>${esc(tr('colourMode'))}</label>${mi('contrast')}<select onchange="setTheme(this.value)"><option value="system" ${state.theme === 'system' ? 'selected' : ''}>${esc(tr('system'))}</option><option value="light" ${state.theme === 'light' ? 'selected' : ''}>${esc(tr('light'))}</option><option value="dark" ${state.theme === 'dark' ? 'selected' : ''}>${esc(tr('dark'))}</option></select></div><div class="sp12"></div><div class="list-tile"><div class="list-leading">${mi('vibration')}</div><div class="list-body"><div class="list-title">${esc(tr('haptics'))}</div><div class="list-sub">${esc(tr('hapticsHelp'))}</div></div><div class="switch ${state.haptics ? 'on' : ''}" role="switch" aria-checked="${state.haptics}" onclick="state.haptics=!state.haptics;persist();render()"></div></div></div></section><section class="settings-section"><div class="title-large">${esc(tr('defaultLanguage'))}</div><div class="card settings-select"><div class="field"><label>${esc(tr('defaultLanguage'))}</label>${mi('language')}<select onchange="setLang(this.value)">${langOptions}</select></div></div></section><section class="settings-section"><div class="title-large">${esc(tr('defaultCurrency'))}</div><div class="card settings-select"><div class="field"><label>${esc(tr('defaultCurrency'))}</label>${mi('currency_exchange')}<select onchange="state.currency=this.value;persist();render()">${currencyOptions}</select></div></div></section><section class="settings-section"><div class="title-large">${esc(tr('supported'))}</div><div class="card">${currencyRows}</div></section><section class="settings-section"><div class="title-large">${esc(tr('privacy'))}</div><div class="card"><div class="list-tile"><div class="list-leading">${mi('delete_outline')}</div><div class="list-body"><div class="list-title">${esc(tr('localOnly'))}</div><div class="list-sub">${esc(tr('localOnlyBody'))}</div></div></div><div class="divider"></div><div class="list-tile clickable" onclick="toggleAppLock()"><div class="list-leading">${mi('lock_outline')}</div><div class="list-body"><div class="list-title">${esc(tr('appLock'))}</div><div class="list-sub">${esc(state.appLock ? tr('appLockOn') : tr('appLockOff'))}</div></div><div class="switch ${state.appLock ? 'on' : ''}"></div></div><div class="divider"></div><div class="list-tile clickable" onclick="toast(tr('privacyOptionsBody'))"><div class="list-leading">${mi('privacy_tip')}</div><div class="list-body"><div class="list-title">${esc(tr('privacyOptions'))}</div><div class="list-sub">${esc(tr('privacyOptionsBody'))}</div></div>${mi('chevron_right')}</div></div></section><section class="settings-section"><div class="title-large">${esc(tr('updates'))}</div><div class="card"><div class="list-tile"><div class="list-leading">${mi('system_update_alt')}</div><div class="list-body"><div class="list-title">${esc(tr('stores'))}</div><div class="list-sub">${esc(tr('storesBody'))}</div></div></div></div></section><div class="sp24"></div><div class="card"><div class="list-tile"><div class="list-leading">${mi('code')}</div><div class="list-body"><div class="list-title">${esc(tr('licences'))}</div></div>${mi('chevron_right')}</div></div><div class="version">${esc(tr('app'))} ${APP_VERSION} · ${esc(tr('previewOnly'))}</div>`, { appbarHtml: appbar(tr('settings')) });
}

function settingsClean() {
  const languageCodes = window.cashTallyLocales?.codes || ['cs', 'en'];
  const languageLabels = window.cashTallyLocales?.labels || { cs: 'Čeština', en: 'English' };
  const langOptions = languageCodes.map(value => `<option value="${value}" ${state.lang === value ? 'selected' : ''}>${esc(languageLabels[value] || value)}</option>`).join('');
  const currencyOptions = currencyCodes().map(code => `<option value="${code}" ${state.currency === code ? 'selected' : ''}>${code} · ${esc(currencyName(code))}</option>`).join('');
  const currencyRows = currencyCodes().map((code, index) => `${index ? '<div class="divider"></div>' : ''}<div class="list-tile"><div class="list-leading"><span class="chip-avatar currency-settings-icon">${esc(currencyGlyph(code))}</span></div><div class="list-body"><div class="list-title">${esc(currencyName(code))}</div><div class="list-sub">${code}</div></div><button class="icon-btn ${state.favorites.includes(code) ? 'favorite-star' : ''}" type="button" onclick="toggleFavorite('${code}')" aria-label="${esc(code)}">${mi(state.favorites.includes(code) ? 'star' : 'star_border')}</button></div>`).join('');
  const sections = [
    countrySettingsSection(),
    `<section class="settings-section"><div class="title-large">${esc(tr('businessProfile'))}</div><div class="card clickable" onclick="navigate('business')"><div class="list-tile"><div class="list-leading">${mi('business')}</div><div class="list-body"><div class="list-title">${esc(state.business.name || tr('notSet'))}</div><div class="list-sub">${esc([state.business.location, state.business.till].filter(Boolean).join(' · '))}</div></div>${mi('chevron_right')}</div></div></section>`,
    `<section class="settings-section"><div class="title-large">${esc(tr('countingSetup'))}</div><div class="card"><div class="list-tile clickable" onclick="navigate('templates')"><div class="list-leading">${mi('point_of_sale')}</div><div class="list-body"><div class="list-title">${esc(tr('templates'))}</div><div class="list-sub">${esc(tr('templatesHelp'))}</div></div>${mi('chevron_right')}</div><div class="divider"></div><div class="list-tile clickable" onclick="navigate('denoms')"><div class="list-leading">${mi('tune')}</div><div class="list-body"><div class="list-title">${esc(tr('denomSettings'))}</div><div class="list-sub">${esc(tr('denomHelp'))}</div></div>${mi('chevron_right')}</div><div class="divider"></div><div class="list-tile clickable" onclick="navigate('backup')"><div class="list-leading">${mi('enhanced_encryption')}</div><div class="list-body"><div class="list-title">${esc(tr('backup'))}</div><div class="list-sub">${esc(tr('backupHelp'))}</div></div>${mi('chevron_right')}</div></div></section>`,
    `<section class="settings-section"><div class="title-large">${esc(tr('appearance'))}</div><div class="card settings-select"><div class="field"><label>${esc(tr('colourMode'))}</label>${mi('contrast')}<select onchange="setTheme(this.value)"><option value="system" ${state.theme === 'system' ? 'selected' : ''}>${esc(tr('system'))}</option><option value="light" ${state.theme === 'light' ? 'selected' : ''}>${esc(tr('light'))}</option><option value="dark" ${state.theme === 'dark' ? 'selected' : ''}>${esc(tr('dark'))}</option></select></div><div class="sp12"></div><div class="list-tile"><div class="list-leading">${mi('vibration')}</div><div class="list-body"><div class="list-title">${esc(tr('haptics'))}</div><div class="list-sub">${esc(tr('hapticsHelp'))}</div></div><div class="switch ${state.haptics ? 'on' : ''}" role="switch" aria-checked="${state.haptics}" onclick="state.haptics=!state.haptics;persist();render()"></div></div></div></section>`,
    `<section class="settings-section"><div class="title-large">${esc(tr('defaultLanguage'))}</div><div class="card settings-select"><div class="field"><label>${esc(tr('defaultLanguage'))}</label>${mi('language')}<select onchange="setLang(this.value)">${langOptions}</select></div></div></section>`,
    `<section class="settings-section"><div class="title-large">${esc(tr('defaultCurrency'))}</div><div class="card settings-select"><div class="field"><label>${esc(tr('defaultCurrency'))}</label>${mi('currency_exchange')}<select onchange="state.currency=this.value;persist();render()">${currencyOptions}</select></div></div></section>`,
    `<section class="settings-section"><div class="title-large">${esc(tr('supported'))}</div><div class="card">${currencyRows}</div></section>`,
    `<section class="settings-section"><div class="title-large">${esc(tr('privacy'))}</div><div class="card"><div class="list-tile"><div class="list-leading">${mi('delete_outline')}</div><div class="list-body"><div class="list-title">${esc(tr('localOnly'))}</div><div class="list-sub">${esc(tr('localOnlyBody'))}</div></div></div><div class="divider"></div><div class="list-tile clickable" onclick="toggleAppLock()"><div class="list-leading">${mi('lock_outline')}</div><div class="list-body"><div class="list-title">${esc(tr('appLock'))}</div><div class="list-sub">${esc(state.appLock ? tr('appLockOn') : tr('appLockOff'))}</div></div><div class="switch ${state.appLock ? 'on' : ''}"></div></div><div class="divider"></div><div class="list-tile clickable" onclick="toast(tr('privacyOptionsBody'))"><div class="list-leading">${mi('privacy_tip')}</div><div class="list-body"><div class="list-title">${esc(tr('privacyOptions'))}</div><div class="list-sub">${esc(tr('privacyOptionsBody'))}</div></div>${mi('chevron_right')}</div></div></section>`,
  ];
  return layout(`${sections.join('')}<div class="version">${esc(appName())} ${APP_VERSION}</div>`, { appbarHtml: appbar(tr('settings')) });
}

function subpage(title, body) { return `<main class="scaffold">${appbar(title, { back: true })}<div class="scroll">${body}</div><div class="toast" id="toast"></div></main>`; }

function business() {
  const fields = [['businessName', 'business', 'name'], ['registrationId', 'badge', 'registrationId'], ['address', 'place', 'address'], ['location', 'store', 'location'], ['till', 'point_of_sale', 'till'], ['cashier', 'person', 'cashier'], ['manager', 'supervisor_account', 'manager'], ['shift', 'schedule', 'shift']];
  return subpage(tr('businessProfile'), `${fields.map(([key, icon, prop]) => `<div class="field" style="margin-bottom:12px"><label>${esc(tr(key))}</label>${mi(icon)}<input name="business-${esc(prop)}" value="${esc(state.business[prop])}" oninput="state.business['${esc(prop)}']=this.value;persist()"></div>`).join('')}<div class="sp8"></div><button class="filled" type="button" onclick="navigate('settings');toast(tr('saved'))">${mi('check')} ${esc(tr('save'))}</button>`);
}

function templates() {
  const rows = state.templates.length ? state.templates.map((item, index) => `<div class="card list-tile"><div class="list-leading">${mi('point_of_sale')}</div><div class="list-body"><div class="list-title">${esc(item.name)}</div><div class="list-sub">${esc(item.currency)} · ${esc(currencyName(item.currency))} · ${money(item.floatMinor || 0, item.currency)}</div></div><button class="icon-btn" type="button" onclick="state.templates.splice(${index},1);persist();render()" aria-label="${esc(tr('delete'))}">${mi('delete_outline')}</button></div>`).join('') : `<div class="empty">${mi('point_of_sale')}<div>${esc(tr('nothing'))}</div></div>`;
  return subpage(tr('templates'), `${rows}<div class="sp16"></div><button class="filled" type="button" onclick="addTemplate()">${mi('add')} ${esc(tr('add'))}</button>`);
}

function denoms() {
  const code = state.currency;
  const rows = [...currencies[code].notes.map(([valueMinor, label]) => ({ id: `note-${valueMinor}`, kind: 'note', valueMinor, label })), ...currencies[code].coins.map(([valueMinor, label]) => ({ id: `coin-${valueMinor}`, kind: 'coin', valueMinor, label })), ...(state.customDenoms[code] || [])].map(item => `<div class="list-tile"><div class="list-leading">${mi(item.kind === 'coin' ? 'toll' : 'payments')}</div><div class="list-body"><div class="list-title">${esc(item.label)}</div><div class="list-sub">${money(item.valueMinor, code)}</div></div><div class="switch ${!(state.hiddenDenoms[code] || []).includes(item.id) ? 'on' : ''}" onclick="toggleDenom('${esc(item.id)}')"></div></div>`).join('<div class="divider"></div>');
  return subpage(tr('denomSettings'), `<div class="body-small">${esc(code)} · ${esc(currencyName(code))}</div><div class="sp12"></div><div class="card">${rows}</div><div class="sp16"></div><button class="outlined" type="button" onclick="addCustomDenom()">${mi('add')} ${esc(tr('add'))}</button>`);
}

function backup() {
  return subpage(tr('backup'), `<div class="info-banner">${mi('enhanced_encryption')}<div>${esc(tr('backupHelp'))}<div class="body-small">AES-256-GCM · PBKDF2 · pouze lokální preview</div></div></div><div class="sp16"></div><div class="card pad"><button class="outlined" style="width:100%" type="button" onclick="exportBackup()">${mi('download')} ${esc(tr('exportBackup'))}</button><div class="sp12"></div><label class="outlined" style="width:100%;justify-content:center"><input class="file-input" type="file" accept="application/json" onchange="importBackup(this.files[0])">${mi('upload')} ${esc(tr('importBackup'))}</label><div class="sp12"></div><button class="outlined danger" style="width:100%" type="button" onclick="resetDemo()">${mi('restart_alt')} ${esc(tr('reset'))}</button></div>`);
}

function detail() {
  const session = state.sessions.find(item => item.id === state.currentSession);
  if (!session) { state.screen = 'history'; return history(); }
  const fields = [['businessName', session.businessName], ['registrationId', session.registrationId], ['address', session.address], ['location', session.location], ['till', session.till], ['cashier', session.cashier], ['manager', session.manager], ['shift', session.shift]].filter(([, value]) => value);
  const rows = sessionRows(session);
  const pieceTotal = rows.reduce((sum, row) => sum + row.quantity, 0);
  const identity = fields.map(([, value]) => value).filter(Boolean).join(' · ');
  const pos = session.pos ? `<div class="card pad"><div class="title-medium">${esc(tr('posReconciliation'))}</div><div class="body-small">${esc(tr('posSource'))}: ${esc(session.pos.sourceFileName || '')}<br>${esc(tr('posExpected'))}: ${money(session.pos.expectedMinor, session.currency)}${session.pos.cardMinor == null ? '' : `<br>${esc(tr('posCard'))}: ${money(session.pos.cardMinor, session.currency)}`}${session.pos.totalSalesMinor == null ? '' : `<br>${esc(tr('posSales'))}: ${money(session.pos.totalSalesMinor, session.currency)}`}<br>${esc(tr('posHash'))}: ${esc(session.pos.sourceSha256 || '')}</div></div><div class="sp12"></div>` : '';
  const signatures = [['cashierSignature', session.cashierSignature, tr('cashierSignature')], ['managerSignature', session.managerSignature, tr('managerSignature')]].filter(([, data]) => data).map(([, data, label]) => `<div class="signature-preview-wrap"><img class="signature-preview" src="${esc(data)}" alt="${esc(label)}"><div class="body-small">${esc(label)}</div></div>`).join('');
  const expected = session.expectedMinor == null ? '' : `<div class="row"><span class="grow">${esc(tr('expected'))}</span><span>${money(session.expectedMinor, session.currency)}</span></div><div class="row"><span class="grow">${esc(tr('difference'))}</span><strong class="${session.difference < 0 ? 'danger' : ''}">${money(session.difference || 0, session.currency)}</strong></div>`;
  const float = session.floatMinor == null ? '' : `<div class="row"><span class="grow">${esc(tr('float'))}</span><span>${money(session.floatMinor, session.currency)}</span></div><div class="row"><span class="grow">${esc(tr('deposit'))}</span><strong>${money(Math.max(0, session.total - session.floatMinor), session.currency)}</strong></div>`;
  const breakdown = rows.length ? rows.map(row => `<div class="card breakdown-row"><div class="grow"><div class="title-medium">${esc(row.label)}</div><div class="body-small">${esc(tr('pieces', { count: row.quantity }))}${row.weight ? ` · ${esc(row.weight)}` : ''}</div></div><div class="body">${money(row.subtotal, session.currency)}</div></div>`).join('') : `<div class="empty">${mi('payments')}<div>${esc(tr('nothing'))}</div></div>`;
  return subpage(tr('detail'), `<div class="card pad"><div class="headline-small">${money(session.total, session.currency)}</div><div class="body-small">${esc(session.currency)} · ${new Date(session.updatedAt).toLocaleString()} · ${esc(session.mode === 'quick' ? tr('quick') : tr('professional'))}</div><div class="sp12"></div><div class="body-small">${esc(session.documentNumber)}</div>${expected || float ? `<div class="sp12"></div>${expected}${float}` : ''}</div><div class="sp12"></div>${fields.length ? `<div class="card pad"><div class="title-medium">${esc(tr('closing'))}</div>${fields.map(([key, value]) => `<div class="row" style="padding-top:8px"><span class="grow body-small">${esc(tr(key))}</span><span class="body">${esc(value)}</span></div>`).join('')}</div><div class="sp12"></div>` : ''}${pos}<div class="card pad"><div class="row"><div class="grow title-medium">${esc(tr('proofHash'))}</div>${mi('verified')}</div><div class="body-small hash-text">${esc(session.closingHash || '')}</div></div><div class="sp20"></div><div class="title-large">${esc(tr('cashBreakdown'))}</div><div class="sp8"></div>${breakdown}<div class="row summary-row"><span class="grow">${esc(tr('total'))}</span><span>${pieceTotal}</span></div><div class="row summary-row"><span class="grow">${esc(tr('sumOfAmounts'))}</span><strong>${money(session.total, session.currency)}</strong></div>${session.note?.trim() ? `<div class="sp20"></div><div class="title-large">${esc(tr('note'))}</div><div class="sp8"></div><div class="card pad">${esc(session.note)}</div>` : ''}${identity ? `<div class="sp16"></div><div class="body-small">${esc(tr('closingIdentitySentence'))}: ${esc(identity)}</div>` : ''}${signatures ? `<div class="sp20"></div><div class="title-large">${esc(tr('signature'))}</div><div class="sp8"></div><div class="signature-grid">${signatures}</div>` : ''}<div class="sp20"></div><div class="subpage-actions"><button class="filled" type="button" onclick="state.screen='report';state.reportZoom=1;render()">${mi('picture_as_pdf')} ${esc(tr('report'))}</button><button class="outlined" type="button" onclick="editSession('${esc(session.id)}')">${mi('edit')} ${esc(tr('edit'))}</button><button class="outlined" type="button" onclick="downloadCsv('${esc(session.id)}')">${mi('table_view')} ${esc(tr('csv'))}</button><button class="outlined" type="button" onclick="copyText('${esc(session.id)}')">${mi('content_copy')} ${esc(tr('copyFinalText'))}</button><button class="outlined" type="button" onclick="shareText('${esc(session.id)}')">${mi('share')} ${esc(tr('shareFinalText'))}</button></div><div class="sp16"></div><button class="outlined danger" type="button" onclick="deleteSession('${esc(session.id)}')">${mi('delete_outline')} ${esc(tr('delete'))}</button>`);
}

function reportLegacy() {
  const session = state.sessions.find(item => item.id === state.currentSession);
  if (!session) return detail();
  const denomMap = Object.fromEntries((session.denomSnapshot || allDenoms(session.currency)).map(item => [item.id, item]));
  const rows = Object.entries(session.qty).filter(([, quantity]) => Number(quantity)).map(([id, quantity]) => { const item = denomMap[id] || { id, label: id, valueMinor: 0 }; const weight = weightLabel(item, session.currency); return `<tr><td>${esc(item.label)} × ${quantity}${weight ? `<div class="report-meta">${esc(weight)}</div>` : ''}</td><td style="text-align:right">${money(item.valueMinor * quantity, session.currency)}</td></tr>`; }).join('');
  const signature = (data, label) => `<div class="report-signature">${data ? `<img src="${data}" alt="${esc(label)}">` : ''}<div>${esc(label)}</div></div>`;
  const pos = session.pos ? `<h2>${esc(tr('posReconciliation'))}</h2><div class="report-meta">${esc(tr('posSource'))}: ${esc(session.pos.sourceFileName)}<br>${esc(tr('posExpected'))}: ${money(session.pos.expectedMinor, session.currency)}${session.pos.cardMinor == null ? '' : `<br>${esc(tr('posCard'))}: ${money(session.pos.cardMinor, session.currency)}`}${session.pos.totalSalesMinor == null ? '' : `<br>${esc(tr('posSales'))}: ${money(session.pos.totalSalesMinor, session.currency)}`}<br>${esc(tr('posHash'))}: ${esc(session.pos.sourceSha256 || '')}</div>` : '';
  const identity = [session.businessName, session.registrationId, session.address, session.location, session.till, session.cashier, session.manager, session.shift].filter(Boolean).join(' · ');
  return `<main class="scaffold">${appbar(tr('report'), { back: true })}<div class="scroll"><div class="report-toolbar"><button class="outlined" type="button" onclick="state.reportZoom=Math.max(.8,state.reportZoom-.1);render()">${mi('zoom_out')} ${esc(tr('zoomOut'))}</button><span class="zoom-label">${esc(tr('pdfZoom'))}: ${Math.round(state.reportZoom * 100)}%</span><button class="outlined" type="button" onclick="state.reportZoom=Math.min(1.5,state.reportZoom+.1);render()">${mi('zoom_in')} ${esc(tr('zoomIn'))}</button><button class="text-btn" type="button" onclick="state.reportZoom=1;render()">${esc(tr('resetZoom'))}</button></div><div class="sp12"></div><article class="report-paper" style="transform:scale(${state.reportZoom})"><h1>${esc(session.closingTitle || tr('app'))}</h1><div class="report-meta">${esc(tr('total'))} · ${esc(session.currency)} · ${new Date(session.updatedAt).toLocaleString()}<br>${identity ? esc(identity) : esc(tr('notSet'))}</div><h2>${esc(tr('banknotes'))} / ${esc(tr('coins'))}</h2><table>${rows || `<tr><td>${esc(tr('nothing'))}</td><td></td></tr>`}</table><div class="report-total"><span>${esc(tr('total'))}</span><span style="float:right">${money(session.total, session.currency)}</span></div>${session.expectedMinor == null ? '' : `<div style="margin-top:8px">${esc(tr('expected'))}: <strong>${money(session.expectedMinor, session.currency)}</strong><br>${esc(tr('difference'))}: <strong class="${session.difference < 0 ? 'danger' : ''}">${money(session.difference || 0, session.currency)}</strong></div>`}${session.floatMinor == null ? '' : `<div style="margin-top:8px">${esc(tr('float'))}: <strong>${money(session.floatMinor, session.currency)}</strong></div>`}${pos}<h2>${esc(tr('proofHash'))}</h2><div class="report-meta" style="word-break:break-all">${esc(session.closingHash || '')}</div><div class="sp16"></div><div class="report-signatures">${signature(session.cashierSignature, tr('cashierSignature'))}${signature(session.managerSignature, tr('managerSignature'))}</div></article><div class="sp16"></div><div class="subpage-actions"><button class="filled" type="button" onclick="window.print()">${mi('print')} ${esc(tr('pdfPrint'))}</button><button class="outlined" type="button" onclick="window.print()">${mi('download')} ${esc(tr('downloadPdf'))}</button><button class="outlined" type="button" onclick="downloadCsv('${esc(session.id)}')">${mi('table_view')} ${esc(tr('csv'))}</button><button class="outlined" type="button" onclick="shareCsv('${esc(session.id)}')">${mi('share')} ${esc(tr('shareCsv'))}</button><button class="outlined" type="button" onclick="copyText('${esc(session.id)}')">${mi('content_copy')} ${esc(tr('copyFinalText'))}</button><button class="outlined" type="button" onclick="shareText('${esc(session.id)}')">${mi('share')} ${esc(tr('shareFinalText'))}</button></div></div><div class="toast" id="toast"></div></main>`;
}

function report() {
  const session = state.sessions.find(item => item.id === state.currentSession);
  if (!session) return detail();
  const denomMap = Object.fromEntries((session.denomSnapshot || allDenoms(session.currency)).map(item => [item.id, item]));
  const rows = Object.entries(session.qty).filter(([, quantity]) => Number(quantity)).map(([id, quantity]) => {
    const item = denomMap[id] || { id, label: id, valueMinor: 0 };
    return { label: item.label, quantity: Number(quantity), subtotal: item.valueMinor * Number(quantity) };
  });
  const identity = [session.businessName, session.registrationId, session.address, session.location, session.till, session.cashier, session.manager, session.shift].filter(Boolean).join(' · ');
  const created = new Date(session.createdAt || session.updatedAt).toLocaleString();
  const updated = new Date(session.updatedAt).toLocaleString();
  const rowHtml = rows.map(row => `<tr><td>${esc(row.label)}</td><td>${row.quantity}</td><td>${money(row.subtotal, session.currency)}</td></tr>`).join('');
  const signHtml = [['cashierSignature', session.cashierSignature, tr('cashierSignature')], ['managerSignature', session.managerSignature, tr('managerSignature')]].map(([, data, label]) => `<div class="report-signature"><div class="report-signature-box">${data ? `<img src="${esc(data)}" alt="${esc(label)}">` : `<span>${esc(tr('signatureMissing'))}</span>`}</div><div>${esc(label)}</div></div>`).join('');
  const expected = session.expectedMinor == null ? '' : `<div class="report-info-row"><span>${esc(tr('expected'))}</span><strong>${money(session.expectedMinor, session.currency)}</strong></div><div class="report-info-row"><span>${esc(tr('difference'))}</span><strong>${money(session.difference || 0, session.currency)}</strong></div>`;
  const pos = session.pos ? `<h2 class="report-section-title">${esc(tr('posReconciliation'))}</h2><div class="report-info-grid"><div class="report-info-label">${esc(tr('posSource'))}</div><div>${esc(session.pos.sourceFileName || '')}</div><div class="report-info-label">${esc(tr('posExpected'))}</div><div>${money(session.pos.expectedMinor, session.currency)}</div>${session.pos.cardMinor == null ? '' : `<div class="report-info-label">${esc(tr('posCard'))}</div><div>${money(session.pos.cardMinor, session.currency)}</div>`}${session.pos.totalSalesMinor == null ? '' : `<div class="report-info-label">${esc(tr('posSales'))}</div><div>${money(session.pos.totalSalesMinor, session.currency)}</div>`}<div class="report-info-label">${esc(tr('posHash'))}</div><div class="report-hash">${esc(session.pos.sourceSha256 || '')}</div></div>` : '';
  return `<main class="scaffold">${appbar(tr('report'), { back: true })}<div class="scroll report-scroll"><div class="report-toolbar"><button class="outlined" type="button" onclick="state.reportZoom=Math.max(.8,state.reportZoom-.1);render()">${mi('zoom_out')} ${esc(tr('zoomOut'))}</button><span class="zoom-label">${esc(tr('pdfZoom'))}: ${Math.round(state.reportZoom * 100)}%</span><button class="outlined" type="button" onclick="state.reportZoom=Math.min(1.5,state.reportZoom+.1);render()">${mi('zoom_in')} ${esc(tr('zoomIn'))}</button><button class="text-btn" type="button" onclick="state.reportZoom=1;render()">${esc(tr('resetZoom'))}</button></div><div class="sp12"></div><article class="report-paper report-paper-parity" style="transform:scale(${state.reportZoom})"><header class="report-header"><img class="report-logo" src="./assets/aardvarkland-mark.png" alt=""><div><h1>${esc(BRAND_NAME)}</h1><div class="report-meta">${esc(session.documentNumber || '')}</div></div></header><h2 class="report-section-title">${esc(tr('closing'))}</h2><div class="report-info-grid"><div class="report-info-label">${esc(tr('closing'))}</div><div>${esc(created)}</div><div class="report-info-label">${esc(tr('detail'))}</div><div>${esc(updated)}</div><div class="report-info-label">${esc(tr('currency'))}</div><div>${esc(session.currency)}</div><div class="report-info-label">${esc(tr('proofHash'))}</div><div class="report-hash">${esc(session.closingHash || '')}</div></div><h2 class="report-section-title">${esc(tr('cashCheck'))}</h2><div class="report-info-grid"><div class="report-info-label">${esc(tr('total'))}</div><div>${money(session.total, session.currency)}</div>${expected}</div>${pos}<h2 class="report-section-title">${esc(tr('cashBreakdown'))}</h2><table class="report-table"><thead><tr><th>${esc(tr('banknotes'))}</th><th>${esc(tr('count'))}</th><th>${esc(tr('sumOfAmounts'))}</th></tr></thead><tbody>${rowHtml || `<tr><td colspan="3">${esc(tr('nothing'))}</td></tr>`}</tbody><tfoot><tr><td>${esc(tr('total'))}</td><td>${rows.reduce((sum, row) => sum + row.quantity, 0)}</td><td>${money(session.total, session.currency)}</td></tr></tbody></table>${identity ? `<div class="report-identity">${esc(tr('closingIdentitySentence'))}: ${esc(identity)}</div>` : ''}<div class="report-signatures">${signHtml}</div><div class="report-footer"><span>${esc(session.documentNumber || '')}</span><span>1 / 1</span></div></article><div class="sp16"></div><div class="subpage-actions"><button class="filled" type="button" onclick="window.print()">${mi('print')} ${esc(tr('pdfPrint'))}</button><button class="filled" type="button" onclick="window.print()">${mi('download')} ${esc(tr('downloadPdf'))}</button><button class="outlined" type="button" onclick="downloadCsv('${esc(session.id)}')">${mi('table_view')} ${esc(tr('csv'))}</button><button class="outlined" type="button" onclick="shareCsv('${esc(session.id)}')">${mi('share')} ${esc(tr('shareCsv'))}</button><button class="outlined" type="button" onclick="copyText('${esc(session.id)}')">${mi('content_copy')} ${esc(tr('copyFinalText'))}</button><button class="outlined" type="button" onclick="shareText('${esc(session.id)}')">${mi('share')} ${esc(tr('shareFinalText'))}</button></div></div><div class="toast" id="toast"></div></main>`;
}

function signatureScreen() {
  const target = state.currentSignatureTarget;
  if (!state.draft || !target) { state.screen = 'count'; return countScreen(); }
  const title = target === 'cashierSignature' ? tr('cashierSignature') : tr('managerSignature');
  return subpage(title, `<div class="signature-wrap"><div class="body">${esc(tr('signatureHelp'))}</div><canvas class="signature-pad" id="signature-pad" aria-label="${esc(title)}"></canvas><div class="signature-actions"><button class="outlined" type="button" onclick="clearSignature()">${mi('delete_sweep')} ${esc(tr('clearSignature'))}</button><button class="filled" type="button" onclick="saveSignature()">${mi('check')} ${esc(tr('saveSignature'))}</button></div><div class="body-small">${esc(tr('previewOnly'))}</div></div>`);
}

function lockScreen() {
  return `<main class="scaffold"><div class="lock-screen"><div><div class="lock-icon">${mi('lock')}</div><div class="title-large">${esc(tr('appLock'))}</div><div class="sp8"></div><div class="body-small">${esc(tr('localOnlyBody'))}</div><div class="sp20"></div><button class="filled" type="button" onclick="unlockApp()">${mi('lock_open')} ${esc(tr('unlock'))}</button></div></div><div class="toast" id="toast"></div></main>`;
}

function render() {
  document.title = appName();
  applyTheme();
  if (!state.locked) persist();
  let html;
  if (state.locked) html = lockScreen();
  else if (!state.country) html = countryPicker();
  else switch (state.screen) {
    case 'dashboard': html = dashboard(); break;
    case 'history': html = history(); break;
    case 'settings': html = settings(); break;
    case 'count': html = countScreen(); break;
    case 'business': html = business(); break;
    case 'templates': html = templates(); break;
    case 'denoms': html = denoms(); break;
    case 'backup': html = backup(); break;
    case 'detail': html = detail(); break;
    case 'report': html = report(); break;
    case 'signature': html = signatureScreen(); break;
    default: state.screen = 'dashboard'; html = dashboard();
  }
  if (state.screen === 'report') html = html.replace(`<h1>${esc(BRAND_NAME)}</h1>`, `<h1>${esc(appName())}</h1>`);
  $('root').innerHTML = html;
  document.body.dataset.ready = 'true';
  if (state.screen === 'signature' && !state.locked) bindSignaturePad();
}

function selectCountry(id) {
  const item = countryById[id];
  if (!item) return;
  state.country = item.id;
  state.countryView = 'top';
  state.lang = window.cashTallyLocales?.countryLocales?.[item.id] || state.lang || 'en';
  state.currency = currencies[item.currency] ? item.currency : 'EUR';
  state.screen = 'dashboard';
  persist();
  render();
}

function changeCountry() {
  state.country = '';
  state.countryView = 'top';
  state.screen = 'dashboard';
  persist();
  render();
}

function navigate(screen) { state.screen = screen; state.modal = null; persist(); render(); }
function goBack() {
  if (state.screen === 'signature') { state.screen = 'count'; state.currentSignatureTarget = null; state.signatureStrokes = []; }
  else if (['business', 'templates', 'denoms', 'backup'].includes(state.screen)) state.screen = 'settings';
  else if (state.screen === 'detail' || state.screen === 'report') state.screen = 'history';
  else state.screen = 'dashboard';
  persist(); render();
}
function toggleFavorite(code) { state.favorites = state.favorites.includes(code) ? state.favorites.filter(item => item !== code) : [...state.favorites, code]; persist(); render(); }
function changeQty(id, delta) { if (!state.draft || state.draft.quantitiesLocked) return; const quantity = Math.max(0, Number(state.draft.qty[id] || 0) + Number(delta)); if (quantity) state.draft.qty[id] = quantity; else delete state.draft.qty[id]; persist(); render(); if (state.haptics && navigator.vibrate) navigator.vibrate(8); }
function editQty(id) { if (!state.draft || state.draft.quantitiesLocked) return; const value = prompt('Quantity', state.draft.qty[id] || 0); if (value !== null && /^\d+$/.test(value)) { state.draft.qty[id] = Math.max(0, Number(value)); persist(); render(); } }
function clearKind(kind) { if (!state.draft || state.draft.quantitiesLocked) return; allDenoms(state.draft.currency).filter(item => kind === 'notes' ? item.kind === 'note' || item.kind === 'custom' : item.kind === 'coin').forEach(item => delete state.draft.qty[item.id]); persist(); render(); }
function changeDraftCurrency(code) { if (!state.draft || state.draft.quantitiesLocked) return; state.draft.currency = code; state.draft.qty = {}; state.draft.expected = ''; state.draft.float = ''; state.draft.pos = null; state.currency = code; persist(); render(); }
function dToggleBlind() { if (!state.draft || state.draft.quantitiesLocked) return; state.draft.blind = !state.draft.blind; persist(); render(); }
function finishBlindCount() { if (!state.draft) return; if (!confirm(tr('finishBlindHelp'))) return; state.draft.quantitiesLocked = true; state.draft.blindLockedAt = new Date().toISOString(); persist(); render(); }

async function sha256Hex(value) {
  if (crypto?.subtle) {
    const bytes = new TextEncoder().encode(String(value));
    const digest = await crypto.subtle.digest('SHA-256', bytes);
    return [...new Uint8Array(digest)].map(byte => byte.toString(16).padStart(2, '0')).join('');
  }
  let hash = 2166136261;
  for (const char of String(value)) hash = Math.imul(hash ^ char.charCodeAt(0), 16777619);
  return `fallback-${(hash >>> 0).toString(16)}`;
}

async function saveCount() {
  const d = state.draft;
  if (!d || (d.blind && !d.quantitiesLocked)) { toast(tr('finishBlind')); return; }
  const total = draftTotal();
  const expectedMinor = d.mode === 'professional' ? parseMinor(d.expected, d.currency) : null;
  const differenceMinor = expectedMinor == null ? null : total - expectedMinor;
  const now = new Date().toISOString();
  const session = { id: d.editSessionId || `s${Date.now()}`, documentNumber: d.documentNumber, currency: d.currency, mode: d.mode, blind: d.blind, blindLockedAt: d.blindLockedAt || null, qty: Object.assign({}, d.qty), denomSnapshot: allDenoms(d.currency), total, expectedMinor, floatMinor: parseMinor(d.float, d.currency), difference: differenceMinor, note: d.note, closingTitle: d.closingTitle, businessName: d.businessName, registrationId: d.registrationId, address: d.address, location: d.location, till: d.till, cashier: d.cashier, manager: d.manager, shift: d.shift, cashierSignature: d.cashierSignature, managerSignature: d.managerSignature, pos: d.pos, createdAt: d.createdAt || now, updatedAt: now };
  session.closingHash = await sha256Hex(JSON.stringify(session));
  const existingIndex = d.editSessionId ? state.sessions.findIndex(item => item.id === d.editSessionId) : -1;
  if (existingIndex >= 0) state.sessions.splice(existingIndex, 1, session); else state.sessions.unshift(session);
  state.currentSession = session.id; state.draft = null; state.screen = 'dashboard'; persist(); render(); setTimeout(() => toast(tr('saved')), 0);
}

function openSession(id) { state.currentSession = id; state.screen = 'detail'; persist(); render(); }
function editSession(id) {
  const session = reportSession(id);
  if (!session) return;
  state.currentSession = null;
  state.closingOpen = session.mode === 'professional';
  state.screen = 'count';
  state.draft = { id: `d${Date.now()}`, editSessionId: session.id, createdAt: session.createdAt, documentNumber: session.documentNumber, mode: session.mode, currency: session.currency, step: 1, blind: Boolean(session.blind), quantitiesLocked: false, qty: Object.assign({}, session.qty || {}), expected: inputMoney(session.expectedMinor, session.currency), float: inputMoney(session.floatMinor, session.currency), note: session.note || '', closingTitle: session.closingTitle || '', businessName: session.businessName || '', registrationId: session.registrationId || '', address: session.address || '', location: session.location || '', till: session.till || '', cashier: session.cashier || '', manager: session.manager || '', shift: session.shift || '', cashierSignature: session.cashierSignature || '', managerSignature: session.managerSignature || '', pos: session.pos || null };
  persist(); render();
}
function deleteSession(id) { state.sessions = state.sessions.filter(item => item.id !== id); state.currentSession = null; state.screen = 'history'; persist(); render(); setTimeout(() => toast(tr('deleted')), 0); }
function clearFilters() { Object.assign(state, { search: '', filterCurrency: '', differencesOnly: false, dateFrom: '', dateTo: '', showDateRange: false }); persist(); render(); }
function setTheme(value) { state.theme = value; persist(); render(); }
function setLang(value) {
  if (!(window.cashTallyLocales?.codes || ['cs', 'en']).includes(value)) return;
  state.lang = value;
  persist();
  render();
}
function addTemplate() { const name = prompt(tr('templates'), state.lang === 'cs' ? 'Hlavní pokladna' : 'Main till'); if (!name) return; const amount = prompt(tr('float'), '2000'); const location = prompt(tr('location'), state.business.location || ''); state.templates.push({ id: `t${Date.now()}`, name, currency: state.currency, floatMinor: parseMinor(amount, state.currency) || 0, location: location || '', till: state.business.till || '', quantities: {} }); persist(); render(); }
function toggleDenom(id) { const code = state.currency; const hidden = new Set(state.hiddenDenoms[code] || []); if (hidden.has(id)) hidden.delete(id); else hidden.add(id); state.hiddenDenoms[code] = [...hidden]; persist(); render(); }
function addCustomDenom() { const label = prompt(tr('denomSettings'), state.lang === 'cs' ? 'Vlastní nominál' : 'Custom denomination'); if (!label) return; const value = parseMinor(prompt(tr('total'), '25'), state.currency); if (value == null || value <= 0) return; const item = { id: `custom-${Date.now()}`, kind: 'custom', valueMinor: value, label }; state.customDenoms[state.currency] = [...(state.customDenoms[state.currency] || []), item]; persist(); render(); }
function importPosDemo() { importPosText('expected_cash;card_total;total_sales\n18000;4200;22200', 'demo-pos.csv'); }
function parsePosText(text) { const code = state.draft?.currency || state.currency; const lines = text.split(/\r?\n/).map(line => line.trim()).filter(Boolean); let expectedMinor = null, cardMinor = null, totalSalesMinor = null; if (lines.length >= 2) { const separator = lines[0].includes(';') ? ';' : ','; const headers = lines[0].split(separator).map(value => value.trim().toLowerCase()); const values = lines[1].split(separator).map(value => value.trim()); headers.forEach((header, index) => { const number = parseMinor(values[index], code); if (number == null) return; if (/expected|oček|cash|hotov/.test(header)) expectedMinor = number; else if (/card|kart/.test(header)) cardMinor = number; else if (/sales|trž|total/.test(header)) totalSalesMinor = number; }); } for (const line of lines) { const lower = line.toLowerCase(); const numberMatch = line.match(/-?\d[\d\s.,]*/); if (!numberMatch) continue; const number = parseMinor(numberMatch[0], code); if (number == null) continue; if (/expected|oček|cash|hotov/.test(lower) && expectedMinor == null) expectedMinor = number; else if (/card|kart/.test(lower) && cardMinor == null) cardMinor = number; else if (/sales|trž|total/.test(lower) && totalSalesMinor == null) totalSalesMinor = number; } return { expectedMinor: expectedMinor ?? (18000 * (10 ** currencyFractionDigits(code))), cardMinor, totalSalesMinor }; }
async function importPosText(text, fileName) { if (!state.draft) return; const parsed = parsePosText(text); const sourceSha256 = await sha256Hex(text); state.draft.expected = inputMoney(parsed.expectedMinor, state.draft.currency); state.draft.pos = { sourceFileName: fileName, expectedMinor: parsed.expectedMinor, cardMinor: parsed.cardMinor, totalSalesMinor: parsed.totalSalesMinor, sourceSha256 }; persist(); render(); setTimeout(() => toast(tr('saved')), 0); }
function importPosFile(file) { if (!file) return; const reader = new FileReader(); reader.onload = () => importPosText(String(reader.result || ''), file.name); reader.readAsText(file); }

function openSignature(target) { if (!state.draft || state.draft.quantitiesLocked) return; state.currentSignatureTarget = target; state.signatureStrokes = []; state.screen = 'signature'; persist(); render(); }
function bindSignaturePad() { const canvas = $('signature-pad'); if (!canvas) return; const ratio = Math.max(1, window.devicePixelRatio || 1); const cssWidth = canvas.clientWidth || 320; const cssHeight = canvas.clientHeight || 180; canvas.width = cssWidth * ratio; canvas.height = cssHeight * ratio; const context = canvas.getContext('2d'); context.scale(ratio, ratio); context.lineWidth = 2.4; context.lineCap = 'round'; context.lineJoin = 'round'; context.strokeStyle = '#101412'; const draw = () => { context.clearRect(0, 0, cssWidth, cssHeight); for (const stroke of state.signatureStrokes) { context.beginPath(); stroke.forEach((point, index) => index ? context.lineTo(point.x, point.y) : context.moveTo(point.x, point.y)); context.stroke(); } }; draw(); let active = null; canvas.addEventListener('pointerdown', event => { event.preventDefault(); const rect = canvas.getBoundingClientRect(); active = []; state.signatureStrokes.push(active); active.push({ x: event.clientX - rect.left, y: event.clientY - rect.top }); canvas.setPointerCapture(event.pointerId); draw(); }); canvas.addEventListener('pointermove', event => { if (!active) return; const rect = canvas.getBoundingClientRect(); active.push({ x: event.clientX - rect.left, y: event.clientY - rect.top }); draw(); }); canvas.addEventListener('pointerup', () => { active = null; }); canvas.addEventListener('pointercancel', () => { active = null; }); }
function clearSignature() { state.signatureStrokes = []; bindSignaturePad(); }
function saveSignature() { const canvas = $('signature-pad'); if (!canvas || !state.draft || !state.currentSignatureTarget) return; if (!state.signatureStrokes.some(stroke => stroke.length > 1)) { toast(tr('signatureMissing')); return; } state.draft[state.currentSignatureTarget] = canvas.toDataURL('image/png'); state.currentSignatureTarget = null; state.signatureStrokes = []; state.screen = 'count'; persist(); render(); }

function downloadBlob(name, content, type) { const url = URL.createObjectURL(new Blob([content], { type })); const anchor = document.createElement('a'); anchor.href = url; anchor.download = name; anchor.rel = 'noopener'; document.body.append(anchor); anchor.click(); anchor.remove(); setTimeout(() => URL.revokeObjectURL(url), 1000); }
function reportSession(id) { return state.sessions.find(item => item.id === id); }
function sessionRows(session) { const map = Object.fromEntries((session.denomSnapshot || allDenoms(session.currency)).map(item => [item.id, item])); return Object.entries(session.qty).filter(([, quantity]) => Number(quantity)).map(([id, quantity]) => { const item = map[id] || { id, label: id, valueMinor: 0 }; return { label: item.label, quantity: Number(quantity), subtotal: item.valueMinor * Number(quantity), weight: weightLabel(item, session.currency) }; }); }
function downloadCsv(id) { const session = reportSession(id); if (!session) return; const scale = 10 ** currencyFractionDigits(session.currency); const rows = [['Denomination', 'Quantity', 'Subtotal'], ...sessionRows(session).map(row => [row.label, row.quantity, row.subtotal / scale]), ['Total', '', session.total / scale]]; downloadBlob('cashtally-closing.csv', rows.map(row => row.map(value => `"${String(value).replaceAll('"', '""')}"`).join(',')).join('\n'), 'text/csv;charset=utf-8'); }
function plainTextFor(session) { const lines = [tr('app'), session.closingTitle || tr('report'), `${tr('currency')}: ${session.currency}`, `${tr('total')}: ${money(session.total, session.currency)}`]; if (session.documentNumber) lines.push(session.documentNumber); sessionRows(session).forEach(row => lines.push(`${row.label} × ${row.quantity}${row.weight ? ` · ${row.weight}` : ''} = ${money(row.subtotal, session.currency)}`)); if (session.expectedMinor != null) lines.push(`${tr('expected')}: ${money(session.expectedMinor, session.currency)}`, `${tr('difference')}: ${money(session.difference || 0, session.currency)}`); if (session.floatMinor != null) lines.push(`${tr('float')}: ${money(session.floatMinor, session.currency)}`); if (session.pos) lines.push(`${tr('posReconciliation')}: ${session.pos.sourceFileName}`, `${tr('posHash')}: ${session.pos.sourceSha256}`); lines.push(`${tr('proofHash')}: ${session.closingHash || ''}`); return lines.join('\n'); }
function downloadText(id) { const session = reportSession(id); if (!session) return; downloadBlob('cashtally-closing.txt', plainTextFor(session), 'text/plain;charset=utf-8'); }
async function copyText(id) { const session = reportSession(id); if (!session) return; const text = plainTextFor(session); try { if (!navigator.clipboard?.writeText) throw new Error('clipboard-unavailable'); await navigator.clipboard.writeText(text); toast(tr('finalTextCopied')); } catch { downloadBlob('cashtally-closing.txt', text, 'text/plain;charset=utf-8'); toast(tr('text')); } }
async function shareText(id) { const session = reportSession(id); if (!session) return; const text = plainTextFor(session); if (navigator.share) { try { await navigator.share({ title: tr('report'), text }); return; } catch (error) { if (error?.name === 'AbortError') return; } } await copyText(id); }
async function shareCsv(id) { const session = reportSession(id); if (!session) return; const scale = 10 ** currencyFractionDigits(session.currency); const rows = [['Denomination', 'Quantity', 'Subtotal'], ...sessionRows(session).map(row => [row.label, row.quantity, row.subtotal / scale]), ['Total', '', session.total / scale]]; const csv = rows.map(row => row.map(value => `"${String(value).replaceAll('"', '""')}"`).join(',')).join('\n'); const file = new File([csv], 'cashtally-closing.csv', { type: 'text/csv' }); if (navigator.share && navigator.canShare?.({ files: [file] })) { try { await navigator.share({ title: tr('report'), files: [file] }); return; } catch (error) { if (error?.name === 'AbortError') return; } } downloadBlob(file.name, csv, file.type); }

async function deriveKey(password, salt) { const material = await crypto.subtle.importKey('raw', new TextEncoder().encode(password), 'PBKDF2', false, ['deriveKey']); return crypto.subtle.deriveKey({ name: 'PBKDF2', salt, iterations: 210000, hash: 'SHA-256' }, material, { name: 'AES-GCM', length: 256 }, false, ['encrypt', 'decrypt']); }
function bytesToBase64(bytes) { let binary = ''; bytes.forEach(byte => { binary += String.fromCharCode(byte); }); return btoa(binary); }
function base64ToBytes(value) { const binary = atob(value); return Uint8Array.from(binary, char => char.charCodeAt(0)); }
async function exportBackup() { const password = prompt(state.lang === 'cs' ? 'Heslo pro šifrovanou zálohu' : 'Password for encrypted backup'); if (!password) return; if (!crypto?.subtle) { downloadBlob('cashtally-preview-backup.json', JSON.stringify(state, null, 2), 'application/json'); toast(tr('exportBackup')); return; } const salt = crypto.getRandomValues(new Uint8Array(16)); const iv = crypto.getRandomValues(new Uint8Array(12)); const key = await deriveKey(password, salt); const cipher = await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, key, new TextEncoder().encode(JSON.stringify(Object.assign({}, state, { modal: null, locked: false })))); downloadBlob('cashtally-preview-backup.json', JSON.stringify({ version: 1, algorithm: 'AES-256-GCM', iterations: 210000, salt: bytesToBase64(salt), iv: bytesToBase64(iv), data: bytesToBase64(new Uint8Array(cipher)) }, null, 2), 'application/json'); toast(tr('exportBackup')); }
async function importBackup(file) { if (!file) return; try { const payload = JSON.parse(await file.text()); let imported = payload; if (payload.algorithm === 'AES-256-GCM') { const password = prompt(state.lang === 'cs' ? 'Heslo pro obnovu zálohy' : 'Backup password'); if (!password) return; const key = await deriveKey(password, base64ToBytes(payload.salt)); const plain = await crypto.subtle.decrypt({ name: 'AES-GCM', iv: base64ToBytes(payload.iv) }, key, base64ToBytes(payload.data)); imported = JSON.parse(new TextDecoder().decode(plain)); } state = Object.assign(baseState(), imported, { business: Object.assign(baseState().business, imported.business || {}) }); state.screen = 'dashboard'; state.modal = null; persist(); render(); toast(tr('saved')); } catch { toast(state.lang === 'cs' ? 'Záloha je neplatná nebo má špatné heslo.' : 'Backup is invalid or the password is wrong.'); } }
function resetDemo() { if (!confirm(`${tr('reset')}?`)) return; state = baseState(); sessionStorage.removeItem('cashtally-preview-unlocked'); persist(); render(); }
async function toggleAppLock() { if (state.appLock) { state.appLock = false; state.locked = false; state.lockPinHash = ''; sessionStorage.setItem('cashtally-preview-unlocked', '1'); persist(); render(); return; } const pin = prompt(tr('appLockReason')); if (!pin || !/^\d{4,}$/.test(pin)) { toast(tr('wrongPin')); return; } state.lockPinHash = await sha256Hex(pin); state.appLock = true; state.locked = false; sessionStorage.setItem('cashtally-preview-unlocked', '1'); persist(); render(); }
async function unlockApp() { const pin = prompt(tr('appLockReason')); if (!pin) return; if (await sha256Hex(pin) !== state.lockPinHash) { toast(tr('wrongPin')); return; } state.locked = false; sessionStorage.setItem('cashtally-preview-unlocked', '1'); render(); }
function renderSoft() { const active = document.activeElement; const name = active?.name; const position = active?.selectionStart; render(); if (name) { const next = document.querySelector(`[name="${name}"]`); next?.focus(); if (position != null) next?.setSelectionRange(position, position); } }
function renderSoftHistory() { persist(); const list = $('history-list'); if (!list) return; const rows = filteredSessions(); list.innerHTML = rows.length ? rows.map(session => `<div class="card history-card clickable" onclick="openSession('${esc(session.id)}')"><div class="grow"><div class="title-large">${money(session.total, session.currency)}</div><div class="body-small">${esc(session.currency)} · ${new Date(session.updatedAt).toLocaleString()}</div></div>${mi('chevron_right')}</div>`).join('') : `<div class="empty">${mi('history')}<div>${esc(tr('historyEmpty'))}</div></div>`; }
function toast(message) { const element = $('toast'); if (!element) return; element.textContent = message; element.classList.add('show'); clearTimeout(window.__toastTimer); window.__toastTimer = setTimeout(() => element.classList.remove('show'), 1800); }

if ('serviceWorker' in navigator) navigator.serviceWorker.register('./sw.js').catch(() => {});
render();
