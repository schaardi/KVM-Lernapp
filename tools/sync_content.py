#!/usr/bin/env python3
"""Sync den Fragenkatalog der App aus dem Content-Repo/-Branch.

Quelle der Wahrheit ist die Web-App ``index.html``. Dort liegen die Inhalte als
JSON-fähige Globals im ``<script>``-Block:

    window.KVM_QUESTIONS = [ ... ];   # Fragen
    window.KVM_CASES     = [ ... ];   # Fallaufgaben

Dieses Skript liest diese beiden Blöcke, prüft sie und schreibt sie kompakt nach
``flutter_app/assets/data/questions.json`` bzw. ``cases.json`` – also genau in das
Format, das die Flutter-App bündelt und offline lädt.

Beispiele:
    # aus dem Content-Branch (Standard) syncen und schreiben:
    python tools/sync_content.py

    # aus einer lokalen index.html syncen:
    python tools/sync_content.py --source index.html

    # nur prüfen, ob die App aktuell ist (CI/Drift-Check, schreibt nichts):
    python tools/sync_content.py --check

Exit-Codes:
    0  erfolgreich (bzw. --check: App ist aktuell)
    1  Inhalt ungültig / Extraktion fehlgeschlagen
    2  --check: App weicht vom Content ab (Sync nötig)
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

# Standard-Content-Quelle: Branch der Content-Session (Web-App / index.html).
DEFAULT_REF = "origin/claude/focused-meitner-ilnlqj"
DEFAULT_SOURCE_IN_REF = "index.html"

REPO_ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = REPO_ROOT / "flutter_app" / "assets" / "data"
QUESTIONS_OUT = ASSET_DIR / "questions.json"
CASES_OUT = ASSET_DIR / "cases.json"
# Seit die Web-App ihre Inhalte aus data/*.js lädt (nicht mehr inline aus
# index.html), ist sie ein zweites Ziel dieses Syncs. Ohne das blieb sie auf dem
# Stand des letzten Umbaus stehen: 157 Fragen fehlten, und bei 416 weiteren
# fehlten die Erklärungen zu den falschen Antworten.
sys.path.insert(0, str(REPO_ROOT / "tools"))
import webdaten as W          # noqa: E402  – Pfad muss vorher stehen

WEB_QUESTIONS = Path(W.pfad("KVM_QUESTIONS"))
WEB_CASES = Path(W.pfad("KVM_CASES"))

VALID_TYPES = {"mc", "calc", "open"}


# --------------------------------------------------------------------------- #
# Extraktion                                                                   #
# --------------------------------------------------------------------------- #
def _aufgabenblatt(case: dict) -> dict:
    """Fall in das Aufgabenblatt-Format bringen (idempotent)."""
    sys.path.insert(0, str(REPO_ROOT / "scripts" / "pruefungen"))
    try:
        import aufgaben_modell  # noqa: PLC0415 – nur hier gebraucht
    except ImportError:
        return case
    return aufgaben_modell.zerlegen(case)


def _aus_datendatei(name: str) -> list | None:
    """Datensatz aus ``data/<name>.js`` lesen, falls vorhanden."""
    sys.path.insert(0, str(REPO_ROOT / "tools"))
    try:
        import webdaten  # noqa: PLC0415 – nur im Fallback gebraucht
    except ImportError:
        return None
    pfad = Path(webdaten.pfad(name))
    if not pfad.exists():
        return None
    daten = webdaten.aus_text(pfad.read_text(encoding="utf-8"), name)
    return daten if isinstance(daten, list) else None


def _extract_global(html: str, name: str) -> list:
    """Zieht ``window.<name> = [ ... ];`` als JSON aus dem HTML.

    Jeder Global liegt in einem eigenen ``<script>``-Block; wir schneiden vom
    ``= `` bis zum schließenden ``</script>`` und parsen den Array-Ausdruck.
    """
    pattern = re.compile(
        r"window\.%s\s*=\s*(\[.*?\])\s*;?\s*</script>" % re.escape(name),
        re.DOTALL,
    )
    m = pattern.search(html)
    if not m:
        # Diese App lädt ihre Inhalte aus data/*.js statt aus index.html. Steht
        # der Global nicht im HTML, wird die Datei daneben gelesen – so bleibt
        # `--source index.html` auch für den eigenen Branch benutzbar.
        daten = _aus_datendatei(name)
        if daten is not None:
            return daten
        raise ValueError(
            f"window.{name} nicht in der Quelle gefunden. "
            f"Erwartet: `window.{name} = [...];` in einem eigenen <script>-Block "
            f"oder die Datei data/*.js daneben."
        )
    raw = m.group(1)
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        # Hilfreiche Fehlermeldung mit Kontext um die Fundstelle.
        pos = exc.pos
        ctx = raw[max(0, pos - 80): pos + 80]
        raise ValueError(
            f"window.{name} ist kein gültiges JSON ({exc.msg} @ {pos}). "
            f"Kontext: …{ctx}…"
        ) from exc
    if not isinstance(data, list):
        raise ValueError(f"window.{name} ist kein JSON-Array.")
    return data


def read_source(source: str | None, ref: str | None) -> str:
    """Liest die index.html – entweder aus einer Datei oder aus einem Git-Ref."""
    if source:
        p = Path(source)
        if not p.is_absolute():
            p = (Path.cwd() / p).resolve()
        if not p.exists():
            raise FileNotFoundError(f"Quelldatei nicht gefunden: {p}")
        return p.read_text(encoding="utf-8")

    gitref = ref or DEFAULT_REF
    try:
        out = subprocess.run(
            ["git", "show", f"{gitref}:{DEFAULT_SOURCE_IN_REF}"],
            cwd=REPO_ROOT,
            check=True,
            capture_output=True,
        )
    except subprocess.CalledProcessError as exc:
        stderr = exc.stderr.decode("utf-8", "replace").strip()
        raise SystemExit(
            f"Konnte {DEFAULT_SOURCE_IN_REF} aus '{gitref}' nicht lesen.\n"
            f"git: {stderr}\n"
            f"Tipp: erst `git fetch origin <content-branch>` ausführen."
        ) from exc
    return out.stdout.decode("utf-8")


# --------------------------------------------------------------------------- #
# Validierung (Datenvertrag)                                                   #
# --------------------------------------------------------------------------- #
def _correct_options(q: dict) -> int:
    return sum(1 for o in q.get("o", []) if o.get("ok") in (1, True))


def validate_questions(questions: list) -> list[str]:
    errors: list[str] = []
    seen: set[str] = set()
    for i, q in enumerate(questions):
        loc = q.get("id") or f"index {i}"
        if not q.get("id"):
            errors.append(f"Frage {loc}: fehlende id")
        elif q["id"] in seen:
            errors.append(f"Frage {loc}: doppelte id")
        else:
            seen.add(q["id"])
        if not isinstance(q.get("f"), int):
            errors.append(f"Frage {loc}: 'f' (Fach) fehlt/ist keine Ganzzahl")
        if not q.get("sub"):
            errors.append(f"Frage {loc}: fehlender Themenbereich 'sub'")
        if not q.get("q"):
            errors.append(f"Frage {loc}: fehlender Fragetext 'q'")
        t = q.get("t")
        if t not in VALID_TYPES:
            errors.append(f"Frage {loc}: unbekannter Typ '{t}' (erlaubt: {sorted(VALID_TYPES)})")
        if t == "mc":
            n = _correct_options(q)
            if not q.get("o"):
                errors.append(f"Frage {loc}: mc ohne Optionen 'o'")
            elif n != 1:
                errors.append(f"Frage {loc}: mc mit {n} richtigen Optionen (genau 1 erwartet)")
        if t == "calc" and not isinstance(q.get("ans"), (int, float)):
            errors.append(f"Frage {loc}: calc ohne numerisches Ergebnis 'ans'")
    return errors


def validate_cases(cases: list) -> list[str]:
    errors: list[str] = []
    seen: set[str] = set()
    for i, c in enumerate(cases):
        loc = c.get("id") or f"index {i}"
        if not c.get("id"):
            errors.append(f"Fall {loc}: fehlende id")
        elif c["id"] in seen:
            errors.append(f"Fall {loc}: doppelte id")
        else:
            seen.add(c["id"])
        if not c.get("title"):
            errors.append(f"Fall {loc}: fehlender Titel")
        steps = c.get("steps")
        if not isinstance(steps, list) or not steps:
            errors.append(f"Fall {loc}: keine Schritte 'steps'")
        else:
            errors.extend(f"Fall {loc} / {e}" for e in validate_questions(steps))
            errors.extend(f"Fall {loc}: {e}" for e in _validate_aufgaben(c, steps))
    return errors


def _validate_aufgaben(case: dict, steps: list) -> list[str]:
    """Aufgabenblatt-Format: Teile zeigen auf eine Aufgabe, Punkte gehen auf."""
    errors: list[str] = []
    aufgaben = case.get("aufgaben")
    if not isinstance(aufgaben, list) or not aufgaben:
        return [f"keine Aufgaben 'aufgaben' (Aufgabenblatt-Format fehlt)"]
    nach_nr: dict[int, dict] = {}
    for a in aufgaben:
        nr = a.get("nr")
        if not isinstance(nr, int):
            errors.append("Aufgabe ohne ganzzahlige 'nr'")
            continue
        if nr in nach_nr:
            errors.append(f"Aufgabe {nr} doppelt")
        nach_nr[nr] = a
    summen: dict[int, int] = {}
    for s in steps:
        sid = s.get("id", "?")
        nr, teil, pts = s.get("nr"), s.get("teil"), s.get("pts")
        if not isinstance(nr, int) or nr not in nach_nr:
            errors.append(f"{sid}: verweist auf keine Aufgabe ('nr')")
            continue
        if not isinstance(teil, str) or not teil:
            errors.append(f"{sid}: fehlendes Teil-Label 'teil'")
        if not isinstance(pts, int) or pts < 0:
            errors.append(f"{sid}: 'pts' fehlt oder ist negativ")
            continue
        summen[nr] = summen.get(nr, 0) + pts
        labels = {t.get("teil") for t in steps if t.get("nr") == nr}
        for b in s.get("braucht", []):
            if b not in labels:
                errors.append(f"{sid}: 'braucht' verweist auf {b}), das es in Aufgabe {nr} nicht gibt")
    for nr, a in nach_nr.items():
        if a.get("pts") != summen.get(nr, 0):
            errors.append(f"Aufgabe {nr}: Punkte {a.get('pts')} != Summe der Teile {summen.get(nr, 0)}")
    if str(case.get("id", "")).startswith("P-") and sum(summen.values()) != 100:
        errors.append(f"Prüfung hat {sum(summen.values())} statt 100 Punkte")
    return errors


# --------------------------------------------------------------------------- #
# Eigenständige Inhalte der App bewahren                                       #
# --------------------------------------------------------------------------- #
# Die IHK-Prüfungen (Fall-IDs mit Präfix "P-") entstehen nicht im Content-Branch,
# sondern in diesem Repo aus den Original-PDFs (scripts/pruefungen/). Ein reiner
# Overwrite-Sync aus dem Content würde sie jedes Mal löschen – genau das ist
# schon passiert. Sie werden deshalb aus den vorhandenen App-Assets übernommen,
# sofern der Content sie nicht selbst mitbringt.
EIGEN_PRAEFIX = "P-"


def preserve_local_cases(cases: list, current) -> tuple[list, list]:
    """Hängt lokale Prüfungsfälle an, die der Content nicht kennt.

    Gibt die ergänzte Liste und die Liste der bewahrten IDs zurück.
    """
    if not isinstance(current, list):
        return cases, []
    vorhanden = _ids(cases)
    bewahrt = [
        c for c in current
        if isinstance(c, dict)
        and str(c.get("id", "")).startswith(EIGEN_PRAEFIX)
        and c.get("id") not in vorhanden
    ]
    return cases + bewahrt, [c["id"] for c in bewahrt]


# Aus den Original-Prüfungen abgeleitete Übungsfragen tragen das Präfix "PX-".
# Sie entstehen in diesem Repo (scripts/pruefungen/build_exam_questions.py),
# nicht im Content-Branch, und würden von einem reinen Overwrite-Sync sonst
# verlorengehen – daher werden sie wie die Prüfungsfälle bewahrt.
EIGEN_FRAGEN_PRAEFIX = "PX-"


def preserve_local_questions(questions: list, current) -> tuple[list, list]:
    """Hängt lokale Übungsfragen (Präfix ``PX-``) an, die der Content nicht kennt."""
    if not isinstance(current, list):
        return questions, []
    vorhanden = _ids(questions)
    bewahrt = [
        x for x in current
        if isinstance(x, dict)
        and str(x.get("id", "")).startswith(EIGEN_FRAGEN_PRAEFIX)
        and x.get("id") not in vorhanden
    ]
    return questions + bewahrt, [x["id"] for x in bewahrt]


# --------------------------------------------------------------------------- #
# Schreiben                                                                    #
# --------------------------------------------------------------------------- #
def dump_compact(data) -> str:
    """Kompaktes JSON – exakt das Format der gebündelten Assets."""
    return json.dumps(data, ensure_ascii=False, separators=(",", ":"))


def _current(path: Path):
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return None


def _ids(items) -> set[str]:
    return {x.get("id") for x in (items or []) if isinstance(x, dict)}


def summarize(label: str, new: list, old) -> str:
    if old is None:
        return f"{label}: {len(new)} (neu angelegt)"
    old_ids, new_ids = _ids(old), _ids(new)
    added = len(new_ids - old_ids)
    removed = len(old_ids - new_ids)
    return (
        f"{label}: {len(old)} -> {len(new)} "
        f"(+{added} / -{removed})"
    )


def _validate_assets_only() -> int:
    """Prüft die bereits gebündelten App-Assets gegen den Datenvertrag."""
    q = _current(QUESTIONS_OUT)
    c = _current(CASES_OUT)
    if q is None:
        print(f"FEHLER: {QUESTIONS_OUT} fehlt oder ist kein gültiges JSON.", file=sys.stderr)
        return 1
    if c is None:
        print(f"FEHLER: {CASES_OUT} fehlt oder ist kein gültiges JSON.", file=sys.stderr)
        return 1
    errors = validate_questions(q) + validate_cases(c)
    if errors:
        print(f"FEHLER: {len(errors)} Validierungsprobleme in den App-Assets:", file=sys.stderr)
        for e in errors[:40]:
            print(f"  - {e}", file=sys.stderr)
        if len(errors) > 40:
            print(f"  … und {len(errors) - 40} weitere", file=sys.stderr)
        return 1
    print(f"OK: {len(q)} Fragen & {len(c)} Fälle gültig (Datenvertrag erfüllt).")
    return 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Fragenkatalog aus dem Content (index.html) in die App syncen.")
    src = ap.add_mutually_exclusive_group()
    src.add_argument("--source", help="Pfad zu einer index.html (statt Git-Ref).")
    src.add_argument("--ref", help=f"Git-Ref des Content-Branches (Standard: {DEFAULT_REF}).")
    ap.add_argument("--check", action="store_true",
                    help="Nur prüfen, ob die App aktuell ist; nichts schreiben. Exit 2 bei Abweichung.")
    ap.add_argument("--validate-assets", action="store_true",
                    help="Nur die gebündelten App-Assets gegen den Datenvertrag prüfen (ohne Content-Quelle).")
    args = ap.parse_args(argv)

    if args.validate_assets:
        return _validate_assets_only()

    html = read_source(args.source, args.ref)

    try:
        questions = _extract_global(html, "KVM_QUESTIONS")
        cases = _extract_global(html, "KVM_CASES")
    except ValueError as exc:
        print(f"FEHLER: {exc}", file=sys.stderr)
        return 1

    # Der Content-Branch liefert die Fälle noch im alten Format (Aufgabenkopf
    # und Ausgangslage im Fragetext). Hier werden sie in das Aufgabenblatt-
    # Format überführt, sonst schreibt der nächtliche Sync den Umbau zurück.
    cases = [_aufgabenblatt(c) for c in cases]
    cases, bewahrt = preserve_local_cases(cases, _current(CASES_OUT))
    if bewahrt:
        print(f"Bewahrt (Fälle, nicht im Content): {', '.join(bewahrt)}")
    questions, bewahrt_q = preserve_local_questions(questions, _current(QUESTIONS_OUT))
    if bewahrt_q:
        print(f"Bewahrt (Übungsfragen aus Prüfungen, {len(bewahrt_q)} Stück, Präfix PX-)")

    errors = validate_questions(questions) + validate_cases(cases)
    if errors:
        print(f"FEHLER: {len(errors)} Validierungsprobleme im Content:", file=sys.stderr)
        for e in errors[:40]:
            print(f"  - {e}", file=sys.stderr)
        if len(errors) > 40:
            print(f"  … und {len(errors) - 40} weitere", file=sys.stderr)
        return 1

    q_new, c_new = dump_compact(questions), dump_compact(cases)
    q_old_txt = QUESTIONS_OUT.read_text(encoding="utf-8") if QUESTIONS_OUT.exists() else None
    c_old_txt = CASES_OUT.read_text(encoding="utf-8") if CASES_OUT.exists() else None
    qw_new, cw_new = W.als_datei("KVM_QUESTIONS", questions), W.als_datei("KVM_CASES", cases)
    qw_old = WEB_QUESTIONS.read_text(encoding="utf-8") if WEB_QUESTIONS.exists() else None
    cw_old = WEB_CASES.read_text(encoding="utf-8") if WEB_CASES.exists() else None

    print(summarize("Fragen", questions, _current(QUESTIONS_OUT)))
    print(summarize("Fälle ", cases, _current(CASES_OUT)))

    up_to_date = (q_new == q_old_txt and c_new == c_old_txt
                  and qw_new == qw_old and cw_new == cw_old)

    if args.check:
        if up_to_date:
            print("OK: App- und Web-Daten sind auf dem Stand des Contents.")
            return 0
        wo = []
        if q_new != q_old_txt or c_new != c_old_txt:
            wo.append("App-Assets")
        if qw_new != qw_old or cw_new != cw_old:
            wo.append("Web-Daten (data/*.js)")
        print("ABWEICHUNG: %s weichen vom Content ab – `python tools/sync_content.py` ausführen."
              % " und ".join(wo), file=sys.stderr)
        return 2

    if up_to_date:
        print("Nichts zu tun: bereits synchron.")
        return 0

    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    QUESTIONS_OUT.write_text(q_new, encoding="utf-8")
    CASES_OUT.write_text(c_new, encoding="utf-8")
    WEB_QUESTIONS.write_text(qw_new, encoding="utf-8")
    WEB_CASES.write_text(cw_new, encoding="utf-8")
    print("Geschrieben: %s & %s (App) · %s & %s (Web)"
          % (QUESTIONS_OUT.relative_to(REPO_ROOT), CASES_OUT.relative_to(REPO_ROOT),
             WEB_QUESTIONS.relative_to(REPO_ROOT), WEB_CASES.relative_to(REPO_ROOT)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
