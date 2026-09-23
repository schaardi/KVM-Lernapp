# -*- coding: utf-8 -*-
"""Struktur aus dem ``pdftotext -layout``-Textlayer retten: Brüche und Tabellen.

Die Hefte ab 2018 setzen Formeln als Word-Formelobjekte und Datenlisten als
Tabellen. Der Textlayer bewahrt davon nur die Spaltenposition jedes Zeichens;
``load()`` presst jede Zeile auf einfache Leerzeichen und ``join_para()`` fügt
alles zu Absätzen. Heraus kamen Texte wie::

    Personalbedarf = = 36,00 Mitarbeiter 4.620 h/Monat 128,32 h/(MA · Monat)
    Anschaffungskosten (netto) 43.000 € geschätzte Wiederbeschaffungskosten …

Dieses Modul arbeitet auf den **Rohzeilen** (mit Spalten), bevor sie gepresst
werden, und macht zwei Dinge:

**Brüche linearisieren** (``brueche``): Word setzt einen Bruch über drei Zeilen –
Zähler, Hauptzeile mit dem Gleichheitszeichen, Nenner. In der Hauptzeile bleibt
an der Stelle des Bruchs eine Lücke; Zähler und Nenner stehen genau darüber und
darunter. Aus

::

                     77.600 € + 60.000 €
       MSS =                             = 57,33 €/Jahr
                          2.400 h

wird ``MSS = (77.600 € + 60.000 €) ÷ 2.400 h = 57,33 €/Jahr``. Verschachtelte
Brüche (Einheitenbrüche im Nenner) erkennt die Automatik nicht sicher; sie
stehen einzeln ausgeschrieben in ``korrekturen_formeln.FORMELN``. Findet die
Automatik eine Stelle, die sie nicht auflösen kann und die dort fehlt, meldet
``bericht()`` sie.

**Zeilen markieren** (``zeile``): Tabellenzeilen, Rechenzeilen und Zeilen eines
Kalkulationsschemas bekommen die Marke ``ZEILE`` vorangestellt, Spalten werden
durch `` | `` getrennt. ``join_para`` fügt markierte Zeilen nicht in den
Absatz davor ein. Die Web-App setzt aufeinanderfolgende ``|``-Zeilen als
Tabelle, die App und der KI-Export zeigen sie als lesbaren Text.
"""
import re

# Vorangestellt vor jede Zeile, die für sich stehen muss. Unsichtbar
# (U+2063 INVISIBLE SEPARATOR) und kein Leerraum – ``str.strip()`` lässt es
# stehen. ``join_para`` entfernt es wieder.
ZEILE = '\u2063'

# ------------------------------------------------------------------ Brüche
GLEICH = re.compile(r'(?<![=<>!])=(?!=)')
PUNKTE_ANM = re.compile(r'^\(\s*\d+\s*Punkte?\s*\)$')
# Operatoren, die einen Zähler oder Nenner in Klammern zwingen.
STRICH = re.compile(r'\s[+\-−–]\s')
PUNKT_OP = re.compile(r'\s[+\-−–·×÷*:]\s|\s·|·\s')


def _spans(zeile):
    """Zusammenhängende Textstücke (Wörter mit höchstens einem Leerzeichen
    dazwischen) als (anfang, ende, text)."""
    return [(m.start(), m.end(), m.group())
            for m in re.finditer(r'\S+(?: \S+)*', zeile)]


def _luecken(zeile, breite=200):
    """Lücken (≥ 2 Leerzeichen) einer Hauptzeile als [a, b) – samt dem Raum
    rechts vom letzten Zeichen."""
    sp = _spans(zeile)
    out = []
    for (a1, e1, _), (a2, e2, _) in zip(sp, sp[1:]):
        out.append((e1, a2))
    if sp:
        out.append((sp[-1][1], breite))
    return out


def _geteilt(zeile, grenzen):
    """Textstücke einer Zähler- oder Nennerzeile; ein Stück, das über die
    Grenze zweier Bruchstellen der Hauptzeile läuft ("P 2 000 W" über
    "I=  =  ="), wird am Leerzeichen geteilt, das der Grenze am nächsten liegt
    (bei Gleichstand am linken)."""
    out = []
    for s, e, t in _spans(zeile):
        stuecke = [(s, e, t)]
        for g in grenzen:
            neu = []
            for s2, e2, t2 in stuecke:
                luecken = [s2 + m.start() for m in re.finditer(r' ', t2)]
                if s2 < g < e2 and luecken:
                    x = min(luecken, key=lambda p: (abs(p - g), p > g))
                    neu += [(s2, x, t2[:x - s2]), (x + 1, e2, t2[x - s2 + 1:])]
                else:
                    neu.append((s2, e2, t2))
            stuecke = neu
        out += stuecke
    return out


def _im_bereich(zeile, a, b, rand=2, spans=None):
    """Textstücke einer Nachbarzeile, die zur Lücke [a, b) gehören: ihre Mitte
    liegt in der Lücke (±1), und sie ragen höchstens ``rand`` Zeichen über sie
    hinaus. Liefert (stuecke, sauber) – sauber ist False, wenn ein Stück mit
    der Mitte in der Lücke weit über sie hinausragt (dann gehört es nicht zu
    diesem Bruch)."""
    drin, sauber = [], True
    for s, e, t in (spans if spans is not None else _spans(zeile)):
        if PUNKTE_ANM.match(t):
            continue
        mitte = (s + e) / 2
        if a - 1 <= mitte < b + 1:
            if s >= a - rand - 1 and e <= b + rand + 1:
                drin.append((s, e, t))
            else:
                sauber = False
        elif s < b and e > a and (min(e, b) - max(s, a)) > (e - s) / 2:
            sauber = False
    return drin, sauber


_E = (r'(?:[kMm]?(?:N|J|W|Wh|V|A|Ω|Pa)|[mcdk]?m|[mk]?g|t|s|h|min|l|Liter|K|°C|bar|'
      r'€|%|Stück|Stk\.?|St\.|MA|Monat|Jahr|Tag|Woche|Std\.?|Bestellung|U|Umdrehungen)[²³]?')
EINHEIT_TEIL = re.compile(r'^' + _E + r'(?:\s?·\s?' + _E + r')*$')


def _hoch(t):
    """'mm 2' → 'mm²', 'm 3' → 'm³' (der Exponent steht im Textlayer als
    eigene Ziffer daneben)."""
    t = re.sub(r'([A-Za-z])\s([²³])', r'\1\2', t)
    return re.sub(r'([A-Za-z])\s?([23])\b', lambda m: m.group(1) + '²³'[int(m.group(2)) - 2], t)


def _einheitenbruch(z, n):
    """Zähler und Nenner, die nur aus Einheiten bestehen ("N" über "mm 2")."""
    z2, n2 = _hoch(z.strip()), _hoch(n.strip())
    if EINHEIT_TEIL.match(z2) and EINHEIT_TEIL.match(n2) and len(z2) <= 12 and len(n2) <= 14:
        return z2 + '/' + ('(' + n2 + ')' if '·' in n2 else n2)
    return None


def _klammer(t, nenner):
    """Zähler oder Nenner einklammern, wenn der Bruch sonst anders gelesen
    würde: im Zähler bei Strichrechnung, im Nenner bei jeder Rechnung."""
    t = t.strip()
    if t.startswith('(') and t.endswith(')') and t.count('(') == 1:
        return t
    innen = t[1:]
    strich = re.search(r'[+−–]', innen) or re.search(r'\s-\s|\d-\d', t)
    punkt = re.search(r'[·×÷*:]', innen)
    if strich or (nenner and punkt):
        return '(' + t + ')'
    return t


def _hauptzeile(zeile, junk):
    s = zeile.strip()
    return bool(s) and not junk(s) and not s.startswith('===') \
        and bool(GLEICH.search(zeile))


def brueche(zeilen, junk=lambda s: False, manuell=None, datei='', geschuetzt=lambda s: False):
    """Brüche in den Rohzeilen linearisieren.

    ``junk(text)``: Seitendeko, die keinen Bruch bilden kann (Wasserzeichen).
    ``manuell``: {zeilennr (1-basiert): (von, bis, text)} – Zeilen von..bis
    (1-basiert, einschließlich) werden durch ``text`` ersetzt; Vorrang vor der
    Automatik. Rückgabe: (neue Zeilen, Liste der Brüche, Liste offener Stellen).
    """
    z = list(zeilen)
    n = len(z)
    manuell = manuell or {}
    erledigt = set()
    brueche_log, offen = [], []

    for nr, (von, bis, text) in sorted(manuell.items()):
        # Die Hauptzeile muss im Bereich liegen, sonst stimmt der Eintrag nicht.
        assert von <= nr <= bis, (datei, nr)
        for k in range(von - 1, bis):
            erledigt.add(k)
        ind = len(z[nr - 1]) - len(z[nr - 1].lstrip())
        z[von - 1] = ' ' * ind + text
        for k in range(von, bis):
            z[k] = ''
        brueche_log.append((datei, nr, 'manuell', text))

    haupt = [i for i in range(n) if i not in erledigt and _hauptzeile(z[i], junk)]
    # Bruchstellen je Hauptzeile bestimmen, ohne schon etwas zu verändern.
    kandidaten = {}
    for i in haupt:
        if i == 0 or i + 1 >= n or (i - 1) in erledigt or (i + 1) in erledigt:
            continue
        oben, unten = z[i - 1], z[i + 1]
        # Seitendeko und die Zeilen, an denen der Parser Aufgaben und Teile
        # erkennt ("a Mögliche Punktzahl: 4"), sind nie Zähler oder Nenner.
        if junk(oben.strip()) or junk(unten.strip()) or \
                geschuetzt(oben.strip()) or geschuetzt(unten.strip()) or geschuetzt(z[i].strip()):
            continue
        stellen = []
        luecken = _luecken(z[i])
        grenzen = [b for (a, b) in luecken[:-1]]
        sp_o, sp_u = _geteilt(oben, grenzen), _geteilt(unten, grenzen)
        for a, b in luecken:
            zo, so = _im_bereich(oben, a, b, spans=sp_o)
            zu, su = _im_bereich(unten, a, b, spans=sp_u)
            # Zähler und Nenner tragen Zeichen, nicht nur Rechenzeichen – sonst
            # sind es die Gleichheitszeichen einer Spalte darüber und darunter.
            if zo and zu and so and su and \
                    re.search(r'\w', ' '.join(t for _, _, t in zo)) and \
                    re.search(r'\w', ' '.join(t for _, _, t in zu)):
                stellen.append((a, b, zo, zu))
        if stellen:
            kandidaten[i] = stellen

    belegt = {}   # Zeile -> Hauptzeile, die sie als Zähler/Nenner nutzt
    for i in kandidaten:
        for k in (i - 1, i + 1):
            belegt.setdefault(k, []).append(i)

    for i, stellen in sorted(kandidaten.items()):
        # Eine Zeile, die zugleich Nenner der einen und Zähler der nächsten
        # Hauptzeile wäre, lässt sich nicht eindeutig zuordnen.
        if len(belegt[i - 1]) > 1 or len(belegt[i + 1]) > 1 or \
                (i - 1) in kandidaten or (i + 1) in kandidaten:
            offen.append((datei, i + 1, 'mehrdeutig'))
            continue
        # Verschachtelt: weiterer Text über dem Zähler oder unter dem Nenner,
        # der keiner anderen Hauptzeile gehört.
        a0 = min(a for a, _, _, _ in stellen)
        b0 = max(max(e for _, e, _ in zo + zu) for _, _, zo, zu in stellen)
        verschachtelt = False
        for k in (i - 2, i + 2):
            if 0 <= k < n and k not in belegt and not junk(z[k].strip()):
                if _im_bereich(z[k], a0, b0, rand=0)[0] and not GLEICH.search(z[k]):
                    verschachtelt = True
        if verschachtelt:
            offen.append((datei, i + 1, 'verschachtelt'))
            continue
        # Linearisieren: jede Lücke mit Bruch wird zu "Zähler ÷ Nenner".
        haupt_z = z[i]
        oben, unten = list(z[i - 1]), list(z[i + 1])
        teile, pos = [], 0
        for a, b, zo, zu in stellen:
            zaehler = ' '.join(t for _, _, t in zo)
            nenner = ' '.join(t for _, _, t in zu)
            teile.append(haupt_z[pos:a].rstrip())
            eb = _einheitenbruch(zaehler, nenner)
            if eb:
                # direkt an die Zahl davor: "9,81 m/s²"
                teile.append(' ' + eb + ' ' if not teile[-1][-1:].isdigit() else ' ' + eb + ' ')
            else:
                teile.append(' %s ÷ %s ' % (_klammer(zaehler, False), _klammer(nenner, True)))
            pos = b
            for s, e, _ in zo:
                oben[s:e] = ' ' * (e - s)
            for s, e, _ in zu:
                unten[s:e] = ' ' * (e - s)
        teile.append(haupt_z[pos:].lstrip() if pos < len(haupt_z) else '')
        ind = len(haupt_z) - len(haupt_z.lstrip())
        neu = re.sub(r' {2,}', ' ', ''.join(teile)).strip()
        z[i] = ' ' * ind + neu
        z[i - 1] = ''.join(oben).rstrip()
        z[i + 1] = ''.join(unten).rstrip()
        brueche_log.append((datei, i + 1, 'auto', neu))
    return z, brueche_log, offen


# ---------------------------------------------------------------- Tabellen
NUM = r'[-–−+]?\s?\d{1,3}(?:\.\d{3})+(?:,\d+)?|[-–−+]?\s?\d+(?:,\d+)?'
EINHEIT = (r'(?:€|EUR|Euro|%|‰|km|t|kg|g|l|Liter|h|Std\.?|Stunden|Min\.?|min\.?|Minuten|'
           r'Tage?|Monate?|Jahre?|Stück|Stk\.?|St\.|m²|m³|m|mm|cm|dm|kWh|kW|kN|N|V|A|W|'
           r'Ω|°C|K|bar|km/h|m/s|Pkt\.?|Punkte?|TEUR|T€|Tsd\. ?€|Mio\. ?€|Personen|'
           r'Mitarbeiter|MA|Fahrzeuge|Bestellungen|Teile|Paletten|Lkw|Pkw)')
WERT = re.compile(r'^(?:[=+\-–−]\s*)?(?:ca\.\s*)?(?:(?:' + NUM + r')\s*(?:' + EINHEIT +
                  r'(?:\s*/\s*[\w.²³ ]{1,14})?)?\.?|(?:' + EINHEIT + r')\s*(?:' + NUM +
                  r'))$|^[–—-]$')
# Wert am Zeilenende für "Beschriftung Wert"-Zeilen (Datenlisten, Schemata).
WERT_ENDE = re.compile(r'(?<=\s)(?:[+\-–−]\s*)?(?:' + NUM + r')\s*(?:' + EINHEIT +
                       r'(?:\s*/\s*(?:\d+\s?)?[\w.²³]{1,14})?)?$')
# Beschriftungen, die mitten im Satz enden – dann ist die Zeile Fließtext.
SATZ_ENDE = re.compile(r'\b(?:von|vom|bei|mit|und|oder|zu|zum|zur|der|die|das|den|dem|'
                       r'des|ein|eine|einen|einem|einer|eines|auf|für|um|ca\.|je|pro|in|im|an|am|'
                       r'aus|nach|über|unter|als|wie|sind|ist|beträgt|betragen|von je|'
                       r'insgesamt|jeweils|etwa|rund|nur|noch|bis|ab|à|alle|Nr\.|§|Absatz)$', re.I)


# Finite Verben machen aus einer "Beschriftung" einen Satz.
VERB = re.compile(r'\b(?:beträgt|betragen|ist|sind|wird|werden|wurde|wurden|hat|haben|'
                  r'hatte|liegt|liegen|ergibt|ergeben|kostet|erhält|erhalten|steigt|'
                  r'sinkt|fällt|entspricht|entsprechen|bleibt|bleiben|müssen|muss|'
                  r'kann|können|soll|sollen|verdient|zahlt|benötigt|braucht)\b')


def ist_wert(t):
    return bool(WERT.match(t.strip()))


def _zellen(zeile):
    """Textstücke einer Zeile ohne die Punkte-Anmerkung am rechten Rand.
    Ein allein stehender Strich am Zeilenanfang gehört zum Stück danach
    ("–   Rabatt (10 %)"). Rückgabe: (stücke, anmerkung)."""
    sp = _spans(zeile)
    if len(sp) >= 2 and re.fullmatch(r'[■•▪◦–-]', sp[0][2]):
        sp = [(sp[0][0], sp[1][1], sp[0][2] + ' ' + sp[1][2])] + sp[2:]
    anm = None
    if sp and PUNKTE_ANM.match(sp[-1][2]):
        anm = sp[-1][2]
        sp = sp[:-1]
    return sp, anm


AUFZAEHLUNG = re.compile(r'^\s*[■•▪◦–-]\s')


def offene_bruchzeile(zeile):
    """Hauptzeile eines Bruchs, den ``brueche`` nicht auflösen konnte: zwei
    Gleichheitszeichen mit nichts dazwischen oder eins am Zeilenende."""
    return bool(re.search(r'=\s{2,}=|=\s*$', zeile))


def _datenzeile(zeile):
    if offene_bruchzeile(zeile):
        return False
    sp, _ = _zellen(zeile)
    # Striche und Aufzählungszeichen allein tragen nichts ("-   8" ist die
    # abgesetzte Zahl eines Punkte-Badges, keine Tabellenzeile).
    sp = [x for x in sp if not re.fullmatch(r'[-–—•■]', x[2])] if \
        sum(1 for x in sp if not re.fullmatch(r'[-–—•■]', x[2])) < 2 else sp
    if len(sp) < 2:
        return False
    if VERB.search(sp[0][2]) or len(sp[0][2]) > 60:
        return False
    werte = sum(1 for _, _, t in sp if ist_wert(t))
    # Zahlenkolonnen ("6  2  25  80  3,20") oder Beschriftung + Wert(e)
    return werte >= 1 and (werte >= 2 or not ist_wert(sp[0][2]) or len(sp) == 2)


def _kopfzeile(zeile):
    """Mögliche Kopfzeile: kurze Stücke ohne Werte, kein Satz, keine Aufzählung."""
    sp, anm = _zellen(zeile)
    return bool(sp) and anm is None and not AUFZAEHLUNG.match(zeile) \
        and '■' not in zeile and not any(ist_wert(t) for _, _, t in sp) \
        and all(len(t) <= 30 for _, _, t in sp) and not GLEICH.search(zeile) \
        and not zeile.rstrip().endswith((':', '.', ';', '?', '!'))


def _beschriftung_weiter(zeile, vorher):
    """Setzt ``zeile`` die Beschriftung der Tabellenzeile ``vorher`` fort? Ein
    einzelnes kurzes Textstück ohne Wert, das dort beginnt, wo die
    Beschriftung darüber beginnt."""
    sp, anm = _zellen(zeile)
    vsp, _ = _zellen(vorher)
    return len(sp) == 1 and anm is None and bool(vsp) and not ist_wert(sp[0][2]) \
        and abs(sp[0][0] - vsp[0][0]) <= 3 and len(sp[0][2]) <= 30 \
        and not GLEICH.search(zeile) and not ist_wert(vsp[0][2])


def _spalten(zeilen):
    """Spaltenbereiche aus den Weißraum-„Flüssen“ der Datenzeilen."""
    breite = max(len(z) for z in zeilen) + 1
    frei = [True] * breite
    for z in zeilen:
        sp, anm = _zellen(z)
        for s, e, t in sp:
            # Platzhalterstriche ("—") stehen oft zwischen den Spalten; sie
            # dürfen keinen eigenen Fluss zuschütten.
            if re.fullmatch(r'[—–-]', t):
                continue
            for x in range(s, e):
                frei[x] = False
    out, x = [], 0
    while x < breite:
        if not frei[x]:
            a = x
            while x < breite and not frei[x]:
                x += 1
            out.append([a, x])
        else:
            x += 1
    return out


def _schneiden(zeile, spalten, kopf=False):
    """Eine Zeile an Spaltengrenzen in Zellen teilen: jedes Wort in die Spalte,
    in der es steht (Zahlen nach ihrem rechten Rand – sie sind rechtsbündig
    gesetzt). In Kopfzeilen bleiben Stücke ganz ("Erzeugnis A" über zwei
    Spalten) und gehen in die Spalte, mit der sie sich am meisten decken."""
    sp, anm = _zellen(zeile)
    zellen = [[] for _ in spalten]
    if kopf:
        def beste(s, e):
            deck = [max(0, min(e, b) - max(s, 0 if j == 0 else a))
                    for j, (a, b) in enumerate(spalten)]
            return deck.index(max(deck)) if max(deck) > 0 else None
        for s, e, t in sp:
            # Liegen die Wörter eines Stücks über verschiedenen Spalten
            # ("Material Arbeits-"), wird es geteilt, sonst bleibt es ganz.
            woerter = [(s + m.start(), s + m.end(), m.group()) for m in re.finditer(r'\S+', t)]
            ziele = [beste(ws, we) for ws, we, _ in woerter]
            if len({x for x in ziele if x is not None}) > 1:
                for (ws, we, w), k in zip(woerter, ziele):
                    zellen[k if k is not None else beste(ws - 3, we + 3) or 0].append(w)
                continue
            k = beste(s, e)
            if k is None:
                mitte = (s + e) / 2
                k = min(range(len(spalten)), key=lambda j: min(
                    abs(mitte - spalten[j][0]), abs(mitte - spalten[j][1])))
            zellen[k].append(t)
        return [' '.join(c) for c in zellen], anm
    for s, e, t in sp:
        # Wörter mit Position, jedes Wort der Spalte seiner Mitte zuordnen
        for m in re.finditer(r'\S+', t):
            ws, we = s + m.start(), s + m.end()
            mitte = (we - 0.5) if re.fullmatch(r'[-–−+]?[\d.,]+', m.group()) else (ws + we) / 2
            k = min(range(len(spalten)),
                    key=lambda j: 0 if spalten[j][0] <= mitte < spalten[j][1]
                    else min(abs(mitte - spalten[j][0]), abs(mitte - spalten[j][1])))
            zellen[k].append(m.group())
    return [' '.join(c) for c in zellen], anm


def _kopf_zusammen(zeilen_zellen):
    """Mehrzeilige Kopfzellen spaltenweise zusammenfügen ("Produktions-" +
    "menge" → "Produktionsmenge")."""
    out = []
    for k in range(len(zeilen_zellen[0])):
        teil = ''
        for z in zeilen_zellen:
            t = z[k].strip()
            if not t:
                continue
            if teil.endswith('-') and t[:1].islower():
                teil = teil[:-1] + t
            else:
                teil = (teil + ' ' + t).strip()
        out.append(teil)
    return out


def _gleich_zusammen(zellen):
    """Ein '=' am Ende einer Zelle oder allein in einer Zelle gehört vor den
    Wert rechts daneben ("12 Monate = | 3.600 €" → "12 Monate | = 3.600 €")."""
    out = list(zellen)
    for k in range(len(out) - 1):
        if out[k + 1] and (out[k] == '=' or out[k].endswith(' =')):
            out[k] = out[k][:-1].rstrip()
            out[k + 1] = '= ' + out[k + 1]
    return out


def tabellen(zeilen, junk=lambda s: False, geschuetzt=lambda s: False):
    """Tabellenblöcke in den Rohzeilen finden und als ``a | b | c`` setzen.

    Ein Block sind mindestens zwei Datenzeilen (Beschriftung + Wert oder
    Zahlenkolonnen), getrennt höchstens durch zwei Leerzeilen; Kopfzeilen ohne
    Werte direkt darüber gehören dazu. Eine einzelne Datenzeile mit großer Lücke
    ("= Kapazitätsbedarf      277.200 min/Monat") wird ebenfalls geteilt.
    Rückgabe: (neue Zeilen, Anzahl Tabellen)."""
    z = list(zeilen)
    n = len(z)
    art = []
    # Rund um einen Bruch, den ``brueche`` nicht auflösen konnte, stehen
    # Zähler und Nenner – keine Tabellenzeilen.
    offen = {k for i, l in enumerate(z) if l.strip() and not junk(l.strip())
             and offene_bruchzeile(l) for k in (i - 1, i, i + 1)}
    for i, l in enumerate(z):
        s = l.strip()
        if not s:
            art.append('leer')
        elif junk(s) or s.startswith('===') or geschuetzt(s) or i in offen:
            art.append('fremd')
        elif _datenzeile(l):
            art.append('daten')
        elif _kopfzeile(l) and len(_zellen(l)[0]) >= 2:
            art.append('kopf')
        else:
            art.append('text')
    # Leerzeilen rund um Seitendeko (das Wasserzeichen steht mitten auf der
    # Seite, von Leerzeilen umgeben) zählen wie die Deko selbst.
    k = 0
    while k < n:
        if art[k] != 'leer':
            k += 1
            continue
        e = k
        while e < n and art[e] == 'leer':
            e += 1
        if (k > 0 and art[k - 1] == 'fremd') or (e < n and art[e] == 'fremd'):
            for x in range(k, e):
                art[x] = 'fremd'
        k = e
    bloecke, i = [], 0
    fortsetzung = {}      # Datenzeile -> Zeile mit dem Rest ihrer Beschriftung
    while i < n:
        if art[i] != 'daten':
            i += 1
            continue
        # Block ab i ausdehnen
        rows, j, leer = [i], i + 1, 0
        while j < n:
            if art[j] == 'daten':
                rows.append(j); leer = 0
            elif art[j] == 'fremd':
                leer = 0           # Seitenwechsel: Fuß- und Kopfzeilen überspringen
            elif art[j] == 'leer' and leer < 2:
                leer += 1
            elif _beschriftung_weiter(z[j], z[rows[-1]]) and fortsetzung.get(rows[-1]) is None:
                # zweite Zeile einer Zeilenbeschriftung ("Grundstücke" / "und Gebäude")
                fortsetzung[rows[-1]] = j; leer = 0
            else:
                break
            j += 1
        # Kopfzeilen direkt darüber (Leerzeilen dazwischen erlaubt). Jedes
        # Stück einer Kopfzeile muss über einer Datenspalte stehen – sonst ist
        # es der Einleitungssatz der Tabelle.
        spalten = _spalten([z[r] for r in rows])
        def ueber_spalte(zeile):
            # Die erste Spalte reicht nach links bis zum Rand: ihre Überschrift
            # ("Monat") steht oft links vor den Zeilenbeschriftungen.
            bereiche = [(0 if k == 0 else a, b) for k, (a, b) in enumerate(spalten)]
            for s_, e_, _ in _zellen(zeile)[0]:
                if not any(s_ < b + 3 and e_ > a - 3 for a, b in bereiche):
                    return False
            return True
        kopf, k, leer = [], i - 1, 0
        while k >= 0 and len(kopf) < 6 and len(rows) >= 2:
            if art[k] in ('kopf', 'text') and _kopfzeile(z[k]) and ueber_spalte(z[k]):
                kopf.insert(0, k); leer = 0
            elif art[k] == 'leer' and leer < 1:
                leer += 1
            else:
                break
            k -= 1
        # Eine Zeile aus nur einem Stück ganz oben, das nur über der ersten
        # Spalte steht, ist eine Überschrift ("Beträge in EUR (€)").
        while kopf and len(_zellen(z[kopf[0]])[0]) == 1 and len(spalten) > 1 \
                and _zellen(z[kopf[0]])[0][0][1] <= spalten[1][0] - 2:
            kopf = kopf[1:]
        if len(kopf) == 1 and len(_zellen(z[kopf[0]])[0]) < 2:
            kopf = []
        bloecke.append((kopf, rows))
        i = j
    def formelartig(zeile):
        sp, _ = _zellen(zeile)
        return any(GLEICH.search(t) for _, _, t in sp[1:]) or GLEICH.search(sp[0][2])

    anzahl = 0
    geprueft = []
    for kopf, rows in bloecke:
        # Eine reine Aufzählung ("– Jahresbedarf   80000 Stück") entscheidet
        # ``wertlisten`` als Ganzes – hier würde sie nur teilweise zur Tabelle.
        if all(AUFZAEHLUNG.match(z[r]) for r in rows):
            continue
        if not kopf:
            while rows and formelartig(z[rows[0]]):
                rows = rows[1:]
            while rows and formelartig(z[rows[-1]]):
                rows = rows[:-1]
            if not rows or sum(1 for r in rows if formelartig(z[r])) * 2 > len(rows):
                continue
        # Eine einzelne Zeile nackter Zahlen ist eine Diagrammachse.
        if len(rows) == 1 and all(re.fullmatch(r'[\d.,%€ ]+', t) for _, _, t in _zellen(z[rows[0]])[0]):
            continue
        geprueft.append((kopf, rows))
    for kopf, rows in geprueft:
        if len(rows) == 1 and not kopf:
            # Eine einzelne Zeile nur, wenn sie "Beschriftung  Wert" ist – eine
            # Formel ("Kges        = 11.070 €/Jahr") bleibt eine Rechenzeile.
            if GLEICH.search(z[rows[0]].strip()[1:]) or AUFZAEHLUNG.match(z[rows[0]]) \
                    or all(re.fullmatch(r'[\d.,%€ ]+', t) for _, _, t in _zellen(z[rows[0]])[0]):
                continue
            zellen, anm = _zellen(z[rows[0]])
            teile = _gleich_zusammen([t for _, _, t in zellen]) + ([anm] if anm else [])
            ind = len(z[rows[0]]) - len(z[rows[0]].lstrip())
            z[rows[0]] = ' ' * ind + ' | '.join(teile)
            continue
        anzahl += 1
        spalten = _spalten([z[r] for r in rows])
        kz = [_schneiden(z[r], spalten, kopf=True)[0] for r in kopf]
        daten = []
        for r in rows:
            zellen, anm = _schneiden(z[r], spalten)
            daten.append((r, zellen, anm))
        # Spalten, die überall leer sind, fallen weg
        leer_sp = [k for k in range(len(spalten))
                   if not any(d[1][k] for d in daten) and not any(h[k] for h in kz)]
        def ohne(c):
            return [x for k, x in enumerate(c) if k not in leer_sp]
        mit_anm = any(d[2] for d in daten)
        if kz:
            kopfzeile = ohne(_kopf_zusammen(kz)) + ([''] if mit_anm else [])
            ind = len(z[kopf[0]]) - len(z[kopf[0]].lstrip())
            z[kopf[0]] = ' ' * ind + ' | '.join(kopfzeile)
            for r in kopf[1:]:
                z[r] = ''
        alle_auf = all(AUFZAEHLUNG.match(z[r]) for r in rows)
        for r, zellen, anm in daten:
            c = _gleich_zusammen(ohne(zellen)) + ([anm or ''] if mit_anm else [])
            if alle_auf and c:
                c[0] = re.sub(r'^[■•▪◦–-]\s+', '', c[0])
            f = fortsetzung.get(r)
            if f is not None and c:
                rest = re.sub(r'\s+', ' ', z[f]).strip()
                c[0] = (c[0][:-1] + rest) if c[0].endswith('-') and rest[:1].islower() \
                    else (c[0] + ' ' + rest).strip()
                z[f] = ''
            ind = len(z[r]) - len(z[r].lstrip())
            z[r] = ' ' * ind + ' | '.join(c)
    return z, anzahl


# ------------------------------------------------------- Zeichen und Zeilen
# pdftotext liefert das x̄ einer Tabelle (NTG F2018) als Folge aus Richtungs-
# zeichen und Überstrich.
SONDERFOLGEN = {'‫̅ݔ‬': 'x̄'}


def symbole(zeile, tabelle):
    """Zeichen der Symbolschrift (Privatbereich U+F0xx) übersetzen, ohne die
    Spalten zu verschieben: jedes Zeichen wird genau ein Zeichen (die
    bedeutungslosen Klammerteile ein Leerzeichen)."""
    for alt, neu in SONDERFOLGEN.items():
        if alt in zeile:
            zeile = zeile.replace(alt, neu.ljust(len(alt)))
    if not re.search(r'[-]', zeile):
        return zeile
    return ''.join((tabelle.get(ch) or ' ') if ch in tabelle else ch for ch in zeile)


# Kleine Wörter, die in Formelbeschriftungen vorkommen ("Kosten pro Stück").
FORMELWORT = {'pro', 'je', 'und', 'bei', 'der', 'des', 'die', 'das', 'im', 'in',
              'für', 'aus', 'zu', 'mit', 'von', 'ohne', 'neu', 'alt', 'soll', 'ist',
              'gesamt', 'kalk', 'kalk.', 'max', 'max.', 'min', 'min.', 'ges'}
EINHEITWORT = re.compile(r'^(?:[a-zµΩ°]{1,3}[²³]?|min\.?|std\.?|stk\.?|st\.|kwh|'
                         r'tage?|jahre?|monat|woche|stunden?|minuten?|sekunden?)[,.;]?$')


def ist_rechenzeile(l):
    """Rechenzeile ("Kapazitätsbestand = 8 h/Tag · 20 Tage") – nicht aber ein
    Satz, der eine Größe nennt ("… eine Höhe h = 4 m gezogen.", "(m = 1,6 t)"),
    oder eine Begriffserklärung ("Forming = Formierungsphase: Die Phase …")."""
    ohne = re.sub(r'\([^()]*\)', ' ', l)          # Klammern zählen nicht
    m = GLEICH.search(ohne)
    if not m:
        return False
    if not (re.search(r'\d', l) or re.search(r'[+−–·÷×/√∑²³]', l) or len(l) <= 45):
        return False
    nach_erst = ohne[m.end():]
    worte = [w for w in re.findall(r'[A-Za-zÄÖÜäöüß]{3,}', nach_erst)
             if not EINHEITWORT.match(w.lower())]
    if len(worte) >= 8 or (len(worte) >= 5 and not re.search(r'\d', nach_erst)):
        return False
    vor = ohne[:m.start()]
    woerter = [w for w in re.findall(r'[A-Za-zÄÖÜäöüß]{2,}\.?', vor)]
    if len([w for w in woerter if w.lower() not in FORMELWORT]) > 6 or VERB.search(vor):
        return False
    # Fließtext nach dem letzten Gleichheitszeichen ("= 4 m gezogen.")
    nach = ohne[ohne.rfind('=') + 1:]
    klein = [w for w in re.findall(r'\b[a-zäöüß][a-zäöüß]{3,}\b\.?', nach)
             if not EINHEITWORT.match(w.lower())]
    if klein and (nach.rstrip().endswith('.') or len(klein) >= 2):
        return False
    return True


def ist_zeile(l):
    """Tabellenzeile ("a | b") oder Rechenzeile ("x = …") – steht für sich."""
    return ' | ' in l or l.startswith('| ') or ist_rechenzeile(l)


def rechen_fortsetzung(vorher, l):
    """Setzt ``l`` die Rechnung aus ``vorher`` fort? Die OCR bricht Rechnungen
    um: "… (49.700 €) — Wiederverkauf (3.500 €)" / "— Reifenkosten … = 44.000"
    oder "… Reifenkosten (2.200 €) =" / "44.000 € (1 Punkt)"."""
    if not vorher or '|' in vorher or '|' in l:
        return False
    # Die Zeile davor ist eine Rechnung ohne Ergebnis, diese führt sie fort.
    if re.match(r'^[—+·×÷:]\s', l) and '=' not in vorher and ist_rechenzeile(vorher + ' ' + l):
        return True
    return bool(re.search(r'[=+·×÷—–-]$', vorher.rstrip())) and GLEICH.search(vorher) \
        and not ist_rechenzeile(l) and bool(re.match(r'^[\d(−–-]', l))


def zeile_sauber(l):
    """Tabellenzeile vereinheitlichen: Leerraum um die Trenner. Leere Zellen
    bleiben stehen – sie halten die Werte in ihrer Spalte."""
    l = re.sub(r'\s{2,}', ' ', l).strip()
    if '|' not in l:
        return l
    zellen = [c.strip() for c in re.split(r'\s*\|\s*', l)]
    return ' | '.join(zellen).strip()


def wertzeile(l):
    """'Beschriftung Wert' → (beschriftung, wert, anmerkung) oder None."""
    if '|' in l or len(l) > 100:
        return None
    anm = None
    m = re.search(r'\s*(\(\s*\d+\s*Punkte?\s*\))$', l)
    if m:
        anm, l = m.group(1), l[:m.start()]
    m = WERT_ENDE.search(l)
    if not m:
        return None
    lab = l[:m.start()].strip()
    # "TbB = 9.750 min/BAZ" ist eine Rechenzeile, keine Wertzeile.
    if lab.endswith('='):
        return None
    kern = re.sub(r'^[–•■-]\s+', '', lab)
    if len(re.findall(r'[A-Za-zÄÖÜäöüß]', kern)) < 3 or SATZ_ENDE.search(kern):
        return None
    # Formeln ("x = 3 · 4 = 12") sind Rechenzeilen, keine Wertzeilen – ein
    # führendes Rechenzeichen des Schemas ("= Barverkaufspreis") zählt nicht.
    if GLEICH.search(re.sub(r'^[=+\-–−]\s*', '', kern)):
        return None
    if lab.endswith((',', ';')) or lab.count('(') != lab.count(')'):
        return None
    # Eine Beschriftung ist kein Satz: nicht zu lang, kein Satzende darin.
    if len(kern) > 60 or re.search(r'[.!?]\s+[A-ZÄÖÜ]', kern) or VERB.search(kern):
        return None
    # "20 Transporter, zGM 3,5 t" ist ein Listeneintrag, kein Wertepaar.
    if re.match(r'^\d', kern) and ',' in kern:
        return None
    return lab, m.group().strip(), anm


def wertlisten(zeilen, geschuetzt=lambda s: False):
    """Läufe aus mindestens zwei 'Beschriftung Wert'-Zeilen als Tabelle setzen
    (``Beschriftung | Wert``). Leerzeilen dazwischen (OCR) unterbrechen den
    Lauf nicht. Eine Wertzeile direkt neben einer schon gesetzten
    Tabellenzeile gehört zur selben Tabelle und bekommt deren Breite.

    Aufzählungsstriche: Stehen alle Zeilen eines Laufs als Aufzählung da, ist
    der Strich ein Aufzählungszeichen und fällt weg ("– Urlaub 10 %"). Im
    Kalkulationsschema wechseln sie sich mit Zeilen ohne Strich ab – dann ist
    er ein Minus ("– Rabatt (10 %) 13,30 €") und bleibt stehen. Eine Aufzählung,
    von der nur ein Teil Werte trägt, bleibt eine Aufzählung."""
    z = list(zeilen)
    voll = [k for k, l in enumerate(z) if l.strip()]       # nicht leere Zeilen
    wz = {k: (None if geschuetzt(z[k]) else wertzeile(z[k])) for k in voll}
    auf = {k: bool(AUFZAEHLUNG.match(z[k])) for k in voll}
    tab = {k: '|' in z[k] for k in voll}
    m = len(voll)
    a = 0
    while a < m:
        if not wz[voll[a]]:
            a += 1
            continue
        b = a
        while b + 1 < m and wz[voll[b + 1]] and voll[b + 1] - voll[b] <= 3:
            b += 1
        lauf = voll[a:b + 1]
        # Aufzählungsblöcke (auch über Leerzeilen), die der Lauf anschneidet,
        # müssen ganz drin liegen.
        ok = True
        if any(auf[k] for k in lauf):
            x = a
            while x > 0 and auf[voll[x - 1]] and voll[x] - voll[x - 1] <= 3:
                x -= 1
            y = b
            while y + 1 < m and auf[voll[y + 1]] and voll[y + 1] - voll[y] <= 3:
                y += 1
            if (x < a and auf[voll[a]]) or (y > b and auf[voll[b]]):
                ok = False
        vor = voll[a - 1] if a > 0 and voll[a] - voll[a - 1] <= 3 else None
        nach = voll[b + 1] if b + 1 < m and voll[b + 1] - voll[b] <= 3 else None
        nachbar = (vor is not None and tab[vor]) or (nach is not None and tab[nach])
        if ok and (len(lauf) >= 2 or nachbar):
            alle_auf = all(auf[k] for k in lauf) and not nachbar
            # Wertspalte der Nachbartabelle: die letzte, oder die davor, wenn
            # die letzte die Punkte-Anmerkungen trägt.
            wspalte = 1
            if nachbar:
                ref = z[vor if vor is not None and tab[vor] else nach].split(' | ')
                wspalte = len(ref) - 1
                if PUNKTE_ANM.match(ref[-1].strip()) and len(ref) > 2:
                    wspalte = len(ref) - 2
            for k in lauf:
                lab, wert, anm = wz[k]
                if alle_auf:
                    lab = re.sub(r'^[–•■-]\s+', '', lab)
                zellen = [lab] + [''] * (wspalte - 1) + [wert] + ([anm] if anm else [])
                z[k] = ' | '.join(zellen)
        a = b + 1
    return z
