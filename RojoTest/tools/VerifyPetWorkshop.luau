--!strict
-- Run on Studio Server. Isolated contexts, never touches a loaded profile.
assert(game:GetService("RunService"):IsStudio())
local Shared = game.ReplicatedStorage.Shared
local Data = require(Shared.Core.ProfileData)
local V = require(Shared.Core.PetVariants)
local Commands = require(game.ServerScriptService.Server.Gameplay.Commands)
local player = assert(game.Players:GetPlayers()[1])
local d = Data.fresh()
d.petMaterial = 100
for i = 1, 5 do
	table.insert(d.pets, {
		uid = "test" .. i,
		id = "Cactus",
		name = "Cactus",
		rarity = "Common",
		boost = 1.27,
		baseBoost = 1.27,
		eggId = "Uncommon",
		sourceWorld = 1,
	})
end
local s: any = {
	data = d,
	tokens = 12,
	lastAction = os.clock(),
	busyUntil = 0,
	inventoryVersion = 0,
	purchasePolicyReady = true,
	paidRandomRestricted = false,
}
local events = {}
local callback: any
Commands.install({
	states = { [player] = s },
	action = { OnServerEvent = {
		Connect = function(_, fn)
			callback = fn
		end,
	} },
	publish = function() end,
	effect = {
		FireClient = function(_, _, kind, info)
			table.insert(events, { kind = kind, info = info })
		end,
	},
	kickTiming = { cancel = function() end },
	claimPending = function() end,
} :: any)
local checks = 0
local function check(ok: boolean, why: string)
	assert(ok, why)
	checks += 1
end
local function call(command: string, value: any, extra: any)
	s.tokens = 12
	callback(player, command, value, extra)
end
s.paidRandomRestricted = true
call("FusePets", 0, { "test1", "test2", "test3", "test4", "test5" })
check(#d.pets == 5, "Policy blocked without consumption")
check(events[#events].kind == "PetCraftRejected", "Policy rejects pending UI")
s.paidRandomRestricted = false
s.purchasePolicyReady = false
call("MutatePet", "test1", 0)
check(d.petMaterial == 100, "Unknown policy fails closed")
s.purchasePolicyReady = true
call("FusePets", 0, { "test1", "test1" })
check(#d.pets == 5, "Duplicate materials never spend")
d.equipped = { "test1" }
call("FusePets", 0, { "test1" })
check(#d.pets == 5, "Equipped pet protected")
d.equipped = {}
call("FusePets", 0, { "test1", "test2", "test3", "test4", "test5" })
check(#d.pets == 1, "Five materials become exactly one")
check(V.form(d.pets[1]) ~= "Normal", "Guaranteed success upgrades form")
check(d.pets[1].craftRevision == 1, "Revision advances before effect")
check(events[#events].kind == "PetCraftResult", "Server sends committed result")
check(s.inventoryVersion == 1, "Inventory snapshot invalidated")
check(d.petMaterial == 100, "Form fusion costs pets only")
call("MutatePet", "test1", 1)
check(d.petMaterial == 100, "Cooldown blocks second spend")
s.petCraftUntil = 0
call("MutatePet", "test1", 1)
check(d.petMaterial == 90, "Mutation exact shard cost")
check(V.mutation(d.pets[1].mutation) ~= nil, "Only configured mutation")
local form = V.form(d.pets[1])
local power = d.pets[1].boost
check(d.pets[1].craftRevision == 2, "Mutation revision advances")
s.petCraftUntil = 0
call("MutatePet", "test1", 1)
check(d.petMaterial == 90 and d.pets[1].boost == power, "Retry cannot spend twice")
local catalog = {
	stones = { Pebble = true },
	trails = { None = true },
	pets = {
		Cactus = { name = "Cactus", rarity = "Common", boost = 1.15 },
	},
}
local loaded = Data.normalize(d, catalog)
check(V.form(loaded.pets[1]) == form, "Form survives reload")
check(loaded.pets[1].mutation == d.pets[1].mutation, "Mutation survives reload")
check(math.abs(loaded.pets[1].boost - power) < 1e-7, "Reload never compounds boost")
check(loaded.petMaterial == 90, "Reload preserves spent shards")
return { checks = checks, profileWrites = 0, source = "isolated Commands context" }
