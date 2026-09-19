# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Herbst 2014.

Aufbau und Regeln: korrekturen_basis.py. Die Hefte sind PDF24-Scans
(Heftform L-ALT); ROHTEXT setzt verschluckte Marker, LOESUNG schreibt
Formelsalate, Tabellen und verlorene Aufzählungen aus dem Seitenbild ab.
Statt des VO-Bezugs nennen die Hefte von 2014 den Rahmenplan („RP: …“).
"""
from korrekturen_basis import anwenden as _anwenden

ROHTEXT = {
    '01-recht.txt': [
        ('83 Abs. 3 ASIG', '§ 3 Abs. 3 ASiG'),
        ('Muftersprache', 'Muttersprache'),
        ('handelt, 8 14\nAbs. 2 a Satz 1 TzBfG.', 'handelt, § 14\nAbs. 2a Satz 1 TzBfG.'),
        ("8'% Stunden", '8½ Stunden'),
        ('Häfrle', 'Härle'),
        ('Enitgeltausfall', 'Entgeltausfall'),
    ],
    '02-bwl.txt': [
        ('Beieiner Belegschaft', 'Bei einer Belegschaft'),
        # A3 e): Marker als „8), ZB“ gelesen
        ('\n8), ZB\n', '\ne) Z. B.:\n'),
    ],
    '03-methoden.txt': [
        ('\nad) z.B:\n', '\na) Z. B.:\n'),
        # A5 c): Marker fehlt
        ('\nEs können z. B. folgende Aufgaben beschrieben werden:\n',
         '\nc) Es können z. B. folgende Aufgaben beschrieben werden:\n'),
    ],
    '04-zusammenarbeit.txt': [
        # A3 a): Marker verstümmelt
        ('\nAI ZEBN\n', '\na) Z. B.:\n'),
        # A5 a): die OCR setzt zwei Aufzählungspunkte vor den Marker
        ('\neindeutige Aufgabenverteilung\nVorbildwirkung\n\na)\n',
         '\na) Z. B.:\n= eindeutige Aufgabenverteilung\n= Vorbildwirkung\n'),
        # A7 c): Marker fehlt
        ('\nvorbildlich korrektes Sozialverhalten',
         '\nc) Z. B.:\n= vorbildlich korrektes Sozialverhalten'),
    ],
    '05-ntg.txt': [
        # A5 b) und c): nur die Ergebnisse überlebten die OCR
        ('\n= 58,86 W (5 Punkte)\n\n=47, (5 Punkte)\n',
         '\nb) P = 58,86 W (5 Punkte)\nc) v = 17,15 m/s (5 Punkte)\n'),
        # A7 e)
        ('\ne = 223-0\nI Poes 5 E (3 Punkte)\n', '\ne) pges = 2 · 3 % = 6 % (3 Punkte)\n'),
    ],
}

LOESUNG = {
    # ---- Rechtsbewusstes Handeln
    ('RE', 7, 'a'): '1. Verursacherprinzip\n2. Vorsorgeprinzip\n3. Gemeinlastprinzip',
    ('RE', 7, 'b'): (
        'Z. B.: Immissionsschutzbeauftragter\n'
        'Die Kündigung des Arbeitsverhältnisses ist unzulässig, es sei denn, dass Tatsachen '
        'vorliegen, die den Betreiber zur Kündigung aus wichtigem Grund ohne Einhaltung '
        'einer Kündigungsfrist berechtigen.'),
    # ---- Betriebswirtschaftliches Handeln
    ('BW', 1, 'a'): (
        '1. 25.000 €\n2. Geschäftsführer\n3. Geschäftsführer\n'
        '4. nach dem Verhältnis der Geschäftsanteile oder nach Vertrag\n'
        '5. Haftung mit Gesellschaftsvermögen\n6. Haftung mit der Einlage'),
    ('BW', 2, 'b'): (
        'Einliniensystem:\n– Vorteile, z. B.: Transparenz und Einfachheit der Beziehungen; '
        'eindeutige Kommunikationswege\n'
        '– Nachteile, z. B.: Gefahr der Informationsfilterung durch einzelne Instanzen; '
        'lange Kommunikationswege; Gefahr der Bürokratisierung\n'
        'Zweiliniensystem (Matrixorganisation):\n'
        '– Vorteile, z. B.: Entlastung der Unternehmensleitung; kurze Entscheidungswege; '
        'hohe Flexibilität; Problemlösungen durch Funktionsmanager und Spezialisten '
        '(Produkt- bzw. Projektmanager)\n'
        '– Nachteile, z. B.: hoher Bedarf an Führungskräften; Kompetenz- und '
        'Handlungskonflikte zwischen Funktions- und Produktmanagern; hoher '
        'Kommunikationsbedarf'),
    ('BW', 2, 'c'): (
        'Auswirkungen einer Unterorganisation, z. B.:\n'
        '– Arbeitsabläufe sind ungeordnet.\n– Doppelarbeiten\n'
        '– Aufgaben werden nicht erledigt.\n– ineffiziente, planlose Aufgabenausführung\n'
        '– Demotivation der Mitarbeiter\n– Streitigkeiten unter den Mitarbeitern\n'
        '– Lieferverzögerungen\n– schlechtes Image\n– Kundenverlust, Umsatzrückgang\n'
        'Auswirkungen einer Überorganisation, z. B.:\n'
        '– Mangelnde Flexibilität – auf Veränderungen am Markt kann nicht zügig reagiert '
        'werden.\n– hoher Personalbedarf\n– höhere Kosten\n– sinkende Konkurrenzfähigkeit\n'
        '– Demotivation der Mitarbeiter durch zu wenig Freiräume, Leistungshemmung\n'
        '– Hohes Maß an organisatorischen Vorschriften führt zu hohem Kontroll- und '
        'Aktualisierungsaufwand.'),
    ('BW', 3, 'a'): (
        'Jahresbedarf = 288.000 Stück · 1,125 = 324.000 Stück\n'
        'Verbrauch/Tag = Jahresbedarf / 360 Tage = 324.000 Stück / 360 Tage '
        '= 900 Stück/Tag\n'
        'Meldebestand = 900 Stück/Tag · (20 Tage + 2 Tage) + 9.000 Stück = 28.800 Stück'),
    ('BW', 3, 'b'): (
        'Ø-Lagerbestand = Bestellmenge / 2 + Sicherheitsbestand = 27.000 Stück / 2 + '
        '9.000 Stück = 22.500 Stück\n'
        'Lagerumschlagshäufigkeit = Jahresverbrauch / Ø-Lagerbestand = 324.000 Stück / '
        '22.500 Stück = 14,4'),
    ('BW', 3, 'c'): 'Lagerdauer = 360 Tage / Lagerumschlagshäufigkeit = 360 Tage / 14,4 = 25 Tage',
    ('BW', 3, 'd'): (
        'xopt = √(2 · Jahresbedarf · Kosten je Bestellung / (Einstandspreis · '
        'Lagerhaltungszinssatz))\n'
        'xopt = √(2 · 324.000 · 84 € / (3 €/Stück · 0,18)) = 10.040 Stück\n'
        'xopt = 10.000 Stück, da 500er Verpackungseinheiten'),
    ('BW', 3, 'e'): (
        'Z. B.: Produktionsbereitschaft sicherstellen bei\n– zusätzlichen Aufträgen\n'
        '– erhöhtem Ausschuss\n– Lieferverzögerungen'),
    ('BW', 4, 'a'): (
        'Zeitgrad = Vorgabezeit / Istauftragszeit · 100 % = 975 min / 780 min · 100 % '
        '= 125 %'),
    ('BW', 4, 'b'): (
        'Akkordlohn = Akkordrichtsatz · Zeitgradfaktor = 13,60 €/Std. · 1,25 = 17 €/Std.'),
    ('BW', 4, 'c'): (
        'Normalleistung:\nFertigungslohnkosten/Stück = 975 min · 13,60 €/Std. / '
        '(500 Stück · 60 min/Std.) = 0,442 €/Stück\n'
        'Zeitgrad 125 %:\nFertigungslohnkosten/Stück = 780 min · 17 €/Std. / '
        '(500 Stück · 60 min/Std.) = 0,442 €/Stück'),
    ('BW', 5, 'a'): (
        'Äquivalenzziffern nach dem Gewicht (Typ S = 1,0): M = 4,20 / 3,50 = 1,2; '
        'L = 7,70 / 3,50 = 2,2\n'
        'Rechnungseinheiten (RE) = Menge · Äquivalenzziffer: S 8.900 · 1,0 = 8.900 RE; '
        'M 6.750 · 1,2 = 8.100 RE; L 3.200 · 2,2 = 7.040 RE; Summe 24.040 RE\n'
        'Selbstkosten pro Rechnungseinheit = 471.184 € / 24.040 RE = 19,60 €/RE\n'
        'Selbstkosten pro Verpackungseinheit: S 19,60 €; M 1,2 · 19,60 € = 23,52 €; '
        'L 2,2 · 19,60 € = 43,12 €\n'
        'Selbstkosten pro Sorte: S 8.900 · 19,60 € = 174.440 €; M 6.750 · 23,52 € '
        '= 158.760 €; L 3.200 · 43,12 € = 137.984 €; Summe 471.184 €'),
    ('BW', 6, 'a'): (
        'Variable Kosten Kv = 60 % · 472.500 € = 283.500 €\n'
        'Menge x = 70 % · 3.000 Stück = 2.100 Stück\n'
        'kv = 283.500 € / 2.100 Stück = 135 €/Stück\n'
        'Kf = 472.500 € – 283.500 € = 189.000 €/Monat\n'
        'Umsatz U = Kosten + Betriebsergebnis = 472.500 € + 31.500 € = 504.000 €\n'
        'p = U / x = 504.000 € / 2.100 Stück = 240 €/Stück\n'
        'xBEP = Kf / (p – kv) = 189.000 €/Monat / (240 €/Stück – 135 €/Stück) '
        '= 1.800 Stück/Monat'),
    ('BW', 6, 'b'): (
        '1. Kosten pro Stück bei 70 % = 472.500 € / 2.100 Stück = 225 €/Stück\n'
        '2. Kosten pro Stück bei 100 % = (189.000 € + 3.000 Stück · 135 €/Stück) / '
        '3.000 Stück = 198 €/Stück\n'
        '3. Die Kosten pro Stück sinken mit zunehmender Auslastung aufgrund der '
        'Fixkostendegression.'),
    ('BW', 7, 'a'): (
        'Materialgemeinkostenzuschlag = Materialgemeinkosten / Fertigungsmaterial · 100 % '
        '= 2.839.788 € / 22.538.000 € · 100 % = 12,6 %\n'
        'Fertigungsgemeinkostenzuschlag A = 1.603.674 € / 378.225 € · 100 % = 424 %\n'
        'Fertigungsgemeinkostenzuschlag B = 3.284.225 € / 756.110 € · 100 % = 434,4 %\n'
        'Herstellkosten = Fertigungsmaterial 22.538.000 € + Materialgemeinkosten '
        '2.839.788 € + Fertigungslohnkosten A 378.225 € + Fertigungsgemeinkosten A '
        '1.603.674 € + Fertigungslohnkosten B 756.110 € + Fertigungsgemeinkosten B '
        '3.284.225 € = 31.400.022 €\n'
        'Verwaltungs- und Vertriebsgemeinkostenzuschlag = 5.495.010 € / 31.400.022 € '
        '· 100 % = 17,5 %'),
    ('BW', 7, 'b'): (
        'Herstellkosten 31.400.022 €\n+ Verwaltungs- und Vertriebsgemeinkosten 5.495.010 €\n'
        '+ Sondereinzelkosten des Vertriebes 255.800 €\n= Selbstkosten 37.150.832 €\n'
        'Betriebsergebnis = Umsatzerlöse – Selbstkosten = 40.250.000 € – 37.150.832 € '
        '= 3.099.168 €'),
    # ---- Methoden der Information, Kommunikation und Planung
    ('MI', 1, 'a'): (
        'Es können z. B. folgende Punkte beschrieben werden:\n'
        '– Analyse des Istzustandes\n– Beschreibung des Sollzustandes\n'
        '– Erläuterung von Pro und Kontra\n– Erläuterung der Zusammenhänge\n'
        '– Bewertung durchführen\n– Auswahl vorschlagen\n– Entscheidung einholen'),
    ('MI', 1, 'b'): (
        'Es können z. B. folgende Protokollpunkte genannt werden:\n'
        '– Gegenstand (Thema) der Beratung\n– Datum und Uhrzeit\n'
        '– Anwesenheitsliste der Teilnehmer\n– Aufgaben\n– Protokollverteiler\n'
        '– Entscheidungen\n– Unterschriften'),
    ('MI', 2, 'a'): (
        'Min-Max-Diagramm (siehe Abbildung): Für jeden Hilfsstoff A bis I werden '
        'Minimal- und Maximaltemperatur über der Hilfsstoff-Achse als Punkte '
        'eingetragen und durch eine senkrechte Linie verbunden (Temperatur in °C von 0 '
        'bis 60).\n'
        'Hinweis für den Korrektor: Die Temperaturen können auch in einem anderen '
        'sachgerechten Diagramm dargestellt werden.'),
    ('MI', 3, 'a'): (
        'Z. B.:\n– Erfassung der Leistungsdaten des Netzwerkes (Monitoring)\n'
        '– Datensicherung auf dem Server (Backup)\n'
        '– Installation und Aktualisierung einer Firewall\n– Installation von Updates\n'
        '– Austausch defekter Geräte'),
    ('MI', 3, 'b'): (
        'In dem Lastenheft für die Individualsoftware können aus Sicht des Auftraggebers '
        'z. B. folgende Forderungen enthalten sein:\n'
        '– ergonomische Gestaltung der Benutzeroberfläche\n'
        '– Kompatibilität zum Betriebssystem\n– Kompatibilität zu vorhandener Hardware\n'
        '– Schnittstellen für den Import und Export von Daten\n'
        '– Formate für die Speicherung der Daten\n– Algorithmen zur Auswertung der Daten'),
    ('MI', 3, 'c'): (
        'In dem Pflichtenheft können z. B. folgende Angaben enthalten sein:\n'
        '– Endtermin\n– Meilensteine (mit Teilabnahmen)\n'
        '– Ansprechpartner auf der Seite des Auftragnehmers\n'
        '– softwaretechnische Angaben zur Realisierung des Programms\n– usw.'),
    ('MI', 4, 'a'): (
        'Netzplan (siehe Abbildung), je Vorgang: FAZ – Dauer – FEZ / SAZ – Puffer – SEZ:\n'
        '– A: 0 – 9 – 9 / 0 – 0 – 9\n– B: 0 – 7 – 7 / 1 – 1 – 8\n'
        '– C: 9 – 6 – 15 / 11 – 2 – 17\n– D: 9 – 6 – 15 / 9 – 0 – 15\n'
        '– E: 7 – 7 – 14 / 8 – 1 – 15\n– F: 15 – 5 – 20 / 17 – 2 – 22\n'
        '– G: 15 – 8 – 23 / 15 – 0 – 23\n– H: 20 – 6 – 26 / 22 – 2 – 28\n'
        '– I: 23 – 5 – 28 / 23 – 0 – 28\n– Ziel: 28 / 28\n'
        'Kritischer Pfad: Start – A – D – G – I – Ziel'),
    ('MI', 4, 'b'): (
        'Balkenplan (siehe Abbildung), Zeit in Tagen: A Tag 1 bis 9; B Tag 1 bis 7 '
        '(Puffer bis Tag 8); C Tag 10 bis 15 (Puffer bis Tag 17); D Tag 10 bis 15; '
        'E Tag 8 bis 14 (Puffer bis Tag 15); F Tag 16 bis 20 (Puffer bis Tag 22); '
        'G Tag 16 bis 23; H Tag 21 bis 26 (Puffer bis Tag 28); I Tag 24 bis 28.'),
    ('MI', 5, 'b'): (
        '– zum Sachziel, z. B.: technische Daten der Lagerboxen; Qualitätsansprüche an '
        'die Montage der Lagerboxen; Schnittstellen; benötigte Medien\n'
        '– zum Terminziel, z. B.: Starttermin; Endtermin; Meilensteine; Vorgangsdauern, '
        'Pufferzeiten usw.\n'
        '– zum Kostenziel, z. B.: Gesamtkosten; Kosten für bestimmte Projektabschnitte; '
        'Arbeitskosten; Ressourcenkosten'),
    ('MI', 5, 'c'): (
        'Es können z. B. folgende Aufgaben beschrieben werden:\n'
        '– ständiger Soll-Ist-Vergleich bezogen auf Sach-, Kosten- und Terminziel\n'
        '– Abweichungen vom Plan feststellen und beheben\n'
        '– Änderungswünsche prüfen, ob diese in das laufende Projekt noch übernommen '
        'werden können\n'
        '– falls Verzögerungen auftreten: Entscheidung treffen, ob Umplanungen nötig '
        'sind, und gegebenenfalls Umplanungen vornehmen'),
    # ---- Zusammenarbeit im Betrieb
    ('ZI', 3, 'a'): (
        'Z. B.:\n– fachliche Leitung der Abteilung aufgrund der Amtsautorität\n'
        '– verantwortlicher Vorgesetzter für Planungs-, Organisations-, Durchführungs- '
        'und Kontrollaufgaben\n'
        '– inhaltliche Durchführung der Ausbildung nach betrieblichem Ausbildungsplan '
        'bzw. Ausbildungsrahmenplan\n'
        '– Moderator und Ansprechpartner für alle Mitarbeiter der Abteilung'),
    ('ZI', 4, 'a'): (
        'Die Beispiele können z. B. darauf abzielen, dass\n'
        '– Aktennotizen die Grundlage für Personalgespräche bilden.\n'
        '– Beurteilungsfehler durch die Anfertigung von Aktennotizen vermieden werden '
        'sollen.\n'
        '– die Auswertung von Aktennotizen die Basis für Personalentscheidungen '
        'darstellt.\n'
        '– hierdurch ein möglicher Qualifizierungsbedarf ermittelt werden kann.'),
    ('ZI', 5, 'a'): (
        'Z. B.:\n– eindeutige Aufgabenverteilung\n– Vorbildwirkung\n'
        '– situatives Führungsverhalten\n– individuelle Ressourcennutzung\n'
        '– nachvollziehbare Arbeitsorganisationen\n– angemessenes Sozialverhalten\n'
        '– persönliche und fachliche Autorität\n'
        '– Empfehlung von Qualifizierungsmöglichkeiten\n– regelmäßige Personalgespräche\n'
        'Hinweis für den Korrektor: Es wird nur bewertet, was tatsächlich von einem '
        'Meister beeinflusst werden kann.'),
    ('ZI', 5, 'b'): (
        'Die Situationen können Folgendes beinhalten:\n'
        '– Anerkennung, wenn eine Aufgabe gemäß den betrieblichen Vorgaben erfüllt wurde\n'
        '– sachliche Fehlerkorrektur – bei einer nicht ordnungsgemäßen Auftragsausführung '
        'oder bei einem Fehlverhalten\n'
        '– Kritik – in Form eines Kritikgespräches bei einem wiederholten Fehlverhalten '
        'oder gravierenden Verstößen'),
    ('ZI', 7, 'b'): (
        'Z. B.:\n– Pünktlichkeit\n– Zuverlässigkeit\n– Kommunikationsfähigkeit\n'
        '– Kenntnisse in der Informationstechnologie (soziale Netzwerke usw.)\n'
        '– Sprachkenntnisse\n– Toleranz'),
    ('ZI', 7, 'c'): (
        'Z. B.:\n– vorbildlich korrektes Sozialverhalten ausnahmslos in allen Situationen '
        'zeigen\n– Erläuterungen und Beispiele zu betrieblichen Abläufen geben\n'
        '– Einsicht in die Notwendigkeit zur Beachtung der Betriebsordnung vermitteln\n'
        '– auf ständige Einhaltung der BGV achten\n– positive Verhaltensmuster fördern\n'
        '– regelmäßiges Führen von Beurteilungsgesprächen'),
    # ---- Naturwissenschaftliche und technische Gesetzmäßigkeiten
    ('NT', 1, 'b'): 'Säure + Lauge → Wasser + Salz',
    ('NT', 1, 'c'): (
        '1. Zeigt das pH-Messgerät den Wert pH 7 an, ist die Neutralisation erreicht.\n'
        '2. Z. B.:\n– Lackmus: Zeigt die Färbung der Lösung die Farbe Violett, ist die '
        'Neutralisation erreicht.\n'
        '– Phenolphthalein: Wird der basischen Lösung nur so viel saure Lösung '
        'zugesetzt, bis der Indikator gerade entfärbt wird, ist die Neutralisation '
        'erreicht.'),
    ('NT', 2, 'a'): 'Bei 130 °C hat der Widerstand R1 einen Wert von 200 Ω.',
    ('NT', 2, 'b'): (
        'R = R1 + R2 = 200 Ω + 1.000 Ω = 1.200 Ω\n'
        'I = U / R = 12 V / 1.200 Ω = 0,01 A\n'
        'U2 = I · R2 = 0,01 A · 1.000 Ω = 10 V'),
    ('NT', 2, 'c'): (
        'Wird die Temperatur kleiner, wird der Widerstand des R1 größer. Damit wird der '
        'Gesamtwiderstand größer, der Strom kleiner und die Spannung U2 kleiner.'),
    ('NT', 3, 'a'): (
        'Wab = F · s\nQzu = ρ · V · Hi\nη = Wab / Qzu = F · s / (ρ · V · Hi)\n'
        'η = 600 N · 100 km / (0,83 kg/dm³ · 8 dm³ · 42.000 kJ/kg)\n'
        'η = 0,215 = 21,5 %'),
    ('NT', 4, 'a'): (
        'τa = F / S mit S = n · π · d² / 4 (n = Anzahl der Niete)\n'
        'n = 4 · F / (π · d² · τa) = 4 · 11.000 N · mm² / (π · 3² mm² · 120 N)\n'
        'n = 12,97 ⇒ gewählt: 13 Niete'),
    ('NT', 5, 'a'): (
        'Epot = FG · s = m · g · h = 20 kg · 9,81 m/s² · 15 m = 2.943 J'),
    ('NT', 5, 'b'): 'P = W / t = 2.943 J / 50 s = 58,86 W',
    ('NT', 5, 'c'): 'v = √(2 · g · h) = √(2 · 9,81 m/s² · 15 m) = 17,15 m/s',
    ('NT', 6, 'a'): (
        'Ekin = EFeder\nm · v² / 2 = R · s² / 2\n'
        's = v · √(m / R) = 1,2 m/s · √(0,12 kg / 1.600 N/m)\ns = 0,0104 m'),
    ('NT', 7, 'b'): 'x̄ ≈ 10,14 ml',
    ('NT', 7, 'c'): (
        's ≈ (10,14 – 9,92) ml ≈ 0,22 ml\n'
        'von x̄ – 3s ≈ 9,48 ml bis x̄ + 3s ≈ 10,8 ml'),
    ('NT', 7, 'd'): (
        'Anzahl der Ausschussanteile:\naA = p · N / 100 = 7 % · 15.000 / 100 % = 1.050'),
    ('NT', 7, 'e'): 'pges = 2 · 3 % = 6 %',
}

FRAGE = {
    ('BW', 1, 'a'): (
        'Nennen Sie die gesetzlichen Regelungen hinsichtlich:\n'
        '1. der Höhe des Mindestgründungskapitals\n2. der Geschäftsführungsbefugnis\n'
        '3. des Außenvertretungsrechtes\n4. der Gewinnverteilung\n'
        '5. der Haftung der Gesellschaft\n6. der Haftung der Gesellschafter'),
    ('BW', 1, 'c'): (
        'Erläutern Sie den wesentlichen Grund für die Umwandlung einer KG zu einer '
        'GmbH & Co. KG.'),
    ('BW', 5, 'a'): (
        'In einem Betrieb werden Feinkostbecher hergestellt. Diese Becher werden in der '
        'Spritzgusstechnik gefertigt, dadurch ist die Fertigungszeit unabhängig von der '
        'Bechergröße. In der Aufstellung (siehe Tabelle) sehen Sie das '
        'Produktionsprogramm des letzten Monates. Im letzten Monat fielen für das gesamte '
        'Sortiment Selbstkosten in Höhe von 471.184 € an.\n'
        'Ermitteln Sie die Selbstkosten\n– pro Verpackungseinheit sowie\n'
        '– pro Sorte insgesamt.'),
    ('BW', 6, 'b'): (
        'Bestimmen Sie die Kosten pro Stück bei einem Beschäftigungsgrad von\n'
        '1. 70 %\n2. 100 %\n3. Interpretieren Sie die von Ihnen festgestellten Ergebnisse.'),
    ('BW', 7, 'b'): 'Berechnen Sie das Betriebsergebnis.',
    ('MI', 2, 'a'): (
        'Die Lagerung der Hilfsstoffe darf nur in bestimmten Temperaturbereichen '
        'erfolgen. Die notwendigen Angaben zu den minimalen und maximalen '
        'Lagertemperaturen finden Sie in der Tabelle.\n'
        'Stellen Sie die Minimal- und Maximaltemperaturen für die neun Hilfsstoffe in '
        'einem Min-Max-Diagramm dar.'),
    ('NT', 1, 'b'): (
        'Nachfolgend ist eine Neutralisationsreaktion dargestellt:\n'
        '2 HNO₃ + Ca(OH)₂ → 2 H₂O + Ca(NO₃)₂\n'
        'Beschreiben Sie die chemischen Formeln durch allgemeine Begriffe bzw. '
        'formulieren Sie eine allgemeine Neutralisationsreaktion.'),
    ('NT', 2, 'a'): 'Bestimmen Sie den Widerstandswert von R1 bei 130 °C.',
    ('NT', 2, 'b'): (
        'Berechnen Sie die Spannung U2 am Widerstand R2 für den Fall, dass der '
        'Widerstand R1 einer Temperatur von 130 °C ausgesetzt ist.'),
    ('NT', 2, 'c'): (
        'Erläutern Sie, wie sich die Spannung U2 verändert, wenn die Temperatur am '
        'Widerstand geringer wird.'),
    ('NT', 3, 'a'): (
        'Ein Pkw fährt mit gleichbleibender Geschwindigkeit auf der Autobahn eine Strecke '
        'von 100 km und verbraucht dabei 8 Liter Diesel. Der mittlere Kraftaufwand zur '
        'Überwindung der Bodenreibung, des Luftwiderstandes und von Steigungen beträgt '
        '600 N.\nErmitteln Sie den Gesamtwirkungsgrad des Pkws während der Fahrt.'),
    ('NT', 4, 'a'): (
        'Zwei übereinanderliegende Flugzeugbauteile werden durch mehrere Niete mit einem '
        'Durchmesser von 3 mm miteinander verbunden. Die Bauteile sollen eine Last von 11 kN '
        'übertragen. Berechnen Sie die erforderliche Anzahl der Niete für den Fall, dass aus '
        'Sicherheitsgründen die Scherspannung von 120 N/mm² nicht überschritten werden soll.'),
    ('NT', 7, 'b'): 'Bestimmen Sie aus dieser Darstellung die Prozesslage x̄.',
    ('NT', 7, 'c'): 'Bestimmen Sie aus dieser Darstellung die Maschinenstreuung x̄ ± 3 s.',
    ('NT', 7, 'd'): (
        'Berechnen Sie aus den oben angegebenen Bedingungen die Anzahl der '
        'Ausschussampullen (aA) bei einer Tagesproduktion von N = 15 000 Teilen.'),
    ('NT', 7, 'e'): (
        'Bestimmen Sie den Gesamtausschussanteil (pges) bei gleicher Streubreite (6 s) '
        'für den Fall, dass die Prozesslage auf Toleranzmitte eingestellt ist.'),
}

PUNKTE = {
    # A7 a) und A8 a) haben nummerierte Teilfragen mit eigener Klammer
    ('RE', 7, 'a'): 6,
    ('RE', 8, 'a'): 6,
    # sechs Nennungen à 1 Punkt
    ('BW', 1, 'a'): 6,
    # die Klammer der Seite (19 Punkte) rutschte in c)
    ('BW', 4, 'c'): 3,
    # drei Teilfragen à 2 Punkte
    ('BW', 6, 'b'): 6,
    # 1 Punkt + 3 Punkte
    ('NT', 1, 'c'): 4,
}
LABEL = {}
DATUM = {}

INTRO = {
    ('BW', 7): ('Folgende Werte erhalten Sie aus dem Betriebsabrechnungsbogen (siehe '
                'Tabelle). Es sind Sondereinzelkosten des Vertriebes in Höhe von 255.800 € '
                'angefallen, die Umsatzerlöse betragen 40.250.000 €.'),
    ('NT', 2): ('Zwei Widerstände R1 und R2 sind in Reihe geschaltet und an einer '
                'konstanten Spannungsquelle von 12 V angeschlossen. Der Widerstand R1 ist '
                'ein temperaturabhängiger Widerstand mit einem Kennwert von 10 kΩ. Die '
                'Kennlinie des Widerstandes R1 finden Sie in der Formelsammlung. Der '
                'Widerstand R2 ist ein Festwiderstand mit einem Widerstandswert von 1 kΩ.'),
    ('NT', 7): ('Die Füllmenge einer bestimmten Farbstoffampulle ist mit 10 (+0,5/–0,3) ml '
                'angegeben. Es ist bekannt, dass die Füllmengenergebnisse normalverteilt '
                'vorliegen. Eine umfassende Prozessfähigkeitsuntersuchung ergab:\n'
                '– 2 % der Ampullen hatten eine zu geringe Füllmenge.\n'
                '– 5 % der Ampullen hatten eine zu große Füllmenge.'),
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
