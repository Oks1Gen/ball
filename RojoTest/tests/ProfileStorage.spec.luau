--!strict
local Storage = require("../src/server/ProfileStorage")

return {
	["Studio profiles cannot select Production or its legacy import"] = function()
		local studio = Storage.select(true)
		local production = Storage.select(false)
		assert(studio.name == "Studio" and production.name == "Production")
		assert(studio.storeName ~= production.storeName)
		assert(studio.legacyStoreName == nil)
		-- Keep the existing live namespace: adding a Studio store must not reset live saves.
		assert(production.storeName == "BallProfiles_v1" and production.legacyStoreName == "StoneSkipping_1")
		assert(not pcall(function()
			studio.storeName = production.storeName
		end))
	end,
	["memory fallback and unknown API access never count as persistent storage"] = function()
		assert(Storage.canPersist("Access"))
		for _, state in { "NotReady", "NoAccess", "NoInternet", "Unknown" } do
			assert(not Storage.canPersist(state))
		end
	end,
}
