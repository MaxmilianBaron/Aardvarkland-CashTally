#!/usr/bin/env python3
"""Generate translations for English runtime fallbacks.

The input is the JSON produced by tool/l10n_currency_audit.dart. Existing
hand-authored translations are not touched: the generated Dart catalog only
contains keys listed as English fallbacks by the runtime audit.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
import time
from pathlib import Path


# A self-closing neutral tag survives both classic and LLM-backed translation
# models without being transliterated or merged into neighbouring sentences.
SEPARATOR = " <x/> "
PLACEHOLDER_PATTERN = re.compile(r"\{([A-Za-z][A-Za-z0-9_]*)\}")
MANUAL_OVERRIDES: dict[str, dict[str, str]] = {
    "ar": {
        "actualInTill": "المبلغ الفعلي في الصندوق",
        "breakdown": "التفاصيل",
        "businessProfile": "هوية المنشأة والصندوق",
        "businessProfileNotSet": "أعدّ بيانات المنشأة والموقع والصندوق",
        "clear": "مسح",
        "countMatches": "المبلغ متطابق",
        "downloadPdf": "حفظ PDF",
        "estimatedWeightInfo": (
            "تنشر جهة الإصدار هذا الوزن الاسمي للأوراق النقدية؛ وقد تختلف "
            "الورقة الفعلية. تُستبعد الأوراق النقدية التي لا يتوفر لها رقم "
            "رسمي. وتتبع أوزان العملات المعدنية مواصفات دار السك."
        ),
        "expectedHelp": "المبلغ المسجل في نظام نقطة البيع",
        "finishBlindCountConfirm": (
            "هل تريد قفل كميات جميع الفئات وإظهار حقول المقارنة؟ "
            "لا يمكن التراجع عن ذلك في هذه الإقفالة."
        ),
        "leaveInTillHelp": "الرصيد الافتتاحي للوردية التالية",
        "notAuthenticity": "ليس فحصًا للأصالة",
        "ocrScansCount": "عدد عمليات مسح OCR في هذه الإقفالة: {count}",
        "sharePdf": "مشاركة PDF",
        "signatureHelp": "وقّع داخل المربع بإصبعك أو قلم الشاشة.",
        "tillName": "الصندوق / سجل النقدية",
        "unlimitedOcrBody": "جميع العملات الـ 32 المدعومة.",
    },
    "bg": {"unlimitedOcrBody": "Всички 32 поддържани валути."},
    "da": {
        "signatureHelp": "Skriv under i feltet med en finger eller pen.",
        "unlimitedOcrBody": "Alle 32 understøttede valutaer.",
    },
    "de": {
        "trialReportWatermark": (
            "TESTVORSCHAU — für den Export ist die Vollversion erforderlich"
        )
    },
    "el": {
        "signatureHelp": "Υπογράψτε στο πλαίσιο με το δάχτυλο ή μια γραφίδα.",
        "unlimitedOcrBody": "Και τα 32 υποστηριζόμενα νομίσματα.",
    },
    "es": {
        "currencyUAH": "grivna ucraniana",
        "lifetimeBenefitAllFeaturesBody": (
            "La versión gratuita y la versión sin publicidad tienen las "
            "mismas funciones de conteo, OCR, historial, PDF y CSV."
        ),
        "unlimitedOcr": "OCR ilimitado de billetes",
        "unlimitedOcrBody": "Las 32 monedas admitidas.",
    },
    "et": {
        "signatureHelp": "Allkirjastage kastis sõrme või puutepliiatsiga.",
        "unlimitedOcrBody": "Kõik 32 toetatud valuutat.",
    },
    "fi": {
        "signatureHelp": "Allekirjoita ruutuun sormella tai kosketuskynällä.",
        "unlimitedOcrBody": "Kaikki 32 tuettua valuuttaa.",
    },
    "fr": {
        "purchaseCompletionFailed": (
            "La version sans publicité est active, mais le magasin n’a pas pu "
            "terminer la confirmation de l’achat. Rouvrez l’application pour "
            "réessayer."
        )
    },
    "he": {"unlimitedOcrBody": "כל 32 המטבעות הנתמכים."},
    "hi": {"unlimitedOcrBody": "सभी 32 समर्थित मुद्राएँ।"},
    "hr": {"unlimitedOcrBody": "Sve 32 podržane valute."},
    "hu": {"unlimitedOcrBody": "Mind a 32 támogatott pénznem."},
    "id": {"unlimitedOcrBody": "Semua 32 mata uang yang didukung."},
    "lb": {"unlimitedOcrBody": "All 32 ënnerstëtzt Währungen."},
    "lt": {"unlimitedOcrBody": "Visos 32 palaikomos valiutos."},
    "lv": {"unlimitedOcrBody": "Visas 32 atbalstītās valūtas."},
    "ms": {"unlimitedOcrBody": "Semua 32 mata wang yang disokong."},
    "mt": {
        "blindCountHelp": (
            "Għodd l-ewwel mingħajr ma tara l-ammont mistenni. "
            "Illokkja l-kwantitajiet qabel ma jintwera l-paragun."
        ),
        "blindCountUsed": (
            "Iva — il-kwantitajiet ġew illokkjati qabel il-paragun"
        ),
        "unlimitedOcrBody": "It-32 munita appoġġata kollha.",
    },
    "nb": {"unlimitedOcrBody": "Alle 32 støttede valutaer."},
    "nl": {"unlimitedOcrBody": "Alle 32 ondersteunde valuta's."},
    "pl": {
        "leaveInTillHelp": "Gotówka początkowa na następną zmianę",
        "unlimitedOcrBody": "Wszystkie 32 obsługiwane waluty.",
    },
    "pt": {"unlimitedOcrBody": "Todas as 32 moedas suportadas."},
    "ru": {"unlimitedOcrBody": "Все 32 поддерживаемые валюты."},
    "sk": {"unlimitedOcrBody": "Všetkých 32 podporovaných mien."},
    "sl": {
        "signatureHelp": "Podpišite se v okvir s prstom ali pisalom.",
        "storeConnectionFailed": (
            "Aplikacija se ni mogla povezati s trgovino."
        ),
        "unlimitedOcrBody": "Podprtih je vseh 32 valut.",
    },
    "sv": {"unlimitedOcrBody": "Alla 32 valutor som stöds."},
    "th": {"unlimitedOcrBody": "รองรับสกุลเงินทั้งหมด 32 สกุล"},
    "tr": {"unlimitedOcrBody": "Desteklenen 32 para biriminin tümü."},
    "uk": {"unlimitedOcrBody": "Усі 32 підтримувані валюти."},
    "ur": {"unlimitedOcrBody": "تمام 32 معاونت یافتہ کرنسیاں۔"},
}


def _shield_placeholders(text: str) -> tuple[str, dict[str, str]]:
    replacements: dict[str, str] = {}

    def replace(match: re.Match[str]) -> str:
        token = f"{{{{{len(replacements)}}}}}"
        replacements[token] = match.group(0)
        return token

    return PLACEHOLDER_PATTERN.sub(replace, text), replacements


def _restore_placeholders(text: str, replacements: dict[str, str]) -> str:
    for token, placeholder in replacements.items():
        text = re.sub(re.escape(token), placeholder, text, flags=re.IGNORECASE)
    return text


def _repair_transport_mojibake(text: str) -> str:
    # Windows PowerShell 5 can decode UTF-8 punctuation through its OEM code
    # page while relaying JSON. Repair only the two observed byte sequences.
    return (
        text.replace("ÔÇö", "—")
        .replace("ÔČö", "—")
        .replace("ÔÇŽ", "…")
        .replace("┬Ě", "·")
        .replace("┼é", "ł")
    )


def _translate_block(texts: list[str], target: str) -> list[str]:
    shielded: list[str] = []
    replacements: list[dict[str, str]] = []
    for text in texts:
        protected, mapping = _shield_placeholders(text)
        shielded.append(protected)
        replacements.append(mapping)

    body = {"source": "en", "target": target, "text": SEPARATOR.join(shielded)}
    powershell = (
        "$ErrorActionPreference='Stop';"
        "$payload=[Console]::In.ReadToEnd()|ConvertFrom-Json;"
        "$session=New-Object Microsoft.PowerShell.Commands.WebRequestSession;"
        "$html=(Invoke-WebRequest -UseBasicParsing "
        "-Uri 'https://www.bing.com/translator' -WebSession $session "
        "-TimeoutSec 45).Content;"
        "$abuse=[regex]::Match($html,"
        "'params_AbusePreventionHelper\\s*=\\s*(\\[[^;]+\\])')"
        ".Groups[1].Value|ConvertFrom-Json;"
        "$ig=[regex]::Match($html,'IG:\"([A-F0-9]+)\"').Groups[1].Value;"
        "$iid=[regex]::Match($html,'data-iid=\"([^\"]+)\"').Groups[1].Value;"
        "if(!$ig-or!$iid-or$abuse.Count-lt2){throw 'Bing token parsing failed'};"
        "$uri=\"https://www.bing.com/ttranslatev3?"
        "isVertical=1&IG=$ig&IID=$iid.1\";"
        "$result=Invoke-WebRequest -UseBasicParsing -Method Post -Uri $uri "
        "-WebSession $session -Body @{fromLang=$payload.source;"
        "to=$payload.target;text=$payload.text;token=$abuse[1];key=$abuse[0];"
        "tryFetchingGenderDebiasedTranslations='true'} -TimeoutSec 45;"
        "$result.Content"
    )
    last_error: Exception | None = None
    for attempt in range(5):
        try:
            process = subprocess.run(
                ["powershell.exe", "-NoProfile", "-Command", powershell],
                input=json.dumps(body, ensure_ascii=False),
                text=True,
                encoding="utf-8",
                capture_output=True,
                timeout=60,
                check=True,
            )
            response = json.loads(process.stdout)
            if not isinstance(response, list):
                raise ValueError(f"unexpected Bing response: {response!r}")
            translated = response[0]["translations"][0]["text"]
            parts = translated.split(SEPARATOR)
            if len(parts) != len(texts):
                # CJK and some Indic models preserve the neutral tag but
                # remove one or both surrounding spaces.
                parts = re.split(r"\s*<x\s*/>\s*", translated)
            if len(parts) != len(texts):
                # Other models preserve the bars but collapse their newlines.
                parts = re.split(r"\s*\|{5}\s*", translated)
            if len(parts) != len(texts):
                # Some target models remove the punctuation-only separator but
                # retain the blank line around it (observed for Korean).
                parts = re.split(r"\r?\n\s*\r?\n", translated)
            if len(parts) != len(texts):
                raise ValueError(
                    f"separator mismatch: expected {len(texts)}, got {len(parts)}; "
                    f"sample={translated[:500]!r}"
                )
            restored = [
                _repair_transport_mojibake(
                    _restore_placeholders(part, mapping).strip()
                )
                for part, mapping in zip(parts, replacements, strict=True)
            ]
            for source, result in zip(texts, restored, strict=True):
                if set(PLACEHOLDER_PATTERN.findall(source)) != set(
                    PLACEHOLDER_PATTERN.findall(result)
                ):
                    raise ValueError(
                        f"placeholder mismatch: {source!r} -> {result!r}"
                    )
            return restored
        except Exception as error:  # Network retries are intentionally bounded.
            last_error = error
            time.sleep(2**attempt)
    raise RuntimeError(f"translation failed for {target}: {last_error}")


def _dart_string(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("$", "\\$")
        .replace("\r", "")
        .replace("\n", "\\n")
    )


def main() -> int:
    if len(sys.argv) != 4:
        print(
            "usage: generate_complete_localizations.py "
            "<audit.json> <cache.json> <output.dart>",
            file=sys.stderr,
        )
        return 2

    audit_path, cache_path, output_path = map(Path, sys.argv[1:])
    audit = json.loads(audit_path.read_text(encoding="utf-8"))
    english_row = next(
        row for row in audit["languages"] if row["language"] == "en"
    )
    english = english_row["translatedStrings"]

    if cache_path.exists():
        cache: dict[str, dict[str, str]] = json.loads(
            cache_path.read_text(encoding="utf-8")
        )
        cache = {
            language: {
                key: _repair_transport_mojibake(value)
                for key, value in translations.items()
            }
            for language, translations in cache.items()
        }
        for language, translations in MANUAL_OVERRIDES.items():
            cache.setdefault(language, {}).update(translations)
    else:
        cache = {}

    rows = [
        row for row in audit["languages"] if row["language"] != "en"
    ]
    for row in rows:
        language = row["language"]
        target = language
        language_cache = cache.setdefault(language, {})
        missing_keys = row["englishFallbackKeys"]
        pending = [key for key in missing_keys if key not in language_cache]
        print(
            f"{language}: {len(missing_keys)} fallback keys, "
            f"{len(pending)} to translate",
            flush=True,
        )
        batches: list[list[str]] = []
        batch: list[str] = []
        batch_size = 0
        for key in pending:
            added_size = len(english[key]) + (len(SEPARATOR) if batch else 0)
            if batch and batch_size + added_size > 850:
                batches.append(batch)
                batch = []
                batch_size = 0
                added_size = len(english[key])
            batch.append(key)
            batch_size += added_size
        if batch:
            batches.append(batch)

        for keys in batches:
            translated = _translate_block([english[key] for key in keys], target)
            language_cache.update(zip(keys, translated, strict=True))
            cache_path.parent.mkdir(parents=True, exist_ok=True)
            cache_path.write_text(
                json.dumps(cache, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            time.sleep(0.5)

    lines = [
        "/// Generated from the English runtime fallback catalog.",
        "///",
        "/// Existing hand-authored translations take precedence at runtime.",
        "abstract final class CompleteLocalizations {",
        "  static const Map<String, Map<String, String>> all = {",
    ]
    for row in sorted(rows, key=lambda item: item["language"]):
        language = row["language"]
        # Emit every cached translation that still belongs to the current
        # English catalog. A later audit may contain only newly introduced
        # fallbacks; limiting output to that delta would silently discard the
        # previously generated catalog.
        keys = sorted(key for key in cache[language] if key in english)
        lines.append(f"    '{language}': {{")
        for key in keys:
            value = cache[language][key]
            lines.append(f"      '{key}': '{_dart_string(value)}',")
        lines.append("    },")
    lines.extend(["  };", "}", ""])
    cache_path.write_text(
        json.dumps(cache, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    output_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {output_path}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
