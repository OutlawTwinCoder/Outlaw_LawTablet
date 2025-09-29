local ready = false
local running = false

local function ensureMigrations()
  if ready or running then return end
  running = true

  local ok, err = pcall(function()
    -- Create notes table
    MySQL.query.await([[
      CREATE TABLE IF NOT EXISTS outlaw_notes (
        id INT AUTO_INCREMENT PRIMARY KEY,
        type VARCHAR(16) NOT NULL,
        title VARCHAR(128) NOT NULL,
        body MEDIUMTEXT NOT NULL,
        status VARCHAR(24) NOT NULL,
        visibility VARCHAR(64) NOT NULL DEFAULT 'private',
        tags VARCHAR(255) NULL,
        case_id INT NULL,
        linked_ids TEXT NULL,
        author_identifier VARCHAR(64) NOT NULL,
        author_charname VARCHAR(96) NOT NULL,
        concerned_identifier VARCHAR(64) NULL,
        concerned_charname VARCHAR(96) NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NULL DEFAULT NULL,
        deleted_at TIMESTAMP NULL DEFAULT NULL,
        locked_at TIMESTAMP NULL DEFAULT NULL,
        locked_by_identifier VARCHAR(64) NULL
      );
    ]])

    -- Printed documents table
    MySQL.query.await([[
      CREATE TABLE IF NOT EXISTS outlaw_documents_printed (
        id INT AUTO_INCREMENT PRIMARY KEY,
        type VARCHAR(16) NOT NULL,
        note_id INT NULL,
        case_id INT NULL,
        version_id INT NULL,
        title VARCHAR(128) NOT NULL,
        body_html MEDIUMTEXT NOT NULL,
        status VARCHAR(24) NULL,
        tags VARCHAR(255) NULL,
        printed_by_identifier VARCHAR(64) NOT NULL,
        printed_by_charname VARCHAR(96) NOT NULL,
        printed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        hash VARCHAR(128) NOT NULL,
        public_code VARCHAR(16) NOT NULL,
        revoked TINYINT(1) NOT NULL DEFAULT 0,
        meta_json TEXT NULL
      );
    ]])
  end)

  if not ok then
    running = false
    print(('[Outlaw_LawTablet] Failed to run DB migrations: %s'):format(err))
    return
  end

  ready = true
  running = false
  print('[Outlaw_LawTablet] DB migrations ensured')
end

if MySQL and type(MySQL.ready) == 'function' then
  MySQL.ready(ensureMigrations)
else
  AddEventHandler('onMySQLReady', ensureMigrations)
end

exports('dbReady', function()
  return ready
end)
