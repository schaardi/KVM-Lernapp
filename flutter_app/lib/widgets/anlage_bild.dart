import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../models.dart';
import '../services/data_service.dart';

/// Bildanlage einer Prüfungsaufgabe (Abbildung, Skizze, Typenschild).
///
/// Die Bilder liegen als Dateien im Asset-Bündel; [ref] ist ihr Schlüssel in
/// `anlagen.json`. Angetippt öffnet sich das Bild als Vollbild mit Zoom –
/// ein Motortypenschild oder ein Schaltplan ist auf Handybreite sonst nicht
/// zu entziffern.
class AnlageBild extends StatelessWidget {
  final String? ref;
  final String fallbackTitel;

  const AnlageBild(this.ref, {super.key, this.fallbackTitel = 'Anlage zur Aufgabe'});

  @override
  Widget build(BuildContext context) {
    final a = DataService.instance.anlage(ref);
    if (a == null) return const SizedBox.shrink();
    final bild = _bildWidget(a);
    if (bild == null) return const SizedBox.shrink();
    final titel = a.titel.isNotEmpty ? a.titel : fallbackTitel;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
          image: true,
          label: titel,
          button: true,
          child: InkWell(
            onTap: () => _oeffnen(context, bild, titel),
            borderRadius: BorderRadius.circular(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                    color: kPaper,
                    border: Border.all(color: kLine),
                    borderRadius: BorderRadius.circular(10)),
                child: bild,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(
            child: Text(titel,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, height: 1.4, color: kMuted)),
          ),
          const SizedBox(width: 5),
          Icon(Icons.zoom_in, size: 13, color: kMuted),
        ]),
      ]),
    );
  }

  /// Bild aus dem Asset-Bündel – oder, bei Alt-Einträgen, aus der Data-URI.
  Widget? _bildWidget(Anlagenbild a) {
    if (a.datei.isNotEmpty) {
      return Image.asset(a.asset, fit: BoxFit.fitWidth, width: double.infinity);
    }
    final komma = a.uri.indexOf(',');
    if (!a.uri.startsWith('data:') || komma < 0) return null;
    try {
      return Image.memory(base64Decode(a.uri.substring(komma + 1)),
          fit: BoxFit.fitWidth, width: double.infinity);
    } catch (_) {
      return null;
    }
  }

  void _oeffnen(BuildContext context, Widget bild, String titel) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (_, __, ___) => _Vollbild(bild: bild, titel: titel),
    ));
  }
}

class _Vollbild extends StatelessWidget {
  final Widget bild;
  final String titel;
  const _Vollbild({required this.bild, required this.titel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(children: [
          // Tippen neben das Bild schließt – wie eine Lightbox.
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 6,
              child: Center(child: bild),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Text(titel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5, height: 1.4, color: Colors.white)),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Schließen',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ]),
      ),
    );
  }
}
