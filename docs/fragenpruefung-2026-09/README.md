# Prüfung des Fragenkatalogs – September 2026

> „Prüfe alle Fragen systematisch, ob sich diese irgendwo doppeln oder fachlich richtig sind und für die
> KVM wichtig sind. Lösche überflüssige, korrigiere und füge hinzu, was fehlt. Denk dran, dass diese Fragen
> für die Prüfung helfen sollen und die Frage in Prüfungsschema passen und übertragbar sein müssen.“

Die vollständige Liste aller Änderungen mit Begründung je Frage steht in
[`aenderungen.csv`](aenderungen.csv): ID, Aktion, Prüfstufe, Fach, Bereich, Typ, Kategorie, Grund, Ersatz.

## Ergebnis in Zahlen

| | vorher | nachher |
|---|---:|---:|
| Fragen insgesamt | 3.666 | 3.101 |
| Auswahlfragen (mc) | 2.777 | 1.926 |
| Rechenaufgaben (calc) | 801 | 795 |
| offene Aufgaben mit Musterlösung (open) | 88 | 380 |
| Auswahlfragen ohne Begründung zu falschen Antworten | 2.019 | 0 |

| Fach | vorher | nachher |
|---|---:|---:|
| 1 Recht | 662 | 559 |
| 2 BWL | 838 | 695 |
| 3 Methoden | 538 | 491 |
| 4 Zusammenarbeit | 688 | 598 |
| 5 Kraftverkehr (mit Naturwissenschaft/Technik) | 940 | 758 |

- **unverändert:** 777
- **korrigiert:** 2.034, davon 151 in einen passenderen Bereich verschoben und 100 in einen anderen
  Aufgabentyp umgebaut (meist Auswahlfrage → offene Situationsaufgabe)
- **gelöscht:** 855 (645 echte Dubletten, 180 nicht prüfungsrelevant oder überholt, 21 fachlich unbrauchbar oder nicht eigenständig lösbar, 9 Rechenaufgaben mit denselben Zahlen wie eine andere)
- **neu:** 290
- **als Variation zurückgeholt:** 221 (in „korrigiert“ enthalten)

## Vorgehen

1. **Maßstab.**
   - die 121 Originalprüfungen der App (Recht, BWL, Methoden, Zusammenarbeit, Naturwissenschaft/Technik,
     Organisation und Kommunikation, Fuhrparktechnik/-management)
   - der Rahmenplan
   - der Rechtsstand September 2026
2. **Zwölf Themenpakete.** Jede Frage wurde einzeln geprüft:
   - fachlich richtig und eindeutig lösbar
   - Rechenweg nachgerechnet
   - prüfungsrelevant
   - im Prüfungsschema: Situation, Operator, Punkte
   - übertragbar, also Verständnis statt Wortlaut
   - sprachlich sauber und richtig einsortiert

   Wo Prüfungsthemen fehlten, kamen neue Fragen hinzu. Jede neue Frage nennt die Lücke und eine
   Beispielprüfung.
3. **Dublettenabgleich.** Textähnliche Fragen wurden gruppiert und je Gruppe beurteilt.
4. **Variationen bleiben (Wunsch des Nutzers).** Gelöscht wird nur, was wirklich dieselbe Aufgabe ist:
   dieselbe Frage umformuliert mit derselben Antwort oder dieselbe Rechnung mit denselben Zahlen.
   - Rechenaufgaben mit anderen Zahlen, anderer Situation oder anderer gesuchter Größe bleiben ohne
     Obergrenze. Dasselbe gilt für dieselbe Sache aus einem anderen Blickwinkel: Begriff, Beispiel
     erkennen, Anwendung im Fall, Abgrenzung.
   - Alle Löschungen, die nach der zuvor strengeren Regel entschieden waren, wurden erneut geprüft. Die
     zurückgeholten Variationen sind überarbeitet wie der übrige Katalog. War eine Variante zahlengleich
     mit einer anderen, wurde sie abgewandelt, z. B. als Rückwärtsrechnung.
5. **Querschnittsabgleich nach dem Zusammenführen.** Jede neue, verschobene und zurückgeholte Frage wurde
   gegen ihre ähnlichsten Nachbarn im ganzen Katalog verglichen, auch über Fächer hinweg. Die neuen
   Fragen wurden dabei ein zweites Mal fachlich gegengelesen.
6. **Automatische Prüfungen.**
   - Datenformat: genau eine richtige Option, Pflichtfelder, gültige Bereiche, keine doppelten IDs
   - HTML-Maskierungen (`&gt;`, `&amp;`) durch echte Zeichen ersetzt; Web und App maskieren selbst

## Was sich inhaltlich geändert hat

- **Begründungen:** Jede Auswahlfrage erklärt jetzt zu jeder falschen Option, warum sie falsch ist.
  Vorher fehlte das bei 2.019 von 2.777 Auswahlfragen.
- **Erratbarkeit:** Optionen sind ähnlich lang und gleich gebaut. Eine auffällig lange richtige Antwort,
  absurde Distraktoren und Verneinungsfallen („Welche … NICHT …?“) sind beseitigt.
- **Prüfungsform:**
  - Viele reine Begriffsabfragen sind jetzt offene Situationsaufgaben mit Operator (nennen, beschreiben,
    erläutern, beurteilen), Punkten und einer Musterlösung in Stichpunkten wie ein IHK-Lösungshinweis.
  - Offene Aufgaben: vorher 88, jetzt 380.
- **Rechenaufgaben:**
  - Alle Ergebnisse sind nachgerechnet, der Rechenweg steht in der Erklärung.
  - Muss das Ergebnis gerundet werden, nennt die Aufgabe die Rundung. Die Web-App wertet mit ±0,01, die App
    mit 0,1 %.
  - Beispiele für behobene Rechenfehler:
    - Personalbedarf durch Arbeitszeit statt Mitarbeiterzahl geteilt
    - Akkordrichtsatz mit Grundlohn gleichgesetzt
    - Verdichtungsverhältnis falsch umgesetzt
    - Niederzurrformel mit doppeltem Übertragungsbeiwert
    - Diagonalzurren mit vier addierten Ketten
- **Fachliche Fehler (Auswahl):**
  - Prokura-Umfang steht in § 49 HGB, nicht in § 48.
  - Ein Prokurist darf keine Prokura erteilen und die Bilanz nicht unterschreiben.
  - Die eG ist keine Handelsgesellschaft.
  - Nach dem MoPeG gelten die 4-%-Gewinnverteilung der OHG und die KG-Abstimmung „nach Köpfen“ nicht
    mehr.
  - BF3/BF4 bei Schwertransporten waren vertauscht; Verwaltungshelfer ist der BF4.
  - UN-Nummern 1223/1863 waren vertauscht.
  - Die Feststellbremse (18 %) richtet sich nach UN-R 13, nicht nach § 41 StVZO.
  - Die jährliche Unterweisung folgt aus DGUV Vorschrift 1 § 4.
  - § 99 BetrVG stellt auf das Unternehmen ab, nicht auf den Betrieb: in der Regel mehr als 20 wahlberechtigte
    Arbeitnehmer.
  - Ein Arbeitsschutzausschuss ist ab mehr als 20 Beschäftigten Pflicht (§ 11 ASiG).
- **Einsortierung:** 151 Fragen stehen jetzt im passenden Bereich, zum Beispiel:
  - Beurteilungsfehler → Mitarbeiterbeurteilung
  - Akkord- und Auftragszeitrechnung → Entgelt und Arbeitszeit
  - HGB-Grundlagen (Kaufmann, Handelsregister, Prokura) → Vertrags- und Handelsrecht
  - Statistik aus Naturwissenschaft/Technik → Methoden/Statistik
  - Q7-Werkzeuge → Qualitätsmanagement
  - Tarif- und Arbeitskampfrecht → Arbeitsrecht

## Rechtsstand 2026 (eingearbeitet)

- **GüKG:** Seit 27.02.2026 gibt es keine nationale Erlaubnis mehr, nur noch die Gemeinschaftslizenz
  (§ 3 GüKG). Bestehende Erlaubnisse gelten bis zu ihrem Ablauf, längstens bis 27.02.2036
  ([BALM](https://www.balm.bund.de/SharedDocs/Standardartikel_Buehne/2026/02_Februar/Aenderung_Gueterkraftverkehrsgesetze.html),
  [BGBl. 2026 I Nr. 47](https://www.recht.bund.de/bgbl/1/2026/47/regelungstext.pdf)).
- **Lenk- und Ruhezeiten, Fahrtenschreiber:** Seit 01.07.2026 gelten sie auch für Fahrzeuge über 2,5 t im
  grenzüberschreitenden Verkehr und in der Kabotage
  ([IHK Magdeburg](https://www.ihk.de/magdeburg/produktmarken/branchen/verkehrswirtschaft/branchennews/tachographenpflicht-1-juli-2026-7039746)).
- **Maut:** Emissionsfreie Lkw sind bis 30.06.2031 von der Maut befreit
  ([BMV](https://www.bmv.de/SharedDocs/DE/Pressemitteilungen/2025/068-schnieder-mautbefreiung-emissionsfreie-lkw-bis-mitte-2031-verlaengert.html)).
  Die Handwerkerausnahme gilt unter 7,5 t.
- **Berufskraftfahrer:** Seit 03.02.2026 dürfen bis zu 12 der 35 Weiterbildungsstunden per E-Learning
  absolviert werden
  ([Berufskraftfahrer-Zeitung](https://www.berufskraftfahrer-zeitung.de/e-learning-in-der-berufskraftfahrer-weiterbildung-aenderungen-im-berufskraftfahrerqualifikationsrecht-beschlossen/)).
  Nachweis ist seit 23.05.2021 der Fahrerqualifizierungsnachweis (FQN); die Schlüsselzahl 95 wird in Deutschland
  nicht mehr neu eingetragen.
- **Verpackungen:** Seit 12.08.2026 gelten die EU-Verpackungsverordnung (PPWR) und das VerpackDG statt des
  VerpackG ([Umweltbundesamt](https://www.umweltbundesamt.de/themen/neue-regeln-fuer-verpackungen-bringen-plus-fuer)).
- **Batterien:** Es gelten die EU-Batterieverordnung und das BattDG statt des BattG.
- **Ausbildung:** Für den Ausbildungsvertrag genügt seit 01.08.2024 die Textform (§ 11 BBiG,
  [gesetze-im-internet.de](https://www.gesetze-im-internet.de/bbig_2005/__11.html)).
- **Werte 2026:**
  - Mindestlohn 13,90 € (ab 2027: 14,60 €)
  - Beitragssätze mit durchschnittlichem Zusatzbeitrag 2,9 %
  - Wahlrecht zum Betriebsrat ab 16 Jahren
- **Noch offen, deshalb neutral formuliert:**
  - ArbZG-Reform zur elektronischen Zeiterfassung (Entwurf)
  - Umsetzung der EU-Produkthaftungsrichtlinie 2024/2853 (bis 09.12.2026)
  - Schwelle für den Datenschutzbeauftragten nach § 38 BDSG

## Gelöscht – wofür es keinen Ersatz braucht

- **Echte Dubletten:** Viele Fragen gab es zwei- bis fünfmal, etwa in den Serien `…-1xx` und `PX-…`, die die
  Serie `…-0xx` wiederholten. Behalten wurde jeweils die beste Fassung; ihr Zusatzwissen steht in deren
  Erklärung.
- **Nicht prüfungsrelevant:** Themen, die weder im Rahmenplan stehen noch in den Originalprüfungen vorkommen.
  Beispiele:
  - makroökonomische VWL (Konjunktur, BIP, Inflation, Marktformen)
  - Handelskalkulation, Plankostenrechnung
  - Marketing-Randwissen
  - Earned-Value-Analyse, Scrum
  - Konzernbetriebsrat
  - Euro-VI-Grenzwerte, Detailzahlen ohne Prüfungsbezug
- **Fachlich unbrauchbar:** Fragen ohne eigenständige Lösbarkeit, triviale Rechnungen ohne Fachinhalt sowie
  Fragen zu entfallenem Recht, etwa zur Befristung der nationalen GüKG-Erlaubnis.

## Neu – geschlossene Lücken (Auswahl)

- **Recht:**
  - § 21a ArbZG für Fahrpersonal, Arbeitszeiterfassung
  - krankheitsbedingte Kündigung, Sozialauswahl, Abmahnung
  - §§ 99–101 BetrVG, Unfalluntersuchung, Gefährdungsbeurteilung
  - Quasi- und Teilhersteller
- **BWL:**
  - Kfz-Kostenblatt (Kosten je km, Fixkosten je Einsatztag, Zinsen, Tourenpreis, Kostengleichheit
    Diesel/E-Lkw)
  - BAB mit Über-/Unterdeckung, Zusatzauftrag mit teilvariablen Gemeinkosten
  - Globalisierung, Unternehmenszusammenschlüsse
  - Organisationsaufgaben, QM-Dokumentation und Audits
- **Methoden:**
  - Netzplan mit Gesamt- und freiem Puffer
  - Projektsteuerung und -risiken
  - Präsentation per Videokonferenz, Schichtübergabe, Kennzahlen im Vergleich
- **Zusammenarbeit:**
  - teilautonome Gruppen, Kritikgespräch, Qualifizierungsbedarf
  - Prämien- und Anreizsysteme für Fahrer
  - Mindestlohn im Transportgewerbe, Auftraggeberhaftung nach § 13 MiLoG
- **Kraftverkehr:**
  - Gefahrgutbeauftragter, beschädigte Lithium-Batterien
  - Kühlfahrzeuge und ATP-Prüffristen
  - Genehmigungen im Schwertransport, T1/NCTS
  - Werkstattabfälle, Prämiensysteme
  - Chemie und Elektrotechnik (Wasserenthärtung, Korrosionsschutz, Innenwiderstand)
  - Überholvorgang, alternative Antriebe

## Hinweise

- **IDs bleiben stabil.** Lernstände zu bestehenden Fragen bleiben erhalten. Gelöschte Fragen fallen aus
  Auswahl und Statistik. Bei 100 Fragen hat sich der Typ geändert; ihr Lernstand gilt weiter.
- **Nicht abbildbar:** Zeichenaufgaben der Prüfungen (Diagramm, Balkenplan, Wahrscheinlichkeitsnetz) lassen
  sich als App-Frage nicht abbilden. Sie bleiben in den Originalprüfungen der App.
- **Pflege:**
  - Neue Fragen haben IDs `<Bereich>-6NN`.
  - Quelle der Wahrheit ist `data/questions.js`; die App übernimmt sie mit `tools/sync_content.py`.
