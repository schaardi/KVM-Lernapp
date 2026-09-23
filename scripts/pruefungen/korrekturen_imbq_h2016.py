# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Herbst 2016.

Scans (Tranche T4), deutlich sauberer gelesen als 2017. Die Deckblätter
setzen Prüfungstag und Datum in zwei Spalten, die OCR trennt sie (DATUM).
Rechenwege, Tabellen und Aufzählungen sind aus dem Seitenbild neu
geschrieben. Aufbau und Regeln: ``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # ---- Rechtsbewusstes Handeln
    ('RE', 1, 'a'):
     "– In 2014 muss der Arbeitgeber die ersten sechs Wochen das Entgelt von "
     "Herrn Dürr weiterbezahlen. Danach bezahlt die Krankenkasse "
     "Krankengeld.\n"
     "– Im Jahr 2015 zahlt der Arbeitgeber wiederum die ersten sechs Wochen "
     "das Entgelt weiter. Die weiteren vier Wochen bezahlt die "
     "Unfallversicherung Verletztengeld, da es sich um einen Wegeunfall "
     "handelt.",
    ('RE', 2, 'a'):
     "Der Betriebsrat hat in beiden Fällen ein Mitbestimmungsrecht. Die "
     "Taschenkontrollen fallen unter § 87 Abs. 1 Nr. 1 BetrVG und das "
     "Aufstellen der Kameras fällt unter § 87 Abs. 1 Nr. 6 BetrVG.",
    ('RE', 2, 'c'):
     "Der Arbeitgeber kann eine außerordentliche Kündigung aussprechen, da "
     "der Diebstahl das Vertrauensverhältnis zerstört. Der Arbeitgeber muss "
     "den Betriebsrat anhören. Die Kündigung bedarf der Schriftform.",
    ('RE', 3, 'b'):
     "Der Betriebsrat hat ein Mitbestimmungsrecht, § 87 Abs. 1 Nr. 3 BetrVG.",
    ('RE', 4, 'c'):
     "Frau Bührle darf nicht mehr in der Spätschicht ab 20:00 Uhr "
     "beschäftigt werden, § 8 Abs. 1 MuSchG.\n"
     "Sie darf nicht länger als 8,5 Stunden am Tag arbeiten, § 8 Abs. 2 "
     "Satz 1 Nr. 2 MuSchG. Zudem darf Frau Bührle keinen Akkord mehr "
     "leisten, § 4 Abs. 3 Satz 1 Nr. 1 MuSchG.",
    ('RE', 5, 'c'):
     "Gemäß § 83 Absatz 1 BetrVG kann Frau Mayer ein Mitglied des "
     "Betriebsrats hinzuziehen.",
    ('RE', 6, 'c'):
     "Herr Lisson darf an Schulungs- und Bildungsveranstaltungen teilnehmen, "
     "soweit diese Kenntnisse vermitteln, die für die Arbeit des "
     "Betriebsrates erforderlich sind.\n"
     "Zudem besteht für jedes Betriebsratsmitglied während der regelmäßigen "
     "Amtszeit ein Anspruch auf Teilnahme an Schulungs- und "
     "Bildungsveranstaltungen, die von der zuständigen obersten "
     "Arbeitsbehörde des Landes als geeignet anerkannt sind, für insgesamt "
     "drei Wochen.",
    ('RE', 7, 'b'):
     "– Vorsorgeprinzip\n– Kooperationsprinzip\n– Verursacherprinzip\n"
     "(je 1 Punkt, max. 3 Punkte)",
    ('RE', 7, 'c'):
     "– Nach dem Vorsorgeprinzip soll der frühzeitige Einsatz von Maßnahmen "
     "gewährleisten, dass die Naturgrundlagen geschützt und schonend in "
     "Anspruch genommen werden.\n"
     "– Nach dem Kooperationsprinzip sollen Staat und Gesellschaft so weit "
     "wie möglich zusammenarbeiten.\n"
     "– Nach dem Verursacherprinzip haftet derjenige für den Schaden, der "
     "ihn verursacht hat.\n(je 3 Punkte, max. 6 Punkte)",
    # ---- Betriebswirtschaftliches Handeln
    ('BW', 1, 'a'):
     "Z. B.:\n"
     "– Durch einen horizontalen Unternehmenszusammenschluss soll eine "
     "höhere Marktmacht und damit eine stärkere Marktposition erreicht "
     "werden (Reduzierung bzw. Ausschaltung des Wettbewerbes), z. B.: "
     "Zusammenschluss von Supermärkten/Lebensmitteldiscountern.\n"
     "– Ein vertikaler Unternehmenszusammenschluss sichert die Beschaffungs- "
     "und/oder Absatzbasis, z. B.: Zusammenschluss von Maschinenbau und "
     "Maschinenhandel.\n"
     "– Branchenfremde Unternehmenszusammenschlüsse dienen der "
     "Risikostreuung sowie der Erschließung von Wachstumsmärkten, z. B.: "
     "Lebensmittelhandel und Tourismus.\n"
     "(für einen plausiblen Grund je 3 Punkte, für das Beispiel je 1 Punkt, "
     "insgesamt max. 12 Punkte)\n"
     "Hinweis für den Korrektor: Auch reale Beispiele (konkrete "
     "Zusammenschlüsse von Firmen) sind zulässig.",
    ('BW', 2, 'b'):
     "Vorteile, z. B.:\n"
     "– hohe Produktivität aufgrund zunehmender Fertigungsroutine "
     "(Lerneffekte) der Mitarbeiter\n"
     "– geringe Anlernzeit/Anlernkosten für neue Mitarbeiter\n"
     "– kurze Durchlaufzeiten der Werkstücke und damit geringe "
     "Kapitalbindungskosten\n"
     "– relativ einfache Planung, Steuerung und Kontrolle des "
     "Produktionsprozesses\n"
     "Nachteile, z. B.:\n"
     "– Die feste Taktung und monotone Arbeit führen eventuell zu einer "
     "hohen psychischen Belastung der Mitarbeiter.\n"
     "– hohe Störanfälligkeit aufgrund der Verkettung von Arbeitssystemen\n"
     "– hohe Investitionskosten in Fertigungsanlagen\n"
     "– geringe Flexibilität bei der Umstellung der Produktion auf andere "
     "Produkte",
    ('BW', 3, 'a'):
     "Positive Auswirkungen sind z. B.:\n"
     "– Die Mitarbeiter haben einen besseren Gesamtüberblick über das "
     "Produkt.\n"
     "– Die Mitarbeiter können sich besser mit ihrem Produkt identifizieren, "
     "was zu höherer Motivation führt.\n"
     "– Es entsteht ein stärkeres Verantwortungsbewusstsein.\n"
     "– Die Teamarbeit in den Sparten steigert die Mitarbeitermotivation.\n"
     "Negative Auswirkungen sind z. B.:\n"
     "– Es kann Konfliktpotenzial zwischen den Mitarbeitern der einzelnen "
     "Sparten entstehen.\n"
     "– Ein hoher Kommunikationsaufwand kann zu Missverständnissen und damit "
     "zu sinkender Motivation führen.\n"
     "– Es kann ein höheres Konfliktpotenzial zwischen Mitarbeitern und "
     "Vorgesetzten durch Diskussionen im Team entstehen.",
    ('BW', 4, 'a'):
     "1. durchschnittlicher Lagerbestand = (Anfangsbestand + 6 "
     "Monatsendbestände) / 7 = 210.000 l / 7 = 30.000 Liter\n"
     "2. Verbrauch = Anfangsbestand + Zugänge – Endbestand = 20.000 Liter + "
     "240.000 Liter – 40.000 Liter = 220.000 Liter\n"
     "3. Lagerumschlagshäufigkeit = Verbrauch pro Periode / Ø Lagerbestand "
     "= 220.000 Liter / 30.000 Liter = 7,33",
    ('BW', 4, 'b'):
     "Z. B.:\n– Der durchschnittliche Lagerbestand sinkt und damit auch die "
     "Lagerhaltungs- und Kapitalbindungskosten.\n– Die Bestellkosten "
     "steigen.\n– Die Gefahr, nicht lieferfähig zu sein, steigt.",
    ('BW', 5, 'a'):
     "1. Akkordlohn/Std. = Akkordlohn / Anzahl geleistete Stunden = "
     "552 €/Woche / 40 Std./Woche = 13,80 €/Std.\n"
     "Akkordrichtsatz/Std. = Akkordgrundlohn (100 %) + Akkordzuschlag "
     "(15 %)\n"
     "Akkordgrundlohn = 13,80 €/Std. / 115 % · 100 % = 12,00 €/Stunde\n"
     "2. Stückzahl pro Woche = 40 Stunden/Woche · 60 min/Stunde / "
     "4 min/Stück = 600 Stück/Woche",
    ('BW', 5, 'b'):
     "– Zeitlohn wird dort angewendet, wo die Arbeitsleistung nicht messbar "
     "ist. Vorteile, z. B.: einfaches Abrechnungsverfahren; keine "
     "Qualitätsverschlechterung aufgrund von Zeitdruck. Nachteile, z. B.: "
     "keine großen Leistungsanreize; keine Berücksichtigung von "
     "Leistungsunterschieden.\n"
     "– Prämienlohn wird verwendet, wenn auch andere Kriterien als die "
     "Mengenleistung wichtig sind, z. B. Qualität, Termintreue, geringerer "
     "Werkstoffverbrauch usw. Er besteht aus einem festen Grundlohn und "
     "einer Prämie für eine Mehr- bzw. Sonderleistung. Vorteile, z. B.: "
     "Mehrere Leistungsmerkmale können verwendet werden; Leistungsanreize; "
     "Belohnung für hohe Qualität. Nachteile, z. B.: Der Zusammenhang "
     "zwischen Lohnhöhe und Leistung ist nicht immer klar erkennbar; "
     "aufwändige Berechnung der Prämien.",
    ('BW', 6, 'a'):
     "Maschinenkosten pro Stück = Maschinenstundensatz · "
     "Maschinenbelegungszeit pro Stück = 19,20 €/Stunde / 60 min/Stunde · "
     "40 min/Stück = 12,80 €/Stück\n"
     "(alle Beträge in Euro)\n"
     "Materialeinzelkosten 96,00\n+ Materialgemeinkosten (15 %) 14,40\n"
     "= Materialkosten 110,40\nFertigungslöhne 2,40\n"
     "+ Restfertigungsgemeinkosten (180 %) 4,32\n+ Maschinenkosten 12,80\n"
     "+ Sondereinzelkosten der Fertigung 2,08\n= Fertigungskosten 21,60\n"
     "= Herstellkosten 132,00\n+ Verwaltungsgemeinkosten (8 %) 10,56\n"
     "+ Vertriebsgemeinkosten (6 %) 7,92\n"
     "+ Sondereinzelkosten des Vertriebes 1,52\n= Selbstkosten 152,00\n"
     "+ Gewinn (15 %) 22,80\n= Barverkaufspreis 174,80\n+ Skonto (2 %) 4,37\n"
     "+ Vertreterprovision (18 %) 39,33\n= Zielverkaufspreis 218,50\n"
     "+ Rabatt (24 %) 69,00\n= Listenverkaufspreis 287,50",
    ('BW', 7, 'a'):
     "1. x(60 %) = 2.000 Stück / 80 % · 60 % = 1.500 Stück\n"
     "Umsatz bei 60 % Beschäftigung = p · x = 195 €/Stück · 1.500 Stück "
     "= 292.500 €\n"
     "Kosten bei 60 % Beschäftigung = 292.500 € + 50.000 € = 342.500 €\n"
     "Break-even-Umsatz U(BEP) = p · x(BEP) = 195 €/Stück · 2.000 Stück "
     "= 390.000 €\n"
     "Kosten im Break-even-Punkt = 390.000 €\n"
     "kv = (K2 – K1) / (x2 – x1) = ΔK / Δx = (390.000 € – 342.500 €) / "
     "(2.000 Stück – 1.500 Stück) = 47.500 € / 500 Stück = 95 €/Stück\n"
     "2. Kf = K – kv · x = 390.000 €/Monat – 95 €/Stück · 2.000 Stück/Monat "
     "= 200.000 €/Monat\n"
     "bzw. = 342.500 €/Monat – 95 €/Stück · 1.500 Stück/Monat "
     "= 200.000 €/Monat\n"
     "Alternative Lösung zu a) 1. und a) 2.: db = ΔDB / Δx = 50.000 € / "
     "500 Stück = 100 €/Stück; kv = p – db = 195 €/Stück – 100 €/Stück "
     "= 95 €/Stück; Kf = K – kv · x = 390.000 €/Monat – 95 €/Stück · "
     "2.000 Stück/Monat = 200.000 €/Monat\n"
     "3. BG 90 % ⇒ x = 2.250 Stück/Monat\n"
     "Betriebsergebnis = db · x – Kf = 100 €/Stück · 2.250 Stück/Monat – "
     "200.000 €/Monat = 25.000 €/Monat",
    ('BW', 7, 'b'):
     "BG(BEP) = 64 % ⇒ x(BEP) = 2.000 Stück / 80 % · 64 % "
     "= 1.600 Stück/Monat\n"
     "db = Kf / x(BEP) = 184.000 €/Monat / 1.600 Stück/Monat = 115 €/Stück",
    # ---- Methoden der Information, Kommunikation und Planung
    ('MI', 1, 'a'):
     "– Der angehende Meister kann bei erfahrenen Kollegen und Vorgesetzten "
     "Informationen über spezielle Sicherheitsvorschriften einholen.\n"
     "– Er kann in Quellen der Berufsgenossenschaft oder aus "
     "Fachzeitschriften der Branche weitere Informationen zur "
     "Arbeitssicherheit beschaffen.\n"
     "– Er schreibt wichtige Stichpunkte und Anhaltspunkte auf Karteikarten, "
     "ordnet sie chronologisch, und hat somit einen roten Faden.\n"
     "– Er bereitet die Präsentationsmedien vor, testet sie auf Tauglichkeit "
     "und übt den Ablauf der Präsentation.\n"
     "– Er sollte den gesamten Ablauf der Unterweisung mit dem Vorgesetzten "
     "absprechen.\n"
     "– Sinnvoll ist bei der Vorbereitung auch eine Absprache mit dem "
     "jeweiligen Sicherheitsbeauftragten / Ingenieur für Arbeitssicherheit.",
    ('MI', 2, 'a'):
     "Z. B.:\n– höhere Flexibilität der Produktion\n– höhere Transparenz der "
     "Prozesse\n– kürzere Reaktionszeiten auf Wünsche der Kunden",
    ('MI', 2, 'b'):
     "Z. B.:\n– Aufstellung einer Sicherheitsrichtlinie\n"
     "– Sicherheitszertifizierung/Sicherheitsaudit\n– Zutritt nur für wenige "
     "befugte Mitarbeiter\n– Überwachung der Mitarbeiter von Fremdfirmen, "
     "die in dem Raum Support leisten\n– Vier-Augen-Prinzip bei Betreten des "
     "Raumes\n– Protokollierung aller Vorgänge",
    ('MI', 2, 'c'):
     "Z. B.:\n– Datensicherheit gegen Industriespionage und Sabotage\n"
     "– in Zukunft zu übertragende Datenmengen (Abschätzung)\n– Art und "
     "Anzahl der Clients, die für die Zugriffe genutzt werden\n"
     "– Schnittstellen zu anderen IT-Systemen innerhalb des Unternehmens\n"
     "– Schnittstellen zu den IT-Systemen von Kunden und Lieferanten\n"
     "– Zeitrahmen und Meilensteine des Vorhabens\n"
     "Hinweis für den Korrektor zu den Aufgabenteilen a) bis c): Die Punkte "
     "sind zu beschreiben.",
    ('MI', 3, 'a'):
     "Z. B.:\n1. Analyse des Istzustandes: Welche IT-Kenntnisse und "
     "Qualifikationen haben die Mitarbeiter?\n2. Sollzustand: Aufstellen der "
     "Anforderungen in einem Lastenheft\n3. Auswahl eines Auftragnehmers\n"
     "4. Durchführung der Schulung\n5. Feedback, Nachbetreuung der "
     "Teilnehmer\nHinweis für den Korrektor: Andere in sich schlüssige "
     "Abläufe können ebenfalls gewertet werden.",
    ('MI', 3, 'b'):
     "– Qualifikation des Anbieters: Lehrmethoden, Material, "
     "Qualitätssicherung\n– zeitnahe Verfügbarkeit der Schulung am "
     "gewünschten Ort und unter den gewünschten technischen "
     "Voraussetzungen\n– zielgruppenorientierte Vermittlung: Die Schulung "
     "soll sich an der Qualifikation und am Wissensstand orientieren.\n"
     "– Dokumentation der vermittelten Lehrinhalte und der erreichten "
     "Leistungen, ggf. mit Teilnahmebestätigung und Zertifikat\n"
     "– verständliches und anschauliches Lehrmaterial mit Bezug auf die "
     "IT-Netze des Auftraggebers\n"
     "Hinweis für den Korrektor: Die oben genannten Anforderungen sind zu "
     "beschreiben.",
    ('MI', 4, 'a'):
     "Anhand der Summen der gewichteten Werte fällt die Entscheidung für "
     "Fahrzeug A (siehe Zeichnung).\n"
     "Hinweis für den Korrektor: Je richtig berechnetem Fahrzeug 5 Punkte, "
     "Entscheidung 1 Punkt.\n"
     "– Reichweite pro Ladevorgang (20 %): A 10 → 2,0; B 8 → 1,6; C 6 → 1,2\n"
     "– Anschaffungskosten (25 %): A 8 → 2,0; B 10 → 2,5; C 6 → 1,5\n"
     "– Ladevolumen (15 %): A 8 → 1,2; B 6 → 0,9; C 10 → 1,5\n"
     "– Nutzlast (30 %): A 8 → 2,4; B 6 → 1,8; C 8 → 2,4\n"
     "– Batterie-Ladekonzept (10 %): A 6 → 0,6; B 8 → 0,8; C 10 → 1,0\n"
     "– Summe (100 %): A 8,2; B 7,6; C 7,6",
    ('MI', 5, 'a'):
     "Erzeugnisstruktur (siehe Zeichnung): Erzeugnis E → 2 × B2, 4 × T5, "
     "2 × B3; B2 → 2 × T1, 1 × B1; B1 → 2 × T2, 3 × T3, 1 × T4; B3 → 3 × T2, "
     "2 × B6; B6 → 4 × T1, 3 × T5, 2 × T6.",
    ('MI', 5, 'b'):
     "Mengenstückliste des Erzeugnisses E:\n– Position 1: T1 – 20\n"
     "– Position 2: T2 – 10\n– Position 3: T3 – 6\n– Position 4: T4 – 2\n"
     "– Position 5: T5 – 16\n– Position 6: T6 – 8",
    ('MI', 6, 'a'):
     "Z. B.:\n– Beurteilung des finanziellen Risikos\n– Beurteilung des "
     "Funktionsrisikos\n– Beurteilung des Terminrisikos\n– Beurteilung des "
     "personellen Risikos\n– Beurteilung des juristischen Risikos\n"
     "– Beurteilung des Risikos des Imageverlustes",
    ('MI', 6, 'b'):
     "– Definitionsphase, z. B.: Mitwirken an den Projektzielen (Termin, "
     "Kosten usw.); Mitarbeiter auswählen; Analyse der Interessengruppen "
     "(Stakeholder)\n"
     "– Planungsphase, z. B.: Strukturplanung; Terminplanung; "
     "Ressourcenplanung; Kostenplanung\n"
     "– Realisierungsphase, z. B.: Starten und Beenden von Vorgängen; "
     "Soll-Ist-Vergleich; Kontrolle der Meilensteine; Probleme erkennen und "
     "lösen\n"
     "– Abschlussphase, z. B.: Dokumentation (Projektabschlussbericht); "
     "Erfahrungswerte sichern; Feedback; Überleitung der Mitarbeiter in ihre "
     "ursprünglichen Abteilungen\n"
     "Hinweis für den Korrektor: Die oben genannten Phasen sind zu "
     "beschreiben.",
    # ---- Zusammenarbeit im Betrieb
    ('ZI', 1, 'b'):
     "Z. B.:\n– Jemand lebt vor, was er von anderen erwartet.\n– Wort und Tat "
     "sind in Übereinstimmung.\n– Jemand ist bereit, zu verzichten oder zu "
     "verzeihen.\n– Verantwortung für Mitschüler oder Mitarbeiter wird "
     "übernommen.",
    ('ZI', 2, 'a'):
     "Z. B.:\n– Konflikt kann Quelle für Fehlererkennung sein oder Probleme "
     "generieren.\n– Konflikte provozieren, die bisherige Handhabung zu "
     "überdenken.\n– Konflikte können zu neuen Lösungen führen.\n"
     "– Konfliktlösungen sind geeignet, das Selbstwertgefühl zu stärken, vor "
     "allem dann, wenn sich Mitarbeiter einbringen können.\n– Konflikte "
     "sind ein Zeichen von Dynamik, wenn sie konstruktiv nutzbar sind.",
    ('ZI', 2, 'b'):
     "Z. B.:\n– Trennung von Person und Sache\n– Wertschätzung des anderen "
     "ausdrücken\n– Interesse an der Meinung anderer zeigen\n– Bereitschaft "
     "zur Selbstkritik (Fehlereinsicht)\n– keinen Machtkampf aufkommen "
     "lassen\n– gemeinsam akzeptable Lösungen suchen\n– Lösungen auch durch- "
     "und umsetzen",
    ('ZI', 3, 'a'):
     "Z. B.:\n– Gestaltung der Arbeitszeit\n– Entgeltgestaltung\n"
     "– Veränderung der Arbeitsorganisation (Job-Rotation/Fließfertigung)\n"
     "– Gestaltung der Arbeitsumgebung\n– Arbeitsplatzgestaltung\n"
     "– freiwillige soziale Leistungen\n– Anforderungen des Arbeitsplatzes\n"
     "– Umsetzung der genannten Maßnahmen und Begründung aus Sicht des "
     "Betriebes oder des Mitarbeiters",
    ('ZI', 3, 'b'):
     "mögliche Maßnahme der Umsetzung und Begründung, z. B.:\n"
     "– Gestaltung der Arbeitszeit: Dreischichtsystem; gute Ausnutzung der "
     "hochautomatisierten Maschinen\n"
     "– Entgeltgestaltung: Prämienlohn usw., flexibel einsetzbare "
     "Mitarbeiter – Anreiz zu optimaler Leistung\n"
     "(Auswahl 3 Punkte, Beschreibung 3 Punkte, insgesamt max. 9 Punkte)",
    ('ZI', 4, 'a'):
     "Ausgehend von der Bereitschaft zur Kommunikation bis zu den Regeln der "
     "Kommunikation sind die Bedingungen darzustellen, z. B.:\n"
     "– Anwendung verständlicher Kommunikationsmittel\n– Ort\n– Zeit\n"
     "– Dauer\n– Atmosphäre\n– Vertrauen\n– Offenheit\n– Takt\n"
     "– vorurteilsfrei",
    ('ZI', 4, 'b'):
     "Der Prüfungsteilnehmer soll eingehen auf z. B.:\n– Dominanz der "
     "Stärkeren\n– Verstecken der Schwachen\n– Meinungsvielfalt\n"
     "– Cliquenbildung\n– Führerschaft (formell und informell)\n– eine "
     "Bereitschaft, an Kommunikation teilzunehmen\n– „links liegen lassen“\n"
     "– Zeitfaktor\n– Mitläufer\n– mangelnde Problemidentifikation",
    ('ZI', 5, 'a'):
     "Z. B.:\n– Transparenz gegenüber dem Mitarbeiter erhöhen\n"
     "– Leistungsstand mitteilen\n– Entwicklungsmöglichkeiten aufzeigen\n"
     "– Lob und Tadel ansprechen\n– Wertschätzung vermitteln",
    ('ZI', 5, 'b'):
     "Z. B.:\n– das Gespräch freundlich eröffnen\n– den Grund der Beurteilung "
     "erklären\n– versuchen, eine eventuelle Befangenheit zu nehmen\n"
     "– gemachte Beobachtungen mitteilen und dem Mitarbeiter seine "
     "Beurteilung eröffnen\n– den Mitarbeiter Stellung nehmen lassen\n"
     "– Gesprächsergebnisse notieren und der Beurteilung beifügen\n"
     "– die Kenntnisnahme der Beurteilung vom Mitarbeiter",
    ('ZI', 7, 'a'):
     "– Bei formellen Gruppen sind die Beziehungsstrukturen der einzelnen "
     "Personen zueinander durch die Betriebsorganisation festgelegt.\n"
     "– Informelle Gruppen bilden sich durch gleiche Interessen und "
     "Neigungen, wobei die Beziehungsstrukturen der einzelnen Personen "
     "zueinander nicht durch Vorgesetzte festgelegt sind.",
    ('ZI', 7, 'b'):
     "– ähnliche Sprache (Begriffe, Ausdrücke usw.)\n– gleiches Verhalten\n"
     "– klare Rollenverteilung\n– häufige Kontakte untereinander\n"
     "– einheitliche oder ähnliche Kleidung\n– bestehendes Normensystem",
    # ---- Naturwissenschaftliche und technische Gesetzmäßigkeiten
    ('NT', 1, 'c'): "Säure + Lauge → Salz + Wasser",
    ('NT', 1, 'd'):
     "Der Umschlagbereich des Indikators Methylorange (rot ↔ gelb) liegt "
     "etwa bei dem pH-Wert 3. Bei einem pH-Wert oberhalb 3 ist die Farbe des "
     "Indikators gelb. Demzufolge ist der Nachweis einer neutralen Lösung "
     "mit dem pH-Wert 7 nicht möglich.",
    ('NT', 2, 'a'):
     "I = U / R\nR24 = R2 + R4 = 200 Ω\n"
     "1/R234 = 1/R3 + 1/R24 = 1/300 Ω + 1/200 Ω → R234 = 120 Ω\n"
     "R = R1 + R234 = 400 Ω\nI = 200 V / 400 Ω = 0,5 A\n"
     "U1 = I · R1 = 0,5 A · 280 Ω = 140 V\n"
     "U3 = U – U1 = 200 V – 140 V = 60 V\n"
     "P = U² / R → P3 = (U3)² / R3 = (60 V)² / 300 Ω = 12 W",
    ('NT', 3, 'a'):
     "v-t-Diagramm (siehe Zeichnung): 40 km/h von 0 bis 0,7 s "
     "(Reaktionszeit), gleichmäßiger Anstieg auf 50 km/h von 0,7 s bis "
     "1,7 s, danach 50 km/h bis 3,0 s.",
    ('NT', 3, 'b'):
     "s1 = v1 · t1 = 40/3,6 m/s · 0,7 s = 7,78 m\n"
     "s2 = ½ · (v0 + vt) · t = ½ · ((40 + 50)/3,6) m/s · 1 s = 12,5 m\n"
     "s3 = v3 · t3 = 50/3,6 m/s · 1,3 s = 18,06 m\n"
     "s = s1 + s2 + s3 = 38,34 m\n"
     "Der Pkw legt in den drei Sekunden 38,34 m zurück. Damit befindet er "
     "sich beim Umschalten der Ampel auf Rot noch 1,66 m vor der Ampel und "
     "passiert diese erst in der Rotphase.",
    ('NT', 4, 'a'):
     "Fz = FR\nFR = FN · μ = m · g · μ = 180 kg · 9,81 m/s² · 0,20 "
     "= 353,16 N\n"
     "FR = m · v² / r → v = √(FR · r / m) = √(353,16 N · 140 m / 180 kg)\n"
     "v = 16,57 m/s = 59,65 km/h",
    ('NT', 5, 'a'):
     "VT = VB\nV0T · (1 + 3 · αL · Δϑ) = V0B · (1 + αV · Δϑ)\n"
     "V0T + V0T · 3 · αL · Δϑ = V0B + V0B · αV · Δϑ\n"
     "Δϑ · (V0T · 3 · αL – V0B · αV) = V0B – V0T\n"
     "Δϑ = (V0B – V0T) / (V0T · 3 · αL – V0B · αV)\n"
     "Δϑ = (59,5 l – 60 l) / (60 l · 3 · 0,000012 1/°C – 59,5 l · "
     "0,0011 1/°C)\n"
     "Δϑ = 7,9 °C\nϑ = 27,9 °C",
    ('NT', 6, 'a'):
     "η = W(ab) / Q = P(ab) · t / Q\n"
     "P(ab) · t = 220.000 W · 60 s = 13.200.000 Ws\n"
     "Q = m · Hi = 0,985 kg · 42.000 kJ/kg = 41.370 kJ\n"
     "η = 13.200.000 Ws / 41.370.000 J = 0,32\nη = 32 %",
    ('NT', 7, 'a'): "x̄ = 20,095 g und s = 1,356 g",
    ('NT', 7, 'b'): "x̄ + 3s = 24,163 g und x̄ – 3s = 16,027 g",
    ('NT', 7, 'c'):
     "Die Prozessmittellage liegt sehr nahe bei der Toleranzmitte von 20 g, "
     "damit keine Veranlassung. Ausschließlich durch die Prozessstreuung "
     "werden die Toleranzen überschritten. Der 6s-Bereich beträgt 8,1 g und "
     "ist somit größer als die Toleranz von 6 g. Daraus ergibt sich eine "
     "notwendige Reduzierung der Standardabweichung von s ≤ 1 g.",
}
FRAGE = {
    # Das Liter-Zeichen „l“ las die OCR als senkrechten Strich.
    ('NT', 5, 'a'):
     "Ein Benzintank aus Stahl mit einem Volumen von 60 l bei 20 °C wird mit "
     "59,5 l Benzin gefüllt.\n"
     "Durch Sonneneinstrahlung kommt es zur Erhöhung der Temperatur. Berechnen "
     "Sie, bei welcher Temperatur der Tank überläuft.",
    ('RE', 1, 'a'):
     "Begründen Sie, wer für die Fehlzeiten\n– in 2014 und\n– in 2015\n"
     "jeweils das Entgelt von Herrn Dürr sichert.",
    ('RE', 2, 'c'):
     "Begründen Sie, welche schwerwiegende arbeitsrechtliche Maßnahme der "
     "Arbeitgeber ergreifen kann, wenn er den schuldigen Arbeitnehmer "
     "überführt, und welche zwei Vorgaben er dabei einhalten muss.",
    ('BW', 4, 'a'):
     "Ermitteln Sie\n1. den durchschnittlichen Lagerbestand für das erste "
     "Halbjahr,\n2. den Verbrauch bei Materialeinkäufen in diesem Halbjahr "
     "von 240.000 Liter,\n3. die Lagerumschlagshäufigkeit. Runden Sie auf "
     "zwei Nachkommastellen.",
    ('BW', 4, 'b'):
     "Beschreiben Sie zwei Auswirkungen einer hohen "
     "Lagerumschlagshäufigkeit.",
    ('BW', 5, 'a'):
     "Ermitteln Sie\n1. den Akkordgrundlohn pro Stunde,\n2. die von dem "
     "Arbeitnehmer erreichte Stückzahl pro Woche bei einer Vorgabezeit von "
     "4 Minuten/Stück.",
    ('BW', 7, 'a'):
     "Bestimmen Sie rechnerisch nachvollziehbar\n1. die variablen "
     "Stückkosten,\n2. die Fixkosten pro Monat und\n3. das Betriebsergebnis "
     "bei einem geplanten Beschäftigungsgrad von 90 % im März.",
    ('MI', 4, 'a'):
     "Führen Sie mit den oben stehenden Angaben die Nutzwertanalyse durch "
     "und entscheiden Sie sich für einen Lieferanten. Verwenden Sie Anlage 1 "
     "(Tabelle: Kriterien, Gewichtung, je Fahrzeug absolut und gewichtet, "
     "Summe).",
    ('NT', 1, 'b'):
     "Nachfolgend ist eine Reaktionsgleichung dargestellt, die eine "
     "Neutralisation beschreibt.\nH₂SO₄ + 2 NaOH → Na₂SO₄ + 2 H₂O\n"
     "Nennen Sie die Edukte (Ausgangsstoffe) der Reaktionsgleichung.",
    ('NT', 2, 'a'):
     "Eine gemischte Schaltung besteht aus vier Widerständen und ist an "
     "200 V angeschlossen (siehe Abbildung: R1 in Reihe, dahinter R3 "
     "parallel zur Reihenschaltung aus R2 und R4).\n"
     "U = 200 V, R1 = 280 Ω, R2 = 60 Ω, R3 = 300 Ω, R4 = 140 Ω\n"
     "Berechnen Sie den Gesamtstrom und die Leistung im Widerstand R3.",
    ('NT', 3, 'a'):
     "Vervollständigen Sie das v-t-Diagramm (Geschwindigkeit in km/h über "
     "der Zeit in s, Achsen 0 bis 60 km/h und 0 bis 3,5 s) nach diesem "
     "Muster auf Ihrem Lösungsblatt.",
}
PUNKTE = {
    # Aufgabenteil ohne lesbare Klammern (RBH 6, ZIB 5 und 6, MIKP 3) bzw.
    # Teilpunkte in Unterpunkten (BWL 7 a: 7 + 3 + 4).
    ('BW', 5, 'a'): 7, ('BW', 7, 'a'): 14,
}
LABEL = {}
DATUM = {'RE': '3. November 2016', 'BW': '4. November 2016'}
INTRO = {
    ('BW', 4):
     "Zu Beginn dieses Jahres betrug der Lagerbestand 20.000 Liter Öl. Bei "
     "den folgenden Bestandskontrollen zum Ende eines jeden Monates betrugen "
     "die Lagerbestände:\n– Januar: 24.000 Liter\n– Februar: 32.000 Liter\n"
     "– März: 15.000 Liter\n– April: 37.000 Liter\n– Mai: 42.000 Liter\n"
     "– Juni: 40.000 Liter",
    ('MI', 4):
     "In Ihrem Unternehmen soll ein E-Fahrzeug zum Ausliefern von Aufträgen "
     "im näheren Umkreis beschafft werden. Die Vorauswahl soll mithilfe der "
     "Nutzwertanalyse erfolgen. Die Geschäftsleitung hat fünf Kriterien "
     "festgelegt und gewichtet; die Fahrzeuge sollen nach den "
     "Punktetabellen bewertet werden (siehe Tabelle zu dieser Aufgabe).\n"
     "Auf dem Markt werden folgende Fahrzeuge angeboten:\n"
     "– Lieferant A bietet ein Fahrzeug mit maximaler Reichweite von 120 km "
     "und einer Nutzlast von 120 kg an. Das Ladevolumen beträgt 1,75 "
     "Kubikmeter. Die Batterie wird mit einem Ladegerät geladen. Das "
     "Fahrzeug kostet 25.000 €.\n"
     "– Lieferant B bietet ein Fahrzeug zum Preis von 18.000 € an. Die "
     "Reichweite beträgt 70 km. Die Nutzlast des Fahrzeugs beträgt 80 kg. "
     "Das Ladevolumen beträgt 1,5 Kubikmeter. Die Stromversorgung erfolgt "
     "durch eine Wechselbatterie.\n"
     "– Lieferant C bietet ein Fahrzeug an, dessen Nutzlast 110 kg beträgt. "
     "Die Reichweite beträgt 60 km. Das Ladevolumen beträgt 2 Kubikmeter. "
     "Das Fahrzeug wird induktiv geladen. Der Preis beträgt 35.000 €.",
    ('MI', 5):
     "Gegeben ist die folgende Strukturstückliste für das Erzeugnis E (siehe "
     "Tabelle zu dieser Aufgabe).",
    ('NT', 7):
     "Für die Produktion von Wuchtgewichten mit der Masse 20 g für "
     "Fahrzeugfelgen ist in den Lieferbedingungen 20 g ± 3 g vorgegeben; "
     "dieser ist von mindestens 99,73 % der produzierten Teile einzuhalten. "
     "Die Stichprobenergebnisse waren bei der Prozessüberwachung "
     "normalverteilt und zeigten die Werte in der Tabelle zu dieser Aufgabe.",
}
# Rohtext-Korrekturen der Scans (siehe korrekturen_basis.py, ROHTEXT).
ROHTEXT = {
    '02-bwl.txt': [
        # Aufgabe 4: „b)“ vor die Monatsliste gerutscht, „a)“ verschluckt.
        ('b)\n\nJanuar 24 000 Liter', 'Januar 24 000 Liter'),
        ('Ermitteln Sie\n\n1. den durchschnittlichen',
         'a) Ermitteln Sie (8 Punkte)\n\n1. den durchschnittlichen'),
        ('Beschreiben Sie zwei Auswirkungen einer hohen Lagerumschlagshäufigkeit.\n\n'
         'Lösungshinweise Aufgabe 4',
         'b) Beschreiben Sie zwei Auswirkungen einer hohen Lagerumschlagshäufigkeit. (4 Punkte)\n\n'
         'Lösungshinweise Aufgabe 4'),
        ('bb) Z.B#', 'b) Z. B.:'),
        # Lösung 7 a): „a) 1.“ als „2) 1%,“ gelesen.
        ('2) 1%, 2000 Stück , 50% = 1500 Stück', 'a) 1. x(60 %) = 1500 Stück'),
    ],
    '03-methoden.txt': [
        # Lösung 2 b) und c): Marker verschluckt.
        ('\nAufstellung einer Sicherheitsrichtlinie\n',
         '\nb) Z. B.:\nAufstellung einer Sicherheitsrichtlinie\n'),
        ('\nDatensicherheit gegen Industriespionage und Sabotage\n',
         '\nc) Z. B.:\nDatensicherheit gegen Industriespionage und Sabotage\n'),
    ],
    '04-zusammenarbeit.txt': [
        ('= _ Trennung von Person und Sache', 'b) Z. B.:\n= Trennung von Person und Sache'),
        ('E) eine Bereitschaft, an Kommunikation', '= eine Bereitschaft, an Kommunikation'),
        ('= das Gespräch freundlich eröffnen', 'b) Z. B.:\n= das Gespräch freundlich eröffnen'),
    ],
    '05-ntg.txt': [
        # Lösung 3 b): Formelblock ohne Marker am Seitenanfang.
        ('(3 Punkte)\n\n(3 Punkte)\n\nSy =V3.t3', 'b) s1 = 7,78 m (3 Punkte)\n\n(3 Punkte)\n\nSy =V3.t3'),
    ],
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
