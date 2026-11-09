--!strict
-- Run in Studio Server. All transactions use an isolated in-memory state.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.GameConfig)
local Data = require(Shared.Core.ProfileData)
local Buy = require(Shared.BallPurchases)
local Snapshot = require(game.ServerScriptService.Server.Gameplay.Snapshot)
local Commands = require(game.ServerScriptService.Server.Gameplay.Commands)
local player = assert(game.Players:GetPlayers()[1])
local count = 0
local function check(ok: boolean, message: string)
	assert(ok, message)
	count += 1
end
local data = Data.fresh()
data.wins = 1000
data.skill = 20000
data.petMaterial = 20
data.pets = { { uid = "fixture", id = "Cactus", name = "Cactus", rarity = "Common", boost = 1.15 } }
local state: any = {
	data = data,
	inventoryVersion = 1,
	busyUntil = 0,
	joined = os.clock(),
	gifts = {},
	friends = 0,
	tokens = 12,
	lastAction = os.clock(),
}
local states = { [player] = state }
local context: any = {
	states = states,
	multiplier = function(s: any)
		return Config.Balance.trainingMultiplier(s.data, Buy.trainingBonus(s.data))
	end,
	inKickZone = function()
		return false
	end,
	arenaFor = function()
		return require(Shared.WorldRefs).world(1)
	end,
}
local before = Snapshot.build(context, player)
check(Buy.buyOrEquip(data, "Smooth"), "Buy fixture ball")
local after = Snapshot.build(context, player)
check(after.shotDistance == before.shotDistance, "Ball does not directly affect flight distance")
check(after.multiplier > before.multiplier and Buy.trainingBonus(data) == 2, "Ball adds training bonus")
check(Config.shotDistance(20000, 1.35, 1) < Config.shotLimit(1, nil), "Perfect cannot skip World1")
local total = 0
for _, pet in Config.RainbowPets do
	total += pet.weight
end
check(total == 10000 and Config.RainbowPets[5].weight / total * 100 == 0.05, "Exact Secret odds")
check(Config.rollEggPet("Rainbow", 10000).id == "EclipseCat", "Secret boundary rolls correctly")
check(Config.rebirthRequirement(0) == 50000 and Config.rebirthRequirement(1) == 80000, "Rebirth costs unchanged")
check(Config.Lanes[7].multiplier == 64 and Config.Lanes[7].rebirths == 16, "Lane progression unchanged")
local events: { any } = {}
local callback: any
context.action = { OnServerEvent = {
	Connect = function(_, fn)
		callback = fn
	end,
} }
context.effect = {
	FireClient = function(_, _, kind, info)
		table.insert(events, { kind = kind, info = info })
	end,
}
context.publish = function() end
context.claimPending = function() end
context.kickTiming = { cancel = function() end }
Commands.install(context)
state.purchasePolicyReady = true
state.paidRandomRestricted = false
callback(player, "MutatePet", "fixture", 0)
check(data.petMaterial == 10 and data.pets[1].mutation ~= nil, "Server mutation spends exact cost")
callback(player, "RecyclePet", "fixture")
check(data.petMaterial == 11 and #data.pets == 0, "Server recycle grants material")
callback(player, "RecyclePet", "fixture")
check(data.petMaterial == 11, "Replayed recycle cannot pay twice")
callback(player, "ClaimChallenge", "first-kick")
check(not data.challengeClaims["1:first-kick"], "Unfinished challenge cannot be claimed")
data.challengeProgress["1:first-kick"] = 1
callback(player, "ClaimChallenge", "first-kick")
local wins = data.wins
callback(player, "ClaimChallenge", "first-kick")
check(data.wins == wins and data.challengeClaims["1:first-kick"], "Challenge pays once")
check(#events == 6, "Server sends confirmed feedback for all transactions")
return { checks = count, source = "isolated Commands and Snapshot contexts", profileWrites = 0 }
