--!strict
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Shapes = require(game.ServerStorage.CloudShapes)
local Clouds = {}
local V = Vector3.new
local VERSION = 4
local CLOUD_SCALE = 0.85

local function archive(parent: Instance, name: string): Folder
	local old = parent:FindFirstChild(name)
	if old then
		return old :: Folder
	end
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = name, parent
	return folder
end

local function cloud(parent: Instance, frame: CFrame, scale: number, variant: number, index: number, stretch: Vector3)
	local model = Instance.new("Model")
	model.Name = string.format("Cloud%03d", index)
	model:SetAttribute("CloudVariant", variant)
	model:SetAttribute("CloudStretch", stretch)
	for _, shape in Shapes[variant] do
		local part = Instance.new("Part")
		part.Name = "CloudLobe"
		part.Size = shape.size * stretch * scale
		part.CFrame = frame * CFrame.new(shape.position * stretch * scale)
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
		part.Material, part.Color = Enum.Material.SmoothPlastic, Color3.fromRGB(246, 244, 252)
		part.CastShadow = false
		part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType, mesh.Parent = Enum.MeshType.Sphere, part
		part.Parent = model
	end
	model.WorldPivot = frame
	model.Parent = parent
end

local function retire(node: Instance, destination: Instance)
	if not node:FindFirstChild("CloudSeaOriginalParent") then
		local link = Instance.new("ObjectValue")
		link.Name, link.Value, link.Parent = "CloudSeaOriginalParent", node.Parent, node
	end
	node.Parent = destination
end

function Clouds.apply(world: any): any
	local course = Refs.course(world)
	local environment = course.Environment
	local backups = archive(archive(game.ServerStorage, "WorldBackups"), "World1BeforeCloudSea")
	local river = environment:FindFirstChild("River")
	if river then
		-- Preserve the authored water and emitters, including layout journal references.
		retire(river, backups)
	end
	-- The tug was a generated water decoration; a dry dock remains represented by containers/crane.
	local dock = course.Zones.Zone04.Environment:FindFirstChild("Cityscape")
	local boat = dock and dock:FindFirstChild("HarborTug")
	if boat then
		retire(boat, backups)
	end
	local first, last = Refs.field(world, 1), Refs.field(world, 8)
	local deckY = first.Position.Y + first.Size.Y / 2
	local minX, maxX = math.huge, -math.huge
	for _, bank in course.Zones.Zone01.Geometry:GetChildren() do
		if bank:IsA("BasePart") and bank.Name:match("^BiomeBank") then
			minX = math.min(minX, bank.Position.X - bank.Size.X / 2)
			maxX = math.max(maxX, bank.Position.X + bank.Size.X / 2)
		end
	end
	assert(minX < maxX, "Missing course shoreline")
	local front = first.Position.Z + first.Size.Z / 2
	local back = last.Position.Z - last.Size.Z / 2
	local lobbyMaxX, lobbyBack = maxX, front
	for _, p in world.Lobby:GetDescendants() do
		if p:IsA("BasePart") and p.CanCollide and p.Transparency < 1 then
			minX = math.min(minX, p.Position.X - p.Size.X / 2)
			lobbyMaxX = math.max(lobbyMaxX, p.Position.X + p.Size.X / 2)
			lobbyBack = math.max(lobbyBack, p.Position.Z + p.Size.Z / 2)
		end
	end
	local signature = table.concat({
		tostring(VERSION),
		tostring(minX),
		tostring(maxX),
		tostring(lobbyMaxX),
		tostring(front),
		tostring(back),
		tostring(lobbyBack),
		tostring(deckY),
	}, ":")
	local existing = environment:FindFirstChild("CloudSea")
	if existing and existing:GetAttribute("Signature") == signature then
		return { rebuilt = false }
	end
	if existing then
		existing:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name, root.Parent = "CloudSea", environment
	local outline = {
		V(minX, 0, back),
		V(maxX, 0, back),
		V(maxX, 0, front),
		V(lobbyMaxX, 0, front),
		V(lobbyMaxX, 0, lobbyBack),
		V(minX, 0, lobbyBack),
	}
	local rng = Random.new(71481)
	local count = 0
	for edge, a in outline do
		local b = outline[edge % #outline + 1]
		local tangent = (b - a).Unit
		-- Polygon is clockwise in top-down X/Z; right-hand normal points outside.
		local outward = V(tangent.Z, 0, -tangent.X)
		local segment = Instance.new("Model")
		segment.Name = "Perimeter" .. edge
		segment.Parent = root
		local length = (b - a).Magnitude
		for layer = 1, 2 do
			-- Float rounding of a 180-stud edge must not add another cloud in Play.
			local steps = math.max(1, math.ceil(length / (if layer == 1 then 45 else 70) - 0.00001))
			for i = 0, steps - 1 do
				-- Unequal intervals and broad/low silhouettes break the repeated scalloped rim.
				-- Retain the same cloud budget and cover every side of the island.
				local along = (i + 0.5 + rng:NextNumber(-0.22, 0.22)) / steps * length
				local offset = if layer == 1 then rng:NextNumber(17, 25) else rng:NextNumber(59, 76)
				local y = deckY + (if layer == 1 then -14.6 + rng:NextNumber(-4, 2) else -32.6 + rng:NextNumber(-7, 4))
				local position = a + tangent * along + outward * offset + V(0, y, 0)
				count += 1
				cloud(
					segment,
					CFrame.fromMatrix(position, outward, V(0, 1, 0), tangent)
						* CFrame.Angles(0, rng:NextNumber(-0.25, 0.25), 0),
					CLOUD_SCALE * (if layer == 1 then rng:NextNumber(0.9, 1.15) else rng:NextNumber(1.2, 1.65)),
					rng:NextInteger(1, #Shapes),
					count,
					V(rng:NextNumber(0.9, 1.12), rng:NextNumber(0.65, 1.1), rng:NextNumber(0.9, 1.25))
				)
			end
		end
		task.wait()
	end
	root:SetAttribute("Signature", signature)
	root:SetAttribute("CloudCount", count)
	root:SetAttribute("CloudScale", CLOUD_SCALE)
	world:SetAttribute("CloudSeaVersion", VERSION)
	return { rebuilt = true, clouds = count }
end

return Clouds
