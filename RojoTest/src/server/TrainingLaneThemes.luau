--!strict
-- Approved biome reference B. Cosmetic parts only; authored lanes and nets stay in place.
local Themes = {}
local V, RGB = Vector3.new, Color3.fromRGB
local WHITE = RGB(245, 246, 231)
local STUDS = "rbxassetid://88156646156237"
local VERSION = 6
-- Geometry revisions are independent of palette updates; retain authored placement.
local LANE_VERSIONS = { 4, 4, 5, 4, 5, 5, 4 }
type Palette = { name: string, floor: Color3, stone: Color3, dark: Color3, accent: Color3 }
local PALETTES: { Palette } = {
	{
		name = "Standard",
		floor = RGB(35, 155, 61),
		stone = RGB(224, 232, 226),
		dark = RGB(43, 64, 73),
		accent = RGB(238, 244, 236),
	},
	{
		name = "Desert",
		floor = RGB(218, 120, 52),
		stone = RGB(237, 187, 143),
		dark = RGB(154, 76, 36),
		accent = RGB(255, 168, 81),
	},
	{
		name = "Ocean",
		floor = RGB(16, 179, 205),
		stone = RGB(212, 228, 211),
		dark = RGB(13, 105, 183),
		accent = RGB(78, 222, 248),
	},
	{
		name = "Frost",
		floor = RGB(48, 105, 219),
		stone = RGB(205, 222, 244),
		dark = RGB(37, 77, 155),
		accent = RGB(112, 173, 255),
	},
	{
		name = "Amethyst",
		floor = RGB(111, 31, 190),
		stone = RGB(91, 52, 135),
		dark = RGB(47, 23, 78),
		accent = RGB(208, 116, 255),
	},
	{
		name = "Volcano",
		floor = RGB(151, 32, 26),
		stone = RGB(48, 44, 54),
		dark = RGB(31, 30, 39),
		accent = RGB(255, 110, 13),
	},
	{
		name = "Champion",
		floor = RGB(240, 191, 30),
		stone = RGB(239, 224, 183),
		dark = RGB(202, 144, 16),
		accent = RGB(255, 214, 45),
	},
}

-- Palette-only migration: retain the current models, part geometry and hand placement.
local PREVIOUS_PALETTES: { [number]: Palette } = {
	[2] = {
		name = "Desert",
		floor = RGB(230, 174, 63),
		stone = RGB(232, 203, 146),
		dark = RGB(174, 116, 43),
		accent = RGB(255, 206, 71),
	},
	[4] = {
		name = "Frost",
		floor = RGB(87, 187, 235),
		stone = RGB(219, 235, 241),
		dark = RGB(45, 133, 205),
		accent = RGB(134, 233, 255),
	},
}

local function colorKey(color: Color3): string
	return string.format("%d,%d,%d", math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255))
end

local function colorVariants(p: Palette): { Color3 }
	local colors = {
		p.floor,
		p.stone,
		p.dark,
		p.accent,
		p.stone:Lerp(WHITE, 0.26),
		p.dark:Lerp(p.stone, 0.2),
		p.dark:Lerp(WHITE, 0.4),
		p.dark:Lerp(p.accent, 0.35),
		p.dark:Lerp(p.stone, 0.18),
		p.dark:Lerp(p.accent, 0.25),
	}
	for j = 0, 3 do
		table.insert(colors, p.stone:Lerp(p.accent, j * 0.09))
	end
	for j = 0, 2 do
		table.insert(colors, p.stone:Lerp(p.accent, 0.15 + j * 0.1))
	end
	for _, base in { p.floor, p.accent } do
		for _, shade in { base, base:Lerp(WHITE, 0.27), base:Lerp(p.dark, 0.26) } do
			table.insert(colors, shade)
			table.insert(colors, shade:Lerp(WHITE, 0.09))
		end
	end
	return colors
end

local function updatePalette(visual: Instance, index: number)
	local previous = PREVIOUS_PALETTES[index]
	if not previous or visual:GetAttribute("ColorPaletteVersion") == 1 then
		return
	end
	local old, new = colorVariants(previous), colorVariants(PALETTES[index])
	local mapping: { [string]: Color3 } = {}
	for i, color in old do
		mapping[colorKey(color)] = new[i]
	end
	for _, item in visual:GetDescendants() do
		if item:IsA("BasePart") then
			local color = mapping[colorKey(item.Color)]
			if color then
				item.Color = color
			end
		end
	end
	visual:SetAttribute("ColorPaletteVersion", 1)
end

local function build(lane: Model, index: number): Model
	local strip = assert(lane:FindFirstChild("TrainingStrip")) :: BasePart
	local imported = assert(lane:FindFirstChild("ImportedField"))
	local net: BasePart? = nil
	for _, item in imported:GetChildren() do
		if item:IsA("BasePart") and item.Name:find("Goal_Net", 1, true) then
			net = item
			break
		end
	end
	local goal = assert(net, "Missing authored goal net")
	local palette = PALETTES[index]
	local floorColor, stone, dark, accent = palette.floor, palette.stone, palette.dark, palette.accent
	local model = Instance.new("Model")
	model.Name = "BiomeReferenceVisuals"
	model:SetAttribute("Theme", palette.name)
	model:SetAttribute("Version", LANE_VERSIONS[index])
	model:SetAttribute("ColorPaletteVersion", 1)
	local origin = strip.CFrame * CFrame.new(0, strip.Size.Y / 2, 0) * CFrame.Angles(0, -math.pi / 2, 0)
	local length, width = strip.Size.X, strip.Size.Z
	local half = width / 2
	local localNet = origin:PointToObjectSpace(goal.Position)
	local goalZ = localNet.Z + goal.Size.Z / 2 + 0.18
	local goalTop = localNet.Y + goal.Size.Y / 2
	local crestTop = goalTop

	local function part(name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?): Part
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color = name, size, origin * cf, color
		p.Anchored = true
		p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if shape then
			p.Shape = shape
		end
		p.Parent = model
		return p
	end
	local function block(
		name: string,
		x: number,
		y: number,
		z: number,
		sx: number,
		sy: number,
		sz: number,
		color: Color3
	): Part
		return part(name, V(sx, sy, sz), CFrame.new(x, y, z), color)
	end
	local function beam(name: string, a: Vector3, b: Vector3, thickness: number, color: Color3): Part
		return part(name, V(thickness, thickness, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), color)
	end
	local function ball(name: string, x: number, y: number, z: number, size: Vector3, color: Color3): Part
		return part(name, size, CFrame.new(x, y, z), color, Enum.PartType.Ball)
	end
	local function triangle(name: string, a: Vector3, b: Vector3, c: Vector3, depth: number, color: Color3)
		local ab, ac, bc = b - a, c - a, c - b
		if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
			c, a = a, c
		elseif ac.Magnitude > bc.Magnitude then
			a, b = b, a
		end
		ab, ac, bc = b - a, c - a, c - b
		if ac:Cross(ab).Magnitude < 0.00001 then
			return
		end
		local right = ac:Cross(ab).Unit
		local back = bc.Unit
		local up = back:Cross(right).Unit
		local height = math.abs(ab:Dot(up))
		local wedges = {
			{ center = (a + b) / 2, right = right, back = back, span = math.abs(ab:Dot(back)) },
			{ center = (a + c) / 2, right = -right, back = -back, span = math.abs(ac:Dot(back)) },
		}
		for i, data in wedges do
			local span = data.span
			if span > 0.0001 and height > 0.0001 then
				local wedge = Instance.new("WedgePart")
				wedge.Name = name .. i
				wedge.Size = V(depth, height, span)
				wedge.CFrame = origin * CFrame.fromMatrix(data.center, data.right, up, data.back)
				wedge.Color, wedge.Material = color, Enum.Material.SmoothPlastic
				wedge.Anchored = true
				wedge.CanCollide, wedge.CanTouch, wedge.CanQuery = false, false, false
				wedge.TopSurface, wedge.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
				wedge.Parent = model
			end
		end
	end
	local function polygon(name: string, points: { Vector3 }, center: Vector3, depth: number, color: Color3)
		for i, a in points do
			triangle(name, center, a, points[i % #points + 1], depth, color)
		end
	end
	local function stud(p: BasePart, opacity: number)
		local t = Instance.new("Texture")
		t.Name, t.Texture, t.Face = "ReferenceHDStuds", STUDS, Enum.NormalId.Top
		t.StudsPerTileU, t.StudsPerTileV = 8, 8
		t.Transparency = opacity
		local point = origin:PointToObjectSpace(p.Position)
		t.OffsetStudsU = (point.X - p.Size.X / 2 + half) % 8
		t.OffsetStudsV = (point.Z - p.Size.Z / 2 + length / 2) % 8
		t.Parent = p
	end
	local function cylinder(
		name: string,
		x: number,
		y: number,
		z: number,
		diameter: number,
		height: number,
		color: Color3
	): Part
		return part(
			name,
			V(height, diameter, diameter),
			CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.pi / 2),
			color,
			Enum.PartType.Cylinder
		)
	end
	local function shard(x: number, y: number, z: number, w: number, h: number, color: Color3, tilt: number)
		local cf = CFrame.new(x, y, z) * CFrame.Angles(0, 0, tilt)
		local lower, upper = {}, {}
		for j = 0, 3 do
			local angle = math.pi / 4 + j * math.pi / 2
			local p = V(math.cos(angle) * w * 0.68, 0, math.sin(angle) * w * 0.52)
			table.insert(lower, cf:PointToWorldSpace(p))
			table.insert(upper, cf:PointToWorldSpace(p + V(0, h * 0.64, 0)))
		end
		local tip = cf:PointToWorldSpace(V(w * 0.08, h, 0))
		for j = 1, 4 do
			local k = j % 4 + 1
			local shade = if j == 1 then color:Lerp(WHITE, 0.27) elseif j == 2 then color else color:Lerp(dark, 0.26)
			triangle("CrystalSide", lower[j], lower[k], upper[j], 0.025, shade)
			triangle("CrystalSide", lower[k], upper[k], upper[j], 0.025, shade)
			triangle("CrystalTip", upper[j], upper[k], tip, 0.025, shade:Lerp(WHITE, 0.09))
		end
		crestTop = math.max(crestTop, y + h)
	end
	local function wave(x: number, y: number, z: number, scale: number)
		local previousA: Vector3? = nil
		local previousB: Vector3? = nil
		for j = 0, 20 do
			local t = j / 20
			local angle = -math.pi * 0.55 + t * math.pi * 1.85
			local radius = (1 - t * 0.82) * scale
			local thick = (0.48 - t * 0.30) * scale
			local a = V(x + math.cos(angle) * radius, y + math.sin(angle) * radius, z)
			local b = V(x + math.cos(angle) * (radius + thick), y + math.sin(angle) * (radius + thick), z)
			if previousA and previousB then
				triangle("Wave", previousA, previousB, a, 1.3, RGB(17, 150, 229))
				triangle("Wave", previousB, b, a, 1.3, RGB(17, 150, 229))
				beam("WaveFoam", previousB + V(0, 0, 0.70), b + V(0, 0, 0.70), 0.14 * scale, WHITE)
			end
			previousA, previousB = a, b
		end
		crestTop = math.max(crestTop, y + scale * 1.35)
	end
	local function surfCrest(y: number, z: number)
		local function point(x: number, height: number, depth: number): Vector3
			return V(x * 0.94, y + height * 0.80, z + depth)
		end
		local outline = {}
		for _, p in
			{
				Vector2.new(-5.6, 0),
				Vector2.new(-4.5, 0.55),
				Vector2.new(-3.9, 1.3),
				Vector2.new(-3.52, 2.35),
				Vector2.new(-2.60, 2.35),
				Vector2.new(-2.35, 1.4),
				Vector2.new(-1.25, 0.3),
				Vector2.new(-0.1, 0),
			}
		do
			table.insert(outline, point(p.X, p.Y, 0))
		end
		polygon("SurfBody", outline, point(-3, 0.8, 0), 1.42, RGB(0, 139, 211))
		local lastA: Vector3? = nil
		local lastB: Vector3? = nil
		for j = 0, 32 do
			local t = j / 32
			local angle, radius = math.pi - t * math.pi * 1.76, 2.8 * (1 - t * 0.86)
			local thick = 0.92 - t * 0.72
			local a = point(0.2 + math.cos(angle) * radius, 2.35 + math.sin(angle) * radius, 0)
			local b = point(0.2 + math.cos(angle) * (radius + thick), 2.35 + math.sin(angle) * (radius + thick), 0)
			if lastA and lastB then
				triangle("SurfCurl", lastA, lastB, a, 1.42, RGB(0, 169, 224))
				triangle("SurfCurl", lastB, b, a, 1.42, RGB(0, 169, 224))
				beam("SurfFoam", lastB + V(0, 0, 0.79), b + V(0, 0, 0.79), 0.22 - t * 0.09, WHITE)
				if j % 6 == 0 and t < 0.8 then
					ball("CrestFoamDrop", b.X + 0.07, b.Y + 0.06, z + 0.82, V(0.30, 0.25, 0.25), WHITE)
				end
			end
			lastA, lastB = a, b
		end
		local sweep =
			{ point(-5.2, 0.16, 0.78), point(-4.2, 0.54, 0.78), point(-3.3, 1.05, 0.78), point(-2.8, 1.55, 0.78) }
		for j = 1, #sweep - 1 do
			beam("SurfHighlight", sweep[j], sweep[j + 1], 0.12, RGB(106, 235, 248))
		end
	end
	local function shell(x: number, y: number, z: number, size: number)
		local hub = V(x, y, z)
		local last: Vector3? = nil
		for j = 0, 6 do
			local a = math.pi * (0.12 + j / 6 * 0.76)
			local p = hub + V(math.cos(a) * size, math.sin(a) * size, 0)
			if last then
				triangle("SeaShell", hub, last, p, 0.18, if j % 2 == 0 then WHITE else RGB(199, 230, 227))
			end
			beam("ShellRib", hub + V(0, 0, 0.12), p + V(0, 0, 0.12), 0.045, RGB(255, 240, 204))
			last = p
		end
	end
	local function glint(x: number, y: number, z: number, size: number)
		local c = V(x, y, z)
		local pts = {
			c + V(0, size, 0),
			c + V(size * 0.18, size * 0.18, 0),
			c + V(size * 0.58, 0, 0),
			c + V(size * 0.18, -size * 0.18, 0),
			c - V(0, size, 0),
			c - V(size * 0.18, size * 0.18, 0),
			c - V(size * 0.58, 0, 0),
			c + V(-size * 0.18, size * 0.18, 0),
		}
		polygon("CrystalGlint", pts, c, 0.08, RGB(245, 215, 255))
	end
	local function volcanicFault(j: number, h: number, baseY: number, z: number)
		local w = 1.95
		local cf = CFrame.new(j * 1.7, baseY, z) * CFrame.Angles(0, 0, -j * 0.06)
		local function surface(t: number, offset: number): Vector3
			local taper = if t <= 0.64 then 1 else math.max(0, (1 - t) / 0.36)
			local centerX = if t <= 0.64 then 0 else w * 0.08 * (t - 0.64) / 0.36
			return cf:PointToWorldSpace(
				V(centerX + offset * taper, h * t, w * math.sin(math.pi / 4) * 0.52 * taper + 0.055)
			)
		end
		local vertices = {}
		for n = 0, 6 do
			local t = 0.07 + n / 6 * 0.85
			local dx = math.sin(n * 1.8 + j * 2.1) * 0.17 + j * 0.025
			table.insert(vertices, surface(t, dx))
		end
		local function fissure(a: Vector3, b: Vector3, thickness: number)
			beam("VolcanoCrack", a, b, thickness, RGB(255, 94, 5)).Material = Enum.Material.Neon
			beam("VolcanoHotCore", a + V(0, 0, 0.035), b + V(0, 0, 0.035), thickness * 0.33, RGB(255, 218, 69)).Material =
				Enum.Material.Neon
		end
		for n = 1, #vertices - 1 do
			fissure(vertices[n], vertices[n + 1], if j == 0 then 0.15 else 0.10)
		end
		if j % 2 == 0 or math.abs(j) == 1 then
			local t = 0.35 + (j % 3) * 0.06
			local a, b, c =
				surface(t, 0),
				surface(t + 0.09, if j % 2 == 0 then 0.40 else -0.34),
				surface(t + 0.20, if j % 2 == 0 then 0.61 else -0.54)
			fissure(a, b, 0.08)
			fissure(b, c, 0.065)
		end
	end
	local function star(x: number, y: number, z: number, radius: number, color: Color3)
		local points = {}
		for j = 0, 9 do
			local a = math.pi / 2 + j * math.pi / 5
			local r = if j % 2 == 0 then radius else radius * 0.46
			table.insert(points, V(x + math.cos(a) * r, y + math.sin(a) * r, z))
		end
		polygon("ChampionStar", points, V(x, y, z), 0.25, color)
	end
	local function rosette(x: number, y: number, z: number, radius: number, color: Color3)
		part(
			"InsetMedallion",
			V(0.13, radius * 2, radius * 2),
			CFrame.new(x, y, z) * CFrame.Angles(0, math.pi / 2, 0),
			color,
			Enum.PartType.Cylinder
		)
	end
	local function palm(x: number, y: number, z: number)
		local height = 3.7
		for j = 0, 5 do
			local p = V(x - math.sign(x) * j * 0.06, y + j * height / 6, z)
			local q = V(x - math.sign(x) * (j + 1) * 0.06, y + (j + 1) * height / 6, z)
			beam("PalmTrunk", p, q, 0.40 - j * 0.025, RGB(153 + j * 5, 104 + j * 4, 53))
		end
		local hub = V(x - math.sign(x) * 0.36, y + height, z)
		for j = 0, 5 do
			local a = j * math.pi / 3 + 0.2
			local direction, across = V(math.cos(a), 0, math.sin(a)), V(-math.sin(a), 0, math.cos(a))
			local ridge, tip = hub + direction * 1.15 + V(0, 0.42, 0), hub + direction * 2.35 - V(0, 0.65, 0)
			local left, right = hub + direction * 1.0 - across * 0.45, hub + direction * 1.0 + across * 0.45
			local green = RGB(35, 151 + (j % 2) * 22, 46)
			triangle("PalmFrond", hub, left, ridge, 0.08, green)
			triangle("PalmFrond", hub, ridge, right, 0.08, green:Lerp(WHITE, 0.15))
			triangle("PalmFrond", left, tip, ridge, 0.08, green)
			triangle("PalmFrond", ridge, tip, right, 0.08, green:Lerp(WHITE, 0.15))
		end
		for j = -1, 1 do
			ball("Coconut", hub.X + j * 0.24, hub.Y - 0.18, hub.Z + 0.1, V(0.32, 0.35, 0.32), RGB(103, 76, 39))
		end
	end

	-- One quiet floor, thin markings and broad low curbs match the approved reference.
	local foundation = lane:FindFirstChild("Foundation") :: BasePart
	local localFoundation = origin:ToObjectSpace(foundation.CFrame)
	part(
		"EarthPlinth",
		V(foundation.Size.Z, foundation.Size.Y, foundation.Size.X),
		localFoundation * CFrame.Angles(0, math.pi / 2, 0),
		dark
	)
	local floor = block("StuddedPitch", 0, 0.025, -1.25, width, 0.05, length - 2.5, floorColor)
	stud(floor, 0.45)
	if index == 1 then
		local stripeLength = (length - 2.5) / 8
		for j = 0, 6, 2 do
			local stripe = block(
				"MownTurfBand",
				0,
				0.0675,
				-length / 2 + (j + 0.5) * stripeLength,
				width,
				0.025,
				stripeLength,
				floorColor:Lerp(RGB(17, 76, 34), 0.10)
			)
			stud(stripe, 0.45)
		end
	end
	local front, rear = length / 2 - 2.65, goalZ - 0.25
	local lineX, lineWidth = half - 0.7, 0.17
	for _, side in { -1, 1 } do
		block("Touchline", side * lineX, 0.15, (front + rear) / 2, lineWidth, 0.035, front - rear, WHITE).CastShadow =
			false
		block("LowStoneWall", side * (half - 0.12), 0.55, 0, 0.72, 1.0, length - 0.15, stone)
		block("WallInset", side * (half - 0.12), 1.10, 0, 0.50, 0.12, length - 0.3, dark)
		block("WallAccent", side * (half - 0.12), 0.70, 0, 0.77, 0.15, length - 0.4, accent)
		block("WallFootTrim", side * (half + 0.24), 0.22, 0, 0.12, 0.18, length - 0.25, dark:Lerp(stone, 0.2))
		local sections = 6
		for j = 0, sections do
			local z = front - j / sections * (front - rear)
			block("CurbPier", side * (half - 0.10), 0.86, z, 0.91, 1.6, 0.82, stone)
			block("PierCap", side * (half - 0.10), 1.66, z, 1.02, 0.16, 0.96, stone:Lerp(WHITE, 0.26))
			for _, dz in { -0.23, 0.23 } do
				ball("RailFastener", side * (half - 0.58), 1.1, z + dz, V(0.07, 0.12, 0.12), dark:Lerp(WHITE, 0.40))
			end
			if index == 1 then
				block("StandardPostCap", side * (half - 0.10), 1.77, z, 0.75, 0.08, 0.69, dark)
			elseif index == 2 then
				ball("SandstoneCap", side * (half - 0.10), 1.65, z, V(0.68, 0.44, 0.68), accent)
			elseif index == 3 then
				ball("SeaPebble", side * (half - 0.10), 1.64, z, V(0.65, 0.44, 0.66), accent)
			elseif index == 4 or index == 5 then
				if index == 4 or j % 2 == 0 then
					shard(side * (half - 0.10), 1.48, z, 0.48, 0.85, accent, side * 0.10)
				else
					ball("AmethystCabochon", side * (half - 0.10), 1.88, z, V(0.34, 0.38, 0.34), RGB(225, 172, 255))
				end
			elseif index == 6 then
				local glow = block("LavaVent", side * (half - 0.10), 1.7, z, 0.46, 0.18, 0.44, accent)
				glow.Material = Enum.Material.Neon
			else
				ball("GoldFinial", side * (half - 0.10), 1.70, z, V(0.48, 0.48, 0.48), accent)
			end
		end
	end
	for _, z in { front, rear } do
		block("EndLine", 0, 0.13, z, lineX * 2 + lineWidth, 0.03, lineWidth, WHITE).CastShadow = false
	end
	local penaltyWidth, penaltyDepth = 7.5, 4.3
	block("PenaltyLine", 0, 0.155, rear + penaltyDepth, penaltyWidth, 0.03, lineWidth, WHITE).CastShadow = false
	for _, side in { -1, 1 } do
		block(
			"PenaltySide",
			side * penaltyWidth / 2,
			0.155,
			rear + penaltyDepth / 2,
			lineWidth,
			0.03,
			penaltyDepth,
			WHITE
		).CastShadow =
			false
	end
	cylinder("StartingSpot", 0, 0.17, front - 3.5, 0.42, 0.035, WHITE).CastShadow = false
	-- Entry pad rests just below the walkable plane; no new physical step.
	local badgeZ = length / 2 - 1.25
	block("EntryPad", 0, 0.025, badgeZ, width, 0.05, 2.5, stone)
	for _, side in { -1, 1 } do
		block("EntryInlay", side * 3.65, 0.075, badgeZ, 3.9, 0.035, 0.13, dark:Lerp(accent, 0.25)).CastShadow = false
		block("EntryCornerTrim", side * 5.82, 0.075, badgeZ, 0.13, 0.035, 1.70, dark)
	end
	cylinder("EntryMedallionRim", 0, 0.06, badgeZ, 2.15, 0.09, dark)
	cylinder("EntryMedallion", 0, 0.12, badgeZ, 1.86, 0.05, accent)
	-- Emblems are geometry on a horizontal disc, no uploaded decal or interactive GUI.
	local function badgeLine(a: Vector3, b: Vector3)
		beam("EntryEmblem", a + V(0, 0.18, badgeZ), b + V(0, 0.18, badgeZ), 0.10, if index == 1 then dark else WHITE).CastShadow =
			false
	end
	if index == 1 then
		for j = 0, 4 do
			local a, b = -math.pi / 2 + j * math.pi * 2 / 5, -math.pi / 2 + (j + 1) * math.pi * 2 / 5
			badgeLine(V(math.cos(a) * 0.42, 0, math.sin(a) * 0.42), V(math.cos(b) * 0.42, 0, math.sin(b) * 0.42))
			badgeLine(V(math.cos(a) * 0.42, 0, math.sin(a) * 0.42), V(math.cos(a) * 0.76, 0, math.sin(a) * 0.76))
		end
	elseif index == 2 or index == 4 then
		for j = 0, 7 do
			local a = j * math.pi / 4
			badgeLine(V(math.cos(a) * 0.23, 0, math.sin(a) * 0.23), V(math.cos(a) * 0.68, 0, math.sin(a) * 0.68))
		end
	elseif index == 3 then
		local last: Vector3? = nil
		for j = 0, 20 do
			local t = j / 20
			local a, r = t * math.pi * 3, 0.08 + t * 0.52
			local p = V(math.cos(a) * r, 0, math.sin(a) * r)
			if last then
				badgeLine(last, p)
			end
			last = p
		end
	elseif index == 5 or index == 6 then
		local pts = { V(0, 0, -0.62), V(0.48, 0, -0.1), V(0.22, 0, 0.55), V(-0.22, 0, 0.55), V(-0.48, 0, -0.1) }
		for j, p in pts do
			badgeLine(p, pts[j % #pts + 1])
		end
	else
		local pts = {}
		for j = 0, 9 do
			local a, r = -math.pi / 2 + j * math.pi / 5, if j % 2 == 0 then 0.72 else 0.32
			table.insert(pts, V(math.cos(a) * r, 0, math.sin(a) * r))
		end
		for j, p in pts do
			badgeLine(p, pts[j % #pts + 1])
		end
	end

	-- Goal surrounds are built around the actual net opening, never across it.
	local gw = goal.Size.X + 0.65
	for _, side in { -1, 1 } do
		block("GoalWhiteUpright", side * gw / 2, goalTop / 2, goalZ, 0.26, goalTop, 0.35, WHITE)
		if index == 1 then
			block("GoalFrameFoot", side * gw / 2, 0.15, goalZ - 0.6, 0.5, 0.25, 1.6, dark)
		else
			block("GoalPillarBase", side * (gw / 2 + 0.65), 0.38, goalZ - 0.28, 1.4, 0.76, 1.65, stone)
			block("GoalThemePillar", side * (gw / 2 + 0.65), goalTop / 2, goalZ - 0.35, 1.02, goalTop, 1.2, stone)
			block("GoalPillarCapital", side * (gw / 2 + 0.65), goalTop - 0.05, goalZ - 0.35, 1.40, 0.45, 1.55, accent)
			block(
				"CapitalInset",
				side * (gw / 2 + 0.65),
				goalTop + 0.20,
				goalZ - 0.35,
				1.20,
				0.09,
				1.36,
				dark:Lerp(accent, 0.35)
			)
			block(
				"PillarRecess",
				side * (gw / 2 + 0.65),
				goalTop / 2,
				goalZ + 0.28,
				0.65,
				goalTop - 1.2,
				0.10,
				dark:Lerp(stone, 0.18)
			)
		end
	end
	block("GoalWhiteCrossbar", 0, goalTop, goalZ, gw + 0.25, 0.27, 0.36, WHITE)
	-- A crisp white visual net uses the authored target plane and opening.
	local bottom = localNet.Y - goal.Size.Y / 2
	local netZ = goalZ - 0.18
	local columns, rows = math.ceil(goal.Size.X / 0.48), math.ceil(goal.Size.Y / 0.48)
	for j = 0, columns do
		local x = -goal.Size.X / 2 + j / columns * goal.Size.X
		beam("WhiteNetVertical", V(x, bottom, netZ), V(x, goalTop, netZ), 0.035, WHITE).CastShadow = false
	end
	for j = 0, rows do
		local y = bottom + j / rows * goal.Size.Y
		beam("WhiteNetHorizontal", V(-goal.Size.X / 2, y, netZ), V(goal.Size.X / 2, y, netZ), 0.035, WHITE).CastShadow =
			false
	end
	local depth = math.min(goal.Size.Z + 0.35, 1.65)
	local backZ = netZ - depth
	for _, side in { -1, 1 } do
		local x = side * goal.Size.X / 2
		beam("GoalRearBrace", V(x, bottom, backZ), V(x, goalTop, netZ), 0.09, WHITE)
		beam("GoalGroundRail", V(x, bottom, backZ), V(x, bottom, netZ), 0.10, WHITE)
		for j = 1, rows - 1 do
			local t = j / rows
			beam(
				"NetSideHorizontal",
				V(x, bottom + t * goal.Size.Y, netZ),
				V(x, bottom + t * goal.Size.Y, backZ + t * depth),
				0.025,
				WHITE
			).CastShadow =
				false
		end
		for j = 1, 3 do
			local t = j / 4
			beam(
				"NetSideVertical",
				V(x, bottom, netZ - t * depth),
				V(x, goalTop * (1 - t) + bottom * t, netZ - t * depth),
				0.025,
				WHITE
			).CastShadow =
				false
		end
	end
	beam("NetRearGroundRail", V(-goal.Size.X / 2, bottom, backZ), V(goal.Size.X / 2, bottom, backZ), 0.09, WHITE)
	if index ~= 1 then
		block("GoalThemeLintel", 0, goalTop + 0.55, goalZ - 0.35, width - 0.5, 0.70, 1.25, stone)
		block("LintelLowerTrim", 0, goalTop + 0.24, goalZ + 0.30, width - 0.55, 0.12, 0.14, accent)
	end
	local header = goalTop + 0.8
	if index == 1 then
		-- Plain training goal: no themed portal, crest, foliage or tall gate.
		crestTop = goalTop + 0.2
	elseif index == 2 then
		for j = 0, 3 do
			local p = block(
				"TempleStep",
				0,
				header + j * 0.55,
				goalZ - 0.40,
				8.2 - j * 1.75,
				0.55,
				1.5,
				stone:Lerp(accent, j * 0.09)
			)
			stud(p, 0.64)
		end
		crestTop = header + 2.2
		rosette(0, header + 0.6, goalZ + 0.44, 0.70, accent)
		for j = 0, 7 do
			local a = j * math.pi / 4
			beam(
				"TempleSunRay",
				V(math.cos(a) * 0.86, header + 0.6 + math.sin(a) * 0.86, goalZ + 0.52),
				V(math.cos(a) * 1.11, header + 0.6 + math.sin(a) * 1.11, goalZ + 0.52),
				0.12,
				accent
			)
		end
		for _, side in { -1, 1 } do
			palm(side * 5.4, goalTop - 0.9, goalZ - 0.80)
			for j = 1, 4 do
				block(
					"TempleMasonryJoint",
					side * (gw / 2 + 0.65),
					j * 0.95,
					goalZ + 0.35,
					0.73,
					0.055,
					0.06,
					dark:Lerp(stone, 0.45)
				)
			end
			local x = side * (half - 0.1)
			block("EntryCactus", x, 1.75, front - 0.2, 0.42, 2.2, 0.44, RGB(33, 154, 58))
			beam("CactusArm", V(x, 1.65, front - 0.2), V(x - side * 0.6, 1.65, front - 0.2), 0.28, RGB(36, 169, 65))
			block("CactusBranch", x - side * 0.6, 1.95, front - 0.2, 0.28, 0.62, 0.28, RGB(36, 169, 65))
			ball("CactusFlower", x, 2.95, front - 0.2, V(0.33, 0.22, 0.32), RGB(255, 141, 91))
			for j = 0, 2 do
				block(
					"SandstoneEntryRock",
					x - side * j * 0.28,
					0.82 + j * 0.06,
					front + 0.4,
					0.50 - j * 0.08,
					0.35,
					0.5,
					stone:Lerp(accent, 0.15 + j * 0.1)
				)
			end
		end
	elseif index == 3 then
		block("SeaBlueHeader", 0, header - 0.02, goalZ - 0.25, width - 0.6, 0.48, 1.1, dark)
		surfCrest(header + 0.05, goalZ - 0.12)
		block("OceanFoamCornice", 0, header - 0.21, goalZ + 0.34, width - 0.55, 0.16, 0.22, WHITE)
		shell(3.95, header + 0.12, goalZ + 0.65, 1.12)
		rosette(3.95, header + 0.40, goalZ + 0.83, 0.23, WHITE)
		for j = 0, 2 do
			ball(
				"ShellPearlFoam",
				2.55 + j * 0.24,
				header + 0.08 + (j % 2) * 0.12,
				goalZ + 0.77,
				V(0.25, 0.23, 0.20),
				WHITE
			)
		end
		for _, side in { -1, 1 } do
			wave(side * (half - 0.2), 1.6, front, 0.8)
			shell(side * (gw / 2 + 0.65), 2.6, goalZ + 0.47, 0.38)
			rosette(side * (half - 0.18), 1.1, goalZ + 0.55, 0.36, RGB(244, 232, 199))
			for j = 0, 2 do
				ball(
					"FoamBubble",
					side * (gw / 2 + 0.7) + side * (j % 2) * 0.18,
					goalTop - j * 0.65,
					goalZ + 0.42,
					V(0.32 + j * 0.07, 0.38, 0.25),
					WHITE
				)
			end
			block("OceanColumnFlute", side * (gw / 2 + 0.65), 2.8, goalZ + 0.38, 0.16, 3.4, 0.16, accent)
		end
	elseif index == 4 then
		for j = -4, 4 do
			local h = 1.5 + (1 - math.abs(j) / 5) * 2.7 + (j % 2) * 0.5
			shard(
				j * 1.23,
				header - 0.12,
				goalZ - 0.1 - (j % 2) * 0.45,
				1.3,
				h,
				if j % 2 == 0 then accent else floorColor,
				-j * 0.085
			)
		end
		for _, side in { -1, 1 } do
			shard(side * (half - 0.05), 0.7, front, 1.1, 2.9, accent, -side * 0.13)
			shard(side * (half - 0.4), 0.7, goalZ + 0.4, 0.8, 2.1, floorColor, side * 0.2)
			shard(side * (half - 0.5), 0.7, front + 0.65, 0.65, 1.45, floorColor, side * 0.22)
			if index == 4 then
				ball("SnowDrift", side * (half - 0.10), 0.80, front + 0.05, V(1.4, 0.40, 1.5), WHITE)
				block("FrostCornice", side * (gw / 2 + 0.65), goalTop + 0.30, goalZ - 0.2, 1.5, 0.22, 1.65, WHITE)
			else
				rosette(side * (gw / 2 + 0.65), 3.2, goalZ + 0.40, 0.38, RGB(223, 188, 255))
				shard(side * (gw / 2 + 0.65), 2.9, goalZ + 0.63, 0.38, 0.6, accent, 0)
			end
		end
		if index == 4 then
			for j = 0, 5 do
				local a = j * math.pi / 3
				beam(
					"Snowflake",
					V(0, header - 0.3, goalZ + 0.40),
					V(math.cos(a) * 0.55, header - 0.3 + math.sin(a) * 0.55, goalZ + 0.40),
					0.08,
					WHITE
				)
			end
		end
	elseif index == 5 then
		local metal = RGB(234, 210, 147)
		local pale = RGB(224, 176, 255)
		-- A distinct crystal monument: asymmetric masses, a tall central gem and a facet halo.
		for j = 0, 11 do
			local a, b = j * math.pi / 6, (j + 1) * math.pi / 6
			beam(
				"AmethystFacetHalo",
				V(math.cos(a) * 3.3, header + 3.3 + math.sin(a) * 3.3, goalZ - 0.95),
				V(math.cos(b) * 3.3, header + 3.3 + math.sin(b) * 3.3, goalZ - 0.95),
				0.12,
				metal
			)
		end
		for _, shape in
			{
				{ -4.45, 1.45, 2.95, 0.24 },
				{ -2.35, 1.90, 4.65, 0.15 },
				{ 0, 2.35, 6.85, -0.06 },
				{ 2.5, 1.9, 5.1, -0.19 },
				{ 4.5, 1.5, 3.3, -0.28 },
			}
		do
			shard(
				shape[1],
				header - 0.04,
				goalZ - 0.1,
				shape[2],
				shape[3],
				if shape[1] < 0 then RGB(167, 65, 225) else accent,
				shape[4]
			)
		end
		for _, shape in { { -3.8, 1.0, 1.6 }, { -1.25, 0.9, 2.15 }, { 1.2, 1.15, 1.65 }, { 4.0, 0.9, 1.5 } } do
			shard(shape[1], header - 0.1, goalZ + 0.68, shape[2], shape[3], pale, -shape[1] * 0.055)
		end
		block("AmethystCrestSocket", 0, header - 0.08, goalZ + 0.38, width - 0.36, 0.28, 1.7, dark)
		block("AmethystCrestMetalEdge", 0, header - 0.26, goalZ + 1.12, width - 0.4, 0.12, 0.14, metal)
		for _, side in { -1, 1 } do
			local x = side * (gw / 2 + 0.65)
			block(
				"AmethystOuterButtress",
				side * (half - 0.05),
				goalTop / 2 + 0.2,
				goalZ - 0.25,
				1.0,
				goalTop + 0.4,
				1.45,
				dark
			)
			for _, h in { 0.7, 1.2, goalTop - 0.38, goalTop + 0.22 } do
				block("AmethystPillarBand", x, h, goalZ + 0.30, 1.18, 0.12, 0.20, metal)
			end
			for _, dx in { -0.39, 0.39 } do
				block("AmethystMetalFlute", x + dx, goalTop / 2, goalZ + 0.38, 0.07, goalTop - 1.6, 0.12, metal)
			end
			rosette(x, 3.1, goalZ + 0.46, 0.41, metal)
			shard(x, 2.86, goalZ + 0.68, 0.40, 0.78, pale, 0)
			local trim =
				block("AmethystRailLight", side * (half - 0.12), 1.23, 0, 0.14, 0.06, length - 0.6, RGB(191, 111, 247))
			trim.Material = Enum.Material.Neon
			block("AmethystGiltRail", side * (half - 0.42), 1.20, 0, 0.07, 0.08, length - 0.6, metal)
			cylinder("AmethystEntrySocket", side * (half - 0.10), 0.83, front, 1.45, 0.25, dark)
			shard(side * (half - 0.10), 0.9, front, 1.25, 3.7, accent, -side * 0.12)
			shard(side * (half - 0.55), 0.85, front + 0.55, 0.68, 1.9, pale, side * 0.22)
			shard(side * (half - 0.42), 0.85, goalZ + 0.6, 0.85, 2.6, accent, side * 0.16)
		end
		glint(-3.75, header + 5.6, goalZ + 0.1, 0.34)
		glint(4.8, header + 4.9, goalZ + 0.1, 0.27)
		glint(1.35, header + 7.1, goalZ - 0.2, 0.23)
	elseif index == 6 then
		for j = -3, 3 do
			local h = 1.5 + (1 - math.abs(j) / 4) * 3.7
			shard(j * 1.7, header - 0.25, goalZ - 0.2, 1.95, h, if j % 2 == 0 then dark else stone, -j * 0.06)
			volcanicFault(j, h, header - 0.25, goalZ - 0.2)
		end
		for _, side in { -1, 1 } do
			for _, y in { 1.2, 3.9 } do
				shard(side * (half - 0.45), y, goalZ + 0.58, 0.48, 0.75, accent, 0)
			end
			shard(side * (half - 0.12), 0.7, front, 1.4, 3.0, stone, -side * 0.1)
			local glow = block("EntryLava", side * (half - 0.12), 1.45, front + 0.57, 0.92, 0.23, 0.06, accent)
			glow.Material = Enum.Material.Neon
			for j = 0, 2 do
				local x, y = side * (half - 0.12) - side * j * 0.24, 0.74 + j * 0.05
				local rock = block(
					"BasaltBoulder",
					x,
					y,
					front + 0.45 + j * 0.1,
					0.72 - j * 0.1,
					0.62,
					0.68,
					stone:Lerp(dark, j * 0.20)
				)
				rock.CFrame *= CFrame.Angles(0.12 * j, 0.25 * j, side * 0.12)
			end
		end
	else
		block("RoyalBlueHeader", 0, header + 0.15, goalZ + 0.30, width - 0.6, 0.35, 0.16, RGB(24, 83, 179))
		local crownY = header + 0.55
		block("CrownBand", 0, crownY, goalZ - 0.1, 6.5, 0.85, 1.3, accent)
		block("CrownBandTrim", 0, crownY - 0.36, goalZ + 0.61, 6.65, 0.13, 0.14, RGB(255, 234, 123))
		for j = -2, 2 do
			rosette(j * 1.15, crownY, goalZ + 0.62, 0.16, if j % 2 == 0 then RGB(37, 122, 213) else RGB(241, 100, 110))
		end
		for j = -2, 2 do
			local x = j * 1.4
			local h = if j == 0 then 3.0 elseif math.abs(j) == 2 then 2.4 else 1.6
			triangle(
				"CrownPoint",
				V(x - 0.72, crownY + 0.25, goalZ - 0.1),
				V(x + 0.72, crownY + 0.25, goalZ - 0.1),
				V(x + j * 0.2, crownY + h, goalZ - 0.1),
				1.25,
				accent
			)
			ball("CrownJewelTip", x + j * 0.2, crownY + h, goalZ - 0.1, V(0.45, 0.45, 0.45), RGB(255, 231, 98))
		end
		star(0, crownY + 0.65, goalZ + 0.65, 1.05, RGB(38, 124, 222))
		crestTop = crownY + 3.3
		for _, side in { -1, 1 } do
			for j = -1, 1 do
				block(
					"RoyalColumnFlute",
					side * (gw / 2 + 0.65) + j * 0.23,
					2.8,
					goalZ + 0.38,
					0.06,
					3.75,
					0.10,
					accent
				)
			end
			block("RoyalBanner", side * (half - 0.3), 3.7, goalZ + 0.35, 0.65, 2.4, 0.14, RGB(24, 83, 179))
			star(side * (half - 0.3), 3.8, goalZ + 0.5, 0.25, accent)
			block("RoyalEntryPier", side * (half - 0.10), 1.4, front, 0.95, 2.3, 0.95, stone)
			star(side * (half - 0.10), 2.75, front + 0.5, 0.55, accent)
			block("RoyalEntryBlueInset", side * (half - 0.10), 1.35, front + 0.52, 0.60, 1.40, 0.08, RGB(24, 83, 179))
		end
	end
	local topY = origin:PointToWorldSpace(V(0, crestTop, 0)).Y
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") then
			local cf, size = p.CFrame, p.Size
			local extent = (
				math.abs(cf.RightVector.Y) * size.X
				+ math.abs(cf.UpVector.Y) * size.Y
				+ math.abs(cf.LookVector.Y) * size.Z
			) / 2
			topY = math.max(topY, p.Position.Y + extent)
		end
	end
	model:SetAttribute("CrestWorldY", topY)
	model.WorldPivot = origin
	return model
end

function Themes.apply(map: Instance)
	-- Only the seven World1 lanes approved in the reference. World2 keeps its authored theme.
	if map.Name ~= "World1" then
		return
	end
	local zone = assert(map:FindFirstChild("TrainingZone"))
	for i = 1, 7 do
		local lane = assert(zone:FindFirstChild("TrainingLane" .. i)) :: Model
		local existing = lane:FindFirstChild("BiomeReferenceVisuals")
		if existing and existing:GetAttribute("Version") == LANE_VERSIONS[i] then
			updatePalette(existing, i)
			local anchor = lane:FindFirstChild("GoalSignAnchor")
			if anchor and anchor:IsA("BasePart") then
				anchor.Position =
					V(anchor.Position.X, (existing:GetAttribute("CrestWorldY") :: number) + 3.5, anchor.Position.Z)
			end
			continue
		end
		local visual = build(lane, i)
		local imported = assert(lane:FindFirstChild("ImportedField"))
		for _, item in imported:GetDescendants() do
			if item:IsA("BasePart") then
				if item:GetAttribute("BeforeBiomeTransparency") == nil then
					item:SetAttribute("BeforeBiomeTransparency", item.Transparency)
				end
				item.Transparency = 1
				for _, texture in item:GetDescendants() do
					if texture:IsA("Decal") then
						if texture:GetAttribute("BeforeBiomeTransparency") == nil then
							texture:SetAttribute("BeforeBiomeTransparency", texture.Transparency)
						end
						texture.Transparency = 1
					end
				end
			end
		end
		for _, item in lane:GetChildren() do
			if item:IsA("BasePart") and item.Name == "LaneEdge_Surface" then
				item.Transparency = 1
				for _, texture in item:GetDescendants() do
					if texture:IsA("Decal") then
						texture.Transparency = 1
					end
				end
			end
		end
		-- Hide detached historic overlays that otherwise float through the new curbs.
		local repairs = map:FindFirstChild("SurfaceRepairs")
		if repairs then
			for _, item in repairs:GetChildren() do
				local source = item:GetAttribute("SurfaceSource")
				if
					item:IsA("BasePart")
					and type(source) == "string"
					and source:find("TrainingZone." .. lane.Name .. ".", 1, true)
				then
					item.Transparency = 1
					for _, texture in item:GetChildren() do
						if texture:IsA("Decal") then
							texture.Transparency = 1
						end
					end
				end
			end
		end
		if existing then
			existing:Destroy()
		end
		visual.Parent = lane
		local anchor = lane:FindFirstChild("GoalSignAnchor")
		if anchor and anchor:IsA("BasePart") then
			anchor.Position =
				V(anchor.Position.X, (visual:GetAttribute("CrestWorldY") :: number) + 3.5, anchor.Position.Z)
		end
		task.wait()
	end
	map:SetAttribute("BiomeTrainingReferenceVersion", VERSION)
end

return Themes
