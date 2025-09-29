ESX = exports['es_extended'] and exports['es_extended']:getSharedObject() or nil
json = json or (require and require('json')) or { encode = function(t) return '{}' end, decode=function() return nil end }

AddEventHandler('onResourceStart', function(res)
  if res == GetCurrentResourceName() then
    print('[Outlaw_LawTablet] started v0.1.1')
  end
end)

-- Exports used by ox_inventory items config
exports('useTablet', function(source, item)
  TriggerClientEvent('outlaw_lawtablet:client:open', source)
  return true
end)

exports('useDocument', function(source, item)
  local meta
  if type(item) == 'table' then
    if type(item.metadata) == 'table' then
      meta = item.metadata
    elseif type(item.info) == 'table' then
      meta = item.info
    end
  end

  if not Perms.canReadDocument(source, meta or {}) then
    TriggerClientEvent('ox_lib:notify', source, {
      type = 'error',
      title = 'Accès refusé',
      description = 'Vous ne pouvez pas lire ce document.'
    })
    return false
  end

  TriggerClientEvent('outlaw_lawtablet:client:openDocument', source, meta or {})
  return true
end)

-- Fallback for servers not wiring item exports:
AddEventHandler('ox_inventory:usedItem', function(source, itemName, data)
  if itemName == Config.Items.Tablet then
    TriggerClientEvent('outlaw_lawtablet:client:open', source)
    return
  end
  if itemName == Config.Items.DocPlainte or itemName == Config.Items.DocPlaidoyer or itemName == Config.Items.DocNote then
    local meta
    if type(data) == 'table' then
      if type(data.metadata) == 'table' then
        meta = data.metadata
      elseif type(data.info) == 'table' then
        meta = data.info
      end
    end
    if not Perms.canReadDocument(source, meta or {}) then
      TriggerClientEvent('ox_lib:notify', source, {
        type = 'error',
        title = 'Accès refusé',
        description = 'Vous ne pouvez pas lire ce document.'
      })
      return
    end
    TriggerClientEvent('outlaw_lawtablet:client:openDocument', source, meta or {})
  end
end)
