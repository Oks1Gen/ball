--!strict
local HttpService = game:GetService("HttpService")
local Timing = require(game.ReplicatedStorage.Shared.Core.KickTiming)
local KickTiming = {}

function KickTiming.build(context: any)
	local function cancel(player: Player)
		local s = context.states[player]
		if s and s.kickTiming then
			s.kickTiming = nil
			context.effect:FireClient(player, "KickCancelled")
		end
	end
	local function valid(player: Player, s: any): boolean
		local pending = s.kickTiming
		local root, hum = context.rootFor(player)
		return pending ~= nil
			and pending.character == player.Character
			and pending.data == s.data
			and pending.world == s.data.world
			and root ~= nil
			and hum ~= nil
			and hum.Health > 0
			and context.inApron(player)
			and os.clock() >= s.busyUntil
			and not s.lane
	end
	return {
		cancel = cancel,
		validate = function(player: Player)
			local s = context.states[player]
			if s and s.kickTiming and not valid(player, s) then
				cancel(player)
			end
		end,
		begin = function(player: Player)
			local s = context.states[player]
			if not s or s.kickTiming then
				return
			end
			local root, hum = context.rootFor(player)
			if not root or not hum or hum.Health <= 0 or s.lane or os.clock() < s.busyUntil then
				context.effect:FireClient(player, "KickCancelled")
				return
			end
			if not context.inApron(player) then
				context.effect:FireClient(player, "KickCancelled")
				context.publish(player, "Go to the yellow THROW ZONE")
				return
			end
			local pending = {
				token = HttpService:GenerateGUID(false),
				startedAt = workspace:GetServerTimeNow() + math.clamp(player:GetNetworkPing(), 0.05, 0.25),
				character = player.Character,
				data = s.data,
				world = s.data.world,
			}
			s.kickTiming = pending
			context.effect:FireClient(player, "KickReady", { token = pending.token, startedAt = pending.startedAt })
		end,
		release = function(player: Player, token: string, pressedAt: number)
			local s = context.states[player]
			if not s or not s.kickTiming or s.kickTiming.token ~= token then
				return
			end
			local pending = s.kickTiming
			local now = workspace:GetServerTimeNow()
			local allowance = math.clamp(player:GetNetworkPing() * 2 + 0.15, 0.2, 1)
			if not valid(player, s) or not Timing.validRelease(pending.startedAt, pressedAt, now, allowance) then
				cancel(player)
				return
			end
			-- Consume before throwing: duplicate/replayed releases cannot create a shot.
			s.kickTiming = nil
			local height = Timing.height(pressedAt - pending.startedAt)
			context.throw(player, nil, Timing.multiplier(height))
		end,
	}
end

return KickTiming
