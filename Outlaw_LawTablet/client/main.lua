local uiOpen = false

RegisterCommand('lawtablet', function()
  TriggerEvent('outlaw_lawtablet:client:open')
end, false)

RegisterNetEvent('outlaw_lawtablet:client:open', function()
  if uiOpen then return end
  SetNuiFocus(true, true)
  SendNUIMessage({ action = 'open' })
  uiOpen = true
end)

RegisterNUICallback('close', function(_, cb)
  SetNuiFocus(false, false)
  uiOpen = false
  cb(true)
end)

RegisterNUICallback('create_note', function(data, cb)
  local res = lib.callback.await('outlaw_lawtablet:notes:create', false, data)
  cb(res or { ok=false })
end)

RegisterNUICallback('list_notes', function(data, cb)
  local res = lib.callback.await('outlaw_lawtablet:notes:list', false, { type = data and data.type or nil })
  cb(res or { ok=false })
end)

RegisterNUICallback('get_note', function(data, cb)
  local id = data and data.id
  if type(id) ~= 'number' then
    cb({ ok=false, error='invalid_id' })
    return
  end
  local res = lib.callback.await('outlaw_lawtablet:notes:get', false, id)
  cb(res or { ok=false })
end)

RegisterNUICallback('print_document', function(data, cb)
  local res = lib.callback.await('outlaw_lawtablet:documents:print', false, { note_id = data.note_id })
  cb(res or { ok=false })
end)

RegisterNUICallback('verify_code', function(data, cb)
  local res = lib.callback.await('outlaw_lawtablet:documents:verify', false, data and data.code or '')
  cb(res or { ok=false })
end)

RegisterNetEvent('outlaw_lawtablet:client:openDocument', function(meta)
  SetNuiFocus(true, true)
  SendNUIMessage({ action = 'openDocument', meta = meta })
  uiOpen = true
end)
