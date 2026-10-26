-- Run on the Studio server during Play. Isolated state: no profile writes or real throws.
local Timing = require(game.ReplicatedStorage.Shared.Core.KickTiming)
local Handler = require(game.ServerScriptService.Server.Gameplay.KickTiming)
local player = game.Players:GetPlayers()[1]
assert(player, "Run in Play with one player")
local state = { data = { world = 1 }, busyUntil = 0 }
local events, throws = {}, {}
local perfectCounts = {}
local inside = true
local health = 100
local handler = Handler.build({
	states = { [player] = state },
	rootFor = function()
		return {}, { Health = health }
	end,
	inApron = function()
		return inside
	end,
	publish = function() end,
	effect = {
		FireClient = function(_, _, kind, payload)
			table.insert(events, { kind = kind, payload = payload })
		end,
	},
	throw = function(_, _, multiplier, count)
		table.insert(throws, multiplier)
		table.insert(perfectCounts, count)
	end,
})
local checks = 0
local function check(value, message)
	assert(value, message)
	checks += 1
end
local function lockPower(elapsed)
	handler.begin(player)
	local pending = state.kickTiming
	pending.startedAt = workspace:GetServerTimeNow() - elapsed
	handler.release(player, pending.token, workspace:GetServerTimeNow())
	return pending
end

handler.begin(player)
local pending = state.kickTiming
check(pending.stage == "power", "Starts with original power meter")
pending.startedAt = workspace:GetServerTimeNow() - 0.8
local oldToken = pending.token
handler.release(player, oldToken, pending.startedAt + 0.8)
check(#throws == 0, "First press never launches a shot")
check(pending.stage == "accuracy" and events[#events].kind == "KickAccuracyReady", "Server advances to accuracy")
check(events[#events].payload.perfectPower == true, "Power-stage camera cue is server confirmed")
check(pending.power > 1.99, "Power multiplier stays locked")
local secondToken = pending.token
check(secondToken ~= oldToken, "Each stage has its own token")
handler.release(player, oldToken, workspace:GetServerTimeNow())
check(state.kickTiming == pending and #throws == 0, "Replayed first press ignored")
pending.startedAt = workspace:GetServerTimeNow() - 1
handler.release(player, secondToken, pending.startedAt + 1)
check(#throws == 1 and math.abs(throws[1] - Timing.MaxCombined) < 1e-6, "Both stages produce maximum six")
check(perfectCounts[1] == 2, "Server confirms double perfect independently of product")
handler.release(player, secondToken, workspace:GetServerTimeNow())
check(#throws == 1, "Second-stage replay cannot duplicate the shot")

pending = lockPower(0)
pending.startedAt = workspace:GetServerTimeNow()
handler.release(player, pending.token, pending.startedAt)
check(#throws == 2 and math.abs(throws[2] - Timing.MinCombined) < 1e-4, "Weak shots multiply to one quarter")
check(perfectCounts[2] == 0, "Weak shot has no perfect accent")

lockPower(0.4)
inside = false
handler.validate(player)
check(state.kickTiming == nil, "Leaving the apron cancels accuracy")
inside = true
lockPower(0.4)
health = 0
handler.validate(player)
check(state.kickTiming == nil, "Death cancels accuracy")
health = 100
pending = lockPower(0.4)
state.data.world = 2
handler.release(player, pending.token, workspace:GetServerTimeNow())
check(state.kickTiming == nil and #throws == 2, "World change rejects second press")
state.data.world = 1
pending = lockPower(0.4)
handler.release(player, pending.token, pending.startedAt - 0.01)
check(state.kickTiming == nil and #throws == 2, "Second press cannot predate its start")
pending = lockPower(0.4)
handler.cancel(player)
handler.release(player, pending.token, workspace:GetServerTimeNow())
check(state.kickTiming == nil and #throws == 2, "Cancelled accuracy cannot launch later")
pending = lockPower(0.8)
pending.startedAt = workspace:GetServerTimeNow()
handler.release(player, pending.token, pending.startedAt)
check(perfectCounts[3] == 1 and math.abs(throws[3] - 1) < 1e-4, "Perfect power survives a weak second stage")
pending = lockPower(0)
pending.startedAt = workspace:GetServerTimeNow() - 1
handler.release(player, pending.token, pending.startedAt + 1)
check(perfectCounts[4] == 1 and math.abs(throws[4] - 1.5) < 1e-4, "Perfect accuracy survives weak power")
return { checks = checks, multipliers = throws, perfectCounts = perfectCounts }
