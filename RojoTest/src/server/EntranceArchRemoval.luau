--!strict
-- Opens the lobby to the course: retires the entrance arch (roof, lintels, legs, roof
-- planting, ceiling lamps and their skins) and caps the two earth abutments with grass.
-- Retired parts are kept in ServerStorage.WorldBackups and leave the layout journal and the
-- SurfaceSeparation records, so the next startup cannot restore them. docs/lobby-paths.md.
local Storage = game:GetService("ServerStorage")
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local Style = {}

local BACKUP = "BeforeArchRemoval_20261102"
local ARCH_PARTS = { TunnelRoof = true, TunnelGrassRoof = true, StoneLintel = true, StoneArchLeg = true }
local LAMP_PARTS = { CeilingLamp = true, CeilingLampHousing = true }

local function centre(node: Instance): Vector3?
	if node:IsA("BasePart") then
		return node.Position
	elseif node:IsA("Model") and node:FindFirstChildWhichIsA("BasePart", true) then
		return (node:GetBoundingBox()).Position
	end
	return nil
end

function Style.apply(world: Instance): number
	if world.Name ~= "World1" then
		return 0
	end
	local lobby = world:FindFirstChild("Lobby")
	local environment = lobby and lobby:FindFirstChild("Environment")
	local tunnel = environment and environment:FindFirstChild("EntranceTunnel")
	if not tunnel then
		return 0
	end
	local left, right = tunnel:FindFirstChild("LeftAbutment"), tunnel:FindFirstChild("RightAbutment")
	assert(left and left:IsA("BasePart") and right and right:IsA("BasePart"), "Missing arch abutments")
	-- The opening between the inner faces of the two abutments.
	local openLow = left.Position.X + left.Size.X / 2
	local openHigh = right.Position.X - right.Size.X / 2
	local roofLevel = left.Position.Y + left.Size.Y / 2 - 6.5 * Scale.factor(world)

	local retire: { Instance } = {}
	local roof = tunnel:FindFirstChild("TunnelGrassRoof")
	for _, node in tunnel:GetChildren() do
		local p = centre(node)
		-- The arch itself, plus planting and stones that stood on the roof above the opening.
		local onRoof = p ~= nil
			and node.Name ~= "ExplorerOutpost"
			and p.Y > roofLevel
			and p.X > openLow
			and p.X < openHigh
		if ARCH_PARTS[node.Name] or onRoof then
			table.insert(retire, node)
		end
	end
	local collision = tunnel:FindFirstChild("Collision")
	local roofCollision = collision and collision:FindFirstChild("TunnelRoof")
	if roofCollision then
		table.insert(retire, roofCollision)
	end
	local outpost = tunnel:FindFirstChild("ExplorerOutpost")
	if outpost then
		for _, node in outpost:GetChildren() do
			if LAMP_PARTS[node.Name] then
				table.insert(retire, node)
			end
		end
	end
	for _, node in world:GetDescendants() do
		if node:IsA("Model") and node.Name == "TunnelRoofChecker" then
			table.insert(retire, node)
		end
	end
	-- SmallMapFlowers planted pockets on the roof turf; without the roof they would float.
	local flowers = (environment :: Instance):FindFirstChild("Flowers")
	local roofLow, roofHigh = left.Position.Z - left.Size.Z / 2, left.Position.Z + left.Size.Z / 2
	if flowers then
		for _, node in flowers:GetChildren() do
			local p = centre(node)
			if p and p.Y > roofLevel and p.X > openLow and p.X < openHigh and p.Z > roofLow and p.Z < roofHigh then
				table.insert(retire, node)
			end
		end
	end
	if #retire == 0 then
		return 0
	end

	-- Grass caps keep the abutment tops green where the roof turf used to cover them.
	if roof and roof:IsA("BasePart") then
		for _, abutment in { left, right } do
			local name = abutment.Name .. "GrassCap"
			if not tunnel:FindFirstChild(name) then
				local cap = roof:Clone()
				cap.Name = name
				cap.Size = Vector3.new(abutment.Size.X, roof.Size.Y, roof.Size.Z)
				cap.CFrame = CFrame.new(abutment.Position.X, roof.Position.Y, roof.Position.Z)
				for key in cap:GetAttributes() do
					cap:SetAttribute(key, nil)
				end
				cap.Parent = tunnel
			end
		end
	end

	-- A render copy and its hidden original are retired together.
	local nodes: { [Instance]: boolean } = {}
	for _, node in retire do
		nodes[node] = true
		for _, d in node:GetDescendants() do
			if d:IsA("ObjectValue") and d.Name == "OriginalPart" then
				local link = d.Value
				if link and link:IsA("BasePart") then
					nodes[link] = true
				end
			end
		end
		local link = node:FindFirstChild("OriginalPart")
		if link and link:IsA("ObjectValue") and link.Value then
			nodes[link.Value] = true
		end
	end
	local ids = {}
	local covered: { [Instance]: boolean } = {}
	for node in nodes do
		for _, d in { node, table.unpack(node:GetDescendants()) } do
			covered[d] = true
			local id = d:GetAttribute("SurfaceSeparationId")
			if typeof(id) == "number" then
				ids[id] = true
			end
		end
	end
	local function retired(value: Instance?): boolean
		return value ~= nil and covered[value] == true
	end
	local state = Storage:FindFirstChild("WorldLayoutState")
	local journal = state and state:FindFirstChild(world.Name)
	local moves = journal and journal:FindFirstChild("Moves")
	if moves then
		for i, ref in moves:GetChildren() do
			if ref:IsA("ObjectValue") and retired(ref.Value) then
				ref:Destroy()
			end
			if i % 1000 == 0 then
				task.wait()
			end
		end
	end
	local separation = world:FindFirstChild("SurfaceSeparation")
	local sources = journal and journal:FindFirstChild("Sources")
	separation = separation or (sources and sources:FindFirstChild("SurfaceSeparation"))
	if separation then
		local list = {}
		local previous = separation:GetAttribute("RetiredRecordIds")
		for id in string.gmatch(if typeof(previous) == "string" then previous else "", "%d+") do
			ids[tonumber(id) :: number] = true
		end
		for id in ids do
			table.insert(list, id)
		end
		table.sort(list)
		separation:SetAttribute("RetiredRecordIds", table.concat(list, ","))
	end

	local backups = Storage:FindFirstChild("WorldBackups") or Instance.new("Folder")
	backups.Name, backups.Parent = "WorldBackups", Storage
	local backup = backups:FindFirstChild(BACKUP)
	if not backup then
		backup = Instance.new("Folder")
		backup.Name, backup.Parent = BACKUP, backups
	end
	local count = 0
	for node in nodes do
		if node.Parent and not node:IsDescendantOf(backup) then
			node:SetAttribute("ArchOriginalPath", (node.Parent :: Instance):GetFullName())
			node.Parent = backup
			count += 1
		end
	end
	world:SetAttribute("EntranceArchRemoved", true)
	return count
end

return Style
