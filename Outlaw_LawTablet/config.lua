Config = Config or {}

-- Which job can create/edit (others can read if they have access to item and permissions)?
Config.WriterJob = 'avocat'   -- change to your job name
Config.AllowPoliceRead = true -- police can read documents if true

-- Item names (must be defined in ox_inventory items data file)
Config.Items = {
  Tablet = 'avocat_tablet',
  DocPlainte = 'doc_plainte',
  DocPlaidoyer = 'doc_plaidoyer',
  DocNote = 'doc_note'
}

-- Visuals for types & statuses
Config.Types = {
  complaint = { label = 'Plainte', color = '#ff6b6b', item = 'doc_plainte' },
  trial     = { label = 'Procès', color = '#6b9aff', item = 'doc_plaidoyer' },
  note      = { label = 'Note', color = '#9aff6b', item = 'doc_note' },
  other     = { label = 'Autre', color = '#f0ad4e', item = 'doc_note' }
}

Config.StatusByType = {
  complaint = { 'Ouverte', 'En révision', 'Classée' },
  trial     = { 'Préparation', 'Audience', 'Délibéré', 'Clos' },
  note      = { 'Brouillon', 'Finale' },
  other     = { 'Brouillon', 'Finale' }
}

-- Security
Config.MaxTitle = 96
Config.MaxBody  = 12000
Config.MaxTags  = 128

-- Discord webhook (optional): set a URL here to enable simple logs
Config.DiscordWebhook = nil
