fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'Outlaw_LawTablet'
author 'Outlaw Scripts'
description 'Avocat Tablet + Notes/Complaints/Trials with printable document items'
version '0.1.2'

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/app.js',
  'html/app.css',
  'html/assets/*'
}

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua',
  'shared/utils.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/migrations.lua',
  'server/permissions.lua',
  'server/notes.lua',
  'server/documents.lua',
  'server/items.lua',
  'server/main.lua'
}

client_scripts {
  'client/main.lua',
  'client/ui.lua'
}
