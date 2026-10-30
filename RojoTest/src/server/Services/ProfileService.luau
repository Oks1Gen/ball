--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local Data = require(game.ReplicatedStorage.Shared.Core.ProfileData)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local BallPurchases = require(game.ReplicatedStorage.Shared.BallPurchases)
local ReturnRewards = require(game.ReplicatedStorage.Shared.Core.ReturnRewards)
local Log = require(script.Parent.Parent.ProfileLog)
local Storage = require(script.Parent.Parent.ProfileStorage)
local Service: any = { profiles = {}, loading = {} }

-- The datastore key and the user id must never reach the log.
function Service:Init(context: any)
	self.ProfileStore = context.ProfileStore
	self.catalog = { stones = {}, trails = {}, pets = {} }
	for _, item in Config.Stones do
		self.catalog.stones[item.id] = item
	end
	for _, item in Config.Trails do
		self.catalog.trails[item.id] = item
	end
	local catalogs: { any } = {
		Config.Pets,
		Config.LegacyPets,
		Config.UncommonPets,
		Config.RarePets,
		Config.RainbowPets,
		{ Config.AdminPet },
	}
	for _, list in catalogs do
		for _, item in list do
			self.catalog.pets[item.id] = item
		end
	end
	self.environment = Storage.select(RunService:IsStudio())
	self.store = context.ProfileStore.New(self.environment.storeName, { version = 0, progress = Data.fresh() })
	self.legacyStore = if self.environment.legacyStoreName
		then DataStoreService:GetDataStore(self.environment.legacyStoreName)
		else nil
end

function Service:waitForStorage(player: Player): boolean
	local deadline = os.clock() + Storage.AccessTimeout
	while self.ProfileStore.DataStoreState == "NotReady" and os.clock() < deadline do
		if player.Parent ~= Players or self.ProfileStore.IsClosing then
			return false
		end
		task.wait(0.1)
	end
	if not Storage.canPersist(self.ProfileStore.DataStoreState) then
		-- ProfileStore can fall back to memory when Studio API access is off.
		-- Refuse that session: both configured environments must persist.
		warn("[Ball profiles] Persistent storage unavailable: " .. tostring(self.ProfileStore.DataStoreState))
		if player.Parent == Players then
			player:Kick(
				if RunService:IsStudio()
					then "Saving is unavailable. Enable Studio Access to API Services in Game Settings > Security, then restart Play."
					else "Saving is temporarily unavailable. Please rejoin shortly."
			)
		end
		return false
	end
	return not self.ProfileStore.IsClosing and player.Parent == Players
end

function Service:Start()
	self.ProfileStore.OnError:Connect(function(message, store, key)
		warn("[Ball profiles] " .. Log.redact(tostring(store) .. ": " .. tostring(message), nil, tostring(key)))
	end)
end

function Service:Load(player: Player): any
	if self.loading[player] or self.profiles[player] then
		return nil
	end
	-- The guard is held until the profile is published: the migration below
	-- yields, and a second session for the same key would be rejected by
	-- ProfileStore, so the player would be kicked with a good profile loaded.
	self.loading[player] = true
	local ok, result = pcall(function()
		return self:loadSession(player)
	end)
	self.loading[player] = nil
	if not ok then
		warn("[Ball profiles] Load failed: " .. Log.redact(tostring(result), player.UserId))
		if player.Parent == Players then
			player:Kick("Your data could not be loaded. Please rejoin.")
		end
		return nil
	end
	return result
end

-- Starts the session, migrates the data and publishes the profile. The caller
-- holds the loading guard, so the profile is registered while it is still set.
function Service:loadSession(player: Player): any
	if not self:waitForStorage(player) then
		return nil
	end
	local ok, profile = pcall(function()
		return self.store:StartSessionAsync("Player_" .. player.UserId, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})
	end)
	if not ok then
		warn("[Ball profiles] Load failed: " .. Log.redact(tostring(profile), player.UserId))
		profile = nil
	end
	if not profile then
		if player.Parent == Players then
			player:Kick("Your data could not be loaded. Please rejoin.")
		end
		return nil
	end
	if player.UserId > 0 then
		profile:AddUserId(player.UserId)
	end
	profile:Reconcile()
	local initialized, reason = pcall(function()
		assert(profile.Data.version == 0 or profile.Data.version == 1, "Unsupported profile version")
		if profile.Data.version == 0 and self.legacyStore then
			assert(self:importLegacy(player, profile), "Legacy import pending; progress was not replaced")
		end
		profile.Data.progress = Data.normalize(profile.Data.progress, self.catalog)
		ReturnRewards.arrive(profile.Data.progress, os.time())
		profile.Data.version = 1
	end)
	if not initialized or player.Parent ~= Players or not profile:IsActive() then
		profile:EndSession()
		if not initialized then
			warn("[Ball profiles] Migration failed: " .. Log.redact(tostring(reason), player.UserId))
		end
		if player.Parent == Players then
			player:Kick("Your saved data is unavailable. Please rejoin shortly.")
		end
		return nil
	end
	self.profiles[player] = profile
	player:SetAttribute("ProfileStorage", "ProfileStore")
	player:SetAttribute("ProfileEnvironment", self.environment.name)
	return profile
end

-- Do not expose fresh progress until the old store has been read successfully.
-- A failed attempt leaves version zero, so rejoining retries the import.
function Service:importLegacy(player: Player, profile: any): boolean
	local ok, record = pcall(function()
		return self.legacyStore:GetAsync("u_" .. player.UserId)
	end)
	if not ok then
		warn(
			"[Ball profiles] Legacy store read failed; import pending: " .. Log.redact(tostring(record), player.UserId)
		)
		return false
	end
	local progress, err = Data.legacy(record, os.time())
	if err then
		warn("[Ball profiles] Legacy import pending: " .. err)
		return false
	end
	if progress then
		profile.Data.progress = progress
	end
	return true
end

function Service:Attach(player: Player, state: any, onLost: () -> ())
	local profile = assert(self.profiles[player], "Profile session is missing")
	local function sync()
		local original = state.data
		original.lastSeen = os.time()
		original.offlineRate = ReturnRewards.offlineRate(original, Config.Lanes, BallPurchases.power(original))
		profile.Data.progress = original
	end
	profile.OnSave:Connect(sync)
	profile.OnLastSave:Connect(sync)
	profile.OnSessionEnd:Connect(function()
		if self.profiles[player] == profile then
			self.profiles[player] = nil
			onLost()
			if player.Parent == Players then
				player:Kick("Your data session ended. Please rejoin.")
			end
		end
	end)
end

function Service:Save(player: Player, state: any, receiptId: string?): boolean
	local profile = self.profiles[player]
	if not profile or not profile:IsActive() or state.saving then
		return false
	end
	profile.Data.progress = state.data
	if receiptId and profile.LastSavedData.progress.receipts[receiptId] then
		return true
	end
	state.saving = true
	profile:Save()
	-- The save runs in the background, so the guard is released right away:
	-- the leave path and the autosave must not wait for the receipt.
	state.saving = false
	if receiptId then
		local id: string = receiptId
		state.awaitingReceipt = true
		local deadline = os.clock() + 15
		local ok, saved = pcall(function()
			while profile:IsActive() and os.clock() < deadline and not profile.LastSavedData.progress.receipts[id] do
				task.wait(0.1)
			end
			return profile.LastSavedData.progress.receipts[id] == true
		end)
		state.awaitingReceipt = false
		if not ok then
			warn("[Ball profiles] Receipt wait failed: " .. Log.redact(tostring(saved), player.UserId))
			return false
		end
		return profile:IsActive() and saved
	end
	return profile:IsActive()
end

function Service:Release(player: Player, state: any)
	local profile = self.profiles[player]
	if not profile then
		return
	end
	profile.Data.progress = state.data
	profile.Data.progress.lastSeen = os.time()
	profile.Data.progress.offlineRate =
		ReturnRewards.offlineRate(profile.Data.progress, Config.Lanes, BallPurchases.power(profile.Data.progress))
	self.profiles[player] = nil
	profile:EndSession()
	player:SetAttribute("ProfileStorage", nil)
end

return Service
