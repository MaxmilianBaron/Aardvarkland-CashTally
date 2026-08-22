(function () {
  const script = document.currentScript;
  const assetRoot = new URL('./assets/', script && script.src ? script.src : location.href);
  const flagIds = new Set([
    'EU', 'IN', 'US', 'ID', 'PK', 'NG', 'BR', 'RU', 'MX', 'JP', 'EG', 'TR', 'TH', 'GB', 'ZA', 'KR', 'DZ', 'AR',
    'CA', 'UA', 'PL', 'MY', 'SA', 'AU', 'AE', 'CZ', 'SE', 'IL', 'HU', 'CH', 'DK', 'NO', 'DE', 'FR', 'IT', 'ES',
    'NL', 'BE', 'AT', 'BG', 'PT', 'GR', 'FI', 'IE', 'SK', 'HR', 'LT', 'SI', 'LV', 'EE', 'CY', 'LU', 'MT',
  ]);
  const assetUrl = path => new URL(path, assetRoot).href;
  const flagUrl = id => assetUrl(`flags/${(flagIds.has(id) ? id : 'EU').toLowerCase()}.svg`);

  window.cashTallyFlagSvg = id => `<img class="flag-icon" src="${flagUrl(String(id || '').toUpperCase())}" alt="" aria-hidden="true" draggable="false">`;
  window.cashTallyLogoSvg = () => `<img class="country-logo-image" src="${assetUrl('aardvarkland-mark.png')}" alt="" aria-hidden="true" draggable="false">`;
}());
