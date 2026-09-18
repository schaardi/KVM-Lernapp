# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Frühjahr 2017.

Scans (Tranche T4). Rechenwege der BWL- und NTG-Hefte, Tabellen und
Aufzählungen sind aus dem Seitenbild neu geschrieben; Zahlen im Fragetext
gegen das Seitenbild geprüft. Aufbau und Regeln: ``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # ---- Rechtsbewusstes Handeln
    ('RE', 1, 'b'):
     "sechs Werktage = drei volle Monate Beschäftigung à zwei Werktage "
     "(§ 3 Abs. 1 i. V. m. § 5 Abs. 1b Bundesurlaubsgesetz)",
    ('RE', 1, 'c'):
     "Die Behandlungskosten werden nicht von der gesetzlichen "
     "Unfallversicherung übernommen, weil es sich nicht um einen Arbeitsunfall "
     "handelt. Es fehlt an einem hinreichenden betrieblichen Bezug. Die "
     "Krankenversicherung kommt für die Behandlungskosten auf. Die "
     "Krankenkasse zahlt Krankengeld für die Dauer der Arbeitsunfähigkeit "
     "(§ 3 Abs. 3 Entgeltfortzahlungsgesetz).",
    ('RE', 2, 'd'):
     "Angelegenheiten, die in Betriebsvereinbarungen geregelt werden können, "
     "z. B.:\n– Fragen der betrieblichen Ordnung\n– Regelungen, die die "
     "Arbeitszeit betreffen\n– Pausenregelung\n– Regelung der betrieblichen "
     "Lohngestaltung\n– Grundsätze über das betriebliche Vorschlagswesen\n"
     "– Teilnahme an betrieblichen Bildungsmaßnahmen",
    ('RE', 3, 'a'):
     "Z. B.:\n– Die Befristung ist zulässig, weil sie im Anschluss an eine "
     "Ausbildung erfolgt, um den Übergang in eine Beschäftigung zu erleichtern "
     "(§ 14 Abs. 1 Nr. 2 TzBfG). Somit liegt ein sachlicher Grund für die "
     "Befristung vor.\n– Die Schriftform nach § 14 Abs. 4 TzBfG wurde "
     "eingehalten.\n– Auch eine sachgrundlose Befristung gemäß § 14 Abs. 2 "
     "TzBfG wäre wirksam, da ein Ausbildungsverhältnis kein Arbeitsverhältnis "
     "darstellt.",
    ('RE', 4, 'a'):
     "Diese ergeben sich aus § 6 ASiG, z. B.:\n– Beratung des Arbeitgebers und "
     "der anderen Betriebsmitglieder in Sachen des Arbeitsschutzes\n"
     "– Überwachung der Einhaltung der Vorschriften des Arbeitsschutzes\n"
     "– Ursachen von Arbeitsunfällen untersuchen\n– Arbeitsstätten regelmäßig "
     "begehen, Mängel melden und auf deren Beseitigung hinwirken\n"
     "– Zusammenarbeit mit Betriebsarzt und Betriebsrat",
    ('RE', 4, 'b'):
     "Anforderungen an Fachkräfte für Arbeitssicherheit, § 7 ASiG:\n"
     "– Ingenieur + sicherheitstechnische Fachkunde = Sicherheitsingenieur\n"
     "– Herr Schmidt erfüllt diese Anforderungen nicht, da ihm die "
     "sicherheitstechnische Fachkunde fehlt.",
    ('RE', 5, 'a'):
     "– Vorsorgeprinzip: Umweltpolitik soll bereits vorsorgend den Eintritt "
     "von Umweltbelastungen innerhalb der Gefahrenschwelle verhindern. Durch "
     "vorausschauendes Handeln und vorzeitigen Einsatz entsprechender "
     "Maßnahmen soll die Abwehr von Gefahren und die Beseitigung von Schäden "
     "möglichst am Ursprung erreicht werden, um nachhaltigen Nutzen zu "
     "erzielen.\n"
     "– Verursacherprinzip: Kosten zur Vermeidung, zur Beseitigung und zum "
     "Ausgleich von Umweltbeeinträchtigungen sollen demjenigen zugerechnet "
     "werden, der sie verursacht hat (= Grundsatz der Kostenzurechnung).\n"
     "– Kooperationsprinzip\n– Subsidiaritätsprinzip",
    ('RE', 5, 'c'):
     "– Immissionen: die auf Menschen, Tiere, Pflanzen usw. einwirkenden "
     "schädlichen Umwelteinwirkungen wie Luftverunreinigungen, Geräusche, "
     "Erschütterungen, Licht, Wärme, Strahlen\n"
     "– Emissionen: die von einer Anlage ausgehenden Luftverunreinigungen, "
     "Geräusche, Erschütterungen, Licht, Wärme, Strahlen",
    ('RE', 6, 'c'):
     "Der Arbeitgeber kann gegen den Hersteller Schadensersatz in Höhe des "
     "entstandenen Verdienstausfalles des Herrn Semmler geltend machen, denn "
     "der Arbeitgeber leistet gegenüber Herrn Semmler während dessen "
     "Arbeitsunfähigkeit Entgeltfortzahlung.",
    ('RE', 7, 'a'):
     "Die B-GmbH muss den Mitarbeitern mitteilen, dass es sich bei der Prämie "
     "um eine freiwillige Leistung handelt, auf die auch bei mehrmaliger "
     "Gewährung kein Rechtsanspruch für die Zukunft entsteht. Sie sollte sich "
     "diesen Vorbehalt von den Mitarbeitern bestätigen lassen.",
    ('RE', 7, 'b'):
     "Der Betriebsrat ist bei freiwilligen Leistungen nur hinsichtlich "
     "eventueller Verteilungsgrundsätze nach § 87 Abs. 1 Nr. 10 BetrVG zu "
     "beteiligen, nicht jedoch bei der Entscheidung über eine Zahlung.",
    # ---- Betriebswirtschaftliches Handeln
    ('BW', 1, 'a'):
     "– GmbH: Geschäftsführungsbefugnis Geschäftsführer; Haftung beschränkt "
     "auf Kapitaleinlage; Mindestgründungskapital 25.000 €\n"
     "– OHG: jeder Gesellschafter; unbeschränkt, d. h. mit Geschäfts- und "
     "Privatvermögen; nicht vorgeschrieben\n"
     "– KG: Komplementär; Komplementär ist Vollhafter, Kommanditist haftet "
     "mit Einlage (Teilhafter); nicht vorgeschrieben",
    ('BW', 1, 'c'):
     "Im Falle eines Gewinnes müssen 25 % der Jahresgewinnsumme angespart "
     "werden, bis 25.000 € und damit die Option zur Gründung einer GmbH "
     "erreicht ist.",
    ('BW', 2, 'a'):
     "Kapazitätsbestand = Anzahl Mitarbeiter · Arbeitszeit pro Tag · Anzahl "
     "Arbeitstage pro Periode · Planungsfaktor\n"
     "Kapazitätsbestand = 24 Mitarbeiter · 8 Std./Tag · 20 Tage · 0,85 "
     "= 3.264 Std.\n"
     "Kapazitätsbedarf = Anzahl Bauteile · Vorgabezeit pro Bauteil / 60 Minuten "
     "pro Stunde = 1.500 Teile · 160 min/Bauteil / 60 min/Std. = 4.000 Std.\n"
     "Zusatzbedarf = Kapazitätsbedarf – Kapazitätsbestand = 4.000 Std. – "
     "3.264 Std. = 736 Std.",
    ('BW', 2, 'b'):
     "Mehrarbeit pro Mitarbeiter und Tag = Zusatzbedarf / (Anzahl Mitarbeiter · "
     "Anzahl Arbeitstage · Planungsfaktor · Zeitgradfaktor)\n"
     "= 736 Std. / (24 Mitarbeiter · 20 Tage · 0,85 · 1,1) = 1,64 Std./Tag",
    ('BW', 3, 'a'):
     "durchschnittlicher Lagerbestand = (Anfangsbestand + 6 Monatsbestände) / 7\n"
     "durchschnittlicher Lagerbestand = 252 t / 7 = 36 t",
    ('BW', 3, 'b'):
     "Materialverbrauch = Anfangsbestand + Zugänge – Endbestand\n"
     "Materialverbrauch = 22 t + 210 t – 40 t = 192 t",
    ('BW', 3, 'c'):
     "Lagerumschlagshäufigkeit = Verbrauch pro Jahr / Ø Lagerbestand\n"
     "Lagerumschlagshäufigkeit = 420 t / 45 t = 9,33",
    ('BW', 3, 'd'):
     "Z. B.:\n– Eine hohe Lagerumschlagshäufigkeit kann zu geringeren "
     "Kapitalbindungs- und Lagerkosten führen.\n– Eine hohe "
     "Lagerumschlagshäufigkeit reduziert das Risiko einer Veralterung der "
     "Lagerbestände.\n– Bestellkosten erhöhen sich, die Lieferbereitschaft "
     "wird durch geringe Lagerbestände eingeschränkt.",
    ('BW', 4, 'a'):
     "Zeitgrad in % = Vorgabezeit / Istauftragszeit · 100 = 34,5 Stunden / "
     "30 Stunden · 100 = 115 %",
    ('BW', 4, 'b'):
     "Akkordrichtsatz pro Stunde = Akkordgrundlohn + Akkordzuschlag "
     "= 16 €/Stunde + 10 % = 17,60 €/Stunde\n"
     "tatsächlicher Stundenlohn = Akkordrichtsatz/Stunde · Zeitgradfaktor "
     "= 17,60 €/Std. · 1,15 = 20,24 €/Stunde",
    ('BW', 4, 'c'):
     "Lohnkosten pro Auftrag = Akkordlohn · Istzeit = 20,24 €/Std. · "
     "30 Stunden = 607,20 €\n"
     "bzw. = Akkordrichtsatz · Vorgabezeit = 17,60 €/Std. · 34,5 Stunden "
     "= 607,20 €",
    ('BW', 4, 'd'):
     "Lohnkosten/Stück = Akkordrichtsatz/Stunde · Vorgabezeit / Auftragsmenge "
     "= 17,60 €/Std. · 34,5 Std. / 1.200 Teile = 0,506 €/Stück\n"
     "oder Lohnkosten/Stück = Akkordlohn/Stunde · Istzeit / Auftragsmenge "
     "= 20,24 €/Std. · 30 Std. / 1.200 Teile = 0,506 €/Stück\n"
     "oder Lohnkosten/Stück = Lohnkosten pro Auftrag / Auftragsmenge "
     "= 607,20 € / 1.200 Stück = 0,506 €/Stück",
    ('BW', 5, 'a'):
     "Kalkulatorische Abschreibung = (WBW – RW) / n = (561.000 € – 120.000 €) "
     "/ 6 Jahre = 73.500 €/J\n"
     "Kalkulatorische Zinsen = (AK + RW) / 2 · Zinssatz = (510.000 € + "
     "120.000 €) / 2 · 6 % = 18.900 €/J\n"
     "Raumkosten = Flächenbedarf · Mietpreis · 12 Monate/Jahr = 16 m² · "
     "14,00 €/m² · Monat · 12 Monate/Jahr = 2.688 €/J\n"
     "Energiekosten = Energieverbrauch · Energiekosten · Laufzeit = 15 kW · "
     "0,21 €/kWh · 3.000 Stunden/Jahr = 9.450 €/J\n"
     "Instandhaltungskosten = AK · Instandhaltungskostensatz = 510.000 € · "
     "8 % = 40.800 €/J\n"
     "Maschinenkosten/Jahr (Summe) = 145.338 €/J\n"
     "Maschinenstundensatz = Maschinenkosten / Laufzeit = 145.338 €/J / "
     "3.000 Std./J = 48,45 €/Std.",
    ('BW', 5, 'b'):
     "Maschinenkosten/Jahr = 145.338 €/J\n"
     "– Energiekosten [alt] = –9.450 €/J\n"
     "+ Energiekosten = 15 kW · 0,21 €/kWh · 3.300 Stunden/Jahr = 10.395 €/J\n"
     "Maschinenkosten/Jahr (Summe) = 146.283 €/J\n"
     "Maschinenstundensatz = Maschinenkosten / Laufzeit = 146.283 €/J / "
     "3.300 Std./J = 44,33 €/Std.",
    ('BW', 6, 'a'):
     "Beschäftigungsgrad BG: 80 % / 100 %\n"
     "– Menge in Stück x: 96.000 Stück / 120.000 Stück\n"
     "– fixe Stückkosten kf: 12,50 €/Stück / 10,00 €/Stück\n"
     "– gesamte Fixkosten Kf: 1.200.000 € / 1.200.000 €\n"
     "– gesamte variable Kosten Kv: 1.440.000 € / 1.800.000 €\n"
     "– Stückdeckungsbeitrag db: 12,00 €/Stück / 12,00 €/Stück\n"
     "– Gesamtdeckungsbeitrag DB: 1.152.000 € / 1.440.000 €\n"
     "– Betriebsergebnis BE: –48.000 € / 240.000 €",
    ('BW', 7, 'a'):
     "Fertigungsmaterial 28,00 €\n+ Material-GK (15 %) 4,20 €\n"
     "= Materialkosten 32,20 €\nFertigungslöhne 35,00 €\n"
     "+ Fertigungs-GK (215 %) 75,25 €\n= Fertigungskosten 110,25 €\n"
     "Herstellkosten 142,45 €\n+ Verwaltungs-GK (22 %) 31,34 €\n"
     "+ Vertriebs-GK (13 %) 18,52 €\n+ SEV 2,00 €\n= Selbstkosten 194,31 €\n"
     "+ Gewinn pro Stück 48,53 €\n= Barverkaufspreis 242,84 €\n"
     "+ Skonto (2 %) 4,96 €\n= Zielverkaufspreis 247,80 €\n"
     "+ Rabatt (16 %) 47,20 €\n= Listenverkaufspreis 295,00 €\n"
     "Gewinnzuschlag = 48,53 € · 100 / 194,31 € = 24,98 %",
    # ---- Methoden der Information, Kommunikation und Planung
    ('MI', 1, 'b'):
     "Z. B.:\n– höhere Gewalt\n– Versagen der Technik\n– Fahrlässigkeit\n"
     "– Computersabotage bzw. Computerspionage",
    ('MI', 1, 'c'):
     "Z. B.:\n– Aufstellen einer Sicherheitsrichtlinie\n– Aufstellen eines "
     "Wartungsplanes\n– Vergabe von Benutzerrechten für den Datenzugriff\n"
     "– Belehrungen und regelmäßige Nachweisführung\n– Verpflichtung auf das "
     "Datengeheimnis bzw. die Vertraulichkeit",
    ('MI', 1, 'd'):
     "Aus Sicht des Datenschutzes ist z. B. zu beachten:\n– Es dürfen nicht "
     "mehr Daten gespeichert werden, als unbedingt notwendig sind "
     "(Datensparsamkeit).\n– Die Mitarbeiter müssen Auskunft über die Daten "
     "erhalten, die über sie erhoben wurden.\n– Es muss jederzeit nachweisbar "
     "sein, welche Mitarbeiter bzw. Führungskräfte Zugriff auf die "
     "personenbezogenen Daten hatten und wer diese Daten geändert hat.",
    ('MI', 2, 'a'):
     "Ursache-Wirkungs-Diagramm (siehe Zeichnung): Hauptachsen Mensch, "
     "Methode, Maschine, Milieu (Umwelt) und Material laufen auf die Wirkung "
     "„Qualitätsprobleme“ zu.",
    ('MI', 2, 'b'):
     "– Das Ursache-Wirkungs-Diagramm ermöglicht eine systematische "
     "Ursachenforschung. Es werden im Idealfall keine Ursachen übersehen.\n"
     "– Das Ursache-Wirkungs-Diagramm kann in einer Gruppe bearbeitet werden, "
     "wobei mehrere Teilnehmer einen unterschiedlichen Blick auf die Ursachen "
     "haben.",
    ('MI', 2, 'c'):
     "– Es können keine Kausalketten dargestellt werden. Jede Ursache steht "
     "für sich allein, obwohl die Ursachen oft voneinander abhängig sind.\n"
     "– Beim Erstellen des Ursache-Wirkungs-Diagramms fehlen oft Zahlen, "
     "Daten oder Fakten, die zum Erkennen von Ursachen notwendig wären.\n"
     "– Die Gewichtung der Ursachen kann nicht direkt aus dem Diagramm "
     "abgelesen werden.",
    ('MI', 2, 'd'):
     "Das Ishikawa-Diagramm kann z. B. zur Suche nach den Ursachen von\n"
     "– Arbeitsunfällen,\n– Produktionsstörungen,\n– Kostensteigerungen,\n"
     "– Datenverlusten\nverwendet werden.",
    ('MI', 3, 'a'):
     "– Der Raum muss rechtzeitig geöffnet und für die Präsentation "
     "vorbereitet werden.\n– Der Vortragende muss die Technik rechtzeitig vor "
     "dem Termin auf Funktion prüfen oder prüfen lassen.\n– Bei "
     "Präsentationen mit elektronischen Medien sollte ein Ersatzgerät sofort "
     "bereitstehen und nicht erst besorgt werden müssen.\n– Bei Änderungen "
     "des geplanten Ablaufes müssen die Teilnehmer rechtzeitig informiert "
     "werden.\n– Es muss ein Zeitpuffer eingeplant werden, damit die "
     "Präsentation auch bei Verzögerungen oder Unterbrechungen noch komplett "
     "abgehalten werden kann.",
    ('MI', 4, 'a'):
     "Netzdiagramm mit den fünf Achsen Spurführung, Entfernung, Preis, "
     "Batterieladekonzept und Nutzlast (Skala 0 bis 10); Fahrzeug A: 8 / 6 / 8 "
     "/ 6 / 8, Fahrzeug B: 6 / 8 / 10 / 8 / 6 – jeweils als geschlossener "
     "Linienzug (siehe Zeichnung).",
    ('MI', 4, 'b'):
     "Das Netzdiagramm kann z. B. auch bei der Bewertung\n– der Stärken und "
     "Schwächen (bzw. des Potenzials) von Mitarbeitern,\n– der Leistungen von "
     "Lieferanten oder\n– des Wertes von Kunden für das Unternehmen\n"
     "eingesetzt werden. Eine weitere Anwendungsmöglichkeit ist der "
     "Soll-Ist-Vergleich bei der Auswertung von Zielen.",
    ('MI', 5, 'a'):
     "Balkenplan (siehe Zeichnung): A Tag 1–7; I Tag 3–4; B Tag 8–10; "
     "E Tag 8–9; F Tag 10–11; C Tag 11–12; H Tag 11; G Tag 12; D Tag 13–15.",
    ('MI', 5, 'c'):
     "Es können z. B. folgende Schritte beschrieben werden:\n– die Risiken des "
     "Projektes identifizieren\n– Wahrscheinlichkeit des Eintretens des "
     "Risikos ermitteln\n– Intensität der Auswirkungen des Risikos "
     "kalkulieren\n– jedes erkannte Risiko in eine Risikomatrix einordnen",
    ('MI', 6, 'a'):
     "Die Geschäftsleitung kann z. B.\n– eine schriftliche Meinungsumfrage "
     "unter den Mitarbeitern durchführen lassen,\n– ein System zur Bewertung "
     "der Führungskräfte durch ihre Mitarbeiter einführen,\n– einen "
     "Betriebsdurchgang mit Kontakt zu den Mitarbeitern vor Ort durchführen,\n"
     "– eine Betriebsversammlung oder mehrere Bereichsversammlungen "
     "durchführen,\n– Mitarbeiter aus mehreren Ebenen zu Gesprächsrunden oder "
     "Einzelgesprächen einladen.",
    ('MI', 6, 'b'):
     "Offene Fragen können z. B. eingesetzt werden, um\n– die Motivation und "
     "die Ziele von Mitarbeitern zu erfragen,\n– Ideen und Vorschläge der "
     "Mitarbeiter zu erfassen,\n– ein Stimmungsbild der Mitarbeiter zu "
     "erhalten.\nGeschlossene Fragen können z. B. eingesetzt werden, um\n"
     "– Sachverhalte eindeutig zu klären,\n– Missverständnisse "
     "auszuschließen,\n– eine Auswahl unter zwei oder mehreren Möglichkeiten "
     "treffen zu lassen.",
    # ---- Zusammenarbeit im Betrieb
    ('ZI', 1, 'b'):
     "Hinweis für den Korrektor: Ein Beispiel ist gefordert, das die "
     "fachliche und soziale Komponente enthält. Es muss deutlich werden, dass "
     "sich fachliche Kompetenzen durch arbeitsplatzbezogene Unterweisungen "
     "vermitteln lassen und soziale Kompetenzen aufgrund persönlicher und "
     "sozialer Gegebenheiten gefördert werden können.",
    ('ZI', 2, 'a'):
     "Merkmale, z. B.:\n– Der Arbeitsauftrag erfolgt durch den Meister.\n"
     "– Die Gruppe hat einen offiziellen Gruppenführer.\n– Die Umsetzung des "
     "Arbeitsauftrages erfolgt eigenständig und eigenverantwortlich innerhalb "
     "der Gruppe.\n– Die Gruppe hat sich weitestgehend selbst zu "
     "organisieren.\n– Die Kontrolle der Arbeitsergebnisse wird durch die "
     "Gruppe selbst gewährleistet.",
    ('ZI', 2, 'b'):
     "Mögliche Entwicklungsphasen, z. B.:\n– Forming – Orientierungsphase\n"
     "– Storming – Konfliktphase\n– Norming – Vertrautheitsphase\n"
     "– Performing – Differenzierungsphase",
    ('ZI', 3, 'a'):
     "– Der Ablauf der Themenvermittlung kann genau geplant werden.\n– Ein "
     "geplanter Ablauf kann eingehalten werden.\n– zeitsparender als andere "
     "Methoden der Wissensvermittlung\n– Alle Mitarbeiter können gleichzeitig "
     "eingewiesen werden.",
    ('ZI', 3, 'b'):
     "– Einleitung: Begrüßung der Mitarbeiter; Anlass und Thema vorstellen; "
     "den Mitarbeitern die Befangenheit nehmen; Mitarbeiter motivieren\n"
     "– Hauptteil: betriebliche Situation darstellen; Arbeitsorganisation "
     "erläutern; Beispiele präsentieren; Argumente für diese "
     "Arbeitsorganisation nennen; Sachverhalte durch Medieneinsatz "
     "verdeutlichen; schriftliche Informationen zum Nachlesen verteilen\n"
     "– Schluss: kurze Zusammenfassung geben; zur Zusammenarbeit auffordern; "
     "für das Zuhören bedanken\n"
     "Hinweis für den Korrektor: Auch ein anderer sachlogischer und "
     "nachvollziehbarer Vortragsablauf ist möglich.",
    ('ZI', 4, 'a'):
     "– Bei formellen Gruppen sind die Beziehungsstrukturen der einzelnen "
     "Mitarbeiter zueinander durch die Betriebsorganisation festgelegt.\n"
     "– Informelle Gruppen bilden sich durch gleiche Interessen und "
     "Neigungen, wobei die Beziehungsstrukturen nicht durch Vorgesetzte "
     "festgelegt sind.",
    ('ZI', 4, 'b'):
     "Hinweise auf informelle Gruppen, z. B.:\n– ähnliche Ausdrucksweise\n"
     "– Verwenden derselben Begriffe und Formulierungen\n– gleiches "
     "Verhalten\n– klare Rollenverteilung\n– stetige Kontakte untereinander\n"
     "– einheitliches Auftreten\n– erkennbares Normensystem",
    ('ZI', 5, 'a'):
     "Hinweis für den Korrektor: Bei den Beispielen muss Folgendes deutlich "
     "werden, z. B.:\n– Umsetzen der Unternehmensziele unter Berücksichtigung "
     "der persönlichen Ziele der Mitarbeiter\n– klare Zielvereinbarungen mit "
     "den Mitarbeitern treffen\n– Zusammenarbeit fördern, Aufgaben und "
     "Befugnisse übertragen (delegieren)\n– Stellvertreter benennen\n"
     "– Mitarbeitern Qualifizierungsmöglichkeiten erläutern\n– Vorbildfunktion "
     "einnehmen\n– Selbstständigkeit entwickeln lassen und fördern\n"
     "(je Beispiel 3 Punkte, max. 15 Punkte)",
    ('ZI', 7, 'a'):
     "Z. B.:\n– Transparenz gegenüber dem Mitarbeiter erhöhen\n"
     "– Leistungsstand mitteilen\n– Entwicklungsmöglichkeiten aufzeigen\n"
     "– Wertschätzung vermitteln",
    ('ZI', 7, 'b'):
     "Verlauf eines Beurteilungsgespräches, z. B.:\n– das Gespräch freundlich "
     "eröffnen\n– den Grund der Beurteilung erklären\n– gemachte Beobachtungen "
     "mitteilen und dem Mitarbeiter die Beurteilung eröffnen\n– den "
     "Mitarbeiter Stellung nehmen lassen\n– Gesprächsergebnisse notieren und "
     "der Beurteilung beifügen\n– die Kenntnisnahme der Beurteilung vom "
     "Mitarbeiter schriftlich bestätigen lassen\n– Mitarbeiter motivieren und "
     "verabschieden",
    # ---- Naturwissenschaftliche und technische Gesetzmäßigkeiten
    ('NT', 1, 'b'):
     "Eigenschaften, z. B.:\n– CO = Kohlenstoffmonoxid: farblos, geruchlos, "
     "brennbar, sehr giftig\n– CO₂ = Kohlenstoffdioxid: farblos, geruchlos, "
     "schwerer als Luft – Erstickungsgefahr, trägt zur Erderwärmung bei",
    ('NT', 1, 'c'):
     "Technische Anwendungen, z. B.:\n– CO = Kohlenstoffmonoxid: "
     "Reduktionsmittel bei der Roheisengewinnung; Herstellung chemischer "
     "Produkte, z. B. Methanol\n– CO₂ = Kohlenstoffdioxid: Herstellung "
     "kohlensäurehaltiger Getränke; Löschmittel; Schutzgas; Trockeneis",
    ('NT', 2, 'a'):
     "P = m · g · h / (t · η) = 3.000 kg · 9,81 m/s² · 18 m / (20 s · 0,69) "
     "= 38.387 W = 38,4 kW",
    ('NT', 3, 'a'):
     "WR = Wkin1 – Wkin2 = m/2 · (va² – ve²)\n"
     "WR = 1.400 kg / 2 · ((25 m/s)² – (4,17 m/s)²)\n"
     "WR = 425.328 J\n"
     "Q = WR / 2 = 425.328 J / 2 = 212.664 J\n"
     "Q(pro Vorderrad-Bremsscheibe) = 212.664 J · 0,7 / 2 = 74.432 J\n"
     "Q = m · c · ΔT\n"
     "ΔT = Q / (m · c) = 74.432 J / (2,5 kg · 510 J/(kg·K)) = 58,4 K",
    ('NT', 4, 'a'):
     "EkinA = EkinB\n"
     "½ · m · vA² + m · g · hA = ½ · m · vB² + m · g · hB\n"
     "vB = √(2 · (½ · vA² + g · hA – g · hB))\n"
     "vB = √(2 · (½ · (1,5 m/s)² + 9,81 m/s² · 1,6 m – 9,81 m/s² · 0,5 m))\n"
     "vB = 4,88 m/s",
    ('NT', 5, 'a'):
     "Reihenschaltung: R = RA + RA = 500 Ω + 500 Ω = 1.000 Ω\n"
     "I = U / R = 24 V / 1.000 Ω = 0,024 A = 24 mA",
    ('NT', 5, 'b'):
     "Parallelschaltungen von RA mit RA und RB mit RB:\n"
     "RAB = RA / 2 = 500 Ω / 2 = 250 Ω\n"
     "RCD = RB / 2 = 800 Ω / 2 = 400 Ω\n"
     "Reihenschaltung von RAB, RR und RCD:\n"
     "R = RAB + RR + RCD = 250 Ω + 20 Ω + 400 Ω = 670 Ω\n"
     "I = U / R = 24 V / 670 Ω = 0,0358 A = 35,8 mA",
    ('NT', 5, 'c'):
     "I = U / R = 120 V / 670 Ω = 0,179 A = 179 mA",
    ('NT', 5, 'd'):
     "Z. B.:\n– Feuchtigkeit der Hände bzw. Füße\n– Hautoberfläche erhöht "
     "den elektrischen Widerstand durch Hornhaut\n– persönliche "
     "Schutzausrüstung, z. B. spezielle Schuhe\n– Beschaffenheit des "
     "Fußbodens",
    ('NT', 6, 'a'):
     "Merkmale, z. B.:\n– Klasse I: Sinnbild; Schutzleiter (grün/gelb) "
     "vorhanden; Profilstecker mit Schutzkontakt; Anschlussleitung "
     "dreiadrig\n– Klasse II: Schutzisolierung, d. h., das Gehäuse ist "
     "elektrisch nicht leitend; Profilstecker ohne Schutzkontakt oder "
     "Flachstecker; Sinnbild; Anschlussleitung zweiadrig, ohne grün/gelb\n"
     "– Klasse III: Stecker und Steckdosen unterscheiden sich von denen der "
     "Schutzklassen I und II; Betriebsspannung liegt im "
     "Kleinspannungsbereich (< 50 V AC, 120 V DC); Sinnbild; "
     "Schutzkleinspannung wird über einen Sicherheitstransformator erzeugt",
    ('NT', 7, 'a'): "zwischen ca. 3.120 h und 4.080 h (siehe Zeichnung)",
    ('NT', 7, 'b'): "ca. 11 %",
    ('NT', 7, 'c'): "ca. 3 %",
    ('NT', 7, 'd'): "ca. 170 h (siehe Zeichnung)",
}
FRAGE = {
    ('BW', 1, 'a'):
     "Vervollständigen Sie die Tabelle ausgewählter Rechtsformen in Anlage 1 "
     "(Tabelle zu dieser Teilaufgabe).",
    ('BW', 2, 'a'):
     "Berechnen Sie auf Basis dieser Angaben\n– den Kapazitätsbestand in "
     "Stunden,\n– den Kapazitätsbedarf in Stunden,\n– den Zusatzbedarf in "
     "Stunden.",
    ('BW', 3, 'c'):
     "Im vergangenen Jahr betrug der durchschnittliche Lagerbestand 45 t. "
     "Ermitteln Sie die Umschlagshäufigkeit bei einem Materialverbrauch im "
     "vergangenen Jahr in Höhe von 420 t.",
    ('BW', 4, 'b'): "Ermitteln Sie den tatsächlichen Stundenlohn des Facharbeiters.",
    ('BW', 6, 'a'):
     "Als angehender Industriemeister werden Sie vom Controller mit der "
     "Kosten- und Erlössituation in Ihrem Betrieb konfrontiert. Die Daten "
     "sind allerdings unvollständig.\n"
     "Um sich einen Überblick über die Kosten- und Erlössituation zu "
     "verschaffen, müssen Sie die leeren Felder in Anlage 2 (Tabelle zu "
     "dieser Aufgabe) ergänzen.",
    ('BW', 7, 'a'):
     "Aufgrund zunehmenden Wettbewerbs kann das Unternehmen ein Spezialbauteil "
     "nur noch zu einem Listenverkaufspreis von 295,00 € pro Stück am Markt "
     "verkaufen.\n"
     "Durch Rationalisierungsmaßnahmen in der Fertigung ist es gelungen, die "
     "Fertigungslohnkosten auf 35,00 € pro Bauteil zu senken. Die Kosten für "
     "das Fertigungsmaterial betragen 28,00 € pro Bauteil. Für eine "
     "Spezialverpackung müssen 2,00 € pro Bauteil aufgewendet werden. Dem "
     "Kunden werden 2 % Skonto und ein Rabatt von 16 % gewährt.\n"
     "Ermitteln Sie den Gewinn pro Bauteil und den realisierten "
     "Gewinnzuschlag für den Fall, dass mit folgenden "
     "Gemeinkostenzuschlagssätzen kalkuliert wird:\n"
     "– Materialgemeinkostenzuschlagssatz 15 %\n"
     "– Fertigungsgemeinkostenzuschlagssatz 215 %\n"
     "– Verwaltungsgemeinkostenzuschlagssatz 22 %\n"
     "– Vertriebsgemeinkostenzuschlagssatz 13 %",
    ('MI', 1, 'd'):
     "In dem Produktionsplanungs- und Steuerungssystem werden auch "
     "personenbezogene Daten verarbeitet.\nBeschreiben Sie aus Sicht des "
     "Datenschutzes zwei Anforderungen an das Datensicherheitskonzept.",
    ('MI', 2, 'a'):
     "Skizzieren Sie eine einfache Vorlage für ein Ursache-Wirkungs-Diagramm "
     "zur Ermittlung der Ursachen der Qualitätsprobleme. Benennen Sie darin "
     "die fünf Hauptachsen.",
    ('MI', 4, 'a'):
     "Tragen Sie die Leistungsbewertung der beiden Fahrzeuge in das "
     "Netzdiagramm in Anlage 1 ein (fünfachsiges Netz mit der Skala 0 bis "
     "10).",
    ('MI', 5, 'a'):
     "Zeichnen Sie diese Vorgänge in den Balkenplan in Anlage 2 ein "
     "(Raster: Vorgänge A bis I über der Zeit in Tagen, 1 bis 20).",
    ('NT', 1, 'c'):
     "Trotz der Gefährdung für den Menschen sind die beiden Gase wichtige "
     "Reaktionsprodukte. Geben Sie für jedes der beiden Gase zwei technische "
     "Anwendungen an.",
    ('NT', 1, 'a'): "Geben Sie die Namen der beiden Gase CO und CO₂ an.",
    ('NT', 3, 'a'):
     "Ein Fahrzeug (m = 1,4 t) wird von 90 km/h auf 15 km/h abgebremst, dabei "
     "wird 70 % der Bremswirkung von den beiden vorderen Bremsen "
     "aufgebracht.\nDie Hälfte der beim Bremsen entstehenden Reibarbeit "
     "erwärmt die Bremsscheiben. Die Masse einer Bremsscheibe aus legiertem "
     "Stahl beträgt 2,5 kg (c = 510 J/(kg·K)).\nBerechnen Sie die "
     "Temperaturerhöhung einer Vorderradbremsscheibe durch den Bremsvorgang.",
    ('NT', 4, 'a'):
     "Eine Box verlässt mit einer gleichförmigen Geschwindigkeit von 90 m/min "
     "die Packstation. Sie bewegt sich auf einer Gleitbahn ab Position A "
     "zunächst 1,6 m nach unten und anschließend 0,5 m wieder nach oben zur "
     "Position B (siehe Abbildung).\nBerechnen Sie die Geschwindigkeit der "
     "Box an der Position B. Die Reibung wird vernachlässigt.",
    ('NT', 5, 'c'):
     "Berechnen Sie die Gesamtstromstärke in mA, wenn die maximal zulässige "
     "Berührungsspannung von 120 V (Gleichspannung) anliegt. Der Strom fließt "
     "von AB (durch beide Arme) nach CD (durch beide Beine).\nHinweis für die "
     "Bearbeitung: Rechnen Sie mit einem Gesamtwiderstand von 680 Ω, sofern "
     "Sie b) nicht gelöst haben.",
    ('NT', 5, 'd'):
     "Die nach obiger Skizze ermittelten Widerstands-Stromwerte sind rein "
     "theoretische Werte. Geben Sie drei Faktoren an, die den theoretischen "
     "Gesamtwiderstand und damit die Gesamtstromstärke beeinflussen.",
    ('NT', 6, 'a'):
     "Sicherheitsbestimmungen nach VDE für elektrische Betriebsmittel dienen "
     "der Verhütung von Unfällen durch elektrischen Strom. Zum Schutz gegen "
     "elektrischen Schlag werden die Betriebsmittel gegen direktes und "
     "indirektes Berühren in die drei Schutzklassen I, II und III "
     "eingeteilt.\nGeben Sie zu folgenden Schutzklassen I, II, III je drei "
     "Merkmale an, woran die verwendete Schutzklasse erkannt wird:\n"
     "– Schutzklasse I – Kennzeichen: Erdungssymbol im Kreis – mit "
     "Schutzleiter\n– Schutzklasse II – Kennzeichen: Quadrat im Quadrat – mit "
     "Schutzisolierung\n– Schutzklasse III – Kennzeichen: römische III in "
     "einer Raute – mit Schutzkleinspannung",
    ('NT', 7, 'a'): "die Grenzen des Intervalls –3s ≤ x̄ ≤ 3s in Stunden,",
    ('NT', 7, 'c'):
     "den prozentualen Anteil der Lampen, die länger als 3.900 Stunden "
     "durchgehalten haben,",
    ('NT', 7, 'd'): "die Standardabweichung der Stichprobe.",
}
PUNKTE = {
    # NTG Aufgabe 6: Kopf und Klammer nennen 9 Punkte (drei Klassen zu je
    # 3 Punkten), das Heft geht damit nur auf 99 Punkte auf. Die Prüfung ist
    # auf 100 Punkte ausgelegt (Deckblatt) – die Aufgabe trägt hier 10.
    ('NT', 6, 'a'): 10,
}
LABEL = {}
DATUM = {}
INTRO = {
    ('MI', 4):
     "Für Ihren Meisterbereich soll ein elektrisches Transportfahrzeug "
     "beschafft werden. Die folgenden beiden Fahrzeuge wurden bereits auf "
     "einer Skala von 0 bis 10 Punkten bewertet (siehe Tabelle zu dieser "
     "Aufgabe).",
    ('MI', 5):
     "Für die Einrichtung einer neuen Fertigungshalle liegen die Vorgänge mit "
     "Dauer und direkten Vorgängern in der Tabelle zu dieser Aufgabe vor.",
    ('ZI', 6):
     "Meister Merbt muss sich darauf einstellen, dass es eventuell in seiner "
     "Arbeitsgruppe zu sozialen Konflikten kommen kann.",
    ('NT', 1):
     "Bei der Verbrennung fossiler Energieträger entstehen Gase, z. B. CO und "
     "CO₂.",
    ('NT', 5):
     "Das Arbeiten an elektropneumatischen Steuerungen geschieht häufig ohne "
     "Abschaltung der 24 V DC Energieversorgung. Deshalb kann beim Arbeiten "
     "durch den menschlichen Körper elektrischer Strom fließen. Es sind "
     "verschiedene Strompfade möglich (siehe Abbildung):\n– RA = 500 Ω, "
     "Widerstand eines Armes\n– RB = 800 Ω, Widerstand eines Beines\n"
     "– RR = 20 Ω, Widerstand des Rumpfes",
    ('NT', 7):
     "Ein Bildungszentrum erfasst die Lebensdauer der Hochdrucklampen in den "
     "Beamern. Für eine Stichprobe von 100 gleichartigen Lampen wurde in das "
     "Wahrscheinlichkeitsnetz in Anlage 1 (siehe Abbildung) eine "
     "Ausgleichsgerade eingezeichnet.\nMarkieren Sie im "
     "Wahrscheinlichkeitsnetz folgende Parameter und geben Sie die "
     "abgelesenen Werte an:",
    ('BW', 1):
     "Sie beabsichtigen, ein Unternehmen zu gründen. Die deutsche "
     "Rechtsordnung bietet dazu verschiedene Möglichkeiten an.",
    ('BW', 2):
     "Im September müssen 1.500 Bauteile in der Fertigungskostenstelle 2000 "
     "gefertigt werden. Folgende zusätzliche Informationen liegen Ihnen für "
     "die Kapazitätsplanung vor:\n– Vorgabezeit: 160 min/Bauteil\n"
     "– Personalbestand: 24 Facharbeiter\n– Arbeitstage: 20 Tage\n"
     "– Arbeitszeit: 8 Stunden/Tag\n– Ausfallzeiten: 12 % Urlaub, 3 % "
     "krankheitsbedingte Fehlzeiten",
    ('BW', 3):
     "Zu Beginn dieses Jahres betrug der Lagerbestand eines Rohstoffes 22 t. "
     "Der Materialeinkauf betrug 210 t. Bei den Bestandskontrollen zum Ende "
     "der folgenden Monate betrugen die Lagerbestände:\n– Januar: 30 t\n"
     "– Februar: 36 t\n– März: 35 t\n– April: 45 t\n– Mai: 44 t\n– Juni: 40 t",
    ('BW', 4):
     "Für die Herstellung von 1.200 Teilen wird eine Vorgabezeit von 2.070 "
     "Minuten festgelegt. Der Akkordgrundlohn beträgt 16 €/Stunde, der "
     "Akkordzuschlag 10 %. Der Facharbeiter benötigt für den Auftrag 30 "
     "Stunden.",
    ('BW', 5):
     "Im Unternehmen soll eine neue Werkzeugmaschine angeschafft werden. Für "
     "die Maschine liegen folgende Daten vor:\n"
     "– Anschaffungskosten 510.000,00 €\n– Nutzungsdauer 6 Jahre\n"
     "– Restwert nach 6 Jahren 120.000,00 €\n– jährliche Laufzeit 3.000 "
     "Stunden\n– Flächenbedarf 16 m²\n– Durchschnittlicher Energieverbrauch "
     "(Anschlusswert) 15 kW\n"
     "Im Betrieb wird mit folgenden Daten gerechnet:\n"
     "– Kalkulatorischer Zinssatz 6 % pro Jahr\n"
     "– Instandhaltungskostensatz auf Anschaffungskosten pro Jahr 8 %\n"
     "– Kalkulatorische Monatsmiete 14,00 €/m²\n– Stromkosten 0,21 €/kWh\n"
     "Es wird davon ausgegangen, dass nach 6 Jahren Nutzungsdauer der "
     "Wiederbeschaffungswert 10 % über den aktuellen Anschaffungskosten liegt.",
}
# Rohtext-Korrekturen der Scans (siehe korrekturen_basis.py, ROHTEXT).
ROHTEXT = {
    '03-methoden.txt': [
        # Lösung 1 c): Marker verschluckt; Lösung 5 a): der Balkenplan ist
        # eine Zeichnung, die OCR liest nur das leere Raster.
        ('"»  Computersabotage bzw Computerspionage (6 Punkte)\n',
         '"»  Computersabotage bzw Computerspionage (6 Punkte)\nc) Z. B.\n'),
        ('Zeit in Tagen\nVorgang ıl2|3', 'a) Balkenplan siehe Zeichnung\nZeit in Tagen\nVorgang ıl2|3'),
    ],
    '05-ntg.txt': [
        # Lösung 2 (eine Zeile) wanderte in den Fragetext von Aufgabe 3.
        ('aufgebracht\n\n= 38 387 W = 38,4 kW\n', 'aufgebracht\n'),
        # Lösung 5 d): Marker ohne Klammer gelesen.
        ('\nd ZB\n', '\nd) Z. B.\n'),
    ],
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
