--!strict
-- Zone-local voxel kit on the shared ground grid (docs/course-voxel.md).
-- u runs across the field (its X), h up from the field top, s along from the lobby edge.
-- Grid lines: u = n * p, s = m * p; levels base/terrace/lawn are whole rows above the pitch.
local Kit = {}
local Palette = require(script.Parent.LobbyPalette)
local HDStuds = require(script.Parent.HDStuds)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local C = Color3.fromRGB
local N = Enum.NormalId
local SIDES = { N.Top, N.Front, N.Back, N.Left, N.Right }

-- Flush layers clear VerifyFootballCitySurfaces' 0.035 coplanar tolerance.
Kit.Layer = 0.05

Kit.Colors = {
	Rim = Palette.PathEdge,
	Path = Palette.Path,
	PathDark = Palette.PathChecker,
	Curb = Palette.PathCurb,
	CurbLight = C(206, 212, 218),
	Stone = Palette.Stone,
	StoneLight = Palette.StoneLight,
	StoneDark = C(116, 131, 139),
	Lawn = Palette.Lawn,
	LawnDark = Palette.LawnChecker,
	LawnLight = C(150, 228, 86),
	Leaf = Palette.Leaf,
	LeafLight = Palette.LeafLight,
	LeafDark = C(34, 128, 48),
	Blossom = C(255, 168, 204),
	BlossomLight = C(255, 212, 230),
	BlossomDark = C(230, 112, 164),
	Autumn = C(250, 146, 44),
	AutumnLight = C(255, 196, 72),
	AutumnDark = C(212, 88, 34),
	Sand = C(242, 214, 150),
	SandDark = C(222, 188, 118),
	Navy = C(38, 60, 112),
	Cream = C(250, 240, 214),
	Pink = C(244, 120, 176),
	Green = C(70, 196, 92),
	Pine = C(46, 140, 82),
	PineLight = C(72, 172, 96),
	Earth = Palette.Earth,
	EarthDark = Palette.EarthDark,
	EarthLight = C(230, 162, 88),
	EarthDeep = C(170, 96, 34),
	Wood = Palette.Wood,
	WoodDark = Palette.WoodDark,
	WoodLight = C(214, 160, 100),
	TimberEdge = C(112, 74, 44),
	White = C(245, 246, 235),
	Ink = C(67, 93, 121),
	Black = C(45, 48, 56),
	FlowerWhite = C(250, 250, 240),
	FlowerYellow = Palette.KickZoneChecker,
	FlowerPink = C(244, 132, 178),
	FlowerRed = C(232, 72, 58),
	FlowerBlue = C(92, 160, 240),
	Lamp = C(255, 244, 196),
	Red = C(232, 72, 58),
	Blue = C(43, 154, 237),
	Orange = C(241, 120, 47),
	Yellow = C(252, 189, 51),
	Teal = C(40, 185, 187),
	Purple = C(155, 92, 215),
	Gold = C(255, 200, 60),
	GoldDark = C(222, 150, 34),
	Brick = C(196, 92, 62),
	BrickDark = C(156, 68, 48),
	BrickLight = C(220, 122, 84),
	Asphalt = C(78, 85, 96),
	AsphaltDark = C(64, 70, 80),
	RoadLine = C(252, 206, 64),
	Concrete = C(184, 190, 194),
	ConcreteDark = C(156, 163, 168),
	Coping = C(214, 219, 224),
	Gravel = C(162, 167, 172),
	GravelDark = C(140, 145, 151),
	GravelLight = C(184, 188, 192),
	Hazard = C(255, 196, 38),
	HazardDark = C(52, 56, 66),
	Water = C(70, 166, 228),
	WaterLight = C(140, 210, 245),
	Glass = C(130, 214, 240),
	WindowLit = C(255, 226, 140),
	Steel = C(196, 206, 216),
	SteelDark = C(96, 112, 128),
	Smoke = C(226, 229, 233),
}

local FACE_AXES: { [Enum.NormalId]: { string } } = {
	[N.Top] = { "X", "Z" },
	[N.Bottom] = { "X", "Z" },
	[N.Right] = { "Y", "Z" },
	[N.Left] = { "Y", "Z" },
	[N.Front] = { "X", "Y" },
	[N.Back] = { "X", "Y" },
}

-- Zone-local box of an axis-aligned part: (u, h, s) minimum and maximum.
local function extent(frame: CFrame, part: BasePart): (Vector3, Vector3)
	assert(frame.XVector:Dot(part.CFrame.XVector) > 0.9999, "Voxel styling needs axis-aligned course parts")
	local c, half = frame:PointToObjectSpace(part.Position), part.Size / 2
	return Vector3.new(c.X - half.X, c.Y - half.Y, -c.Z - half.Z),
		Vector3.new(c.X + half.X, c.Y + half.Y, -c.Z + half.Z)
end

-- One side's authored banks, as distances from the field centre line.
local function bank(frame: CFrame, zone: any, side: number): any
	local suffix = if side < 0 then "West" else "East"
	local banks = assert(zone.Geometry:FindFirstChild("Banks"), "Missing bank bodies")
	local ilo, ihi = extent(frame, assert(banks:FindFirstChild("Inner" .. suffix)) :: BasePart)
	local olo, ohi = extent(frame, assert(banks:FindFirstChild("Outer" .. suffix)) :: BasePart)
	local inner, step = math.min(math.abs(ilo.X), math.abs(ihi.X)), math.max(math.abs(ilo.X), math.abs(ihi.X))
	local from, outer = math.min(math.abs(olo.X), math.abs(ohi.X)), math.max(math.abs(olo.X), math.abs(ohi.X))
	assert(math.abs(from - step) < 0.1, "Outer bank must start at the inner bank edge")
	local result = { inner = inner, step = step, outer = outer, bottom = math.min(ilo.Y, olo.Y) }
	result.innerTop, result.outerTop = ihi.Y, ohi.Y
	for _, skin in zone.Geometry:GetChildren() do
		if skin:IsA("BasePart") and skin.Name:match("^BiomeBank") then
			local lo, hi = extent(frame, skin)
			local centre = (lo.X + hi.X) / 2
			if math.sign(centre) == side then
				if math.abs(centre) < step then
					result.innerTop = math.max(result.innerTop, hi.Y)
				else
					result.outerTop = math.max(result.outerTop, hi.Y)
				end
			end
		end
	end
	return result
end

function Kit.new(world: Instance, zone: any, field: BasePart): any
	local p = Palette.GroundStudPitch * Scale.factor(world)
	local frame = field.CFrame * CFrame.new(0, field.Size.Y / 2, field.Size.Z / 2)
	local tile = p * Palette.StudsPerTexture
	local function whole(x: number): boolean
		return math.abs(x / p - math.round(x / p)) < 0.001
	end
	local west, east = bank(frame, zone, -1), bank(frame, zone, 1)
	for _, key in { "inner", "step", "outer", "innerTop", "outerTop" } do
		assert(math.abs(west[key] - east[key]) < 0.001, "Banks are not mirrored")
	end
	-- Authored banks may sit a few hundredths off the grid; the cladding snaps to it
	-- and stays in front of every bank face it covers.
	for _, key in { "inner", "step", "outer" } do
		local snapped = math.round(west[key] / p) * p
		assert(math.abs(snapped - west[key]) < 0.1, "Zone is not on the ground grid")
		west[key] = snapped
	end
	assert(whole(field.Size.Z), "Zone length is not on the ground grid")
	-- Every visible step is a whole number of rows, anchored on the pitch layer and
	-- at least 0.1 above the old skins it covers.
	local base = Kit.Layer
	local terrace = base + math.ceil((west.innerTop + 0.1 - base) / p) * p
	local lawn = terrace + math.ceil((west.outerTop + 0.1 - terrace) / p) * p
	local kit: any = {
		p = p,
		frame = frame,
		rows = math.round(field.Size.Z / p),
		colors = Kit.Colors,
		layer = Kit.Layer,
		bank = west,
		levels = { base = base, terrace = terrace, lawn = lawn },
		-- Rows before this zone along the course, so stripes and checkers run on.
		rowOffset = 0,
	}
	kit.whole = whole
	function kit.onGround(h: number): boolean
		return math.abs(h - base) < 0.001 or math.abs(h - terrace) < 0.001 or math.abs(h - lawn) < 0.001
	end
	local function checkFace(part: BasePart, face: Enum.NormalId)
		local axes = FACE_AXES[face]
		local size = part.Size :: any
		assert(whole(size[axes[1]]) and whole(size[axes[2]]), "Studs need a whole-stud face: " .. part.Name)
	end
	-- A cosmetic block; the designated visible faces follow the shared stud grid.
	function kit.box(
		parent: Instance,
		name: string,
		u0: number,
		u1: number,
		h0: number,
		h1: number,
		s0: number,
		s1: number,
		color: Color3,
		faces: { Enum.NormalId }?,
		material: Enum.Material?
	): Part
		local part = Instance.new("Part")
		part.Name = name
		part.Size = Vector3.new(u1 - u0, h1 - h0, s1 - s0)
		part.CFrame = frame * CFrame.new((u0 + u1) / 2, (h0 + h1) / 2, -(s0 + s1) / 2)
		part.Color = color
		part.Material = material or Enum.Material.Plastic
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
		part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		part.CastShadow = math.min(part.Size.X, part.Size.Y, part.Size.Z) >= p * 0.99
		if faces then
			for _, face in faces do
				checkFace(part, face)
			end
			if part.Material == Enum.Material.Neon then
				-- Roblox does not support Neon as a custom material base.
				for _, face in faces do
					local t = Instance.new("Texture")
					t.Name, t.Texture, t.Face = "VoxelStuds", Palette.Studs, face
					t.StudsPerTileU, t.StudsPerTileV = tile, tile
					t.Transparency, t.Parent = Palette.StudsTransparency, part
				end
			else
				HDStuds.apply(part, tile)
			end
		end
		part.Parent = parent
		return part
	end
	-- A whole voxel block: u in [n0, n1] * p, s in [m0, m1] * p, h on whole rows above the
	-- pitch layer. Studs cover every face except a bottom resting on a ground level.
	function kit.cells(
		parent: Instance,
		name: string,
		n0: number,
		n1: number,
		h0: number,
		h1: number,
		m0: number,
		m1: number,
		color: Color3,
		material: Enum.Material?
	): Part
		assert(
			whole(h0 - base) and whole(h1 - base) and h1 > h0 and n1 > n0 and m1 > m0,
			"Voxel off the grid: " .. name
		)
		local faces = table.clone(SIDES)
		if not kit.onGround(h0) then
			table.insert(faces, N.Bottom)
		end
		return kit.box(parent, name, n0 * p, n1 * p, h0, h1, m0 * p, m1 * p, color, faces, material)
	end
	function kit.model(parent: Instance, name: string): Model
		local m = Instance.new("Model")
		m.Name, m.WorldPivot, m.Parent = name, frame, parent
		return m
	end
	-- The canvas keeps the face's proportions, so captions are never squeezed. TextScaled
	-- stops at 100 px, so 32 px per stud lets short captions fill a small flag.
	function kit.text(part: BasePart, text: string, face: Enum.NormalId, color: Color3)
		local axes = if face == N.Left or face == N.Right then { "Z", "Y" } else FACE_AXES[face]
		local size = part.Size :: any
		local gui = Instance.new("SurfaceGui")
		gui.Name, gui.Face = "Sign_" .. face.Name, face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		gui.CanvasSize = Vector2.new(size[axes[1]], size[axes[2]]) * 32
		gui.LightInfluence, gui.MaxDistance = 0, 450
		gui.Parent = part
		local label = Instance.new("TextLabel")
		label.Name, label.Size = "Caption", UDim2.fromScale(0.94, 0.86)
		label.Position, label.BackgroundTransparency = UDim2.fromScale(0.03, 0.07), 1
		label.Font, label.TextScaled, label.TextColor3, label.Text = Enum.Font.FredokaOne, true, color, text
		label.Parent = gui
	end
	return kit
end

return Kit
