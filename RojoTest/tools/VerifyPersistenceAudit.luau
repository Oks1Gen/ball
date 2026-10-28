-- Edit mode. All profiles, players and receipts below are isolated tables.
-- No Init, DataStore or real ProcessReceipt callback is used.
local server = game.ServerScriptService.Server
local function freshModule(module)
	local copy = module:Clone()
	copy.Name = module.Name .. "AuditCheck"
	copy.Parent = module.Parent
	local ok, value = pcall(require, copy)
	copy:Destroy()
	assert(ok, value)
	return value
end
local Profiles = freshModule(server.Services.ProfileService)
local Receipts = freshModule(server.Gameplay.Receipts)
local Data = freshModule(game.ReplicatedStorage.Shared.Core.ProfileData)
local Players = game:GetService("Players")
local H = game:GetService("HttpService")
local report = {}
-- Init must select the real, isolated Studio store, not its Mock reflection.
local requestedStore
local persistentStore = { Mock = {} }
local initialized = setmetatable({}, { __index = Profiles })
initialized:Init({ ProfileStore = {
	New = function(name)
		requestedStore = name
		return persistentStore
	end,
} })
assert(initialized.store == persistentStore and initialized.store ~= persistentStore.Mock)
assert(requestedStore == "BallProfiles_Studio_v1" and initialized.legacyStore == nil)
table.insert(report, { check = "persistent Studio routing without Production import", store = requestedStore })

for _, access in { "NoAccess", "NoInternet" } do
	local opened, kicked = false, false
	local player = {
		Parent = Players,
		UserId = -42,
		Kick = function()
			kicked = true
		end,
	}
	local service = setmetatable({
		profiles = {},
		loading = {},
		ProfileStore = { DataStoreState = access, IsClosing = false },
		store = {
			StartSessionAsync = function()
				opened = true
			end,
		},
	}, { __index = Profiles })
	assert(service:Load(player) == nil and kicked and not opened and not service.loading[player])
	table.insert(report, { check = "refuse nonpersistent fallback", state = access })
end

local function migrationFailure(name, read)
	local active, ended, reads = true, 0, 0
	local profile = { Data = { version = 0, progress = Data.fresh() } }
	function profile:Reconcile() end
	function profile:IsActive()
		return active
	end
	function profile:EndSession()
		active = false
		ended += 1
	end
	local kicked = false
	local player = { Parent = Players, UserId = -42 }
	function player:Kick()
		kicked = true
	end
	function player:SetAttribute() end
	local fake = setmetatable({
		ProfileStore = { DataStoreState = "Access", IsClosing = false },
		environment = { name = "Studio" },
		profiles = {},
		loading = {},
		catalog = { stones = {}, trails = {}, pets = {} },
		store = {
			StartSessionAsync = function()
				active = true
				return profile
			end,
		},
		legacyStore = {
			GetAsync = function()
				reads += 1
				return read()
			end,
		},
	}, { __index = Profiles })
	assert(fake:Load(player) == nil and kicked and ended == 1, name .. ": incomplete import must not publish")
	assert(profile.Data.version == 0 and fake.profiles[player] == nil and not fake.loading[player])
	fake.legacyStore.GetAsync = function()
		reads += 1
		return { data = { wins = 123456, skill = 98765 } }
	end
	assert(fake:Load(player) == profile)
	assert(profile.Data.version == 1 and profile.Data.progress.wins == 123456 and reads == 2)
	table.insert(report, { check = name, retryWins = profile.Data.progress.wins, reads = reads })
end
migrationFailure("temporary read failure", function()
	error("AUDIT simulated unavailable store Player_-42")
end)
migrationFailure("active old lease", function()
	return { data = {}, owner = "old-server", expires = os.time() + 60 }
end)
migrationFailure("malformed old record", function()
	return { wrong = true }
end)

local player = { UserId = -42 }
local data = Data.fresh()
for i = 1, 60 do
	table.insert(data.pets, { uid = tostring(i), id = "AdminDragon", boost = 1 })
end
local state = { data = data }
local saved, saveCount, hatchCount = nil, 0, 0
local saveOk = true
local context = {
	states = { [player] = state },
	Config = {
		Products = { AdminEgg = { id = 1001 } }, -- fixture only, never installed
		AdminPet = { id = "AdminDragon", name = "Dragon", rarity = "Mythic", boost = 25 },
	},
	save = function()
		saveCount += 1
		if saveOk then
			saved = H:JSONDecode(H:JSONEncode(state.data))
		end
		return saveOk
	end,
	publish = function() end,
	equipBest = function() end,
	effect = {
		FireClient = function(_, _, kind)
			if kind == "Hatch" then
				hatchCount += 1
			end
		end,
	},
}
local receipt = { ProductId = 1001, PurchaseId = "audit-receipt" }
local granted = Enum.ProductPurchaseDecision.PurchaseGranted
local deferred = Enum.ProductPurchaseDecision.NotProcessedYet
assert(Receipts.process(context, player, receipt) == granted)
assert(#data.pets == 60 and data.perks.AdminEggPending and saved.perks.AdminEggPending)
assert(saved.receipts[receipt.PurchaseId] and hatchCount == 0)
assert(Receipts.process(context, player, receipt) == granted and #data.pets == 60)
-- Simulate loading the saved obligation in a new session, then deleting a pet.
state.data = saved
table.remove(state.data.pets)
assert(Receipts.claimPending(context, player))
assert(#state.data.pets == 60 and not state.data.perks.AdminEggPending and hatchCount == 1)
assert(not Receipts.claimPending(context, player) and hatchCount == 1)
assert(Receipts.process(context, player, receipt) == granted and hatchCount == 1)
saveOk = false
assert(Receipts.process(context, player, receipt) == deferred)
state.adminOriginal = {}
assert(Receipts.process(context, player, receipt) == deferred)
table.insert(
	report,
	{ check = "receipt reservation, reload, delivery and retries", saves = saveCount, hatches = hatchCount }
)
-- A paid rebirth must wait for an active shot and execute only once on retry.
state.adminOriginal = nil
saveOk = true
state.data.skill = 500
state.data.rebirths = 0
state.lane = 2
local busy = true
context.Config.Products.SkipRebirth = { id = 1002 }
context.rebirth = function(_, skip)
	assert(skip)
	if busy then
		return false
	end
	state.lane = nil
	state.data.skill = 0
	state.data.rebirths += 1
	return true
end
local rebirthReceipt = { ProductId = 1002, PurchaseId = "audit-rebirth" }
assert(Receipts.process(context, player, rebirthReceipt) == deferred)
assert(state.data.skill == 500 and state.data.rebirths == 0 and not state.data.receipts[rebirthReceipt.PurchaseId])
busy = false
assert(Receipts.process(context, player, rebirthReceipt) == granted)
assert(state.data.skill == 0 and state.data.rebirths == 1 and state.lane == nil)
assert(Receipts.process(context, player, rebirthReceipt) == granted and state.data.rebirths == 1)
table.insert(report, { check = "paid rebirth waits and retries once" })
return report
