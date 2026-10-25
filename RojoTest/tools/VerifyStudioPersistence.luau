-- Run in Server Play through Studio MCP. Call write(), restart Play, then
-- readAndClean(key, token). Uses only a newly generated QA key in the Studio
-- namespace; never reads Production or changes a player's progress.
local RunService = game:GetService("RunService")
local H = game:GetService("HttpService")
local Check = {}

local function store()
	assert(RunService:IsStudio() and RunService:IsRunning() and RunService:IsServer(), "Studio Server Play only")
	local Storage = require(game.ServerScriptService.Server.ProfileStorage)
	local environment = Storage.select(true)
	assert(environment.name == "Studio" and environment.storeName == "BallProfiles_Studio_v1")
	assert(environment.legacyStoreName == nil)
	local Library = require(game.ServerStorage.ServerPackages.ProfileStore)
	local deadline = os.clock() + 20
	while Library.DataStoreState == "NotReady" and os.clock() < deadline do
		task.wait(0.1)
	end
	assert(Library.DataStoreState == "Access", "Real DataStore API access required")
	local Data = require(game.ReplicatedStorage.Shared.Core.ProfileData)
	return Library.New(environment.storeName, { version = 1, progress = Data.fresh() })
end

local function releaseAndWait(profile)
	local saved = false
	local connection = profile.OnAfterSave:Connect(function()
		saved = true
	end)
	profile:EndSession()
	local deadline = os.clock() + 20
	while not saved and os.clock() < deadline do
		task.wait(0.1)
	end
	connection:Disconnect()
	assert(saved, "Final DataStore save was not confirmed")
end

function Check.write()
	local profiles = store()
	local token = H:GenerateGUID(false)
	local key = "QA_RoundTrip_" .. token
	local profile = assert(profiles:StartSessionAsync(key), "Could not start QA profile")
	local Config = require(game.ReplicatedStorage.Shared.GameConfig)
	local definition = Config.Pets[1]
	local data = profile.Data.progress
	profile.Data.qaToken = token
	data.skill, data.wins, data.rebirths, data.best = 12345, 6789, 2, 321
	data.settings.sound = 73
	data.pets = {
		{
			uid = "qa-pet-" .. token,
			id = definition.id,
			name = definition.name,
			boost = definition.boost,
			rarity = definition.rarity,
		},
	}
	data.equipped = { data.pets[1].uid }
	releaseAndWait(profile)
	return { key = key, token = token, saved = true, environment = "Studio" }
end

function Check.readAndClean(key, token)
	assert(type(token) == "string" and token:match("^[%da-fA-F%-]+$") and #token == 36)
	assert(key == "QA_RoundTrip_" .. token, "Only this check's own generated key may be used")
	local profiles = store()
	local profile = assert(profiles:StartSessionAsync(key), "Could not reload QA profile")
	local data = profile.Data.progress
	local valid = profile.Data.qaToken == token
		and data.skill == 12345
		and data.wins == 6789
		and data.rebirths == 2
		and data.best == 321
		and data.settings.sound == 73
		and #data.pets == 1
		and #data.equipped == 1
		and data.pets[1].uid == "qa-pet-" .. token
		and data.equipped[1] == data.pets[1].uid
	local ownsFixture = profile.Data.qaToken == token
	releaseAndWait(profile)
	-- Delete only the isolated fixture created by write(), after its final save.
	if ownsFixture then
		assert(profiles:RemoveAsync(key), "Could not remove the QA fixture")
	end
	assert(valid, "Progress did not survive the Play restart")
	return { environment = "Studio", skill = 12345, wins = 6789, rebirths = 2, best = 321, pets = 1, cleaned = true }
end

return Check
