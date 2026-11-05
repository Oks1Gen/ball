local Look = require(script.Parent.OceanDepthsLook)
local Kit = require(script.Parent.OceanReefKit)
local Ground = require(script.Parent.OceanReefGround)
local HDStuds = require(script.Parent.HDStuds)

local Reef = {}
local color = Color3.fromHex
local rock = { color("3679B1"), color("478BC1"), color("589CCC") }
local shoreSand = color("F2D9A0")
local trim = color("23B6C2")

-- x is measured from the center line; progress is measured from Kick Zone.
local gardens = {
	{ at = Vector2.new(-53, 25), species = "PinkStaghorn", scale = 1.24 },
	{ at = Vector2.new(52, 31), species = "MintAnemone", scale = 1.2 },
	{ at = Vector2.new(62, 55), species = "PinkStaghorn", scale = 1.43 },
	{ at = Vector2.new(-62, 69), species = "PinkStaghorn", scale = 1.76 },
	{ at = Vector2.new(-48, 96), species = "OrangeBranch", scale = 1.02 },
	{ at = Vector2.new(53, 108), species = "OrangeTubes", scale = 1.05 },
	{ at = Vector2.new(62, 132), species = "LavenderFan", scale = 1.16 },
	{ at = Vector2.new(-52, 139), species = "MintAnemone", scale = 1.04 },
	{ at = Vector2.new(-60, 167), species = "OrangeBranch", scale = 1.26 },
	{ at = Vector2.new(54, 171), species = "PinkStaghorn", scale = 1.22 },
	{ at = Vector2.new(66, 204), species = "OrangeBranch", scale = 1.43 },
	{ at = Vector2.new(-52, 214), species = "OrangeTubes", scale = 1.12 },
	{ at = Vector2.new(-62, 237), species = "PinkStaghorn", scale = 3.85 },
	{ at = Vector2.new(54, 254), species = "PinkTubes", scale = 1.08 },
	{ at = Vector2.new(62, 278), species = "PinkStaghorn", scale = 1.36 },
	{ at = Vector2.new(-52, 280), species = "MintAnemone", scale = 1.14 },
}

local function lightPattern(part: Part)
	local texture = Instance.new("Texture")
	texture.Name = "WaterLight"
	texture.Face = Enum.NormalId.Top
	texture.Texture = "rbxassetid://12781828706" -- Shared with the lobby water surface.
	texture.Color3 = color("A5ECF6")
	texture.StudsPerTileU = 34
	texture.StudsPerTileV = 29
	texture.Transparency = 0.77
	texture.Parent = part
end

local function stone(parent: Model, cf: CFrame, size: Vector3, tone: Color3, studs: number): Part
	local slab = Look.part(parent, "BlueLimestone", cf, size, tone)
	HDStuds.apply(slab, studs)
	return slab
end

local function terrace(
	parent: Instance,
	cf: CFrame,
	studs: number,
	asset: string,
	scale: number,
	index: number,
	x: number,
	settle: (CFrame, Vector2) -> CFrame
)
	local hero = scale > 3
	local plot = Look.model(parent, if hero then "CrownCoralTerrace" else "ReefTerrace")
	local width = if hero then 28.8 elseif index % 3 == 0 then 16.8 else 12
	local depth = if hero then 28.8 else 14.4
	local courses = if hero then 3 else 1 + index % 2
	cf = settle(cf, Vector2.new(width, depth))
	local ledges = {}
	for tier = 1, courses do
		local height = if hero then 3.6 else 2.4
		local step = (tier - 1) * 4.8
		local offset = (tier - 1) * 1.2
		local widthAtTier = width - step
		local depthAtTier = depth - step
		local base = cf * CFrame.new(math.sign(x) * offset, height * (tier - 1), -offset)
		if tier > 1 then
			base = Ground.fit(ledges, base, Vector2.new(widthAtTier, depthAtTier), 0.08)
		end
		local slab = stone(
			plot,
			base * CFrame.new(0, height / 2, 0),
			Vector3.new(widthAtTier, height, depthAtTier),
			rock[tier],
			studs
		)
		Ground.add(ledges, slab)
	end
	local top = if hero then 10.8 else courses * 2.4
	local offset = (courses - 1) * 1.2
	local crown = cf
		* CFrame.new(math.sign(x) * offset, top, -offset)
		* CFrame.Angles(0, math.rad((index * 43) % 150 - 75), 0)
	Kit.place(plot, asset, Ground.fit(ledges, crown, Kit.footprint(asset, scale), 0.08), scale)
	if hero then
		Kit.place(plot, "OrangeBranch", settle(cf * CFrame.new(-7, 0, 16.8), Kit.footprint("OrangeBranch", 1.2)), 1.2)
		Kit.place(plot, "MintAnemone", settle(cf * CFrame.new(-8.4, 0, -17.4), Kit.footprint("MintAnemone", 1.2)), 1.2)
	elseif index % 2 == 0 then
		local species = if index % 4 == 0 then "OrangeTubes" else "MintAnemone"
		local position = cf * CFrame.new(width * 0.24, 2.4, depth * 0.32)
		Kit.place(plot, species, Ground.fit(ledges, position, Kit.footprint(species, 0.74), 0.08), 0.74)
	end
	if not hero then
		local low = cf * CFrame.new(-math.sign(x) * 2.4, 0, depth / 2 + 4.8)
		local species = if index % 3 == 0 then "OrangeTubes" else "MintAnemone"
		Kit.place(plot, species, settle(low, Kit.footprint(species, 0.82)), 0.82)
	end
end

function Reef.applySwimmers(zone: any, garden: Instance)
	local field: BasePart = zone.Field
	local function at(x: number, y: number, progress: number): CFrame
		return field.CFrame * CFrame.new(x, y, field.Size.Z * 0.5 - progress)
	end
	local swimmers = Instance.new("Folder")
	swimmers.Name = "ReefSwimmers"
	local random = Random.new(4397)
	for i, point in { at(-64, 39, 59), at(70, 46, 135), at(-62, 44, 247), at(75, 36, 285) } do
		Look.school(swimmers, point.Position, i, random, 10)
	end
	Look.manta(swimmers, at(-92, 57, 86) * CFrame.Angles(0.56, 0.85, -0.55)):ScaleTo(1.25)
	local old = garden:FindFirstChild(swimmers.Name)
	swimmers.Parent = garden
	if old then
		old:Destroy()
	end
end

function Reef.apply(zone: any): Model
	local field: BasePart = zone.Field
	local environment: Instance = zone.Environment
	local ground: Instance = zone.Geometry.GroundCladding
	local turf = assert(ground:FindFirstChild("Turf", true), "Coral Reef needs its original course cladding")
	local studs = Look.studsTile(turf :: BasePart)
	local model = Instance.new("Model")
	model.Name = "CoralGardens"
	local bank = Look.model(model, "SunlitBanks")
	local plots = Instance.new("Folder")
	plots.Name = "Terraces"
	plots.Parent = model

	local function at(x: number, y: number, progress: number): CFrame
		return field.CFrame * CFrame.new(x, y, field.Size.Z * 0.5 - progress)
	end
	local random = Random.new(4397)
	local copingWidth = 4.8
	local shoulderWidth = 14.4
	local shoulderStart = 62.4
	local shoulderTop = 6.074
	local surfaces = Ground.collect(ground, { LawnTop = true })
	local function settle(cf: CFrame, size: Vector2): CFrame
		return Ground.fit(surfaces, cf, size, 0.16, 15)
	end
	for _, side in { -1, 1 } do
		local edge = field.Size.X / 2
		local rim = Look.part(
			bank,
			"TurquoiseCoping",
			at(side * (edge + copingWidth / 2 + 0.03), 2.48, field.Size.Z / 2),
			Vector3.new(copingWidth, 0.48, field.Size.Z),
			trim
		)
		HDStuds.apply(rim, studs)
		local shoulder = stone(
			bank,
			at(side * (shoulderStart + shoulderWidth / 2), shoulderTop - 4.8, field.Size.Z / 2),
			Vector3.new(shoulderWidth, 9.6, field.Size.Z),
			shoreSand,
			studs
		)
		shoulder.Name = "SandShoulder"
		Ground.add(surfaces, shoulder)
		local shelf = Look.part(
			bank,
			"SandShelf",
			at(side * 78, -4.1, field.Size.Z / 2),
			Vector3.new(38.4, 2.4, field.Size.Z),
			color("C6CDB5")
		)
		HDStuds.apply(shelf, studs)
		lightPattern(shelf)
		Ground.add(surfaces, shelf)
		local floor = Look.part(
			bank,
			"Seabed",
			at(side * 152, -13, field.Size.Z / 2),
			Vector3.new(129.6, 3.6, field.Size.Z),
			color("238BAE")
		)
		HDStuds.apply(floor, studs)
		lightPattern(floor)
		Ground.add(surfaces, floor)
		for i = 1, 13 do
			local distance = (i - 0.5) * field.Size.Z / 13
			local distanceFromLane = random:NextNumber(84, 136)
			local formation = Look.model(plots, "OffshoreLedge")
			local span = random:NextInteger(4, 8) * 2.4
			local height = random:NextInteger(3, 7) * 2.4
			local onShelf = distanceFromLane < 99
			local x = side
				* (
					if onShelf
						then math.clamp(distanceFromLane, 77 + span / 2, 97 - span / 2)
						else math.max(distanceFromLane, 97.5 + span / 2)
				)
			local base = settle(at(x, if onShelf then -2.9 else -11.2, distance), Vector2.new(span, 16.8))
			stone(formation, base * CFrame.new(0, height / 2, 0), Vector3.new(span, height, 16.8), rock[1], studs)
			local ledge = stone(
				formation,
				base * CFrame.new(0, height + 1.2, 1.2),
				Vector3.new(span - 4.8, 2.4, 12),
				rock[2],
				studs
			)
			if i % 2 == 1 then
				local species = if i % 3 == 0 then "LavenderFan" else "MintAnemone"
				local ledgeSurface = {}
				Ground.add(ledgeSurface, ledge)
				local position = base * CFrame.new(0, height + 2.4, 1.2)
				Kit.place(
					formation,
					species,
					Ground.fit(ledgeSurface, position, Kit.footprint(species, 0.83), 0.08),
					0.83
				)
			end
		end
		for i = 1, 5 do
			local x = side * (48 + i * 5.7)
			local y = shoulderTop - 0.06
			local scale = 1.25 + (i % 3) * 0.24
			local cf = settle(at(x, y, field.Size.Z - 4 - (i % 3) * 4), Kit.footprint("RibbonKelp", scale))
			Kit.place(plots, "RibbonKelp", cf, scale)
		end
		for i = 1, 8 do
			local distance = (i - 0.45) * field.Size.Z / 8
			local x = side * random:NextNumber(144, 196)
			local ledge = Look.model(plots, "DistantReefShelf")
			local rise = random:NextInteger(2, 5) * 2.4
			local base = settle(at(x, -11.2, distance), Vector2.new(24, 24))
			stone(ledge, base * CFrame.new(0, rise / 2, 0), Vector3.new(24, rise, 24), color("287B9E"), studs)
			stone(
				ledge,
				base * CFrame.new(side * 2.4, rise + 1.2, -2.4),
				Vector3.new(16.8, 2.4, 16.8),
				color("3D90AA"),
				studs
			)
		end
	end
	for index, entry in gardens do
		local x = entry.at.X
		terrace(plots, at(x, shoulderTop, entry.at.Y), studs, entry.species, entry.scale, index, x, settle)
	end
	for index, point in
		{
			Vector2.new(-50.4, 11),
			Vector2.new(50.4, 16),
			Vector2.new(-51.6, 45),
			Vector2.new(51.6, 76),
			Vector2.new(-51.6, 114),
			Vector2.new(52.8, 154),
			Vector2.new(-50.4, 186),
			Vector2.new(51.6, 228),
			Vector2.new(-50.4, 262),
			Vector2.new(51.6, 295),
		}
	do
		local species = if index % 3 == 0
			then "OrangeBranch"
			elseif index % 3 == 1 then "PinkStaghorn"
			else "MintAnemone"
		local scale = 0.48 + (index % 3) * 0.12
		Kit.place(plots, species, settle(at(point.X, shoulderTop, point.Y), Kit.footprint(species, scale)), scale)
	end
	for index, point in
		{ at(-70, shoulderTop - 0.06, 49), at(70, shoulderTop - 0.06, 147), at(-89, -2.9, 200.4), at(79, -2.9, 267) }
	do
		Kit.spring(
			plots,
			"ReefBubbleSpring",
			point * CFrame.Angles(0, index * 0.8, 0),
			0.9 + index * 0.08,
			index % 2 == 0,
			settle
		)
	end
	Reef.applySwimmers(zone, model)
	for _, part in ground:GetDescendants() do
		if part:IsA("BasePart") then
			if part.Name == "TerraceTop" or part.Name == "LawnTop" or part.Name == "LawnEnd" then
				part.Color = shoreSand
			elseif part.Name == "PitchWall" then
				part.Color = trim
			elseif part.Name == "OuterWall" or part.Name == "StepWall" then
				part.Color = rock[2]
			end
		end
	end
	for _, old in environment:GetChildren() do
		if old.Name == model.Name or old.Name == "ReefBorder" or old.Name == "ReefOutcrop" then
			old:Destroy()
		end
	end
	model.Parent = environment
	return model
end

return Reef
