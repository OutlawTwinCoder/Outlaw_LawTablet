Utils = Utils or {}

local function sanitize(str, maxlen)
  if type(str) ~= 'string' then return '' end
  str = str:gsub('[\0\b\f\v]', ''):gsub('[<>]', '') -- strip angle brackets to reduce XSS
  if #str > (maxlen or 255) then str = str:sub(1, maxlen or 255) end
  return str
end

function Utils.sanitizeTitle(s) return sanitize(s, Config.MaxTitle) end
function Utils.sanitizeBody(s)  return sanitize(s, Config.MaxBody) end
function Utils.sanitizeTags(s)  return sanitize(s, Config.MaxTags) end

function Utils.nowUtcIso()
  return os.date('!%Y-%m-%dT%H:%M:%SZ')
end

-- Simple JSON helpers
function Utils.jsonEncode(tbl)
  return json.encode(tbl or {})
end
function Utils.jsonDecode(s)
  if not s or s == '' then return nil end
  local ok, res = pcall(json.decode, s)
  if ok then return res end
  return nil
end

-- Character info helpers (ESX)
function Utils.getIdentifier(source)
  local xPlayer = ESX and ESX.GetPlayerFromId(source)
  if xPlayer and xPlayer.identifier then return xPlayer.identifier end
  if GetPlayerIdentifierByType then
    return GetPlayerIdentifierByType(source, 'license') or GetPlayerIdentifierByType(source, 'steam')
  end
  return nil
end

function Utils.getCharName(source)
  local xPlayer = ESX and ESX.GetPlayerFromId(source)
  if xPlayer and xPlayer.getName then return xPlayer.getName() end
  -- fallback: player name (rp servers usually override this via esx_identity)
  return GetPlayerName(source) or 'Inconnu'
end
