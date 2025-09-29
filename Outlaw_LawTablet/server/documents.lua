Documents = Documents or {}

local function deepCopy(value)
  if type(value) ~= 'table' then return value end
  local result = {}
  for k, v in pairs(value) do
    result[k] = deepCopy(v)
  end
  return result
end

local function randomCode(n)
  local s = ''
  for i=1,n do
    local r = math.random(0,35)
    local c = (r < 10) and string.char(48+r) or string.char(55+r) -- 0-9 A-Z
    s = s .. c
  end
  return s
end

local function simpleHash(str)
  local h = 5381
  for i=1,#str do
    h = ((h * 33) ~ string.byte(str, i)) & 0x7fffffff
  end
  return tostring(h)
end

local function buildHtml(note)
  local typeCfg = Config.Types[note.type] or { label = note.type, color = '#999' }
  local title = Utils.sanitizeTitle(note.title)
  local body  = Utils.sanitizeBody(note.body)
  local printedAt = Utils.nowUtcIso()
  local header = string.format('<div class="hdr"><div class="l">%s</div><div class="r">%s</div></div>', typeCfg.label, printedAt)
  local h1 = string.format('<h1 style="color:%s">%s</h1>', typeCfg.color, title)
  local author = string.format('<div class="meta">Auteur: %s • Statut: %s • Type: %s</div>', note.author_charname or 'Inconnu', note.status or '', typeCfg.label)
  local content = string.format('<div class="content">%s</div>', body:gsub('\n','<br/>'))
  local seal = '<div class="seal">Cachet: TRIBUNAL-LS</div>'
  local style = [[
    <style>
      body { font-family: Arial, sans-serif; background: #0b0f1a; color:#dfe7ff; margin:0; padding:24px; }
      .doc { max-width: 860px; margin:0 auto; background: rgba(20,24,36,.9); border:1px solid rgba(255,255,255,.1); border-radius: 14px; padding: 20px 28px; }
      .hdr { display:flex; justify-content:space-between; opacity:.8; font-size:12px; margin-bottom:8px }
      h1 { margin: 12px 0 6px 0; }
      .meta { font-size:12px; opacity:.8; margin-bottom:18px }
      .content { line-height:1.5; white-space:pre-wrap; background: rgba(255,255,255,.03); padding:12px; border-radius:10px; }
      .seal { margin-top:18px; font-size:12px; opacity:.7 }
      .footer { margin-top:14px; display:flex; gap:10px; align-items:center; font-size:12px; opacity:.75 }
      .badge { display:inline-block; padding:2px 6px; border:1px solid rgba(255,255,255,.15); border-radius:8px; font-size:11px; }
    </style>
  ]]
  local html = string.format('%s<div class="doc">%s%s%s%s<div class="footer"><span class="badge">Outlaw Document</span></div></div>', style, header, h1, author, content, seal)
  return html
end

local function ensureSource(meta)
  if type(meta.source) ~= 'table' then
    meta.source = {}
  end
  return meta.source
end

local function applyPrintedRow(meta, row)
  if not row then return end

  meta.doc_id = row.id or meta.doc_id
  meta.note_id = meta.note_id or row.note_id
  meta.type = meta.type or row.type
  if not meta.type_label and meta.type then
    local typeCfg = Config.Types[meta.type]
    if typeCfg and typeCfg.label then
      meta.type_label = typeCfg.label
    end
  end
  meta.title = (meta.title and meta.title ~= '') and meta.title or row.title
  meta.status = meta.status or row.status
  meta.tags = meta.tags or row.tags
  meta.printed_at = meta.printed_at or Utils.toIso8601(row.printed_at)
  meta.body_html = meta.body_html or row.body_html
  meta.author = meta.author or row.printed_by_charname
  meta.author_identifier = meta.author_identifier or row.printed_by_identifier

  if type(meta.printed_by) ~= 'table' then
    meta.printed_by = {
      charname = row.printed_by_charname,
      identifier = row.printed_by_identifier
    }
  else
    meta.printed_by.charname = meta.printed_by.charname or row.printed_by_charname
    meta.printed_by.identifier = meta.printed_by.identifier or row.printed_by_identifier
  end

  local src = ensureSource(meta)
  src.doc_id = src.doc_id or row.id
  src.note_id = src.note_id or row.note_id
  src.type = src.type or row.type
  src.case_id = src.case_id or row.case_id
  src.version_id = src.version_id or row.version_id
end

local function applyNoteRow(meta, note)
  if not note then return end

  meta.note_id = meta.note_id or note.id
  meta.type = meta.type or note.type
  if not meta.type_label and meta.type then
    local typeCfg = Config.Types[meta.type]
    if typeCfg and typeCfg.label then
      meta.type_label = typeCfg.label
    end
  end
  meta.title = (meta.title and meta.title ~= '') and meta.title or note.title
  meta.status = meta.status or note.status
  meta.tags = meta.tags or note.tags
  meta.created_at = meta.created_at or Utils.toIso8601(note.created_at)
  meta.author = meta.author or note.author_charname
  meta.author_identifier = meta.author_identifier or note.author_identifier

  if not meta.body_html or meta.body_html == '' then
    meta.body_html = buildHtml(note)
  end

  local src = ensureSource(meta)
  src.note_id = src.note_id or note.id
  src.type = src.type or note.type
  src.case_id = src.case_id or note.case_id
end

function Documents.prepareViewerMeta(meta)
  local prepared = deepCopy(type(meta) == 'table' and meta or {})

  local docId = prepared.doc_id or (prepared.source and prepared.source.doc_id)
  if docId ~= nil then
    docId = tonumber(docId)
  end

  local noteId = prepared.note_id or (prepared.source and prepared.source.note_id)
  if noteId ~= nil then
    noteId = tonumber(noteId)
  end

  local printedRow
  if docId then
    printedRow = MySQL.single.await('SELECT id,note_id,type,title,body_html,status,tags,case_id,version_id,printed_by_identifier,printed_by_charname,printed_at FROM outlaw_documents_printed WHERE id = ?', { docId })
    if printedRow then
      applyPrintedRow(prepared, printedRow)
      noteId = noteId or printedRow.note_id
    end
  end

  if noteId then
    local noteRow = MySQL.single.await('SELECT id,type,title,body,status,tags,author_charname,author_identifier,created_at,case_id FROM outlaw_notes WHERE id = ? AND deleted_at IS NULL', { noteId })
    if noteRow then
      applyNoteRow(prepared, noteRow)
    end
  end

  if not prepared.body_html or prepared.body_html == '' then
    return nil, 'body_missing'
  end

  if prepared.type and not prepared.type_label then
    local typeCfg = Config.Types[prepared.type]
    if typeCfg and typeCfg.label then
      prepared.type_label = typeCfg.label
    end
  end

  return prepared
end

function Documents.openDocumentForPlayer(source, meta)
  local prepared, err = Documents.prepareViewerMeta(meta)
  if not prepared then
    TriggerClientEvent('ox_lib:notify', source, {
      type = 'error',
      title = 'Document',
      description = err == 'body_missing' and 'Document introuvable ou vide.' or 'Impossible de charger ce document.'
    })
    return false
  end

  TriggerClientEvent('outlaw_lawtablet:client:openDocument', source, prepared)
  return true
end

lib.callback.register('outlaw_lawtablet:documents:print', function(source, params)
  if not Perms.canWrite(source) then return { ok=false, error='no_permission' } end
  local id = params and params.note_id
  if not id then return { ok=false, error='missing_note_id' } end

  local note = MySQL.single.await('SELECT * FROM outlaw_notes WHERE id = ? AND deleted_at IS NULL', { id })
  if not note then return { ok=false, error='not_found' } end

  local html = buildHtml(note)
  local bodyForHash = (note.title or '') .. '|' .. (note.type or '') .. '|' .. (note.status or '') .. '|' .. html
  local hash = simpleHash(bodyForHash)
  local code = string.format('%s-%s', randomCode(4), randomCode(4))

  local docId = MySQL.insert.await('INSERT INTO outlaw_documents_printed (type,note_id,case_id,version_id,title,body_html,status,tags,printed_by_identifier,printed_by_charname,printed_at,hash,public_code,revoked,meta_json) VALUES (?,?,?,?,?,?,?,?,?,?,NOW(),?,?,0,?)', {
    note.type, note.id, note.case_id, note.version_id or 1, note.title, html, note.status, note.tags or '',
    Utils.getIdentifier(source) or 'unknown', Utils.getCharName(source), hash, code, Utils.jsonEncode({ watermark = 'CONFIDENTIEL' })
  })

  local typeCfg = Config.Types[note.type] or Config.Types['note']
  local itemName = typeCfg.item or Config.Items.DocNote

  if exports.ox_inventory then
    exports.ox_inventory:AddItem(source, itemName, 1, {
      doc_id = docId,
      note_id = note.id,
      type = note.type,
      type_label = typeCfg.label,
      source = { type = note.type, note_id = note.id, case_id = note.case_id, version_id = note.version_id or 1 },
      title = (typeCfg.label .. ' – ' .. (note.title or ('Note #'..tostring(note.id)))),
      body_html = html,
      status = note.status,
      tags = note.tags,
      printed_at = os.date('!%Y-%m-%dT%H:%M:%SZ'),
      printed_by = { charname = Utils.getCharName(source), identifier = Utils.getIdentifier(source) },
      signature = { signed = true, signed_by = Utils.getCharName(source), seal = 'TRIBUNAL-LS', hash = hash, revoked = false },
      verify = { original_hash = hash, public_code = code, expires_at = nil },
      ui = { watermark = 'CONFIDENTIEL', theme = 'Outlaw' }
    })
    return { ok=true, id=docId, code=code, hash=hash, item=itemName }
  else
    return { ok=false, error='ox_inventory_missing_but_doc_saved' }
  end
end)

lib.callback.register('outlaw_lawtablet:documents:verify', function(source, code)
  local row = MySQL.single.await('SELECT id,hash,revoked FROM outlaw_documents_printed WHERE public_code = ?', { code })
  if not row then return { ok=false, status='not_found' } end
  if row.revoked == 1 then return { ok=false, status='revoked' } end
  return { ok=true, status='valid', id=row.id, hash=row.hash }
end)
