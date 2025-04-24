fx_version 'cerulean'
games { 'gta5' }

author 'Olsen1157'
description 'olsen_drugbusiness'
version '1.0.0'

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	"@vrp/lib/utils.lua",
	'language.lua',
	'config.lua',
	'server/server.lua',
	'server/protection_sv.lua',
}

client_scripts {
	"lib/Tunnel.lua",
	"lib/Proxy.lua",
	'language.lua',
	'config.lua',
	'client/client.lua',
	'client/utils.lua',
	'client/protection_cl.lua',
}
