const app = document.getElementById('app');
const docLayer = document.getElementById('doc');
const docFrame = document.getElementById('doc-frame');
const docTitleEl = document.getElementById('doc-title');
const docSubtitleEl = document.getElementById('doc-subtitle');
let lastDocUrl = null;
let appWasVisibleBeforeDoc = false;

const tabs = document.querySelectorAll('.tab');
const listTitle = document.getElementById('list-title');
const filterType = document.getElementById('filter-type');
const listEl = document.getElementById('list');

const TYPE_LABELS = {
  complaint: 'Plainte',
  trial: 'Procès',
  note: 'Note',
  other: 'Autre'
};

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

function escapeHtml(str) {
  return String(str == null ? '' : str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function cleanText(value) {
  if (value == null) return '';
  const text = String(value).trim();
  return text;
}

function docSubtitle(meta) {
  if (!meta || typeof meta !== 'object') return '';
  const parts = [];
  const typeKey = meta.type || (meta.source && meta.source.type) || '';
  const type = cleanText(meta.type_label || (typeKey && TYPE_LABELS[typeKey]) || typeKey);
  if (type) parts.push(type);
  const noteId = cleanText(
    (meta.note_id != null ? `#${meta.note_id}` : '') ||
    (meta.source && meta.source.note_id != null ? `#${meta.source.note_id}` : '')
  );
  if (noteId) parts.push(noteId);
  const status = cleanText(meta.status);
  if (status) parts.push(status);
  const printedAt = cleanText(meta.printed_at || meta.created_at || meta.updated_at);
  if (printedAt) parts.push(printedAt);
  const author = cleanText(meta.author || meta.author_charname || (meta.printed_by && (meta.printed_by.charname || meta.printed_by.name)));
  if (author) parts.push(author);
  const tags = cleanText(meta.tags);
  if (tags) parts.push(tags);
  return parts.join(' • ');
}

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
  if ([...fType.options].some(opt => opt.value === t)) {
    fType.value = t;
  }
  refreshList();
}

function rowEl(item) {
  const div = document.createElement('div');
  div.className = 'row clickable';
  const rawTitle = typeof item.title === 'string' && item.title.trim() !== '' ? item.title : 'Sans titre';
  const rawType = TYPE_LABELS[item.type] || item.type || 'Note';
  const rawStatus = item.status || '';
  const idText = item.id != null ? String(item.id) : '?';
  div.innerHTML = `
    <div>
      <div class="title">${escapeHtml(rawTitle)}</div>
      <div class="type">${escapeHtml(rawType)} • ${escapeHtml(rawStatus)}</div>
    </div>
    <div class="id">#${escapeHtml(idText)}</div>`;
  div.addEventListener('click', () => openNote(Number(item.id)));
  div.tabIndex = 0;
  div.addEventListener('keydown', (ev) => {
    if (ev.key === 'Enter' || ev.key === ' ') {
      ev.preventDefault();
      openNote(Number(item.id));
    }
  });
  return div;
}

async function refreshList() {
  const r = await postNui('list_notes', { type: filterType.value });
  listEl.innerHTML = '';
  if (!r.ok) { listEl.textContent = 'Erreur de chargement'; return; }
  if (!Array.isArray(r.items) || r.items.length === 0) {
    const empty = document.createElement('div');
    empty.className = 'empty';
    empty.textContent = 'Aucun document';
    listEl.appendChild(empty);
    return;
  }
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

async function openNote(id) {
  if (!id || Number.isNaN(id)) return;
  const r = await postNui('get_note', { id });
  if (!r.ok || !r.item) {
    alert('Impossible d\'ouvrir la note (introuvable)');
    return;
  }
  const note = r.item;
  const typeLabel = TYPE_LABELS[note.type] || note.type || 'Note';
  const title = escapeHtml(note.title && note.title.trim() !== '' ? note.title : 'Sans titre');
  const status = escapeHtml(note.status || '');
  const tags = escapeHtml(note.tags || '');
  const author = escapeHtml(note.author_charname || 'Inconnu');
  const createdAt = escapeHtml(note.created_at || '');
  const body = escapeHtml(note.body || '');
  const html = `
    <style>
      body { font-family: Arial, sans-serif; background:#0b0f1a; color:#eaefff; margin:0; padding:24px; }
      .doc { max-width:860px; margin:0 auto; background:rgba(20,24,36,.92); border-radius:16px; border:1px solid rgba(255,255,255,.12); padding:24px 28px; }
      .meta { font-size:13px; opacity:.8; margin-bottom:12px; display:flex; flex-direction:column; gap:4px; }
      .meta span { display:block; }
      h1 { margin:0 0 12px 0; font-size:24px; }
      .body { line-height:1.6; white-space:pre-wrap; background:rgba(255,255,255,.04); padding:16px; border-radius:12px; }
      .tags { margin-top:12px; font-size:12px; opacity:.75; }
    </style>
    <div class="doc">
      <h1>${title}</h1>
      <div class="meta">
        <span>Type: ${escapeHtml(typeLabel)}</span>
        <span>Statut: ${status}</span>
        <span>Auteur: ${author}</span>
        <span>Créé le: ${createdAt}</span>
      </div>
      <div class="body">${body.trim() !== '' ? body : '<em>Sans contenu</em>'}</div>
      ${tags ? `<div class="tags">Tags: ${tags}</div>` : ''}
    </div>`;
  let modalTitle = cleanText(note.title);
  if (!modalTitle) {
    modalTitle = note.id != null ? `${typeLabel} #${note.id}` : typeLabel;
  }

  openDocument({
    body_html: html,
    title: modalTitle,
    type: note.type,
    type_label: typeLabel,
    status: note.status,
    created_at: note.created_at,
    author: note.author_charname,
    tags: note.tags
  });
}

// NUI open/close
window.addEventListener('message', (e) => {
  const d = e.data || {};
  if (d.action === 'open') {
    closeDocument(false);
    app.classList.remove('hidden');
    switchTab('complaint');
  } else if (d.action === 'openDocument') {
    openDocument(d.meta);
  }
});

function openDocument(meta) {
  appWasVisibleBeforeDoc = !app.classList.contains('hidden');
  app.classList.add('hidden');
  docLayer.classList.remove('hidden');
  const titleText = cleanText(meta && meta.title) || 'Document';
  docTitleEl.textContent = titleText;
  const subtitleText = docSubtitle(meta);
  if (subtitleText) {
    docSubtitleEl.textContent = subtitleText;
    docSubtitleEl.classList.remove('hidden');
  } else {
    docSubtitleEl.textContent = '';
    docSubtitleEl.classList.add('hidden');
  }
  // Build sandboxed HTML for viewing the stored snapshot
  const html = meta && meta.body_html ? meta.body_html : '<p>Document vide</p>';
  const blob = new Blob([html], { type: 'text/html' });
  if (lastDocUrl) {
    URL.revokeObjectURL(lastDocUrl);
  }
  lastDocUrl = URL.createObjectURL(blob);
  docFrame.src = lastDocUrl;
}

function closeDocument(showApp = true) {
  if (lastDocUrl) {
    URL.revokeObjectURL(lastDocUrl);
    lastDocUrl = null;
  }
  docFrame.src = 'about:blank';
  docLayer.classList.add('hidden');
  docTitleEl.textContent = 'Document';
  docSubtitleEl.textContent = '';
  docSubtitleEl.classList.add('hidden');
  if (showApp) {
    if (appWasVisibleBeforeDoc) {
      app.classList.remove('hidden');
    } else {
      app.classList.add('hidden');
    }
  }
  appWasVisibleBeforeDoc = false;
}

function handleDocClose() {
  const shouldShowApp = appWasVisibleBeforeDoc;
  closeDocument(true);
  postNui('close_document', { showApp: shouldShowApp });
}

document.getElementById('doc-close').addEventListener('click', handleDocClose);

btnClose.addEventListener('click', () => {
  postNui('close', {}).finally(() => {
    closeDocument(false);
    app.classList.add('hidden');
  });
});
btnRefresh.addEventListener('click', refreshList);
btnCreate.addEventListener('click', createNote);
btnPrint.addEventListener('click', printDoc);
btnVerify.addEventListener('click', verifyCode);

tabs.forEach(btn => btn.addEventListener('click', () => switchTab(btn.dataset.tab)));
filterType.addEventListener('change', refreshList);

window.addEventListener('keydown', (ev) => {
  if (ev.key === 'Escape') {
    if (!docLayer.classList.contains('hidden')) {
      ev.preventDefault();
      handleDocClose();
    } else if (!app.classList.contains('hidden')) {
      ev.preventDefault();
      btnClose.click();
    }
  }
});
