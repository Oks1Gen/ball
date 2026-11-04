--!strict
-- Final course-only art pass, after the reversible legacy layout compiler.
local City = {}
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local Themes = require(game.ReplicatedStorage.Shared.FootballCity)
local Props = require(script.Parent.FootballCityProps)
local Palette = require(script.Parent.LobbyPalette)
local VERSION = 9
local V, C = Vector3.new, Color3.fromRGB
local WHITE, DARK = C(245, 246, 235), C(67, 93, 121)

local function folder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing :: Folder
	end
	local node = Instance.new("Folder")
	node.Name, node.Parent = name, parent
	return node
end

-- Keep complete retired authored objects and their origin references for rollback.
-- WorldLayout.prepare can still restore the very same instances on normal startup.
local function retire(node: Instance, archive: Instance)
	local origin = assert(node.Parent)
	local destination = folder(archive, origin.Name)
	local ref = node:FindFirstChild("FootballCityOriginalParent")
	if not ref then
		local link = Instance.new("ObjectValue")
		link.Name, link.Value, link.Parent = "FootballCityOriginalParent", origin, node
	end
	node.Parent = destination
end

local function common(ctx: any, root: Model, theme: any, index: number)
	for _, side in { -1, 1 } do
		-- These thin paving skins sit on the existing stepped banks.
		Props.paving(ctx, root, side * 66.8, 21.6, 268 * ctx.length, 3.65, theme.paving)
		local pattern = theme.pavingPattern
		Props.paving(
			ctx,
			root,
			side * 90.8,
			25.6,
			268 * ctx.length,
			8.65,
			if index <= 2 then Palette.Grass else theme.paving,
			if pattern then (if side < 0 then pattern.west else pattern.east) else nil,
			if pattern then pattern.length else nil,
			if pattern then pattern.light else nil
		)
		ctx.part(root, "TouchlineCurb", V(side * 57.1, 4.185, 0), V(0.8, 0.65, 267.4 * ctx.length), WHITE)
		for _, z in { -128, 128 } do
			local m = ctx.model(root, "TournamentPennant")
			ctx.part(m, "Pole", V(side * 99, 16, z), V(0.45, 15, 0.45), DARK)
			local flag = ctx.part(m, "Flag", V(side * 95, 21.5, z), V(7.5, 4.4, 0.25), theme.accent)
			ctx.text(flag, string.format("%02d", index))
		end
	end
	Props.goal(ctx, root, -122, WHITE)
	Props.goal(ctx, root, 122, WHITE)
end

local function field(ctx: any, root: Model, theme: any)
	for _, s in { -1, 1 } do
		Props.fence(ctx, root, s * 60, 232, 10, C(111, 134, 120))
		Props.bench(ctx, root, s * 87, if s > 0 then 24 else 0, Palette.Wood)
		for _, z in { -88, 88 } do
			Props.lamp(ctx, root, s * 94, z, 23)
			Props.tree(ctx, root, s * 90, z + (if z > 0 then -24 else 24), 0.65)
		end
	end
	Props.stand(ctx, root, -1, 0, 45, 2, C(247, 172, 48))
	Props.scoreboard(ctx, root, 88, -22, "LOCAL FOOTBALL", theme.accent)
end

local function park(ctx: any, root: Model, theme: any)
	for _, s in { -1, 1 } do
		for _, z in { -94, -46, 46, 94 } do
			Props.tree(ctx, root, s * 90, z, if math.abs(z) > 90 then 0.9 else 0.75)
		end
		Props.bench(ctx, root, s * 86, 0, Palette.Wood)
		for _, z in { -68, 68 } do
			Props.lamp(ctx, root, s * 65, z, 15)
		end
		Props.stand(ctx, root, s, 0, 37, 3, C(249, 172, 47))
	end
	local pergola = ctx.model(root, "ParkPergola")
	for _, z in { -18, 18 } do
		for _, x in { 80, 99 } do
			ctx.part(pergola, "Column", V(x, 17.5, z), V(1.3, 18, 1.3), C(164, 116, 69))
		end
	end
	for z = -22, 22, 5.5 do
		ctx.part(pergola, "RoofSlat", V(89.5, 27, z), V(24, 1.1, 2.5), C(192, 151, 97))
	end
	local sign = ctx.part(pergola, "ParkSign", V(89.5, 21, 20), V(16, 4, 0.5), C(63, 115, 78))
	ctx.text(sign, "CITY PARK", Enum.NormalId.Back)
	for _, z in { -48, 48 } do
		local target = ctx.model(root, "AccuracyTarget")
		ctx.part(target, "Target", V(-65, 7, z), V(1, 6, 7), theme.accent)
		ctx.part(target, "TargetInset", V(-64.4, 7, z), V(0.15, 2, 2), WHITE)
	end
end

local function street(ctx: any, root: Model, theme: any)
	local colors = { C(238, 115, 58), C(252, 189, 51), C(53, 171, 204), C(155, 92, 215) }
	for _, s in { -1, 1 } do
		Props.fence(ctx, root, s * 59, 234, 17, DARK)
		for j, z in { -92, -30, 38, 100 } do
			local m = Props.building(ctx, root, s * 92, z, 22, 39, 29 + (j % 3) * 10, colors[j], C(65, 184, 231))
			local wall = ctx.part(m, "StreetArt", V(s * 80.3, 17, z), V(0.2, 7, 29), theme.accent)
			ctx.text(
				wall,
				if j % 2 == 0 then "PLAY\nEVERY DAY" else "STREET FC",
				if s > 0 then Enum.NormalId.Left else Enum.NormalId.Right,
				DARK
			)
			ctx.part(m, "Awning", V(s * 79.1, 22, z), V(3.8, 1, 32), colors[j]:Lerp(DARK, 0.08))
		end
		Props.lamp(ctx, root, s * 66, 0, 25)
	end
	for _, z in { -76, 76 } do
		local rack = ctx.model(root, "StreetSeating")
		Props.bench(ctx, rack, 67, z, theme.accent)
		ctx.part(rack, "Bin", V(-66, 6, z), V(3, 5, 3), C(62, 115, 111))
	end
end

local function dock(ctx: any, root: Model, theme: any)
	for _, s in { -1, 1 } do
		for j, z in { -96, -50, 4, 54, 100 } do
			local color = if j % 2 == 0 then C(46, 157, 226) else C(241, 104, 47)
			Props.container(ctx, root, s * 89, z, 8.8, color)
			if j == 2 or j == 4 then
				Props.container(ctx, root, s * 89, z, 20.8, theme.accent)
			end
		end
		for z = -106, 106, 28 do
			ctx.part(root, "QuaySafetyMark", V(s * 63, 4.02, z), V(5, 0.15, 10), theme.accent)
		end
	end
	local crane = ctx.model(root, "HarborCrane")
	for _, x in { -100, -80 } do
		ctx.part(crane, "TowerLeg", V(x, 35, -24), V(2, 53, 2), theme.accent)
	end
	for y = 13, 53, 10 do
		ctx.beam(crane, "CrossBrace", V(-100, y, -24), V(-80, y + 10, -24), 0.8, theme.accent)
	end
	ctx.part(crane, "Jib", V(-80, 62, -24), V(44, 3, 3), theme.accent)
	ctx.part(crane, "Cab", V(-85, 58, -24), V(8, 6, 7), C(61, 112, 137))
	ctx.part(crane, "HoistCable", V(-61, 49, -24), V(0.25, 24, 0.25), DARK)
	ctx.part(crane, "Hook", V(-61, 36, -24), V(3, 3, 1), DARK)
	local boat = ctx.model(root, "HarborTug")
	ctx.part(boat, "Hull", V(118, -0.5, -48), V(19, 9, 46), C(43, 70, 86))
	ctx.part(boat, "Deck", V(118, 4.5, -48), V(18, 1, 43), C(179, 126, 76))
	ctx.part(boat, "Cabin", V(118, 9, -48), V(12, 8, 15), WHITE)
	ctx.part(boat, "Wheelhouse", V(118, 12, -48), V(12.3, 3, 15.3), C(96, 169, 184))
	ctx.part(boat, "Funnel", V(118, 17, -59), V(4, 11, 4), theme.accent)
end

local function factory(ctx: any, root: Model, theme: any)
	for _, s in { -1, 1 } do
		for _, z in { -71, 71 } do
			local m = Props.building(ctx, root, s * 90, z, 25, 75, 30, C(229, 119, 48), C(67, 191, 226))
			ctx.part(m, "SawtoothRoof", V(s * 90, 40, z), V(27, 3, 78), C(58, 137, 197))
			for dz = -28, 28, 14 do
				ctx.part(m, "RoofLight", V(s * 90, 42, z + dz), V(17, 1, 5), C(84, 216, 231))
			end
		end
		for _, z in { -112, 112 } do
			Props.lamp(ctx, root, s * 66, z, 23)
		end
		for z = -113, 113, 16 do
			ctx.part(root, "SafetyBollard", V(s * 60, 6.26, z), V(1.3, 4.8, 1.3), theme.accent)
			ctx.part(root, "BollardBand", V(s * 60, 6.5, z), V(1.5, 1, 1.5), DARK)
		end
	end
	local pipe = ctx.model(root, "ServicePipe")
	ctx.part(pipe, "PipeRun", V(-96, 46, 0), V(3, 3, 210 * ctx.length), C(138, 175, 190))
	for _, z in { 0 } do
		ctx.part(pipe, "PipeSupport", V(-96, 27, z), V(1, 38, 1), DARK)
	end
	local stack = ctx.model(root, "BrickChimney")
	ctx.part(stack, "Shaft", V(90, 39, 0), V(10, 61, 12), C(224, 105, 42))
	for y = 18, 66, 8 do
		ctx.part(stack, "BrickBand", V(90, y, 0), V(10.5, 1, 12.5), C(255, 187, 72))
	end
	Props.scoreboard(ctx, root, -85, 0, "FACTORY LEAGUE", theme.accent)
end

local function rooftop(ctx: any, root: Model, _theme: any)
	for _, s in { -1, 1 } do
		Props.fence(ctx, root, s * 59, 234, 22, C(71, 85, 111))
		for j, z in { -95, -34, 31, 96 } do
			local h = 38 + ((j + (if s > 0 then 2 else 0)) % 4) * 12
			local m = Props.building(
				ctx,
				root,
				s * 92,
				z,
				22,
				40,
				h,
				if j % 2 == 0 then C(71, 143, 222) else C(143, 87, 211),
				C(66, 205, 231)
			)
			ctx.part(m, "RooftopPlant", V(s * 92, h + 12, z), V(12, 5, 13), C(75, 131, 179))
			ctx.part(m, "Antenna", V(s * 95, h + 22, z), V(0.4, 15, 0.4), DARK)
		end
		local rail = ctx.model(root, "RooftopParapet")
		ctx.part(rail, "Parapet", V(s * 78.6, 11.24, 0), V(1, 5, 266 * ctx.length), C(202, 213, 224))
		Props.lamp(ctx, root, s * 67, 0, 30)
	end
	local billboard = ctx.model(root, "CityBillboard")
	local sign = ctx.part(billboard, "Advertisement", V(-85, 42, -1), V(2, 18, 20), C(255, 164, 49))
	ctx.text(sign, "OWN THE\nSKYLINE", Enum.NormalId.Right, DARK)
	for _, z in { -8, 6 } do
		ctx.part(billboard, "Support", V(-85, 24, z), V(1, 30.52, 1), DARK)
	end
end

local function academy(ctx: any, root: Model, theme: any)
	for _, s in { -1, 1 } do
		for _, z in { -80, 80 } do
			local m = Props.building(ctx, root, s * 90.4, z, 24, 60, 26, WHITE, C(51, 178, 227))
			ctx.part(m, "ClubStripe", V(s * 77.6, 30, z), V(0.2, 3, 59.5), theme.accent)
		end
		Props.stand(ctx, root, s, 0, 49, 3, theme.accent, true)
		for _, z in { -113, 113 } do
			Props.lamp(ctx, root, s * 97, z, 36, true)
		end
		for z = -100, 100, 25 do
			local equipment = ctx.model(root, "TrainingEquipment")
			ctx.part(equipment, "MannequinBase", V(s * 61.5, 4.11, z), V(4, 0.5, 4), DARK)
			ctx.part(equipment, "Mannequin", V(s * 61.5, 7.36, z), V(0.6, 6, 3.5), theme.accent)
			ctx.part(equipment, "MannequinHead", V(s * 61.5, 11.36, z), V(0.6, 2, 2), theme.accent)
		end
	end
	Props.scoreboard(ctx, root, 89, 0, "PRO ACADEMY", theme.accent)
end

local function stadium(ctx: any, root: Model, theme: any)
	for _, s in { -1, 1 } do
		for _, z in { -68, 68 } do
			local color = if s > 0 then C(43, 154, 237) else C(238, 71, 57)
			Props.stand(ctx, root, s, z, 96, 4, color)
			Props.stand(ctx, root, s, z, 96, 4, color, true, 21, 19.4)
		end
		for _, z in { -123, 123 } do
			Props.lamp(ctx, root, s * 99, z, 59, true)
		end
		Props.trophy(ctx, root, s * 87, 0, 8.8)
	end
	local finish = ctx.model(root, "ChampionshipFinish")
	for _, x in { -39, 39 } do
		ctx.part(finish, "FinalPylon", V(x, 20, -129), V(4, 40, 4), C(47, 137, 218))
		ctx.part(finish, "GoldTrim", V(x, 20, -126.8), V(1, 36, 0.25), theme.accent)
	end
	local banner = ctx.part(finish, "FinalBanner", V(0, 39, -129), V(74, 9, 3), C(38, 118, 195))
	ctx.text(banner, "CITY CHAMPIONS", Enum.NormalId.Back, theme.accent)
	ctx.text(banner, "CITY CHAMPIONS", Enum.NormalId.Front, theme.accent)
	Props.trophy(ctx, finish, 0, -129, 43.5)
	Props.scoreboard(ctx, root, -85, 0, "CITY STADIUM", theme.accent)
end

local builders = { field, park, street, dock, factory, rooftop, academy, stadium }

function City.apply(world: any)
	assert(world.Name == "World1" and world:GetAttribute("WorldLayoutReady"), "Final World1 layout required")
	local course = Refs.course(world)
	local k = Scale.factor(world)
	local archives = folder(folder(game.ServerStorage, "WorldBackups"), "World1BeforeFootballCity")
	-- Freeze the historical finish position before retiring its Japanese scenery.
	local finale = course:FindFirstChild("SakuraJapaneseFinale", true)
	local oldGate = finale and finale:FindFirstChild("SakuraGatewayFrame")
	local last = Refs.field(world, 8)
	local finishPosition = course:GetAttribute("ShotFinishPosition")
	if not finishPosition then
		finishPosition = if oldGate
			then oldGate:GetPivot().Position
			else last.Position + V(0, 3.48 * k, -last.Size.Z / 2 + 7 * k)
		course:SetAttribute("ShotFinishPosition", finishPosition)
	end
	for index, theme in Themes do
		local zone = course.Zones[string.format("Zone%02d", index)]
		local archive = folder(archives, zone.Name)
		for _, node in zone.Environment:GetChildren() do
			if node.Name ~= "Cityscape" then
				retire(node, archive)
				task.wait()
			end
		end
		for _, node in zone.Geometry:GetChildren() do
			if node.Name == "BiomeDecorStem" or node.Name == "CactusArm" or node.Name == "CliffShoulder_Surface" then
				retire(node, archive)
			end
		end
		local surface = Refs.field(world, index)
		surface.Color = theme.pitch
		zone:SetAttribute("BiomeName", theme.name)
		for _, bank in zone.Geometry:GetChildren() do
			if bank:IsA("BasePart") and bank.Name:match("^BiomeBank") then
				bank.Color = theme.paving
				for _, t in bank:GetChildren() do
					if t:IsA("Texture") then
						t.Color3 = theme.paving
					end
				end
			end
		end
		for _, body in zone.Geometry.Banks:GetChildren() do
			if body:IsA("BasePart") then
				body.Color = theme.earth
				if body:GetAttribute("CityBankOriginalSize") == nil then
					body:SetAttribute("CityBankOriginalSize", body.Size)
					body:SetAttribute("CityBankOriginalFrame", body.CFrame)
				end
				-- Preserve the shore top; extend only the cosmetic underside away
				-- from the former abutment checker caps. Collision is unchanged.
				local originalSize, originalFrame =
					body:GetAttribute("CityBankOriginalSize"), body:GetAttribute("CityBankOriginalFrame")
				assert(
					typeof(originalSize) == "Vector3" and typeof(originalFrame) == "CFrame",
					"Missing shore source geometry"
				)
				local drop = 0.12 * k / Scale.Measured
				body.Size = originalSize + V(0, drop, 0)
				body.CFrame = originalFrame - V(0, drop / 2, 0)
			end
		end
		-- A voxel-styled zone (CourseVoxelStyle) retires its old markings.
		local markings = zone.Geometry:FindFirstChild("PitchMarkings")
		for _, stripe in if markings then markings:GetChildren() else {} do
			if stripe:IsA("BasePart") and stripe.Name == "MownGrassStripe" then
				stripe.Color = theme.pitch:Lerp(Color3.new(0, 0, 0), 0.09)
			end
		end
		local signature = tostring(surface.CFrame) .. tostring(surface.Size) .. ":" .. VERSION
		local current = zone.Environment:FindFirstChild("Cityscape")
		if not current or current:GetAttribute("GeometrySignature") ~= signature then
			if current then
				current:Destroy()
			end
			local root = Instance.new("Model")
			root.Name = "Cityscape"
			root:SetAttribute("GeometrySignature", signature)
			root:SetAttribute("ZoneIndex", index)
			root:SetAttribute("Theme", theme.name)
			local ctx = Props.context(surface, k)
			common(ctx, root, theme, index)
			builders[index](ctx, root, theme)
			Props.spread(ctx, root)
			Props.finish(ctx, root)
			root.WorldPivot = surface.CFrame
			root.Parent = zone.Environment
		end
		task.wait()
	end
	local found = course.Zones.Zone08.Boundaries:FindFirstChild("ShotFinish")
	local endpoint = if found then found :: Part else Instance.new("Part")
	if not found then
		endpoint.Name, endpoint.Size = "ShotFinish", V(0.5, 0.5, 0.5)
		endpoint.Anchored, endpoint.Transparency = true, 1
		endpoint.CanCollide, endpoint.CanTouch, endpoint.CanQuery = false, false, false
		endpoint:SetAttribute("PartRole", "QueryVolume")
		endpoint:SetAttribute("Purpose", "Distance-calculation endpoint; preserves the previous maximum shot distance")
		endpoint.Parent = course.Zones.Zone08.Boundaries
	end
	endpoint.CFrame = CFrame.new(finishPosition)
	require(script.Parent.ZoneDividers).align(world)
	course:SetAttribute("FootballCityVersion", VERSION)
end

return City
