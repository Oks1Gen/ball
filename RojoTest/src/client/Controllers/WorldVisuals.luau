--!strict
-- World side visuals: the portal beams, the water caustics and the ball stands.
-- Every value here is written per frame, so the collections are cached and the
-- transparency and the camera state only change when they really change.
local CollectionService = game:GetService("CollectionService")
local BallVisuals = require(game.ReplicatedStorage.Shared.BallVisuals)

local World = {}

export type Context = {
	effects: () -> boolean,
	rebirths: () -> number?,
	ownedBalls: () -> { [string]: boolean }?,
}

export type Handle = {
	frame: () -> (),
	lane: (number, number) -> any,
	destroy: () -> (),
}

function World.mount(context: Context): Handle
	local portalBeams: { BasePart } = {}
	local waterTextures: { Texture } = {}
	local standPreviews: { Instance } = CollectionService:GetTagged("BallStandPreview")
	local mapCache: { [number]: any } = {}
	local laneCache: { [string]: { instance: any, found: boolean, retryAt: number } } = {}
	local signs: { [Instance]: { RBXScriptConnection } } = {}
	local lastRebirths: number? = nil
	local lastOwned: { [string]: boolean }? = nil
	local function updateSign(gui: Instance)
		local status = gui:FindFirstChild("Status")
		if not status or not status:IsA("TextLabel") then
			return
		end
		local id = gui:GetAttribute("BallId")
		local unlocked: boolean
		if typeof(id) == "string" then
			local owned = context.ownedBalls()
			if not owned then
				return
			end
			unlocked = owned[id] == true
		else
			local rebirths = context.rebirths()
			local required = gui:GetAttribute("RequiredRebirths")
			if rebirths == nil or typeof(required) ~= "number" then
				return
			end
			unlocked = rebirths >= required
		end
		local wanted = if unlocked then "UNLOCKED" else "LOCKED"
		if status.Text ~= wanted then
			status.Text = wanted
			status.TextColor3 = if unlocked then Color3.fromRGB(55, 255, 35) else Color3.fromRGB(255, 44, 44)
		end
	end
	local function addSign(gui: Instance)
		if signs[gui] or not gui:IsA("BillboardGui") then
			return
		end
		signs[gui] = {
			gui.ChildAdded:Connect(function()
				updateSign(gui)
			end),
			gui:GetAttributeChangedSignal("RequiredRebirths"):Connect(function()
				updateSign(gui)
			end),
			gui:GetAttributeChangedSignal("BallId"):Connect(function()
				updateSign(gui)
			end),
		}
		updateSign(gui)
	end
	local function removeSign(gui: Instance)
		local connections = signs[gui]
		if connections then
			for _, connection in connections do
				connection:Disconnect()
			end
			signs[gui] = nil
		end
	end
	local signAdded = CollectionService:GetInstanceAddedSignal("TrainingLaneSign"):Connect(addSign)
	local signRemoved = CollectionService:GetInstanceRemovedSignal("TrainingLaneSign"):Connect(removeSign)
	for _, gui in CollectionService:GetTagged("TrainingLaneSign") do
		addSign(gui)
	end
	local ballSignAdded = CollectionService:GetInstanceAddedSignal("BallStandSign"):Connect(addSign)
	local ballSignRemoved = CollectionService:GetInstanceRemovedSignal("BallStandSign"):Connect(removeSign)
	for _, gui in CollectionService:GetTagged("BallStandSign") do
		addSign(gui)
	end

	local standAdded = CollectionService:GetInstanceAddedSignal("BallStandPreview"):Connect(function(instance: Instance)
		table.insert(standPreviews, instance)
	end)
	local standRemoved = CollectionService:GetInstanceRemovedSignal("BallStandPreview")
		:Connect(function(instance: Instance)
			for i, item in standPreviews do
				if item == instance then
					table.remove(standPreviews, i)
					break
				end
			end
		end)

	task.spawn(function()
		for _, name in { "World1", "World2" } do
			local map: any = workspace:WaitForChild("Map"):WaitForChild(name)
			local world: any = map:WaitForChild("SkippingWorld")
			for _, part in world.World2Portal:GetChildren() do
				if part:IsA("BasePart") and part:GetAttribute("AnimatedPortal") then
					table.insert(portalBeams, part)
				end
			end
			for _, part in world:GetChildren() do
				local texture = part:FindFirstChild("WaterCaustics")
				if texture and texture:IsA("Texture") and not part:GetAttribute("FootballPitch") then
					table.insert(waterTextures, texture)
				end
			end
		end
	end)

	-- The lane is looked up once per world and lane number: the string
	-- concatenation and the tree search do not belong in the frame loop.
	-- A miss is not final: the map or the zone can still be streaming in, so
	-- a negative result is kept only until the next retry.
	local LANE_RETRY = 1

	local function trainingLane(world: number, index: number): any
		local key = world .. ":" .. index
		local cached = laneCache[key]
		if cached then
			if cached.found and cached.instance and cached.instance.Parent then
				return cached.instance
			end
			if not cached.found and cached.retryAt > os.clock() then
				return nil
			end
			-- The lane left the tree or the miss is stale, look it up again.
			laneCache[key] = nil
		end
		local map = mapCache[world]
		if map == nil or not map.Parent then
			map = (
				workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild(world == 2 and "World2" or "World1")
			)
			mapCache[world] = map
		end
		local found: any = nil
		if map then
			local zone = map:FindFirstChild("TrainingZone")
			found = zone and zone:FindFirstChild("TrainingLane" .. index)
		end
		if found == nil then
			laneCache[key] = { instance = nil, found = false, retryAt = os.clock() + LANE_RETRY }
		else
			laneCache[key] = { instance = found, found = true, retryAt = 0 }
		end
		return found
	end

	local function updateStands()
		local camera = workspace.CurrentCamera
		for _, model in standPreviews do
			if model:IsA("Model") and model:IsDescendantOf(workspace) then
				local base = model:GetAttribute("DisplayBasePivot")
				if base and camera and (camera.CFrame.Position - base.Position).Magnitude < 250 then
					local pose, bob = BallVisuals.standPose(
						base,
						workspace:GetServerTimeNow(),
						(model:GetAttribute("DisplaySlot") or 1) * 0.55
					)
					model:PivotTo(pose)
					local link = model:FindFirstChild("DisplayLabel")
					local labelBase = model:GetAttribute("DisplayLabelBase")
					if link and link:IsA("ObjectValue") and link.Value and labelBase then
						link.Value.Position = labelBase + Vector3.new(0, bob, 0)
					end
				end
			end
		end
	end

	return {
		frame = function()
			local now = os.clock()
			local rebirths = context.rebirths()
			local owned = context.ownedBalls()
			if rebirths ~= lastRebirths or owned ~= lastOwned then
				lastRebirths = rebirths
				lastOwned = owned
				for gui in signs do
					updateSign(gui)
				end
			end
			local effectsOn = context.effects()
			for i, beam in portalBeams do
				beam.Transparency = effectsOn and (0.2 + 0.5 * (0.5 + 0.5 * math.sin(now * 4 + i))) or 0.7
			end
			for _, texture in waterTextures do
				texture.OffsetStudsU = now * 0.45
				texture.OffsetStudsV = now * 0.25
			end
			updateStands()
		end,
		lane = trainingLane,
		destroy = function()
			standAdded:Disconnect()
			standRemoved:Disconnect()
			signAdded:Disconnect()
			signRemoved:Disconnect()
			ballSignAdded:Disconnect()
			ballSignRemoved:Disconnect()
			for gui in signs do
				removeSign(gui)
			end
			portalBeams = {}
			waterTextures = {}
			standPreviews = {}
		end,
	}
end

return World
