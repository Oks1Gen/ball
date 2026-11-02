--!strict
-- All services are initialized before any starts. Scene migrations retain their existing guards.
local Profiles = require(script.Services.ProfileService)
local World = require(script.Services.WorldService)
local context = { ProfileStore = require(game.ServerStorage.ServerPackages.ProfileStore) }
local services = { Profiles, World }
for _, service in services do
	service:Init(context)
end
require(script.IntroStreaming).start()
for _, service in services do
	service:Start()
end
require(script.CharacterSpawn).start(World.map)
require(script.SkippingGame).start(World.map)
print("[Ball] Server started - BUILD stack-1")
