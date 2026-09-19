# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Herbst 2015.

Aufbau und Regeln: korrekturen_basis.py. Die Hefte sind PDF24-Scans
(Heftform L-ALT); ROHTEXT setzt verschluckte Marker und Punkteklammern,
LOESUNG schreibt die Formelsalate der Rechenaufgaben aus dem Seitenbild ab.
"""
from korrekturen_basis import anwenden as _anwenden

ROHTEXT = {
    '01-recht.txt': [
        # A3 b): zweiter Aufzählungspunkt als Marker „E)“ gelesen
        ('\nE) acht Wochen nach der Geburt:', '\n= acht Wochen nach der Geburt:'),
        # A4 b): Lösungsmarker „b) Z. B.:“ verstümmelt
        ('\nD)N 2 Z.B\n', '\nb) Z. B.:\n'),
        ('nis-bestand.', 'nis bestand.'),
        ('a) Erhatgegen 89 ArbSchG', 'a) Er hat gegen § 9 ArbSchG'),
        ('b) -Z.B.:', 'b) Z. B.:'),
    ],
    '02-bwl.txt': [
        ('( » Haftung der Gesellschafter.', '– Haftung der Gesellschafter.'),
        ('Projektsirukturplan', 'Projektstrukturplan'),
        ('Grundenigelt', 'Grundentgelt'),
        # A6: die Marker der beiden Lösungsteile stecken im Formelsalat
        ('\na AK\nER\n', '\na) kv = ΔK / Δx\n'),
        ('\nb\nU\npP = —\n', '\nb) p = U / x\n'),
    ],
    '03-methoden.txt': [
        ('(VO: 84 Abs. A Nr. 1)', '(VO: § 4 Abs. 4 Nr. 1)'),
        ('C):1Zu.B:', 'c) Z. B.:'),
        ('frequentiy', 'frequently'),
    ],
    '04-zusammenarbeit.txt': [
        ('a) Z.B.\n', 'a) Z. B.:\n'),
        ('=  Beieiner ergonomischen', '= Bei einer ergonomischen'),
        # A2 b): Lösungsmarker fehlt, die beiden Grundsätze hingen an a)
        ('\n®= Keine umfassenden und unnötigen Kontrollsysteme',
         '\nb) Z. B.:\n= Keine umfassenden und unnötigen Kontrollsysteme'),
        ('"= _ _Beider Arbeitssicherheit', '= Bei der Arbeitssicherheit'),
        ('CNC- Maschine', 'CNC-Maschine'),
        ('a) Z.B:.', 'a) Z. B.:'),
        # A5 c): „c) Z. B.:“ als „6), B.:“ gelesen
        ('\n6), B.:\n', '\nc) Z. B.:\n'),
        # A6 a): Marker und die Überschrift des zweiten Szenarios
        ('\nale me2.,BE\n', '\na) 1. Z. B.:\n'),
        ('halten.\n\n= Kritik ist für Mitarbeiter unangenehm.',
         'halten.\n2. Z. B.:\n= Kritik ist für Mitarbeiter unangenehm.'),
        ('Ändere Kollegen', 'Andere Kollegen'),
        ('2. Erkritisiert', '2. Er kritisiert'),
        # Punktespalte der Seite 41: a) von Aufgabe 6 hat zwei Szenarien à 3 P
        ('(10 Punkte)\n\n(3 Punkte)\n\n(3 Punkte)\n\n(4 Punkte)\n\n(11 Punkte)\n\n(4 Punkte)',
         '(10 Punkte)\n\n(6 Punkte)\n\n(4 Punkte)\n\n(11 Punkte)\n\n(4 Punkte)'),
        # A7
        ('a). ZzEB::', 'a) Z. B.:'),
        ('= evil. Zusatzprojekt', '= evtl. Zusatzprojekt'),
        ('\n® Gespräch mit den zwei Kollegen',
         '\nb) Z. B.:\n= Gespräch mit den zwei Kollegen'),
    ],
    '05-ntg.txt': [
        ('Ausgangssioffe', 'Ausgangsstoffe'),
        ('\na Re, Atom\n', '\nb) S Atom\n'),
        ('(VO: 8 4 Abs. 6 Nr. 1-3)\n2\na\npe\nR\n(230 V}\n2940\nP=1800W\ner (4 Punkte)',
         '(VO: 8 4 Abs. 6 Nr. 1-3)\na) P = U² / R\nP = (230 V)² / 29,4 Ω\nP = 1800 W (4 Punkte)'),
        ('a Q = A +V . 2\n) Bar Pi d', 'a) Q = A1 · v1'),
        ('cosp = 0,89', 'cos φ = 0,89'),
        ('(R, = 580 N/mm’)', '(Re = 580 N/mm²)'),
        ('\n2) x arfsım\n', '\na) x̄ = 3,775 µm\n'),
        ('\nbo 3.0.2005 um\n', '\nb) s = 0,2005 µm\n'),
        ('\nKa ax 3-S\n', '\nc) xmax = x̄ + 3 · s\n'),
    ],
}

LOESUNG = {
    # ---- Rechtsbewusstes Handeln
    ('RE', 3, 'b'): (
        'Eine Schwangere darf in folgenden Fällen nicht beschäftigt werden, z. B.:\n'
        '– sechs Wochen vor der Geburt: Sie erhält Mutterschaftsgeld in Höhe von 13 € '
        'pro Tag von der Krankenkasse und einen Zuschuss zum Mutterschaftsgeld von ihrem '
        'Arbeitgeber in Höhe des Unterschiedsbetrages zwischen 13 € und dem um die '
        'gesetzlichen Abzüge verminderten durchschnittlichen kalendertäglichen Arbeitsentgelt.\n'
        '– acht Wochen nach der Geburt: Sie erhält Mutterschaftsgeld in Höhe von 13 € pro '
        'Tag von der Krankenkasse und einen Zuschuss zum Mutterschaftsgeld von ihrem '
        'Arbeitgeber in Höhe des Unterschiedsbetrages zwischen 13 € und dem um die '
        'gesetzlichen Abzüge verminderten durchschnittlichen kalendertäglichen Arbeitsentgelt.\n'
        '– wenn nach ärztlichem Zeugnis Leben oder Gesundheit von Mutter und Kind bei '
        'Fortdauer der Beschäftigung gefährdet ist: Sie erhält vom Arbeitgeber mindestens '
        'den Durchschnittsverdienst der letzten 13 Wochen oder der letzten drei Monate vor '
        'Beginn des Monates, in dem die Schwangerschaft eingetreten ist, weiter gewährt.\n'
        'Hinweis für den Korrektor: Es sind auch Beispiele der §§ 4, 8 MuSchG als richtig '
        'zu werten.'),
    ('RE', 4, 'b'): (
        'Z. B.:\n– Name\n– Anschrift\n– Familienstand\n– Geburtsdatum\n'
        'Hinweis für den Korrektor: Es sind auch andere Nennungen als richtig zu bewerten.\n'
        '§ 32 BDSG'),
    ('RE', 7, 'b'): (
        'Z. B.:\n'
        '– Verpackungsverordnung: Danach müssen alle Verpackungen vom Vertreiber '
        'zurückgenommen und einer erneuten Verwendung oder Verwertung außerhalb der '
        'öffentlichen Abfallentsorgung zugeführt werden.\n'
        '– Batterieverordnung: Sie verpflichtet Hersteller und Vertreiber zur Rücknahme '
        'und Beseitigung.\n'
        '(je 3 Punkte, max. 6 Punkte)\n'
        'Hinweis für den Korrektor: Andere zutreffende Nennungen sind ebenfalls als '
        'richtig zu werten.'),
    # ---- Betriebswirtschaftliches Handeln
    ('BW', 1, 'b'): (
        'Geschäftsführungsbefugnis:\n'
        '– OHG: jeder Gesellschafter\n– KG: Komplementär\n– GmbH: Geschäftsführer\n'
        '– AG: Vorstand\n'
        'Haftung der Gesellschafter:\n'
        '– OHG: Alle Gesellschafter sind Vollhafter.\n'
        '– KG: Komplementäre sind Vollhafter, Kommanditisten sind Teilhafter mit '
        'Kapitaleinlage.\n'
        '– GmbH: Teilhaftung mit Geschäftsanteil\n'
        '– AG: Teilhaftung mit Kapitaleinsatz'),
    ('BW', 4, 'a'): (
        'Zeitgrad in Prozent = Vorgabezeit / Istauftragszeit · 100 %\n'
        '= 30 Stunden / 25 Stunden · 100 % = 120 %'),
    ('BW', 4, 'b'): (
        'Akkordrichtsatz pro Stunde = Akkordgrundlohn + Akkordzuschlag\n'
        '= 18 €/Stunde + 10 % = 19,80 €/Stunde\n'
        'Akkordlohn pro Stunde = Akkordrichtsatz/Stunde · Zeitgradfaktor\n'
        '= 19,80 €/Stunde · 1,2 = 23,76 €/Stunde'),
    ('BW', 4, 'c'): (
        'Bruttolohn = Akkordlohn/Stunde · Istzeit\n'
        '= 23,76 €/Stunde · 25 Stunden = 594 €'),
    ('BW', 4, 'd'): (
        'Lohnkosten/Stück = Akkordrichtsatz/Stunde · Vorgabezeit / Auftragsmenge\n'
        '= 19,80 €/Stunde · 30 Stunden/Auftrag / 1.500 Teile/Auftrag = 0,396 €/Stück\n'
        'oder: Lohnkosten/Stück = Akkordlohn/Stunde · Istzeit / Auftragsmenge\n'
        '= 23,76 €/Stunde · 25 Stunden/Auftrag / 1.500 Teile/Auftrag = 0,396 €/Stück\n'
        'oder: Lohnkosten/Stück = Bruttolohn / Auftragsmenge\n'
        '= 594 € / 1.500 Teile = 0,396 €/Stück'),
    ('BW', 5, 'a'): (
        'Materialgemeinkostenzuschlagsatz = 125.000 € / 750.000 € · 100 % = 16,67 %\n'
        'Fertigungsgemeinkostenzuschlagsatz = 795.000 € / 550.000 € · 100 % = 144,55 %\n'
        'Herstellkosten des Umsatzes = 750.000 € + 125.000 € + 550.000 € + 795.000 € '
        '= 2.220.000 €\n'
        'Verwaltungsgemeinkostenzuschlagsatz = 85.000 € / 2.220.000 € · 100 % = 3,83 %\n'
        'Vertriebsgemeinkostenzuschlagsatz = 80.000 € / 2.220.000 € · 100 % = 3,60 %'),
    ('BW', 5, 'b'): (
        'Materialeinzelkosten 24.000,00 €\n'
        '+ Materialgemeinkosten (15 %) 3.600,00 €\n'
        '+ Fertigungslohnkosten 16.000,00 €\n'
        '+ Fertigungsgemeinkosten (150 %) 24.000,00 €\n'
        '= Herstellkosten 67.600,00 €\n'
        '+ Verwaltungsgemeinkosten (5 %) 3.380,00 €\n'
        '+ Vertriebsgemeinkosten (4 %) 2.704,00 €\n'
        '= Selbstkosten 73.684,00 €\n'
        '+ Gewinn (10 %) 7.368,40 €\n'
        '= Barverkaufspreis 81.052,40 € (95 %)\n'
        '+ Rabatt (5 %) 4.265,92 €\n'
        '= Angebotspreis 85.318,32 € (100 %)'),
    ('BW', 6, 'a'): (
        'Variable Stückkosten:\n'
        'kv = (585.000 €/Monat – 504.000 €/Monat) / (6.750 Stück/Monat – 5.400 Stück/Monat)\n'
        '= 81.000 € / 1.350 Stück = 60 €/Stück\n'
        'Fixkosten pro Monat:\n'
        'Kf = 504.000 €/Monat – 60 €/Stück · 5.400 Stück/Monat = 180.000 €/Monat'),
    ('BW', 6, 'b'): (
        'Preis: p = Umsatz / Menge = (504.000 € – 18.000 €) / 5.400 Stück = 90 €/Stück\n'
        'Break-even-Menge:\n'
        'xBEP = Kf / (p – kv) = 180.000 €/Monat / (90 €/Stück – 60 €/Stück) '
        '= 6.000 Stück/Monat\n'
        'Beschäftigungsgrad an der Gewinnschwelle:\n'
        'xmax = 5.400 Stück/Monat / 72 % · 100 % = 7.500 Stück/Monat\n'
        'BG(BEP) = 6.000 Stück/Monat / 7.500 Stück/Monat · 100 % = 80 %'),
    ('BW', 7, 'a'): (
        '1. Neutraler Aufwand, z. B.:\n– Spende an gemeinnützige Einrichtung\n'
        '– Steuernachzahlung für vergangene Periode\n'
        '2. Zweckaufwand, z. B.:\n– Gehälter\n– Löhne\n– Materialverbrauch'),
    ('BW', 7, 'b'): (
        'Z. B.:\n– kalkulatorische Abschreibungen\n– kalkulatorische Zinsen\n'
        '– kalkulatorische Wagnisse\n– kalkulatorische Miete\n'
        '– kalkulatorischer Unternehmerlohn'),
    # ---- Methoden der Information, Kommunikation und Planung
    ('MI', 1, 'b'): (
        'Das Systemhaus\n'
        '– betreibt eine Hotline, damit Fragen der Mitarbeiter beantwortet werden und '
        'Fehler gemeldet werden können;\n'
        '– hilft den Mitarbeitern per Fernwartung direkt bei der Lösung von Problemen;\n'
        '– installiert neue Hardware, tauscht Geräte aus und sorgt für passende '
        'Treibersoftware;\n'
        '– schult die Mitarbeiter im Umgang mit neuer oder aktualisierter Software;\n'
        '– passt die Standardsoftware an die Anforderungen des Unternehmens an.'),
    ('MI', 2, 'a'): (
        'Produkt – Wertanteil einzeln – Wertanteil kumuliert – Klasse:\n'
        '– A: 29 % – 29 % – A\n– G: 26 % – 55 % – A\n– H: 24 % – 79 % – A\n'
        '– B: 8 % – 87 % – B\n– F: 6 % – 93 % – B\n– E: 4 % – 97 % – C\n'
        '– C: 2 % – 99 % – C\n– D: 1 % – 100 % – C'),
    ('MI', 2, 'b'): (
        'Die A-Produkte repräsentieren einen Wertanteil und somit Kostenanteil von etwa '
        '80 %. Um Kosten zu sparen, sind folgende Schlussfolgerungen möglich:\n'
        '– Einsparungen dieser Materialien\n– Rabatte aushandeln\n'
        '– Ersatzprodukte einsetzen\n'
        '– bei schwankenden Preisen: Material günstig kaufen und einlagern\n'
        'Bevor Kostensenkungen bei den B- und C-Produkten angestrebt werden, müssen erst '
        'alle Möglichkeiten zur Kostensenkung der A-Produkte ausgereizt sein.'),
    ('MI', 4, 'a'): (
        'Relative Häufigkeiten (Anzahl / 80 Messungen):\n'
        '– Klasse 1 (65 bis 66 g): 2 Messungen = 2,5 %\n'
        '– Klasse 2 (66 bis 67 g): 4 Messungen = 5,0 %\n'
        '– Klasse 3 (67 bis 68 g): 8 Messungen = 10,0 %\n'
        '– Klasse 4 (68 bis 69 g): 16 Messungen = 20,0 %\n'
        '– Klasse 5 (69 bis 70 g): 22 Messungen = 27,5 %\n'
        '– Klasse 6 (70 bis 71 g): 14 Messungen = 17,5 %\n'
        '– Klasse 7 (71 bis 72 g): 8 Messungen = 10,0 %\n'
        '– Klasse 8 (72 bis 73 g): 4 Messungen = 5,0 %\n'
        '– Klasse 9 (73 bis 74 g): 2 Messungen = 2,5 %\n'
        'Diagramm: Säulendiagramm der relativen Häufigkeiten über den Klassenmitten '
        '(65,5 g bis 73,5 g), siehe Abbildung.\n'
        'Hinweis für den Korrektor: Statt der Klassenmitten können auf der horizontalen '
        'Achse auch die Klassengrenzen dargestellt werden.'),
    # ---- Zusammenarbeit im Betrieb
    ('ZI', 3, 'b'): (
        'Teamentwicklungsphasen und Verhalten der Mitarbeiter:\n'
        '1. Teambildung – Forming: zurückhaltend; orientieren sich am Vorgesetzten.\n'
        '2. Auseinandersetzung – Storming: Rollenverteilung findet statt; zeigen Sympathie '
        'und Antipathie; Bildung von informellen Gruppen; Konkurrenzkämpfe, '
        'zwischenmenschliche Konflikte; Regeln werden aufgestellt, Grenzen gesetzt.\n'
        '3. Zusammenschluss – Norming: erstmalig Gruppengefühl; gemeinsames Lösen von '
        'Konflikten; Austausch von Informationen; öffnen sich allmählich; genießen das '
        'Team.\n'
        '4. Vernetzung – Performing: stark personenbezogene Zusammenarbeit; funktionaler '
        'Wettbewerb; Engagement; gegenseitige Unterstützung; stark aufgabenbezogen.'),
    ('ZI', 3, 'c'): (
        'Definition:\n'
        '– Informelle Gruppen entstehen spontan, häufig innerhalb bzw. parallel zu '
        'formalen Gruppen.\n'
        '– Ziele, Normen, Rollen, Status werden von der Gruppe selbst definiert.\n'
        '– Hier stehen soziale Bedürfnisse im Vordergrund.\n'
        'Z. B.:\n– Fahrgemeinschaften\n– Pausengemeinschaften\n– Lerngruppen'),
    ('ZI', 4, 'a'): (
        'Wahlweise Tätigkeiten eines bestimmten Arbeitsplatzes – hier Schleifen:\n'
        '– Plan- und Nutenschleifen: Herr Becker +++, Herr Schröder +++++\n'
        '– Planschleifen: Herr Becker +++, Herr Schröder +++++\n'
        '– Rundschleifen: Herr Becker +++++, Herr Schröder ++\n'
        '– Außen-Rundschleifen: Herr Becker +++++, Herr Schröder ++\n'
        'Kenntnisse: +++++ sehr gut, ++++ gut, +++ mittelmäßig, ++ gering, – keine\n'
        'Hinweis für den Korrektor: Die Tätigkeiten sollen nachvollziehbar zu einem '
        'konkreten Arbeitsplatz gehören.'),
    # ---- Naturwissenschaftliche und technische Gesetzmäßigkeiten
    ('NT', 1, 'a'): '– S: Schwefel\n– O₂: Sauerstoff\n– SO₂: Schwefeldioxid',
    ('NT', 1, 'b'): '– S: Atom\n– O₂: Molekül\n– SO₂: Molekül',
    ('NT', 1, 'c'): (
        'Oxidation\nOxidationsmittel sind sauerstoffreiche Verbindungen, die den '
        'Sauerstoff bei einer Reaktion leicht abgeben.'),
    ('NT', 2, 'a'): 'P = U² / R\nP = (230 V)² / 29,4 Ω\nP = 1800 W',
    ('NT', 2, 'b'): (
        'Strom:\nU = 0,95 · 230 V = 218,5 V\n'
        'I = U / R = 218,5 V / 29,4 Ω = 7,43 A\n'
        'Leistung:\nP = U² / R = (218,5 V)² / 29,4 Ω = 1624 W'),
    ('NT', 3, 'a'): (
        'L/2 = √((0,66 m)² + (15 m)²)\n'
        'L = 2 · √((0,66 m)² + (15 m)²)\nL = 30,029 m'),
    ('NT', 3, 'b'): (
        'L = L0 · (1 – αL · Δϑ)\n'
        'L = 30,029 m · (1 – 0,000012 1/°C · 50 °C)\nL = 30,011 m'),
    ('NT', 3, 'c'): (
        'd = √((15,0055 m)² – (15 m)²)\nd = 0,406 m\n'
        'Der Durchhang von 0,35 m wird nicht unterschritten.'),
    ('NT', 4, 'a'): (
        'Q = A1 · v1\n'
        'A1 = π · d² / 4 = π · (0,8 dm)² / 4 = 0,503 dm²\n'
        'v1 = Q / A1 = 12 dm³/min / 0,503 dm² = 23,86 dm/min'),
    ('NT', 4, 'b'): (
        'Q = A2 · v2\n'
        'A2 = π · (D² – d²) / 4 = π · (0,8² – 0,4²) dm² / 4 = 0,377 dm²\n'
        'v2 = Q / A2 = 12 dm³/min / 0,377 dm² = 31,83 dm/min = 5,3 cm/s'),
    ('NT', 4, 'c'): 'v1 / v2 = 3,98 cm/s / 5,3 cm/s = 0,75',
    ('NT', 5, 'a'): (
        'FG = m · g = 125 kg · 9,81 m/s² = 1226,25 N\n'
        'Pab = FG · s / t = 1226,25 N · 5,5 m / 18 s = 375 W\n'
        'η = Pab / Pzu\n'
        'Pzu = Pab / η = 375 W / 0,88 = 426,14 W = Pel\n'
        'Pel = √3 · U · I · cos φ\n'
        'I = Pel / (√3 · U · cos φ) = 426,14 W / (√3 · 400 V · 0,89) = 0,69 A'),
    ('NT', 6, 'a'): (
        'Steigung 15 % ⇒ tan α = 0,15 ⇒ α = 8,5°\n'
        'FG = m · g = 47.000 kg · 9,81 m/s² = 461,07 kN\n'
        'Fz = FH = FG · sin α = 461,07 kN · sin 8,5° = 68,15 kN\n'
        'σz,zul = Re / ν = 580 N/mm² / 2,7 = 214,8 N/mm²\n'
        'SSeil = Fz / σz,zul = 68.150 N / 214,8 N/mm² = 317,3 mm²\n'
        'SDraht = π · d² / 4 = π · (1,5 mm)² / 4 = 1,77 mm²\n'
        'n = SSeil / SDraht = 317,3 mm² / 1,77 mm² = 179,26 ⇒ n = 180 Drähte'),
    ('NT', 7, 'a'): 'x̄ = Σx / n = 45,3 µm / 12 = 3,775 µm',
    ('NT', 7, 'b'): 's = √(Σ(x – x̄)² / (n – 1)) = 0,2005 µm',
    ('NT', 7, 'c'): (
        'xmax = x̄ + 3 · s = 3,775 µm + 3 · 0,2005 µm = 4,377 µm\n'
        'xmin = x̄ – 3 · s = 3,775 µm – 3 · 0,2005 µm = 3,173 µm'),
    ('NT', 7, 'd'): (
        'siehe Anlage zu Lösung 7 d): Die Gerade der Summenhäufigkeit verläuft durch '
        'die Punkte x̄ – 3s = 3,17 µm bei 0,135 % und x̄ + 3s = 4,38 µm bei 99,87 %.'),
}

FRAGE = {
    ('BW', 5, 'a'): (
        'Ermitteln Sie die Istgemeinkostenzuschlagsätze, wenn Ihnen folgende '
        'Istgemeinkosten aus der Betriebsabrechnung des vergangenen Monats vorliegen:\n'
        '– Kostenstelle Material 125.000 €\n– Kostenstelle Fertigung 795.000 €\n'
        '– Kostenstelle Verwaltung 85.000 €\n– Kostenstelle Vertrieb 80.000 €\n'
        'Weiterhin liegen Ihnen folgende Einzelkosten aus der Betriebsabrechnung vor:\n'
        '– Fertigungseinzelkosten (Fertigungslöhne) 550.000 €\n'
        '– Materialeinzelkosten (Fertigungsmaterial) 750.000 €'),
    ('BW', 5, 'b'): (
        'Kalkulieren Sie für einen Auftrag mit folgenden Normalgemeinkostenzuschlagsätzen '
        'den Listenverkaufspreis (netto).\n'
        '– Materialgemeinkostenzuschlagssatz 15 %\n'
        '– Fertigungsgemeinkostenzuschlagssatz 150 %\n'
        '– Verwaltungsgemeinkostenzuschlagssatz 5 %\n'
        '– Vertriebsgemeinkostenzuschlagssatz 4 %\n'
        'Gehen Sie von 16.000 € Fertigungseinzelkosten und 24.000 € Materialeinzelkosten '
        'aus. Weiterhin soll mit einem Gewinnzuschlagsatz von 10 % kalkuliert werden. Da '
        'es sich um einen langjährigen Stammkunden handelt, werden ihm 5 % Rabatt '
        'eingeräumt.'),
    ('MI', 4, 'a'): (
        'Bei der Qualitätskontrolle eines Produktes wurden 80 Messungen durchgeführt. '
        'Dabei wurden folgende Füllmengen gemessen (siehe Tabelle).\n'
        'Ermitteln Sie die relativen Häufigkeiten der gemessenen Füllmengen und stellen '
        'Sie diese in einem Diagramm dar.'),
    ('ZI', 6, 'a'): (
        'Entwickeln Sie für den Industriemeister Spiller zwei Szenarien:\n'
        '1. Er unternimmt nichts.\n2. Er kritisiert das Verhalten seines Mitarbeiters.'),
    ('NT', 3, 'b'): 'Berechnen Sie die Seillänge, die sich bei einer Abkühlung auf –25 °C einstellt.',
    ('NT', 3, 'c'): (
        'Aus Festigkeitsgründen darf der Durchhang bei –25 °C nicht kleiner als 0,35 m '
        'werden. Überprüfen Sie rechnerisch, ob diese Bedingung eingehalten wird.'),
    ('NT', 4, 'a'): 'Berechnen Sie die Ausfahrgeschwindigkeit (v1) der Kolbenstange in dm/min.',
    ('NT', 4, 'b'): 'Berechnen Sie die Einfahrgeschwindigkeit (v2) der Kolbenstange in cm/s.',
    ('NT', 7, 'a'): 'den arithmetischen Mittelwert x̄',
    ('NT', 7, 'c'): 'die Prozessstreuung xmin bis xmax bei 99,73 % aller gefertigten Teile.',
    ('NT', 7, 'd'): (
        'Tragen Sie aufgrund des Mittelwertes x̄ und der Standardabweichung s die Gerade '
        'der Summenhäufigkeit in das Wahrscheinlichkeitsnetz (Anlage 1) ein.'),
}

PUNKTE = {
    # A6 a) hat zwei Szenarien à 3 Punkte; das Heft druckt beide Klammern
    ('ZI', 6, 'a'): 6,
}
LABEL = {}
DATUM = {}

INTRO = {
    ('BW', 6): ('Ihnen stehen aus dem Controlling für die Monate August und September '
                'folgende Daten zur Verfügung (siehe Tabelle).'),
    ('MI', 2): ('Die Abteilung Einkauf Ihres Unternehmens hat für acht eingekaufte '
                'Materialien Mengen und Preise erfasst (siehe Tabelle). Mit den Daten '
                'soll eine ABC-Analyse durchgeführt werden.'),
    ('NT', 1): 'Nachfolgend ist eine Reaktionsgleichung dargestellt:\nS + O₂ → SO₂',
    ('NT', 2): ('Ein elektrisches Heizgerät ist für den Anschluss an 230 V/50 Hz '
                'vorgesehen. Die Messung des Widerstandes der Heizwicklung ergab einen '
                'Wert von 29,4 Ω.'),
    ('NT', 3): ('In der Mitte einer 30 m breiten Straße ist eine Lampe an einem Stahlseil '
                'aufgehängt. Bei 25 °C beträgt der Durchhang 0,66 m.'),
    ('NT', 4): ('Der Kolben eines doppelt wirkenden hydraulischen Arbeitszylinders mit '
                'einseitiger Kolbenstange wird durch einen Volumenstrom von 12 Liter pro '
                'Minute aus- und eingefahren. Der Kolbendurchmesser beträgt 8 cm, der '
                'Kolbenstangendurchmesser beträgt 4 cm.'),
    ('NT', 7): ('Aus einem normalverteilten Fertigungsprozess wurde eine Stichprobe '
                'entnommen. An den Bauteilen wurde für die Oberflächenbearbeitung die '
                'maximale Rautiefe Rmax ermittelt (siehe Tabelle).\n'
                'Ermitteln Sie aus diesen Stichprobenergebnissen:'),
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
