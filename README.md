# Aardvarkland Cash Tally

Offline cash counting and till-closing application for Android.

[Interactive mobile preview](https://maxmilianbaron.github.io/Aardvarkland-CashTally/)

## Features

- denomination-based banknote and coin counting
- quick count and professional till closing
- all 32 supported currencies with configurable denominations
- denomination weights where official or issuer figures are available
- till templates and favourite currencies
- blind count, expected cash, cash float and difference calculation
- POS report import
- closing history and saved closing details
- PDF and CSV closing reports
- SHA-256 report fingerprint
- cashier and manager signature capture
- encrypted backup and restore
- local App Lock
- light and dark themes
- country-first start screen with embedded flag icons, local country names and Eurozone drilldown
- 36 interface languages
- offline-first local data storage
- one complete version with no advertising, subscriptions, trials or in-app purchases

## Preview

Interactive browser preview with demo data. Mobile viewport: `390 × 844`.
The first-run country picker is rendered inside the phone frame from the first
page load; it is part of the standalone app and the mobile iframe itself. It
follows the canonical currency order: 32 top-level cards
including Eurozone and all 21 euro-area members. Flags are embedded SVG icons,
so the browser does not turn them into country-code text when an emoji font is
unavailable.

The preview mirrors the Android flow locally: quick/professional count, blind
count, POS reconciliation, signatures, history/detail, report zoom and
browser PDF/print, CSV/text export, encrypted backup, App Lock and settings
toggles. It includes all 36 interface languages from the product catalog
source, switches to the matching language after country selection, and keeps
the real app logo, local Material icons and local SVG flag assets in the
  mobile frame. The browser preview exposes the complete 32-currency catalog,
  including its full denomination sets and zero-decimal currencies
  such as JPY, KRW, HUF and IDR. Browser data is local demo data and the
  complete feature set is available without advertising or purchase flows.

## License

Proprietary. All rights reserved. See [LICENSE](LICENSE).
