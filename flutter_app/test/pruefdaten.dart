import 'dart:convert';
import 'dart:io';

import 'package:kvm_trainer/models.dart';
import 'package:kvm_trainer/services/data_service.dart';

/// Prüfungsdaten für die Tests (FR-020). Die Original-IHK-Prüfungen stehen
/// nicht im Repository, sie kommen nur nach einer Freigabe aus Supabase. Die
/// Tests nutzen deshalb erfundene Beispielprüfungen mit dem Aufbau von sechs
/// Originalen (IDs, Aufgaben, Teile, Punkte, Tabellenformen):
/// `test/fixtures/pruefungen_beispiel.json`.
///
/// Liegt das private Paket daneben (`privat/hochladen/pruefungen.json`), laufen
/// zusätzlich die Prüfungen über alle Original-Prüfungen; sonst werden sie
/// übersprungen.

Map<String, dynamic> _lesen(File f) => json.decode(f.readAsStringSync()) as Map<String, dynamic>;

List<CaseStudy> _faelle(Map<String, dynamic> paket) => (paket['pruefungen'] as List<dynamic>)
    .map((e) => CaseStudy.fromJson(e as Map<String, dynamic>))
    .toList();

/// Das Paket mit den Beispielprüfungen im Format von pruefungen.json.
Map<String, dynamic> beispielPaket() => _lesen(File('test/fixtures/pruefungen_beispiel.json'));

/// Die Beispielprüfungen als Fälle.
List<CaseStudy> beispielPruefungen() => _faelle(beispielPaket());

/// Die gebündelten Fälle der App (ohne Prüfungen).
List<CaseStudy> gebuendelteFaelle() => (json.decode(File('assets/data/cases.json').readAsStringSync()) as List<dynamic>)
    .map((e) => CaseStudy.fromJson(e as Map<String, dynamic>))
    .toList();

/// Beispielprüfungen in den [DataService] setzen – nach `load()`, so wie die
/// App freigegebene Prüfungen nachträglich einsetzt.
void beispielEinsetzen() => DataService.instance.pruefungenEinsetzen(beispielPaket());

final File _privat = File('../privat/hochladen/pruefungen.json');

/// Gibt es das private Paket mit den Original-Prüfungen?
bool get mitPrivat => _privat.existsSync();

/// Grund zum Überspringen für Tests über alle Original-Prüfungen (für `skip:`).
String? get nurMitPrivat => mitPrivat ? null : 'nur mit dem privaten Prüfungspaket (privat/hochladen)';

/// Die Original-Prüfungen aus dem privaten Paket (nur mit [mitPrivat]).
List<CaseStudy> originalPruefungen() => _faelle(_lesen(_privat));
