--!strict
-- World interaction prompts: the eggs, the item stands and
-- the admin egg. Every handler checks that the player really is in the arena
-- that owns the prompt.
-- A prop that is missing from the map is reported and skipped: the install
-- must never raise, or the whole server would start without a single session.
local Prompts = {}
local OceanCatalog = require(game.ReplicatedStorage.Shared.OceanEggCatalog)
local WorldRefs = require(game.ReplicatedStorage.Shared.WorldRefs)
local BallPurchases = require(game.ReplicatedStorage.Shared.BallPurchases)
local Tutorial = require(game.ReplicatedStorage.Shared.Core.Tutorial)

export type Context = {
	states: { [Player]: any },
	Config: any,
	effect: RemoteEvent,
	kickTiming: any,
	publish: (Player, string?) -> (),
	stopTraining: (Player, boolean?) -> (),
	arenaFor: (Player) -> any,
	rootFor: (Player) -> (any, any),
}

function Prompts.install(context: Context, map: any, world2: Instance?)
	-- The stand buys or equips on the spot. A new ball gets the unlock reveal
	-- instead of a text notice; the price check stays in BallPurchases.
	local function buyBall(player: Player, id: any)
		local s = context.states[player]
		if type(id) ~= "string" then
			return
		end
		if os.clock() < s.busyUntil then
			context.publish(player, "Wait for your throw to finish")
			return
		end
		context.kickTiming.cancel(player)
		local owned = s.data.stones[id] == true
		local success, message = BallPurchases.buyOrEquip(s.data, id)
		if success then
			Tutorial.ball(s.data, id)
		end
		if success and not owned then
			context.publish(player)
			context.effect:FireClient(player, "BallUnlocked", id)
		else
			context.publish(player, message)
		end
	end
	local function installBalls(arena: any)
		local stand = WorldRefs.balls(arena)
		if not stand then
			warn("[Ball] " .. arena.Name .. " has no BallShop")
			return
		end
		for _, prompt in stand:GetDescendants() do
			local anchor = prompt.Parent
			if
				prompt:IsA("ProximityPrompt")
				and prompt:GetAttribute("BallId")
				and anchor
				and anchor:IsA("BasePart")
			then
				prompt.Triggered:Connect(function(player)
					local root, humanoid = context.rootFor(player)
					if
						context.states[player]
						and context.arenaFor(player) == arena
						and root
						and humanoid
						and humanoid.Health > 0
						and (root.Position - anchor.Position).Magnitude <= 15
					then
						buyBall(player, prompt:GetAttribute("BallId"))
					end
				end)
			end
		end
	end
	installBalls(map)
	if world2 then
		local source = WorldRefs.balls(map)
		local destination = WorldRefs.balls(world2)
		if source and destination then
			for _, slot in source.Displays:GetChildren() do
				local target = destination.Displays:FindFirstChild(slot.Name)
				local anchor = target and target:FindFirstChild("PurchaseAnchor")
				local prompt = slot:FindFirstChild("BallPurchasePrompt", true)
				if anchor and prompt and not anchor:FindFirstChild(prompt.Name) then
					prompt:Clone().Parent = anchor
				end
				local labelAnchor = target and target:FindFirstChild("LabelAnchor")
				local label = labelAnchor and labelAnchor:FindFirstChildWhichIsA("BillboardGui")
				if label then
					label:AddTag("BallStandSign")
				end
				local ball = target and target:FindFirstChild("Ball")
				if ball and typeof(ball:GetAttribute("DisplayBaseLocal")) == "CFrame" then
					ball:AddTag("BallStandPreview")
				end
			end
		end
		installBalls(world2)
	end
	local function eggAnchor(arena: any, id: string): BasePart?
		if id == "AdminEgg" then
			local volcanic = WorldRefs.volcanic(arena)
			return volcanic
				and (volcanic:FindFirstChild("InteractionAnchor") or volcanic:FindFirstChild("HackedAdminEgg"))
		end
		local scenery = WorldRefs.eggs(arena)
		local model = scenery and scenery:FindFirstChild("Egg_" .. id)
		return model and model:FindFirstChild("EggShell")
	end
	local function installEgg(arena: any, id: string)
		local anchor = eggAnchor(arena, id)
		local prompt = anchor and anchor:FindFirstChildWhichIsA("ProximityPrompt", true)
		if anchor and not prompt and arena ~= map then
			local source = eggAnchor(map, id)
			local template = source and source:FindFirstChildWhichIsA("ProximityPrompt", true)
			if template then
				local clone = template:Clone()
				clone.Parent = anchor
				prompt = clone
			end
		end
		if not anchor or not prompt then
			warn("[Ball] " .. arena.Name .. " has no prompt for the egg " .. id)
			return
		end
		local ocean = OceanCatalog.find(id, if arena.Name == "World2" then 2 else 1)
		if ocean then
			prompt.ObjectText = ocean.theme .. " Egg"
		end
		prompt.Triggered:Connect(function(player)
			local root, humanoid = context.rootFor(player)
			if
				context.states[player]
				and context.arenaFor(player) == arena
				and root
				and humanoid
				and humanoid.Health > 0
				and (root.Position - anchor.Position).Magnitude <= prompt.MaxActivationDistance + 2
			then
				if id == "AdminEgg" then
					context.effect:FireClient(player, "AdminEgg", {})
				else
					context.effect:FireClient(player, "Egg", id)
				end
			end
		end)
	end
	for _, arena in { map, world2 } do
		local scenery = WorldRefs.eggs(arena)
		if not scenery then
			warn("[Ball] " .. arena.Name .. " has no EggShop")
			continue
		end
		for _, egg in context.Config.Eggs do
			installEgg(arena, egg.id)
		end
		installEgg(arena, "AdminEgg")
	end
end

return Prompts
