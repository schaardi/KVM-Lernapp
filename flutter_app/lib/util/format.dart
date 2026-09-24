/// Ganze Zahl mit Tausenderpunkt („3.666“) – ohne `intl`.
String fmtN(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

/// Prozentwert 0..1 als „37 %“.
String fmtProzent(double anteil) => '${(anteil * 100).round()} %';
