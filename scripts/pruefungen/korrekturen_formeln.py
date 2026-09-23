# -*- coding: utf-8 -*-
"""Formeln, die ``layout_struktur.brueche`` nicht selbst linearisieren kann.

Word setzt verschachtelte Brüche (Einheitenbrüche im Zähler oder Nenner,
Wurzeln, Summenzeichen) so, dass ihre Teile im Textlayer über mehrere Zeilen
verstreut stehen. Diese Stellen sind hier aus den Originalseiten übertragen.

Schlüssel: Quelldatei relativ zu ``quellen/``, darin
``{Hauptzeile: (von, bis, 'linearer Text')}`` – die Zeilen von..bis
(1-basiert, einschließlich) werden durch den Text ersetzt. Die Hauptzeile ist
die mit dem Gleichheitszeichen des Bruchs.
"""

FORMELN = {}
