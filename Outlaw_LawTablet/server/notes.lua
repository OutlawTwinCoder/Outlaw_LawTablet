local function normalizeType(t)
  t = tostring(t or 'note')
  if not Config.Types[t] then return 'note' end
  return t
end

lib.callback.register('outlaw_lawtablet:notes:create', function(source, payload)
  if not Perms.canWrite(source) then
    return { ok=false, error='no_permission' }
  end
  local p = payload or {}
  p.type = normalizeType(p.type)
  local title = Utils.sanitizeTitle(p.title or (Config.Types[p.type].label .. ' #?'))
  local body  = Utils.sanitizeBody(p.body or '')
  local status = (p.status and tostring(p.status)) or (Config.StatusByType[p.type] and Config.StatusByType[p.type][1]) or 'Brouillon'
  local tags  = Utils.sanitizeTags(p.tags or '')
  local author_identifier = Utils.getIdentifier(source) or 'unknown'
  local author_charname   = Utils.getCharName(source)

  local id = MySQL.insert.await('INSERT INTO outlaw_notes (type,title,body,status,visibility,tags,author_identifier,author_charname,created_at) VALUES (?,?,?,?,?,?,?,?,NOW())', {
    p.type, title, body, status, 'private', tags, author_identifier, author_charname
  })
  return { ok=true, id=id }
end)

lib.callback.register('outlaw_lawtablet:notes:list', function(source, params)
  local typeFilter = params and params.type or nil
  local q = 'SELECT id,type,title,status,tags,author_charname,created_at FROM outlaw_notes WHERE deleted_at IS NULL'
  local args = {}
  if typeFilter and typeFilter ~= '' then
    q = q .. ' AND type = ?'
    table.insert(args, typeFilter)
  end
  q = q .. ' ORDER BY id DESC LIMIT 100'
  local rows = MySQL.query.await(q, args)
  return { ok=true, items=rows or {} }
end)

lib.callback.register('outlaw_lawtablet:notes:get', function(source, id)
  local row = MySQL.single.await('SELECT * FROM outlaw_notes WHERE id = ? AND deleted_at IS NULL', { id })
  if not row then return { ok=false, error='not_found' } end
  return { ok=true, item=row }
end)
