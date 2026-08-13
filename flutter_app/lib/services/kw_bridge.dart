/// Übergabe der im BAB ermittelten Zuschlagssätze an die Zuschlagskalkulation.
/// Bewusst schlank gehalten: Die Sätze überleben den Wechsel zwischen den
/// Rechnern innerhalb einer Sitzung, mehr braucht der Rechenweg nicht.
class KwRates {
  static double? mgk;
  static double? fgk;
  static double? vwgk;
  static double? vtgk;

  static bool get hasValues =>
      mgk != null || fgk != null || vwgk != null || vtgk != null;

  static void set({
    required double mgkSatz,
    required double fgkSatz,
    required double vwgkSatz,
    required double vtgkSatz,
  }) {
    mgk = mgkSatz;
    fgk = fgkSatz;
    vwgk = vwgkSatz;
    vtgk = vtgkSatz;
  }

  static void clear() {
    mgk = fgk = vwgk = vtgk = null;
  }
}
