# -*- coding: utf-8 -*-
"""Rechnet die Rechenaufgaben der Original-IHK-Prüfungen unabhängig nach.

Die Musterlösungen sind nicht amtlich, sondern nachträglich erarbeitet – bei
den Rechenaufgaben lässt sich das aber hart prüfen: Dieses Skript rechnet jede
Aufgabe aus den in der Aufgabenstellung genannten Daten neu und vergleicht das
Ergebnis mit den Zahlen, die in der hinterlegten Musterlösung stehen.

    python3 scripts/pruefungen/rechenpruefung.py [index.html]

Ausgabe je Teilaufgabe: erwartete Größe, nachgerechneter Wert und ob der Wert
in der Musterlösung wörtlich vorkommt. Exit-Code 1, sobald etwas nicht passt.
"""
import json
import re
import sys
from decimal import Decimal, ROUND_HALF_UP


def de(x, nk=2):
    """Zahl in deutscher Schreibweise, kaufmännisch gerundet (wie in den Lösungen).

    Kaufmännisch heißt: 318.190,275 € werden zu 318.190,28 €. Die Rundung von
    ``%f`` würde hier abrunden, weil 0,275 binär minimal kleiner gespeichert ist.
    """
    d = x if isinstance(x, Decimal) else Decimal(repr(float(x)))
    s = str(d.quantize(Decimal(1).scaleb(-nk), rounding=ROUND_HALF_UP))
    ganz, _, rest = s.partition('.')
    neg, ganz = ganz.startswith('-'), ganz.lstrip('-')
    grp = ''
    while len(ganz) > 3:
        grp = '.' + ganz[-3:] + grp
        ganz = ganz[:-3]
    out = ('-' if neg else '') + ganz + grp + (',' + rest if rest else '')
    return out


# --------------------------------------------------------------------------- #
# Nachrechnungen: (Teilaufgaben-ID, Beschreibung, Funktion -> [(Größe, Text)])
# --------------------------------------------------------------------------- #
def ok1112_2a():
    """Fahrzeugkostenrechnung Sattelkraftfahrzeug, 12.11.2025 Aufgabe 2 a)."""
    afa_basis = 180_000 - 6_000          # Reifen laufleistungsbezogen
    afa = (afa_basis - 20_000) / 8
    zins = (afa_basis + 20_000) / 2 * 0.05
    personal = 3_500 * 12 * 1.35 * 1.2
    fix = afa + zins + 6_700 + personal + 10_000
    kraftstoff = 100_000 / 100 * 30 * 1.30
    schmier = 100_000 / 1_000 * 2.80
    reifen = 6_000 / 120_000 * 100_000
    var = kraftstoff + schmier + reifen + 15_000
    return [('Abschreibung', de(afa)), ('kalk. Zinsen', de(zins)),
            ('Personalkosten', de(personal)), ('feste Kosten', de(fix)),
            ('variable Kosten', de(var)), ('Gesamtkosten', de(fix + var))]


def ok1112_2b():
    """Wirtschaftlichkeit, 12.11.2025 Aufgabe 2 b)."""
    erloes = 690 * 230
    kosten = 168_120.0
    return [('Erlöse', de(erloes)),
            ('Wirtschaftlichkeit', de(erloes / kosten, 3)),
            ('Verlust', de(kosten - erloes)),
            ('nötiger Tageserlös', de(kosten / 230))]


def ok1112_6a():
    """Nutzplatzkilometer und Linienkosten, 12.11.2025 Aufgabe 6 a).

    Gerechnet wird mit ``Decimal``: 163.174,50 km × 1,95 €/km ergibt exakt
    318.190,275 € – als Gleitkommazahl käme 318.190,2749… heraus und damit eine
    scheinbare Abweichung von einem Cent zur Musterlösung.
    """
    D = Decimal
    wkm910 = D(2 * 67_000)
    nkm910 = wkm910 * D('0.97')
    npk910 = nkm910 * 50
    kost910 = wkm910 * D('2.10')
    netto = (D(2_200) - 225) * D('0.9')
    std = netto * D('5.1')
    wkm920 = std * 18
    nkm920 = wkm920 - 4_000
    npk920 = nkm920 * 45
    kost920 = wkm920 * D('1.95')
    return [('Nutzkilometer 910', de(nkm910, 0)), ('Nutzplatz-km 910', de(npk910, 0)),
            ('Linienkosten 910', de(kost910)),
            ('Fahrdienststunden 920', de(std, 2)), ('Wagenkilometer 920', de(wkm920)),
            ('Nutzplatz-km 920', de(npk920)), ('Linienkosten 920', de(kost920)),
            ('Cent je Platz-km 910', de(kost910 / npk910 * 100, 2)),
            ('Cent je Platz-km 920', de(kost920 / npk920 * 100, 2))]


def ft1111_2a():
    """Sicherungskräfte, 11.11.2025 Aufgabe 2 a)."""
    fg = 16_000 * 9.81
    return [('Gewichtskraft', de(fg, 0)), ('nach vorn 0,8', de(0.8 * fg, 0)),
            ('hinten/seitlich 0,5', de(0.5 * fg, 0)),
            ('Reibung µ=0,6', de(0.6 * fg, 0)),
            ('Restkraft vorn', de(0.8 * fg - 0.6 * fg, 0)),
            ('Restkraft vorn bei µ=0,3', de(0.8 * fg - 0.3 * fg, 0))]


def ft1111_2b():
    """Ladungsschwerpunkt, 11.11.2025 Aufgabe 2 b)."""
    laenge = 16 * 0.80
    mitten = [0.40 + i * 0.80 for i in range(16)]
    return [('Ladelänge', de(laenge, 2)),
            ('Summe der Abstände', de(sum(mitten), 2)),
            ('Schwerpunkt', de(sum(mitten) / 16, 2)),
            ('Gesamtmasse', de(8 + 7 + 16, 0))]


def ft1111_4():
    """Lagerkennzahlen, 11.11.2025 Aufgabe 4 a) bis c)."""
    zugang = 6 * 710 + 4 * 625
    verbrauch = 820 + zugang - 580
    bestand = (820 + 580) / 2
    uh = verbrauch / bestand
    q = (200 * verbrauch * 120 / (12 * 14)) ** 0.5
    bestellkosten = verbrauch / q * 120
    lager = bestand * 12 * 0.14
    return [('Zugänge', de(zugang, 0)), ('Jahresverbrauch', de(verbrauch, 0)),
            ('Ø-Bestand', de(bestand, 0)), ('Umschlagshäufigkeit', de(uh, 0)),
            ('Lagerdauer', de(360 / uh, 0)), ('optimale Bestellmenge', de(q, 0)),
            ('Bestellkosten', de(bestellkosten)), ('Lagerhaltungskosten', de(lager)),
            ('Gesamtkosten', de(bestellkosten + lager))]


def ok0508_1a():
    """Nutzwertanalyse, 08.05.2025 Aufgabe 1 a)."""
    gew = [8, 9, 5, 10, 5, 4, 10, 7]
    a = [60, 70, 100, 90, 60, 50, 80, 60]
    b = [80, 60, 40, 70, 80, 50, 70, 80]
    c = [70, 60, 60, 40, 70, 60, 80, 70]
    s = lambda v: sum(g * p for g, p in zip(gew, v))
    return [('Nutzwert A', de(s(a), 0)), ('Nutzwert B', de(s(b), 0)),
            ('Nutzwert C', de(s(c), 0))]


def ok0508_4():
    """Kostenkalkulation Kühlfahrzeug, 08.05.2025 Aufgabe 4 a) bis c)."""
    afa = 270_000 / 10
    var_km = afa * 0.40 / 96_000 + 35 / 100 * 1.20 + 3_600 / 96_000
    fix = afa * 0.60 + 270_000 / 2 * 0.05 + 57_600 + 4_000 + 3_000 + 2_800 + 10_200
    fix_tag = fix / 240
    tour = fix_tag + var_km * 320
    return [('variable Kosten je km', de(var_km)), ('fixe Kosten je Jahr', de(fix)),
            ('fixe Kosten je Tag', de(fix_tag)), ('Tourkosten', de(tour)),
            ('je 100 kg bei 60 %', de(tour / (24_000 * 0.60 / 100))),
            ('je 100 kg bei 100 %', de(tour / 240))]


PRUEFUNGEN = [
    ('P-OK-20251112-s3', 'Fahrzeugkosten Sattelkraftfahrzeug', ok1112_2a),
    ('P-OK-20251112-s4', 'Wirtschaftlichkeit', ok1112_2b),
    ('P-OK-20251112-s13', 'Nutzplatzkilometer und Linienkosten', ok1112_6a),
    ('P-FT-20251111-s3', 'Sicherungskräfte', ft1111_2a),
    ('P-FT-20251111-s4', 'Ladungsschwerpunkt', ft1111_2b),
    ('P-FT-20251111-s9', 'Lagerkennzahlen und Andler', ft1111_4),
    ('P-OK-20250508-s0', 'Nutzwertanalyse', ok0508_1a),
    ('P-OK-20250508-s10', 'Kostenkalkulation Kühlfahrzeug', ok0508_4),
]


def loesungen(pfad):
    """Alle Musterlösungen aus der Web-App als {Teilaufgaben-ID: Text}."""
    html = open(pfad, encoding='utf-8').read()
    cases = json.loads(re.search(r'window\.KVM_CASES\s*=\s*(\[.*?\]);\s*\n', html, re.S).group(1))
    out = {}
    for c in cases:
        for s in c['steps']:
            out[s['id']] = s.get('a', '')
    return out


def main(pfad='index.html'):
    texte = loesungen(pfad)
    # Die Lagerkennzahlen und die Fahrzeugkalkulation ziehen sich über mehrere
    # Teilaufgaben; dafür wird der Text der ganzen Aufgabe zusammengefasst.
    verbund = {
        'P-FT-20251111-s9': ['P-FT-20251111-s7', 'P-FT-20251111-s8', 'P-FT-20251111-s9'],
        'P-OK-20250508-s10': ['P-OK-20250508-s8', 'P-OK-20250508-s9', 'P-OK-20250508-s10'],
    }
    fehler = 0
    for sid, titel, fn in PRUEFUNGEN:
        text = '\n'.join(texte.get(k, '') for k in verbund.get(sid, [sid]))
        print('\n%s – %s' % (sid, titel))
        for name, wert in fn():
            ok = wert in text
            if not ok:
                fehler += 1
            print('   %-26s %14s  %s' % (name, wert, 'in Musterlösung' if ok
                                         else 'NICHT GEFUNDEN'))
    print('\n%s' % ('Alle nachgerechneten Werte stehen so in den Musterlösungen.'
                    if not fehler else '%d Abweichung(en) gefunden.' % fehler))
    return 1 if fehler else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else 'index.html'))
