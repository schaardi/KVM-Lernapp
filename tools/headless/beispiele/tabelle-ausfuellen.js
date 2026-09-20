// Ausfüllbare Tabellenanlage: Eingabe landet in localStorage (kvm_open_tabs)
// und die Teilaufgabe gilt als beantwortet. Aufgabe 5 der BW-Prüfung H2020.
(async () => {
  const warte = ms => new Promise(r => setTimeout(r, ms));
  localStorage.removeItem('kvm_open_tabs');
  window.KVM_startCase('P-BW-20201103'); await warte(500);
  [...document.querySelectorAll('#blStepper .bl-pill')].find(x => x.textContent.trim().startsWith('5')).click();
  await warte(300);
  const felder = [...document.querySelectorAll('#scrBlatt input.qtab-in')];
  if (felder.length) { felder[0].value = '1234'; felder[0].dispatchEvent(new Event('input', { bubbles: true })); }
  await warte(200);
  const gespeichert = JSON.parse(localStorage.getItem('kvm_open_tabs') || '{}');
  return {
    eingabefelder: felder.length,
    schluessel: Object.keys(gespeichert),
    werte: Object.values(gespeichert).map(t => Object.values(t)).flat().slice(0, 3),
  };
})()
