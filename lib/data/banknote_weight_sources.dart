abstract final class BanknoteWeightSources {
  static const String euroOenb = 'oenb_euro_banknotes';
  static const String usdCurrencyEducation = 'uscurrency_currency_facts';
  static const String gbpBankOfEngland = 'boe_polymer_business_qa';
  static const String cadBankOfCanadaBundle = 'boc_polymer_lca_100_notes';
  static const String jpyBankOfJapan = 'boj_banknote_faq_c15';
  static const String czkCnbBundle = 'cnb_1000_czk_1000_notes';
  static const String hufMnb = 'mnb_banknote_facts';

  static const Map<String, String> officialUris = <String, String>{
    euroOenb: 'https://www.oenb.at/en/the-euro/cash-management/banknotes.html',
    usdCurrencyEducation: 'https://www.uscurrency.gov/about-us/currency-facts',
    gbpBankOfEngland:
        'https://www.bankofengland.co.uk/-/media/boe/files/banknotes/polymer/polymer-qanda-for-businesses.pdf',
    cadBankOfCanadaBundle:
        'https://www.bankofcanada.ca/wp-content/uploads/2011/06/Life-Cycle-Assessment-of-Polymer-and-Cotton-Paper-Bank-Notes_opt.pdf',
    jpyBankOfJapan:
        'https://www.boj.or.jp/en/about/education/oshiete/money/c15.htm',
    czkCnbBundle:
        'https://www.cnb.cz/export/sites/cnb/cs/verejnost/.galleries/pro_media/konference_projevy/vystoupeni_projevy/download/rezabek_20080321_bankovka_1000Kc.pdf',
    hufMnb: 'https://www.mnb.hu/letoltes/tudta.pdf',
  };
}
