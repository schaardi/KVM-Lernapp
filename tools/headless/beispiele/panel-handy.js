// Handy (CDP_GROESSE=390,844): dieselbe Aufgabe, Formelbuch als Bottom-Sheet.
// Oberhalb des Werkzeugs muss Aufgabentext sichtbar bleiben, die Seite darf
// nicht seitlich scrollen, die Werkzeugleiste darf nicht auf dem Sheet liegen.
(async () => {
  const warte = ms => new Promise(r => setTimeout(r, ms));
  window.KVM_startCase('P-BW-20201103'); await warte(500);
  [...document.querySelectorAll('#blStepper .bl-pill')].find(x => x.textContent.trim().startsWith('5')).click();
  await warte(300);
  document.getElementById('tbFormula').click(); await warte(350);
  const sheet = document.querySelector('#mFormula>.sheet').getBoundingClientRect();
  const tool = document.getElementById('toolbar');
  const toolSichtbar = tool && getComputedStyle(tool).display !== 'none';
  return {
    fenster: [innerWidth, innerHeight],
    sheet_oben: sheet.top, sheet_hoehe: sheet.height,
    anteil_sheet: Math.round(sheet.height / innerHeight * 100) + ' %',
    aufgabe_sichtbar_px: Math.max(0, sheet.top),
    toolbar_sichtbar: toolSichtbar,
    toolbar_auf_sheet: toolSichtbar && tool.getBoundingClientRect().bottom > sheet.top,
    seite_scrollt_horizontal: document.documentElement.scrollWidth > innerWidth,
  };
})()
