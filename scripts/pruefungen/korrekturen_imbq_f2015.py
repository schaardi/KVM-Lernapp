# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Frühjahr 2015.

Aufbau und Regeln: korrekturen_basis.py. Die Hefte sind PDF24-Scans
(Heftform L-ALT); ROHTEXT setzt verschluckte Marker und Punkteklammern,
LOESUNG schreibt Formelsalate und Tabellen aus dem Seitenbild ab.
"""
from korrekturen_basis import anwenden as _anwenden

ROHTEXT = {
    '01-recht.txt': [
        ('8 1 | KSchG', '§ 1 I KSchG'),
        ('\nAN ZUB:\n', '\nd) Z. B.:\n'),
        ('S31TVG,851TVG', '§ 3 I TVG, § 5 I TVG'),
        ('\nD\\SZ.B:\n', '\nb) Z. B.:\n'),
        ('MaßR-\nnahme', 'Maß-\nnahme'),
        # A6: b) und c) samt Aufzählungszeichen verloren
        ('\nDITZAB:\n\nm Wasserhaushaltsgesetz\nAbwasserverordnung\nBundesimmissionsschutzgesetz\n'
         'Bundesnaturschutzgesetz\nLandesnaturschutzgesetze\nStrafgesetzbuch\n\nAbwassergesetz\n',
         '\nb) Z. B.:\n= Wasserhaushaltsgesetz\n= Abwasserverordnung\n= Bundesimmissionsschutzgesetz\n'
         '= Bundesnaturschutzgesetz\n= Landesnaturschutzgesetze\n= Strafgesetzbuch\n= Abwassergesetz\n'),
        ('\nB=\nVerursacherprinzip\nGemeinlastprinzip\nVorsorgeprinzip\nKooperationsprinzip\n'
         'Subsidiaritätsprinzip\n\nc)\n\nBE mE wu wu N\n',
         '\nc) Z. B.:\n= Verursacherprinzip\n= Gemeinlastprinzip\n= Vorsorgeprinzip\n'
         '= Kooperationsprinzip\n= Subsidiaritätsprinzip\n'),
        ('diesern Thema', 'diesem Thema'),
        # A7: a) und e) ohne Marker
        ('\na.\n= Fragen der betrieblichen Ordnung\nRegelungen, die die Arbeitszeit betreffen\n'
         'Pausenregelung\nRegelung der betrieblichen Lohngestaltung\n'
         'Grundsätze über das betriebliche Vorschlagswesen\n'
         'Teilnahme an betrieblichen Bildungsmaßnahmen (5 Punkte)\n',
         '\na) Z. B.:\n= Fragen der betrieblichen Ordnung\n= Regelungen, die die Arbeitszeit betreffen\n'
         '= Pausenregelung\n= Regelung der betrieblichen Lohngestaltung\n'
         '= Grundsätze über das betriebliche Vorschlagswesen\n'
         '= Teilnahme an betrieblichen Bildungsmaßnahmen (5 Punkte)\n'),
        ('8 77 Ill Satz 2 BVerfG', '§ 77 III Satz 2 BetrVG'),
        ('beschlie-\nRen', 'beschlie-\nßen'),
        ('\nNach 8 83 Abs. 1 Betriebsverfassungsgesetz hat er',
         '\ne) Nach § 83 Abs. 1 Betriebsverfassungsgesetz hat er'),
    ],
    '02-bwl.txt': [
        ('a) m z.B:', 'a) Z. B.:'),
        ('\nCHEZ. BD:\n', '\nc) Z. B.:\n'),
        ('ÖOrganisationsanalyse', 'Organisationsanalyse'),
        ('\nA ProduktA Produkt B ProduktC ProduktD Summe\n',
         '\na) Produkt A Produkt B Produkt C Produkt D Summe\n'),
    ],
    '03-methoden.txt': [
        ('\ne)92.B:\n', '\nc) Z. B.:\n'),
        ('Eswird nicht', 'Es wird nicht'),
        ('Füralle Mitarbeiter', 'Für alle Mitarbeiter'),
        ('\nD)72.B.\n', '\nb) Z. B.:\n'),
        ('a) 2.D.\n', 'a) Z. B.:\n'),
        ('b) BE\n', 'b) Z. B.:\n'),
        ('e) ZB:\n', 'c) Z. B.:\n'),
        ('\nRang BEARUIISE aan Jahresumsatz BED Klasse\n',
         '\na) Rang – Erzeugnisgruppe – Jahresumsatz – Anteil – kumuliert – Klasse\n'),
        ('\nDITZIBE\n', '\nb) Z. B.:\n'),
        ('\nCr Zu Bi\n', '\nc) Z. B.:\n'),
    ],
    '04-zusammenarbeit.txt': [
        ('DieLeistungsfähigkeit', 'Die Leistungsfähigkeit'),
        ('\nBI’ zB:\n', '\nb) Z. B.:\n'),
        ('\nZB:\n\n= willkürliches Eingreifen', '\nc) Z. B.:\n= willkürliches Eingreifen'),
        ('B)@272B2', 'b) Z. B.:'),
        ('\nbeZB:\n', '\nb) Z. B.:\n'),
    ],
    '05-ntg.txt': [
        ('\nITZaB.\n', '\nd) Z. B.:\n'),
        # A3 a): Formelsalat ohne Marker
        ('(RVO $ 4 Absatz 6 Nr. 1-3)\n\nWan\nN\nWu\n', '(RVO $ 4 Absatz 6 Nr. 1-3)\na) η = Wab / Wzu\n'),
        # A5: beide Punkteklammern stehen abgesetzt hinter der Lösung
        ('erforderlich ist.\n\nLösungshinweise Aufgabe 5\n',
         'erforderlich ist. (15 Punkte)\n\nLösungshinweise Aufgabe 5 (15 Punkte)\n'),
        ('F=2812N\n\n(15 Punkte)\n\n(15 Punkte)\n', 'F=2812N\n'),
    ],
}

LOESUNG = {
    # ---- Rechtsbewusstes Handeln
    ('RE', 1, 'b'): (
        'Ein unbefristetes Arbeitsverhältnis kann gemäß § 622 Abs. 3 BGB während einer '
        'vereinbarten Probezeit (längstens für die Dauer von sechs Monaten) unter Einhaltung '
        'einer Frist von zwei Wochen gekündigt werden. Ohne Vereinbarung einer Probezeit '
        'beträgt die Kündigungsfrist bei unbefristeten Arbeitsverträgen innerhalb der ersten '
        'zwei Jahren vier Wochen jeweils zum 15. oder zum Ende des Kalendermonates '
        '(§ 622 Abs. 1 BGB). Die Kündigungsfrist beträgt gemäß § 622 II Satz 1 Nr. 1 BGB ein '
        'Monat zum Ende des Kalendermonates. § 622 II Satz 2 BGB ist wegen '
        'Altersdiskriminierung nicht anwendbar.\n'
        'Hinweis für den Korrektor: Auch eine Lösung unter Berücksichtigung des § 622 II '
        'Satz 2 BGB ist als richtig zu werten.'),
    ('RE', 3, 'b'): (
        'sechs Werktage = drei volle Monate Beschäftigung à zwei Werktage (§ 3 Abs. 1 '
        'i. V. m. § 5 Abs. 1b Bundesurlaubsgesetz)'),
    # ---- Betriebswirtschaftliches Handeln
    ('BW', 2, 'b'): (
        'Organigramm (siehe Abbildung): Unternehmensleitung; darunter die vier funktionalen '
        'Abteilungen Einkauf, Verwaltung, Vertrieb und Produktion; quer dazu die beiden '
        'Querschnittseinheiten Personal und IT.\n'
        '(Geschäftsleitung 1 Punkt, vier funktionelle Abteilungen 1 Punkt, zwei '
        'Querschnittseinheiten 1 Punkt, richtige Darstellung der Verbindungen 4 Punkte, '
        'insgesamt max. 7 Punkte)\n'
        'Hinweis für den Korrektor: Das Organigramm muss ein vollständig funktionsfähiges '
        'Unternehmen darstellen, nicht nur einen Unternehmensausschnitt.'),
    ('BW', 3, 'a'): (
        'Personalbedarf = 600 h · 1,03 / (8 h/MA/Tag · 10 Tage/Auftrag · 0,87) '
        '= 8,88 MA/Auftrag\n'
        'Der Personalbedarf beträgt neun Mitarbeiter, das zur Verfügung stehende Personal von '
        'acht Facharbeitern reicht also nicht aus, um den Auftrag termingerecht auszuführen.'),
    ('BW', 3, 'b'): (
        'Mehrarbeitsstunden pro Mitarbeiter und Tag = 69,5 h/Auftrag / (8 h/MA/Tag · '
        '10 Tage/Auftrag · 0,87)\n= 1 Std./Mitarbeiter und Tag'),
    ('BW', 5, 'a'): (
        'Umlageschlüssel: Fuhrpark 8.400 € / 6.000 km = 1,40 €/km; Arbeitsvorbereitung '
        '14.500 € / 100 = 145 € je Prozentpunkt; Instandhaltung 55.800 € / 900 h = 62 €/h\n'
        'Umlage Fuhrpark: Material 1.260,00 €; Arbeitsvorbereitung 420,00 €; Instandhaltung '
        '280,00 €; Fertigung A 560,00 €; Fertigung B 700,00 €; Verwaltung und Vertrieb '
        '5.180,00 €\n'
        'Umlage Arbeitsvorbereitung (14.500,00 €): Instandhaltung 1.450,00 €; Fertigung A '
        '5.800,00 €; Fertigung B 7.250,00 €\n'
        'Umlage Instandhaltung (55.800,00 €): Fertigung A 26.040,00 €; Fertigung B '
        '29.760,00 €\n'
        'Σ Istgemeinkosten: Material 50.000,00 €; Fertigung A 151.200,00 €; Fertigung B '
        '169.200,00 €; Verwaltung und Vertrieb 182.600,00 €\n'
        '(siehe Anlage 1 zu Lösung 5)'),
    ('BW', 5, 'b'): (
        'Bezugsbasis: Material 240.000,00 € (Fertigungsmaterial); Fertigung A 48.000,00 € '
        '(Fertigungslöhne A); Fertigung B 72.000,00 € (Fertigungslöhne B); Verwaltung und '
        'Vertrieb 730.400,00 € (Herstellkosten)\n'
        'Herstellkosten = MK + FKA + FKB = 290.000 € + 199.200 € + 241.200 € = 730.400 €\n'
        'Istzuschlagssätze: Material 20,83 %; Fertigung A 315 %; Fertigung B 235 %; '
        'Verwaltung und Vertrieb 25 %'),
    ('BW', 6, 'a'): (
        'db = p – kv: Produkt A 6,32 €/Stück; Produkt B 4,10 €/Stück; Produkt C '
        '6,61 €/Stück; Produkt D –0,93 €/Stück\n'
        'DB = db · x: Produkt A 45.504,00 €; Produkt B 58.630,00 €; Produkt C 62.134,00 €; '
        'Produkt D –22.134,00 €; Summe 144.134,00 €\n'
        'Kf = 150.000,00 €\n'
        'Betriebsergebnis = 144.134,00 € – 150.000,00 € = –5.866,00 €\n'
        'Beurteilung: Produkt D erwirtschaftet einen negativen Deckungsbeitrag und führt '
        'damit zu einem Verlust.'),
    ('BW', 6, 'b'): (
        'DBges = DBA + DBB + DBC = 45.504 € + 58.630 € + 62.134 € = 166.268 €\n'
        'BEneu = DBges – Kf = 166.268 € – 150.000 € = 16.268 €'),
    ('BW', 7, 'a'): (
        'Blechsorte – Menge – Äquivalenzziffer – Recheneinheiten – Fertigungskosten gesamt '
        '– Fertigungskosten je Tonne:\n'
        '– 0,4 mm: 1.500 t – 1,40 – 2.100 – 1.050.000,00 € – 700,00 €/t\n'
        '– 0,6 mm: 1.000 t – 1,25 – 1.250 – 625.000,00 € – 625,00 €/t\n'
        '– 0,8 mm: 1.800 t – 1,05 – 1.890 – 945.000,00 € – 525,00 €/t\n'
        '– 1,0 mm: 2.100 t – 1,00 – 2.100 – 1.050.000,00 € – 500,00 €/t\n'
        '– Summe: 7.340 Recheneinheiten – 3.670.000,00 €\n'
        'Fertigungskosten je Recheneinheit = 3.670.000 € / 7.340 Recheneinheiten '
        '= 500 €/Recheneinheit'),
    # ---- Methoden der Information, Kommunikation und Planung
    ('MI', 3, 'a'): (
        'Die Fehlerkosten werden wie folgt aufgeschlüsselt (Anteil an der Gesamtproduktion – '
        'Anteil an der Gesamtzahl der Fehler – Anteil an den Fehlerkosten):\n'
        '– mangelnde Dokumentation: 8 % – 33,3 % – 16.666,67 €\n'
        '– mangelhafte Maßhaltigkeit: 7 % – 29,2 % – 14.583,33 €\n'
        '– mangelhafte Beschaffenheit der Oberfläche: 5 % – 20,8 % – 10.416,67 €\n'
        '– Korrosion: 4 % – 16,7 % – 8.333,33 €\n'
        '– gesamt: 24 % – 100,0 % – 50.000,00 €'),
    ('MI', 3, 'b'): (
        'Kreisdiagramm „Anteile an den Fehlerkosten“ (siehe Abbildung):\n'
        '– mangelnde Dokumentation 33,3 %\n– mangelhafte Maßhaltigkeit 29,2 %\n'
        '– mangelhafte Beschaffenheit der Oberfläche 20,8 %\n– Korrosion 16,7 %\n'
        'Hinweis für den Korrektor: Auch andere Diagramme zur anschaulichen Darstellung von '
        'Anteilen können gewertet werden.'),
    ('MI', 6, 'a'): (
        'Rang – Erzeugnisgruppe – Jahresumsatz in Euro – Anteil am Jahresumsatz in % – '
        'kumulierte Umsatzanteile in % – Klasse:\n'
        '– 1: F – 540.200 – 45,07 – 45,07 – A\n'
        '– 2: D – 240.310 – 20,05 – 65,11 – A\n'
        '– 3: G – 160.200 – 13,36 – 78,48 – A\n'
        '– 4: H – 84.240 – 7,03 – 85,51 – B\n'
        '– 5: B – 74.810 – 6,24 – 91,75 – B\n'
        '– 6: C – 56.400 – 4,71 – 96,45 – C\n'
        '– 7: A – 24.360 – 2,03 – 98,49 – C\n'
        '– 8: E – 18.160 – 1,51 – 100,00 – C\n'
        'Summe: 1.198.680 €'),
    ('MI', 6, 'b'): (
        'Z. B.:\n– Marktpotenzial für die Produkte der Erzeugnisgruppen F, D, G analysieren\n'
        '– umsatzfördernde und kundenbindende Maßnahmen für die Produkte der '
        'Erzeugnisgruppen F, D, G\n'
        '– Produkte der Erzeugnisgruppen C, A, E eventuell durch andere Unternehmen '
        'zuliefern lassen'),
    ('MI', 6, 'c'): (
        'Z. B.:\n– Ermittlung der Verbrauchsmaterialien mit den höchsten Kosten im Einkauf\n'
        '– Ermittlung von Ladenhütern im Lagerbestand\n'
        '– Ermittlung der Premiumkunden mit den höchsten Umsätzen\n'
        '– Identifikation der Fehler mit den höchsten Kosten und des '
        'Verbesserungspotenzials'),
    # ---- Zusammenarbeit im Betrieb
    ('ZI', 2, 'a'): (
        'Z. B. (Kriterium: kooperativer Führungsstil / autoritärer Führungsstil):\n'
        '– Beziehung Mitarbeiter – Vorgesetzter: Kontakt wird ständig gehalten. / Distanz '
        'ist zu erwarten.\n'
        '– Betriebsklima: vertrauensvoll / Misstrauen kann von beiden Seiten ausgehen.\n'
        '– Selbstkontrolle: wird ständig praktiziert / wird ausgeschlossen\n'
        '– Motivation: Die Mitarbeiter fühlen sich wertgeschätzt und werden so eine höhere '
        'Motivation haben. / Die Motivation wird wahrscheinlich geringer sein.'),
    ('ZI', 3, 'b'): (
        '– Zielvereinbarungen\n– Besetzung von Stellen\n– Kompetenzabgrenzungen\n'
        '– Einstellungen von Mitarbeitern\n– Kontrolle der Mitarbeiter\n– Beurteilungen\n'
        '– Mitarbeitergespräche'),
    ('ZI', 4, 'a'): (
        'Hinweis für den Korrektor: Mögliche Lösungen könnten in verschiedene Richtungen '
        'gehen:\n'
        '– Eine Möglichkeit wäre die persönliche Unterstützung oder die Unterstützung durch '
        'Mitarbeiter – Entgegenkommen beim Arbeitseinsatz, Lernpatenschaften.\n'
        '– Abendschule unter Berücksichtigung der bisherigen Berufserfahrung\n'
        '– gemeinsame Lösung mit der Agentur für Arbeit'),
    # ---- Naturwissenschaftliche und technische Gesetzmäßigkeiten
    ('NT', 1, 'd'): (
        'Z. B.:\n– die Reinheit der an der Reaktion beteiligten Stoffe\n'
        '– die Größe der Kontaktfläche zwischen den oxidierenden Stoffen\n'
        '– die Affinität (Bindungsbestreben) zu Sauerstoff\n– die Temperatur\n– der Druck'),
    ('NT', 2, 'a'): (
        'R1:\nU1 = U – U2 = 24 V – 18 V = 6 V\nR1 = U1 / I = 6 V / 2 A = 3 Ω\n'
        'R2:\nI3 = U2 / R3 = 18 V / 36 Ω = 0,5 A\nI2 = I – I3 = 2 A – 0,5 A = 1,5 A\n'
        'R2 = U2 / I2 = 18 V / 1,5 A = 12 Ω'),
    ('NT', 2, 'b'): (
        'mit R1:\nP = U · I = 24 V · 2 A = 48 W\n'
        'ohne R1:\n1/R23 = 1/R2 + 1/R3 = 1/12 Ω + 1/36 Ω\nR23 = 9 Ω\n'
        'P = U² / R23 = (24 V)² / 9 Ω = 64 W\n'
        'Die Gesamtleistung erhöht sich bei kurzgeschlossenem Widerstand R1 (von 48 W auf '
        '64 W).'),
    ('NT', 3, 'a'): (
        'η = Wab / Wzu = Eab / Epot\n'
        'Epot = Eab / η = 18.000 kWh / 0,85 = 21.176,5 kWh'),
    ('NT', 3, 'b'): (
        'Epot = m · g · h\n'
        'm = Epot / (g · h) = 21.176,5 kWh · s² / (9,81 m · 45 m) '
        '= 21.176,5 · 3.600 kJ · s² / (9,81 · 45 m²)\n'
        'm = 172.693,2 t'),
    ('NT', 3, 'c'): (
        'V = m / ρ = 172.693,2 t · m³ / 1 t = 172.693,2 m³\n'
        'Q = V / t = 172.693,2 m³ / 180 min = 959,4 m³/min'),
    ('NT', 4, 'a'): (
        'σzul = 1/3 · Re = 1/3 · 225 N/mm² = 75 N/mm²\n'
        'S = F / σzul = 120.000 N · mm² / 75 N = 1.600 mm²'),
    ('NT', 4, 'b'): (
        'S = b² + b² · π/4 = b² · (1 + π/4) = b² · 1,785\n'
        'b = √(S / 1,785) = √(1.600 mm² / 1,785)\nb = 29,9 mm'),
    ('NT', 5, 'a'): (
        'ΣF = 0\n0 = F + FH – FR\nF = FR – FH\n'
        'F = µ · FG · cos α – FG · sin α = FG · (µ · cos α – sin α)\n'
        'Gleitreibung: µ = 0,12\ntan α = 0,5 m / 8 m = 0,0625 ⇒ α = 3,58°\n'
        'F = 500 kg · 9,81 m/s² · (0,12 · cos 3,58° – sin 3,58°)\nF = 281,2 N'),
    ('NT', 6, 'a'): (
        'v = d · π · n = 0,2 m · π · 192 / 60 s = 2,01 m/s\n'
        't = s / v = 25 m · s / 2,01 m = 12,4 s'),
    ('NT', 7, 'b'): 'x̃ = 30 ms',
    ('NT', 7, 'c'): 'x̄ = 30,25 ms',
    ('NT', 7, 'e'): 's = 1,459 ms',
    ('NT', 7, 'f'): (
        'h27 = 1 · 100 % / 32 = 3,1 %\nh28 = 2 · 100 % / 32 = 6,3 %\n'
        'h29 = 6 · 100 % / 32 = 18,8 %\nh30 = 10 · 100 % / 32 = 31,2 %\n'
        'h31 = 8 · 100 % / 32 = 25,0 %\nh32 = 3 · 100 % / 32 = 9,4 %\n'
        'h33 = 1 · 100 % / 32 = 3,1 %\nh34 = 1 · 100 % / 32 = 3,1 %\n'
        'Säulendiagramm: siehe Abbildung.'),
}

FRAGE = {
    ('RE', 1, 'b'): (
        'Geben Sie an, innerhalb welcher Fristen die folgenden Arbeitsverhältnisse gekündigt '
        'werden können, und nennen Sie die Rechtsgrundlagen:\n'
        '– Mit der 32-jährigen Thea Schulze wurde vor zwei Monaten ebenfalls ein '
        'unbefristetes Arbeitsverhältnis geschlossen. Es wurde eine dreimonatige Probezeit '
        'vereinbart.\n'
        '– Mit dem 45-jährigen Bernd Müller wurde vor fünf Monaten ein unbefristetes '
        'Arbeitsverhältnis abgeschlossen.\n'
        '– Mit dem 26-jährigen Fabian Jung wurde vor drei Jahren gleichfalls ein '
        'unbefristetes Arbeitsverhältnis geschlossen.'),
    ('BW', 5, 'a'): (
        'Führen Sie die innerbetriebliche Leistungsverrechnung in Anlage 1 durch und '
        'ermitteln Sie die Istgemeinkosten (auf zwei Nachkommastellen genau).\n'
        'Anlage 1 (Betriebsabrechnungsbogen), primäre Gemeinkosten: Fuhrpark 8.400,00 €; '
        'Material 48.740,00 €; Arbeitsvorbereitung 14.080,00 €; Instandhaltung 54.070,00 €; '
        'Fertigung A 118.800,00 €; Fertigung B 131.490,00 €; Verwaltung und Vertrieb '
        '177.420,00 €'),
    ('BW', 7, 'a'): (
        'Ein Walzwerk stellt Spezialbleche unterschiedlicher Stärke her (siehe Tabelle). Die '
        'Gesamtfertigungskosten im Oktober betragen 3.670.000 €. Da Bleche mit geringerer '
        'Stärke öfter gewalzt werden müssen, steigen die Fertigungskosten tendenziell mit '
        'abnehmender Blechstärke. Die Tabelle gibt den Zusammenhang von Blechstärke und '
        'Kostenerfahrungswerten bezogen auf die Blechstärke von 1 mm an.\n'
        'Berechnen Sie die Fertigungskosten für jede Blechsorte pro Tonne sowie insgesamt.'),
    ('MI', 3, 'a'): (
        'Ordnen Sie den einzelnen Fehlerursachen ihre Anteile an der Gesamtzahl der Fehler '
        'und an den Fehlerkosten in einer Tabelle zu. Verwenden Sie hierzu die Anlage 1 '
        '(Tabelle mit den Spalten Fehlerursache, Anteil an der Gesamtproduktion, Anteil an '
        'der Gesamtzahl der Fehler, Anteil an den Fehlerkosten).'),
    ('ZI', 2, 'a'): (
        'Erklären Sie Ihren Mitarbeitern die Unterschiede beider Führungsstile anhand von je '
        'vier Kriterien. Verwenden Sie dazu die Anlage 1 (Tabelle mit den Spalten Kriterien, '
        'Kooperativer Führungsstil, Autoritärer Führungsstil).'),
    ('NT', 2, 'a'): 'Bestimmen Sie die Widerstandswerte von R1 und R2.',
    ('NT', 2, 'b'): (
        'Begründen Sie durch Berechnung, wie sich die Gesamtleistung der Schaltung '
        'verändert, wenn der Widerstand R1 kurzgeschlossen wird.'),
    ('NT', 3, 'c'): 'Berechnen Sie den erforderlichen Volumenstrom (Q) des Wassers in m³/min.',
    ('NT', 5, 'a'): (
        'Ein Stahlkörper mit der Masse 500 kg soll mit gleichbleibender Geschwindigkeit auf '
        'einer Stahlrampe abwärts bewegt werden (siehe Abbildung).\n'
        'Berechnen Sie die Kraft F, die zum Verschieben der Kiste mit konstanter '
        'Geschwindigkeit erforderlich ist.'),
    ('NT', 6, 'a'): (
        'Die Drehzahl einer Bauwinde mit einem Seiltrommeldurchmesser von 200 mm beträgt '
        '192 min⁻¹. Mit dieser Winde soll eine Last von 500 kg 25 m hochgehoben werden '
        '(siehe Abbildung).\nBerechnen Sie die dazu erforderliche Zeit.'),
}

PUNKTE = {}
LABEL = {}
DATUM = {}

INTRO = {
    ('BW', 5): ('Für die Maschinenbau GmbH liegt für den Monat April der '
                'Betriebsabrechnungsbogen in Anlage 1 vor. Die Verteilung der primären '
                'Gemeinkosten wurde bereits durchgeführt. Im April wurden von den '
                'Hilfskostenstellen die folgenden Leistungen erbracht (siehe Tabelle).\n'
                'Zusätzlich liegen für den Monat April noch folgende Informationen vor:\n'
                '– Fertigungsmaterial 240.000 €\n– Fertigungslöhne A 48.000 €\n'
                '– Fertigungslöhne B 72.000 €'),
    ('BW', 6): ('In einer Betriebsstätte werden vier Produkte produziert. Die Produktion ist '
                'ausgelastet und hat keine freien Kapazitäten. Die Angaben zur '
                'Deckungsbeitragsrechnung sind in Anlage 2 dargestellt (siehe Tabelle).'),
    ('MI', 2): ('In Ihrem Unternehmen wird ein neues IT-System zur Betriebsdatenerfassung '
                'eingeführt. Das Projekt muss innerhalb von vier Monaten abgeschlossen sein. '
                'Ihr Stellvertreter hat Ihnen folgende Tabelle zur Abschätzung des '
                'Arbeitszeitaufwandes vorbereitet (siehe Tabelle).'),
    ('MI', 3): ('Die Produktion einer Pilotanlage weist eine Fehlerquote von 24 % auf. Für '
                'die Fehler wurden folgende Ursachen ermittelt (siehe Tabelle). Die '
                'Fehlerkosten betragen insgesamt 50.000 €.'),
    ('MI', 6): ('In Ihrem Unternehmen wurde folgende Verteilung der Umsätze auf die '
                'produzierten Erzeugnisgruppen erfasst (siehe Tabelle).'),
    ('NT', 1): ('Nachfolgend sind die Reaktionsgleichungen zur Herstellung einer Säure '
                'aufgeführt:\n1. S + O₂ → SO₂\n2. 2 SO₂ + O₂ ↔ 2 SO₃\n3. SO₃ + H₂O → H₂SO₄'),
    ('NT', 2): ('Eine elektrische Schaltung besteht aus drei Widerständen (siehe '
                'Abbildung).\nU = 24 V, I = 2 A, U2 = 18 V, R3 = 36 Ω'),
    ('NT', 4): ('Eine Zugstange (Re = 225 N/mm²) wird mit 120 kN belastet. Die zulässige '
                'Zugspannung beträgt bei schwellender Belastung 1/3 Re.'),
    ('NT', 7): ('Die tägliche Lieferung von Airbags eines Automobilzulieferers hat den '
                'Umfang N = 1000. Aus jeder Lieferung wird eine Stichprobe von n = 32 '
                'entnommen und jeweils die Auslösezeit in Millisekunden ermittelt. Die '
                'Stichprobenergebnisse der letzten Tage waren (siehe Tabelle).\n'
                'Ermitteln Sie daraus'),
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
