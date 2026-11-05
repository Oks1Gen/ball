--!strict
local Shared = game.ReplicatedStorage.Shared
local Refs = require(Shared.WorldRefs)
local Config = require(Shared.GameConfig)
local Worlds = require(Shared.Worlds)
local Spawn = require(Shared.SpawnProtocol)

local Travel = {}

local function portalPlacement(arena: Instance): (Model?, CFrame?)
	local portal = Refs.portal(arena)
	local step = portal and (portal:FindFirstChild("Step") or portal:FindFirstChild("Foundation"))
	if not portal or not step or not step:IsA("BasePart") then
		return nil, nil
	end
	local center = step.Position + step.CFrame.LookVector * (step.Size.Z / 2 + 5)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { arena }
	params.RespectCanCollide = true
	local hit = workspace:Raycast(center + Vector3.yAxis * 3, -Vector3.yAxis * 12, params)
	if not hit then
		return nil, nil
	end
	local point = Vector3.new(center.X, hit.Position.Y + 0.045, center.Z)
	return portal, CFrame.lookAt(point, point + step.CFrame.LookVector)
end

function Travel.prepare(first: Instance): Instance?
	local second = Refs.world(2)
	if not second or second:GetAttribute("OceanDepthsPreview") ~= true then
		return nil
	end
	local portal1, cf1 = portalPlacement(first)
	local portal2, cf2 = portalPlacement(second)
	if not (portal1 and cf1 and portal2 and cf2 and Refs.kickZoneFloor(second)) then
		warn("[WorldTravel] Ocean Depths needs both portals and an arrival floor")
		return nil
	end
	for index = 1, 8 do
		if not Refs.field(second, index) then
			warn("[WorldTravel] Ocean Depths is missing field " .. index)
			return nil
		end
	end
	for index, portal in { portal1, portal2 } do
		local zone = Instance.new("Part")
		zone.Name = "TravelZone"
		zone.Size = Vector3.new(14, 0.05, 10)
		zone.CFrame = if index == 1 then cf1 else cf2
		zone.Anchored, zone.CastShadow = true, false
		zone.CanCollide, zone.CanTouch, zone.CanQuery = false, false, false
		zone.Transparency = 1
		zone:SetAttribute("PartRole", "InteractionZone")
		zone:SetAttribute("Purpose", "Bounds of the world selection portal")
		zone.Parent = portal
	end
	return second
end

export type Context = {
	states: { [Player]: any },
	arenas: { [number]: any },
	rootFor: (Player) -> (BasePart?, Humanoid?),
	stopTraining: (Player, boolean?) -> (),
	publish: (Player, string?) -> (),
	save: (Player) -> boolean,
	effect: RemoteEvent,
}

function Travel.build(context: Context): (Player, number) -> ()
	return function(player, destination)
		local state = context.states[player]
		local root, humanoid = context.rootFor(player)
		local character = player.Character
		local target = context.arenas[destination]
		if not (state and character and root and humanoid and target) or state.worldTravelPending then
			return
		end
		local data = state.data
		local source = data.world
		local zone = Refs.portalZone(context.arenas[source])
		local floor = Refs.kickZoneFloor(target)
		local function canTravel(): boolean
			return context.states[player] == state
				and state.data == data
				and data.world == source
				and destination ~= source
				and player.Character == character
				and character:GetAttribute(Spawn.Ready) == true
				and humanoid.Health > 0
				and player:GetAttribute("AdminFlight") ~= true
				and player:GetAttribute("DevPreviewWorld") == nil
				and os.clock() >= state.busyUntil
				and zone ~= nil
				and Refs.insidePortal(zone, root.Position)
		end
		if not (floor and canTravel()) or os.clock() < (state.nextWorldTravel or 0) then
			return
		end
		state.nextWorldTravel = os.clock() + 0.8
		local cost = if destination == 2 and not data.oceanUnlocked then Worlds[2].cost else 0
		if data.wins < cost then
			context.publish(player, "Need " .. Config.format(cost) .. " Wins to unlock Ocean Depths")
			return
		end
		state.worldTravelPending = true
		local streamed = true
		if workspace.StreamingEnabled then
			player:AddReplicationFocus(floor)
			streamed = pcall(player.RequestStreamAroundAsync, player, floor.Position, 3)
			task.delay(1.5, function()
				if player.Parent then
					player:RemoveReplicationFocus(floor)
				end
			end)
		end
		state.worldTravelPending = nil
		if not canTravel() then
			return
		end
		if not streamed then
			context.publish(player, "The destination could not load. Try again.")
			return
		end
		if data.wins < cost then
			context.publish(player, "Need " .. Config.format(cost) .. " Wins to unlock Ocean Depths")
			return
		end
		local position = Config.kickZoneCharacterPose(target, root, humanoid, Config.KickZoneStandFromFront)
		if cost > 0 then
			data.wins -= cost
			data.oceanUnlocked = true
			if not context.save(player) then
				data.wins += cost
				data.oceanUnlocked = false
				context.publish(player, "Your world unlock could not be saved. Try again.")
				return
			end
		end
		context.stopTraining(player)
		state.blockedLane = nil
		state.auto = false
		data.world = destination
		root.CFrame = position
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		context.publish(player)
		context.effect:FireClient(player, "World", destination)
	end
end

return Travel
