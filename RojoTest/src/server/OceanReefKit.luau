-- The coral reference sheet uses chunky, stepped silhouettes. Native parts keep
-- each color, hollow and branch editable in Studio without an imported asset.
local Look = require(script.Parent.OceanDepthsLook)
local RunService = game:GetService("RunService")
local Kit = {}
local color = Color3.fromHex

local branching = {
	PinkStaghorn = {
		tone = color("F34CA0"),
		tips = {
			{ -4.5, 4.6, 0.3 },
			{ -3, 7.4, -0.45 },
			{ -1.3, 6, 1.2 },
			{ 0.2, 8.5, 0 },
			{ 2.6, 7.15, -0.6 },
			{ 4.8, 5.3, 0.65 },
		},
	},
	OrangeBranch = {
		tone = color("FFAA37"),
		tips = { { -3.4, 3.6, 0.15 }, { -1.9, 5.1, -0.3 }, { 0.2, 6.05, 0.4 }, { 2, 4.55, -0.35 }, { 3.3, 3.9, 0.5 } },
	},
	LavenderFan = {
		tone = color("BD73D9"),
		tips = {
			{ -4.9, 4.6, -0.3 },
			{ -3.8, 6.45, 0.25 },
			{ -1.7, 7.3, -0.2 },
			{ 1, 7.2, 0.3 },
			{ 3.15, 6.4, 0 },
			{ 4.7, 4.9, 0.2 },
		},
	},
}

local function stem(parent: Model, a: Vector3, b: Vector3, width: number, tone: Color3)
	local delta = b - a
	local up = if math.abs(delta.Unit.Y) > 0.95 then Vector3.zAxis else Vector3.yAxis
	Look.part(
		parent,
		"Branch",
		CFrame.lookAt(a:Lerp(b, 0.5), b, up),
		Vector3.new(width, width, delta.Magnitude + width * 0.42),
		tone
	)
end

local function branch(parent: Instance, name: string, cf: CFrame, scale: number)
	local asset = Look.model(parent, name)
	asset.WorldPivot = cf
	local recipe = branching[name]
	local function point(x: number, y: number, z: number)
		return cf:PointToWorldSpace(Vector3.new(x, y, z) * scale)
	end
	stem(asset, point(0, 0, 0), point(0, 3.3, 0), 1.72 * scale, recipe.tone)
	for i, shape in recipe.tips do
		local x, y, z = table.unpack(shape)
		local hue = recipe.tone:Lerp(color("FFE1B7"), (i % 3) * 0.06)
		local joint = point(x * 0.69, y * 0.68, z * 0.72)
		local endPoint = point(x, y, z)
		stem(asset, point(0, 1.55 + i % 3 * 0.45, 0), joint, 1.18 * scale, hue)
		stem(asset, joint, endPoint, 0.96 * scale, hue)
		local tip = CFrame.new(endPoint) * cf.Rotation
		local lip = hue:Lerp(color("FFD5E5"), 0.23)
		for side = 0, 3 do
			local turn = tip * CFrame.Angles(0, side * math.pi / 2, 0)
			Look.part(
				asset,
				"GrowthRim",
				turn * CFrame.new(0, 0.21 * scale, 0.44 * scale),
				Vector3.new(0.86, 0.68, 0.28) * scale,
				lip
			)
		end
		if i % 2 == 1 then
			local fork = point(x * 0.82, y * 0.83 + 0.7, z + 0.74)
			stem(asset, joint, fork, 0.78 * scale, hue)
		end
	end
	return asset
end

local function tubes(parent: Instance, name: string, cf: CFrame, scale: number)
	local asset = Look.model(parent, name)
	asset.WorldPivot = cf
	local tone = color(if name == "OrangeTubes" then "FFA348" else "EE659F")
	for i, position in { Vector3.new(-1.25, 3.15, 0.2), Vector3.new(1.05, 2, 0.95), Vector3.new(1.48, 2.65, -0.9) } do
		local origin = cf
			* CFrame.new(position.X * scale, 0, position.Z * scale)
			* CFrame.Angles(0, 0, math.rad((i - 2) * 7))
		local radius = (if i == 1 then 1.05 else 0.78) * scale
		local height = position.Y * scale
		local floor = Look.part(
			asset,
			"TubeInterior",
			origin * CFrame.new(0, 0.12, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Vector3.new(0.24, radius * 1.65, radius * 1.65),
			tone:Lerp(color("64354E"), 0.7)
		)
		floor.Shape = Enum.PartType.Cylinder
		for side = 1, 8 do
			local turn = origin * CFrame.Angles(0, side * math.pi / 4, 0)
			local length = radius * 0.82
			local tint = tone:Lerp(color("FFD6A2"), (side % 3) * 0.075)
			Look.part(
				asset,
				"TubeWall",
				turn * CFrame.new(0, (height - 0.24 * scale) / 2, radius * 0.86),
				Vector3.new(length, height + 0.24 * scale, radius * 0.27),
				tint
			)
			Look.part(
				asset,
				"TubeLip",
				turn * CFrame.new(0, height, radius * 0.86),
				Vector3.new(length + 0.05 * scale, 0.34 * scale, radius * 0.34),
				tone:Lerp(color("FFF0BC"), 0.3)
			)
		end
	end
	return asset
end

local function fronds(parent: Instance, name: string, cf: CFrame, scale: number)
	local asset = Look.model(parent, name)
	asset.WorldPivot = cf
	local kelp = name == "RibbonKelp"
	local tone = color(if kelp then "27A88D" else "59DFB0")
	for i = 0, 6 do
		local turn = cf * CFrame.Angles(0, i * math.pi * 2 / 7, 0)
		local height = (if kelp then 6.2 else 2.9) + (i * 3 % 5) * 0.47
		local lean = if kelp then 1.12 else 2.6
		local spread = if kelp then 0.95 else 0.43
		local a = (turn * CFrame.new(0, 0, spread * scale)).Position
		local b = (turn * CFrame.new(0.25 * scale, height * 0.51 * scale, (spread + lean * 0.65) * scale)).Position
		local c = (turn * CFrame.new(0, height * scale, (spread + lean) * scale)).Position
		local tint = tone:Lerp(color("AAFFD1"), (i % 3) * 0.1)
		stem(asset, a, b, (if kelp then 0.68 else 1.03) * scale, tint)
		if kelp then
			local zig = (turn * CFrame.new(-0.32 * scale, height * 0.76 * scale, (spread + lean * 0.5) * scale)).Position
			stem(asset, b, zig, 0.62 * scale, tint)
			stem(asset, zig, c, 0.54 * scale, tint)
		else
			stem(asset, b, c, 0.85 * scale, tint)
			Look.ellipsoid(asset, "RoundedTip", CFrame.new(c), Vector3.new(0.86, 0.85, 0.86) * scale, tint)
		end
	end
	return asset
end

function Kit.place(parent: Instance, name: string, cf: CFrame, scale: number): Model
	local model: Model
	if branching[name] then
		model = branch(parent, name, cf, scale)
	elseif name == "OrangeTubes" or name == "PinkTubes" then
		model = tubes(parent, name, cf, scale)
	else
		assert(name == "MintAnemone" or name == "RibbonKelp", "Unknown reef asset: " .. name)
		model = fronds(parent, name, cf, scale)
	end
	model:SetAttribute("SupportFootprint", Kit.footprint(name, scale))
	return model
end

function Kit.footprint(name: string, scale: number): Vector2
	if name == "OrangeTubes" or name == "PinkTubes" then
		return Vector2.new(4.8, 3.8) * scale
	end
	local width = if name == "RibbonKelp" then 2.9 elseif name == "MintAnemone" then 2.35 else 1.8
	return Vector2.new(width, width) * scale
end

function Kit.spring(
	parent: Instance,
	name: string,
	cf: CFrame,
	scale: number,
	pink: boolean,
	settle: (CFrame, Vector2) -> CFrame
): Model
	local spring = Look.model(parent, name)
	spring.WorldPivot = cf
	local tubeSpecies = if pink then "PinkTubes" else "OrangeTubes"
	local coral = if pink then "OrangeBranch" else "PinkStaghorn"
	local sponge = settle(cf, Kit.footprint(tubeSpecies, scale))
	local anemone =
		settle(sponge * CFrame.new(-3.45 * scale, 0, -1.1 * scale), Kit.footprint("MintAnemone", scale * 0.58))
	local coralBase = settle(sponge * CFrame.new(3.25 * scale, 0, 1.5 * scale), Kit.footprint(coral, scale * 0.53))
	Kit.place(spring, tubeSpecies, sponge, scale)
	Kit.place(spring, "MintAnemone", anemone, scale * 0.58)
	Kit.place(spring, coral, coralBase, scale * 0.53)
	Look.bubblePlume(spring, (sponge * CFrame.new(-1.5 * scale, 3.4 * scale, 0.2 * scale)).Position, 3.4)
	Look.bubblePlume(spring, (sponge * CFrame.new(1.7 * scale, 2.7 * scale, -0.9 * scale)).Position, 1.4)
	return spring
end

function Kit.writeTemplates(storage: ServerStorage): Folder
	assert(RunService:IsStudio() and not RunService:IsRunning(), "Reef templates are authored in Edit mode")
	local previous = storage:FindFirstChild("OceanReefAssets")
	assert(
		not previous or previous:GetAttribute("GeneratedOceanReefKit") == true,
		"OceanReefAssets is already occupied"
	)
	local pack = Instance.new("Folder")
	pack.Name = "OceanReefAssets"
	pack:SetAttribute("GeneratedOceanReefKit", true)
	for _, species in
		{ "PinkStaghorn", "OrangeBranch", "LavenderFan", "MintAnemone", "OrangeTubes", "PinkTubes", "RibbonKelp" }
	do
		Kit.place(pack, species, CFrame.identity, 1)
	end
	pack.Parent = storage
	if previous then
		previous:Destroy()
	end
	return pack
end

return Kit
