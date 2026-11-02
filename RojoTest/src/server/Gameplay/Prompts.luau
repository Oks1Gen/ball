--!strict
-- World interaction prompts: the eggs, the item stands and
-- the admin egg. Every handler checks that the player really is in the arena
-- that owns the prompt.
-- A prop that is missing from the map is reported and skipped: the install
-- must never raise, or the whole server would start without a single session.
local Prompts = {}
local WorldRefs = require(game.ReplicatedStorage.Shared.WorldRefs)

export type Context = {
	states: { [Player]: any },
	Config: any,
	effect: RemoteEvent,
	publish: (Player, string?) -> (),
	stopTraining: (Player, boolean?) -> (),
	arenaFor: (Player) -> any,
	rootFor: (Player) -> (any, any),
}

function Prompts.install(context: Context, map: any)
	for _, arena in { map } do
		local label = "World1"
		local scenery = WorldRefs.eggs(arena)
		if not scenery then
			warn("[Ball] " .. label .. " has no EggShop")
			continue
		end
		for _, egg in context.Config.Eggs do
			local eggModel = scenery:FindFirstChild("Egg_" .. egg.id)
			local shell = eggModel and eggModel:FindFirstChild("EggShell")
			local prompt = shell and shell:FindFirstChildWhichIsA("ProximityPrompt", true)
			if not prompt then
				warn("[Ball] " .. label .. " has no prompt for the egg " .. egg.id)
				continue
			end
			prompt.Triggered:Connect(function(player)
				if context.states[player] and context.arenaFor(player) == arena then
					context.effect:FireClient(player, "Egg", egg.id)
				end
			end)
		end
		local stand = WorldRefs.balls(arena)
		if not stand then
			warn("[Ball] " .. label .. " has no BallShop")
		else
			for _, p in stand:GetDescendants() do
				if p:IsA("ProximityPrompt") and p:GetAttribute("BallId") then
					p.Triggered:Connect(function(player)
						if context.states[player] and context.arenaFor(player) == arena then
							local root = context.rootFor(player)
							if root and (root.Position - p.Parent.Position).Magnitude <= 15 then
								context.effect:FireClient(player, "OpenBall", p:GetAttribute("BallId"))
							end
						end
					end)
				end
			end
		end
		local volcanic = WorldRefs.volcanic(arena)
		local adminEgg = volcanic
			and (volcanic:FindFirstChild("InteractionAnchor") or volcanic:FindFirstChild("HackedAdminEgg"))
		local adminPrompt = adminEgg and adminEgg:FindFirstChildWhichIsA("ProximityPrompt", true)
		if not adminPrompt then
			warn("[Ball] " .. label .. " has no admin egg prompt")
		else
			adminPrompt.Triggered:Connect(function(player)
				if context.states[player] and context.arenaFor(player) == arena then
					context.effect:FireClient(player, "AdminEgg", {})
				end
			end)
		end
	end
end

return Prompts
