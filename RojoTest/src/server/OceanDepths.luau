-- Studio authoring for the Ocean Depths lobby. The live world still uses World1.
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Look = require(script.Parent.OceanDepthsLook)
local Reef = require(script.Parent.OceanCoralReef)
local Kit = require(script.Parent.OceanReefKit)
local Ground = require(script.Parent.OceanReefGround)
local Landmarks = require(script.Parent.OceanLandmarks)
local Course = require(script.Parent.OceanCourseLocations)
local WorldHDStuds = require(script.Parent.WorldHDStuds)

local OceanDepths = {}
local OFFSET = Vector3.new(4096, 0, 0)
local color = Color3.fromHex
local sand = color("F9DA97")
local seaStone = color("467DA5")
local turquoise = color("21B9BE")
local brass = color("E8A544")

local terrainColors = {
	["60b432"] = color("E1B96D"),
	["77d241"] = sand,
	["96e456"] = color("FFE7AB"),
	["52b82b"] = color("E7BF7D"),
	["5ccd30"] = turquoise,
	["c37529"] = color("D3A762"),
	["d68b3e"] = color("F0C886"),
	["e6a258"] = color("F2D59D"),
	["aa6022"] = color("BE995F"),
}

local function recolor(root: Instance, palette: { [string]: Color3 })
	for _, part in root:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 then
			part.Color = palette[part.Color:ToHex():lower()] or part.Color
		end
	end
end

local function tintStructure(root: Instance, light: Color3, dark: Color3)
	for _, part in root:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 then
			part.Color = dark:Lerp(light, part.Color.R * 0.65 + part.Color.G * 0.35)
		end
	end
end

local function shell(parent: Instance, center: Vector3, hue: Color3)
	local cradle = Look.model(parent, "ShellCradle")
	local ivory = color("FFF1CF")
	for i = -3, 3 do
		local angle = math.rad(i * 29)
		local cf = CFrame.new(center) * CFrame.Angles(0, angle, 0)
		local length = 4.25 - math.abs(i) * 0.24
		Look.ellipsoid(
			cradle,
			"Flute",
			cf * CFrame.new(0, 1.05, length * 0.55) * CFrame.Angles(-0.43, 0, 0),
			Vector3.new(2.15, 1.85, length * 1.56),
			hue:Lerp(ivory, math.abs(i) * 0.12)
		)
	end
	Look.ellipsoid(cradle, "Hinge", CFrame.new(center), Vector3.new(4.2, 0.84, 4.2), hue)
	return cradle
end

local function dressEggs(lobby: any, premium: any)
	local shop = lobby.EggShop
	tintStructure(shop.EggStand, color("B0CFDE"), color("466D97"))
	local colors = { color("EAA9C3"), color("F3B99C"), color("F0CE92"), color("C6E5F5"), color("B8DCCD") }
	for i, name in { "Egg_Rainbow", "Egg_Rare", "VolcanicEgg", "Egg_Uncommon", "Egg_Common" } do
		local egg = shop[name]
		local pedestal = egg:FindFirstChild("EggPedestal") or egg:FindFirstChild("Pedestal")
		if pedestal and pedestal:IsA("BasePart") then
			pedestal.Color = seaStone
			shell(egg, pedestal.Position + Vector3.new(0, 0.48, -1.9), colors[i])
		end
		local ring = egg:FindFirstChild("EggRing")
		if ring then
			ring.Transparency = 1
		end
	end
	local goldEgg = premium.GoldEgg
	local cf, size = goldEgg:GetBoundingBox()
	goldEgg:Destroy()
	shell(premium, cf.Position - Vector3.new(0, size.Y * 0.48, 0), brass)
	Look.ellipsoid(premium, "Pearl", cf, Vector3.new(4.8, 4.8, 4.8), color("FFF0F7"), Enum.Material.Glass).Transparency =
		0.06
end

function OceanDepths.applyLobbySign(world: any): Model
	assert(
		RunService:IsStudio() and world:GetAttribute("OceanDepthsPreview") == true,
		"Expected the Ocean Depths Studio preview"
	)
	local decor = world.Lobby.Environment.ClubDecor
	local previous = decor:FindFirstChild("ReefMosaicSign")
	local old = previous or decor.Scoreboard
	local cf = if previous then previous:GetPivot() else old.Screen.CFrame
	local mosaic = Look.reefMosaic(decor, cf)
	old:Destroy()
	return mosaic
end

function OceanDepths.applyLobbyLandmarks(world: any)
	assert(
		RunService:IsStudio() and world:GetAttribute("OceanDepthsPreview") == true,
		"Expected the Ocean Depths Studio preview"
	)
	Landmarks.apply(world.Lobby)
end

function OceanDepths.applySeaLife(world: any)
	assert(
		RunService:IsStudio() and world:GetAttribute("OceanDepthsPreview") == true,
		"Expected the Ocean Depths Studio preview"
	)
	local lobby = world.Lobby
	local anchor = lobby.KickZone.KickZoneFloor
	Look.applyLobbySwimmers(lobby.Environment.OpenWater, anchor.Position - Vector3.new(55, 20.42, 127.6))
	local zone = world.FootballCourse.Zones.Zone01
	Reef.applySwimmers(zone, zone.Environment.CoralGardens)
end

local function dressLandmarks(world: any)
	local lobby = world.Lobby
	local decor = lobby.Environment.ClubDecor
	decor.Trees:Destroy()
	decor.WallGreenery:Destroy()
	decor.LobbyBalls:Destroy()
	OceanDepths.applyLobbySign(world)
	OceanDepths.applyLobbyLandmarks(world)
	dressEggs(lobby, decor.PremiumEggStand)
end

function OceanDepths.applyLobbyReef(world: any): Model
	assert(
		RunService:IsStudio() and world:GetAttribute("OceanDepthsPreview") == true,
		"Expected the Ocean Depths Studio preview"
	)
	local lobby = world.Lobby
	local environment: Instance = lobby.Environment
	local existing = environment:FindFirstChild("CoralGardens")
	local garden: Instance
	if existing then
		garden = existing
	else
		local folder = Instance.new("Folder")
		folder.Name = "CoralGardens"
		folder.Parent = environment
		garden = folder
	end
	local anchor: BasePart = lobby.KickZone.KickZoneFloor
	local offset = anchor.Position - Vector3.new(55, 20.42, 127.6)
	local surfaces = Ground.collect(lobby, { CapSurface = true, LawnCell = true })
	local function settle(cf: CFrame, size: Vector2): CFrame
		return Ground.fit(surfaces, cf, size, 0.27, 7)
	end
	local plants = Instance.new("Model")
	plants.Name = "ReefPlantings"
	for _, entry in
		{
			{ at = Vector3.new(-7.8, 35.81, 237), species = "PinkStaghorn", scale = 0.92 },
			{ at = Vector3.new(-12.8, 45.41, 160), species = "OrangeBranch", scale = 0.83 },
			{ at = Vector3.new(-12.1, 45.41, 219), species = "LavenderFan", scale = 0.79 },
			{ at = Vector3.new(-17.25, 57.41, 146), species = "MintAnemone", scale = 0.68 },
			{ at = Vector3.new(-17.2, 57.41, 211), species = "PinkTubes", scale = 0.68 },
			{ at = Vector3.new(-24.5, 69.41, 172), species = "PinkStaghorn", scale = 1.16 },
			{ at = Vector3.new(-24.7, 69.41, 221), species = "OrangeBranch", scale = 0.98 },
			{ at = Vector3.new(118.2, 35.81, 232), species = "MintAnemone", scale = 0.77 },
			{ at = Vector3.new(123.1, 47.81, 179), species = "LavenderFan", scale = 0.86 },
			{ at = Vector3.new(127.25, 57.41, 213), species = "PinkStaghorn", scale = 0.75 },
			{ at = Vector3.new(127.4, 57.41, 241), species = "OrangeTubes", scale = 0.75 },
			{ at = Vector3.new(135.4, 69.41, 166), species = "OrangeBranch", scale = 0.91 },
			{ at = Vector3.new(134.6, 69.41, 204), species = "LavenderFan", scale = 1.08 },
			{ at = Vector3.new(21, 33.41, 261), species = "OrangeTubes", scale = 0.8 },
			{ at = Vector3.new(77, 45.41, 268), species = "MintAnemone", scale = 0.87 },
			{ at = Vector3.new(104, 57.41, 275), species = "RibbonKelp", scale = 0.76 },
		}
	do
		local rotation = if entry.at.X < 0 or entry.at.X > 112 then math.pi * 0.48 else 0.2
		local cf = CFrame.new(entry.at + offset) * CFrame.Angles(0, rotation, 0)
		Kit.place(plants, entry.species, settle(cf, Kit.footprint(entry.species, entry.scale)), entry.scale)
	end
	for index, entry in
		{
			{ name = "CornerWaterfall1BubbleSpring", at = Vector3.new(55.3, 20.35, 254.5), yaw = 0.15, scale = 1.05 },
			{ name = "CornerWaterfall1TerraceVent", at = Vector3.new(55.3, 69.41, 276.3), yaw = 0, scale = 0.8 },
			{ name = "SideWaterfallBubbleSpring", at = Vector3.new(112, 20.35, 150.7), yaw = 1.25, scale = 1.14 },
			{ name = "SideWaterfallTerraceVent", at = Vector3.new(132.3, 69.41, 150.7), yaw = 1.55, scale = 0.81 },
		}
	do
		local cf = CFrame.new(entry.at + offset) * CFrame.Angles(0, entry.yaw, 0)
		Kit.spring(plants, entry.name, cf, entry.scale, index % 2 == 0, settle)
	end
	for _, old in garden:GetChildren() do
		if
			old.Name == plants.Name
			or old.Name:match("^CornerWaterfall1")
			or old.Name:match("^SideWaterfall")
			or (old.Name == "CoralColony" and old:FindFirstChild("ReefStone"))
		then
			old:Destroy()
		end
	end
	plants.Parent = garden
	return plants
end

local function isolate(world: Model)
	for _, instance in world:GetDescendants() do
		for _, tag in CollectionService:GetTags(instance) do
			CollectionService:RemoveTag(instance, tag)
		end
		if instance:IsA("LuaSourceContainer") or instance:IsA("ProximityPrompt") or instance:IsA("ClickDetector") then
			instance:Destroy()
		elseif instance:IsA("ObjectValue") and instance.Value and not instance.Value:IsDescendantOf(world) then
			instance.Value = nil
		elseif instance:IsA("SpawnLocation") then
			instance.Enabled = false
		elseif instance:IsA("BasePart") then
			instance.CanTouch = false
		end
	end
end

function OceanDepths.build(source: any): Model
	assert(RunService:IsStudio(), "Ocean Depths is in Studio authoring")
	assert(source.Name == "World1" and source.Parent, "Expected the live World1 template")
	local map: Instance = source.Parent
	local previous = map:FindFirstChild("World2")
	assert(not previous or previous:GetAttribute("OceanDepthsPreview") == true, "World2 is already occupied")

	local world = Instance.new("Model")
	world.Name = "World2"
	world:SetAttribute("OceanDepthsPreview", true)
	world:SetAttribute("WorldScale", source:GetAttribute("WorldScale"))
	world:SetAttribute("DisplayName", "Ocean Depths")
	local lobby = source.Lobby:Clone()
	lobby.Parent = world
	source.TrainingArea:Clone().Parent = world

	local course = Instance.new("Folder")
	course.Name = "FootballCourse"
	course.Parent = world
	local zones = Instance.new("Folder")
	zones.Name = "Zones"
	zones.Parent = course
	local zone = source.FootballCourse.Zones.Zone01:Clone()
	zone.Parent = zones
	zone:SetAttribute("BiomeName", "Coral Reef")
	zone.Environment:ClearAllChildren()
	recolor(lobby.Geometry, terrainColors)
	recolor(lobby.Environment, terrainColors)
	recolor(zone, terrainColors)
	for _, part in lobby.Environment:GetDescendants() do
		if part:IsA("BasePart") and part.Position.Y > 67 and part.Color == turquoise then
			part.Color = sand
		end
	end
	for _, part in zone.Geometry.GroundCladding:GetDescendants() do
		if part:IsA("BasePart") then
			if part.Name == "Turf" and part.Color == turquoise then
				part.Color = color("FFE3A0")
			end
		end
	end
	tintStructure(lobby.BallShop.Structure, color("75A7C6"), color("2B547F"))
	dressLandmarks(world)
	lobby.Environment.CornerWaterfall1:Destroy()
	lobby.Environment.SideWaterfall:Destroy()
	OceanDepths.applyLobbyReef(world)
	Look.water(lobby.Environment)
	Reef.apply(zone)
	isolate(world)
	world:SetAttribute("WorldLayoutReady", true)
	world:PivotTo(world:GetPivot() + OFFSET)
	world.Parent = map
	WorldHDStuds.apply(world)
	if previous then
		previous:Destroy()
	end
	return world
end

OceanDepths.previewLighting = Look.previewLighting

function OceanDepths.applyLocation(world: any, index: number): Model
	return Course.applyZone(world, index)
end

function OceanDepths.applyLocations(world: any)
	for index = 2, 8 do
		Course.applyZone(world, index)
	end
	Course.extendWater(world)
end

function OceanDepths.applyCoralReef(world: any): Model
	assert(
		RunService:IsStudio() and world:GetAttribute("OceanDepthsPreview") == true,
		"Expected the Ocean Depths Studio preview"
	)
	return Reef.apply(world.FootballCourse.Zones.Zone01)
end

function OceanDepths.animate(world: any, water: Model)
	local reef = world.FootballCourse.Zones.Zone01.Environment:FindFirstChild("CoralGardens")
	Look.animate(world, water, reef and reef:FindFirstChild("ReefSwimmers"))
end

return OceanDepths
