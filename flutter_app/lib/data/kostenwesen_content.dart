import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/kostenwesen.dart';

/// Lerninhalte „Betriebliches Kostenwesen" – vom Nullpunkt bis Prüfungsniveau.
const List<KwChapter> kwChapters = [
  // ─────────────────────────────────────────────────────────────── 1
  KwChapter(
    id: 'grundlagen',
    title: 'Grundlagen der Kostenrechnung',
    subtitle: 'Wozu das Ganze · Aufwand vs. Kosten · Kostenbegriffe',
    icon: Icons.foundation,
    color: kPetrol,
    sections: [
      KwSection(
        title: 'Warum es die Kostenrechnung überhaupt gibt',
        body: 'Ein Betrieb führt zwei Rechnungen nebeneinander. Die '
            'Finanzbuchhaltung (FiBu) schaut nach außen: Sie ist gesetzlich '
            'vorgeschrieben und zeigt dem Finanzamt, der Bank und den '
            'Eigentümern, wie erfolgreich das ganze Unternehmen im Geschäftsjahr '
            'war.\n\nDie Kosten- und Leistungsrechnung (KLR) schaut nach innen. '
            'Sie beantwortet genau die Fragen, die dich als Meister täglich '
            'betreffen: Was kostet uns dieses Teil wirklich? Welchen Preis '
            'müssen wir mindestens verlangen, damit wir nicht draufzahlen? '
            'Lohnt sich der Zusatzauftrag? Selbst fertigen oder zukaufen? '
            'Niemand schreibt vor, wie du intern rechnest – du darfst so '
            'rechnen, wie es die Entscheidung verlangt.',
        bullets: [
          'FiBu: extern, gesetzlich (HGB/Steuerrecht), Zeitraum Geschäftsjahr, rechnet mit Aufwand und Ertrag.',
          'KLR: intern, freiwillig, kurze Perioden (meist Monat), rechnet mit Kosten und Leistungen.',
          'Die KLR ist die Grundlage jeder Kalkulation und jeder Preisentscheidung.',
        ],
        merke: 'Die KLR läuft in drei Stufen und beantwortet drei Fragen: '
            'Kostenartenrechnung – WELCHE Kosten sind angefallen? '
            'Kostenstellenrechnung – WO sind sie angefallen? '
            'Kostenträgerrechnung – WOFÜR sind sie angefallen?',
      ),
      KwSection(
        title: 'Aufwand und Kosten sauber trennen',
        body: 'Das ist das Fundament – und die häufigste Fehlerquelle. '
            'Aufwand ist jeder Werteverzehr, den die Buchhaltung erfasst. '
            'Kosten sind nur der betriebsbedingte, periodengerechte, bewertete '
            'Verzehr von Gütern und Leistungen für die eigentliche '
            'Betriebsleistung.\n\nEine Spende an den örtlichen Sportverein ist '
            'Aufwand – aber sie hat nichts mit der Fertigung zu tun, also sind '
            'es keine Kosten. Umgekehrt gibt es Kosten, die in der Buchhaltung '
            'gar nicht auftauchen: Der Inhaber eines Einzelunternehmens zahlt '
            'sich kein Gehalt, seine Arbeit ist aber trotzdem etwas wert.',
        bullets: [
          'Neutraler Aufwand = kein Kostencharakter. Drei Fälle: betriebsfremd (Spende, Kursverlust), außerordentlich (Brandschaden, Diebstahl), periodenfremd (Steuernachzahlung fürs Vorjahr).',
          'Zweckaufwand = betriebsbedingt und in gleicher Höhe → wird 1:1 als Grundkosten übernommen (Löhne, Materialverbrauch).',
          'Anderskosten = gleiche Sache, anderer Betrag (kalkulatorische statt bilanzieller Abschreibung).',
          'Zusatzkosten = in der FiBu überhaupt nicht vorhanden (kalk. Unternehmerlohn, kalk. Eigenkapitalzinsen, kalk. Miete für eigene Räume).',
          'Anderskosten + Zusatzkosten = kalkulatorische Kosten.',
        ],
        formulas: [
          KwFormula('Kostenbegriff', 'Kosten = Grundkosten + kalkulatorische Kosten'),
          KwFormula('Gegenstück', 'Leistung = Grundleistung + kalkulatorische Leistung',
              note: 'Der Ertrag ist das Pendant zum Aufwand, die Leistung das Pendant zu den Kosten.'),
        ],
        falle: 'Ordne in der Prüfung jeden Geschäftsvorfall zuerst in eine der '
            'vier Schubladen ein (neutral / Zweckaufwand / Anders / Zusatz), '
            'bevor du rechnest. „Verkauf eines Firmenwagens über Buchwert" ist '
            'neutraler Ertrag, keine Leistung.',
      ),
      KwSection(
        title: 'Die Ergebnistabelle (Abgrenzungsrechnung)',
        body: 'In der Ergebnistabelle wird die Brücke zwischen FiBu und KLR '
            'geschlagen. Links stehen alle Aufwendungen und Erträge aus der '
            'Buchhaltung. Diese werden aufgeteilt: Was nicht betriebsbedingt '
            'ist, wandert in die neutrale Spalte. Was betriebsbedingt ist, '
            'wandert – gegebenenfalls mit korrigiertem Betrag – in die '
            'KLR-Spalte.',
        scheme: [
          'Gesamtergebnis (FiBu)',
          '   = neutrales Ergebnis',
          '   + Betriebsergebnis (KLR)',
          '',
          'neutrales Ergebnis  = neutraler Ertrag − neutraler Aufwand',
          'Betriebsergebnis    = Leistungen − Kosten',
        ],
        formulas: [
          KwFormula('Gesamtergebnis', 'Betriebsergebnis + neutrales Ergebnis'),
        ],
        example: KwExample(
          task: 'Gesamtergebnis der FiBu: 80.000 €. Darin enthalten: '
              'Spende 5.000 €, Brandschaden 20.000 €, Mieterträge aus einem '
              'nicht betriebsnotwendigen Haus 15.000 €. Zusätzlich verrechnet '
              'die KLR kalkulatorischen Unternehmerlohn von 60.000 €.',
          steps: [
            'Neutraler Aufwand = 5.000 + 20.000 = 25.000 €',
            'Neutraler Ertrag = 15.000 €',
            'Neutrales Ergebnis = 15.000 − 25.000 = −10.000 €',
            'Betriebsergebnis = Gesamtergebnis − neutrales Ergebnis = 80.000 − (−10.000) = 90.000 €',
            'Nach Abzug des kalk. Unternehmerlohns: 90.000 − 60.000 = 30.000 €',
          ],
          result: 'Kalkulatorisches Betriebsergebnis = 30.000 €',
        ),
      ),
      KwSection(
        title: 'Die Kostenbegriffe, die du sicher können musst',
        body: 'Kosten werden nach zwei völlig verschiedenen Gesichtspunkten '
            'sortiert. Erstens: Kann ich sie einem einzelnen Produkt direkt '
            'zurechnen? Zweitens: Verändern sie sich, wenn ich mehr oder '
            'weniger produziere? Diese beiden Einteilungen darfst du nie '
            'durcheinanderbringen.',
        bullets: [
          'Einzelkosten: direkt zurechenbar – Fertigungsmaterial, Fertigungslöhne, Sondereinzelkosten (z. B. Spezialwerkzeug für genau diesen Auftrag).',
          'Gemeinkosten: nicht direkt zurechenbar – Meistergehalt, Hallenmiete, Energie. Sie kommen über Schlüssel bzw. Zuschlagssätze ins Produkt.',
          'Fixe Kosten: bleiben bei Beschäftigungsänderung gleich (Miete, lineare Abschreibung, Gehälter).',
          'Variable Kosten: verändern sich mit der Ausbringung (Fertigungsmaterial, Akkordlohn, Fertigungsenergie).',
          'Sprungfixe Kosten: bleiben in Stufen konstant – eine zweite Schicht braucht einen zweiten Meister.',
        ],
        formulas: [
          KwFormula('Gesamtkosten', 'K = Kf + kv · x',
              note: 'Kf = Fixkosten, kv = variable Stückkosten, x = Menge'),
          KwFormula('Stückkosten', 'k = K ÷ x'),
          KwFormula('Fixe Stückkosten', 'kf = Kf ÷ x'),
        ],
        merke: 'Fixkosten sind pro Stück variabel, variable Kosten sind pro '
            'Stück fix. Genau dieser Satz wird geprüft – und dahinter steckt '
            'die Fixkostendegression: Je mehr Stück, desto weniger Fixkosten '
            'trägt jedes einzelne Stück.',
        falle: 'Fixkosten sind niemals „unveränderlich" – sie sind nur '
            'unabhängig von der Beschäftigung. Die Miete kann trotzdem steigen.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────── 2
  KwChapter(
    id: 'kostenarten',
    title: 'Kostenartenrechnung',
    subtitle: 'Welche Kosten? · Material · Personal · kalkulatorische Kosten',
    icon: Icons.category_outlined,
    color: kAmber,
    sections: [
      KwSection(
        title: 'Aufgabe der Kostenartenrechnung',
        body: 'Die erste Stufe erfasst vollständig und überschneidungsfrei, '
            'welche Kosten in der Periode angefallen sind. Jede Kostenart wird '
            'genau einmal erfasst und sofort in Einzel- und Gemeinkosten '
            'getrennt – denn Einzelkosten gehen später direkt ins Produkt, '
            'Gemeinkosten müssen den Umweg über die Kostenstellenrechnung nehmen.',
        bullets: [
          'Materialkosten, Personalkosten, Dienstleistungskosten, Abgaben, kalkulatorische Kosten.',
          'Grundsatz: eindeutig, vollständig, überschneidungsfrei.',
        ],
      ),
      KwSection(
        title: 'Materialverbrauch ermitteln',
        body: 'Bevor Material bewertet werden kann, muss die verbrauchte Menge '
            'bekannt sein. Dafür gibt es drei Verfahren – sie unterscheiden '
            'sich darin, wie genau sie sind und wie viel Aufwand sie machen.',
        bullets: [
          'Inventurmethode (Befundrechnung): Anfangsbestand + Zugänge − Endbestand. Einfach, erfasst aber Schwund/Diebstahl nicht getrennt.',
          'Skontrationsmethode (Fortschreibung): Summe der Materialentnahmescheine. Genau, zeigt durch Vergleich mit der Inventur die Fehlmenge.',
          'Retrograde Methode (Rückrechnung): Sollverbrauch = Stückliste × produzierte Menge. Nur ein Sollwert, keine Ist-Erfassung.',
        ],
        formulas: [
          KwFormula('Inventurmethode', 'Verbrauch = AB + Zugänge − EB'),
          KwFormula('Fehlmenge', 'Fehlmenge = Verbrauch (Inventur) − Verbrauch (Skontration)'),
        ],
        example: KwExample(
          task: 'AB 400 Stück, Zugänge 2.600 Stück, Endbestand laut Inventur '
              '350 Stück. Die Entnahmescheine weisen 2.600 Stück aus.',
          steps: [
            'Inventurmethode: 400 + 2.600 − 350 = 2.650 Stück',
            'Skontration: 2.600 Stück',
            'Differenz: 2.650 − 2.600 = 50 Stück',
          ],
          result: 'Fehlmenge (Schwund/Bruch/Diebstahl) = 50 Stück',
        ),
      ),
      KwSection(
        title: 'Kalkulatorische Abschreibung',
        body: 'Die bilanzielle Abschreibung folgt dem Steuerrecht: '
            'Anschaffungswert, vorgeschriebene Nutzungsdauer. Für die interne '
            'Rechnung ist das unbrauchbar – denn wenn die Maschine in acht '
            'Jahren ersetzt werden muss, brauchst du bis dahin den dann '
            'gültigen Preis. Deshalb rechnet die KLR mit dem '
            'Wiederbeschaffungswert und der tatsächlichen Nutzungsdauer.',
        bullets: [
          'Basis: Wiederbeschaffungswert (nicht Anschaffungswert).',
          'Zeitraum: tatsächliche betriebliche Nutzungsdauer (nicht AfA-Tabelle).',
          'Ziel: Substanzerhaltung – am Ende muss die Ersatzmaschine bezahlbar sein.',
        ],
        formulas: [
          KwFormula('Linear', '(Wiederbeschaffungswert − Restwert) ÷ Nutzungsdauer',
              note: 'Gleichbleibender Betrag pro Jahr – der Standardfall.'),
          KwFormula('Degressiv (geometrisch)', 'Restbuchwert × Abschreibungssatz %',
              note: 'Fallende Beträge; der Restwert wird nie ganz null.'),
          KwFormula('Leistungsbezogen',
              '(WBW − Restwert) ÷ Gesamtleistung × Periodenleistung',
              note: 'Z. B. nach Maschinenstunden oder gefahrenen Kilometern.'),
        ],
        example: KwExample(
          task: 'Wiederbeschaffungswert 120.000 €, Restwert 20.000 €, '
              'Nutzungsdauer 10 Jahre. Wie hoch ist die kalkulatorische '
              'Abschreibung pro Jahr?',
          steps: [
            '(120.000 € − 20.000 €) = 100.000 € Abschreibungsvolumen',
            '100.000 € ÷ 10 Jahre',
          ],
          result: '10.000 € pro Jahr',
        ),
        falle: 'Die kalkulatorische Abschreibung darf über die gesamte '
            'Nutzungsdauer mehr betragen als der Anschaffungswert – das ist '
            'kein Fehler, sondern gewollt (Anderskosten).',
      ),
      KwSection(
        title: 'Kalkulatorische Zinsen',
        body: 'Im Betrieb steckt Kapital – in Maschinen, Vorräten, '
            'Forderungen. Dieses Geld könnte stattdessen am Kapitalmarkt Zinsen '
            'bringen. Diesen entgangenen Gewinn verrechnet die KLR als Kosten, '
            'und zwar auf das gesamte betriebsnotwendige Kapital: egal ob es '
            'von der Bank oder vom Eigentümer stammt.',
        scheme: [
          '   Betriebsnotwendiges Vermögen',
          ' − Abzugskapital (zinsfrei überlassen:',
          '   Lieferantenkredite, Anzahlungen, Rückstellungen)',
          ' = Betriebsnotwendiges Kapital',
          ' × Kalkulatorischer Zinssatz',
          ' = Kalkulatorische Zinsen',
        ],
        formulas: [
          KwFormula('Betriebsnotwendiges Kapital',
              'betriebsnotwendiges Vermögen − Abzugskapital'),
          KwFormula('Kalkulatorische Zinsen',
              'betriebsnotwendiges Kapital × Zinssatz ÷ 100'),
          KwFormula('Abnutzbares Anlagevermögen',
              'durchschnittlich gebundenes Kapital = (AW + Restwert) ÷ 2',
              note: 'Weil das Kapital durch die Abschreibung stetig freigesetzt wird.'),
        ],
        falle: 'Nicht betriebsnotwendige Teile (leerstehendes Grundstück, '
            'Wertpapierdepot) gehören nicht ins betriebsnotwendige Vermögen – '
            'sie fliegen vorher raus.',
      ),
      KwSection(
        title: 'Wagnisse, Unternehmerlohn und Miete',
        body: 'Drei weitere kalkulatorische Kostenarten runden das Bild ab. '
            'Gemeinsam ist ihnen: Sie machen die Rechnung realistischer, als '
            'die Buchhaltung es könnte.',
        bullets: [
          'Kalkulatorische Wagnisse: Einzelwagnisse wie Ausschuss, Gewährleistung, Forderungsausfall werden über einen Durchschnittssatz mehrerer Jahre verrechnet.',
          'Das allgemeine Unternehmerwagnis wird NICHT verrechnet – es ist durch den Gewinn abgedeckt.',
          'Kalkulatorischer Unternehmerlohn: nur bei Einzelunternehmen und Personengesellschaften (der GmbH-Geschäftsführer bekommt echtes Gehalt = Grundkosten).',
          'Kalkulatorische Miete: für privat zur Verfügung gestellte Räume, in Höhe der ortsüblichen Miete.',
        ],
        formulas: [
          KwFormula('Wagniszuschlag',
              'Wagnisverluste mehrerer Jahre ÷ Bezugsgröße × 100',
              note: 'Bezugsgröße z. B. Umsatz oder Materialeinsatz derselben Jahre.'),
        ],
        example: KwExample(
          task: 'Forderungsausfälle der letzten 4 Jahre: 32.000 €. '
              'Umsatz derselben Jahre: 4.000.000 €. Erwarteter Umsatz im '
              'Planjahr: 1.200.000 €.',
          steps: [
            'Wagnissatz = 32.000 ÷ 4.000.000 × 100 = 0,8 %',
            'Kalk. Wagnis = 1.200.000 € × 0,8 %',
          ],
          result: '9.600 € kalkulatorisches Vertriebswagnis',
        ),
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────── 3
  KwChapter(
    id: 'kostenstellen',
    title: 'Kostenstellenrechnung (BAB)',
    subtitle: 'Wo entstehen die Kosten? · Zuschlagssätze bilden',
    icon: Icons.grid_on,
    color: kOk,
    sections: [
      KwSection(
        title: 'Wozu Kostenstellen?',
        body: 'Einzelkosten wandern direkt ins Produkt. Bei den Gemeinkosten '
            'geht das nicht: Die Hallenmiete lässt sich keinem einzelnen Bauteil '
            'zuordnen. Also wird ein Umweg gebaut – die Gemeinkosten werden '
            'zuerst auf die Orte verteilt, an denen sie entstanden sind '
            '(Kostenstellen), und von dort mit einem prozentualen Zuschlagssatz '
            'ins Produkt gebracht. Das Werkzeug dafür ist der '
            'Betriebsabrechnungsbogen (BAB).',
        bullets: [
          'Hauptkostenstellen: Material, Fertigung, Verwaltung, Vertrieb – sie rechnen direkt aufs Produkt ab.',
          'Hilfskostenstellen: Reparatur, Energie, Fuhrpark – sie leisten für andere Stellen und werden umgelegt.',
          'Zweitens dient der BAB der Wirtschaftlichkeitskontrolle: Man sieht, welche Stelle aus dem Ruder läuft.',
        ],
        merke: 'Der BAB hat drei Arbeitsschritte: 1. Gemeinkosten mit '
            'Verteilungsschlüsseln auf die Stellen verteilen, 2. Spalten '
            'summieren, 3. Zuschlagssätze berechnen.',
      ),
      KwSection(
        title: 'Verteilungsschlüssel richtig wählen',
        body: 'Ein Verteilungsschlüssel muss die Kostenverursachung abbilden. '
            'Die Frage lautet immer: Wovon hängen diese Kosten ab?',
        bullets: [
          'Raumkosten (Miete, Heizung) → Quadratmeter',
          'Energiekosten → installierte kW oder gemessene kWh',
          'Personalnebenkosten → Lohn- und Gehaltssumme oder Mitarbeiterzahl',
          'Kalkulatorische Abschreibungen → Anlagenwerte je Stelle',
          'Materialgemeinkosten → Zahl der Materialentnahmescheine',
        ],
        falle: 'Ein bequemer Schlüssel ist nicht automatisch ein richtiger. '
            'Wenn die Prüfung „verursachungsgerecht" verlangt, ist der Schlüssel '
            'gesucht, der die Kostenentstehung erklärt – nicht der einfachste.',
      ),
      KwSection(
        title: 'Zuschlagssätze berechnen',
        body: 'Am Ende jeder Spalte steht die Summe der Gemeinkosten dieser '
            'Stelle. Diese Summe wird zu einer Bezugsgröße ins Verhältnis '
            'gesetzt – und zwar zu derjenigen Größe, die den besten '
            'Zusammenhang zeigt. Material bezieht sich aufs '
            'Fertigungsmaterial, Fertigung auf die Fertigungslöhne, Verwaltung '
            'und Vertrieb auf die Herstellkosten.',
        formulas: [
          KwFormula('Materialgemeinkosten',
              'MGK-Satz % = MGK ÷ Fertigungsmaterial × 100'),
          KwFormula('Fertigungsgemeinkosten',
              'FGK-Satz % = FGK ÷ Fertigungslöhne × 100'),
          KwFormula('Herstellkosten der Erzeugung',
              'HK = FM + MGK + FL + FGK + SEK Fertigung'),
          KwFormula('Verwaltungsgemeinkosten', 'VwGK-Satz % = VwGK ÷ HK × 100'),
          KwFormula('Vertriebsgemeinkosten', 'VtGK-Satz % = VtGK ÷ HK × 100'),
        ],
        example: KwExample(
          task: 'MGK 24.000 €, Fertigungsmaterial 160.000 €, FGK 189.000 €, '
              'Fertigungslöhne 90.000 €, VwGK 27.720 €, VtGK 18.480 €.',
          steps: [
            'MGK-Satz = 24.000 ÷ 160.000 × 100 = 15 %',
            'FGK-Satz = 189.000 ÷ 90.000 × 100 = 210 %',
            'HK = 160.000 + 24.000 + 90.000 + 189.000 = 463.000 €',
            'VwGK-Satz = 27.720 ÷ 463.000 × 100 ≈ 5,99 %',
            'VtGK-Satz = 18.480 ÷ 463.000 × 100 ≈ 3,99 %',
          ],
          result: 'MGK 15 % · FGK 210 % · VwGK ≈ 6 % · VtGK ≈ 4 %',
        ),
        falle: 'Fertigungsgemeinkostensätze von 200 % und mehr sind völlig '
            'normal – die Maschinen kosten heute mehr als die Menschen, die sie '
            'bedienen. Rechne nicht nach, weil dir die Zahl zu hoch vorkommt.',
      ),
      KwSection(
        title: 'Innerbetriebliche Leistungsverrechnung',
        body: 'Hilfskostenstellen arbeiten für andere Stellen – die '
            'Reparaturabteilung repariert Maschinen in der Fertigung. Diese '
            'Leistungen müssen weiterverrechnet werden, bevor die '
            'Zuschlagssätze gebildet werden können.',
        bullets: [
          'Anbauverfahren (Blockverfahren): einfachster Fall, gegenseitige Leistungen werden ignoriert.',
          'Stufenleiterverfahren (Treppenverfahren): Stellen werden in eine Reihenfolge gebracht, jede gibt nur nach unten ab.',
          'Gleichungsverfahren (mathematisches Verfahren): berücksichtigt den gegenseitigen Austausch vollständig – am genauesten.',
        ],
      ),
      KwSection(
        title: 'Normalkosten, Über- und Unterdeckung',
        body: 'Rechnet man mit Zuschlagssätzen aus dem Durchschnitt der '
            'Vergangenheit (Normalkosten), weichen die verrechneten '
            'Gemeinkosten von den tatsächlichen ab. Diese Differenz macht die '
            'Wirtschaftlichkeit sichtbar.',
        formulas: [
          KwFormula('Deckungsdifferenz',
              'verrechnete Gemeinkosten − Ist-Gemeinkosten'),
        ],
        merke: 'Verrechnet > Ist → Überdeckung (positiv, wir haben zu viel '
            'kalkuliert). Verrechnet < Ist → Unterdeckung (negativ, die Kosten '
            'sind uns davongelaufen).',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────── 4
  KwChapter(
    id: 'kostentraeger',
    title: 'Kalkulationsverfahren',
    subtitle: 'Zuschlagskalkulation · Division · Äquivalenzziffern · Angebot',
    icon: Icons.calculate_outlined,
    color: Color(0xFF3F6FB5),
    sections: [
      KwSection(
        title: 'Welches Verfahren wann?',
        body: 'Die Kostenträgerrechnung beantwortet die Frage: Was kostet das '
            'einzelne Stück? Welches Verfahren passt, hängt allein vom '
            'Fertigungstyp ab.',
        bullets: [
          'Ein einziges Produkt in Masse (Zement, Strom) → Divisionskalkulation.',
          'Artverwandte Sorten aus einem Prozess (Biersorten, Papierstärken) → Äquivalenzziffernkalkulation.',
          'Unterschiedliche Erzeugnisse, Einzel- und Serienfertigung → Zuschlagskalkulation.',
          'Hoher Maschinenanteil, wenig Handarbeit → Maschinenstundensatzrechnung.',
        ],
      ),
      KwSection(
        title: 'Divisionskalkulation',
        body: 'Das einfachste Verfahren: Gesamtkosten durch Menge. Es setzt '
            'voraus, dass nur ein einziges Produkt hergestellt wird und keine '
            'Bestandsveränderungen auftreten. Weichen Produktions- und '
            'Absatzmenge voneinander ab, wird zweistufig gerechnet – denn '
            'Verwaltung und Vertrieb fallen nur für die verkauften Stücke an.',
        formulas: [
          KwFormula('Einstufig', 'k = Gesamtkosten ÷ Menge'),
          KwFormula('Zweistufig',
              'k = HK ÷ Produktionsmenge + VwVt-Kosten ÷ Absatzmenge'),
        ],
        example: KwExample(
          task: 'Herstellkosten 400.000 € bei 20.000 produzierten Stück, '
              'Verwaltungs- und Vertriebskosten 54.000 € bei 18.000 verkauften '
              'Stück.',
          steps: [
            'Herstellkosten je Stück = 400.000 ÷ 20.000 = 20,00 €',
            'VwVt je verkauftem Stück = 54.000 ÷ 18.000 = 3,00 €',
          ],
          result: 'Selbstkosten je verkauftem Stück = 23,00 €',
        ),
      ),
      KwSection(
        title: 'Äquivalenzziffernkalkulation',
        body: 'Bei Sortenfertigung entstehen ähnliche Produkte im gleichen '
            'Prozess, die aber unterschiedlich viel Kosten verursachen. Die '
            'Äquivalenzziffer drückt dieses Verhältnis aus: Die Standardsorte '
            'bekommt die Ziffer 1,0 – eine Sorte, die 20 % mehr Aufwand '
            'verursacht, bekommt 1,2. Über die Rechnungseinheiten werden die '
            'Sorten vergleichbar gemacht.',
        scheme: [
          '1. Rechnungseinheiten je Sorte = Menge × Äquivalenzziffer',
          '2. Summe aller Rechnungseinheiten bilden',
          '3. Kosten je Rechnungseinheit = Gesamtkosten ÷ Σ RE',
          '4. Stückkosten je Sorte = Kosten je RE × Äquivalenzziffer',
        ],
        example: KwExample(
          task: 'Gesamtkosten 231.000 €. Sorte A: 10.000 Stück, ÄZ 1,0; '
              'Sorte B: 8.000 Stück, ÄZ 1,3; Sorte C: 5.000 Stück, ÄZ 0,8.',
          steps: [
            'RE A = 10.000 × 1,0 = 10.000',
            'RE B = 8.000 × 1,3 = 10.400',
            'RE C = 5.000 × 0,8 = 4.000',
            'Σ RE = 24.400',
            'Kosten je RE = 231.000 ÷ 24.400 ≈ 9,4672 €',
          ],
          result: 'A ≈ 9,47 € · B ≈ 12,31 € · C ≈ 7,57 € je Stück',
        ),
      ),
      KwSection(
        title: 'Differenzierende Zuschlagskalkulation',
        body: 'Das wichtigste Verfahren der Prüfung. Die Einzelkosten werden '
            'direkt angesetzt, die Gemeinkosten kommen über die Zuschlagssätze '
            'aus dem BAB dazu. Das Schema läuft immer gleich – lerne es '
            'auswendig, dann ist jede Aufgabe nur noch Einsetzen.',
        scheme: [
          '   Fertigungsmaterial            (FM)',
          ' + Materialgemeinkosten   % auf FM',
          ' = Materialkosten               (MK)',
          '',
          '   Fertigungslöhne              (FL)',
          ' + Fertigungsgemeinkosten % auf FL',
          ' + Sondereinzelkosten der Fertigung',
          ' = Fertigungskosten             (FK)',
          '',
          ' = Herstellkosten          MK + FK',
          ' + Verwaltungsgemeinkosten % auf HK',
          ' + Vertriebsgemeinkosten   % auf HK',
          ' + Sondereinzelkosten des Vertriebs',
          ' = Selbstkosten                 (SK)',
        ],
        merke: 'Materialgemeinkosten immer auf das Fertigungsmaterial, '
            'Fertigungsgemeinkosten immer auf die Fertigungslöhne, Verwaltung '
            'und Vertrieb immer auf die Herstellkosten. Die '
            'Sondereinzelkosten der Fertigung gehen in die Herstellkosten ein, '
            'die des Vertriebs erst danach.',
        falle: 'Sondereinzelkosten des Vertriebs (Verpackung, Fracht, '
            'Provision) dürfen niemals in die Herstellkosten – sonst erhöhen '
            'sie fälschlich die Basis für die Verwaltungs- und '
            'Vertriebszuschläge.',
      ),
      KwSection(
        title: 'Vom Angebot zum Verkaufspreis',
        body: 'Auf die Selbstkosten kommt der Gewinn – und danach das, was der '
            'Kunde später wieder abzieht: Skonto und Rabatt. Genau hier liegt '
            'die klassische Falle. Skonto und Rabatt beziehen sich immer auf '
            'den höheren Wert, nicht auf den, von dem du gerade kommst.',
        scheme: [
          '   Selbstkosten',
          ' + Gewinnzuschlag        % von den Selbstkosten',
          ' = Barverkaufspreis',
          ' + Kundenskonto          % vom Zielverkaufspreis',
          ' = Zielverkaufspreis',
          ' + Kundenrabatt          % vom Listenverkaufspreis',
          ' = Listenverkaufspreis (netto)',
          ' + Umsatzsteuer',
          ' = Bruttoverkaufspreis',
        ],
        formulas: [
          KwFormula('Vorwärts (im Hundert)',
              'Zielverkaufspreis = Barverkaufspreis ÷ (100 − Skonto%) × 100'),
          KwFormula('Rückwärts (vom Hundert)',
              'Zielverkaufspreis = Listenpreis × (100 − Rabatt%) ÷ 100'),
          KwFormula('Differenzkalkulation',
              'Gewinn = Barverkaufspreis − Selbstkosten'),
        ],
        example: KwExample(
          task: 'Barverkaufspreis 970 €, Kundenskonto 3 %. Wie hoch ist der '
              'Zielverkaufspreis?',
          steps: [
            'Falsch wäre: 970 + 3 % = 999,10 €',
            'Richtig: Die 3 % beziehen sich auf den Zielverkaufspreis (100 %).',
            '970 € entsprechen also 97 %.',
            '970 ÷ 97 × 100 = 1.000 €',
          ],
          result: 'Zielverkaufspreis = 1.000 € (Probe: 1.000 − 3 % = 970 €)',
        ),
        falle: 'Vorwärts wird geteilt („im Hundert"), rückwärts wird '
            'multipliziert („vom Hundert"). Mach immer die Probe – sie kostet '
            'zehn Sekunden und rettet die Aufgabe.',
      ),
      KwSection(
        title: 'Maschinenstundensatzrechnung',
        body: 'Wo Maschinen den Takt vorgeben, ist der Fertigungslohn eine '
            'schlechte Bezugsgröße – eine hochautomatisierte Anlage würde zu '
            'wenig Gemeinkosten tragen. Deshalb werden die maschinenabhängigen '
            'Kosten separat erfasst und durch die Laufzeit geteilt.',
        formulas: [
          KwFormula('Maschinenstundensatz',
              'maschinenabhängige Kosten pro Jahr ÷ Maschinenlaufstunden pro Jahr'),
          KwFormula('Fertigungskosten',
              'Maschinenstundensatz × Laufzeit + Restgemeinkosten auf den Lohn'),
        ],
        bullets: [
          'Maschinenabhängig: kalk. Abschreibung, kalk. Zinsen, Raumkosten, Energie, Instandhaltung, Werkzeuge.',
          'Der Rest der Fertigungsgemeinkosten wird weiter über einen Restgemeinkostenzuschlag auf die Löhne verrechnet.',
        ],
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────── 5
  KwChapter(
    id: 'teilkosten',
    title: 'Deckungsbeitrag & Entscheidungen',
    subtitle: 'Teilkosten · Break-Even · Preisuntergrenze · Engpass',
    icon: Icons.trending_up,
    color: kDue,
    sections: [
      KwSection(
        title: 'Warum Vollkosten in die Irre führen',
        body: 'Die Vollkostenrechnung verteilt alle Fixkosten auf die Produkte '
            '– so, als würden sie durch das einzelne Stück verursacht. Das ist '
            'für die Kalkulation langfristig richtig, für kurzfristige '
            'Entscheidungen aber gefährlich. Streichst du ein Produkt, weil es '
            'laut Vollkostenrechnung Verlust bringt, bleiben die Fixkosten '
            'trotzdem da – sie verteilen sich nur auf weniger Produkte. Am Ende '
            'geht ein Produkt nach dem anderen, bis nichts mehr übrig ist.',
        merke: 'Die Teilkostenrechnung rechnet nur mit den variablen Kosten – '
            'also mit den Kosten, die tatsächlich wegfallen, wenn du die '
            'Entscheidung anders triffst.',
      ),
      KwSection(
        title: 'Der Deckungsbeitrag',
        body: 'Der Deckungsbeitrag ist der Betrag, der nach Abzug der '
            'variablen Kosten übrig bleibt, um die Fixkosten zu decken – und '
            'alles darüber hinaus ist Gewinn. Solange ein Produkt einen '
            'positiven Deckungsbeitrag liefert, trägt es zum Ergebnis bei.',
        formulas: [
          KwFormula('Stückdeckungsbeitrag', 'db = Preis − variable Stückkosten'),
          KwFormula('Gesamtdeckungsbeitrag', 'DB = Umsatz − variable Kosten = db × Menge'),
          KwFormula('Deckungsbeitragsrate', 'DB-Rate % = db ÷ Preis × 100'),
          KwFormula('Betriebsergebnis', 'Gewinn = Gesamtdeckungsbeitrag − Fixkosten'),
        ],
        example: KwExample(
          task: 'Preis 50 €/Stück, variable Kosten 30 €/Stück, Fixkosten '
              '120.000 €, Absatz 8.000 Stück.',
          steps: [
            'db = 50 − 30 = 20 €',
            'DB gesamt = 20 × 8.000 = 160.000 €',
            'Gewinn = 160.000 − 120.000 = 40.000 €',
          ],
          result: 'Gewinn = 40.000 € · DB-Rate = 40 %',
        ),
      ),
      KwSection(
        title: 'Break-Even-Punkt (Gewinnschwelle)',
        body: 'Der Break-Even-Punkt ist die Menge, bei der die Fixkosten genau '
            'gedeckt sind: Der Betrieb macht weder Gewinn noch Verlust. Jede '
            'weitere Einheit bringt ihren vollen Deckungsbeitrag als Gewinn.',
        formulas: [
          KwFormula('Break-Even-Menge', 'Fixkosten ÷ Stückdeckungsbeitrag'),
          KwFormula('Break-Even-Umsatz', 'Fixkosten ÷ DB-Rate × 100'),
          KwFormula('Menge für Zielgewinn',
              '(Fixkosten + Zielgewinn) ÷ Stückdeckungsbeitrag'),
          KwFormula('Sicherheitsstrecke %',
              '(Ist-Menge − Break-Even-Menge) ÷ Ist-Menge × 100',
              note: 'Sagt, um wie viel der Absatz einbrechen darf, bevor Verlust entsteht.'),
        ],
        example: KwExample(
          task: 'Fixkosten 120.000 €, db 20 €/Stück, tatsächlicher Absatz '
              '8.000 Stück.',
          steps: [
            'Break-Even-Menge = 120.000 ÷ 20 = 6.000 Stück',
            'Sicherheitsstrecke = (8.000 − 6.000) ÷ 8.000 × 100',
          ],
          result: 'Gewinnschwelle bei 6.000 Stück · Sicherheitsstrecke 25 %',
        ),
      ),
      KwSection(
        title: 'Preisuntergrenzen',
        body: 'Wie weit darfst du mit dem Preis heruntergehen? Die Antwort '
            'hängt vom Zeithorizont ab – und diese Unterscheidung ist '
            'prüfungsrelevant.',
        bullets: [
          'Kurzfristige Preisuntergrenze = variable Stückkosten. Darunter verlierst du mit jedem Stück zusätzlich Geld.',
          'Langfristige Preisuntergrenze = Selbstkosten (Vollkosten). Auf Dauer müssen auch die Fixkosten verdient werden.',
          'Zwischen beiden Grenzen liefert der Auftrag einen Beitrag zur Fixkostendeckung – bei freien Kapazitäten also sinnvoll.',
        ],
        merke: 'Kurzfristig entscheidet der Deckungsbeitrag, langfristig die '
            'Vollkostendeckung.',
      ),
      KwSection(
        title: 'Zusatzauftrag, Eigenfertigung und Engpass',
        body: 'Mit dem Deckungsbeitrag löst du die drei klassischen '
            'Entscheidungsaufgaben.',
        bullets: [
          'Zusatzauftrag annehmen? Ja, wenn der Preis über den variablen Stückkosten liegt UND freie Kapazität vorhanden ist.',
          'Eigenfertigung oder Fremdbezug? Vergleiche den Einkaufspreis mit den variablen Kosten der Eigenfertigung – Fixkosten laufen ja weiter.',
          'Engpass (z. B. begrenzte Maschinenstunden): Nicht der höchste Deckungsbeitrag gewinnt, sondern der höchste Deckungsbeitrag je Engpasseinheit.',
        ],
        formulas: [
          KwFormula('Relativer Deckungsbeitrag',
              'db ÷ Verbrauch der Engpasseinheit je Stück',
              note: 'Das Produkt mit dem höchsten Wert kommt zuerst ins Programm.'),
        ],
        example: KwExample(
          task: 'Produkt A: db 30 €, braucht 3 Maschinenstunden. '
              'Produkt B: db 24 €, braucht 1,5 Maschinenstunden. Die '
              'Maschinenkapazität ist der Engpass.',
          steps: [
            'A: 30 ÷ 3 = 10 € je Maschinenstunde',
            'B: 24 ÷ 1,5 = 16 € je Maschinenstunde',
          ],
          result: 'Produkt B zuerst fertigen – trotz niedrigerem Stück-DB.',
        ),
        falle: 'Bei Engpassaufgaben wählt fast jeder spontan das Produkt mit '
            'dem höchsten Deckungsbeitrag. Das ist genau dann falsch, wenn die '
            'Produkte den Engpass unterschiedlich stark beanspruchen.',
      ),
      KwSection(
        title: 'Mehrstufige Deckungsbeitragsrechnung',
        body: 'Fixkosten sind nicht alle gleich: Manche gehören zu einem '
            'Produkt, manche zu einer Produktgruppe, manche zum ganzen '
            'Unternehmen. Die stufenweise Fixkostendeckungsrechnung zieht sie '
            'nacheinander ab und zeigt so, auf welcher Ebene das Geld verloren '
            'geht.',
        scheme: [
          '   Umsatz',
          ' − variable Kosten',
          ' = Deckungsbeitrag I',
          ' − Erzeugnisfixkosten',
          ' = Deckungsbeitrag II',
          ' − Erzeugnisgruppenfixkosten',
          ' = Deckungsbeitrag III',
          ' − Unternehmensfixkosten',
          ' = Betriebsergebnis',
        ],
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────── 6
  KwChapter(
    id: 'plankosten',
    title: 'Plankosten & Kennzahlen',
    subtitle: 'Soll-Ist-Vergleich · Abweichungen · Wirtschaftlichkeit',
    icon: Icons.query_stats,
    color: kErr,
    sections: [
      KwSection(
        title: 'Ist, Normal, Plan',
        body: 'Nach welchen Werten wird gerechnet? Die Istkostenrechnung '
            'schaut zurück und nimmt die tatsächlichen Zahlen – gut für die '
            'Dokumentation, schlecht für die Steuerung, weil zufällige '
            'Ausreißer mitlaufen. Die Normalkostenrechnung glättet über '
            'Durchschnittswerte. Die Plankostenrechnung setzt Vorgabewerte und '
            'macht damit echte Kontrolle möglich.',
        bullets: [
          'Starre Plankostenrechnung: keine Anpassung an die tatsächliche Beschäftigung – nur begrenzt aussagefähig.',
          'Flexible Plankostenrechnung: trennt fixe und variable Kosten und passt die Sollkosten an die Ist-Beschäftigung an.',
        ],
      ),
      KwSection(
        title: 'Abweichungsanalyse',
        body: 'Die entscheidende Größe ist die Sollkostenlinie: Was hätten die '
            'Kosten bei der tatsächlichen Beschäftigung kosten dürfen? Der '
            'Vergleich mit den Istkosten zeigt, ob unwirtschaftlich gearbeitet '
            'wurde – der Vergleich mit den verrechneten Plankosten zeigt, ob '
            'die Anlage ausgelastet war.',
        formulas: [
          KwFormula('Sollkosten', 'Kf(Plan) + kv(Plan) × Ist-Beschäftigung'),
          KwFormula('Verrechnete Plankosten',
              'Plankostenverrechnungssatz × Ist-Beschäftigung'),
          KwFormula('Verbrauchsabweichung', 'Istkosten − Sollkosten',
              note: 'Zeigt Unwirtschaftlichkeit – dafür ist die Kostenstelle verantwortlich.'),
          KwFormula('Beschäftigungsabweichung',
              'Sollkosten − verrechnete Plankosten',
              note: 'Entsteht durch Leerkosten bei Unterauslastung – dafür kann die Stelle nichts.'),
        ],
        merke: 'Verbrauchsabweichung = Wirtschaftlichkeit. '
            'Beschäftigungsabweichung = Auslastung.',
      ),
      KwSection(
        title: 'Nutz- und Leerkosten',
        body: 'Wird eine Anlage nicht voll genutzt, zerfallen die Fixkosten '
            'gedanklich in zwei Teile: Der genutzte Teil ist wertschöpfend '
            '(Nutzkosten), der ungenutzte Teil verpufft (Leerkosten). Das ist '
            'das stärkste Argument für hohe Auslastung.',
        formulas: [
          KwFormula('Nutzkosten', 'Fixkosten × Beschäftigungsgrad ÷ 100'),
          KwFormula('Leerkosten', 'Fixkosten − Nutzkosten'),
          KwFormula('Beschäftigungsgrad',
              'Ist-Beschäftigung ÷ Plan-Beschäftigung × 100'),
        ],
        example: KwExample(
          task: 'Fixkosten 200.000 €, Kapazität 10.000 Stunden, tatsächlich '
              'genutzt 7.500 Stunden.',
          steps: [
            'Beschäftigungsgrad = 7.500 ÷ 10.000 × 100 = 75 %',
            'Nutzkosten = 200.000 × 75 % = 150.000 €',
            'Leerkosten = 200.000 − 150.000 = 50.000 €',
          ],
          result: '50.000 € Leerkosten – Kosten für nicht genutzte Bereitschaft.',
        ),
      ),
      KwSection(
        title: 'Kennzahlen für die Meisterpraxis',
        body: 'Zum Abschluss die Kennzahlen, mit denen du deinen Bereich '
            'steuerst und in der Prüfung argumentierst.',
        formulas: [
          KwFormula('Produktivität', 'Ausbringungsmenge ÷ Faktoreinsatz',
              note: 'Mengengröße, z. B. Stück je Mitarbeiterstunde.'),
          KwFormula('Wirtschaftlichkeit', 'Leistung ÷ Kosten',
              note: 'Wertgröße; auch als Sollkosten ÷ Istkosten.'),
          KwFormula('Umsatzrentabilität', 'Gewinn ÷ Umsatz × 100'),
          KwFormula('Return on Investment',
              'Umsatzrentabilität × Kapitalumschlag = Gewinn ÷ Gesamtkapital × 100'),
        ],
        merke: 'Produktivität ist mengenbezogen, Wirtschaftlichkeit '
            'wertbezogen, Rentabilität kapitalbezogen. Diese Dreiteilung wird '
            'gern abgefragt.',
      ),
    ],
  ),
];
