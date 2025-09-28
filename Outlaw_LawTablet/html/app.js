const app = document.getElementById('app');
const docLayer = document.getElementById('doc');
const docFrame = document.getElementById('doc-frame');

const tabs = document.querySelectorAll('.tab');
const listTitle = document.getElementById('list-title');
const filterType = document.getElementById('filter-type');
const listEl = document.getElementById('list');

const btnClose = document.getElementById('btn-close');
const btnRefresh = document.getElementById('btn-refresh');
const btnCreate = document.getElementById('btn-create');
const btnPrint = document.getElementById('btn-print');
const btnVerify = document.getElementById('btn-verify');

const fTitle = document.getElementById('f-title');
const fType = document.getElementById('f-type');
const fStatus = document.getElementById('f-status');
const fTags = document.getElementById('f-tags');
const fBody = document.getElementById('f-body');
const fPrintId = document.getElementById('f-print-id');
const verifyInput = document.getElementById('verify-input');
const printResult = document.getElementById('print-result');

function postNui(action, data) {
  return new Promise((resolve) => {
    fetch(`https://${GetParentResourceName()}/${action}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data || {})
    }).then(r => r.json().catch(()=>({}))).then(resolve).catch(()=>resolve({ ok:false }));
  });
}

function switchTab(t) {
  tabs.forEach(btn => btn.classList.toggle('active', btn.dataset.tab === t));
  listTitle.textContent = t === 'complaint' ? 'Plainte' : t === 'trial' ? 'Procès' : 'Notes';
  filterType.value = t;
  refreshList();
}

function rowEl(item) {
  const div = document.createElement('div');
  div.className = 'row';
  div.innerHTML = `
    <div>
      <div class="title">\${item.title}</div>
      <div class="type">\${item.type} • \${item.status}</div>
    </div>
    <div class="id">#\${item.id}</div>`;
  return div;
}

async function refreshList() {
  const r = await postNui('list_notes', { type: filterType.value });
  listEl.innerHTML = '';
  if (!r.ok) { listEl.textContent = 'Erreur de chargement'; return; }
  r.items.forEach(it => listEl.appendChild(rowEl(it)));
}

async function createNote() {
  const payload = {
    title: fTitle.value,
    type: fType.value,
    status: fStatus.value,
    tags: fTags.value,
    body: fBody.value
  };
  const r = await postNui('create_note', payload);
  if (r.ok) {
    fTitle.value = ''; fBody.value = ''; fTags.value = '';
    fStatus.value = 'Brouillon';
    await refreshList();
  } else {
    alert('Erreur: création impossible (droits?)');
  }
}

async function printDoc() {
  const id = parseInt(fPrintId.value || '0', 10);
  if (!id || id < 1) { printResult.textContent = 'ID invalide'; return; }
  const r = await postNui('print_document', { note_id: id });
  if (r.ok) {
    printResult.textContent = 'Imprimé! Code: ' + (r.code || 'N/A') + ' • Item: ' + (r.item || '?');
  } else {
    printResult.textContent = 'Erreur impression: ' + (r.error || 'inconnue');
  }
}

async function verifyCode() {
  const code = (verifyInput.value || '').trim().toUpperCase();
  if (!code) return;
  const r = await postNui('verify_code', { code });
  if (!r.ok) { alert('Non valide: ' + (r.status || 'inconnu')); return; }
  alert('Document VALIDE (hash: ' + r.hash + ')');
}

// NUI open/close
window.addEventListener('message', (e) => {
  const d = e.data || {};
  if (d.action === 'open') {
    app.classList.remove('hidden');
    switchTab('complaint');
  } else if (d.action === 'openDocument') {
    app.classList.add('hidden');
    openDocument(d.meta);
  }
});

function openDocument(meta) {
  docLayer.classList.remove('hidden');
  // Build sandboxed HTML for viewing the stored snapshot
  const html = meta && meta.body_html ? meta.body_html : '<p>Document vide</p>';
  const blob = new Blob([html], { type: 'text/html' });
  const url = URL.createObjectURL(blob);
  docFrame.src = url;
}

document.getElementById('doc-close').addEventListener('click', () => {
  docLayer.classList.add('hidden');
  app.classList.remove('hidden');
});

btnClose.addEventListener('click', () => postNui('close', {}).then(()=>{}));
btnRefresh.addEventListener('click', refreshList);
btnCreate.addEventListener('click', createNote);
btnPrint.addEventListener('click', printDoc);
btnVerify.addEventListener('click', verifyCode);

tabs.forEach(btn => btn.addEventListener('click', () => switchTab(btn.dataset.tab)));
filterType.addEventListener('change', refreshList);
