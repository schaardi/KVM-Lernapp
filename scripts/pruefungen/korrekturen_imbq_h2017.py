# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Herbst 2017.

Erster Termin der Tranche T4 (Scans, Heftform L-ALT). Die OCR verliert in
diesen Heften die i-Punkte, Umlaute und Bruchstriche; ``ocr_scan.py`` fängt
das Wortmaterial ab, die Rechenwege der BWL- und NTG-Hefte müssen aber von
Hand aus dem Seitenbild neu geschrieben werden (LOESUNG). Zahlen im Fragetext
sind gegen das Seitenbild geprüft; wo die OCR eine Ziffer verlesen hat
(BWL 2 a: „50“ statt 60 Arbeitstage, „5 %“ statt 6 %), steht der Teil hier
neu. Aufbau und Regeln: ``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # ---- Betriebswirtschaftliches Handeln
    ('BW', 1, 'a'):
     "– Mindestgründungskapital: 25.000 €\n"
     "– Geschäftsführungsbefugnis: Geschäftsführer\n"
     "– Außenvertretungsrecht: Geschäftsführer\n"
     "– Haftung der Gesellschaft: Gesellschaftsvermögen\n"
     "– Haftung der Gesellschafter: beschränkt auf Kapitaleinlage",
    ('BW', 1, 'b'):
     "Mindestgründungskapital: 1 € pro Gesellschafter, Pflicht zum Ansparen "
     "von 25 % des jährlichen Gewinnes, bis 25.000 € erreicht sind, dann "
     "Wahlrecht zwischen UG (haftungsbeschränkt) und GmbH",
    ('BW', 2, 'a'):
     "Personalbedarf = 18.000 Std. · 1,05 / (8 Std./Tag · 60 Tage/MA · 0,82) "
     "= 48,02 Mitarbeiter\n"
     "Der Personalbedarf beträgt 48 Mitarbeiter.",
    ('BW', 2, 'b'):
     "Kapazitätsbedarf: 18.000 Std./Quartal · 1,05 = 18.900 Std./Quartal\n"
     "Kapazitätsbestand: 44 MA · 8 Std./Tag · 60 Tage/Quartal · 0,82 "
     "= 17.318,4 Std./Quartal\n"
     "Zusatzbedarf: 1.581,6 Std./Quartal\n"
     "Mehrarbeitsstunden je Mitarbeiter und Quartal = 1.581,6 Std. / "
     "(44 MA · 0,82) = 43,84 Std./MA und Quartal",
    ('BW', 3, 'a'):
     "– Liniensystem: Streng hierarchisch aufgebaut, Informationen bzw. "
     "Anweisungen können nur unter Einhaltung des Instanzenweges "
     "weitergegeben werden.\n"
     "– Stabliniensystem: Den Instanzen des Liniensystems werden im oberen "
     "Bereich z. B. Spezialisten (Experten) zur Seite gestellt, die "
     "ausschließlich beratende und entscheidungsvorbereitende Aufgaben haben, "
     "aber keine Weisungsbefugnisse.\n"
     "– Matrixsystem: Zweiliniensystem, z. B. ein Strang produktorientiert, "
     "der andere funktionsorientiert, in dem je nach Aufgabenstellung der "
     "eine oder der andere Strang eine Aufgabe einbringt, auf deren Lösung "
     "sich beide Seiten einigen müssen.",
    ('BW', 3, 'b'):
     "– Liniensystem: Vorteile, z. B.: klare Struktur, eindeutige "
     "Weisungsbefugnisse; Nachteile, z. B.: unflexibel, starr\n"
     "– Stabliniensystem: Vorteil, z. B.: klare, fachlich qualifizierte "
     "Anweisungen; Nachteile, z. B.: unflexibel, kostenintensiv\n"
     "– Matrixsystem: Vorteile, z. B.: sehr flexibel und situationsbezogen, "
     "mehr Marktnähe durch Spezialisierung (Produktmanagement); Nachteile, "
     "z. B.: hohes Konfliktpotenzial, kostenintensiv",
    ('BW', 4, 'a'):
     "Die auftragsbezogene Beschaffung wird auch als Einzelbeschaffung im "
     "Bedarfsfall bezeichnet. Der Einkauf bestellt die Ware beim Lieferanten "
     "nach Auftreten des Bedarfes, wie z. B. nach dem Eingang einer "
     "Kundenbestellung.\n"
     "Bei der Just-in-time-Beschaffung wird die Bestellung vor dem geplanten "
     "Bedarf ausgelöst. Die Anlieferung des Materials erfolgt allerdings zu "
     "dem Zeitpunkt, zu dem es in der Produktion benötigt wird "
     "(fertigungssynchrone Beschaffung).",
    ('BW', 4, 'b'):
     "Vorteile, z. B.:\n"
     "– niedrige Lagerkosten aufgrund geringer Bestände (Sicherheitsbestände)\n"
     "– geringer Lagerflächenbedarf\n"
     "– Beim Lieferanten können aufgrund großer Bestellmengen gute "
     "Konditionen durchgesetzt werden, meist durch Abschluss von "
     "Rahmenverträgen.\n"
     "Nachteile, z. B.:\n"
     "– Gefahr des Produktionsstillstandes bei Ausbleiben bzw. Verzögerungen "
     "von Lieferungen\n"
     "– relativ lange vertragliche Bindung an Lieferanten\n"
     "– geringe Flexibilität bei Änderungen des Produktionsvolumens",
    ('BW', 5, 'a'):
     "Auftragszeit: T = tr + x · te\n"
     "T = 30 min + 120 Stück · 5,75 min/Stück = 720 min = 12 Stunden",
    ('BW', 5, 'b'):
     "Fertigungslohnkosten für den Auftrag = 12 Std. · 15,50 €/Std. · 1,1 "
     "= 204,60 €",
    ('BW', 5, 'c'):
     "Zeitgrad in % = Vorgabezeit / Istauftragszeit · 100 "
     "= 12 Stunden / 10 Stunden · 100 = 120 %",
    ('BW', 5, 'd'):
     "Akkordlohn/Stunde = 204,60 € / 10 Std. = 20,46 €/Std.\n"
     "oder: Akkordlohn/Stunde = Akkordrichtsatz · Zeitgradfaktor "
     "= 15,50 €/Std. · 1,1 · 1,2 = 20,46 €/Std.",
    ('BW', 6, 'a'):
     "MEK 56,50 €\n"
     "+ MGK 16 % = 9,04 €\n"
     "= MK 65,54 €\n"
     "FLK Zerspanung 3,80 €\n"
     "+ RFGK Zerspanung 140 % = 5,32 €\n"
     "+ MAK Zerspanung 7,60 €\n"
     "FLK Montage 9,50 €\n"
     "+ FGK Montage 220 % = 20,90 €\n"
     "+ SEK (5.872 € / 800 Einheiten) = 7,34 €\n"
     "= FK 54,46 €\n"
     "= HK 120,00 €\n"
     "+ VwGK 9 % = 10,80 €\n"
     "+ VtGK 6 % = 7,20 €\n"
     "= SK 138,00 €\n"
     "+ Gewinn 20 % = 27,60 €\n"
     "= BVP 165,60 €\n"
     "+ Skonto 2 % = 4,14 €\n"
     "+ Vertreterprovision 18 % = 37,26 €\n"
     "= ZVP 207,00 €\n"
     "+ Rabatt 25 % = 69,00 €\n"
     "= LVP 276,00 €",
    ('BW', 6, 'b'):
     "SK 138,00 €\n"
     "+ Gewinn 16,56 €\n"
     "= BVP 154,56 €\n"
     "+ Skonto 2 % = 3,86 €\n"
     "+ Vertreterprovision 18 % = 34,78 €\n"
     "= ZVP 193,20 €\n"
     "+ Rabatt 30 % = 82,80 €\n"
     "= LVP 276,00 €\n"
     "prozentualer Gewinn = (16,56 € : 138,00 €) · 100 = 12 %",
    ('BW', 7, 'a'):
     "kv = ΔK / Δx = 243.000 € / 2.700 Stück = 90 €/Stück\n"
     "Kf = K – kv · x = 1.512.000 €/Monat – 90 €/Stück · 10.800 Stück/Monat "
     "= 540.000 €/Monat",
    ('BW', 7, 'b'):
     "p = U / x = 1.822.500 € / 13.500 Stück = 135 €/Stück\n"
     "xBEP = Kf / (p – kv) = 540.000 €/Monat / (135 €/Stück – 90 €/Stück) "
     "= 12.000 Stück/Monat\n"
     "BG(BEP) = xBEP / xmax · 100, mit xmax = 10.800 Stück/Monat / 72 % · 100 % "
     "= 15.000 Stück/Monat\n"
     "gilt: BG(BEP) = 12.000 Stück/Monat / 15.000 Stück/Monat · 100 = 80 %\n"
     "Alternativlösung mit den Hilfswerten: xBEP = 500.000 €/Monat / "
     "(135 €/Stück – 85 €/Stück) = 10.000 Stück/Monat; "
     "BG(BEP) = 10.000 / 15.000 · 100 = 66,67 %",
    # ---- Methoden der Information, Kommunikation und Planung
    ('MI', 1, 'c'):
     "Z. B.:\n– unterbrechungsfreie Stromversorgung\n– Brandschutzanlage\n"
     "– Alarmanlage\n– Videoüberwachung\n– Zutrittskontrolle\n"
     "– Zugangskontrolle\n– Zugriffskontrolle\n– Backup/Datensicherung\n"
     "– organisatorische Verfahrensanweisungen",
    ('MI', 2, 'b'):
     "Netzplan siehe Zeichnung (Vorgangsknoten mit FAZ, Dauer, FEZ / SAZ, "
     "Puffer, SEZ). Projektdauer 27 Zeiteinheiten.\n"
     "Kritischer Pfad: Start – B – E – G – I – Ziel",
    ('MI', 4, 'a'):
     "Kumulierte Soll- und Ist-Werte bis zum Monatsende (insgesamt zu prüfende / "
     "insgesamt geprüfte Werkzeuge):\n"
     "– Januar: 1.200 / 800\n– Februar: 2.400 / 1.600\n– März: 3.600 / 2.600\n"
     "– April: 4.800 / 4.000\n– Mai: 6.000 / 5.400\n– Juni: 7.200 / 7.200",
    ('MI', 4, 'b'):
     "Liniendiagramm „Soll-Ist-Vergleich der Prüfung von Werkzeugen“: Monate "
     "Januar bis Juni auf der x-Achse, kumulierte Anzahl der Werkzeuge (0 bis "
     "8.000) auf der y-Achse; Soll-Linie von 1.200 bis 7.200 gleichmäßig "
     "steigend, Ist-Linie von 800 bis 7.200 zunächst flacher, ab April steiler "
     "– beide treffen sich im Juni bei 7.200 (siehe Zeichnung).",
    ('BW', 7, 'c'):
     "Stückkosten: k = Kf / x + kv = 540.000 € / 15.000 Stück + 90 €/Stück "
     "= 126 €/Stück\n"
     "Stückgewinn = p – k = 135 €/Stück – 126 €/Stück = 9 €/Stück\n"
     "Alternativlösung mit den Hilfswerten: k = 500.000 € / 15.000 Stück "
     "+ 85 €/Stück = 118,33 €/Stück; Stückgewinn = 135,00 €/Stück – "
     "118,33 €/Stück = 16,67 €/Stück",
    # ---- Zusammenarbeit im Betrieb
    ('ZI', 1, 'a'):
     "Stufen der Persönlichkeitsentwicklung:\n– Kindheit\n– Jugend\n"
     "– Erwachsenenalter",
    ('ZI', 1, 'b'):
     "Z. B.:\n"
     "– Prägung durch negatives Erlebnis, z. B. Arbeitslosigkeit in der "
     "Vergangenheit – daraus resultierendes Verhalten, z. B.: Ängstlichkeit, "
     "übertrieben angepasst sein, Unterwürfigkeit; nicht eingehaltenes "
     "Versprechen des Vorgesetzten – daraus resultierendes Verhalten, z. B.: "
     "Verbitterung, Enttäuschung, Demotivation\n"
     "– Prägung durch positives Erlebnis, z. B. gutes Betriebsklima – daraus "
     "resultierendes Verhalten, z. B.: Offenheit, Vertrauen, Loyalität; Lob "
     "durch den Vorgesetzten – daraus resultierendes Verhalten, z. B.: "
     "Selbstbewusstsein, Belastbarkeit, Einsatzfreude",
    ('ZI', 2, 'a'):
     "Eine Möglichkeit der Einflussnahme ist die Vorbildfunktion, z. B.:\n"
     "– Der Meister sollte selber die Arbeits- und Pausenzeiten einhalten.\n"
     "– Dasselbe muss auch für die Einhaltung der Arbeitsschutzmaßnahmen "
     "gelten.\n"
     "– Auch sollte er bei den Arbeitsleistungen und Ergebnissen nur das "
     "verlangen, was er selber in der Lage ist, zu zeigen.",
    ('ZI', 2, 'b'):
     "Leistungsfähigkeit: Die Leistungsfähigkeit ist das, was ein "
     "Auszubildender (z. B. im Hinblick auf Veranlagung, Ausbildungs-, "
     "Entwicklungs- und Gesundheitszustand) maximal leisten kann.\n"
     "Leistungsbereitschaft: Die Leistungsbereitschaft ist der Wille (z. B. "
     "abhängig von der Motivation und der Tagesform), diese "
     "Leistungsfähigkeit auch voll auszuschöpfen.\n"
     "Hinweis für den Korrektor: Ein Beispiel ist zwingend erforderlich.",
    ('ZI', 3, 'a'):
     "Zu erläuternde Rollen sind z. B.:\n"
     "– Vorgesetzter: ist disziplinarischer oder/und fachlicher Vorgesetzter\n"
     "– Berater: gibt Entscheidungshilfen\n"
     "– Trainer: qualifiziert, schult, bildet weiter\n"
     "– Mentor: fordert, fördert und entwickelt\n"
     "– Interessensvertreter: Einhaltung von Arbeitsschutz, Arbeitsrecht\n"
     "– Vorbild: im sozialen, fachlichen und persönlichen Kompetenzbereich\n"
     "(je Erläuterung 3 Punkte, max. 9 Punkte)",
    ('ZI', 3, 'b'):
     "Unterschiede zwischen beiden Führungsstilen, z. B.:\n"
     "– Beziehung Mitarbeiter – Vorgesetzter: kooperativ – Kontakt wird "
     "ständig gehalten; autoritär – Distanz ist zu erwarten\n"
     "– Betriebsklima: kooperativ – vertrauensvoll; autoritär – Misstrauen "
     "kann von beiden Seiten ausgehen\n"
     "– Selbstkontrolle: kooperativ – wird ständig praktiziert; autoritär – "
     "wird ausgeschlossen\n"
     "– Motivation: kooperativ – Die Mitarbeiter fühlen sich wertgeschätzt "
     "und werden so eine höhere Motivation haben; autoritär – Die Motivation "
     "wird wahrscheinlich geringer sein",
    ('ZI', 4, 'a'):
     "Kriterien können z. B. sein:\n"
     "– häufige persönliche Kontakte, z. B. Fahrgemeinschaften, Kinder gehen "
     "auf die gleiche Schule, gleicher Wohnort, Nachbarn\n"
     "– gemeinsame Interessensschwerpunkte, z. B. Vereine, gleiche Hobbies, "
     "Sport\n"
     "– gleiche Zielvorstellungen, z. B. Fortbildung, Weiterbildung",
    ('ZI', 5, 'a'):
     "Maßnahmen zur Einbindung der Spezialisten sind z. B.:\n"
     "– Übernahme von Patenschaften\n"
     "– Nutzung der Spezialisten als Multiplikatoren\n"
     "– Übernahme von Arbeitsunterweisungen durch Spezialisten",
    ('ZI', 5, 'b'):
     "Z. B. Übertragung von:\n"
     "– Weisungsbefugnis gegenüber den Auszubildenden\n"
     "– Steuerung der innerbetrieblichen Einsätze\n"
     "– Berechtigung, Ausbildungsnachweise abzuzeichnen\n"
     "– Lernzielkontrollen durchführen",
    ('ZI', 6, 'a'):
     "Z. B.:\n– Zielvereinbarung\n– Kritikgespräch\n– Beurteilungen\n"
     "– Informationsrunden\n– Qualitätszirkel\n– Projektbesprechung",
    ('ZI', 6, 'b'):
     "Z. B.:\n– Bewahren Sie Ruhe.\n– Lassen Sie Ihren Gesprächspartner "
     "ausreden.\n– Hören Sie aktiv zu.\n– Stellen Sie klärende Fragen.\n"
     "– Bleiben Sie mit Ihren Mitarbeitern im ständigen Gespräch.\n"
     "– Kritisieren Sie die Sache, niemals die Person.\n"
     "– Erörtern Sie Maßnahmen zur Behebung von Mängeln gemeinsam.",
    ('ZI', 6, 'c'):
     "Z. B.:\n– Situativ-angepasstes Führen ist angebracht.\n"
     "– Berücksichtigung der Persönlichkeit, der Kenntnisse/Fähigkeiten, des "
     "Engagements sowie auch die besonderen Umstände – der Mitarbeiter ist "
     "jung, will sich beweisen, verfügt über hochaktuelles technisches "
     "Wissen.\n"
     "– Der Meister sollte ein Gespräch mit dem Mitarbeiter führen, ihn loben, "
     "ihm aber auch klarmachen, dass die tägliche Arbeit nicht leiden darf.\n"
     "– evtl. Zusatzprojekt für diesen Mitarbeiter/mit diesem Mitarbeiter "
     "konzipieren\n"
     "– dem jungen Mitarbeiter dafür Verantwortung übertragen\n"
     "– dieses Projekt in den KVP-Prozess des Unternehmens integrieren und "
     "damit auch das Ansehen der Abteilung steigern",
    # ---- Naturwissenschaftliche und technische Gesetzmäßigkeiten
    ('NT', 1, 'a'):
     "Basen können durch Reaktion von Metalloxid mit Wasser entstehen.\n"
     "Merkmale, z. B.:\n– Basen sind ätzend\n– Basen haben einen pH-Wert "
     "größer 7\n– In Wasser gelöst sind Basen „seifig“",
    ('NT', 1, 'b'):
     "Bei der Reaktion von Säuren und Basen können sich beide Stoffarten in "
     "ihrer ätzenden Wirkung aufheben. Es entsteht Wasser mit dem pH-Wert 7 "
     "(neutral) und ein Salz.",
    ('NT', 1, 'c'):
     "technische Anwendung von Säuren, z. B.:\n– Herstellung von Lacken\n"
     "– Elektrolyt in Batterien (Schwefelsäure)\n– Reinigung von Metallen\n"
     "technische Anwendung von Basen/Laugen, z. B.:\n– Herstellung von festen "
     "Seifen\n– Herstellung von Kalkmörtel\n– als Ätzmittel",
    ('NT', 2, 'a'):
     "η · E(zu) = Q(ab)\n"
     "η · P(zu) · t = c · m · ΔT\n"
     "t = c · m · ΔT / (η · P(zu))\n"
     "t = 4,18 kJ/(kg·K) · 1,5 kg · 80 K / (0,85 · 1,6 kW)\n"
     "t = 369 s\nt = 6 min 9 s",
    ('NT', 3, 'a'):
     "Ig = Pmax / U = 2.760 W / 230 V = 12 A\n"
     "I1 / I2 = R2,3 / R1 = 2 R1 / R1 = 2 / 1; mit R2,3 = R1 + R1 = 2 R1\n"
     "I1 = 2 · I2\n"
     "Ig = I1 + I2 = 2 · I2 + I2 = 3 · I2\n"
     "I2 = Ig / 3 = 12 A / 3 = 4 A\n"
     "I1 = 2 · I2 = 2 · 4 A = 8 A\n"
     "R1 = R2 = R3 = U / I1 = 230 V / 8 A = 28,75 Ω",
    ('NT', 3, 'b'):
     "Rg = 3 · R1 = 3 · 28,75 Ω = 86,25 Ω\n"
     "Ig = U / Rg = 230 V / 86,25 Ω = 2,67 A\n"
     "P = U · I = 230 V · 2,67 A = 614,1 W",
    ('NT', 3, 'c'):
     "R = ρ · L / A\n"
     "L = R · A / ρ = 28,75 Ω · (0,25 mm)² · π · m / (4 · 0,49 Ω · mm²) "
     "= 2,88 m",
    ('NT', 4, 'a'):
     "P = Fz · v\n"
     "NR: Steigung 15 % → tan α = 0,15 → Steigungswinkel α = 8,53°\n"
     "Fz = FH + FR\n"
     "FH = FG · sin α = 40.000 kg · 9,81 m/s² · sin 8,53° = 58.203,61 N\n"
     "FR = FN · μ = FG · cos α · μ = 40.000 kg · 9,81 m/s² · cos 8,53° · 0,05 "
     "= 19.402,97 N\n"
     "Fz = FH + FR = 77.606,58 N",
    ('NT', 4, 'b'):
     "P = 15 kW/t · 40 t = 600 kW = 600.000 W = 600.000 Nm/s\n"
     "v = P / Fz = 600.000 Nm/s / 77.606,58 N = 7,73 m/s\n"
     "v = 27,8 km/h",
    ('NT', 5, 'a'):
     "Winkel des Zugseils zur Waagerechten: tan α = 1 m / 2 m = 0,5 → "
     "α = 26,57°\n"
     "vertikale Komponente der Zugseilkraft: Fv = sin α · FZ = sin 26,57° · "
     "263,15 N = 117,7 N\n"
     "zulässige Masse der Leuchte: mL = Fv / g – mSt / 2 = 117,7 N / "
     "9,81 m/s² – 4 kg / 2 = 9,99 kg ≈ 10 kg",
    ('NT', 6, 'a'):
     "Q = A1 · v1 → v1 = Q / A1\n"
     "A1 = π · d² / 4 = π · (6 cm)² / 4 = 28,27 cm²\n"
     "v1 = 10.000 cm³/min / 28,27 cm² = 353,73 cm/min\n"
     "v1 = 3,54 m/min",
    ('NT', 6, 'b'):
     "Q = A2 · v2 → v2 = Q / A2\n"
     "A2 = π · (D² – d²) / 4 = π · (6² – 3²) cm² / 4 = 21,2 cm²\n"
     "v2 = 10.000 cm³/min / 21,2 cm² = 471,7 cm/min\n"
     "v2 = 4,72 m/min",
    ('NT', 6, 'c'):
     "v1 / v2 = 3,54 m/min / 4,71 m/min = 0,75 = 1 : 1,33",
    ('NT', 7, 'a'):
     "Säulendiagramm „Relative Häufigkeit der Schichtdicken“: Schichtdicke in "
     "µm (32 bis 39) auf der x-Achse, relative Häufigkeit (0 bis 30 %) auf "
     "der y-Achse; Säulen 2 %, 8 %, 16 %, 24 %, 22 %, 18 %, 8 %, 2 % (siehe "
     "Zeichnung).\n"
     "Hinweis für den Korrektor: Auch andere plausible Diagramme sollen "
     "gewertet werden.",
    ('NT', 7, 'b'):
     "x̄ = (1/n) · Σ xi\n"
     "x̄ = (32 · 1 + 33 · 4 + 34 · 8 + 35 · 12 + 36 · 11 + 37 · 9 + 38 · 4 + "
     "39 · 1) µm / 50\n"
     "x̄ = 35,52 µm (der Lösungshinweis der IHK nennt 35,53 µm)",
}
FRAGE = {
    ('BW', 1, 'a'):
     "Stellen Sie die GmbH anhand folgender Kriterien dar:\n"
     "– Mindestgründungskapital\n– Geschäftsführungsbefugnis\n"
     "– Außenvertretungsrecht\n– Haftung der Gesellschaft\n"
     "– Haftung der Gesellschafter",
    ('BW', 2, 'a'):
     "Berechnen Sie den voraussichtlichen Personalbedarf für das nächste "
     "Quartal, wenn Ihnen folgende Plandaten vorliegen:\n"
     "– Kapazitätsbedarf 18.000 Fertigungsstunden\n– Störzeitfaktor 1,05\n"
     "– tägliche Arbeitszeit 8 Stunden\n– Anzahl der Arbeitstage 60\n"
     "– Urlaub 12 %\n– Krankheitsquote 6 %",
    ('BW', 3, 'a'):
     "Beschreiben Sie zwei wesentliche Merkmale folgender Systeme:\n"
     "– Liniensystem\n– Stabliniensystem\n– Matrixsystem",
    ('BW', 7, 'b'):
     "Berechnen Sie die Break-even-Menge und den Beschäftigungsgrad an der "
     "Gewinnschwelle.\n"
     "Hinweis für den Prüfungsteilnehmer: Falls Sie a) nicht lösen konnten, "
     "nehmen Sie bei b) und c) folgende Werte als Grundlage:\n"
     "– variable Stückkosten: 85 €/Stück und\n– Fixkosten pro Monat: 500.000 €",
    ('BW', 7, 'c'):
     "Ermitteln Sie rechnerisch den Stückgewinn an der Kapazitätsgrenze.",
    ('MI', 1, 'c'):
     "Die erfassten Daten werden zentralisiert auf einem Server gespeichert. "
     "Nennen Sie sechs Maßnahmen, mit denen die Verfügbarkeit der Daten "
     "gewährleistet wird.",
    ('MI', 2, 'b'):
     "Erstellen Sie aus den Angaben in der Tabelle zu dieser Teilaufgabe einen "
     "Netzplan und kennzeichnen Sie den kritischen Pfad.",
    ('MI', 5, 'a'):
     "Beschreiben Sie für die Phasen Initiierung und Durchführung jeweils drei "
     "Aufgaben des Auftraggebers.",
    # ---- Zusammenarbeit im Betrieb
    ('ZI', 3, 'a'): "Erläutern Sie drei Rollenfunktionen des Meisters.",
    ('ZI', 3, 'b'):
     "Ihr Vorgänger hatte einen sehr autoritären Führungsstil; Sie bevorzugen "
     "den kooperativen Führungsstil.\n"
     "Erklären Sie Ihren Mitarbeitern die Unterschiede zwischen beiden "
     "Führungsstilen anhand von je vier Kriterien.",
    ('ZI', 5, 'a'):
     "Erläutern Sie drei Maßnahmen, wie Sie die Spezialisten einbinden, um "
     "ihre Erfahrung und Wissen auf andere Mitarbeiter zu übertragen.",
    # ---- Naturwissenschaftliche und technische Gesetzmäßigkeiten
    ('NT', 1, 'c'):
     "Geben Sie jeweils ein Beispiel für den technischen Einsatz von Säuren "
     "und Basen an.",
    ('NT', 2, 'a'):
     "Auf dem Typenschild eines Wasserkochers stehen die Werte 230 V/1.600 W. "
     "Wasserkocher verlieren beim Erhitzungsvorgang ca. 15 % der eingesetzten "
     "elektrischen Energie.\n"
     "Ermitteln Sie die benötigte Zeit in Minuten und Sekunden, um 1,5 l "
     "Wasser mit einer Ausgangstemperatur von 20 °C zum Sieden zu bringen.",
    ('NT', 3, 'a'):
     "In der Heizstufe II werden die Heizspiralen wie abgebildet betrieben "
     "(R1 parallel zur Reihenschaltung aus R2 und R3, siehe Abbildung).\n"
     "Berechnen Sie alle Stromstärken und den Einzel-Widerstandswert der "
     "drei Heizspiralen.",
    ('NT', 3, 'b'):
     "In der Heizstufe I werden die Heizspiralen in Reihenschaltung betrieben "
     "(siehe Abbildung).\n"
     "Berechnen Sie den Strom Ig und die Heizleistung, die jetzt erbracht "
     "wird.\n"
     "Hinweis für den Prüfungsteilnehmer: Wenn Sie den Aufgabenteil a) nicht "
     "gelöst haben, rechnen Sie mit R1 = R2 = R3 = 30 Ω weiter.",
    ('NT', 3, 'c'):
     "Ein defekter Heizwiderstand muss ersetzt werden. Es steht ein "
     "Konstantandraht mit dem Durchmesser d = 0,25 mm zur Verfügung.\n"
     "Berechnen Sie die erforderliche Länge des Drahtes.",
    ('NT', 4, 'b'):
     "Berechnen Sie die maximale Geschwindigkeit, mit der der Lkw die "
     "Steigung befahren kann.\n"
     "Hinweis für den Prüfungsteilnehmer: Wenn Sie den Aufgabenteil a) nicht "
     "gelöst haben, rechnen Sie mit 78 kN für die Zugkraft weiter.",
    ('NT', 5, 'a'):
     "Eine Leuchte soll an der abgebildeten Aufhängung befestigt werden "
     "(Zugseil vom Mast 1,0 m über der waagerechten Stange, Stange 2,0 m "
     "lang, siehe Abbildung).\n"
     "Die Stange hat eine Masse von mSt = 4 kg. Die zulässige Kraft im "
     "Zugseil wurde mit FZ = 263,15 N bestimmt. Die Masse des Zugseils ist zu "
     "vernachlässigen.\n"
     "Berechnen Sie die zulässige Masse mL der Leuchte.",
    ('NT', 6, 'a'):
     "Berechnen Sie die Ausfahrgeschwindigkeit (v1) der Kolbenstange in "
     "cm/min.",
    ('NT', 6, 'b'):
     "Berechnen Sie die Einfahrgeschwindigkeit (v2) der Kolbenstange in "
     "cm/min.",
}
PUNKTE = {}
LABEL = {}
DATUM = {}
INTRO = {
    ('ZI', 3):
     "In Ihrer Funktion als Meister in einem Produktionsbetrieb müssen Sie "
     "situativ verschiedene Rollen einnehmen.",
    ('ZI', 5):
     "Sie haben in Ihrem Betrieb einige Mitarbeiter, die sich spezialisiert "
     "und im Laufe der Zeit ein enormes Expertenwissen erworben haben. Durch "
     "betrieblich bedingte Veränderungen wechseln Produkte und Produktlinien. "
     "Die Mitarbeiter reagieren unsicher und beunruhigt, einige melden sich "
     "immer häufiger krank.\n"
     "Als Meister können Sie weder auf die komplexen Kenntnisse noch auf die "
     "soziale Kompetenz dieser Spezialisten verzichten.",
    ('NT', 1):
     "In Ihrem Unternehmen werden gefährliche Stoffe, wie z. B. Säuren oder "
     "Basen, eingesetzt.",
    ('NT', 3):
     "Sie entnehmen dem Typenschild eines Glühofens für den Laboreinsatz "
     "folgende Daten:\n– Spannung: U = 230 V~\n– maximale Heizleistung "
     "Pmax = 2.760 W\n"
     "Die drei Heizspiralen aus Konstantandraht, die den Ofen heizen, haben "
     "die gleichen Widerstandswerte: R1 = R2 = R3.\n"
     "Der Ofen verfügt über zwei Heizstufen. Die maximale Leistung von "
     "2.760 W wird in der Heizstufe II erreicht.",
    ('NT', 4):
     "Für die Entwicklung (Dimensionierung) eines Lkws mit einem maximalen "
     "Gesamtgewicht von 40 t beträgt die Leistungsvorgabe 15 kW/t.\n"
     "Auf einer Teststrecke soll der Lkw eine Steigung von 15 % befahren.\n"
     "Zu berücksichtigen ist eine Fahrwiderstandszahl μ = 0,05.\n"
     "Der Luftwiderstand ist zu vernachlässigen.",
    ('NT', 6):
     "Der Kolben eines doppelt wirkenden hydraulischen Arbeitszylinders mit "
     "einseitiger Kolbenstange wird durch einen Volumenstrom von 10 Liter pro "
     "Minute aus- und eingefahren. Der Kolbendurchmesser beträgt 6 cm, der "
     "Kolbenstangendurchmesser beträgt 3 cm (siehe Abbildung).",
    ('NT', 7):
     "In Ihrem Unternehmen werden Rohre für Leitungen beschichtet. Eine "
     "Beschichtung soll in der Dicke von 35 µm ± 7 µm ausgeführt werden. "
     "Folgende Schichtdicken wurden bei einer Stichprobe gemessen (siehe "
     "Tabelle zu dieser Aufgabe). Sie haben die Aufgabe, die Qualität des "
     "Fertigungsprozesses zu beurteilen.",
    ('MI', 4):
     "In Ihrem Meisterbereich wurden 7.200 Werkzeuge innerhalb von sechs "
     "Monaten einer technischen Überprüfung unterzogen. Pro Monat sollten laut "
     "Plan 1.200 Werkzeuge geprüft werden (Soll). Tatsächlich wurden in den "
     "einzelnen Monaten folgende Ist-Werte erreicht (tatsächlich geprüfte "
     "Werkzeuge):\n– Januar: 800\n– Februar: 800\n– März: 1.000\n"
     "– April: 1.400\n– Mai: 1.400\n– Juni: 1.800",
    ('MI', 5):
     "Alle komplexen Projekte durchlaufen vier Phasen: Initiierung, Planung, "
     "Durchführung und Abschluss. In Ihrem Unternehmen steht im kommenden Jahr "
     "ein Projekt zur Optimierung der Betriebsdatenerfassung bevor. "
     "Auftraggeber des Projektes ist die Geschäftsleitung.",
    ('BW', 5):
     "Sie sind in der Arbeitsvorbereitung der Maschinenbau GmbH beschäftigt. "
     "In der Montage sind von einem Montagewerker 120 Teile zu montieren. "
     "Dafür benötigt er zehn Stunden.\n"
     "Gehen Sie von folgendem Sachverhalt aus:\n"
     "– Vorgabezeiten: Rüstzeit 30 Minuten/Auftrag, Zeit je Einheit 5,75 Minuten\n"
     "– Akkordgrundlohn: 15,50 €/Stunde\n– Akkordzuschlag: 10 %\n"
     "Berechnen Sie",
    ('BW', 6):
     "Für ein Produkt der Maschinenbau GmbH liegen folgende Daten vor:\n"
     "– Materialeinzelkosten 56,50 €/Stück\n"
     "– Fertigungslohnkosten Zerspanung 3,80 €/Stück\n"
     "– Maschinenkosten Zerspanung 7,60 €/Stück\n"
     "– Fertigungslohnkosten Montage 9,50 €/Stück\n"
     "Für die Fertigung wird ein Spezialwerkzeug mit einem Einstandspreis von "
     "5.872 € benötigt. Die Standzeit des Werkzeuges beträgt 800 Einheiten.\n"
     "In diesem Betrieb wird mit folgenden Daten kalkuliert:\n"
     "– Materialgemeinkostenzuschlagssatz 16 %\n"
     "– Restfertigungsgemeinkostenzuschlagssatz Zerspanung 140 %\n"
     "– Fertigungsgemeinkostenzuschlagssatz Montage 220 %\n"
     "– Verwaltungsgemeinkostenzuschlagssatz 9 %\n"
     "– Vertriebsgemeinkostenzuschlagssatz 6 %\n"
     "– Gewinnzuschlagssatz 20 %\n– Skonto 2 %\n– Vertreterprovision 18 %\n"
     "– Rabatt 25 %",
    ('BW', 7):
     "Aus dem Controlling der Industrie GmbH stehen Ihnen für die Monate "
     "September und Oktober die Daten in der Tabelle zu dieser Aufgabe zur "
     "Verfügung.",
}
# Rohtext-Korrekturen der Scans (siehe korrekturen_basis.py, ROHTEXT).
ROHTEXT = {
    '04-zusammenarbeit.txt': [
        # Lösung 1 b): "b)" als "br" gelesen; Lösung 6 c): Marker verschluckt.
        ('br ZB\n', 'b) Z. B.\n'),
        ('Sıtuativ-angepasstes Führen ıst angebracht.',
         'c) Situativ-angepasstes Führen ist angebracht.'),
    ],
    '05-ntg.txt': [
        # Lösung 3 c) und 6 c): der Marker steckt im Formelsalat.
        ('p 4:0490- mm“ (6 Punkte)', 'c) L = 2,88 m (6 Punkte)'),
        ('c\n) Va 4,71 m/mın', 'c) v1/v2 = 0,75 = 1 : 1,33'),
    ],
    '03-methoden.txt': [
        # Lösung 2 b) ist die Netzplan-Zeichnung; die OCR liest darunter nur
        # den kritischen Pfad – ohne den Teil-Marker.
        ('Kritischer Pfaı Start = B = E = Bu iu Ziel\n\n(16 Punkte)',
         'b) Kritischer Pfad: Start – B – E – G – I – Ziel (16 Punkte)'),
    ],
    '01-recht.txt': [
        # Lösungskopf: die Ziffer 5 als "$" gelesen.
        ('Lösungshinweise Aufgabe $ (14 Punkte)', 'Lösungshinweise Aufgabe 5 (14 Punkte)'),
    ],
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
