# -*- coding: utf-8 -*-
"""Zerlegt die IHK-Basisqualifikations-Prüfungen (Industriemeister) in
Aufgaben samt amtlichen Lösungshinweisen.

Quelle: ``quellen/imbq-<jahrgang>/*.txt`` – Textlayer der PDFs
(``pdftotext -layout``) mit Seitenmarkern. Aufbau je Datei: Deckblatt,
Aufgabenteil, dann ab einer Zeile, die nur ``Lösungshinweise`` enthält, der
Lösungsteil (Bauform PL, alle Termine ab Frühjahr 2023). Die Termine Frühjahr
2019 bis Herbst 2022 setzen die Lösung stattdessen hinter jede Aufgabe (Bauform
L-I); ``teilen()`` bringt beide auf dieselbe Form. ``JAHRGAENGE`` hält die
übrigen Unterschiede (Verzeichnis, Prüfungshefte, Korrekturdatei). Termine bis
Herbst 2018 sind noch einmal anders aufgebaut – siehe
``docs/PLAN-altklausuren-und-aufgabenblatt.md``, Teil A.

Anders als bei den Kraftverkehr-Prüfungen ist der Buchstabe vor
``Mögliche Punktzahl`` optional (Aufgaben ohne Teilaufgaben) und kommt auch
groß vor (``D Mögliche Punktzahl: 3``).
"""
import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import layout_struktur as LS

# Datei -> (Kürzel, Bezeichnung der Basisqualifikation, App-Fach)
RECHT  = ('01-recht.txt',          'RE', 'Rechtsbewusstes Handeln', 1)
BWL    = ('02-bwl.txt',            'BW', 'Betriebswirtschaftliches Handeln', 2)
METHOD = ('03-methoden.txt',       'MI', 'Methoden der Information, Kommunikation und Planung', 3)
ZUSAMM = ('04-zusammenarbeit.txt', 'ZI', 'Zusammenarbeit im Betrieb', 4)
NTG    = ('05-ntg.txt',            'NT',
          'Naturwissenschaftliche und technische Gesetzmäßigkeiten', 5)

# Prüfungstermine: Verzeichnis, Hefte und die zugehörige Korrekturdatei.
# ``format``   fehlt (PL/L-I) oder 'alt' – siehe parse_imbq_alt.py
# ``scan``     Textlayer stammt aus Tesseract, nicht aus dem PDF
# ``ocr``      einzelne Hefte eines sonst sauberen Termins als Scan
# ``in_arbeit`` noch nicht abgenommen: build_imbq.py lässt den Termin aus,
#              parse_imbq.py liest ihn trotzdem (Arbeitsstand sichtbar halten)
JAHRGAENGE = {
    # Frühjahr 2019 bis Herbst 2022: Bauform L-I (Lösung hinter jeder Aufgabe).
    'f2019': {'dir': 'imbq-f2019', 'korrekturen': 'korrekturen_imbq_f2019',
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    'h2019': {'dir': 'imbq-h2019', 'korrekturen': 'korrekturen_imbq_h2019',
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    'f2020': {'dir': 'imbq-f2020', 'korrekturen': 'korrekturen_imbq_f2020',
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    'h2020': {'dir': 'imbq-h2020', 'korrekturen': 'korrekturen_imbq_h2020',
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    'f2021': {'dir': 'imbq-f2021', 'korrekturen': 'korrekturen_imbq_f2021',
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    # Herbst 2021: das ZiB-Heft liegt nur als Scan vor (kein Textlayer),
    # der Textlayer stammt aus Tesseract – siehe ocr_zeile().
    'h2021': {'dir': 'imbq-h2021', 'korrekturen': 'korrekturen_imbq_h2021',
              'ocr': {'04-zusammenarbeit.txt'},
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    'f2022': {'dir': 'imbq-f2022', 'korrekturen': 'korrekturen_imbq_f2022',
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    'h2022': {'dir': 'imbq-h2022', 'korrekturen': 'korrekturen_imbq_h2022',
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    # Herbst 2023: das Heft "Methoden …" fehlt im Archiv (die abgelegte Datei
    # ist ein Doppel der ZiB-Prüfung desselben Termins).
    # Herbst 2014 bis Herbst 2017: Bauform L-ALT, aber nur als Scan – der
    # Textlayer stammt aus Tesseract.
    'h2014': {'dir': 'imbq-h2014', 'korrekturen': 'korrekturen_imbq_h2014',
              'format': 'alt', 'scan': True,
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    'f2015': {'dir': 'imbq-f2015', 'korrekturen': 'korrekturen_imbq_f2015',
              'format': 'alt', 'scan': True,
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    'h2015': {'dir': 'imbq-h2015', 'korrekturen': 'korrekturen_imbq_h2015',
              'format': 'alt', 'scan': True,
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    'f2016': {'dir': 'imbq-f2016', 'korrekturen': 'korrekturen_imbq_f2016',
              'format': 'alt', 'scan': True,
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    'h2016': {'dir': 'imbq-h2016', 'korrekturen': 'korrekturen_imbq_h2016',
              'format': 'alt', 'scan': True,
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    'f2017': {'dir': 'imbq-f2017', 'korrekturen': 'korrekturen_imbq_f2017',
              'format': 'alt', 'scan': True,
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    'h2017': {'dir': 'imbq-h2017', 'korrekturen': 'korrekturen_imbq_h2017',
              'format': 'alt', 'scan': True,
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    # Frühjahr und Herbst 2018: Bauform L-ALT (Punktzahl in Klammern am
    # rechten Rand, Lösung hinter jeder Aufgabe) – siehe parse_imbq_alt.py.
    'f2018': {'dir': 'imbq-f2018', 'korrekturen': 'korrekturen_imbq_f2018',
              'format': 'alt',
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    'h2018': {'dir': 'imbq-h2018', 'korrekturen': 'korrekturen_imbq_h2018',
              'format': 'alt',
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    'f2023': {'dir': 'imbq-f2023', 'korrekturen': 'korrekturen_imbq_f2023',
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    'h2023': {'dir': 'imbq-h2023', 'korrekturen': 'korrekturen_imbq_h2023',
              'pruefungen': [RECHT, BWL, ZUSAMM, NTG]},
    'f2024': {'dir': 'imbq-f2024', 'korrekturen': 'korrekturen_imbq_f2024',
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    'h2024': {'dir': 'imbq-h2024', 'korrekturen': 'korrekturen_imbq_h2024',
              'pruefungen': [RECHT, BWL, METHOD, ZUSAMM, NTG]},
    'h2025': {'dir': 'imbq-h2025', 'korrekturen': 'korrekturen_imbq',
              'pruefungen': [RECHT, BWL, ZUSAMM, NTG]},
}
STANDARD = 'h2025'


def quellen(jahrgang):
    return os.path.join(HERE, 'quellen', JAHRGAENGE[jahrgang]['dir'])

PAGE    = re.compile(r'^=== Seite (\d+) ===\s*$')
# Das Deckblatt nennt den Prüfungstag je nach Heftform als "Datum:" (PL, L-I)
# oder als "Prüfungstag" (L-ALT).
DATUM   = re.compile(r'(?:Datum:|Pr[üu]fungstag)\s*(\d{1,2}\.\s*\w+\s*\d{4})')
AUFG    = re.compile(r'^Aufgabe\s+(\d+)$')
LOES_A  = re.compile(r'^L[öo]sungshinweise\s+Aufgabe\s+(\d+)$')
LOES_TL = re.compile(r'^L[öo]sungshinweise$')
# Buchstabe optional und case-insensitiv – siehe Modul-Doku.
# "Mögliche Punktzahl: 8" – ein Heft schreibt "Punktezahle" (NTG F2023, A2),
# ein anderes lässt den Doppelpunkt weg (BWL H2019, A7a); ohne diese Toleranzen
# fiele die Teilaufgabe samt ihrer Punkte weg.
PUNKTE  = re.compile(r'^(?:([a-hA-H])\s+)?M[öo]gliche\s+Punkte?zahle?:?\s*(\d+)$')
# Bis 2015 steht der Verweis in runden Klammern und mal als „RVO“ ohne
# Doppelpunkt: „(VO: § 4 Abs. 2 Nr. 1-2)“, „(RVO § 4 Absatz 2 Nr. 1)“.
VO      = re.compile(r'^[\[(]?\s*R?VO:?\s*(.+?)\s*[\])]?$')
# Anlagen stehen physisch hinter der letzten Aufgabe, gehören aber zu einer
# früheren – ihr Block darf nicht in den Text der letzten Aufgabe rutschen.
ANLAGE  = re.compile(r'^Anlage\s+\d+\s+zu\s+Aufgabe\s+\d+', re.I)
# Gleiches auf der Lösungsseite: 'Lösungshinweis(e) zu Aufgabe N' ist die
# Anlagen-Lösung und steht hinter der letzten Aufgabe. Einzahl (H2025) wie
# Mehrzahl (H2024) kommen vor.
ANLAGE_L = re.compile(r'^L[öo]sungshinweise?\s+zu\s+Aufgabe\s+\d+', re.I)

def vo_norm(vo):
    """Verordnungsverweis vereinheitlichen: führendes §, Leerzeichen vor Nr."""
    vo = re.sub(r'^\s*§?\s*', '§ ', vo).strip()
    return re.sub(r'(\d)(Nr\.)', r'\1 \2', vo)

MON = {'januar':1,'februar':2,'märz':3,'april':4,'mai':5,'juni':6,'juli':7,
       'august':8,'september':9,'oktober':10,'november':11,'dezember':12}

# Seiten-Deko, Wasserzeichen und Kopfzeilen, die der Textlayer mitliefert.
JUNK = re.compile(
    r'^(Einsatz nur im Rahmen des Korrekturprozesses.*'
    r'|Im Fall der Zuwiderhandlung wird Strafantrag gestellt\.?'
    # Die Kopfzeile jeder Seite. Im MIKP-Heft Herbst 2018 ist sie zweimal
    # leicht versetzt gesetzt; pdftotext liest daraus Bruchstücke
    # ("GEPRÜFTE/-RR INDUSTRIEMEISTER/", "IFENDEBASISQUALIFIK"). Die Muster
    # sind deshalb absichtlich weit – so beginnt keine echte Textzeile.
    r'|GEPR[ÜU]FTE/-.*'
    r'|INDUSTRIEMEISTER/-?IN,?'
    r'|FACHRICHTUNGS[ÜU]BERGRE.*'
    r'|IFENDEBASISQUALIFIK.*'
    r'|(?:GRUNDLEGENDE )?QUALIFIKATIONEN'
    r'|Bundeseinheitliche Fortbildungspr[üu]fung.*'
    r'|Gepr[üu]fter Industriemeister.*'
    r'|Seite \d+'
    # Heftnummer der Fußzeile, mit und ohne angehängte Prüfziffer:
    # "L 050-01-0519-7" (Termine bis 2022) wie "P 050-05-1123" (ab 2023).
    r'|[LP] \d{3}-\d{2}-\d{4}(?:-\d+)?'
    r'|Pr[üu]fungsteilnehmer-Nummer.*'
    r'|Ber[üu]cksichtigung naturwissenschaftlicher und technischer Gesetzm[äa][ßs]igkeiten'
    r'|Anwendung von Methoden der Information,.*'
    # Fußzeile und Urheberrechtshinweis der L-ALT-Hefte. Sie stehen dort auf
    # jeder Seite und landeten sonst mitten im Aufgaben- und Lösungstext.
    r'|\|?\s*Seite \d+\s*\|.*'
    r'|\|\s*[LP] \d{3}-\d{2}-\d{4}.*'
    r'|©\s*DIHK.*'
    r'|Die Vervielf[äa]ltigung, Verbreitung oder [öo]ffentliche Wiedergabe.*'
    r'|ist nicht gestattet \(§§ 53, 54 UrhG\).*'
    r'|strafbar \(§ 106 UrhG\).*'
    r'|Bundeseinheitliche Weiterbildungspr[üu]fung.*'
    r'|der Industrie- und Handelskammern'
    r'|Hinweise f[üu]r den Korrektor:'
    r'|M[öo]gliche Punktzahl:?\s*'
    r'|\d{1,3})$', re.I)

# Word setzt Formeln in der Symbol-Schrift; pdftotext liefert deren Zeichen im
# Privatbereich U+F0xx. Die Codes sind die der Adobe-Symbol-Kodierung: der
# Bereich 0x20–0x7E deckt sich in der Anordnung mit ASCII, die Buchstaben stehen
# dort aber für griechische.
#
# Ohne diese Tabelle verschwinden die Rechenzeichen: ``clean()`` wirft alles aus
# dem Privatbereich weg, was nicht übersetzt wurde – und damit allein in den
# Basisqualifikations-Heften 845 Gleichheitszeichen, 124 Plus und 91 Minus.
# Aus "σz,zul = Fzul ÷ S" wurde so "z, zul Fzul S".
_SYMBOL_0X20 = (' !∀#∃%&∋()∗+,−./0123456789:;<=>?'
                '≅ΑΒΧΔΕΦΓΗΙϑΚΛΜΝΟΠΘΡΣΤΥςΩΞΨΖ[∴]⊥_'
                '‾αβχδεφγηιϕκλμνοπθρστυϖωξψζ{|}∼')
SYMBOL = {chr(0xF020 + i): z for i, z in enumerate(_SYMBOL_0X20)}
SYMBOL.update({
    '\uf0a3': '≤',  '\uf0a7': '•',  '\uf0ae': '→',  '\uf0b0': '°',
    '\uf0b1': '±',  '\uf0b3': '≥',  '\uf0bb': '≈',  '\uf0c6': 'Ø',
    '\uf0d6': '√',  '\uf0d7': '·',  '\uf0de': '→',  '\uf0e5': '∑',
    # Die sechs Teilstücke großer Klammern tragen keine Bedeutung.
    '\uf0e6': '', '\uf0e7': '', '\uf0e8': '',
    '\uf0f6': '', '\uf0f7': '', '\uf0f8': '',
})

def clean(line):
    l = re.sub(r'\s{2,}', ' ', line).strip()
    l = re.sub(r'^■\s*', '– ', l)
    for k, v in SYMBOL.items():
        if k in l:
            l = l.replace(k, v)
    l = l.replace(' o ', ' → ')   # OCR-Pfeil in Reaktionsgleichungen
    # Was danach noch aus dem Privatbereich übrig ist, trägt keine Information.
    l = re.sub(r'[\ue000-\uf8ff]', '', l)
    return re.sub(r'\s{2,}', ' ', l).strip()

# Das Punkte-Badge steht gelegentlich über zwei Zeilen: "a Mögliche Punktzahl:"
# und darunter die Zahl, mitunter mit einem Strich davor (NTG H2023, Aufgabe 4).
# Ohne Zusammenführung fehlt die Teilaufgabe komplett und die Prüfung kommt
# nicht auf 100 Punkte.
BADGE_OHNE_ZAHL = re.compile(r'^(?:[a-hA-H]\s+)?M[öo]gliche\s+Punktzahl:?\s*$')
NUR_ZAHL = re.compile(r'^[-–—•■\s]*(\d+)\s*$')


# ------------------------------------------------------------ OCR-Textlayer
# Einzelne Hefte liegen nur als Scan vor (ZiB Herbst 2021: ein Word-Dokument
# mit eingebetteten Seitenbildern, ohne Textebene). Tesseract liest den Aufbau
# zuverlässig, verhaspelt sich aber an zwei Stellen immer gleich:
#
# * Der graue Kasten mit dem Teil-Buchstaben wird zu Zeichensalat
#   (``EB``, ``[e|``, ``Il``, ``2]`` …) und „Punktzahl“ gelegentlich zu
#   „Punktzanı“. Beides wird auf die kanonische Badge-Zeile **ohne** Buchstaben
#   gebracht: Frage- und Lösungsteil stehen in derselben Reihenfolge im Heft,
#   also vergibt ``split_teile`` die Labels nach Position – und zwar auf beiden
#   Seiten gleich. Einen Buchstaben stehen zu lassen wäre schlechter: ein
#   einziges falsch gelesenes Zeichen verschiebt die Zuordnung.
# * Das Paragrafenzeichen wird als ``$`` oder ``8`` gelesen.
OCR_BADGE = re.compile(
    r'^(?:[^\s]{1,3}\s+){0,2}[Mm][öo]\w*e\s+Punkt\w*:\s*(\d+)\s*$')
OCR_PARA = re.compile(r'(?<![\w§])[$8]\s*(?=\d+\s+Absatz)')


def ocr_zeile(l):
    """Eine Zeile aus einem OCR-Textlayer geradeziehen."""
    l = OCR_PARA.sub('§ ', l)
    m = OCR_BADGE.match(l)
    return 'Mögliche Punktzahl: %s' % m.group(1) if m else l


def _aehnlich(a, b):
    """Kopfzeile in OCR-Lesart („Betriehswirtschaftliches Handeln“)."""
    import difflib
    return abs(len(a) - len(b)) <= 3 and \
        difflib.SequenceMatcher(None, a.lower(), b.lower()).ratio() >= 0.9


def load(path, bezeichnung, ocr=False, scan=False, rohtext=()):
    """Zeilen laden, Deko/Wasserzeichen entfernen.

    ``scan``: Textlayer eines gescannten Hefts (T4) – vorab durch die
    Nachbesserung in ``ocr_scan`` (i-Punkte, Umlaute, Paragrafen).
    ``rohtext``: Paare (alt, neu) aus der ``ROHTEXT``-Tabelle des
    Korrekturmoduls, die vor allem anderen im Rohtext ersetzt werden; jedes
    Paar muss genau einmal greifen."""
    text = open(path, encoding='utf-8').read()
    for alt, neu in rohtext:
        assert text.count(alt) == 1, \
            'ROHTEXT-Korrektur greift %d-mal statt einmal in %s: %r' % (
                text.count(alt), os.path.basename(path), alt[:60])
        text = text.replace(alt, neu)
    raw_lines = text.split('\n')
    if scan:
        import ocr_scan
        raw_lines = ocr_scan.zeilen(raw_lines)
    elif not ocr:
        # Textlayer aus dem PDF: Spalten sind noch da. Brüche und Tabellen
        # jetzt retten – clean() presst jede Zeile auf einfache Leerzeichen.
        raw_lines = struktur(raw_lines, path, bezeichnung)
    out = []
    for raw in raw_lines:
        if PAGE.match(raw):
            continue
        l = clean(raw)
        if not l:
            continue
        if ocr:
            l = ocr_zeile(l)
        # Vor den JUNK-Filtern: eine alleinstehende Zahl unter einem Badge ohne
        # Punktzahl gehört zu diesem Badge. JUNK verwirft blanke Zahlen
        # (Seitenzahlen), diese hier darf es nicht erwischen.
        m = NUR_ZAHL.match(l)
        if m and out and BADGE_OHNE_ZAHL.match(out[-1]):
            out[-1] = out[-1] + ' ' + m.group(1)
            continue
        if JUNK.match(l):
            continue
        if l == bezeichnung or l.lower() == bezeichnung.lower():
            continue
        if scan and _aehnlich(l, bezeichnung):
            continue
        out.append(l)
    # Datenlisten ("Anschaffungskosten (netto) 43.000 €") – auch in den Scans
    return LS.wertlisten(out, strukturzeile)


def _deko(s):
    """Seitendeko, die keinen Bruch und keine Tabellenzeile bilden kann. Blanke
    Zahlen zählen hier nicht dazu: in Formeln sind sie Nenner ("… ÷ 2")."""
    return bool(s) and bool(JUNK.match(s)) and not re.fullmatch(r'\d{1,3}', s)


def strukturzeile(s):
    """Zeilen, an denen der Parser Aufgaben, Teile und Lösungen erkennt. Sie
    dürfen nicht zu Tabellenzeilen werden."""
    s = s.strip()
    return bool(PUNKTE.match(s) or AUFG.match(s) or LOES_A.match(s)
                or LOES_TL.match(s) or VO.match(s) or ANLAGE.match(s)
                or ANLAGE_L.match(s) or BADGE_OHNE_ZAHL.match(s)
                or DATUM.search(s) or re.match(r'L[öo]sungshinweise\b', s)
                or re.match(r'^[a-hA-H]\s+M[öo]gliche', s))


def struktur(raw_lines, path, bezeichnung=''):
    """Symbolschrift übersetzen, Brüche linearisieren, Tabellen setzen – auf
    den Rohzeilen mit ihren Spalten (siehe layout_struktur.py)."""
    import korrekturen_formeln as KF
    rel = os.path.relpath(path, os.path.join(HERE, 'quellen')).replace(os.sep, '/')
    def deko(s):
        # Der Heft-Titel steht als Kopfzeile auf jeder Seite.
        return _deko(s) or (bool(bezeichnung) and s.lower() == bezeichnung.lower())
    z = [LS.symbole(l, SYMBOL) for l in raw_lines]
    z, _, _ = LS.brueche(z, deko, KF.FORMELN.get(rel), rel, strukturzeile)
    z, _ = LS.tabellen(z, deko, strukturzeile)
    return z

def join_para(lines):
    """Absätze bilden, Silbentrennung am Zeilenende auflösen, Listen trennen."""
    out, buf = [], ''
    zeile = False          # letzter Absatz ist eine Tabellen-/Rechenzeile
    for l in lines:
        # Tabellenzeilen ("a | b") und Rechenzeilen ("x = …") stehen für sich;
        # eine Punkte-Klammer darunter gehört noch zu ihnen.
        if LS.PUNKTE_ANM.match(l) and zeile and not buf:
            out[-1] = out[-1] + ' ' + l
            continue
        # Ein Satz, der in der Zeile davor begonnen hat und klein weitergeht
        # ("… die durchschnittliche Fahrgeschwindigkeit" / "beträgt v = 32 m/min."),
        # bleibt ein Satz.
        fortsetzung = bool(buf) and buf.rstrip()[-1:] not in '.:;!?' \
            and not re.search(r'\(\s*\d+\s*Punkte?\s*\)$', buf) \
            and l[:1].islower() and '|' not in l
        if zeile and not buf and LS.rechen_fortsetzung(out[-1], l):
            out[-1] = LS.zeile_sauber(out[-1] + ' ' + l)
            continue
        if buf and LS.rechen_fortsetzung(buf, l):
            out.append(LS.zeile_sauber(buf + ' ' + l)); buf = ''
            zeile = True
            continue
        if LS.ist_zeile(l) and not fortsetzung:
            if buf: out.append(buf.strip()); buf = ''
            out.append(LS.zeile_sauber(l))
            zeile = True
            continue
        zeile = False
        # Der Hinweis an den Korrektor ist ein eigener Absatz.
        if re.match(r'Hinweise? für den Korrektor', l):
            if buf: out.append(buf.strip())
            buf = l; continue
        if l.startswith('– '):
            if buf: out.append(buf.strip()); buf = ''
            # Trennstrich am Ende: die Fortsetzung gehört noch zum Punkt
            if l.endswith('-'):
                buf = l
            else:
                out.append(l)
            continue
        # „1. Z. B.:“, „2. Zweckaufwand“ nach Satzende: eigener Absatz – ebenso
        # der nächste Punkt einer Aufzählung ("1. … festlegen" / "2. Beteiligte …")
        mn = re.match(r'^(\d{1,2})\.\s+\S', l)
        mb = re.match(r'^(\d{1,2})\.\s', buf) if buf else None
        if mn and (not buf or buf.rstrip()[-1:] in '.:;!?'
                   or (mb and int(mn.group(1)) == int(mb.group(1)) + 1)):
            if buf: out.append(buf.strip())
            buf = l; continue
        if buf.endswith('--'):          # Artefakt dieser Quelle
            buf = buf[:-2] + l
        elif buf.endswith('-'):
            # Ergänzungsstrich („Anfangs- und Endzeitpunkte“) bleibt stehen
            if re.match(r'(?:und|oder|bzw\.|sowie|beziehungsweise)\b', l):
                buf = buf + ' ' + l
            else:
                buf = buf[:-1] + l
        else:
            buf = (buf + ' ' + l).strip() if buf else l
    if buf: out.append(buf.strip())
    return [p for p in out if p]

def split_teile(block, loesung):
    """Block an den Punktzahl-Zeilen in Teilaufgaben zerlegen."""
    idx = [i for i, l in enumerate(block) if PUNKTE.match(l)]
    intro = join_para(block[:idx[0]]) if idx else join_para(block)
    teile = []
    for j, pi in enumerate(idx):
        pe = idx[j+1] if j+1 < len(idx) else len(block)
        m = PUNKTE.match(block[pi])
        label = (m.group(1) or chr(ord('a') + j)).lower()
        seg = block[pi+1:pe]
        eintrag = {'label': label, 'punkte': int(m.group(2))}
        if loesung:
            eintrag['loesung'] = '\n'.join(join_para(seg))
        else:
            eintrag['text'] = '\n'.join(join_para(seg))
        teile.append(eintrag)
    return intro, teile

def aufgaben(block, loesung):
    """Sequenz von 'Aufgabe N'/'Lösungshinweise Aufgabe N' auswerten."""
    marker = LOES_A if loesung else AUFG
    idx = [(i, int(marker.match(l).group(1))) for i, l in enumerate(block) if marker.match(l)]
    res = {}
    for k, (i, nr) in enumerate(idx):
        e = idx[k+1][0] if k+1 < len(idx) else len(block)
        seg = block[i+1:e]
        schnitt = ANLAGE_L if loesung else ANLAGE
        ank = next((x for x, l in enumerate(seg) if schnitt.match(l)), None)
        if ank is not None:
            seg = seg[:ank]
        vo = ''
        if seg and VO.match(seg[0]):
            vo = vo_norm(VO.match(seg[0]).group(1))
            seg = seg[1:]
        intro, teile = split_teile(seg, loesung)
        res[nr] = {'nr': nr, 'intro': '\n'.join(intro), 'teile': teile, 'vo': vo}
    return res

def teilen(lines):
    """Vorspann, Frageteil und Lösungsteil trennen. Zwei Bauformen kommen vor:

    **PL** (Termine ab Frühjahr 2023) – erst alle Aufgaben, dann ab einer Zeile
    ``Lösungshinweise`` alle Lösungen. Ein einziger Schnitt genügt.

    **L-I** (Frühjahr 2019 bis Herbst 2022) – Aufgabe und Lösung stehen
    abwechselnd; ``Lösungshinweise`` ist hier die Überschrift des Deckblatts und
    steht **vor** ``Aufgabe 1``. Geschnitten wird deshalb nicht, sondern
    umsortiert: jede Zeile gehört zu dem Kopf, der zuletzt kam – ``Aufgabe N``
    schaltet auf den Frageteil, ``Lösungshinweise Aufgabe N`` auf den
    Lösungsteil. Danach sehen beide Teile aus wie im PL-Aufbau.

    Der Vorspann (alles vor der ersten Aufgabe) trägt in beiden Bauformen das
    Deckblatt und – nur in Rechtsbewusstes Handeln – die Ausgangssituation.
    """
    erste = next((i for i, l in enumerate(lines) if AUFG.match(l)), len(lines))
    tl = next((i for i, l in enumerate(lines) if LOES_TL.match(l)), None)
    if tl is not None and tl > erste:
        return lines[:erste], lines[:tl], lines[tl:]
    frage, loes, ziel = [], [], None
    for l in lines:
        if AUFG.match(l):
            ziel = frage
        elif LOES_A.match(l):
            ziel = loes
        if ziel is not None:
            ziel.append(l)
    return lines[:erste], frage, loes


def parse_datei(fn, kuerzel, bezeichnung, fach, jahrgang=STANDARD):
    if JAHRGAENGE[jahrgang].get('format') == 'alt':
        import parse_imbq_alt
        return parse_imbq_alt.parse_datei(fn, kuerzel, bezeichnung, fach, jahrgang)
    ocr = fn in JAHRGAENGE[jahrgang].get('ocr', ())
    lines = load(os.path.join(quellen(jahrgang), fn), bezeichnung, ocr)
    kopf = ' '.join(lines[:20])
    m = DATUM.search(kopf)
    datum = m.group(1) if m else None
    vorspann, frage_teil, loes_teil = teilen(lines)
    # Ausgangssituation: von der Überschrift bis zur ersten Aufgabe
    cs = next((i for i, l in enumerate(vorspann)
               if re.match(r'^Ausgangssituation', l, re.I)), None)
    kontext = '\n'.join(join_para(vorspann[cs+1:])) if cs is not None else ''
    A = aufgaben(frage_teil, False)
    L = aufgaben(loes_teil, True)
    return {'kuerzel': kuerzel, 'bezeichnung': bezeichnung, 'fach': fach,
            'jahrgang': jahrgang, 'datum': datum, 'kontext': kontext,
            'aufgaben': A, 'loesungen': L}

def parse_alle(mit_korrekturen=True, jahrgang=STANDARD):
    cfg = JAHRGAENGE[jahrgang]
    exams = [parse_datei(fn, k, b, f, jahrgang) for fn, k, b, f in cfg['pruefungen']]
    if mit_korrekturen:
        modul = __import__(cfg['korrekturen'])
        n = modul.anwenden(exams)
        globals()['_KORREKTUREN'] = globals().get('_KORREKTUREN', 0) + n
    return exams

def datum_teile(d):
    """'3. November 2022' -> (2022, 11, 3); None, wenn nichts zu holen ist."""
    m = re.match(r'(\d{1,2})\.\s*(\w+)\s*(\d{4})', d or '')
    if not m or m.group(2).lower() not in MON:
        return None
    return int(m.group(3)), MON[m.group(2).lower()], int(m.group(1))


def pruefe(ex):
    """100-Punkte-Invariante, Label-Deckung Frage<->Lösung und Prüfungstag."""
    fehler = []
    # Aus dem Datum entstehen Fall-ID und Termin. Ein fehlendes Deckblatt (Scan)
    # oder ein verdrucktes Jahr – NTG Herbst 2022 nennt "3. November 2023" –
    # fiele sonst erst als falsch einsortierte Prüfung auf.
    dt = datum_teile(ex['datum'])
    jg = ex['jahrgang']
    if not dt:
        fehler.append('kein Prüfungsdatum')
    elif re.match(r'^[fh]\d{4}$', jg) and (
            dt[0] != int(jg[1:]) or jg[0] != ('f' if dt[1] <= 6 else 'h')):
        fehler.append('Datum %s passt nicht zum Termin %s' % (ex['datum'], jg))
    pf = sum(t['punkte'] for a in ex['aufgaben'].values() for t in a['teile'])
    pl = sum(t['punkte'] for a in ex['loesungen'].values() for t in a['teile'])
    if pf != 100: fehler.append(f'Frageteil {pf} Punkte')
    if pl != 100: fehler.append(f'Lösungsteil {pl} Punkte')
    for nr, a in sorted(ex['aufgaben'].items()):
        lo = ex['loesungen'].get(nr)
        if not lo:
            fehler.append(f'A{nr}: keine Lösung'); continue
        lab = {t['label']: t for t in lo['teile']}
        for t in a['teile']:
            ml = lab.get(t['label'])
            if not ml:
                fehler.append(f'A{nr}{t["label"]}: Lösungsteil fehlt')
            elif ml['punkte'] != t['punkte']:
                fehler.append(f'A{nr}{t["label"]}: Punkte {t["punkte"]}≠{ml["punkte"]}')
            elif not ml.get('loesung', '').strip():
                fehler.append(f'A{nr}{t["label"]}: Lösung leer')
    return fehler

if __name__ == '__main__':
    jg = [a for a in sys.argv[1:] if a in JAHRGAENGE] or sorted(JAHRGAENGE)
    alle = []
    for j in jg:
        alle += parse_alle(jahrgang=j)
    print('  Jahrgänge: %s · Nachkorrekturen eingespielt: %d'
          % (', '.join(jg), globals().get('_KORREKTUREN', 0)))
    ok = True
    print(f"{'Prüfung':<52} {'Datum':<18} {'Aufg':>4} {'Teile':>5} {'Pkt':>4}  Status")
    for ex in alle:
        f = pruefe(ex)
        if f: ok = False
        nt = sum(len(a['teile']) for a in ex['aufgaben'].values())
        pk = sum(t['punkte'] for a in ex['aufgaben'].values() for t in a['teile'])
        print(f"{ex['bezeichnung'][:50]:<52} {str(ex['datum']):<18} "
              f"{len(ex['aufgaben']):>4} {nt:>5} {pk:>4}  "
              + ('✓ vollständig' if not f else '; '.join(f[:4])))
    vo = sum(1 for ex in alle for a in ex['loesungen'].values() if a['vo'])
    print(f"\nAufgaben mit VO-Bezug: {vo}")
    ziel = [a for a in sys.argv[1:] if a not in JAHRGAENGE]
    if ziel:
        json.dump(alle, open(ziel[0], 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
        print('geschrieben:', ziel[0])
    raise SystemExit(0 if ok else 1)
