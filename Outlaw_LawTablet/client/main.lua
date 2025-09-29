local uiOpen = false

RegisterCommand('lawtablet', function()
  TriggerEvent('outlaw_lawtablet:client:open')
end, false)

RegisterNetEvent('outlaw_lawtablet:client:open', function()
  if uiOpen then return end
  SetNuiFocus(true, true)
  local typePayload = {}
  for key, data in pairs(Config.Types or {}) do
    typePayload[key] = {
      label = data.label,
      color = data.color,
      item = data.item
    }
  end

  local statusPayload = {}
  for key, list in pairs(Config.StatusByType or {}) do
    if type(list) == 'table' then
      statusPayload[key] = {}
      for i=1, #list do
        statusPayload[key][i] = list[i]
      end
    end
  end

  SendNUIMessage({
    action = 'open',
    config = {
      types = typePayload,
      statuses = statusPayload
    }
  })
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

RegisterNUICallback('close_document', function(data, cb)
  local showApp = data and data.showApp
  if showApp then
    SetNuiFocus(true, true)
    uiOpen = true
  else
    SetNuiFocus(false, false)
    uiOpen = false
  end
  cb(true)
end)

RegisterNetEvent('outlaw_lawtablet:client:openDocument', function(meta)
  SetNuiFocus(true, true)
  SendNUIMessage({ action = 'openDocument', meta = meta })
  uiOpen = true
end)
