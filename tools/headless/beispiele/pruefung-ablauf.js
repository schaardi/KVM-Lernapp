// Heutiger Prüfungsablauf einmal durchgespielt: Übersicht öffnen, Prüfung
// starten, eine Teilaufgabe beantworten, aufdecken, Punkte vergeben, zum
// Ergebnis springen. Dient als Referenz vor dem Umbau des Prüfungsmodus.
(async () => {
  const warte = ms => new Promise(r => setTimeout(r, ms));
  ['kvm_open_answers', 'kvm_open_points', 'kvm_open_tabs'].forEach(k => localStorage.removeItem(k));
  document.getElementById('btnPruef').click(); await warte(300);
  const startKnopf = document.querySelector('#pruefList [data-start="P-BW-20201103"]');
  const meta = startKnopf.closest('.pr-item').querySelector('.pr-meta');
  const metaText = meta ? meta.textContent : '';
  startKnopf.click(); await warte(500);
  const timerSichtbar = !document.getElementById('qTimer').hidden;
  const erstes = document.querySelector('#scrBlatt textarea[data-antwort]');
  erstes.value = 'Testantwort'; erstes.dispatchEvent(new Event('input', { bubbles: true })); await warte(150);
  const aufdecken = document.querySelectorAll('#scrBlatt .bl-reveal').length;
  document.querySelector('#scrBlatt .bl-reveal').click(); await warte(200);
  const punkte = [...document.querySelectorAll('#scrBlatt .oas-p')];
  punkte[punkte.length - 1].click(); await warte(150);
  const pills = [...document.querySelectorAll('#blStepper .bl-pill')];
  pills[pills.length - 1].click(); await warte(200);
  const next = document.getElementById('blNext');
  const nextText = next.textContent;
  next.click(); await warte(400);
  return {
    picker_meta: metaText.trim(),
    picker_zeigt_180: /180 Minuten/.test(metaText),
    timer_bei_pruefung: timerSichtbar,
    aufdeck_knoepfe_vor_abgabe: aufdecken,
    punkte_knoepfe: punkte.length,
    letzter_knopf: nextText.trim(),
    ergebnis_sichtbar: !document.getElementById('scrResult').hidden,
    ergebnis_zeile: document.getElementById('resLine').textContent.trim(),
    ergebnis_badge: document.getElementById('resBadge').textContent.trim(),
    aufgaben_im_ergebnis: document.querySelectorAll('#taskList .tl-row').length,
    versuch_gespeichert: Object.keys(localStorage).filter(k => /versuch|attempt|verlauf/i.test(k)),
    antworten_bleiben: Object.keys(JSON.parse(localStorage.getItem('kvm_open_answers') || '{}')),
  };
})()
