# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Frühjahr 2016.

Scans (Tranche T4). Das RBH-Deckblatt setzt den Prüfungstag in einer eigenen
Spalte (DATUM). Rechenwege, Tabellen und Aufzählungen sind aus dem
Seitenbild neu geschrieben. Aufbau und Regeln: ``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # ---- Rechtsbewusstes Handeln
    ('RE', 1, 'b'):
     "– Antrag beim Arbeitsgericht auf Durchführung einer Betriebsversammlung, "
     "§ 43 IV BetrVG\n"
     "– bei Untätigkeit des Betriebsrates oder Ablehnung der Durchführung "
     "Einleitung eines Beschlussverfahrens, § 2a I Nr. 1, 10 ArbGG\n"
     "– einstweilige Verfügung, § 85 II ArbGG\n"
     "– Antrag beim zuständigen Arbeitsgericht auf Ausschluss einzelner "
     "Mitglieder aus dem Betriebsrat bzw. Auflösung des Betriebsrates "
     "aufgrund grober Pflichtverletzung, § 23 I BetrVG",
    ('RE', 2, 'a'):
     "Nein, es sind die Mitbestimmungsrechte des Betriebsrates zu beachten, "
     "§ 87 I Nr. 2 BetrVG. Ohne Zustimmung des Betriebsrates dürfen die "
     "Veränderungen nicht umgesetzt werden.\n"
     "Hinweis für den Korrektor: Auch Hinweise auf Mehrarbeit, § 87 I Nr. 3 "
     "BetrVG, sind zulässig.",
    ('RE', 2, 'b'):
     "Die Arbeit an sechs Tagen in der Woche außer sonntags ist zulässig nach "
     "§§ 3, 9 ArbZG.\n"
     "Der Zehn-Stunden-Arbeitstag ist zulässig nach § 3 Satz 2 ArbZG.\n"
     "Maximal acht Stunden Mehrarbeit im Monat, Mehrarbeit wird durch "
     "Freizeit ausgeglichen: zulässig nach § 3 ArbZG, eine 48-Stunden-Woche "
     "wird nicht überschritten.",
    ('RE', 3, 'a'):
     "1. Herr Drost erhält die ersten sechs Wochen Entgeltfortzahlung des "
     "Arbeitgebers, danach Verletztengeld durch die zuständige "
     "Berufsgenossenschaft für eine Woche, da die Betriebsfeier dem besseren "
     "Miteinander der Mitarbeiter dient und damit im betrieblichen Interesse "
     "liegt.\n"
     "2. Herr Steiner erhält sechs Wochen Entgeltfortzahlung durch den "
     "Arbeitgeber, danach zwei Wochen Krankengeld durch die "
     "Krankenversicherung, da die Arbeitsunfähigkeit im privaten Bereich und "
     "nicht bei der Arbeit entstanden ist.",
    ('RE', 3, 'b'):
     "Z. B.:\n– Sozialversicherungsbeiträge des Arbeitgebers\n– Urlaubsgeld\n"
     "– Weihnachtsgeld\n– vermögenswirksame Leistungen\n– betriebliche "
     "Altersvorsorge",
    ('RE', 4, 'b'):
     "Der Arbeitnehmer hat ein Einsichtsrecht und kann ggf. ein Mitglied des "
     "Betriebsrates hinzuziehen; der Betriebsrat allein hat kein "
     "Einsichtsrecht, § 83 I BetrVG.",
    ('RE', 6, 'a'):
     "Herr Müller könnte gegen die S-GmbH nur Ansprüche gemäß § 1 ProdHG "
     "geltend machen, wenn diese Hersteller wäre. Dies ist allerdings nicht "
     "der Fall, Hersteller ist vielmehr die MAG.\n"
     "Produkthaftungsrechtliche Ansprüche gegen die MAG scheiden aber aus, "
     "da der Fehler erst nach Inverkehrbringen des Produktes entstanden "
     "ist.\n"
     "Da die S-GmbH den Fehler, der zum Schaden bei Herrn Müller geführt "
     "hat, zumindest fahrlässig verursacht hat, ist sie Herrn Müller zum "
     "Schadensersatz gemäß § 823 BGB verpflichtet.",
    ('RE', 7, 'a'):
     "– Schriftform, § 623 BGB\n– Betriebsratsanhörung vor der Kündigung, "
     "§ 102 BetrVG\n– Kündigungsfristen, § 622 KSchG\n– bei Anwendbarkeit "
     "des Kündigungsschutzgesetzes die soziale Rechtfertigung der Kündigung, "
     "§§ 1, 23 KSchG\n– Zustimmung des Integrationsamtes, § 85 SGB IX",
    # ---- Betriebswirtschaftliches Handeln
    ('BW', 1, 'a'):
     "Z. B.:\n– Geschäftsführungsbefugnis\n– Außenvertretungsrecht\n"
     "– Stimmrecht bei der Gesellschafterversammlung\n– Gewinnverteilung\n"
     "– Haftungsumfang\n– Mindestgründungskapital\nusw.",
    ('BW', 1, 'b'):
     "Kriterien, z. B. (KG / GmbH):\n"
     "– Geschäftsführungsbefugnis, Außenvertretungsrecht: Komplementär / "
     "Geschäftsführer\n"
     "– Stimmrecht bei der Gesellschafterversammlung: nach Köpfen / nach "
     "Anteil am Stammkapital\n"
     "– Haftung: Komplementäre Vollhaftung, Kommanditisten Teilhaftung / "
     "Teilhaftung der Gesellschafter mit ihrer Kapitaleinlage\n"
     "– Mindestgründungskapital: keine gesetzliche Vorschrift / 25.000 €",
    ('BW', 1, 'c'):
     "– Geschäftsführer\n– Aufsichtsrat\n– Gesellschafterversammlung",
    ('BW', 2, 'a'):
     "– Einliniensystem, z. B.: Die nachgeordnete Stelle erhält "
     "ausschließlich von der ihr direkt vorgesetzten Instanz Weisungen; die "
     "Linie ist formaler Kommunikationsweg; streng hierarchischer Aufbau\n"
     "– Stabliniensystem, z. B.: Den Linieninstanzen werden zur "
     "Unterstützung Stäbe zugeordnet; Stäbe beraten und bereiten "
     "Entscheidungen vor; keine Weisungsbefugnisse gegenüber "
     "rangniedrigeren Hierarchieebenen\n"
     "– Zweiliniensystem (Matrixorganisation), z. B.: Funktionsmanagement "
     "und Produkt-/Projektmanagement überlappen sich vertikal, horizontal "
     "und sind gleichberechtigt; Schnittpunkte in der Matrix geben an, wo "
     "Koordinationsbedarf zwischen den Managementebenen besteht.",
    ('BW', 2, 'b'):
     "– Einliniensystem: Vorteile, z. B.: Transparenz und Einfachheit der "
     "Beziehungen; eindeutige Kommunikationswege. Nachteile, z. B.: Gefahr "
     "der Informationsfilterung durch einzelne Instanzen; lange "
     "Kommunikationswege; Gefahr der Bürokratisierung\n"
     "– Zweiliniensystem (Matrixorganisation): Vorteile, z. B.: Entlastung "
     "der Unternehmensleitung; kurze Entscheidungswege; hohe Flexibilität; "
     "Problemlösungen durch Funktionsmanager und Spezialisten (Produkt- bzw. "
     "Projektmanager). Nachteile, z. B.: hoher Bedarf an Führungskräften; "
     "Kompetenz- und Handlungskonflikte zwischen Funktions- und "
     "Produktmanagern; hoher Koordinationsbedarf\n"
     "Hinweis für den Korrektor: Die genannten Vor- und Nachteile stellen "
     "nur Beispiele dar, d. h., auch andere plausible Antworten sind "
     "zulässig.",
    ('BW', 3, 'a'):
     "Optimale Bestellmenge: x(opt) = √(2 · kB · x(ges) / (EP · iL))\n"
     "x(opt) = √(2 · 125 €/Bestellung · 30.000 Stück / (37,50 €/Stück · "
     "0,2))\n"
     "x(opt) = 1.000 Stück/Bestellung",
    ('BW', 3, 'b'):
     "Lagerumschlagshäufigkeit = Verbrauch pro Jahr / Ø Lagerbestand\n"
     "Ø Lagerbestand = x(opt) / 2 + Sicherheitsbestand = 1.000 Stück / 2 + 0 "
     "= 500 Stück\n"
     "Lagerumschlagshäufigkeit = 30.000 Stück / 500 Stück = 60",
    ('BW', 3, 'c'):
     "Bestellmenge x = 500 Stück:\n"
     "Bestellkosten = 60 Bestellungen/Jahr · 125 €/Bestellung = "
     "7.500 €/Jahr\n"
     "Lagerhaltungskosten = 250 Stück · 0,2 · 37,50 €/Stück = 1.875 €/Jahr\n"
     "Gesamtkosten = 9.375 €/Jahr\n"
     "optimale Bestellmenge x(opt) = 1.000 Stück:\n"
     "Bestellkosten = 30 Bestellungen/Jahr · 125 €/Bestellung = "
     "3.750 €/Jahr\n"
     "Lagerhaltungskosten = 500 Stück · 0,2 · 37,50 €/Stück = 3.750 €/Jahr\n"
     "Gesamtkosten = 7.500 €/Jahr\n"
     "Kostenersparnis bei Wahl der optimalen Bestellmenge ΔK(ges) = "
     "1.875,00 €/Jahr",
    ('BW', 4, 'a'):
     "Z. B.:\n– Instandhaltungsarbeiten: Die Dauer der "
     "Instandhaltungsarbeiten kann nicht präzise vorhergesagt werden.\n"
     "– Führungstätigkeiten: keine sich wiederholenden Tätigkeiten, "
     "besondere Sorgfalt erforderlich\n"
     "– Kontrolltätigkeiten: Besondere Sorgfalt ist erforderlich.\n"
     "– Entwicklung: Eine Ermittlung der individuellen Leistung ist "
     "schwierig.",
    ('BW', 4, 'b'):
     "Vorteile, z. B.:\n– einfache Lohnermittlung\n– Das Einkommen ist "
     "gleichbleibend und dadurch für den Mitarbeiter kalkulierbar.\n– mehr "
     "Qualität möglich, da kein Zeitdruck vorhanden ist\n– kein voreiliges "
     "Handeln bei gefährlichen Tätigkeiten (weniger Unfälle)\n– Reduzierung "
     "der Lohnstückkosten, wenn der Mitarbeiter eine hohe Leistung "
     "erbringt\n"
     "Nachteile, z. B.:\n– kein Anreiz zu Mehrleistung\n– keine "
     "Berücksichtigung der Leistungsunterschiede\n– Risiko verminderter "
     "Leistung und dadurch höhere Lohnstückkosten\n– mehr Personal "
     "erforderlich, da die Leistung nicht zu 100 % kontrollierbar ist",
    ('BW', 5, 'a'):
     "kalkulatorische Abschreibung = (921.600 € – 230.000 €) / 7 Jahre "
     "= 98.800 €/Jahr\n"
     "kalkulatorische Zinsen = (768.000 € + 230.000 €) · 6,5 / (100 · 2) "
     "= 32.435 €/Jahr\n"
     "Raumkosten = 30 m² · 16,25 €/m² · 12 Monate = 5.850 €/Jahr\n"
     "Energiekosten = 13,5 kW · 0,28 €/kWh · 3.250 h = 12.285 €/Jahr\n"
     "Instandhaltungskosten = 768.000 € · 8,0 / 100 = 61.440 €/Jahr\n"
     "Maschinenkosten = 210.810 €/Jahr\n"
     "Maschinenstundensatz = Maschinenkosten/Jahr / geplante "
     "Einsatzzeit/Jahr = 210.810 €/Jahr / 3.250 h/Jahr = 64,86 €/h",
    ('BW', 5, 'b'):
     "Fertigungslohn (21 €/h / 60 min/h · 42 min/Stück) 14,70 €/Stück\n"
     "+ Restfertigungsgemeinkosten (90 %) 13,23 €/Stück\n"
     "+ Maschinenkosten (105 €/h / 60 min/h · 42 min/Stück) 73,50 €/Stück\n"
     "+ Sondereinzelkosten der Fertigung 1,57 €/Stück\n"
     "= Fertigungskosten 103,00 €/Stück",
    ('BW', 6, 'a'):
     "Aus dem Diagramm (siehe Zeichnung):\n– Break-even-Menge: 250 Stück\n"
     "– Break-even-Umsatz: 25.000 €\n– fixe Gesamtkosten: 15.000 €",
    ('BW', 6, 'b'):
     "– Umsatzerlöse (U): U = 25.000 € · 450 Stück / 250 Stück = 45.000 €\n"
     "– variable Gesamtkosten (Kv): Kv = 25.000 € – 15.000 € = 10.000 € für "
     "x = 250 Stück; Kv = 10.000 € · 450 Stück / 250 Stück = 18.000 € für "
     "x = 450 Stück\n"
     "– Betriebsergebnis (BE): BE = 45.000 € – 15.000 € – 18.000 € "
     "= 12.000 €",
    ('BW', 6, 'c'):
     "– Preis (p): p = 25.000 € / 250 Stück = 100 €/Stück\n"
     "– variable Stückkosten (kv): kv = 10.000 € / 250 Stück = 40 €/Stück",
    ('BW', 6, 'd'):
     "Gesamtdeckungsbeitrag (DB): DB = 200 Stück · (100 €/Stück – "
     "40 €/Stück) = 12.000 €",
    ('BW', 7, 'a'):
     "Fertigungsmaterial 12.000,00 €\n+ 10 % Materialgemeinkosten "
     "1.200,00 €\n= Materialkosten 13.200,00 €\nFertigungslöhne 5.000,00 €\n"
     "+ 50 % Fertigungsgemeinkosten 2.500,00 €\n+ Sondereinzelkosten der "
     "Fertigung 300,00 €\n= Fertigungskosten 7.800,00 €\n= Herstellkosten "
     "21.000,00 €\n+ 15 % Verwaltungs- und Vertriebsgemeinkosten "
     "3.150,00 €\n+ Sondereinzelkosten des Vertriebes 350,00 €\n"
     "= Selbstkosten 24.500,00 €",
    ('BW', 7, 'b'):
     "Selbstkosten 24.500,00 €\n+ 25 % Gewinn 6.125,00 €\n"
     "= Barverkaufspreis 30.625,00 €",
    # ---- Methoden der Information, Kommunikation und Planung
    ('MI', 1, 'b'):
     "Hinweis für den Korrektor: Erwartet werden Beschreibungen zu zwei "
     "technischen Lösungen, wie z. B.:\n– Datensicherung auf Magnet- oder "
     "magneto-optischen Bändern nach dem Generationenprinzip\n"
     "– Datensicherung auf externen Festplattenlaufwerken\n"
     "– Datensicherung in ein externes Rechenzentrum (Cloud)",
    ('MI', 1, 'c'):
     "Hinweis für den Korrektor: Erwartet werden Beschreibungen zu fünf "
     "Anforderungen, wie z. B.:\n"
     "– Verständlichkeit: Alle Bedienelemente müssen selbsterklärend und mit "
     "einer Hilfefunktion versehen sein.\n"
     "– Eindeutigkeit: Jede Eingabe muss für die Benutzer eindeutig "
     "beschrieben sein. Das gilt auch für jede Systemrückmeldung.\n"
     "– Vermeidung von Redundanz: Identische Informationen müssen stets nur "
     "einmal eingegeben werden, nutzlose Eingaben werden vermieden.\n"
     "– Barrierefreiheit: Auch Personen mit Handicaps müssen das System "
     "bedienen können.\n"
     "– Fehlertoleranz: Fehlerhafte Eingaben führen nicht zu einem "
     "Systemversagen.",
    ('MI', 2, 'a'):
     "Paarweiser Vergleich (Zeile gegen Spalte; Summe → Gewichtung in "
     "Prozent):\n"
     "– Preis: gegen Handhabung 0, Lebensdauer 2, Kundendienst 0, laufende "
     "Kosten 0 → Summe 2 → 10 %\n"
     "– Handhabung: gegen Preis 2, Lebensdauer 1, Kundendienst 2, laufende "
     "Kosten 2 → Summe 7 → 35 %\n"
     "– Lebensdauer: gegen Preis 0, Handhabung 1, Kundendienst 0, laufende "
     "Kosten 1 → Summe 2 → 10 %\n"
     "– Kundendienst: gegen Preis 2, Handhabung 0, Lebensdauer 2, laufende "
     "Kosten 2 → Summe 6 → 30 %\n"
     "– laufende Kosten: gegen Preis 2, Handhabung 0, Lebensdauer 1, "
     "Kundendienst 0 → Summe 3 → 15 %\n"
     "Summe 20 → 100 %",
    ('MI', 4, 'a'):
     "Liniendiagramm „Entwicklung der Projektkosten“ (siehe Zeichnung): "
     "Datum 1. April bis 1. Oktober auf der x-Achse, Kosten 0 bis 90.000 € "
     "auf der y-Achse; vier Linien für geplante Gesamtkosten (waagerecht "
     "80.000 €), geplanten Kostenverlauf, tatsächlichen Kostenverlauf und "
     "geschätzte Restkosten.",
    ('MI', 4, 'b'):
     "– In der Zeit vom 1. April bis zum 1. Juli wird zunächst weniger "
     "ausgegeben als geplant.\n– Dann steigen die laufenden Kosten jedoch "
     "außerplanmäßig an und liegen ab dem Stichtag 1. August kontinuierlich "
     "über den geplanten Kosten.\n– Berücksichtigt man den Verlauf der "
     "geschätzten Restkosten, so ist zu erkennen, dass das Projekt die "
     "geplanten Gesamtkosten überschreiten wird.",
    ('MI', 5, 'a'): "1 → 2 → 3 → 4 → 5 → 8 → 9",
    ('MI', 6, 'a'):
     "Hinweis für den Korrektor: Erwartet werden Beschreibungen zu drei "
     "Schritten, wie z. B.:\n– Beschaffen der Informationen\n– Prüfen der "
     "Richtigkeit und Vollständigkeit der Informationen\n– Aufbereiten und "
     "Verdichten der Informationen (Tabellen, Grafiken usw.)",
    ('MI', 6, 'b'):
     "Hinweis für den Korrektor: Erwartet werden Beschreibungen zu fünf "
     "Inhalten, wie z. B.:\n"
     "– Zeitraum: Es sollte klar erkennbar sein, über welchen Zeitraum sich "
     "die Darstellungen im Bericht erstrecken.\n"
     "– Budget/Ressourcen: Für die Geschäftsleitung ist es wichtig, zu "
     "wissen, wie viel finanzielle Mittel und sonstige Ressourcen im "
     "Berichtszeitraum verwendet wurden.\n"
     "– Leistung: Die Geschäftsleitung möchte wissen, ob die für den "
     "Berichtszeitraum gesteckten Ziele erreicht wurden. Der Fortschritt der "
     "Arbeiten muss dargestellt werden.\n"
     "– Risiken: Risiken, die innerhalb des Berichtszeitraumes eingetreten "
     "sind oder identifiziert wurden, müssen im Bericht dargestellt werden. "
     "Risiken kosten Geld und ziehen Verzögerungen nach sich.\n"
     "– Änderungen: Es muss dargestellt werden, ob Änderungswünsche bzgl. "
     "der Projektplanung gestellt wurden und welche Auswirkungen diese ggf. "
     "auf den weiteren Verlauf haben.\n"
     "– Entscheidungen: Die Geschäftsleitung muss in einem Bericht auf die "
     "zu treffenden Entscheidungen (Abnahmen, Freigaben usw.) hingewiesen "
     "werden.",
    # ---- Zusammenarbeit im Betrieb
    ('ZI', 2, 'a'):
     "– Der Arbeitsauftrag erfolgt durch den Meister.\n– Die Gruppe hat einen "
     "offiziellen Gruppenführer.\n– Die Umsetzung des Arbeitsauftrages "
     "erfolgt eigenständig und eigenverantwortlich innerhalb der Gruppe.\n"
     "– Die Gruppe hat sich weitestgehend selbst organisiert.\n– Die "
     "Kontrolle der Arbeitsergebnisse wird durch die Gruppe selbst "
     "gewährleistet.",
    ('ZI', 4, 'a'):
     "– trägt Verantwortung für die Gruppe\n– leitet die Gruppe von außen\n"
     "– ist Vorgesetzter von allen Gruppenmitgliedern\n– schlichtet bei "
     "Konflikten, die innerhalb der Gruppe durch Gruppenmitglieder nicht "
     "selbst gelöst werden können\n– hält stets Kontakt zum Gruppenführer "
     "bzw. Stellvertreter des Meisters\n(je 3 Punkte, max. 15 Punkte)\n"
     "Hinweis für den Korrektor: Zuzulassen sind nur Antworten, die sich auf "
     "autarke Gruppen beziehen.",
    ('ZI', 5, 'a'):
     "– Primäre/intrinsische Motivation: Der Mitarbeiter ist von sich aus "
     "motiviert, hat eigene Beweggründe bzw. Anreize, um ein Ziel zu "
     "erreichen.\n"
     "– Sekundäre/extrinsische Motivation: Der Mitarbeiter wird von außen "
     "motiviert, ihm werden Beweggründe bzw. Anreize aufgezeigt, die für "
     "ihn lohnenswert und von Vorteil sein können, wenn er versucht, ein "
     "Ziel zu erreichen.\n(je 6 Punkte, max. 12 Punkte)\n"
     "Hinweis für den Korrektor: Es sind Beispiele zu erläutern.",
    ('ZI', 6, 'a'):
     "Z. B.: Ein Mitarbeiter beschwert sich über die unterschiedlichen "
     "Arbeitsbedingungen, Arbeitszeitregelungen, Parkplatzvergabe usw.",
    ('ZI', 6, 'b'):
     "Z. B.:\n– Mitarbeiter nehmen ihr Aufgabengebiet nicht richtig wahr.\n"
     "– Mitarbeiter fühlen sich ungerecht behandelt.\n– Mitarbeiter arbeiten "
     "gegen Gruppenziele.\n– Mitarbeiter verleiten andere zu unerlaubten "
     "Handlungen.\n– Mitarbeiter entwickeln keinen Teamgeist bzw. kein "
     "Wir-Gefühl.\n– Mitarbeiter sehen nur ihre eigenen Vorteile.",
    ('ZI', 6, 'c'):
     "Hinweis für den Korrektor: Beispiele für Einflussmöglichkeiten, "
     "z. B.:\n– Interventionsmaßnahmen\n– Prävention\n– Gespräche\n"
     "– Zielvereinbarungen\n– Anerkennung\n– Kritik\n– Mediation",
    ('ZI', 7, 'b'):
     "Z. B. vier Beurteilungsfehler sind zu beschreiben:\n"
     "– Überstrahlungseffekt\n– Mildefehler\n– Kontrastfehler\n"
     "– Korrekturfehler\n– Tendenz zur Mitte\n– Vorurteile\n"
     "– Pauschalurteile\n– Klischeevorstellungen\nu. a.",
    # ---- Naturwissenschaftliche und technische Gesetzmäßigkeiten
    ('NT', 1, 'c'): "U = 1,92 V",
    ('NT', 1, 'd'): "+Pol: Eisen, –Pol: Magnesium",
    ('NT', 2, 'a'):
     "PL = U² / RL → RL = U² / PL = (230 V)² / 1.000 W = 52,9 Ω\n"
     "I = U / R; R = RL + 2 · R(Ltg) = 52,9 Ω + 2 · 1,2 Ω = 55,3 Ω\n"
     "I = 230 V / 55,3 Ω = 4,16 A",
    ('NT', 2, 'b'):
     "PL = I² · RL = (4,16 A)² · 52,9 Ω = 915,1 W\n"
     "Begründung: Durch den Spannungsfall auf der Hin- und Rückleitung wird "
     "die Spannung an der Halogenlampe kleiner, dadurch verringert sich die "
     "Leistung der Halogenlampe.",
    ('NT', 3, 'a'):
     "QW = m · c · Δϑ = 3,2 kg · 4,18 kJ/(kg·°C) · 48 °C = 642,0 kJ\n"
     "QG = Hi · V̇ · t = 35.000 kJ/m³ · 8 dm³/min · 4,5 min = 35.000 kJ/m³ · "
     "0,008 m³/min · 4,5 min = 1.260 kJ\n"
     "η = QW / QG = 642,0 kJ / 1.260 kJ = 0,51",
    ('NT', 4, 'a'):
     "FZ = FH + FR\n"
     "sin α = h / L = 1,2 m / 6 m = 0,2 ⇒ α = 11,54°\n"
     "FH = FG · sin α = m · g · sin α = 1.600 kg · 9,81 m/s² · 0,2 "
     "= 3.139,2 N\n"
     "FZ = FH + FR = 3.139,2 N + 250 N = 3.389,2 N",
    ('NT', 5, 'a'):
     "Fp = p · A\nA = d² · π / 4 = (3,5 cm)² · π / 4 = 9,62 cm²\n"
     "Fp = 60 N/cm² · 9,62 cm² = 577,2 N",
    ('NT', 5, 'b'):
     "ΣM = 0\n0 = Fp · 80 mm – FG · L\nFp · 80 mm = FG · L\n"
     "577,2 N · 80 mm = 7,5 kg · 9,81 m/s² · L\n"
     "L = 577,2 N · 80 mm / (7,5 · 9,81) N\nL = 627,6 mm",
    ('NT', 6, 'a'):
     "v = 50 km/h = 13,9 m/s\n"
     "s1 = v0 · t1 = 13,9 m/s · 0,6 s = 8,34 m\n"
     "s2 = sg – s1 = 18 m – 8,34 m = 9,66 m\n"
     "s2 = (v0 + vt) / 2 · t2 → vt = 2 · s2 / t2 – v0 = 2 · 9,66 m / 1,2 s – "
     "13,9 m/s\n"
     "vt = 2,2 m/s = 7,92 km/h",
    ('NT', 6, 'b'):
     "Ekin = ½ · m · v² = ½ · 1.500 kg · (2,2 m/s)² = 3.630 J",
    ('NT', 7, 'a'):
     "Toleranzgrenzen OGW = 10,005 mm und UGW = 9,992 mm in der Urwertkarte "
     "(siehe Zeichnung)",
    ('NT', 7, 'b'): "x̄ = 10,001 mm, s = 0,002 mm",
    ('NT', 7, 'c'):
     "Die Messergebnisse zeigen eine Verschiebung der Prozesslage x̄ nach dem "
     "oberen Grenzwert OGW 10,005 mm an. Reichen die Stichprobenergebnisse "
     "schon bis an die Toleranzgrenze, ist anzunehmen, dass im gesamten "
     "Fertigungslos N Ausschussanteile vorhanden sind. (Dies zeigt auch die "
     "Prozessstreuung, die üblicherweise mit x̄ ± 3s berechnet wird.)\n"
     "x̄ – 3s = 9,995 mm; x̄ + 3s = 10,007 mm\n"
     "Wichtige Maßnahme neben dem Aussortieren ist eine Maschinenverstellung "
     "der momentanen Prozesslage x̄ = 10,001 mm in die Mitte der "
     "Toleranzzone:\n"
     "C = (OGW + UGW) / 2 = (10,005 + 9,992) mm / 2 = 9,9985 mm",
}
FRAGE = {
    ('RE', 7, 'b'):
     "Nennen Sie\n– die Frist, die Herr Fitschen bei einer Klage gegen die "
     "Änderungskündigung zu beachten hätte, und\n– das örtlich und sachlich "
     "zuständige Gericht.",
    ('BW', 1, 'b'):
     "Beschreiben Sie deren Ausgestaltung bei\n– einer Kommanditgesellschaft "
     "und\n– einer Gesellschaft mit beschränkter Haftung.",
    ('BW', 1, 'c'): "Nennen Sie die Organe einer GmbH mit 1.800 Mitarbeitern.",
    ('BW', 2, 'b'):
     "Nennen Sie je einen Vor- und einen Nachteil\n– des Einliniensystems "
     "und\n– des Zweiliniensystems.",
    ('BW', 4, 'c'):
     "Unterbreiten Sie der Geschäftsleitung einen Vorschlag, um die "
     "Nachteile des Zeitlohnes unter grundsätzlicher Beibehaltung des "
     "Zeitlohnes abzumildern.",
    ('BW', 5, 'b'):
     "Kalkulieren Sie die Fertigungskosten für ein Bauteil. Folgende "
     "Informationen liegen Ihnen vor:\n– Fertigungslohnkostensatz 21,00 € "
     "pro Stunde\n– Bearbeitungszeit 42 Minuten pro Bauteil\n"
     "– Spezialwerkzeug 1,57 € pro Bauteil\n– Maschinenstundensatz 105,00 € "
     "pro Stunde\n– Restfertigungsgemeinkostenzuschlagssatz 90 %",
    ('BW', 6, 'a'):
     "Ermitteln Sie:\n– die Anzahl der Wellen, die mindestens produziert "
     "werden müsste, um kostendeckend zu arbeiten,\n– den Umsatzerlös, der "
     "dabei erzielt wird, und\n– die fixen Gesamtkosten.",
    ('BW', 6, 'c'):
     "Berechnen Sie\n– den Preis und\n– die variablen Stückkosten\npro "
     "Welle.",
    ('BW', 7, 'a'): "die Selbstkosten",
    ('BW', 7, 'b'): "den Barverkaufspreis",
    ('MI', 2, 'a'):
     "In Ihrem Meisterbereich sollen neue Drucker angeschafft werden. Bevor "
     "Sie mithilfe der Nutzwertanalyse zu einer Entscheidung kommen, wollen "
     "Sie mithilfe des paarweisen Vergleiches die Gewichtungsfaktoren "
     "ermitteln.\nMit Ihren Meisterkollegen haben Sie sich auf folgende "
     "Vergleichsmerkmale geeinigt:\n– Preis\n– Handhabung\n– Lebensdauer\n"
     "– Kundendienst\n– laufende Kosten\nDes Weiteren haben Sie sich auf den "
     "jeweiligen Grad der Wichtigkeit folgendermaßen geeinigt:\n"
     "– Der Preis ist weniger wichtig als die Handhabung, der Kundendienst "
     "und die laufenden Kosten, jedoch wichtiger als die Lebensdauer.\n"
     "– Die Handhabung ist wichtiger als der Kundendienst und die laufenden "
     "Kosten, aber genauso wichtig wie die Lebensdauer.\n"
     "– Die Lebensdauer ist weniger wichtig als der Kundendienst und genauso "
     "wichtig wie die laufenden Kosten.\n"
     "– Der Kundendienst ist wichtiger als die laufenden Kosten.\n"
     "Zwei Kriterien A und B werden folgendermaßen verglichen: Wenn A "
     "wichtiger ist als B, erhält A zwei Punkte und B null Punkte. Wenn A "
     "und B gleich wichtig sind, erhalten beide jeweils einen Punkt.\n"
     "Erstellen Sie mithilfe der Tabelle in Anlage 1 (Tabelle zu dieser "
     "Aufgabe) den paarweisen Vergleich und ermitteln Sie für die jeweiligen "
     "Merkmale die Gewichtungen in Prozent.",
    ('NT', 7, 'b'):
     "Berechnen Sie aus den Stichprobenergebnissen den Mittelwert x̄ und die "
     "Standardabweichung s für normalverteilte Prozesse.",
}
PUNKTE = {
    # RBH 3 a): zwei Unterpunkte zu je 4 Punkten, die Klammer steht nur einmal.
    ('RE', 3, 'a'): 8,
    # ZIB 5 und 6: die Punktespalte ist mit „(je 6 Punkte, max. 12 Punkte)“
    # verschränkt und lässt sich nicht zuordnen.
    ('ZI', 5, 'a'): 12, ('ZI', 6, 'a'): 2, ('ZI', 6, 'b'): 8, ('ZI', 6, 'c'): 10,
}
LABEL = {}
DATUM = {'RE': '3. Mai 2016'}
INTRO = {
    ('RE', 2):
     "Für die Mitarbeiter in Vollzeit, die in einer 40-Stunden-Woche "
     "arbeiten, will der Arbeitgeber ohne Beteiligung des Betriebsrates "
     "folgende Regelungen treffen:\n"
     "– Es kann an sechs Tagen in der Woche außer sonntags gearbeitet "
     "werden.\n"
     "– Die tägliche Arbeitszeit kann bis zu zehn Stunden betragen, die "
     "wöchentliche Arbeitszeit beträgt 40 Stunden.\n"
     "– Die wöchentliche Arbeitszeit, die über 40 Stunden hinaus anfällt, "
     "wird auf einem Arbeitszeitkonto gutgeschrieben. Acht Stunden dürfen "
     "maximal über die vereinbarte Arbeitszeit hinaus im Monat auf dem "
     "Arbeitszeitkonto angesammelt werden. Die unter Umständen geleistete "
     "Mehrarbeit wird durch Freizeit innerhalb eines halben Kalenderjahres "
     "ausgeglichen.",
    ('BW', 3):
     "Die Beschaffungsprozesse der Industrie AG sollen unter "
     "Kostengesichtspunkten analysiert werden. Exemplarisch soll das "
     "Kosteneinsparpotenzial anhand eines Kaufteiles aufgezeigt werden. Es "
     "wird ein kontinuierlicher Bedarf angenommen. Ein Sicherheitsbestand "
     "wird nicht gehalten.\nFolgende Daten liegen Ihnen zur "
     "Entscheidungsfindung vor:\n– Jahresbedarf 30.000 Stück\n"
     "– Einstandspreis 37,50 €/Stück\n– Bestellkosten je Bestellvorgang "
     "125 €\n– Lagerhaltungskostensatz 20 % pro Jahr",
    ('BW', 5):
     "In einem Unternehmen soll ein neues Bearbeitungszentrum angeschafft "
     "werden. Für die Maschine liegen folgende Daten vor:\n"
     "– Anschaffungskosten 768.000 €\n– Wiederbeschaffungswert 921.600 €\n"
     "– Nutzungsdauer 7 Jahre\n– Restwert 230.000 €\n– jährliche Einsatzzeit "
     "3.250 Stunden\n– Platzbedarf 30 m²\n– Energiebedarf pro Stunde "
     "13,5 kW\nIn diesem Betrieb wird mit folgenden Daten gerechnet:\n"
     "– kalkulatorischer Zinssatz 6,5 % pro Jahr\n– kalkulatorische Miete "
     "16,25 €/m² im Monat\n– Energiekosten pro Stunde 0,28 €/kW\n"
     "– Instandhaltungskostensatz 8 % von den Anschaffungskosten pro Jahr",
    ('BW', 6):
     "Die Geschäftsführung legt Ihnen nachfolgende Grafik vor, um mit Ihnen "
     "die Kostensituation einer Sonderanfertigung von Wellen zu besprechen "
     "(Kosten-Umsatz-Diagramm, siehe Abbildung).",
    ('BW', 7):
     "Für einen Auftrag der Industrie GmbH stehen Ihnen folgende Angaben "
     "zur Verfügung:\n– Fertigungsmaterial 12.000 €\n– Fertigungslöhne "
     "5.000 €\n– Kosten für Spezialwerkzeug 300 €\n– Kosten für "
     "Spezialverpackung 350 €\n– Gewinnzuschlag 25 %\n"
     "Gemeinkostenzuschlagssätze:\n– Materialgemeinkosten 10 %\n"
     "– Fertigungsgemeinkosten 50 %\n– Verwaltungs- und "
     "Vertriebsgemeinkosten 15 %\nBerechnen Sie:",
    ('MI', 4):
     "In der Tabelle zu dieser Aufgabe sind einige Kennzahlen eines "
     "Projektes über den Zeitraum vom 1. April bis zum 1. Oktober "
     "dargestellt.",
    ('MI', 5):
     "Ihre Abteilung ist für die Durchführung eines Projektes "
     "verantwortlich. Die Ablaufplanung ist in dem Balkenplan (siehe "
     "Abbildung) dargestellt. Das Projekt beginnt am Montag, dem 6. März, "
     "und endet am Freitag, dem 7. April. Im Balkenplan sind die "
     "arbeitsfreien Wochenenden grau markiert.",
    ('ZI', 2):
     "Der neue Mitarbeiter wurde in einer betrieblichen Ausbildungswerkstatt "
     "ausgebildet. Während seiner Ausbildung lernte er verschiedene Formen "
     "der Arbeitsorganisation kennen. Die Organisation in teilautonomen "
     "Arbeitsgruppen, die in Ihrem Unternehmen bevorzugt wird, ist ihm "
     "jedoch nicht sehr vertraut. Sie wollen dem Mitarbeiter eine "
     "entsprechende Einführung geben.",
    ('NT', 5):
     "Ein Sicherheitsventil soll bei einem Druck von 6 bar öffnen (siehe "
     "Abbildung: Hebel mit Drehpunkt, Ventilteller Ø 35 mm im Abstand 80 mm, "
     "verschiebbare Masse m im Abstand L).",
    ('NT', 7):
     "Der Innendurchmesser eines Gleitlagers ist mit Ø 10 +0,005/–0,008 mm "
     "toleriert. Die letzten zwölf Stichprobenmessungen werden in einer "
     "Urwertkarte dargestellt und zeigen die in Anlage 1 (siehe Abbildung) "
     "dargestellten Ergebnisse.",
}
# Rohtext-Korrekturen der Scans (siehe korrekturen_basis.py, ROHTEXT).
ROHTEXT = {
    '03-methoden.txt': [
        # Lösung 6 b): ein Aufzählungsquadrat als „D)“ gelesen.
        ('\nD) Risiken:\n', '\n= Risiken:\n'),
    ],
    '05-ntg.txt': [
        # Lösung 5 b) und 6 b): Marker im Formelsalat verschluckt.
        ('\na = a\n s=voch', '\na) s1 = v0 · t1\n s=voch'),
        ('»  YMm=0', 'b) ΣM = 0'),
        ('\nExin = MV\n', '\nb) Ekin = ½ m v²\n'),
    ],
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
