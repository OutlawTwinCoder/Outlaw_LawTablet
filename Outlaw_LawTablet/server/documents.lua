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
