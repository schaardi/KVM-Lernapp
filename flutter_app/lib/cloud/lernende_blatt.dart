import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../util/format.dart';
import '../widgets/ui.dart';
import 'bausteine.dart';
import 'lernstand_ansicht.dart';
import 'modelle.dart';
import 'vergleich_dienst.dart';
import 'werte.dart';

/// Öffnet den Dialog „Lernende“ (FR-012) – nur, wenn es Profile gibt.
Future<void> oeffneLernende(BuildContext context, {String? tab, String? profilPid, String? profilName}) async {
  final d = VergleichDienst.instance;
  if (!d.quelle.bereit || d.leuteOk != true) return;
  d.lernendeOeffnen(tab: tab, profilPid: profilPid, profilName: profilName);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: kPaper,
    constraints: const BoxConstraints(maxWidth: 760),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const LernendeBlatt(),
  );
}

/// Namen in Rangliste, Gruppe und Freundesliste öffnen das Profil – nur mit
/// Profilen und in der Rangliste.
void Function(String)? profilOeffner(BuildContext context, VergleichDienst d) =>
    d.leuteOk == true && d.dabei ? (name) => oeffneLernende(context, profilName: name) : null;

/// Dialog „Lernende“: Freunde (mit Zähler offener Anfragen), alle Lernenden,
/// mein Profil – und die Profilansicht.
class LernendeBlatt extends StatefulWidget {
  const LernendeBlatt({super.key});

  @override
  State<LernendeBlatt> createState() => _LernendeBlattState();
}

class _LernendeBlattState extends State<LernendeBlatt> {
  final _d = VergleichDienst.instance;
  late final TextEditingController _suche = TextEditingController(text: _d.lt.suche);
  Timer? _sucheT;
  bool _zu = false;

  @override
  void dispose() {
    _sucheT?.cancel();
    _suche.dispose();
    super.dispose();
  }

  /// Abgemeldet oder Konto gewechselt: Dialog schließen.
  void _schliessenWennAbgemeldet() {
    if (_zu || _d.quelle.bereit) return;
    _zu = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListenableBuilder(
        listenable: _d,
        builder: (context, _) {
          _schliessenWennAbgemeldet();
          return Column(children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: kLine, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 8, 6),
              child: Row(children: [
                Text('Lernende', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kInk)),
                const Spacer(),
                IconButton(
                  tooltip: 'Schließen',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ]),
            ),
            Divider(height: 1, color: kLine),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: EdgeInsets.fromLTRB(16, 14, 16, 24 + MediaQuery.viewInsetsOf(context).bottom),
                children: _inhalt(context),
              ),
            ),
          ]);
        },
      ),
    );
  }

  List<Widget> _inhalt(BuildContext context) {
    final lt = _d.lt;
    if (lt.profil != null || lt.profilLaedt) return [ProfilAnsicht(d: _d)];
    final anfragen = _d.fstand?.anfragen.length ?? 0;
    final breit = MediaQuery.sizeOf(context).width > 560;
    return [
      ReiterLeiste(umbrechen: true, [
        Reiter('Freunde', zaehler: anfragen, gewaehlt: lt.tab == 'freunde', onTap: () => _d.lernendeTab('freunde')),
        Reiter(breit ? 'Alle Lernenden' : 'Alle', gewaehlt: lt.tab == 'alle', onTap: () => _d.lernendeTab('alle')),
        Reiter('Mein Profil', gewaehlt: lt.tab == 'profil', onTap: () => _d.lernendeTab('profil')),
      ]),
      const SizedBox(height: 14),
      if (lt.meld.isNotEmpty) Rueckmeldung(lt.meld, ok: lt.meldOk),
      ...switch (lt.tab) {
        'alle' => _alle(),
        'profil' => _meinProfil(),
        _ => _freunde(),
      },
    ];
  }

  List<Widget> _freunde() {
    final fs = _d.fstand;
    if (fs == null) return [lead('Wird geladen …')];
    return [
      if (fs.anfragen.isNotEmpty) ...[
        unterkopf('Anfragen an dich'),
        PersonenListe(fs.anfragen, art: 'kurz'),
        const SizedBox(height: 16),
      ],
      unterkopf('Deine Freunde', zusatz: fs.freunde.isNotEmpty ? '${fs.freunde.length}' : null),
      if (fs.freunde.isNotEmpty)
        PersonenListe(fs.freunde, art: 'ohne')
      else
        LeerKasten(kinder: [
          leerText('Noch keine Freunde. Such Lernende aus deinem Kurs und schick eine Anfrage – befreundet seht '
              'ihr gegenseitig euren Lernstand je Fach.'),
          VgKnopf('Lernende finden', art: KnopfArt.voll, onPressed: () => _d.lernendeTab('alle')),
        ]),
      if (fs.gesendet.isNotEmpty) ...[
        const SizedBox(height: 16),
        unterkopf('Gesendete Anfragen'),
        PersonenListe(fs.gesendet, art: 'lang'),
      ],
    ];
  }

  void _suchen(String v, {bool sofort = false}) {
    _sucheT?.cancel();
    if (sofort) {
      _d.sucheSetzen(v.trim());
    } else {
      _sucheT = Timer(const Duration(milliseconds: 300), () => _d.sucheSetzen(v.trim()));
    }
  }

  List<Widget> _alle() {
    final lt = _d.lt;
    final l = lt.liste;
    return [
      TextField(
        controller: _suche,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.search,
        inputFormatters: [LengthLimitingTextInputFormatter(20)],
        onChanged: _suchen,
        onSubmitted: (v) => _suchen(v, sofort: true),
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kInk),
        decoration: feldStil('Spitzname suchen …', symbol: Icon(Icons.search, size: 20, color: kMuted)),
      ),
      const SizedBox(height: 12),
      if (l == null)
        lead('Wird geladen …')
      else if (l.isEmpty)
        LeerKasten(kinder: [
          leerText(lt.suche.isNotEmpty
              ? 'Niemand mit „${lt.suche}“ im Spitznamen.'
              : 'Außer dir ist noch niemand dabei – lade andere aus deinem Kurs ein!'),
        ])
      else ...[
        Text(
          '${fmtN(lt.gesamt)} ${lt.gesamt == 1 ? 'Person' : 'Personen'} '
          '${lt.suche.isNotEmpty ? 'gefunden' : 'in der Rangliste'} · aktivste dieser Woche zuerst',
          style: TextStyle(fontSize: 12, color: kMuted),
        ),
        const SizedBox(height: 8),
        PersonenListe(l, art: 'kurz'),
        if (l.length < lt.gesamt) ...[
          const SizedBox(height: 10),
          Center(
            child: VgKnopf('Mehr anzeigen', onPressed: lt.laedt ? null : () => _d.leuteSuchen(mehr: true)),
          ),
        ],
      ],
    ];
  }

  List<Widget> _meinProfil() {
    final ich = _d.fstand?.ich;
    return [
      lead('Alle Teilnehmenden sehen deinen Spitznamen, deine Prüfungsreife, deine Antworten dieser Woche und '
          'deine Lerntage in Folge – wie in der Rangliste.'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Lernstand je Fach zeigen', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kInk)),
          Umschalter<String>(
            werte: const [('freunde', 'Nur Freunden'), ('alle', 'Allen Lernenden')],
            gewaehlt: ich?.sichtbarkeit ?? 'freunde',
            onWahl: _d.sichtbarkeitSetzen,
          ),
        ],
      ),
      const SizedBox(height: 10),
      hinweis([
        'Zum Lernstand je Fach gehören Prüfungsreife und gemeisterte Fragen je Fach, deine Aktivität der letzten '
            '14 Tage und Prüfungen unter Echtbedingungen. Admins der App können zur Betreuung und Moderation alle '
            'Angaben sehen.',
      ]),
      if (ich != null && ich.pid.isNotEmpty) ...[
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: VgKnopf('Mein Profil ansehen', onPressed: () => _d.profilAnsehen(pid: ich.pid)),
        ),
      ],
    ];
  }
}

/// Knöpfe je nach Beziehung (Web `ltAktionHTML`). art: 'kurz' (Liste),
/// 'lang' (Profil, gesendete Anfragen), 'ohne'.
List<Widget> freundKnoepfe(BuildContext context,
    {required String pid, required String name, required String? bez, required String art}) {
  if (art == 'ohne') return const [];
  final d = VergleichDienst.instance;
  final lang = art == 'lang';
  final aus = d.lt.laeuft.contains(pid);
  VoidCallback? los(String a) => aus ? null : () => d.freundAktion(a, pid, name);
  Widget status(String t, {bool ok = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ok ? kOkInk : kMuted)),
      );
  switch (bez) {
    case 'ich':
      return [status('Das bist du')];
    case 'freund':
      return [
        // „✓ Befreundet“ – der Haken als Symbol, er fehlt in den gebündelten Schriften.
        Semantics(
          label: 'Befreundet',
          excludeSemantics: true,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check, size: 15, color: kOkInk),
            status('Befreundet', ok: true),
          ]),
        ),
        if (lang)
          VgKnopf('Freundschaft beenden',
              art: KnopfArt.leise,
              onPressed: aus
                  ? null
                  : () async {
                      final ok = await bestaetigen(context,
                          titel: 'Freundschaft mit $name beenden?',
                          text: 'Ihr seht dann den Lernstand je Fach des anderen nicht mehr.',
                          ja: 'Freundschaft beenden');
                      if (ok) await d.freundAktion('entfernen', pid, name);
                    }),
      ];
    case 'angefragt':
      return [
        status('Angefragt'),
        if (lang) VgKnopf('Zurückziehen', art: KnopfArt.leise, onPressed: los('zurueck')),
      ];
    case 'anfrage':
      return [
        VgKnopf('Annehmen', art: KnopfArt.voll, onPressed: los('annehmen')),
        VgKnopf('Ablehnen', art: KnopfArt.leise, onPressed: los('ablehnen')),
      ];
    default:
      return [VgKnopf(lang ? 'Freundschaft anfragen' : 'Anfragen', onPressed: los('anfragen'))];
  }
}

/// Grobe Breite der Knöpfe – reicht der Platz nicht, rutschen sie unter den Namen.
double _knopfBreite(String? bez, String art) {
  if (art == 'ohne') return 0;
  final lang = art == 'lang';
  return switch (bez) {
    'ich' => 90,
    'freund' => lang ? 270 : 100,
    'angefragt' => lang ? 190 : 80,
    'anfrage' => 200,
    _ => lang ? 170 : 100,
  };
}

/// Personen als Liste (Web `.lt-liste`).
class PersonenListe extends StatelessWidget {
  final List<ProfilKarte> karten;
  final String art;
  const PersonenListe(this.karten, {super.key, required this.art});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: kLine)),
      child: Column(children: [
        for (var i = 0; i < karten.length; i++)
          Container(
            decoration: i == 0 ? null : BoxDecoration(border: Border(top: BorderSide(color: kLineSoft))),
            child: _PersonenZeile(k: karten[i], art: art),
          ),
      ]),
    );
  }
}

class _PersonenZeile extends StatelessWidget {
  final ProfilKarte k;
  final String art;
  const _PersonenZeile({required this.k, required this.art});

  @override
  Widget build(BuildContext context) {
    final d = VergleichDienst.instance;
    final person = Semantics(
      button: true,
      hint: 'Profil ansehen',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => d.profilAnsehen(pid: k.pid),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(children: [
            Kuerzel(k.name),
            const SizedBox(width: 11),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(k.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
                const SizedBox(height: 2),
                Text(zahlenText(k),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: kMuted)),
              ]),
            ),
          ]),
        ),
      ),
    );
    final knoepfe = freundKnoepfe(context, pid: k.pid, name: k.name, bez: k.bez, art: art);
    if (knoepfe.isEmpty) return Padding(padding: const EdgeInsets.all(4), child: person);
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth - _knopfBreite(k.bez, art) >= 210) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
          child: Row(children: [
            Expanded(child: person),
            for (final b in knoepfe) ...[const SizedBox(width: 4), b],
          ]),
        );
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          person,
          Padding(
            padding: const EdgeInsets.only(left: 57),
            child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, runSpacing: 4, children: knoepfe),
          ),
        ]),
      );
    });
  }
}

/// Profil einer Person (Web `ltProfilHTML`).
class ProfilAnsicht extends StatelessWidget {
  final VergleichDienst d;
  const ProfilAnsicht({super.key, required this.d});

  @override
  Widget build(BuildContext context) {
    final lt = d.lt;
    final p = lt.profil;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: d.profilSchliessen,
          style: TextButton.styleFrom(
            foregroundColor: kPetrolInk,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(0, 36),
            textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 13),
          ),
          child: const Text('‹ Zurück'),
        ),
      ),
      const SizedBox(height: 6),
      if (lt.meld.isNotEmpty) Rueckmeldung(lt.meld, ok: lt.meldOk),
      if (lt.profilLaedt)
        lead('Profil wird geladen …')
      else if (p == null || p.fehler)
        lead('Dieses Profil gibt es nicht mehr – vielleicht ist die Person ausgetreten oder hat ihren '
            'Spitznamen geändert.')
      else
        ..._profil(context, p),
    ]);
  }

  List<Widget> _profil(BuildContext context, Profil p) {
    final breit = MediaQuery.sizeOf(context).width > 560;
    final unter = [
      if (p.seit != null) 'dabei seit ${monatJahr(p.seit!)}',
      if (p.bez == 'ich') p.sichtbarkeit == 'alle' ? 'Lernstand für alle sichtbar' : 'Lernstand nur für Freunde sichtbar',
    ];
    final knoepfe = freundKnoepfe(context, pid: p.pid, name: p.name, bez: p.bez, art: 'lang');
    final titel = Row(children: [
      Kuerzel(p.name, groesse: 64),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name, style: dispStyle(24, height: 1.15)),
          if (unter.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(unter.join(' · '), style: TextStyle(fontSize: 12.5, height: 1.4, color: kMuted)),
          ],
        ]),
      ),
    ]);
    final kacheln = <Widget>[
      VgKpi(wert: '${p.reife} %', text: 'prüfungsreif', wertGroesse: 23),
      VgKpi(wert: fmtN(p.antworten), text: 'Antworten diese Woche', wertGroesse: 23),
      VgKpi(wert: fmtN(p.serie), text: 'Tage in Folge', wertGroesse: 23),
      if (p.sichtbar && p.gemeistert != null)
        VgKpi(wert: fmtN(p.gemeistert!), text: 'Fragen gemeistert', wertGroesse: 23),
      if (p.pruefN > 0) ...[
        VgKpi(wert: '${p.pruefOk}/${p.pruefN}', text: 'Prüfungen bestanden', wertGroesse: 23),
        VgKpi(wert: chanceText(p.chance), text: 'Bestehenschance', wertGroesse: 23),
      ],
    ];
    return [
      if (breit)
        Row(children: [
          Expanded(child: titel),
          for (final k in knoepfe) ...[const SizedBox(width: 6), k],
        ])
      else ...[
        titel,
        if (knoepfe.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, runSpacing: 4, children: knoepfe),
        ],
      ],
      const SizedBox(height: 16),
      KpiRaster(kacheln: kacheln, spalten: breit ? 4 : 2),
      const SizedBox(height: 18),
      if (p.adminSicht)
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: kPlumSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kPlumLine),
          ),
          child: Text('Als Admin siehst du auch den Lernstand, den ${p.name} nur Freunden zeigt.',
              style: TextStyle(fontSize: 12, height: 1.45, color: kPlumInk)),
        ),
      if (p.sichtbar)
        LernstandAnsicht(details: p.details, name: p.name, am: p.detailsAm)
      else
        _Schloss(p: p),
    ];
  }
}

/// Kasten mit Schloss, wenn der Lernstand je Fach nur für Freunde ist.
class _Schloss extends StatelessWidget {
  final Profil p;
  const _Schloss({required this.p});

  @override
  Widget build(BuildContext context) {
    final stil = TextStyle(fontSize: 13, height: 1.5, color: kInkSoft);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLine),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.lock_outline, size: 20, color: kMuted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Den Lernstand je Fach zeigt ${p.name} nur Freunden.', style: stil),
            const SizedBox(height: 8),
            Text(
              p.bez == 'angefragt'
                  ? 'Deine Anfrage ist unterwegs.'
                  : (p.bez == 'anfrage'
                      ? 'Nimm die Anfrage an, dann seht ihr ihn gegenseitig.'
                      : 'Schick eine Anfrage – befreundet seht ihr ihn gegenseitig.'),
              style: stil,
            ),
          ]),
        ),
      ]),
    );
  }
}
