--!strict
-- Retire loose lobby dressing without rebuilding the authored map.
local Removal = {}
local STRUCTURE = { SideTerraces1 = true, SideTerraces2 = true, RearTerraces = true }
local ENTRANCE = {
	Collision = true,
	LeftAbutment = true,
	RightAbutment = true,
	LeftAbutmentGrassCap = true,
	RightAbutmentGrassCap = true,
	BankSafetyFloor1 = true,
	BankSafetyFloor2 = true,
	RearOuterGuard = true,
	LeftOuterGuard = true,
	RightOuterGuard = true,
	UpperTier = true,
	WallCladding = true,
}
local WATER = { StreamWater = true, PoolWater = true, PoolRim = true, WaterLip = true }
local INPUTS = { LobbyGardens = true, LobbyAccents = true }

function Removal.plan(world: any): any
	local lobby = world.Lobby
	local storage = game:GetService("ServerStorage")
	local state = storage:FindFirstChild("WorldLayoutState")
	local journal = state and state:FindFirstChild(world.Name)
	local moves = journal and journal:FindFirstChild("Moves")
	local targets, inputs = {}, {}
	local dead: { [Instance]: boolean } = {}
	local function add(target: Instance)
		if dead[target] then
			return
		end
		table.insert(targets, target)
		dead[target] = true
		for _, child in target:GetDescendants() do
			dead[child] = true
		end
	end
	for _, owner in lobby.Environment:GetChildren() do
		if STRUCTURE[owner.Name] then
			continue
		elseif owner.Name == "EntranceTunnel" then
			for _, child in owner:GetChildren() do
				if not ENTRANCE[child.Name] then
					add(child)
				end
			end
		elseif owner.Name == "CornerWaterfall1" or owner.Name == "SideWaterfall" then
			for _, child in owner:GetChildren() do
				if not WATER[child.Name] and not child.Name:match("^VFX_Waterfall") then
					add(child)
				end
			end
		elseif owner.Name == "Flowers" or INPUTS[owner.Name] then
			for _, child in owner:GetChildren() do
				add(child)
			end
			if INPUTS[owner.Name] then
				local parent: Instance? = nil
				if moves then
					for _, ref in moves:GetChildren() do
						if ref:IsA("ObjectValue") and ref.Value == owner then
							local origin = ref:FindFirstChild("ParentRef") :: ObjectValue?
							parent = origin and origin.Value
						end
					end
				end
				assert(parent and parent:IsDescendantOf(storage), "Missing legacy decoration input parent")
				table.insert(inputs, { root = owner, parent = parent })
			end
		else
			add(owner)
		end
	end
	for _, owner in lobby.Paths:GetChildren() do
		if
			owner.Name == "LawnTrees"
			or ((owner.Name == "Paving" or owner.Name == "Borders") and #owner:GetChildren() == 0)
		then
			add(owner)
		end
	end
	-- SurfaceSeparation originals are not independent scenery; retire them with their render.
	local originals = {}
	for node in dead do
		if node:IsA("ObjectValue") and node.Name == "OriginalPart" and node.Value then
			table.insert(originals, node.Value)
		end
	end
	for _, original in originals do
		add(original)
	end
	local parts = 0
	for node in dead do
		assert(
			not node:IsA("LuaSourceContainer") and not node:IsA("ProximityPrompt") and not node:IsA("ClickDetector"),
			"Gameplay inside lobby decoration"
		)
		assert(
			not node:IsA("Beam") and not node:IsA("Trail") and not node:IsA("ParticleEmitter"),
			"Preserve lobby effects"
		)
		if node:IsA("BasePart") then
			assert(
				node.Anchored and not node.CanCollide and not node.CanTouch and not node.CanQuery,
				"Decoration has physics: " .. node:GetFullName()
			)
			parts += 1
		end
	end
	-- Journal/provenance and archived backups are bookkeeping, not gameplay dependencies.
	local backups = storage:FindFirstChild("WorldBackups")
	for _, node in game:GetDescendants() do
		if node:IsA("ObjectValue") and node.Value and dead[node.Value] and not dead[node] then
			assert(
				(state and node:IsDescendantOf(state)) or (backups and node:IsDescendantOf(backups)),
				"External reference to decoration: " .. node:GetFullName()
			)
		end
	end
	return { targets = targets, dead = dead, inputs = inputs, parts = parts, moves = moves, journal = journal }
end

function Removal.apply(world: any): any
	local plan = Removal.plan(world)
	local ids: { [number]: boolean } = {}
	for node in plan.dead do
		local id = node:GetAttribute("SurfaceSeparationId")
		if typeof(id) == "number" then
			ids[id] = true
		end
	end
	local sources = plan.journal and plan.journal:FindFirstChild("Sources")
	local separation = world:FindFirstChild("SurfaceSeparation")
		or (sources and sources:FindFirstChild("SurfaceSeparation"))
	if separation then
		for id in tostring(separation:GetAttribute("RetiredRecordIds") or ""):gmatch("%d+") do
			ids[tonumber(id) :: number] = true
		end
		local list = {}
		for id in ids do
			table.insert(list, id)
		end
		table.sort(list)
		separation:SetAttribute("RetiredRecordIds", table.concat(list, ","))
	end
	-- Two empty containers are still required by old generators. Keep those inputs
	-- at their original ServerStorage source, not as empty objects in the live lobby.
	local inputs: { [Instance]: boolean } = {}
	for _, entry in plan.inputs do
		entry.root.Parent = entry.parent
		inputs[entry.root] = true
	end
	if plan.moves then
		for _, ref in plan.moves:GetChildren() do
			if ref:IsA("ObjectValue") and ref.Value and (plan.dead[ref.Value] or inputs[ref.Value]) then
				ref:Destroy()
			end
		end
	end
	for _, target in plan.targets do
		target:Destroy()
	end
	world:SetAttribute("LobbyDecorRemoved", true)
	return { removedParts = plan.parts, removedObjects = #plan.targets, retainedSourceInputs = #plan.inputs }
end
return Removal
