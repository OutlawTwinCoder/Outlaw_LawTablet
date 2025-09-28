Perms = Perms or {}

-- Basic check: authoring allowed if job == Config.WriterJob
-- You can extend with grade checks or ACE/Custom
local function normalizeJobName(value)
  if not value or value == '' then return nil end
  local vt = type(value)
  if vt ~= 'string' and vt ~= 'number' then return nil end
  return string.lower(tostring(value))
end

local function jobMatches(jobName)
  local normalized = normalizeJobName(jobName)
  if not normalized then return false end

  local writerJob = Config.WriterJob
  if type(writerJob) == 'table' then
    for _, allowed in ipairs(writerJob) do
      if normalizeJobName(allowed) == normalized then
        return true
      end
    end
    return false
  end

  return normalized == normalizeJobName(writerJob)
end

function Perms.canWrite(source)
  if not ESX then return true end -- fallback
  local xPlayer = ESX.GetPlayerFromId(source)
  if not xPlayer then return false end

  local job = nil
  if xPlayer.getJob then
    local ok, data = pcall(xPlayer.getJob, xPlayer)
    if ok then job = data end
  end
  job = job or xPlayer.job or {}

  local jobName = job.name or job.id or job.job or job.label
  return jobMatches(jobName)
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
