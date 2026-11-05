--!strict
-- Football-club dressing of the World1 lobby (docs/lobby-club-decor.md): a scoreboard,
-- wall-side trees and greenery, scattered footballs, a subs bench, the Champions Cup, a FREE
-- chest, a placeholder egg stand and a decorative second-world gate. The set is authored scene
-- content that is arranged by hand in Studio, so nothing rebuilds it at startup. `Decor.ensure`
-- (Edit only) builds each missing object at a spot measured from the walls and stations and never
-- moves, rebuilds or deletes an object that already exists.
local Decor = {}
local Palette = require(script.Parent.LobbyPalette)
local Kit = require(script.Parent.CourseVoxelKit)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)

local C, V = Color3.fromRGB, Vector3.new
local N = Enum.NormalId
local K = Kit.Colors
local CLUB = {
	Navy = K.Navy,
	NavyDark = C(26, 40, 78),
	Yellow = K.Yellow,
	Gold = C(255, 190, 24),
	GoldDark = C(228, 140, 14),
	GoldDeep = C(160, 92, 10),
	Cream = K.Cream,
	Screen = C(20, 28, 54),
	Bulb = K.Lamp,
	ChestWood = C(158, 84, 44),
	ChestWoodDark = C(118, 60, 34),
	Keyhole = C(60, 34, 18),
	PortalStone = C(190, 196, 214),
	PortalGlow = C(168, 110, 255),
	PortalVeil = C(118, 78, 232),
}
local FACE_AXES: { [Enum.NormalId]: { string } } = {
	[N.Top] = { "X", "Z" },
	[N.Bottom] = { "X", "Z" },
	[N.Right] = { "Y", "Z" },
	[N.Left] = { "Y", "Z" },
	[N.Front] = { "X", "Y" },
	[N.Back] = { "X", "Y" },
}
-- Particle textures from the VfxForgeUltra library (anime/stars-01, anime/shiny-01, anime/portal-01).
local FX = {
	Star = "rbxassetid://1851669703",
	Glow = "rbxassetid://1075864321",
	Rays = "rbxassetid://1053548563",
	Ring = "rbxassetid://16951115765",
	Hole = "rbxassetid://1084982817",
	Swirl = "rbxassetid://16951208736",
}

Decor.Name = "ClubDecor"
Decor.Version = 2

type Builder = {
	p: number,
	tile: number,
	world: Instance,
	ray: RaycastParams,
	shelf: { BasePart },
}

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, collide: boolean?): Part
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material = Enum.Material.Plastic
	p.Anchored = true
	-- Solid props block walking through them; everything else is purely visual.
	p.CanCollide, p.CanQuery, p.CanTouch = collide == true, collide == true, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.CastShadow = math.min(size.X, size.Y, size.Z) >= 0.6
	p.Parent = parent
	return p
end

-- Studs on every face whose sides are whole stud rows; a bottom resting on the lawn stays bare.
local function studs(b: Builder, p: BasePart, bare: { Enum.NormalId }?)
	local size = p.Size :: any
	for _, face in Enum.NormalId:GetEnumItems() do
		if bare and table.find(bare, face) then
			continue
		end
		local axes = FACE_AXES[face]
		local whole = true
		for _, axis in axes do
			local n = size[axis] / b.p
			whole = whole and math.abs(n - math.round(n)) < 0.001 and n >= 0.999
		end
		if whole then
			local t = Instance.new("Texture")
			t.Name, t.Texture, t.Face = "DecorStuds", Palette.Studs, face
			t.StudsPerTileU, t.StudsPerTileV = b.tile, b.tile
			t.Transparency = Palette.StudsTransparency
			t.Parent = p
		end
	end
end

local function block(
	b: Builder,
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	collide: boolean?,
	grounded: boolean?
): Part
	local p = part(parent, name, size, cf, color, collide)
	studs(b, p, if grounded then { N.Bottom } else nil)
	return p
end

local function model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function caption(
	p: BasePart,
	face: Enum.NormalId,
	lines: { { text: string, color: Color3, height: number } },
	width: number?
)
	local span = width or 0.92
	local axes = if face == N.Left or face == N.Right then { "Z", "Y" } else FACE_AXES[face]
	local size = p.Size :: any
	local gui = Instance.new("SurfaceGui")
	gui.Name, gui.Face = "Caption", face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(size[axes[1]], size[axes[2]]) * 32
	gui.LightInfluence, gui.MaxDistance = 0, 450
	gui.Parent = p
	local total = 0
	for _, line in lines do
		total += line.height
	end
	local y = (1 - total) / 2
	for index, line in lines do
		local label = Instance.new("TextLabel")
		label.Name = "Line" .. index
		label.Position, label.Size = UDim2.fromScale((1 - span) / 2, y), UDim2.fromScale(span, line.height)
		label.BackgroundTransparency = 1
		label.Font, label.TextScaled, label.TextColor3, label.Text = Enum.Font.FredokaOne, true, line.color, line.text
		label.TextStrokeTransparency, label.TextStrokeColor3 = 0.6, CLUB.NavyDark
		label.Parent = gui
		y += line.height
	end
end

-- The training ball mesh is a classic white-and-black football.
local function ball(parent: Instance, name: string, cf: CFrame, size: Vector3): BasePart
	local template = game.ReplicatedStorage.Shared:FindFirstChild("TrainingBall") :: BasePart?
	local p: BasePart
	if template then
		p = template:Clone()
		for _, child in p:GetChildren() do
			child:Destroy()
		end
		for key in p:GetAttributes() do
			p:SetAttribute(key, nil)
		end
	else
		local sphere = Instance.new("Part")
		sphere.Shape = Enum.PartType.Ball
		sphere.Color = CLUB.Cream
		p = sphere
	end
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Parent = parent
	return p
end

local function aabb(object: Instance): (Vector3, Vector3)
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	local nodes = object:GetDescendants()
	table.insert(nodes, object)
	for _, p in nodes do
		if p:IsA("BasePart") and p.Transparency < 1 then
			local cf, h = p.CFrame, p.Size / 2
			local e = V(
				math.abs(cf.RightVector.X) * h.X + math.abs(cf.UpVector.X) * h.Y + math.abs(cf.LookVector.X) * h.Z,
				math.abs(cf.RightVector.Y) * h.X + math.abs(cf.UpVector.Y) * h.Y + math.abs(cf.LookVector.Y) * h.Z,
				math.abs(cf.RightVector.Z) * h.X + math.abs(cf.UpVector.Z) * h.Y + math.abs(cf.LookVector.Z) * h.Z
			)
			lo, hi = lo:Min(p.Position - e), hi:Max(p.Position + e)
		end
	end
	assert(lo.X < hi.X, "Missing lobby geometry: " .. object:GetFullName())
	return lo, hi
end

-- Terrace tiers of one wall, nearest to the lobby first: inner face coordinate, lowest lip
-- (the grass shelf on top) and the column boundaries along the wall.
type Tier = { face: number, lip: number, cuts: { number }, from: number, to: number }
local function tiers(owner: Instance, axis: string, sign: number, earth: string, grass: string): { Tier }
	local byFace: { [number]: Tier } = {}
	local list: { Tier } = {}
	local along = if axis == "X" then "Z" else "X"
	for _, p in owner:GetChildren() do
		if p:IsA("BasePart") and (p.Name == earth or p.Name == grass) then
			local position, size = p.Position :: any, p.Size :: any
			local face = math.round((position[axis] + sign * size[axis] / 2) * 10) / 10
			local tier: Tier = byFace[face]
				or { face = face, lip = math.huge, cuts = {}, from = math.huge, to = -math.huge }
			if not byFace[face] then
				byFace[face] = tier
				table.insert(list, tier)
			end
			local lo, hi = position[along] - size[along] / 2, position[along] + size[along] / 2
			tier.from, tier.to = math.min(tier.from, lo), math.max(tier.to, hi)
			if p.Name == grass then
				tier.lip = math.min(tier.lip, position.Y + size.Y / 2)
			else
				for _, cut in { lo, hi } do
					local rounded = math.round(cut * 10) / 10
					if not table.find(tier.cuts, rounded) then
						table.insert(tier.cuts, rounded)
					end
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return a.face * sign > b.face * sign
	end)
	for _, tier in list do
		table.sort(tier.cuts)
		assert(tier.lip < math.huge, "Terrace tier without a grass lip: " .. owner:GetFullName())
	end
	return list
end

local function scoreboard(b: Builder, parent: Instance, center: Vector3, normal: Vector3)
	local m = model(parent, "Scoreboard")
	local frame = CFrame.lookAt(center, center + normal)
	local w, h = 31.2, 15.6
	-- The back reaches 0.1 into the terrace face it hangs on.
	block(b, m, "Housing", V(w, h, 1.2), frame * CFrame.new(0, 0, -0.5), CLUB.Navy)
	local screen = part(m, "Screen", V(w - 2.4, h - 3.6, 0.24), frame * CFrame.new(0, -0.6, -1.2), CLUB.Screen)
	screen.Material = Enum.Material.SmoothPlastic
	caption(screen, N.Front, {
		{ text = "FOOTBALL CITY", color = CLUB.Yellow, height = 0.46 },
		{ text = "KICK  •  TRAIN  •  HATCH", color = CLUB.Cream, height = 0.2 },
	}, 0.62)
	for _, y in { h / 2 + 0.6, -h / 2 - 0.6 } do
		block(b, m, "Rail", V(w + 1.2, 1.2, 2.4), frame * CFrame.new(0, y, -0.7), CLUB.Gold)
		for n = 0, 12 do
			local bulb = part(m, "Bulb", V(0.48, 0.48, 0.2), frame * CFrame.new(-14.4 + n * 2.4, y, -2.0), CLUB.Bulb)
			bulb.Material = Enum.Material.Neon
			bulb.CastShadow = false
		end
	end
	for _, x in { -12, 12 } do
		ball(m, "Emblem", frame * CFrame.new(x, -0.6, -1.5), V(4.2, 4.2, 0.6))
	end
end

local function tree(b: Builder, parent: Instance, base: Vector3, lean: Vector3, tall: boolean)
	local m = model(parent, "WallTree")
	local p = b.p
	local trunk = if tall then 6 * p else 5 * p
	block(b, m, "Root", V(3 * p, p, 3 * p), CFrame.new(base + V(0, p / 2, 0)), Palette.WoodDark, true, true)
	block(b, m, "Bole", V(2 * p, trunk, 2 * p), CFrame.new(base + V(0, p + trunk / 2 - 0.05, 0)), Palette.Wood, true)
	local crownY = p + trunk - p
	local crown = base + V(0, crownY, 0)
	block(b, m, "Canopy", V(7 * p, 4 * p, 7 * p), CFrame.new(crown + V(0, 2 * p, 0)), Palette.LeafLight)
	block(
		b,
		m,
		"CanopyTop",
		V(5 * p, 3 * p, 5 * p),
		CFrame.new(crown + V(0, 4 * p + 1.5 * p, 0) - lean * 0.5 * p),
		Palette.LeafLight
	)
	block(b, m, "CanopySide", V(4 * p, 3 * p, 4 * p), CFrame.new(crown + V(0, 1.5 * p, 0) + lean * 4 * p), Palette.Leaf)
end

local function subsBench(b: Builder, parent: Instance, base: Vector3, facing: Vector3)
	local m = model(parent, "SubsBench")
	local frame = CFrame.lookAt(base, base + facing)
	local p = b.p
	-- Local +Z runs to the back wall, X along the bench.
	block(b, m, "BackWall", V(15 * p, 4 * p, p), frame * CFrame.new(0, 2 * p - 0.05, 2 * p), CLUB.Navy, true, true)
	for _, x in { -7 * p, 7 * p } do
		block(b, m, "SideWall", V(p, 4 * p, 4 * p), frame * CFrame.new(x, 2 * p - 0.05, -p / 2), CLUB.Navy, true, true)
	end
	local roof = block(b, m, "Roof", V(16 * p, p, 6 * p), frame * CFrame.new(0, 4.5 * p - 0.05, -p / 2), CLUB.Yellow)
	caption(roof, N.Front, { { text = "HOME TEAM", color = CLUB.Navy, height = 0.86 } })
	local seat = part(m, "Seat", V(13 * p, 0.6, 2 * p), frame * CFrame.new(0, 1.5 * p, 0.5 * p), CLUB.Cream, true)
	seat.Material = Enum.Material.SmoothPlastic
	for _, x in { -5 * p, 0, 5 * p } do
		local leg = 1.5 * p - 0.25
		part(m, "SeatLeg", V(p, leg, p), frame * CFrame.new(x, leg / 2 - 0.05, 0.5 * p), K.Ink)
	end
	local seatTop = 1.5 * p + 0.3
	for _, x in { -3.6, -3.0, 4.2 } do
		local bottle = part(m, "Bottle", V(0.36, 0.84, 0.36), frame * CFrame.new(x, seatTop + 0.42, 0.2), K.Blue)
		bottle.Material = Enum.Material.SmoothPlastic
		part(m, "BottleCap", V(0.24, 0.18, 0.24), frame * CFrame.new(x, seatTop + 0.93, 0.2), CLUB.Cream)
	end
	block(b, m, "KitBag", V(2 * p, p, p), frame * CFrame.new(9.6 * p, p / 2 - 0.05, 0), CLUB.NavyDark, true, true)
	part(m, "KitBagStrap", V(0.3, p + 0.12, p + 0.12), frame * CFrame.new(9.6 * p, p / 2 + 0.01, 0), CLUB.Yellow)
	local cooler = part(m, "Cooler", V(1.8, 2.4, 1.8), frame * CFrame.new(-9.6 * p, 1.2 - 0.05, 0), K.Orange, true)
	cooler.Material = Enum.Material.SmoothPlastic
	part(m, "CoolerLid", V(1.92, 0.36, 1.92), frame * CFrame.new(-9.6 * p, 2.4 + 0.13, 0), CLUB.Cream)
end

local function trophy(b: Builder, parent: Instance, base: Vector3, facing: Vector3)
	local m = model(parent, "TrophyMonument")
	local frame = CFrame.lookAt(base, base + facing)
	local p = b.p
	local y = -0.05
	-- The plinth carries the lobby studs; the cup stays smooth so its gold reads as metal.
	local function layer(name: string, n: number, rows: number, color: Color3, collide: boolean?): Part
		local size = V(n * p, rows * p, n * p)
		local cf = frame * CFrame.new(0, y + size.Y / 2, 0)
		local piece = if name:match("^Cup")
			then part(m, name, size, cf, color, collide)
			else block(b, m, name, size, cf, color, collide, y < 0)
		y += size.Y
		return piece
	end
	layer("PlinthBase", 10, 1, Palette.Stone, true)
	local plinth = layer("Plinth", 8, 3, CLUB.Navy, true)
	-- Captioned towards the kick-zone path and towards the Hub.
	for _, face in { N.Front, N.Right } do
		caption(plinth, face, {
			{ text = "CHAMPIONS", color = CLUB.Gold, height = 0.42 },
			{ text = "CUP", color = CLUB.Cream, height = 0.3 },
		}, 0.86)
	end
	layer("PlinthCap", 9, 1, Palette.StoneLight, true)
	layer("CupFoot", 5, 1, CLUB.GoldDark, true)
	layer("CupStem", 2, 3, CLUB.Gold, true)
	layer("CupKnot", 3, 1, CLUB.GoldDark, true)
	layer("CupBase", 4, 1, CLUB.Gold, true)
	local bowlFrom = y
	local bowl = layer("CupBowl", 6, 4, CLUB.Gold, true)
	layer("CupRim", 7, 1, CLUB.GoldDark, true)
	for _, piece in m:GetChildren() do
		if piece:IsA("BasePart") and piece.Name:match("^Cup") then
			piece.Material = Enum.Material.SmoothPlastic
		end
	end
	local inside = part(m, "CupHollow", V(5 * p, 0.12, 5 * p), frame * CFrame.new(0, y + 0.06 - 0.02, 0), CLUB.GoldDeep)
	inside.Material = Enum.Material.SmoothPlastic
	-- Handles: an arm out of the bowl's upper side, a drop and a short return.
	for _, side in { -1, 1 } do
		local x = side * (3 * p + p)
		local function handle(name: string, size: Vector3, offset: Vector3)
			local piece = part(m, name, size, frame * CFrame.new(offset), CLUB.Gold)
			piece.Material = Enum.Material.SmoothPlastic
		end
		handle("HandleTop", V(2 * p, p, p), V(side * (3 * p + p) - side * 0.05, bowlFrom + 3.5 * p, 0))
		handle("HandleDrop", V(p, 2 * p, p), V(x + side * 0.5 * p, bowlFrom + 2 * p, 0))
		handle("HandleFoot", V(p, p, p), V(side * (3.5 * p) - side * 0.05, bowlFrom + 0.5 * p, 0))
	end
	ball(m, "CupBall", frame * CFrame.new(0, y + 2, 0), V(4.4, 4.4, 4.4))
	local glow = Instance.new("Attachment")
	glow.Name = "SparkleAnchor"
	glow.Position = V(0, y + 2 - (bowlFrom + 2 * p), 0)
	glow.Parent = bowl
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Name = "TrophySparkle"
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(C(255, 236, 150))
	sparkle.LightEmission = 0.8
	sparkle.Rate = 5
	sparkle.Lifetime = NumberRange.new(1.2, 2)
	sparkle.Speed = NumberRange.new(0.5, 1.2)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.9),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkle.Shape = Enum.ParticleEmitterShape.Box
	sparkle.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	sparkle.Parent = glow
end

local function floorAt(b: Builder, x: number, z: number): number
	local hit = workspace:Raycast(V(x, 120, z), V(0, -200, 0), b.ray)
	assert(hit, ("No lawn under lobby decor at %.1f, %.1f"):format(x, z))
	return hit.Position.Y
end

-- Terrace shelves are visual-only (CanQuery off), so their top is read from the grass parts
-- whose footprint holds the point instead of a raycast.
local function shelfAt(b: Builder, x: number, z: number): number
	local best = -math.huge
	for _, p in b.shelf do
		local position, half = p.Position, p.Size / 2
		if math.abs(x - position.X) < half.X and math.abs(z - position.Z) < half.Z then
			best = math.max(best, position.Y + half.Y)
		end
	end
	assert(best > -math.huge, ("No terrace shelf under lobby decor at %.1f, %.1f"):format(x, z))
	return best
end

local function sequence(points: { { number } }): NumberSequence
	local keys = {}
	for _, point in points do
		table.insert(keys, NumberSequenceKeypoint.new(point[1], point[2], point[3] or 0))
	end
	return NumberSequence.new(keys)
end

local function emitter(parent: Instance, name: string, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.LightInfluence = 0
	for key, value in props do
		(e :: any)[key] = value
	end
	e.Parent = parent
	return e
end

local function light(parent: Instance, color: Color3, range: number, brightness: number)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness, l.Shadows = color, range, brightness, false
	l.Parent = parent
end

-- Smooth metal or glow trim: no studs, never solid.
local function trim(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local p = part(parent, name, size, cf, color)
	p.Material = Enum.Material.SmoothPlastic
	return p
end

-- Wall greenery in the lobby's studded block style. Each piece is built in a frame whose -Z
-- faces the lobby and X runs along the wall; every layer sinks 0.05 into the one below.
type Layer = { name: string, size: { number }, at: { number }, color: Color3 }
local WALL_PIECES: { [string]: { Layer } } = {
	Bush = {
		{ name = "Bush", size = { 4, 2, 3 }, at = { 0, 0, 0 }, color = Palette.Leaf },
		{ name = "BushTop", size = { 3, 1, 2 }, at = { -0.4, 2, 0 }, color = Palette.LeafLight },
	},
	Hedge = {
		{ name = "Hedge", size = { 6, 2, 3 }, at = { 0, 0, 0 }, color = Palette.Leaf },
		{ name = "HedgeBump", size = { 2, 1, 2 }, at = { -1.6, 2, 0.2 }, color = Palette.LeafLight },
		{ name = "HedgeBump", size = { 2, 1, 2 }, at = { 1.7, 2, -0.2 }, color = Palette.LeafLight },
	},
	Tree = {
		{ name = "Trunk", size = { 1, 3, 1 }, at = { 0, 0, 0 }, color = Palette.Wood },
		{ name = "Canopy", size = { 4, 3, 4 }, at = { 0, 3, 0 }, color = Palette.LeafLight },
		{ name = "CanopyTop", size = { 2, 1, 2 }, at = { 0.4, 6, 0.3 }, color = Palette.LeafLight },
		{ name = "CanopySide", size = { 2, 2, 2 }, at = { -1.6, 3.4, -0.6 }, color = Palette.Leaf },
	},
	Pine = {
		{ name = "Trunk", size = { 1, 2, 1 }, at = { 0, 0, 0 }, color = Palette.WoodDark },
		{ name = "PineLow", size = { 4, 2, 4 }, at = { 0, 2, 0 }, color = Palette.Leaf },
		{ name = "PineMid", size = { 3, 2, 3 }, at = { 0, 4, 0 }, color = Palette.Leaf },
		{ name = "PineHigh", size = { 2, 2, 2 }, at = { 0, 6, 0 }, color = Palette.LeafLight },
		{ name = "PineTip", size = { 1, 1, 1 }, at = { 0, 8, 0 }, color = Palette.LeafLight },
	},
	Rock = {
		{ name = "Rock", size = { 3, 2, 3 }, at = { 0, 0, 0 }, color = Palette.Stone },
		{ name = "RockTop", size = { 2, 1, 2 }, at = { -0.4, 2, 0.3 }, color = Palette.StoneLight },
		{ name = "RockSide", size = { 2, 1, 2 }, at = { 2.2, 0, -0.3 }, color = Palette.Stone },
	},
	MossRock = {
		{ name = "Rock", size = { 4, 2, 3 }, at = { 0, 0, 0 }, color = Palette.Stone },
		{ name = "Moss", size = { 3, 1, 2 }, at = { 0.4, 2, 0.2 }, color = Palette.LeafLight },
	},
	Boulder = {
		{ name = "Boulder", size = { 3, 3, 3 }, at = { 0, 0, 0 }, color = Palette.StoneLight },
		{ name = "BoulderSide", size = { 2, 2, 2 }, at = { 2.2, 0, 0.3 }, color = Palette.Stone },
		{ name = "BoulderMoss", size = { 2, 1, 2 }, at = { -0.3, 3, -0.2 }, color = Palette.Leaf },
	},
}

-- `at` is in stud rows: X/Z of the layer centre and Y of its base above the shelf.
local function wallPiece(b: Builder, parent: Instance, kind: string, frame: CFrame)
	local m = model(parent, "Wall" .. kind)
	local p = b.p
	for _, layer in WALL_PIECES[kind] do
		local size = V(layer.size[1], layer.size[2], layer.size[3]) * p
		local grounded = layer.at[2] == 0
		local y = layer.at[2] * p + size.Y / 2 - 0.05 * (if grounded then 1 else 2)
		local cf = frame * CFrame.new(layer.at[1] * p, y, layer.at[3] * p)
		block(b, m, layer.name, size, cf, layer.color, false, grounded)
	end
end

-- Wall, terrace tier (1 = lowest shelf), position along the wall and kind of each wall piece.
local GREENERY: { { wall: string, tier: number, at: number, kind: string } } = {
	{ wall = "West", tier = 1, at = 133, kind = "Bush" },
	{ wall = "West", tier = 2, at = 145, kind = "Pine" },
	{ wall = "West", tier = 1, at = 158, kind = "MossRock" },
	{ wall = "West", tier = 1, at = 210, kind = "Hedge" },
	{ wall = "West", tier = 2, at = 229, kind = "Rock" },
	{ wall = "West", tier = 1, at = 247, kind = "Tree" },
	{ wall = "East", tier = 1, at = 131, kind = "Boulder" },
	{ wall = "East", tier = 2, at = 172, kind = "Bush" },
	{ wall = "East", tier = 1, at = 192, kind = "Pine" },
	{ wall = "East", tier = 1, at = 207, kind = "Hedge" },
	{ wall = "East", tier = 2, at = 236, kind = "Tree" },
	{ wall = "East", tier = 1, at = 250, kind = "MossRock" },
	{ wall = "Rear", tier = 2, at = 2, kind = "Pine" },
	{ wall = "Rear", tier = 2, at = 30, kind = "Tree" },
	{ wall = "Rear", tier = 2, at = 80, kind = "Boulder" },
	{ wall = "Rear", tier = 2, at = 104, kind = "Bush" },
}

-- Loose footballs: x, z, diameter; `shelf` balls rest on a terrace shelf instead of the lawn.
local BALLS: { { x: number, z: number, size: number, shelf: boolean? } } = {
	{ x = 22.6, z = 152.4, size = 2.4 },
	{ x = 20.6, z = 213, size = 2.2 },
	{ x = 100.6, z = 219.4, size = 2.2 },
	{ x = 101, z = 131, size = 2.4 },
	{ x = 46.4, z = 160.6, size = 2 },
	{ x = 47, z = 210, size = 2.2 },
	{ x = -7.6, z = 139, size = 2, shelf = true },
	{ x = 123.4, z = 214, size = 2, shelf = true },
}

local function coin(parent: Instance, cf: CFrame): Part
	local p = trim(parent, "Coin", V(0.3, 1.5, 1.5), cf * CFrame.Angles(0, 0, math.pi / 2), CLUB.Gold)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- A chunky simulator-style treasure chest standing on the lawn: studded wooden box, rounded lid,
-- thick gold bands, a big lock and coins spilled in front.
local function freeChest(b: Builder, parent: Instance, base: Vector3, facing: Vector3)
	local m = model(parent, "FreeChest")
	m:SetAttribute("Purpose", "Decorative free-reward chest; it has no interaction yet")
	local frame = CFrame.lookAt(base, base + facing)
	local p = b.p
	local w, h, d = 5 * p, 3 * p, 3 * p
	local bottom = -0.05
	local top = bottom + h
	local body =
		block(b, m, "ChestBody", V(w, h, d), frame * CFrame.new(0, bottom + h / 2, 0), CLUB.ChestWood, true, true)
	-- The lid is a cylinder along the chest width; its lower half is hidden inside the box.
	local lid = part(m, "Lid", V(w, d, d), frame * CFrame.new(0, top, 0), CLUB.ChestWood, true)
	lid.Shape, lid.Material = Enum.PartType.Cylinder, Enum.Material.SmoothPlastic
	-- Gold bands sit a little proud of the wood so no face is shared.
	for _, side in { -1, 1 } do
		local x = side * (w / 2 - 0.2)
		trim(m, "SideStrap", V(0.5, h + 0.1, d + 0.2), frame * CFrame.new(x, bottom + h / 2, 0), CLUB.Gold)
		local band = trim(m, "LidBand", V(0.5, d + 0.24, d + 0.24), frame * CFrame.new(x, top, 0), CLUB.Gold)
		band.Shape = Enum.PartType.Cylinder
	end
	trim(m, "BottomBand", V(w + 0.2, 0.45, d + 0.2), frame * CFrame.new(0, bottom + 0.3, 0), CLUB.GoldDark)
	trim(m, "RimBand", V(w + 0.2, 0.4, d + 0.2), frame * CFrame.new(0, top - 0.25, 0), CLUB.GoldDark)
	trim(m, "LockPlate", V(1.4, 1.8, 0.3), frame * CFrame.new(0, top - 0.3, -d / 2 - 0.12), CLUB.Gold)
	trim(m, "Keyhole", V(0.35, 0.6, 0.12), frame * CFrame.new(0, top - 0.5, -d / 2 - 0.3), CLUB.Keyhole)
	local plaque = trim(m, "Plaque", V(3.6, 1.2, 0.2), frame * CFrame.new(0, bottom + 1.25, -d / 2 - 0.05), CLUB.Navy)
	caption(plaque, N.Front, { { text = "FREE", color = CLUB.Gold, height = 0.9 } }, 0.8)
	-- Coins spilled on the lawn: a few flat ones, a short stack and one leaning on the chest.
	for _, spot in { V(-3.5, 0.1, -2.3), V(2.9, 0.1, -2.6), V(-1.3, 0.1, -3.1), V(3.6, 0.1, -0.4) } do
		coin(m, frame * CFrame.new(spot) * CFrame.Angles(0, spot.X, 0))
	end
	for level = 0, 2 do
		coin(m, frame * CFrame.new(-4, 0.1 + level * 0.28, 0.6) * CFrame.Angles(0, level * 0.5, 0))
	end
	coin(m, frame * CFrame.new(1.9, 0.68, -d / 2 - 0.3) * CFrame.Angles(math.rad(-70), 0, 0))
	-- Gold VFX: glitter rising off the lid, a soft halo and slow star rays above it.
	emitter(lid, "GoldGlitter", {
		Texture = FX.Star,
		Color = ColorSequence.new(C(255, 246, 190), C(255, 212, 57)),
		LightEmission = 1,
		Brightness = 3,
		Size = sequence({ { 0, 0 }, { 0.25, 0.6 }, { 1, 0 } }),
		Transparency = sequence({ { 0, 0.2 }, { 1, 1 } }),
		Lifetime = NumberRange.new(1.2, 2),
		Rate = 10,
		Speed = NumberRange.new(1.5, 3),
		SpreadAngle = Vector2.new(25, 25),
		Acceleration = V(0, -0.6, 0),
		EmissionDirection = N.Top,
		Rotation = NumberRange.new(-180, 180),
		RotSpeed = NumberRange.new(-90, 90),
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
	})
	local halo = Instance.new("Attachment")
	halo.Name = "GoldHalo"
	halo.Position = V(0, d / 2 + 0.6, 0)
	halo.Parent = lid
	emitter(halo, "GoldGlow", {
		Texture = FX.Glow,
		Color = ColorSequence.new(C(255, 212, 57)),
		LightEmission = 1,
		Brightness = 2,
		Size = NumberSequence.new(6),
		Transparency = sequence({ { 0, 1 }, { 0.5, 0.72 }, { 1, 1 } }),
		Lifetime = NumberRange.new(2),
		Rate = 1.5,
		Speed = NumberRange.new(0),
		LockedToPart = true,
	})
	emitter(halo, "GoldRays", {
		Texture = FX.Rays,
		Color = ColorSequence.new(C(255, 227, 114)),
		LightEmission = 1,
		Brightness = 1.5,
		Size = sequence({ { 0, 3.5 }, { 1, 6.5 } }),
		Transparency = sequence({ { 0, 1 }, { 0.5, 0.76 }, { 1, 1 } }),
		Lifetime = NumberRange.new(1.6),
		Rate = 6,
		Speed = NumberRange.new(0),
		Rotation = NumberRange.new(-180, 180),
		RotSpeed = NumberRange.new(-12, 12),
		LockedToPart = true,
		ZOffset = -0.5,
	})
	light(lid, C(255, 200, 80), 14, 1.6)
	local sign = Instance.new("BillboardGui")
	sign.Name = "FreeSign"
	sign.Size = UDim2.fromScale(8, 3)
	sign.StudsOffsetWorldSpace = V(0, 5.4, 0)
	sign.LightInfluence, sign.MaxDistance = 0, 160
	sign.Parent = body
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font, label.TextScaled, label.Text = Enum.Font.FredokaOne, true, "FREE"
	label.TextColor3 = C(255, 255, 255)
	label.Parent = sign
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(C(255, 238, 140), C(255, 170, 20))
	gradient.Rotation = 90
	gradient.Parent = label
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness = CLUB.GoldDeep, 3
	stroke.Parent = label
end

-- The library gold egg (shell, bands, studs and gem) resized to `height` with its gem facing -Z.
-- Parts are resized by hand rather than with Model:ScaleTo, so the model keeps scale 1 like the
-- shop eggs and the floating-egg controller lifts and orbits it by the same amounts.
local function goldEgg(parent: Instance, frame: CFrame, height: number): Model
	local library = game:GetService("ServerStorage"):FindFirstChild("AssetLibrary")
	local source = library and library:FindFirstChild("SimpleEggs")
	local shell = source and source:FindFirstChild("Gold Egg") :: BasePart?
	local egg = model(parent, "GoldEgg")
	if not (source and shell) then
		local p =
			part(egg, "Shell", V(height * 0.7, height, height * 0.7), frame * CFrame.new(0, height / 2, 0), CLUB.Gold)
		p.Shape = Enum.PartType.Ball
		p.Material = Enum.Material.Metal
		return egg
	end
	for _, piece in source:GetChildren() do
		if piece:IsA("BasePart") and piece.Name:match("^Gold ") and (piece.Position - shell.Position).Magnitude < 3 then
			local clone = piece:Clone()
			clone.Anchored, clone.CanCollide, clone.CanQuery, clone.CanTouch = true, false, false, false
			clone.Parent = egg
		end
	end
	local body = egg:FindFirstChild("Gold Egg") :: BasePart
	-- The imported shell carries a tilted pivot offset; pivot on the shell itself instead.
	body.PivotOffset = CFrame.identity
	egg.PrimaryPart = body
	local k = height / shell.Size.Y
	local pivot = body.CFrame
	for _, piece in egg:GetChildren() do
		if piece:IsA("BasePart") then
			local offset = pivot:ToObjectSpace(piece.CFrame)
			piece.Size *= k
			piece.CFrame = pivot * CFrame.new(offset.Position * k) * offset.Rotation
		end
	end
	local center = frame * CFrame.new(0, height / 2, 0)
	egg:PivotTo(CFrame.new(center.Position) * body.CFrame.Rotation)
	local gem = egg:FindFirstChild("Gold central gemstone") :: BasePart?
	if gem then
		-- Spin about the vertical axis until the gem points along the stand's facing (-Z).
		local offset = center:PointToObjectSpace(gem.Position)
		local turn = math.atan2(offset.X, -offset.Z)
		egg:PivotTo(center * CFrame.Angles(0, turn, 0) * center:ToObjectSpace(egg:GetPivot()))
	end
	return egg
end

-- The premium egg copies the shop's display: the golden octagonal seat pad of the Volcanic slot
-- (`template`), a 7.5-stud egg floating above it and the shop caption (`sign`) restyled as a
-- placeholder. The client EggDisplay floats the egg and its caption like the shop eggs.
local EGG_HEIGHT, EGG_GAP, CAPTION_GAP = 7.5, 0.06, 1.8
local function eggStand(
	b: Builder,
	parent: Instance,
	base: Vector3,
	facing: Vector3,
	template: Instance?,
	sign: Instance?
)
	local m = model(parent, "PremiumEggStand")
	m:SetAttribute("Purpose", "Placeholder display for a future premium egg; it has no interaction yet")
	local frame = CFrame.lookAt(base, base + facing) * CFrame.new(0, -0.05, 0)
	local seatY = 0.8
	local pad = template and template:FindFirstChild("SeatPad")
	local center = template and template:FindFirstChild("SeatCenter") :: BasePart?
	if pad and pad:IsA("Model") and center then
		local box, size = pad:GetBoundingBox()
		local bottom = box.Y - size.Y / 2
		local origin = CFrame.new(center.Position.X, bottom, center.Position.Z)
		seatY = center.Position.Y - bottom
		local copy = pad:Clone()
		for _, node in copy:GetDescendants() do
			for key in node:GetAttributes() do
				node:SetAttribute(key, nil)
			end
			if node:IsA("BasePart") then
				node.Anchored, node.CanTouch, node.CanCollide, node.CanQuery = true, false, true, true
			end
		end
		copy:PivotTo(frame * origin:ToObjectSpace(copy:GetPivot()))
		copy.Parent = m
	else
		block(b, m, "SeatPad", V(8 * b.p, b.p, 8 * b.p), frame * CFrame.new(0, b.p / 2, 0), Palette.Stone, true, true)
		seatY = b.p
	end
	local egg = goldEgg(m, frame * CFrame.new(0, seatY + EGG_GAP, 0), EGG_HEIGHT)
	egg:SetAttribute("ElementalEggTheme", "Celestial")
	egg:AddTag("FloatingDisplayEgg")
	local anchor = part(
		m,
		"EggSignAnchor",
		V(0.06, 0.06, 0.06),
		frame * CFrame.new(0, seatY + EGG_GAP + EGG_HEIGHT + CAPTION_GAP, 0),
		CLUB.Gold
	)
	anchor.Transparency = 1
	anchor:SetAttribute("PartRole", "SignAnchor")
	anchor:SetAttribute("Purpose", "Holds the premium egg caption; EggDisplay lifts it with the floating egg")
	if sign then
		local copy = sign:Clone()
		copy.Name = "EggSign"
		for key in copy:GetAttributes() do
			copy:SetAttribute(key, nil)
		end
		local title = copy:FindFirstChild("Title", true)
		if title and title:IsA("TextLabel") then
			title.Text = "Premium Egg"
			local gradient = title:FindFirstChildWhichIsA("UIGradient")
			if gradient then
				gradient.Color = ColorSequence.new(C(255, 238, 140), C(255, 170, 20))
			end
		end
		local amount = copy:FindFirstChild("Amount", true)
		if amount and amount:IsA("TextLabel") then
			amount.Text, amount.TextColor3 = "Coming Soon", C(255, 255, 255)
		end
		local currency = copy:FindFirstChild("Currency", true)
		if currency and currency:IsA("GuiObject") then
			currency.Visible = false
		end
		if copy:IsA("BillboardGui") then
			-- The source sign is adorned to its own anchor; this copy follows its new parent.
			copy.Adornee = nil :: any
			copy.StudsOffsetWorldSpace = Vector3.zero
		end
		copy.Parent = anchor
	end
end

local function worldPortal(b: Builder, parent: Instance, base: Vector3, facing: Vector3)
	local m = model(parent, "WorldPortal")
	m:SetAttribute("Purpose", "Decorative gate for a future second world; it does not teleport")
	local frame = CFrame.lookAt(base, base + facing)
	local p = b.p
	block(b, m, "Platform", V(14 * p, p, 6 * p), frame * CFrame.new(0, p / 2 - 0.05, 0), Palette.Stone, true, true)
	local step =
		block(b, m, "Step", V(10 * p, p, 4 * p), frame * CFrame.new(0, 1.5 * p - 0.1, 0), Palette.StoneLight, true)
	local floor = 2 * p - 0.1
	-- Two-stud feet stand on the platform and rise above the step, so no top face is shared.
	local footTop = 3 * p - 0.1
	local top = footTop - 0.05 + 9 * p
	for _, side in { -1, 1 } do
		block(
			b,
			m,
			"PillarFoot",
			V(3 * p, 2 * p, 3 * p),
			frame * CFrame.new(side * 5 * p, footTop - p, 0),
			Palette.Stone,
			true
		)
		block(
			b,
			m,
			"Pillar",
			V(2 * p, 9 * p, 2 * p),
			frame * CFrame.new(side * 5 * p, top - 4.5 * p, 0),
			CLUB.PortalStone,
			true
		)
		local glow = trim(
			m,
			"InnerGlow",
			V(0.3, top - floor, 0.6),
			frame * CFrame.new(side * (4 * p - 0.1), (floor + top) / 2, 0),
			CLUB.PortalGlow
		)
		glow.Material = Enum.Material.Neon
	end
	local height = top - floor
	local lintel =
		block(b, m, "Lintel", V(12 * p, 2 * p, 3 * p), frame * CFrame.new(0, top + p - 0.05, 0), CLUB.Navy, true)
	caption(lintel, N.Front, {
		{ text = "WORLD 2", color = CLUB.Gold, height = 0.5 },
		{ text = "COMING SOON", color = CLUB.Cream, height = 0.3 },
	}, 0.8)
	local topGlow = trim(m, "InnerGlow", V(8 * p, 0.3, 0.6), frame * CFrame.new(0, top - 0.1, 0), CLUB.PortalGlow)
	topGlow.Material = Enum.Material.Neon
	block(b, m, "Crest", V(4 * p, p, 2 * p), frame * CFrame.new(0, top + 2.5 * p - 0.1, 0), CLUB.PortalStone)
	local gem = trim(
		m,
		"CrestGem",
		V(1.2, 1.2, 1.2),
		frame * CFrame.new(0, top + 3 * p + 0.65, 0) * CFrame.Angles(0, 0, math.pi / 4),
		CLUB.PortalGlow
	)
	gem.Material = Enum.Material.Neon
	-- A see-through veil blocks the doorway; the swirl hovers just in front of it.
	local veil = part(
		m,
		"Veil",
		V(8 * p - 0.5, height - 0.4, 0.24),
		frame * CFrame.new(0, floor + height / 2, 0),
		CLUB.PortalVeil,
		true
	)
	veil.Material, veil.Transparency, veil.CastShadow = Enum.Material.SmoothPlastic, 0.45, false
	local swirl = Instance.new("Attachment")
	swirl.Name = "PortalSwirl"
	swirl.Position = V(0, 0, -0.3)
	swirl.Parent = veil
	local disc = {
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection = N.Front,
		Speed = NumberRange.new(0.001),
		LockedToPart = true,
		Lifetime = NumberRange.new(1),
	}
	local function layerOf(extra: { [string]: any }): { [string]: any }
		local props = table.clone(disc)
		for key, value in extra do
			props[key] = value
		end
		return props
	end
	emitter(
		swirl,
		"PortalRing",
		layerOf({
			Texture = FX.Ring,
			Color = ColorSequence.new(C(205, 165, 255)),
			LightEmission = 1,
			Brightness = 1.5,
			Size = NumberSequence.new(9.6),
			Transparency = sequence({ { 0, 1 }, { 0.1, 0 }, { 1, 0 } }),
			Rate = 10,
			RotSpeed = NumberRange.new(400),
			ZOffset = 1,
		})
	)
	emitter(
		swirl,
		"PortalCore",
		layerOf({
			Texture = FX.Hole,
			Color = ColorSequence.new(C(34, 14, 78)),
			LightEmission = 0,
			Size = NumberSequence.new(6.6),
			Transparency = sequence({ { 0, 1 }, { 0.1, 0 }, { 1, 0 } }),
			Rate = 5,
			RotSpeed = NumberRange.new(400),
			ZOffset = 0.5,
		})
	)
	emitter(
		swirl,
		"PortalPull",
		layerOf({
			Texture = FX.Swirl,
			Color = ColorSequence.new(C(150, 232, 255)),
			LightEmission = 1,
			Brightness = 3,
			Size = sequence({ { 0, 14 }, { 1, 5 } }),
			Transparency = sequence({ { 0, 1 }, { 0.5, 0 }, { 1, 1 } }),
			Lifetime = NumberRange.new(1.2),
			Rate = 4,
			RotSpeed = NumberRange.new(250),
		})
	)
	emitter(step, "PortalMotes", {
		Texture = FX.Star,
		Color = ColorSequence.new(C(236, 222, 255), C(178, 132, 255)),
		LightEmission = 1,
		Brightness = 2,
		Size = sequence({ { 0, 0 }, { 0.3, 0.45 }, { 1, 0 } }),
		Lifetime = NumberRange.new(2, 3),
		Rate = 6,
		Speed = NumberRange.new(1, 2),
		SpreadAngle = Vector2.new(15, 15),
		EmissionDirection = N.Top,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
	})
	light(veil, CLUB.PortalGlow, 16, 1.2)
end

-- Builds every missing club decor object; objects that already exist are left exactly as they are.
function Decor.ensure(world: any): { string }
	local lobby = world:FindFirstChild("Lobby")
	local environment = lobby and lobby:FindFirstChild("Environment")
	assert(environment and lobby:FindFirstChild("Paths"), "World1 lobby is not built")
	local root = environment:FindFirstChild(Decor.Name) or folder(environment, Decor.Name)
	root:SetAttribute("ClubDecorVersion", Decor.Version)

	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Include
	ray.FilterDescendantsInstances = { lobby.Geometry }
	ray.RespectCanCollide = true
	local shelf: { BasePart } = {}
	for _, terraces in { environment.SideTerraces1, environment.SideTerraces2, environment.RearTerraces } do
		for _, piece in terraces:GetChildren() do
			if piece:IsA("BasePart") and (piece.Name == "GrassShelf" or piece.Name == "RearGrassLedge") then
				table.insert(shelf, piece)
			end
		end
	end
	local p = Palette.GroundStudPitch * Scale.factor(world)
	local b: Builder = { p = p, tile = p * Palette.StudsPerTexture, world = world, ray = ray, shelf = shelf }

	local walls: { [string]: { Tier } } = {
		West = tiers(environment.SideTerraces1, "X", 1, "TerraceEarth", "GrassShelf"),
		East = tiers(environment.SideTerraces2, "X", -1, "TerraceEarth", "GrassShelf"),
		Rear = tiers(environment.RearTerraces, "Z", -1, "RearEarthLedge", "RearGrassLedge"),
	}
	for _, list in walls do
		assert(#list >= 3, "Lobby terraces changed shape")
	end
	local west, east = walls.West, walls.East
	local paths = lobby.Paths
	local courtLo, courtHi = aabb(paths.BallCourt)
	local plazaLo = aabb(paths.EggPlaza)
	local northLo, northHi = aabb(paths.NorthPath)
	local kickLo = aabb(paths.KickZonePath)
	local _, kickZoneHi = aabb(lobby.KickZone)
	local _, trainingHi = aabb(paths.TrainingFrame)
	local shopLo, shopHi = aabb(lobby.BallShop.Structure)
	local axis = (shopLo.Z + shopHi.Z) / 2
	local westFace, eastFace = west[1].face, east[1].face
	local southFrom, southTo = kickZoneHi.Z, courtLo.Z
	local southMid = (southFrom + southTo) / 2
	local westLawn = westFace + 6.8

	local built = {}
	local function want(name: string, build: () -> ())
		if not root:FindFirstChild(name) then
			build()
			table.insert(built, name)
		end
	end
	want("Scoreboard", function()
		scoreboard(b, root, V(west[2].face, west[1].lip + 12.2, axis), V(1, 0, 0))
	end)
	want("Trees", function()
		local trees = folder(root, "Trees")
		for _, z in { southFrom + 5.4, southTo - 6.6 } do
			tree(b, trees, V(westLawn, floorAt(b, westLawn, z), z), V(1, 0, 0), z > southMid)
		end
		local benchX = (northHi.X + eastFace) / 2
		for _, x in { northHi.X + 5, eastFace - 6.8 } do
			local z = (trainingHi.Z + plazaLo.Z) / 2
			tree(b, trees, V(x, floorAt(b, x, z), z), V(if x < benchX then 1 else -1, 0, 0), x > benchX)
		end
	end)
	want("SubsBench", function()
		local x, z = (northHi.X + eastFace) / 2, plazaLo.Z - 6.4
		subsBench(b, root, V(x, floorAt(b, x, z), z), V(0, 0, -1))
	end)
	want("TrophyMonument", function()
		local x = (westLawn + 6 + kickLo.X) / 2
		trophy(b, root, V(x, floorAt(b, x, southMid), southMid), V(1, 0, 0))
	end)
	want("WallGreenery", function()
		local greenery = folder(root, "WallGreenery")
		local normals: { [string]: Vector3 } = { West = V(1, 0, 0), East = V(-1, 0, 0), Rear = V(0, 0, -1) }
		for _, spot in GREENERY do
			local list = walls[spot.wall]
			-- Middle of the shelf strip between this tier's face and the next one back.
			local depth = (list[spot.tier].face + list[spot.tier + 1].face) / 2
			local rear = spot.wall == "Rear"
			local x, z = (if rear then spot.at else depth), (if rear then depth else spot.at)
			local base = V(x, shelfAt(b, x, z), z)
			local frame = CFrame.lookAt(base, base + normals[spot.wall])
			wallPiece(b, greenery, spot.kind, frame)
		end
	end)
	want("LobbyBalls", function()
		local balls = folder(root, "LobbyBalls")
		for index, spot in BALLS do
			local y = if spot.shelf then shelfAt(b, spot.x, spot.z) else floorAt(b, spot.x, spot.z)
			local turn = CFrame.Angles(index * 0.9, index * 1.7, index * 0.4)
			ball(balls, "Football", CFrame.new(spot.x, y + spot.size / 2 - 0.05, spot.z) * turn, V(1, 1, 1) * spot.size)
		end
	end)
	local besideShop = (courtHi.X + northLo.X) / 2
	want("FreeChest", function()
		local z = axis + 16.2
		freeChest(b, root, V(besideShop, floorAt(b, besideShop, z), z), V(1, 0, 0))
	end)
	want("PremiumEggStand", function()
		local z = axis - 16.2
		local shop = lobby:FindFirstChild("EggShop")
		local stand = shop and shop:FindFirstChild("EggStand")
		local template = stand and stand:FindFirstChild("Volcanic")
		local sign = shop and shop:FindFirstChild("EggSign", true)
		eggStand(b, root, V(besideShop, floorAt(b, besideShop, z), z), V(1, 0, 0), template, sign)
	end)
	want("WorldPortal", function()
		local x, z = westFace + 21, southMid
		worldPortal(b, root, V(x, floorAt(b, x, z), z), V(1, 0, 0))
	end)
	return built
end

return Decor
