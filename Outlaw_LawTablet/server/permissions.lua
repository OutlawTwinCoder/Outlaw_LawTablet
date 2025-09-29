Perms = Perms or {}

-- Basic check: authoring allowed if job == Config.WriterJob
-- You can extend with grade checks or ACE/Custom
local function normalizeJobName(value)
  if not value or value == '' then return nil end
  local vt = type(value)
  if vt ~= 'string' and vt ~= 'number' then return nil end
  local str = tostring(value)
  str = str:gsub('^%s+', ''):gsub('%s+$', '')
  if str == '' then return nil end
  return string.lower(str)
end

local function extractJobName(job)
  local jt = type(job)
  if jt == 'string' or jt == 'number' then
    return job
  elseif jt == 'table' then
    return job.name or job.id or job.job or job.label or job[1]
  end
  return nil
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

local function resolveJobName(xPlayer)
  if not xPlayer then return nil end

  if type(xPlayer.getJob) == 'function' then
    local ok, data = pcall(xPlayer.getJob, xPlayer)
    if ok then
      local name = extractJobName(data)
      if name then return name end
    end
  end

  local name = extractJobName(xPlayer.job)
  if name then return name end

  if type(xPlayer.PlayerData) == 'table' then
    name = extractJobName(xPlayer.PlayerData.job)
    if name then return name end
  end

  if type(xPlayer.jobs) == 'table' then
    name = extractJobName(xPlayer.jobs.primary or xPlayer.jobs.main or xPlayer.jobs.job)
    if name then return name end
    for _, entry in pairs(xPlayer.jobs) do
      name = extractJobName(entry)
      if name then return name end
    end
  end

  if type(xPlayer.getJobName) == 'function' then
    local ok, data = pcall(xPlayer.getJobName, xPlayer)
    if ok then
      name = extractJobName(data) or data
      if name and name ~= '' then return name end
    end
  end

  return nil
end

function Perms.canWrite(source)
  if not ESX then return true end -- fallback
  local xPlayer = ESX.GetPlayerFromId(source)
  if not xPlayer then return false end

  local jobName = resolveJobName(xPlayer)
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
