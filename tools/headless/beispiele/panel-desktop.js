// Desktop (1280×900): Formelbuch öffnen, während Aufgabe 5 der BW-Prüfung
// H2020 (Betriebsabrechnungsbogen) auf dem Aufgabenblatt liegt. Die Aufgabe
// muss neben dem Werkzeug lesbar bleiben, nichts darf sich überlappen.
(async () => {
  const warte = ms => new Promise(r => setTimeout(r, ms));
  window.KVM_startCase('P-BW-20201103'); await warte(500);
  [...document.querySelectorAll('#blStepper .bl-pill')].find(x => x.textContent.trim().startsWith('5')).click();
  await warte(300);
  document.getElementById('tbFormula').click(); await warte(350);
  const sheet = document.querySelector('#mFormula>.sheet');
  const tool = document.getElementById('toolbar');
  const app = document.querySelector('.app');
  const koerper = document.querySelector('#mFormula .sheet-body').getBoundingClientRect();
  const karten = [...document.querySelectorAll('#mFormula .ks, #mFormula .fb-item')];
  return {
    fenster: [innerWidth, innerHeight],
    body_klasse: document.body.className,
    app: [app.getBoundingClientRect().left, app.getBoundingClientRect().right],
    panel_links: sheet.getBoundingClientRect().left,
    panel_breite: sheet.offsetWidth,
    app_ueberlappt_panel: app.getBoundingClientRect().right > sheet.getBoundingClientRect().left,
    toolbar_ueberlappt_panel: tool.getBoundingClientRect().right > sheet.getBoundingClientRect().left,
    karten_abgeschnitten: karten.filter(k => k.getBoundingClientRect().right > koerper.right + 1).length,
    seite_scrollt_horizontal: document.documentElement.scrollWidth > innerWidth,
  };
})()
