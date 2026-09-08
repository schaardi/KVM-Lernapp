# -*- coding: utf-8 -*-
"""Rechen-Spezifikationen für das Formelbuch.

Jede Formel, die sich ausrechnen lässt, bekommt hier Variablen, einen
Ausdruck und eine Ergebnisangabe. Die Angaben werden von
``build_formelbuch.py`` in ``flutter_app/assets/data/formulas.json``
eingetragen; Web und App rechnen daraus mit demselben Parser.

Ausdrucks-Syntax (bewusst klein gehalten, beide Laufzeiten können sie):
    + - * / ^  ( )  sqrt() sin() cos() tan() abs() min(a,b) max(a,b)  pi
Winkelfunktionen rechnen in Grad.
"""

def v(k, n, u='', d=None):
    """Eingabefeld: Kürzel im Ausdruck, Beschriftung, Einheit, Vorbelegung."""
    o = {'k': k, 'n': n}
    if u:
        o['u'] = u
    if d is not None:
        o['d'] = d
    return o


def rechne(vars_, f, ergebnis, einheit='', dec=2):
    return {'v': vars_, 'f': f, 'r': {'n': ergebnis, 'u': einheit}, 'dec': dec}


# ---------------------------------------------------------------- Rechenwege
# Schlüssel: (Gruppe, Formelname) – exakt wie in formulas.json.
RECHNEN = {
 # ---- Prozent- & Zinsrechnung
 ("Prozent- & Zinsrechnung", "Prozentwert"):
   rechne([v('G','Grundwert','€'), v('p','Prozentsatz','%')], 'G*p/100', 'Prozentwert','€'),
 ("Prozent- & Zinsrechnung", "Grundwert"):
   rechne([v('W','Prozentwert','€'), v('p','Prozentsatz','%')], 'W*100/p', 'Grundwert','€'),
 ("Prozent- & Zinsrechnung", "Prozentsatz"):
   rechne([v('W','Prozentwert','€'), v('G','Grundwert','€')], 'W*100/G', 'Prozentsatz','%'),
 ("Prozent- & Zinsrechnung", "Jahreszinsen"):
   rechne([v('K','Kapital','€'), v('p','Zinssatz','%')], 'K*p/100', 'Jahreszinsen','€'),
 ("Prozent- & Zinsrechnung", "Tageszinsen"):
   rechne([v('K','Kapital','€'), v('p','Zinssatz','%'), v('t','Tage','Tage')],
          'K*p*t/36000', 'Zinsen','€'),
 ("Prozent- & Zinsrechnung", "Brutto aus Netto"):
   rechne([v('N','Nettobetrag','€'), v('p','Umsatzsteuersatz','%',19)],
          'N*(1+p/100)', 'Bruttobetrag','€'),
 ("Prozent- & Zinsrechnung", "Netto aus Brutto"):
   rechne([v('B','Bruttobetrag','€'), v('p','Umsatzsteuersatz','%',19)],
          'B/(1+p/100)', 'Nettobetrag','€'),
 ("Prozent- & Zinsrechnung", "Skontobetrag"):
   rechne([v('R','Rechnungsbetrag','€'), v('p','Skontosatz','%',2)],
          'R*p/100', 'Skontobetrag','€'),

 # ---- Handelskalkulation
 ("Handelskalkulation", "Bezugspreis (Einstandspreis)"):
   rechne([v('LEP','Listeneinkaufspreis','€'), v('rab','Liefererrabatt','%'),
           v('sk','Liefererskonto','%'), v('BK','Bezugskosten','€',0)],
          'LEP*(1-rab/100)*(1-sk/100)+BK', 'Bezugspreis','€'),
 ("Handelskalkulation", "Selbstkostenpreis"):
   rechne([v('BP','Bezugspreis','€'), v('hkz','Handlungskostenzuschlag','%')],
          'BP*(1+hkz/100)', 'Selbstkosten','€'),
 ("Handelskalkulation", "Barverkaufspreis"):
   rechne([v('SK','Selbstkosten','€'), v('g','Gewinnzuschlag','%')],
          'SK*(1+g/100)', 'Barverkaufspreis','€'),
 ("Handelskalkulation", "Zielverkaufspreis"):
   rechne([v('BVP','Barverkaufspreis','€'), v('sk','Kundenskonto','%'),
           v('pr','Vertreterprovision','%',0)],
          'BVP/(1-(sk+pr)/100)', 'Zielverkaufspreis','€'),
 ("Handelskalkulation", "Listenverkaufspreis (netto)"):
   rechne([v('ZVP','Zielverkaufspreis','€'), v('rab','Kundenrabatt','%')],
          'ZVP/(1-rab/100)', 'Listenverkaufspreis','€'),
 ("Handelskalkulation", "Handelsspanne"):
   rechne([v('VK','Verkaufspreis','€'), v('EK','Einkaufspreis','€')],
          '(VK-EK)/VK*100', 'Handelsspanne','%'),
 ("Handelskalkulation", "Kalkulationszuschlag"):
   rechne([v('VK','Verkaufspreis','€'), v('EK','Einkaufspreis','€')],
          '(VK-EK)/EK*100', 'Kalkulationszuschlag','%'),
 ("Handelskalkulation", "Kalkulationsfaktor"):
   rechne([v('VK','Verkaufspreis','€'), v('EK','Einkaufspreis','€')],
          'VK/EK', 'Kalkulationsfaktor','', 4),
 ("Handelskalkulation", "Vorwärtskalkulation (im Hundert)"):
   rechne([v('BP','Barpreis','€'), v('p','Skonto-/Provisionssatz','%')],
          'BP/(100-p)*100', 'Zielpreis','€'),
 ("Handelskalkulation", "Rückwärtskalkulation (vom Hundert)"):
   rechne([v('LP','Listenpreis','€'), v('p','Rabattsatz','%')],
          'LP*(100-p)/100', 'Zielpreis','€'),

 # ---- Zuschlagskalkulation & Kostenstellen
 ("Zuschlagskalkulation & Kostenstellen", "Materialgemeinkostensatz"):
   rechne([v('MGK','Materialgemeinkosten','€'), v('FM','Fertigungsmaterial','€')],
          'MGK/FM*100', 'MGK-Satz','%'),
 ("Zuschlagskalkulation & Kostenstellen", "Fertigungsgemeinkostensatz"):
   rechne([v('FGK','Fertigungsgemeinkosten','€'), v('FL','Fertigungslöhne','€')],
          'FGK/FL*100', 'FGK-Satz','%'),
 ("Zuschlagskalkulation & Kostenstellen", "Herstellkosten"):
   rechne([v('FM','Fertigungsmaterial','€'), v('MGK','Materialgemeinkosten','€'),
           v('FL','Fertigungslöhne','€'), v('FGK','Fertigungsgemeinkosten','€'),
           v('SEF','Sondereinzelkosten Fertigung','€',0)],
          'FM+MGK+FL+FGK+SEF', 'Herstellkosten','€'),
 ("Zuschlagskalkulation & Kostenstellen", "Verwaltungs-/Vertriebsgemeinkostensatz"):
   rechne([v('GK','Gemeinkosten','€'), v('HK','Herstellkosten','€')],
          'GK/HK*100', 'Zuschlagssatz','%'),
 ("Zuschlagskalkulation & Kostenstellen", "Selbstkosten"):
   rechne([v('HK','Herstellkosten','€'), v('VwGK','Verwaltungsgemeinkosten','€'),
           v('VtGK','Vertriebsgemeinkosten','€'), v('SEV','Sondereinzelkosten Vertrieb','€',0)],
          'HK+VwGK+VtGK+SEV', 'Selbstkosten','€'),
 ("Zuschlagskalkulation & Kostenstellen", "Über-/Unterdeckung"):
   rechne([v('ver','verrechnete Gemeinkosten','€'), v('ist','Ist-Gemeinkosten','€')],
          'ver-ist', 'Über-(+)/Unterdeckung(−)','€'),
 ("Zuschlagskalkulation & Kostenstellen", "Maschinenstundensatz"):
   rechne([v('K','maschinenabhängige Kosten','€'), v('h','Maschinenlaufstunden','h')],
          'K/h', 'Maschinenstundensatz','€/h'),
 ("Zuschlagskalkulation & Kostenstellen", "Divisionskalkulation"):
   rechne([v('K','Gesamtkosten','€'), v('x','Menge','Stück')], 'K/x', 'Stückkosten','€/Stück'),
 ("Zuschlagskalkulation & Kostenstellen", "Äquivalenzziffer – Rechnungseinheiten"):
   rechne([v('m','Menge','Stück'), v('a','Äquivalenzziffer','',1)],
          'm*a', 'Rechnungseinheiten','RE'),
 ("Zuschlagskalkulation & Kostenstellen", "Äquivalenzziffer – Stückkosten"):
   rechne([v('K','Gesamtkosten','€'), v('RE','Summe Rechnungseinheiten','RE'),
           v('a','Äquivalenzziffer der Sorte','',1)],
          'K/RE*a', 'Stückkosten der Sorte','€/Stück'),

 # ---- Kalkulatorische Kosten
 ("Kalkulatorische Kosten", "Kalk. Abschreibung (linear)"):
   rechne([v('WBW','Wiederbeschaffungswert','€'), v('RW','Restwert','€',0),
           v('ND','Nutzungsdauer','Jahre')],
          '(WBW-RW)/ND', 'Abschreibung je Jahr','€'),
 ("Kalkulatorische Kosten", "Kalk. Abschreibung (leistungsbezogen)"):
   rechne([v('WBW','Wiederbeschaffungswert','€'), v('RW','Restwert','€',0),
           v('GL','Gesamtleistung',''), v('PL','Periodenleistung','')],
          '(WBW-RW)/GL*PL', 'Abschreibung der Periode','€'),
 ("Kalkulatorische Kosten", "Betriebsnotwendiges Kapital"):
   rechne([v('BNV','betriebsnotwendiges Vermögen','€'), v('AK','Abzugskapital','€',0)],
          'BNV-AK', 'betriebsnotwendiges Kapital','€'),
 ("Kalkulatorische Kosten", "Kalk. Zinsen"):
   rechne([v('BNK','betriebsnotwendiges Kapital','€'), v('i','Zinssatz','%')],
          'BNK*i/100', 'kalkulatorische Zinsen','€'),
 ("Kalkulatorische Kosten", "Wagnissatz"):
   rechne([v('WV','Wagnisverluste','€'), v('BG','Bezugsgröße','€')],
          'WV/BG*100', 'Wagnissatz','%'),
 ("Kalkulatorische Kosten", "Kalk. Wagnis"):
   rechne([v('BG','Bezugsgröße im Planjahr','€'), v('ws','Wagnissatz','%')],
          'BG*ws/100', 'kalkulatorisches Wagnis','€'),
 ("Kalkulatorische Kosten", "Beschäftigungsgrad"):
   rechne([v('ist','Ist-Beschäftigung',''), v('plan','Plan-Beschäftigung','')],
          'ist/plan*100', 'Beschäftigungsgrad','%'),
 ("Kalkulatorische Kosten", "Nutzkosten"):
   rechne([v('Kf','Fixkosten','€'), v('BG','Beschäftigungsgrad','%')],
          'Kf*BG/100', 'Nutzkosten','€'),
 ("Kalkulatorische Kosten", "Leerkosten"):
   rechne([v('Kf','Fixkosten','€'), v('NK','Nutzkosten','€')], 'Kf-NK', 'Leerkosten','€'),

 # ---- Kosten- & Leistungsrechnung
 ("Kosten- & Leistungsrechnung", "Deckungsbeitrag je Stück"):
   rechne([v('p','Verkaufspreis','€'), v('kv','variable Stückkosten','€')],
          'p-kv', 'Stückdeckungsbeitrag','€'),
 ("Kosten- & Leistungsrechnung", "Deckungsbeitrag gesamt"):
   rechne([v('U','Umsatz','€'), v('Kv','variable Kosten','€')], 'U-Kv', 'Deckungsbeitrag','€'),
 ("Kosten- & Leistungsrechnung", "Gewinn"):
   rechne([v('U','Umsatz','€'), v('K','Gesamtkosten','€')], 'U-K', 'Gewinn','€'),
 ("Kosten- & Leistungsrechnung", "Gesamtkosten"):
   rechne([v('Kf','Fixkosten','€'), v('Kv','variable Kosten','€')], 'Kf+Kv', 'Gesamtkosten','€'),
 ("Kosten- & Leistungsrechnung", "Break-Even-Menge"):
   rechne([v('Kf','Fixkosten','€'), v('p','Verkaufspreis','€'), v('kv','variable Stückkosten','€')],
          'Kf/(p-kv)', 'Break-Even-Menge','Stück'),
 ("Kosten- & Leistungsrechnung", "Stückkosten"):
   rechne([v('K','Gesamtkosten','€'), v('x','Menge','Stück')], 'K/x', 'Stückkosten','€/Stück'),
 ("Kosten- & Leistungsrechnung", "Kostendeckungsgrad"):
   rechne([v('DB','Deckungsbeitrag','€'), v('Kf','Fixkosten','€')],
          'DB/Kf*100', 'Kostendeckungsgrad','%'),
 ("Kosten- & Leistungsrechnung", "Deckungsbeitragsrate"):
   rechne([v('db','Stückdeckungsbeitrag','€'), v('p','Verkaufspreis','€')],
          'db/p*100', 'DB-Rate (DBU-Quote)','%'),
 ("Kosten- & Leistungsrechnung", "Break-Even-Umsatz"):
   rechne([v('Kf','Fixkosten','€'), v('r','DB-Rate','%')], 'Kf/r*100', 'Break-Even-Umsatz','€'),
 ("Kosten- & Leistungsrechnung", "Menge für Zielgewinn"):
   rechne([v('Kf','Fixkosten','€'), v('G','Zielgewinn','€'), v('db','Stückdeckungsbeitrag','€')],
          '(Kf+G)/db', 'Menge','Stück'),
 ("Kosten- & Leistungsrechnung", "Sicherheitsstrecke"):
   rechne([v('xist','Ist-Menge','Stück'), v('xbep','Break-Even-Menge','Stück')],
          '(xist-xbep)/xist*100', 'Sicherheitsstrecke','%'),

 # ---- Materialwirtschaft & Lager
 ("Materialwirtschaft & Lager", "Optimale Bestellmenge (Andler)"):
   rechne([v('JB','Jahresbedarf',''), v('kB','Bestellkosten je Bestellung','€'),
           v('EP','Einstandspreis je Einheit','€'), v('LKS','Lagerkostensatz','%')],
          'sqrt(200*JB*kB/(EP*LKS))', 'optimale Bestellmenge','', 2),
 ("Materialwirtschaft & Lager", "Meldebestand"):
   rechne([v('TV','Tagesverbrauch',''), v('LZ','Lieferzeit','Tage'),
           v('MB','Mindest-/Sicherheitsbestand','',0)],
          'TV*LZ+MB', 'Meldebestand','', 2),
 ("Materialwirtschaft & Lager", "Ø Lagerbestand"):
   rechne([v('AB','Anfangsbestand',''), v('EB','Endbestand','')],
          '(AB+EB)/2', 'Ø Lagerbestand','', 2),
 ("Materialwirtschaft & Lager", "Lagerumschlagshäufigkeit"):
   rechne([v('WE','Wareneinsatz',''), v('LB','Ø Lagerbestand','')],
          'WE/LB', 'Umschlagshäufigkeit','', 2),
 ("Materialwirtschaft & Lager", "Ø Lagerdauer (Tage)"):
   rechne([v('LUH','Lagerumschlagshäufigkeit','')], '360/LUH', 'Ø Lagerdauer','Tage'),
 ("Materialwirtschaft & Lager", "Lagerzinssatz"):
   rechne([v('JZ','Jahreszinssatz','%'), v('LD','Ø Lagerdauer','Tage')],
          'JZ*LD/360', 'Lagerzinssatz','%'),
 ("Materialwirtschaft & Lager", "Bestellkosten je Jahr"):
   rechne([v('JB','Jahresbedarf',''), v('BM','Bestellmenge',''),
           v('kB','Kosten je Bestellung','€')],
          'JB/BM*kB', 'Bestellkosten je Jahr','€'),
 ("Materialwirtschaft & Lager", "Lagerhaltungskosten je Jahr"):
   rechne([v('LB','Ø Lagerbestand',''), v('EP','Einstandspreis je Einheit','€'),
           v('LKS','Lagerkostensatz','%')],
          'LB*EP*LKS/100', 'Lagerhaltungskosten je Jahr','€'),

 # ---- Nutzwertanalyse
 ("Nutzwertanalyse & Bewertung", "Teilnutzwert"):
   rechne([v('g','Gewichtung',''), v('p','Punkte','')], 'g*p', 'Teilnutzwert','', 2),

 # ---- Statistik
 ("Statistik", "Arithmetisches Mittel"):
   rechne([v('S','Summe der Werte',''), v('n','Anzahl der Werte','')],
          'S/n', 'Mittelwert','', 2),
 ("Statistik", "Spannweite"):
   rechne([v('max','Maximum',''), v('min','Minimum','')], 'max-min', 'Spannweite','', 2),
 ("Statistik", "Wachstumsrate"):
   rechne([v('neu','neuer Wert',''), v('alt','alter Wert','')],
          '(neu-alt)/alt*100', 'Wachstumsrate','%'),

 # ---- Kennzahlen & Rentabilität
 ("Kennzahlen & Rentabilität", "Eigenkapitalrentabilität"):
   rechne([v('G','Gewinn','€'), v('EK','Eigenkapital','€')], 'G/EK*100', 'EK-Rentabilität','%'),
 ("Kennzahlen & Rentabilität", "Gesamtkapitalrentabilität"):
   rechne([v('G','Gewinn','€'), v('FKZ','Fremdkapitalzinsen','€'), v('GK','Gesamtkapital','€')],
          '(G+FKZ)/GK*100', 'GK-Rentabilität','%'),
 ("Kennzahlen & Rentabilität", "Umsatzrentabilität"):
   rechne([v('G','Gewinn','€'), v('U','Umsatz','€')], 'G/U*100', 'Umsatzrentabilität','%'),
 ("Kennzahlen & Rentabilität", "Produktivität"):
   rechne([v('aus','Ausbringungsmenge',''), v('ein','Faktoreinsatzmenge','')],
          'aus/ein', 'Produktivität','', 4),
 ("Kennzahlen & Rentabilität", "Wirtschaftlichkeit"):
   rechne([v('ertrag','Ertrag','€'), v('aufwand','Aufwand','€')],
          'ertrag/aufwand', 'Wirtschaftlichkeit','', 4),
 ("Kennzahlen & Rentabilität", "Cashflow (vereinfacht)"):
   rechne([v('JU','Jahresüberschuss','€'), v('AfA','Abschreibungen','€',0),
           v('RSt','Zuführung Rückstellungen','€',0)],
          'JU+AfA+RSt', 'Cashflow','€'),
 ("Kennzahlen & Rentabilität", "Liquidität 1. Grades"):
   rechne([v('FM','flüssige Mittel','€'), v('KV','kurzfristige Verbindlichkeiten','€')],
          'FM/KV*100', 'Liquidität 1. Grades','%'),

 # ---- Personal & Zeit
 ("Personal & Zeit", "Fluktuationsrate"):
   rechne([v('ab','Abgänge','MA'), v('best','Ø Personalbestand','MA')],
          'ab/best*100', 'Fluktuationsrate','%'),
 ("Personal & Zeit", "Krankenstand"):
   rechne([v('kt','Kranktage','Tage'), v('sat','Sollarbeitstage','Tage')],
          'kt/sat*100', 'Krankenstand','%'),
 ("Personal & Zeit", "Produktivität je Kopf"):
   rechne([v('L','Leistung',''), v('n','Anzahl Mitarbeitende','MA')],
          'L/n', 'Leistung je Kopf','', 2),

 # ---- Transport- & Fuhrparkkosten
 ("Transport- & Fuhrparkkosten", "Kraftstoffverbrauch"):
   rechne([v('l','verbrauchte Liter','l'), v('km','gefahrene Strecke','km')],
          'l/km*100', 'Verbrauch','l/100 km'),
 ("Transport- & Fuhrparkkosten", "Kraftstoffkosten je km"):
   rechne([v('V','Verbrauch je 100 km','l'), v('P','Preis je Liter','€')],
          'V/100*P', 'Kraftstoffkosten','€/km', 4),
 ("Transport- & Fuhrparkkosten", "Gesamtkosten je km"):
   rechne([v('K','Gesamtkosten','€'), v('km','Fahrleistung','km')],
          'K/km', 'Kosten je km','€/km', 4),
 ("Transport- & Fuhrparkkosten", "Fahrzeugauslastung"):
   rechne([v('zul','tatsächliche Zuladung','t'), v('NL','zul. Nutzlast','t')],
          'zul/NL*100', 'Auslastung','%'),
 ("Transport- & Fuhrparkkosten", "Tonnenkilometer"):
   rechne([v('t','beförderte Tonnen','t'), v('km','gefahrene Kilometer','km')],
          't*km', 'Tonnenkilometer','tkm'),
 ("Transport- & Fuhrparkkosten", "Kosten je Tonnenkilometer"):
   rechne([v('K','Gesamtkosten','€'), v('tkm','Tonnenkilometer','tkm')],
          'K/tkm', 'Kosten je tkm','€/tkm', 4),
 ("Transport- & Fuhrparkkosten", "Lkw-Maut"):
   rechne([v('km','mautpflichtige Strecke','km'), v('satz','Mautsatz je km','€')],
          'km*satz', 'Maut','€'),
 ("Transport- & Fuhrparkkosten", "Kalk. Abschreibung (Fahrzeug)"):
   rechne([v('AW','Anschaffungswert','€'), v('RW','Restwert','€',0),
           v('ND','Nutzungsdauer','Jahre')],
          '(AW-RW)/ND', 'Abschreibung je Jahr','€'),
 ("Transport- & Fuhrparkkosten", "Kalk. Zinsen (Fahrzeug)"):
   rechne([v('AW','Anschaffungswert','€'), v('i','Zinssatz','%')],
          'AW/2*i/100', 'kalkulatorische Zinsen','€'),
 ("Transport- & Fuhrparkkosten", "Fixe Kosten je Einsatztag"):
   rechne([v('FJK','fixe Jahreskosten','€'), v('ET','Einsatztage','Tage')],
          'FJK/ET', 'Fixkosten je Einsatztag','€'),
 ("Transport- & Fuhrparkkosten", "Wirtschaftlichkeit"):
   rechne([v('erloese','Erlöse','€'), v('kosten','Kosten','€')],
          'erloese/kosten', 'Wirtschaftlichkeit','', 4),
 ("Transport- & Fuhrparkkosten", "Nutzplatzkilometer"):
   rechne([v('nkm','Nutzkilometer','km'), v('pl','Platzangebot','Plätze')],
          'nkm*pl', 'Nutzplatzkilometer','Pkm'),
 ("Transport- & Fuhrparkkosten", "Linienkosten je Jahr"):
   rechne([v('wkm','Wagenkilometer je Jahr','km'), v('kkm','Kosten je km','€')],
          'wkm*kkm', 'Linienkosten je Jahr','€'),

 # ---- Fahrzeuggewichte
 ("Fahrzeuggewichte & Abmessungen", "Nutzlast"):
   rechne([v('zGG','zul. Gesamtgewicht','kg'), v('LG','Leergewicht','kg')],
          'zGG-LG', 'Nutzlast','kg'),
 ("Fahrzeuggewichte & Abmessungen", "Ausnutzung der Nutzlast"):
   rechne([v('zul','Zuladung','kg'), v('NL','Nutzlast','kg')],
          'zul/NL*100', 'Ausnutzung','%'),

 # ---- Ladungssicherung
 ("Ladungssicherung (Physik)", "Gewichtskraft"):
   rechne([v('m','Masse','kg'), v('g','Fallbeschleunigung','m/s²',9.81)],
          'm*g', 'Gewichtskraft','N'),
 ("Ladungssicherung (Physik)", "Reibungskraft"):
   rechne([v('mue','Reibbeiwert µ','',0.3), v('FG','Gewichtskraft','daN')],
          'mue*FG', 'Reibungskraft','daN'),
 ("Ladungssicherung (Physik)", "Sicherungskraft nach vorn"):
   rechne([v('mue','Reibbeiwert µ','',0.3), v('FG','Gewichtskraft','daN')],
          '(0.8-mue)*FG', 'Sicherungskraft nach vorn','daN'),
 ("Ladungssicherung (Physik)", "Sicherungskraft seitlich / nach hinten"):
   rechne([v('mue','Reibbeiwert µ','',0.3), v('FG','Gewichtskraft','daN')],
          '(0.5-mue)*FG', 'Sicherungskraft','daN'),
 ("Ladungssicherung (Physik)", "Niederzurren – Anzahl Zurrgurte"):
   rechne([v('c','Beschleunigungsbeiwert','',0.8), v('mue','Reibbeiwert µ','',0.3),
           v('FG','Gewichtskraft','daN'), v('STF','Vorspannkraft je Gurt','daN',400)],
          '((c-mue)*FG)/(2*mue*STF)', 'benötigte Zurrgurte','Stück'),
 ("Ladungssicherung (Physik)", "Rückhaltekraft Stirnwand (Code L)"):
   rechne([v('NL','Nutzlast','daN')], 'min(0.4*NL,5000)', 'Rückhaltekraft Stirnwand','daN'),
 ("Ladungssicherung (Physik)", "Rückhaltekraft Stirnwand (Code XL)"):
   rechne([v('NL','Nutzlast','daN')], '0.5*NL', 'Rückhaltekraft Stirnwand','daN'),

 # ---- Lenk- & Ruhezeiten
 ("Lenk- & Ruhezeiten (VO (EG) 561/2006)", "Ausgleich reduzierter Ruhezeit"):
   rechne([v('genommen','genommene Ruhezeit','h',24)], '45-genommen', 'nachzuholen','h'),
}
