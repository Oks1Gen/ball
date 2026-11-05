local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local MaterialService = game:GetService("MaterialService")
local HDStuds = require(script.Parent.HDStuds)

local Look = {}
local color = Color3.fromHex

function Look.studsTile(source: BasePart): number
	for _, child in source:GetChildren() do
		if child:IsA("Texture") and child.Texture == HDStuds.LegacyImage then
			return child.StudsPerTileU
		end
	end
	local variant = MaterialService:GetMaterialVariant(source.Material, source.MaterialVariant)
	assert(variant and variant.Name:match("^HDStuds_"), "Missing studs on " .. source:GetFullName())
	return variant.StudsPerTile
end

function Look.model(parent: Instance, name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

function Look.part(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	tone: Color3,
	material: Enum.Material?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = tone
	part.Size = size
	part.CFrame = cf
	part.Parent = parent
	return part
end

local signGlyphs = {
	A = { ".###.", "##.##", "##.##", "#####", "#####", "##.##", "##.##" },
	C = { ".####", "##...", "##...", "##...", "##...", "##...", ".####" },
	D = { "####.", "##.##", "##.##", "##.##", "##.##", "##.##", "####." },
	E = { "#####", "##...", "##...", "####.", "##...", "##...", "#####" },
	H = { "##.##", "##.##", "##.##", "#####", "##.##", "##.##", "##.##" },
	N = { "##..#", "###.#", "###.#", "##.##", "#.###", "#.###", "#..##" },
	O = { ".###.", "##.##", "##.##", "##.##", "##.##", "##.##", ".###." },
	P = { "####.", "##.##", "##.##", "####.", "##...", "##...", "##..." },
	S = { ".####", "##...", "##...", ".###.", "...##", "...##", "####." },
	T = { "#####", "#####", "..#..", "..#..", "..#..", "..#..", "..#.." },
}

local function raisedWord(sign: Model, cf: CFrame, word: string, centerY: number)
	local step = 0.59
	local left = -(#word * 6 - 1) * step / 2
	for letter = 1, #word do
		local glyph = signGlyphs[word:sub(letter, letter)]
		for row, pixels in glyph do
			for start, run in pixels:gmatch("()(#+)") do
				local width = #run * step
				local x = left + ((letter - 1) * 6 + start - 1) * step + width / 2
				local y = centerY + (4 - row) * step
				Look.part(
					sign,
					"IvoryLetter",
					cf * CFrame.new(-x, y, -0.56),
					Vector3.new(width, step, 0.36),
					color("FFF0CC")
				)
			end
		end
	end
end

function Look.reefMosaic(parent: Instance, cf: CFrame): Model
	local sign = Instance.new("Model")
	sign.Name = "ReefMosaicSign"
	sign.WorldPivot = cf
	local pitch = 1.12
	local trim = { 4, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
	local teal = { color("146C80"), color("19778A"), color("167184") }
	local rim = color("40C2BD")
	local sand = color("EBC477")
	local coralLeft = { "", "", "", "", "", "", "..X", "X.XX", "XX.X", ".XXX", "..XX", "...X", "...X" }
	local coralRight = { "", "", "", "", "", "", "", "..X", "..XX", "X.X.", "XX.X", ".XX.", "..X." }
	local wave = { 13, 12, 12, 13, 13, 12, 12, 13, 13, 12, 12, 13, 13, 12, 12 }
	for row, inset in trim do
		local y = (7 - row) * pitch
		local first, last = 1 + inset, 27 - inset
		Look.part(
			sign,
			"MosaicBed",
			cf * CFrame.new(0, y, 0.21),
			Vector3.new((last - first + 1) * pitch, pitch, 0.7),
			color("154D5E")
		)
		for column = first, last do
			local x = (column - 14) * pitch
			local tone = teal[(column * 5 + row * 7) % #teal + 1]
			local relief = 0.23
			if
				row == 1
				or column == first
				or column == last
				or (row > 1 and (column <= trim[row - 1] or column > 27 - trim[row - 1]))
			then
				tone = rim
			end
			if row >= 12 and (column <= 4 or column >= 24) then
				tone = sand
			end
			if column <= 4 and coralLeft[row]:sub(column, column) == "X" then
				tone, relief = color("EF6194"), 0.46
			elseif column >= 24 and coralRight[row]:sub(column - 23, column - 23) == "X" then
				tone, relief = color("FFA143"), 0.46
			elseif wave[column - 6] == row then
				tone, relief = color("70D8CA"), 0.36
			end
			Look.part(
				sign,
				"CeramicTile",
				cf * CFrame.new(-x, y, -0.15 - relief / 2),
				Vector3.new(pitch - 0.028, pitch - 0.028, relief),
				tone
			)
		end
	end
	for column = 1, 27 do
		local x = (column - 14) * pitch
		Look.part(
			sign,
			"SandstoneSill",
			cf * CFrame.new(x, -7 * pitch, -0.08),
			Vector3.new(pitch - 0.025, pitch, 1.08),
			sand
		)
	end
	raisedWord(sign, cf, "OCEAN", 2.55)
	raisedWord(sign, cf, "DEPTHS", -2.15)
	sign.Parent = parent
	return sign
end

function Look.ellipsoid(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	tone: Color3,
	material: Enum.Material?
): Part
	local part = Look.part(parent, name, cf, Vector3.one, tone, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = size
	mesh.Parent = part
	return part
end

local function carrier(parent, name, point, purpose)
	local anchor = Look.part(parent, name, CFrame.new(point), Vector3.one, Color3.new())
	anchor.Transparency = 1
	anchor.CastShadow = false
	anchor:SetAttribute("PartRole", "EffectAnchor")
	anchor:SetAttribute("Purpose", purpose)
	return anchor
end

function Look.bubblePlume(parent: Instance, point: Vector3, rate: number)
	local anchor = carrier(parent, "BubbleOrigin", point, "Ambient bubbles rising from the sponge")
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Name = "RisingBubbles"
	bubbles.Texture = "rbxassetid://14425843511" -- VfxForgeUltra library, loose/part-10
	bubbles.Color = ColorSequence.new(color("C5FAFF"), color("F8FFFF"))
	bubbles.Rate = rate
	bubbles.Lifetime = NumberRange.new(4, 6.5)
	bubbles.Speed = NumberRange.new(3, 5.5)
	bubbles.Acceleration = Vector3.new(0.12, 0.6, 0)
	bubbles.SpreadAngle = Vector2.new(10, 10)
	bubbles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.42, 0.18),
		NumberSequenceKeypoint.new(1, 1.48, 0.65),
	})
	bubbles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.24),
		NumberSequenceKeypoint.new(0.78, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	bubbles.LightEmission = 0.24
	bubbles.LightInfluence = 0
	bubbles.Parent = anchor
end

local function waterBackdrop(parent: Instance, center: Vector3)
	local backdrop = Look.model(parent, "WaterBackdrop")
	local size = 700
	local roof = Look.part(
		backdrop,
		"WaterSurface",
		CFrame.new(center + Vector3.yAxis * 113.8),
		Vector3.new(size + 0.3, 0.12, size + 0.3),
		color("2E9DBF")
	)
	roof.CastShadow = false
	local ripples = Instance.new("Texture")
	ripples.Name = "SurfaceRipples"
	ripples.Face = Enum.NormalId.Bottom
	ripples.Texture = "rbxassetid://12781828706" -- Water surface from the existing lobby waterfall.
	ripples.Color3 = color("B4E3EA")
	ripples.Transparency = 0.68
	ripples.StudsPerTileU = 80
	ripples.StudsPerTileV = 52
	ripples.Parent = roof
end

local function shafts(parent)
	local rays = Look.model(parent, "FilteredSunlight")
	local random = Random.new(120)
	for _ = 1, 14 do
		local top = Vector3.new(random:NextNumber(-180, 250), random:NextNumber(106, 155), random:NextNumber(-220, 258))
		local root = carrier(rays, "LightRay", top, "Wide submerged shaft fading before it reaches the floor")
		local start = Instance.new("Attachment")
		start.Parent = root
		local finish = Instance.new("Attachment")
		finish.Position = Vector3.new(32, -100, -15)
		finish.Parent = root
		local beam = Instance.new("Beam")
		beam.Attachment0 = start
		beam.Attachment1 = finish
		beam.FaceCamera = true
		beam.Segments = 10
		beam.Width0 = random:NextNumber(1.4, 3)
		beam.Width1 = random:NextNumber(7, 16)
		beam.Color = ColorSequence.new(color("97F5F7"))
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0.90),
			NumberSequenceKeypoint.new(0.57, 0.97),
			NumberSequenceKeypoint.new(1, 1),
		})
		beam.LightEmission = 0.44
		beam.LightInfluence = 0
		beam.Parent = root
	end
end

local species = { "YellowTang", "Clownfish", "BlueTang", "Butterflyfish" }

local function seaLife(parent: Instance, name: string, cf: CFrame, size: number): Model
	local assets = game:GetService("ServerStorage"):FindFirstChild("Assets")
	local ocean = assets and assets:FindFirstChild("OceanDepths")
	local pack = ocean and ocean:FindFirstChild("SeaLife")
	local template = pack and pack:FindFirstChild(name)
	assert(template and template:IsA("Model"), "Import Ocean Sea Life in Studio first: " .. name)
	local model = template:Clone()
	model:ScaleTo(size)
	model:PivotTo(cf)
	model.Parent = parent
	return model
end

function Look.school(parent: Instance, center: Vector3, index: number, random: Random, count: number): Model
	local school = Look.model(parent, "FishSchool")
	school.WorldPivot = CFrame.new(center)
	local name = species[(index - 1) % #species + 1]
	for i = 1, count do
		local column = (i - 1) % 4
		local row = math.floor((i - 1) / 4)
		local spread = Vector3.new(
			(column - 1.5) * 6.2 + random:NextNumber(-0.7, 0.7),
			(row - 1) * 2.7 + random:NextNumber(-0.55, 0.55),
			(row - 1) * 3.4 + random:NextNumber(-0.8, 0.8)
		)
		local cf = CFrame.new(center) * CFrame.Angles(0, math.rad(15 * index), 0) * CFrame.new(spread)
		seaLife(school, name, cf, random:NextNumber(0.72, 1.16))
	end
	return school
end

function Look.manta(parent: Instance, cf: CFrame): Model
	return seaLife(parent, "MantaRay", cf, 1)
end

function Look.applyLobbySwimmers(water: Model, offset: Vector3)
	local staged = Instance.new("Folder")
	local random = Random.new(2448)
	for index, center in
		{
			Vector3.new(-49, 76, 176),
			Vector3.new(-29, 87, 113),
			Vector3.new(71, 72, -16),
			Vector3.new(164, 89, 108),
			Vector3.new(-82, 68, 26),
			Vector3.new(22, 102, 258),
		}
	do
		Look.school(staged, center + offset, index, random, 12)
	end
	Look.manta(staged, CFrame.new(Vector3.new(-64, 90, 165) + offset) * CFrame.Angles(0.34, -0.38, -0.42))
	for _, old in water:GetChildren() do
		if old.Name == "FishSchool" or old.Name == "MantaRay" then
			old:Destroy()
		end
	end
	for _, model in staged:GetChildren() do
		model.Parent = water
	end
	staged:Destroy()
end

function Look.water(environment: Instance): Model
	local water = Look.model(environment, "OpenWater")
	waterBackdrop(water, Vector3.new(55, 30, 50))
	shafts(water)
	Look.applyLobbySwimmers(water, Vector3.zero)
	return water
end

function Look.animate(world: Model, water: Model, reefSwimmers: Instance?)
	if not RunService:IsRunning() then
		return
	end
	local swimmers = {}
	local models = water:GetChildren()
	if reefSwimmers then
		for _, school in reefSwimmers:GetChildren() do
			table.insert(models, school)
		end
	end
	for _, model in models do
		if model:IsA("Model") and (model.Name == "FishSchool" or model.Name == "MantaRay") then
			table.insert(swimmers, { model = model, origin = model:GetPivot() })
		end
	end
	local elapsed = 0
	local update = 0
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not world.Parent then
			connection:Disconnect()
			return
		end
		elapsed += dt
		if elapsed - update < 0.1 then
			return
		end
		update = elapsed
		for i, swimmer in swimmers do
			local phase = elapsed * 0.13 + i
			local drift = Vector3.new(math.sin(phase) * 20, math.sin(phase * 2) * 2, math.cos(phase) * 10)
			swimmer.model:PivotTo(swimmer.origin + drift)
		end
	end)
end

function Look.previewLighting()
	assert(RunService:IsStudio(), "The preview lighting is for Studio")
	local settings = {
		ClockTime = 11.2,
		Ambient = color("939EA7"),
		OutdoorAmbient = color("AFBAC7"),
		Brightness = 2.05,
		ExposureCompensation = 0.05,
		FogColor = color("127FA9"),
		FogStart = 180,
		FogEnd = 850,
	}
	local previous = {}
	for key, value in settings do
		previous[key] = Lighting[key]
		Lighting[key] = value
	end
	local effects = {}
	for _, effect in Lighting:GetChildren() do
		if effect:IsA("PostEffect") then
			effects[effect] = effect.Enabled
			effect.Enabled = false
		elseif effect:IsA("Atmosphere") then
			effects[effect] = Lighting
			effect.Parent = nil
		end
	end
	return function()
		for key, value in previous do
			Lighting[key] = value
		end
		for effect, value in effects do
			if effect:IsA("PostEffect") then
				effect.Enabled = value
			else
				effect.Parent = value
			end
		end
	end
end

return Look
