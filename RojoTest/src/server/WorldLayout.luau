--!strict
-- Reversible compiler from the historical builders to the scene contract.
-- No geometry is cloned, destroyed, repositioned or given different physics.
local Layout = {}
local Storage = game:GetService("ServerStorage")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)

-- Pin the owning display pivot and store animation origins in its local frame.
-- Moving/rotating a whole shop must not let the client snap its balls back.
function Layout.bindDisplays(world: any)
	local shop = world.Lobby.BallShop
	for _, display in shop.Displays:GetChildren() do
		if display:IsA("Model") then
			display.WorldPivot = display:GetPivot()
			local ball = display:FindFirstChild("Ball")
			local base = ball and ball:GetAttribute("DisplayBasePivot")
			local label = ball and ball:GetAttribute("DisplayLabelBase")
			local top = display:FindFirstChild("DisplayTop")
			if ball and top and top:IsA("BasePart") and typeof(base) == "CFrame" and typeof(label) == "Vector3" then
				ball:SetAttribute("DisplayBaseLocal", top.CFrame:ToObjectSpace(base))
				ball:SetAttribute("DisplayLabelLocal", top.CFrame:PointToObjectSpace(label))
			end
		end
	end
	shop.WorldPivot = shop:GetPivot()
end

local function folder(parent: Instance, name: string): any
	local value: any = parent:FindFirstChild(name)
	if not value then
		value = Instance.new("Folder")
		value.Name, value.Parent = name, parent
	end
	return value
end

local function state(world: Instance): any
	return folder(folder(Storage, "WorldLayoutState"), world.Name)
end

-- Original instances and parents are kept as references, never string paths.
-- This also restores external imported previews before old builders run again.
function Layout.prepare(world: any)
	local s = state(world)
	local moveFolder = folder(s, "Moves")
	if world:GetAttribute("WorldLayoutVersion") == 1 then
		assert(
			#moveFolder:GetChildren() > 0,
			"WorldLayout journal is missing; restore the complete place before building"
		)
	end
	for _, ref in moveFolder:GetChildren() do
		assert(ref:IsA("ObjectValue") and ref:FindFirstChild("ParentRef"), "Invalid WorldLayout journal")
	end
	world:SetAttribute("WorldLayoutReady", false)
	local containers = folder(s, "Containers")
	local parked = folder(s, "Parked")
	for _, ref in containers:GetChildren() do
		if ref.Value then
			ref.Value.Parent = parked
		end
	end
	local moves = moveFolder:GetChildren()
	table.sort(moves, function(a, b)
		return (a:GetAttribute("Order") or 0) > (b:GetAttribute("Order") or 0)
	end)
	for i, ref in moves do
		local node, parent = ref.Value, ref.ParentRef.Value
		-- Removed skins can leave a destroyed-instance reference in a saved journal.
		-- Every live source/container is parented in Workspace or ServerStorage.
		if node and parent and node.Parent and parent:IsDescendantOf(game) then
			node.Name = ref:GetAttribute("OriginalName")
			node.Parent = parent
		end
		ref:Destroy()
		if i % 500 == 0 then
			task.wait()
		end
	end
	world:SetAttribute("WorldLayoutVersion", nil)
end

function Layout.apply(world: any)
	if world:GetAttribute("WorldLayoutReady") == true then
		return
	end
	local s = state(world)
	local moves, containers = folder(s, "Moves"), folder(s, "Containers")
	local sources, retired = folder(s, "Sources"), folder(s, "RetiredVisuals")
	-- Reparenting render/collision children must not change an existing prop's
	-- implicitly computed pivot (used by goal gates and movable authored props).
	for _, node in world:GetDescendants() do
		if node:IsA("Model") then
			node.WorldPivot = node:GetPivot()
		end
	end
	local seen: { [Instance]: boolean } = {}
	local order = #moves:GetChildren()
	local function move(node: any, parent: Instance, name: string?)
		if node.Parent == parent and (not name or node.Name == name) then
			return
		end
		if not seen[node] then
			order += 1
			local ref = Instance.new("ObjectValue")
			ref.Name, ref.Value = tostring(order), node
			ref:SetAttribute("Order", order)
			ref:SetAttribute("OriginalName", node.Name)
			local origin = Instance.new("ObjectValue")
			origin.Name, origin.Value, origin.Parent = "ParentRef", node.Parent, ref
			ref.Parent = moves
			seen[node] = true
		end
		node.Parent = parent
		if name then
			node.Name = name
		end
	end
	local function group(parent: Instance, name: string, class: string?): any
		local key: any = parent:GetAttribute("LayoutKey") or parent:GetAttribute("LayoutOwnerId")
		if not key then
			key = game:GetService("HttpService"):GenerateGUID(false)
			parent:SetAttribute("LayoutOwnerId", key)
		end
		key ..= "/" .. name
		local ref = containers:FindFirstChild(key)
		local node = ref and ref.Value
		if not node then
			node = Instance.new(class or "Folder")
			node.Name = name
			node:SetAttribute("LayoutKey", key)
			ref = Instance.new("ObjectValue")
			ref.Name, ref.Value, ref.Parent = key, node, containers
		end
		node.Parent = parent
		return node
	end
	local lobby = assert(world:FindFirstChild("Lobby"), "Missing authored Lobby")
	local old = assert(world:FindFirstChild("SkippingWorld"), "Prepare layout before running legacy builders")
	local course = group(world, "FootballCourse")
	local zones = group(course, "Zones")
	local sharedEnvironment = group(course, "Environment")
	local sharedGeometry = group(course, "Geometry")
	local boundaries = group(course, "Boundaries")
	local environment = group(lobby, "Environment")
	local flowers = group(environment, "Flowers")
	local geometry = group(lobby, "Geometry")
	local paths = group(lobby, "Paths")
	local launch = group(lobby, "KickZone", "Model")
	local eggs = group(lobby, "EggShop")
	local volcanic = group(eggs, "VolcanicEgg", "Model")
	local shop = group(lobby, "BallShop", "Model")
	local structure = group(shop, "Structure")
	local displays = group(shop, "Displays")
	local fields, zoneList = {}, {}
	for i = 1, 8 do
		local field = assert(old:FindFirstChild("Field_" .. i), "Missing football field " .. i)
		fields[i] = field
		local zone = group(zones, string.format("Zone%02d", i))
		zone:SetAttribute("ZoneIndex", i)
		zone:SetAttribute("BiomeName", Config.Biomes[i].name)
		group(zone, "Environment")
		group(zone, "Geometry")
		group(zone, "Boundaries")
		zoneList[i] = zone
		move(field, zone, "Field")
	end
	local function position(node: Instance): Vector3?
		if node:IsA("BasePart") then
			return node.Position
		end
		if node:IsA("Model") and node:FindFirstChildWhichIsA("BasePart", true) then
			local cf = node:GetBoundingBox()
			return cf.Position
		end
		local low, high: Vector3? = nil, nil
		for _, part in node:GetDescendants() do
			if part:IsA("BasePart") then
				low = if low then low:Min(part.Position) else part.Position
				high = if high then high:Max(part.Position) else part.Position
			end
		end
		return if low and high then (low + high) / 2 else nil
	end
	local function owner(node: Instance, category: string): any
		local p = position(node)
		if not p then
			return if category == "Environment" then sharedEnvironment else sharedGeometry
		end
		if p.Z > fields[1].Position.Z + fields[1].Size.Z / 2 then
			return if category == "Environment" then environment else geometry
		end
		local best, distance = 1, math.huge
		for i, field in fields do
			local delta = math.abs(field.Position.Z - p.Z)
			if delta < distance then
				best, distance = i, delta
			end
		end
		return zoneList[best][category]
	end
	for _, node in lobby:GetChildren() do
		if not node:GetAttribute("LayoutKey") then
			if node.Name == "KickZoneFloor" then
				move(node, launch)
			elseif node:IsA("SpawnLocation") then
				move(node, group(lobby, "Spawns"))
			else
				move(node, geometry)
			end
		end
	end
	-- Every ball display owns its pedestal, animated ball, label and prompt.
	local stand = assert(world:FindFirstChild("EmptyItemStand"))
	local imported = world.Name == "World1" and workspace:FindFirstChild("AllBalls_NoTextures")
	local balls = imported or stand:FindFirstChild("DisplayBalls")
	for _, item in Config.Stones do
		local display = group(displays, string.format("Display%02d", item.displaySlot), "Model")
		display:SetAttribute("BallId", item.id)
		display:SetAttribute("DisplaySlot", item.displaySlot)
		for _, prefix in { "DisplayTop", "EmptyPedestal", "BallPurchase" } do
			local part = stand:FindFirstChild(prefix .. item.displaySlot)
			if part then
				local name = if prefix == "DisplayTop"
					then "DisplayTop"
					elseif prefix == "EmptyPedestal" then "Pedestal"
					else "PurchaseAnchor"
				move(part, display, name)
			end
		end
		if balls then
			for _, ball in balls:GetChildren() do
				if ball:GetAttribute("BallId") == item.id then
					local link = ball:FindFirstChild("DisplayLabel")
					if link and link:IsA("ObjectValue") and link.Value then
						move(link.Value, display, "LabelAnchor")
					end
					move(ball, display, "Ball")
				end
			end
		end
	end
	for _, node in stand:GetChildren() do
		if node ~= balls then
			move(node, structure)
		end
	end
	move(stand, sources)
	if imported then
		move(imported, sources)
	elseif balls then
		move(balls, sources)
	end
	local training = assert(world:FindFirstChild("TrainingZone"))
	move(training, world, "TrainingArea")
	local lanes = group(training, "Lanes")
	for _, node in training:GetChildren() do
		if not node:GetAttribute("LayoutKey") then
			move(node, if node:IsA("Model") then lanes else group(training, "Signs"))
		end
	end
	for _, node in old:GetChildren() do
		local name = node.Name
		if name:match("^Egg_") then
			move(node, eggs)
		elseif
			name == "HackedAdminEgg"
			or name == "HackedEggStand"
			or name == "AdminEggCaption"
			or name:match("^VolcanicEgg")
		then
			local names = {
				HackedAdminEgg = "InteractionAnchor",
				HackedEggStand = "Pedestal",
				AdminEggCaption = "Sign",
				VolcanicEggVisual = "Visual",
				VolcanicEggFallback = "Fallback",
			}
			move(node, volcanic, names[name])
		elseif name == "ImprovedLobbyFlowers" then
			for _, child in node:GetChildren() do
				move(child, flowers)
			end
			move(node, sources)
		elseif name:match("^DisplayStone_") or node:GetAttribute("BallDisplayLabelSlot") then
			-- Disabled predecessors must not remain among the active displays.
			move(node, retired)
		elseif name == "FootballPitchMarkings" then
			for _, child in node:GetChildren() do
				move(child, owner(child, "Geometry"), "PitchMarkings")
			end
			move(node, sources)
		elseif name == "LabelAnchor" then
			move(node, group(owner(node, "Geometry"), "Signs"))
		else
			move(node, owner(node, if node:IsA("Model") then "Environment" else "Geometry"))
		end
	end
	move(old, sources)
	local rootNames: { [string]: string } = {
		FieldCorridor = "Geometry",
		EnvironmentPolish = "Environment",
		NativeEnvironment = "Environment",
		GeometryPolish = "Geometry",
		SurfaceRepairs = "Geometry",
		PerimeterWalls = "Boundaries",
		CorridorBarriers = "Boundaries",
		ZoneDividers = "Boundaries",
		RiverWater = "River",
		CompactLobbyLayout = "Paths",
		TwoAxesLayout = "Paths",
		SmallMapFlowers = "Flowers",
		CornerRockGarden = "Environment",
		SpawnGarden = "Environment",
		SpawnGardenPolish = "Environment",
		TerraceChecker = "Geometry",
	}
	for name, category in rootNames do
		local source = world:FindFirstChild(name)
		if source then
			for _, node in source:GetChildren() do
				if category == "River" then
					move(node, group(sharedEnvironment, "River"))
				elseif category == "Boundaries" then
					move(node, boundaries)
				elseif category == "Flowers" then
					move(node, flowers)
				elseif category == "Paths" then
					move(node, paths)
				elseif name == "FieldCorridor" and node.Name:match("^%d%d_") then
					-- Five old structural sections span the eight current gameplay zones.
					-- Their hidden supports are course-wide; complete scenery belongs to a zone.
					for _, child in node:GetChildren() do
						if child:IsA("Model") then
							move(child, owner(child, "Environment"))
						end
					end
					move(node, group(sharedGeometry, "BankSupport"), "Section" .. node.Name:sub(1, 2))
				elseif
					(name == "EnvironmentPolish" and node.Name:match("^Biome%d$"))
					or (name == "NativeEnvironment" and (node.Name == "Trees" or node.Name == "ShoreGardens"))
				then
					-- Classify each complete prop, never the bounding-box centre of a map-wide bucket.
					for _, detail in node:GetChildren() do
						if detail:IsA("Model") then
							detail:SetAttribute("CourseNaturalDetail", true)
						end
						move(detail, owner(detail, "Environment"))
					end
					move(node, sources)
				else
					move(node, owner(node, category))
				end
			end
			move(source, sources)
		end
	end
	local rankings = world:FindFirstChild("LobbyRankings")
	if rankings then
		move(rankings, lobby, "Leaderboards")
	end
	-- Imported reference packs are source assets, never live map sections.
	if world.Name == "World1" then
		local library = folder(Storage, "AssetLibrary")
		local names: { [string]: string } = {
			DecoratedEggs15 = "DecoratedEggs",
			Eggs6_Simple = "SimpleEggs",
			pets36 = "PetPack36",
			["football-no-textures"] = "Football",
			["portals-v6-no-textures"] = "Portals",
			["sakura-no-textures"] = "Sakura",
		}
		for sourceName, name in names do
			local source = workspace:FindFirstChild(sourceName)
			if source then
				move(source, library, name)
			end
		end
		local loose = workspace:FindFirstChild("Part")
		if loose and loose:IsA("BasePart") then
			loose:SetAttribute("NeedsNamingReview", true)
			move(loose, geometry, "UnclassifiedBlock")
		end
	end
	-- Put each cosmetic correction back with the part it depicts. Keep a
	-- collidable original locally; park only inert replaced visual originals.
	local separation = world:FindFirstChild("SurfaceSeparation")
	if separation then
		for i, render in separation:GetChildren() do
			local link = render:FindFirstChild("OriginalPart")
			local original = link and link:IsA("ObjectValue") and link.Value
			if original and original:IsA("BasePart") and original:IsDescendantOf(world) then
				local parent = original.Parent :: Instance
				move(render, parent)
				local semantic = original.Name == "Field"
					or original.Name == "KickZoneFloor"
					or original.Name == "StartingPad"
					or original.Name == "TrainingStrip"
					or original.Name == "DisplayTop"
					or original:IsA("SpawnLocation")
					or original:FindFirstChildWhichIsA("SurfaceGui") ~= nil
					or original:FindFirstChildWhichIsA("BillboardGui") ~= nil
					or original:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
				if semantic then
					move(render, parent, original.Name .. "Visual")
				elseif original.CanCollide or original.CanTouch or original.CanQuery then
					move(original, group(parent, "Collision"))
				else
					move(original, retired)
				end
			elseif original and not original:IsDescendantOf(world) then
				move(render, retired)
			end
			if i % 250 == 0 then
				task.wait()
			end
		end
		move(separation, sources)
	end
	for i, node in world:GetDescendants() do
		if node:IsA("BasePart") and node.Transparency == 1 then
			local role = if node:FindFirstChildWhichIsA("BillboardGui")
				then "LabelAnchor"
				elseif node:FindFirstChildWhichIsA("ProximityPrompt", true) then "InteractionAnchor"
				elseif node.CanCollide then "Collision"
				elseif node.CanTouch then "Trigger"
				elseif node.CanQuery then "QueryVolume"
				else "HiddenVisual"
			node:SetAttribute("PartRole", role)
		end
		if i % 2000 == 0 then
			task.wait()
		end
	end
	Layout.bindDisplays(world)
	world:SetAttribute("WorldLayoutVersion", 1)
	world:SetAttribute("WorldLayoutReady", true)
end

return Layout
