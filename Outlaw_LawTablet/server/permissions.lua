Perms = Perms or {}

-- Basic check: authoring allowed if job == Config.WriterJob
-- You can extend with grade checks or ACE/Custom
function Perms.canWrite(source)
  if not ESX then return true end -- fallback
  local xPlayer = ESX.GetPlayerFromId(source)
  if not xPlayer then return false end
  local job = xPlayer.getJob and xPlayer.getJob() or {}
  return job.name == Config.WriterJob
end

function Perms.canReadDocument(source, doc)
  if doc.revoked == 1 then return false end
  -- If police read is allowed, allow police job
  if Config.AllowPoliceRead and ESX then
    local xPlayer = ESX.GetPlayerFromId(source)
    local job = xPlayer and xPlayer.getJob() or {}
    if job and job.name == 'police' then return true end
  end
  -- By default documents are readable by anyone who physically has the item
  return true
end
