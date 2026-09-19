# -*- coding: utf-8 -*-
"""Nachbesserung der OCR-Textlayer der gescannten Hefte (Tranche T4).

Die Scans H2014–H2017 sind MRC-PDFs mit 200-ppi-Schwarzweiß-Stencils für den
Text. Beim Scannen sind die i-Punkte und die Umlautpunkte weitgehend
verloren gegangen – auf dem Seitenbild selbst, nicht erst in der OCR. Ein
besseres Modell (``tessdata_best``) oder eine höhere Auflösung ändern daran
nichts; ausprobiert am RBH-Heft Herbst 2017.

Deshalb wird hier nachträglich geradegezogen, was sich aus dem Deutschen und
aus dem Wortschatz der sauberen Textlayer (T1–T3) sicher ableiten lässt:

* ``ı`` (i ohne Punkt) kommt im Deutschen nicht vor → ``i``.
* Umlaute: Ein Wort, das im sauberen Wortschatz **nicht** vorkommt, dessen
  entumlautete Form aber genau einem Wort des Wortschatzes entspricht, wird
  durch dieses ersetzt (``Grunden`` → ``Gründen``, ``Muller`` → ``Müller``).
  Kommt das gelesene Wort selbst im Wortschatz vor (``mochte``/``möchte``,
  ``Masse``/``Maße``), bleibt es stehen – hier kann nur der Blick aufs
  Seitenbild entscheiden.
* Paragrafenzeichen: die OCR liest ``§`` als ``$``, ``&`` oder ``8`` (und
  ``§§`` als ``88``, ``$$``, ``$&``), teils mit der folgenden Ziffer
  zusammengeklebt (``84 Abs. 1`` = ``§ 4 Abs. 1``).
* Aufzählungszeichen: das Quadrat der Hefte wird zu ``m``, ``=``, ``u``,
  ``«`` … gelesen → ``– `` (wie im PL-Parser).
* Punkteklammern mit geschweiften Klammern ``{6 Punkte}`` → ``(6 Punkte)``.

Der Wortschatz wird beim ersten Aufruf aus den Textlayern der Termine ohne
``scan``-Flag und aus den Inhalten der Web-App (``data/*.js``) aufgebaut.
"""
import os, re, sys
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))

WORT = re.compile(r'[A-Za-zÄÖÜäöüß]+(?:-[A-Za-zÄÖÜäöüß]+)*')
_FOLD = str.maketrans({'ä': 'a', 'ö': 'o', 'ü': 'u', 'Ä': 'A', 'Ö': 'O', 'Ü': 'U'})


def falten(w):
    """Umlaute und ß auf die OCR-Lesart abbilden (Schlüssel des Wortschatzes)."""
    return w.translate(_FOLD).replace('ß', 'ss')


_vokabular = None      # Wort -> Häufigkeit
_je_schluessel = None  # gefaltetes Wort -> Counter der echten Formen


def _quellen_texte():
    import parse_imbq as P
    for jg, cfg in P.JAHRGAENGE.items():
        if cfg.get('scan'):
            continue
        d = P.quellen(jg)
        if not os.path.isdir(d):
            continue
        for fn in sorted(os.listdir(d)):
            if not fn.endswith('.txt') or fn in cfg.get('ocr', ()):
                continue
            yield open(os.path.join(d, fn), encoding='utf-8').read()
    for fn in ('questions.js', 'cases.js'):
        p = os.path.join(ROOT, 'data', fn)
        if os.path.exists(p):
            yield open(p, encoding='utf-8').read()


def wortschatz():
    global _vokabular, _je_schluessel
    if _vokabular is None:
        _vokabular = Counter()
        _je_schluessel = defaultdict(Counter)
        for text in _quellen_texte():
            for w in WORT.findall(text):
                _vokabular[w] += 1
        for w, n in _vokabular.items():
            _je_schluessel[falten(w)][w] += n
    return _vokabular, _je_schluessel


# Wörter, die auch entumlautet im Wortschatz stehen (Tippfehler, Fremdwörter),
# in den Heften aber immer die Umlautform meinen.
IMMER = {'Stuck': 'Stück', 'Sauren': 'Säuren', 'Gross': 'Groß', 'TUV': 'TÜV',
         'Grunde': 'Gründe', 'Hohe': 'Höhe', 'Losung': 'Lösung',
         'Prufung': 'Prüfung', 'fur': 'für', 'Fur': 'Für'}


ALPHABET = 'abcdefghijklmnopqrstuvwxyzäöüß'
# Verwechslungsklassen der OCR (Ersetzungen nur innerhalb einer Klasse)
KLASSEN = ['iltrj', 'eaocäö', 'nuhü', 'sz', 'vy', 'mw']
# Nur „dünne“ Buchstaben gehen verloren oder kommen hinzu.
DUENN_WEG, DUENN_HINZU = 'ilrfj', 'iltrfj'


def _nachbarn(w):
    """Alle Wörter im Abstand 1 (ein Zeichen ersetzt, eingefügt, gelöscht)."""
    for i in range(len(w) + 1):
        for c in ALPHABET:
            yield w[:i] + c + w[i:]
            if i < len(w):
                yield w[:i] + c + w[i + 1:]
        if i < len(w):
            yield w[:i] + w[i + 1:]


def _plausibel(w, k):
    """Ist k ein typischer OCR-Lesefehler von w?

    Flexionsendungen (Risikos/Risiko, zeigten/zeigen) sind keine Lesefehler –
    der Unterschied darf nicht in den letzten zwei Zeichen liegen, und nur
    dünne Buchstaben fehlen oder kommen hinzu; Ersetzungen bleiben innerhalb
    der Verwechslungsklassen (i/l/t, e/a/o, n/u/h, …).
    """
    if w[0].isupper() != k[0].isupper():
        return False
    i = 0
    while i < min(len(w), len(k)) and w[i] == k[i]:
        i += 1
    if i >= min(len(w), len(k)) - 1 and len(w) != len(k):
        return False                     # Unterschied nur am Wortende
    if len(w) == len(k):                 # Ersetzung
        if i >= len(w) - 2 or w[i + 1:] != k[i + 1:]:
            return False
        a, b = w[i].lower(), k[i].lower()
        return any(a in kl and b in kl for kl in KLASSEN)
    if len(w) == len(k) + 1:             # in w ein Zeichen zu viel
        if w[:i] + w[i + 1:] != k or i >= len(k) - 1:
            return False
        return w[i].lower() in DUENN_WEG or (i > 0 and w[i] == w[i - 1])
    if len(k) == len(w) + 1:             # in w fehlt ein Zeichen
        if k[:i] + k[i + 1:] != w or i >= len(w) - 1:
            return False
        return k[i].lower() in DUENN_HINZU
    return False


def wort_korrigieren(w, protokoll=None):
    """Ein Wort ohne (verlorene) Umlautpunkte auf seine Wortschatzform bringen."""
    vok, je = wortschatz()
    if w in IMMER:
        return IMMER[w]
    if w in vok or len(w) < 3 or not w.isalpha():
        return w
    kand = je.get(falten(w))
    if not kand:
        # Kein Umlautfall. Ein einzelner Lesefehler („Betreb“, „disse“, „etne“)
        # wird nur ersetzt, wenn genau ein häufiges Wort im Abstand 1 liegt –
        # Namen (Schmeider/Schneider) sind das Risiko, deshalb die Hürden.
        if len(w) < 5:
            return w
        treffer = {n for n in _nachbarn(w)
                   if vok.get(n, 0) >= 20 and _plausibel(w, n)}
        if len(treffer) == 1:
            best = treffer.pop()
            if protokoll is not None:
                protokoll[(w, best)] += 1
            return best
        return w
    best, n = kand.most_common(1)[0]
    if best == w or n < 2 or best == falten(w):
        return w
    # Nur ergänzen, nie Groß-/Kleinschreibung oder Länge ändern (außer ß).
    if best[0].isupper() != w[0].isupper():
        return w
    if protokoll is not None:
        protokoll[(w, best)] += 1
    return best


# ---------------------------------------------------------------- Paragrafen
GESETZ = (r'(?:Abs\b|Absatz|Satz\b|Nr\b|ff\b|S\.|i\.\s?V\.\s?m|'
          r'[A-ZÄÖÜ][A-Za-zÄÖÜäöü]*G\b|SGB|StGB|ZPO|GewO|HGB|BGB|GG|UrhG)')
# „$ 4 Absatz“, „& 106 UrhG“, „8 8 Abs. 1“, „88 53, 54 UrhG“ (= §§)
FOLGE = r'\d+[a-z]?\s*(?:(?:,|und|bis|-|–)\s*\d+[a-z]?\s*)*'
PARA_2 = re.compile(r'(?<![\w§.,])(?:\$\$|\$&|&\$|&&|88|85|8\$|\$8|&8)\s*(?=' + FOLGE + GESETZ + ')')
PARA_1 = re.compile(r'(?<![\w§.,])(?:\$|&|8)\s+(?=' + FOLGE + GESETZ + ')')
# „$“ und „&“ vor einer Zahl sind immer ein Paragrafenzeichen – auch am
# Zeilenende („… sein, & 8“ / „Nach $ 3“), wo das Gesetz erst in der nächsten
# Zeile folgt. „8“ bleibt dort bewusst außen vor (Zahlen!).
PARA_LOS = re.compile(r'(?<![\w§])[$&]\s*(?=\d)')
# „gemäß 84“ am Zeilenende (Gesetz auf der Folgezeile)
PARA_ENDE = re.compile(r'((?:[Gg]emäß|laut|i\.\s?V\.\s?m\.|,)\s+)(?:8)(\d{0,3}[a-z]?)\s*$')
# zusammengeklebt: „84 Abs. 1“ → „§ 4 Abs. 1“, „887 Abs.“ → „§ 87 Abs.“
PARA_KLEB = re.compile(r'(?<![\w§.,])(?:\$|&|8)(\d{1,3}[a-z]?)\s+(?=' + GESETZ + ')')
# in der Verordnungsangabe „[VO: 8 4 Absatz 2 Nr. 1]“
PARA_VO = re.compile(r'(\[VO:\s*)(?:\$|&|8)\s*(?=\d)')

# Kopf- und Fußzeilen der gescannten Seiten – in vielen Lesarten.
SCAN_JUNK = re.compile(
    r'^(?:\W?E?GEPR[ÜU]FTE|\W?E?PR[ÜU]FTEI|FACHRICHTUNGS|BASISQUALIFIKATIONEN\s*$'
    r'|GRUNDLEGENDE QUALIFIKATIONEN\s*$|Grundlegende Qualifikationen,'
    r'|Information, Kommunikation und Planung\s*$|Anwendung ?von ?Methoden ?der'
    r'|\|?\s*Seite\s+\S{1,3}\s*(?:[|}\]]|$|©|DIHK)|\W{0,2}\s*DIHK\b|Die Vervielf.*Publikation'
    r'|ist \w+ gest\w+tet\b|und strafbar\b|\|?\s*[PL]\s?\d{3}-\d{2}-\d{4}-\d)')

BULLET = re.compile(r'^(?:[m=u«»■•®°*eaws&_]|m=|=m|s=|wm|mm|ms|sm|sw|ws|za|--|—|-)(?:\s+_)?\s+(?=\S)')
KLAMMER = re.compile(r'\{\s*(\d+)\s*Punkte?\s*[)}]|\(\s*(\d+)\s*Punkte?\s*\}')


def zeile(l, protokoll=None, fortsetzung=False):
    """Eine Zeile eines Scan-Textlayers geradeziehen.

    ``fortsetzung``: die Zeile davor endet mit Trennstrich – das erste Wort ist
    dann ein Wortrest („Vor-“ / „gaben“) und bleibt unangetastet."""
    if SCAN_JUNK.match(l.strip()):
        return ''
    l = l.replace('ı', 'i').replace('İ', 'I').replace('\\W', 'W').replace('\\V', 'W')
    l = PARA_VO.sub(r'\1§ ', l)
    l = PARA_2.sub('§§ ', l)
    l = PARA_1.sub('§ ', l)
    l = PARA_KLEB.sub(r'§ \1 ', l)
    l = PARA_LOS.sub('§ ', l)
    l = PARA_ENDE.sub(lambda m: m.group(1) + '§ ' + m.group(2), l)
    l = l.replace('Urh@', 'UrhG')
    l = re.sub(r'§\s*§\s+(\d)', r'§ 8\1', l)          # die 8 als § gelesen
    l = re.sub(r'(§\s*\d+[a-z]?)\s+\|\s+', r'\1 I ', l)  # Absatz I als Strich
    l = re.sub(r'(§\s*\d+[a-z]?\s+)(I?l{1,2}|lI|Ill)\b',
               lambda m: m.group(1) + m.group(2).replace('l', 'I'), l)
    # Euro: „15,50 &/Stunde“, „56,50 €&/Stück“, „204,60 &“
    l = re.sub(r'€?&(?=/)', '€', l)
    l = re.sub(r'(?<=\d)\s*€?&(?=\s|$)', ' €', l)
    # Teil-Marker: „d}“, „e})“, „ec)“ (= c) mit Bullet-Rest), „a )“
    l = re.sub(r'^([a-h])\s*\\?[})]\)?\s', r'\1) ', l)
    l = re.sub(r'^[eo]([a-h])\)\s', r'\1) ', l)
    l = re.sub(r'^€\)\s', 'c) ', l)
    l = KLAMMER.sub(lambda m: '(%s Punkte)' % (m.group(1) or m.group(2)), l)
    l = re.sub(r'\((\d+)\s*Punktes\)', r'(\1 Punkte)', l)
    l = BULLET.sub('– ', l)
    # „Erist“, „Ersollte“: das Pronomen klebt am Verb
    l = re.sub(r'\bEr(ist|hat|kann|wird|muss|soll|sollte|darf|war)\b', r'Er \1', l)
    l = WORT.sub(lambda m: m.group(0)
                 if l[m.end():m.end() + 1] == '-' or (fortsetzung and m.start() == 0)
                 else wort_korrigieren(m.group(0), protokoll), l)
    return l


# ------------------------------------------------- abgetrennte Punktespalte
# Tesseract liest die Punktespalte am rechten Rand oft als eigenen Block und
# hängt sie **hinter die Fußzeile** der Seite: „(6 Punkte) / (8 Punkte) /
# (14 Punkte) / (6 Punkte) / (8 Punkte)“ – in Lesereihenfolge die Klammern der
# Teilaufgaben, des Lösungskopfs und der Lösungsteile. Sie werden hier den
# klammerlosen Markern der Seite von oben nach unten zugeteilt, sofern die
# Zahl genau aufgeht; sonst bleibt die Seite unverändert (→ ROHTEXT).
TOKEN = re.compile(r'[({]\s*(\d+)\s*Punkte?\s*[)}]')
NUR_TOKEN = re.compile(r'^\s*[({]\s*\d+\s*Punkte?\s*[)}]\s*$')
# Fußzeile – auch die Variante „Seite 24 | P 050-02-0516-7 |“ ohne DIHK.
FUSS = re.compile(r'^(?:©?\s*DIHK\b|Die Vervielfältigung|ist nicht gestattet|Einsatz nur im Rahmen'
                  r'|\|?\s*Seite\s+\d+\s*\||\|?\s*[PL]\s?\d{3}-\d{2}-\d{4}-\d)')
SLOT = re.compile(r'^(?:[eo]?[a-h]\s*[)}]\)?\s|L[öo]sungshinweise\s+Aufgabe\b)')
SEITE = re.compile(r'^=== Seite \d+ ===')


KOPF = re.compile(r'^L[öo]sungshinweise\s+Aufgabe\b')
UEBERSCHRIFT = re.compile(r'^Aufgabe\b')


def spalte_zuordnen(zeilen):
    out, seite = [], []

    def flush():
        fuss = next((i for i, l in enumerate(seite) if FUSS.match(l)), None)
        if fuss is not None:
            hinten = [i for i in range(fuss, len(seite)) if NUR_TOKEN.match(seite[i])]
            if not hinten:
                # Die Spalte kann auch mitten auf der Seite stehen: der längste
                # Lauf aus Klammerzeilen (nur Leerzeilen dazwischen).
                lauf, bester = [], []
                for i in range(fuss):
                    if NUR_TOKEN.match(seite[i]):
                        lauf.append(i)
                    elif seite[i].strip():
                        bester = max(bester, lauf, key=len); lauf = []
                bester = max(bester, lauf, key=len)
                if len(bester) >= 2:
                    hinten = bester
            # Slots mit ihrer Art: Frage (q), Lösungskopf (k), Lösung (l).
            # Ein Slot ist besetzt, wenn in seinem Abschnitt (bis zum nächsten
            # Slot) schon eine Klammer steht – auch auf einer Folgezeile; die
            # Zeilen der abgetrennten Spalte selbst zählen dabei nicht.
            starts = [i for i in range(fuss) if SLOT.match(seite[i])]
            abschnitt = {}
            for k, i in enumerate(starts):
                e = starts[k + 1] if k + 1 < len(starts) else fuss
                abschnitt[i] = any(TOKEN.search(seite[j]) for j in range(i, e)
                                   if j not in set(hinten))
            slots, art = [], 'l'
            for i in range(fuss):
                if UEBERSCHRIFT.match(seite[i]):
                    art = 'q'
                elif KOPF.match(seite[i]):
                    art = 'k'
                if i in abschnitt and not abschnitt[i]:
                    slots.append((i, art))
                    if art == 'k':
                        art = 'l'
            passt = hinten and len(hinten) == len(slots)
            if hinten and len(hinten) > len(slots):
                # Mehr Klammern als Slots: die Lösungsteile tragen Teilpunkte
                # („(2 Punkte)“ je Spiegelstrich). Zuteilen von oben, wenn die
                # Seite mit dem Frageteil beginnt – die Punkte der Lösungsteile
                # zählen ohnehin nicht (parse_imbq_alt übernimmt die des
                # Frageteils), überzählige Klammern verfallen.
                arten = ''.join(a for _, a in slots)
                passt = arten == ''.join(sorted(arten, key='qkl'.index)) and 'q' in arten
            if passt:
                for (si, _), ti in zip(slots, hinten):
                    seite[si] = seite[si].rstrip() + ' ' + seite[ti].strip()
                for ti in reversed(hinten):
                    del seite[ti]
        out.extend(seite)
        seite.clear()

    for l in zeilen:
        if SEITE.match(l):
            flush()
        seite.append(l)
    flush()
    return out


def klammern(l):
    """Punkteklammern vereinheitlichen – vor der Spaltenzuordnung, die sie
    erkennen muss: „{6 Punkte)“, „(6 Punkte}“, „(2 Punktes)“, „(B Punkte)“."""
    l = re.sub(r'[({]\s*B\s*Punkte?\s*[)}]', '(8 Punkte)', l)
    l = KLAMMER.sub(lambda m: '(%s Punkte)' % (m.group(1) or m.group(2)), l)
    return re.sub(r'\((\d+)\s*Punktes\)', r'(\1 Punkte)', l)


def zeilen(roh, protokoll=None):
    """Alle Zeilen eines Textlayers geradeziehen und die Punktespalte zuordnen."""
    out, vorher = [], ''
    # erst die Punktespalte (braucht die Fußzeile als Anker), dann die Zeilen
    for l in spalte_zuordnen([klammern(l) for l in roh]):
        out.append(zeile(l, protokoll, fortsetzung=vorher.rstrip().endswith('-')))
        if l.strip():
            vorher = l
    return out


def datei(pfad, protokoll=None):
    return zeilen(open(pfad, encoding='utf-8').read().split('\n'), protokoll)


if __name__ == '__main__':
    # Probelauf: python3 ocr_scan.py quellen/imbq-h2017/01-recht.txt [--diff]
    prot = Counter()
    for p in [a for a in sys.argv[1:] if not a.startswith('--')]:
        alt = open(p, encoding='utf-8').read().split('\n')
        neu = datei(p, prot)
        if '--diff' in sys.argv:
            for a, b in zip(alt, neu):
                if a != b:
                    print('- ' + a); print('+ ' + b)
        else:
            print('\n'.join(neu))
    if '--diff' in sys.argv or '--stat' in sys.argv:
        print('\nErsetzungen (%d):' % sum(prot.values()), file=sys.stderr)
        for (a, b), n in prot.most_common():
            print('  %4d  %s → %s' % (n, a, b), file=sys.stderr)
