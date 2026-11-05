-- Studio authoring: the seven approved environments after Coral Reef.
-- New zones use the existing pitch and line geometry, with separately owned side scenery.
local RunService = game:GetService("RunService")
local Look = require(script.Parent.OceanDepthsLook)
local Kit = require(script.Parent.OceanLocationKit)
local Ground = require(script.Parent.OceanReefGround)
local ReefKit = require(script.Parent.OceanReefKit)
local HDStuds = require(script.Parent.HDStuds)
local Course = {}
local C = Color3.fromHex
local blue = C("438CC1")
local sand = C("F4DDA7")
Course.Names = {
	"Coral Reef",
	"Kelp Forest",
	"Sunken Fleet",
	"Lost City",
	"Jellyfish Canyon",
	"Vent Fields",
	"Abyssal Trench",
	"Pearl Grotto",
}
Course.Keys = {
	"CoralReef",
	"KelpForest",
	"SunkenFleet",
	"LostCity",
	"JellyfishCanyon",
	"VentFields",
	"AbyssalTrench",
	"PearlGrotto",
}

local function plant(k: any, parent: Instance, cf: CFrame, scale: number)
	return k.asset(parent, "AmberKelp", cf, scale, Vector2.new(4.8, 4.8) * scale, "Kelp")
end

local function coral(k: any, parent: Instance, cf: CFrame, index: number, scale: number)
	local species = ({ "PinkStaghorn", "OrangeBranch", "MintAnemone" })[(index - 1) % 3 + 1]
	local settled = Ground.fit(k.surfaces, cf, ReefKit.footprint(species, scale), 0.2)
	return ReefKit.place(parent, species, settled, scale)
end

local function kelp(k: any, env: Instance)
	for _, side in { -1, 1 } do
		for i = 1, 9 do
			local s = (i - 0.5) * k.field.Size.Z / 9
			local x = side * (76.8 + (i % 3) * 16.8)
			local hero = side == -1 and i == 7
			local top = k.terrace(
				env,
				k.at(x, k.shore, s),
				if hero then 43.2 else 28.8,
				28.8,
				if hero then 4 else 1 + i % 3,
				blue
			)
			plant(k, env, top, if hero then 2.2 else 1.15 + (i % 3) * 0.18)
			plant(k, env, k.at(side * 132, k.shore, s + 9), 0.85 + (i % 2) * 0.2)
			if i % 2 == 0 then
				k.asset(env, "GoldenSeahorse", top * CFrame.new(side * 9, 6, -4), 0.95, nil, "Seahorse")
			end
			coral(k, env, k.at(side * 50.4, 2.474, s - 4), 3, 0.75)
			local cf =
				Ground.fit(k.surfaces, k.at(side * 55.2, 2.474, s + 6), ReefKit.footprint("RibbonKelp", 0.9), 0.2)
			ReefKit.place(env, "RibbonKelp", cf, 0.9)
		end
		for i = 1, 11 do
			local s = 10 + i * 27 + (i % 3) * 2.4
			plant(k, env, k.at(side * (45.6 + (i % 2) * 9.6), 2.474, s), 0.5 + (i % 3) * 0.06)
		end
	end
end

local function fleet(k: any, env: Instance)
	for i, s in { 67.2, 230.4 } do
		local side = if i == 1 then -1 else 1
		local footprint = Vector2.new(31.2, 86.4) * (if i == 1 then 1.5 else 2)
		local cf = Ground.fit(
			k.surfaces,
			k.at(side * 100, k.shore, s) * CFrame.Angles(0, if side == 1 then math.pi else 0, 0),
			footprint,
			0.2
		)
		local ship = Kit.ship(k, env, cf, if i == 1 then 1.5 else 2)
		k.grounded(ship, cf, footprint)
	end
	for i = 1, 8 do
		local side = if i % 2 == 0 then -1 else 1
		local s = 18 + i * 33
		local top = k.terrace(env, k.at(side * 50.4, 2.474, s), 19.2, 19.2, 1 + i % 2, blue)
		coral(k, env, top, i, 0.8)
		plant(k, env, k.at(side * 145.2, k.shore, s), 0.45)
	end
	local anchor, cf = k.root(env, "HalfBuriedAnchor", k.at(127.2, k.shore, 62), Vector2.new(43.2, 28.8))
	k.segment(
		anchor,
		"Shank",
		(cf * CFrame.new(0, -1, 0)).Position,
		(cf * CFrame.new(0, 18, 0)).Position,
		2.4,
		C("34475A")
	)
	k.box(anchor, "Stock", cf * CFrame.new(0, 14.4, 0), Vector3.new(21.6, 2.4, 2.4), C("D0A453"))
	for _, side in { -1, 1 } do
		k.segment(
			anchor,
			"Fluke",
			(cf * CFrame.new(0, 0, 0)).Position,
			(cf * CFrame.new(side * 10.8, 5, 0)).Position,
			3.6,
			C("34475A")
		)
		k.segment(
			anchor,
			"FlukeTip",
			(cf * CFrame.new(side * 10.8, 5, 0)).Position,
			(cf * CFrame.new(side * 10, 9, 0)).Position,
			3.6,
			C("34475A")
		)
	end
	for i = 1, 6 do
		local p = cf * CFrame.new((i - 1) * 1.8, 0.3, (i - 1) * 1.2)
		for _, side in { -1, 1 } do
			k.box(anchor, "ChainLink", p * CFrame.new(side * 0.8, 0, 0), Vector3.new(0.6, 0.6, 2.4), C("A78B58"), true)
			k.box(anchor, "ChainLink", p * CFrame.new(0, 0, side * 1.1), Vector3.new(2.1, 0.6, 0.6), C("A78B58"), true)
		end
	end
end

local function city(k: any, env: Instance)
	local cream = C("F8E8BB")
	local teal = C("48C4C4")
	for _, entry in { { -93.6, 30, 3 }, { 100.8, 40, 3 }, { -110.4, 200, 4 }, { 100.8, 145, 2 } } do
		local x, s, count = table.unpack(entry)
		local width = math.max(28.8, count * 12)
		local top = k.terrace(env, k.at(x, k.shore, s), width, 24, 2, blue)
		local ruin = Look.model(env, "OpenColonnade")
		for i = 1, count do
			Kit.column(
				k,
				ruin,
				top * CFrame.new((i - (count + 1) / 2) * 12, 0, 0),
				if i == count and s < 100 then 7.2 else 14.4
			)
		end
		if count >= 3 then
			k.box(ruin, "Lintel", top * CFrame.new(-6, 21, 0), Vector3.new((count - 1) * 12 + 7.2, 2.4, 7.2), cream)
		end
	end
	for _, site in { { -105.6, 121 }, { 105.6, 235 } } do
		local siteX, s = table.unpack(site)
		local top = k.terrace(env, k.at(siteX, k.shore, s), 48, 38.4, 2, blue)
		local temple = Look.model(env, "SmallSteppedTemple")
		local entrance = top * CFrame.Angles(0, math.pi, 0)
		k.box(temple, "Sanctum", entrance * CFrame.new(0, 8.4, 7.2), Vector3.new(31.2, 16.8, 19.2), cream)
		for _, x in { -16.8, -5.6, 5.6, 16.8 } do
			Kit.column(k, temple, entrance * CFrame.new(x, 0, -10.8), 12)
		end
		for tier = 1, 4 do
			k.box(
				temple,
				"SteppedRoof",
				top * CFrame.new(0, 18 + (tier - 0.5) * 2.4, 0),
				Vector3.new(43.2 - tier * 4.8, 2.4, 33.6 - tier * 4.8),
				if tier == 1 then cream else teal
			)
		end
	end
	local top = k.terrace(env, k.at(100.8, k.shore, 88), 43.2, 38.4, 2, blue)
	local basin = Look.model(env, "SandfilledShellBasin")
	local fill = Look.part(
		basin,
		"SandInBasin",
		top * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(2.4, 31.2, 31.2),
		sand
	)
	fill.Shape = Enum.PartType.Cylinder
	for side = 0, 11 do
		local cf = top * CFrame.Angles(0, side * math.pi / 6, 0) * CFrame.new(0, 1.2, 16.8)
		k.box(basin, "BasinRim", cf, Vector3.new(9.6, 2.4, 2.4), cream)
	end
	k.box(basin, "ShellPlinth", top * CFrame.new(0, 3, 0), Vector3.new(4.8, 1.2, 4.8), teal)
	k.shell(basin, top * CFrame.new(0, 3.6, 0), 1.2)
	for i = 1, 8 do
		local side = if i % 2 == 0 then -1 else 1
		local s = 18 + i * 35
		local top2 = k.terrace(env, k.at(side * 50.4, 2.474, s), 12, 12, 1, blue)
		k.shell(env, top2, 0.42)
		coral(k, env, k.at(side * 145.2, k.shore, s), 1, 0.8)
	end
	for _, side in { -1, 1 } do
		for i = 1, 12 do
			local ruin, base =
				k.root(env, "BuriedMosaicWall", k.at(side * 67.2, k.shore, 8 + i * 24), Vector2.new(7.2, 16.8))
			local h = 2.4 + (i % 3) * 1.2
			k.box(ruin, "BrokenWall", base * CFrame.new(0, h / 2, 0), Vector3.new(7.2, h, 16.8), cream)
			k.box(
				ruin,
				"MosaicInset",
				base * CFrame.new(-side * 3.65, 1.2, -3.6),
				Vector3.new(0.12, 1.2, 7.2),
				teal,
				true
			)
		end
	end
	-- The gateway frames the far left bank; the continuous course has no overhead obstruction.
	local gate = Look.model(env, "DistantCityGateway")
	for _, side in { -1, 1 } do
		local x = -108 + side * 30
		local pier, cf = k.root(gate, "GatewayPier", k.at(x, k.shore, 300), Vector2.new(12, 19.2))
		k.box(pier, "Pier", cf * CFrame.new(0, 14.4, 0), Vector3.new(12, 28.8, 19.2), cream)
		for tier = 1, 4 do
			k.box(
				pier,
				"CorbelledArch",
				cf * CFrame.new(-side * tier * 3.6, 28.8 + (tier - 0.5) * 3.6, 0),
				Vector3.new(12, 3.6, 19.2),
				cream
			)
		end
	end
	k.box(gate, "HighLintel", k.at(-108, k.shore + 44.4, 300), Vector3.new(72, 2.4, 19.2), teal)
	k.shell(gate, k.at(-108, k.shore + 45.6, 300), 0.6)
	local school = Look.school(env, k.at(-108, 62, 300).Position, 2, Random.new(492), 16)
	for _, p in school:GetDescendants() do
		if p:IsA("UnionOperation") then
			p.UsePartColor = true
			p.Color = C("D6EEF1")
		end
	end
end

local function jelly(k: any, env: Instance)
	for _, side in { -1, 1 } do
		local wall, base =
			k.root(env, "ContinuousCanyonWall", k.at(side * 136.8, k.shore, 162), Vector2.new(38.4, 321.6))
		k.box(wall, "CliffFoundation", base * CFrame.new(0, 12, 0), Vector3.new(38.4, 24, 321.6), C("3074B0"))
		for i = 1, 9 do
			local s = (i - 0.5) * k.field.Size.Z / 9
			if not (side == -1 and i >= 2 and i <= 4) then
				k.terrace(env, k.at(side * 103.2, k.shore, s), 48, 33.6, 2 + i % 2, C("316FA8"))
			end
			for tier = 1, 2 + i % 3 do
				k.box(
					wall,
					"CliffStratum",
					k.at(side * 136.8, k.shore + 24 + (tier - 0.5) * 12, s),
					Vector3.new(38.4 - tier * 4.8, 12, 31.2 - tier * 2.4),
					C("3074B0"):Lerp(C("69B7D5"), tier * 0.07)
				)
			end
			local cf = k.at(side * (if i % 2 == 0 then 70 else 88), 25 + (i % 3) * 4, s)
			local size = if side == -1 and i == 1 then 2 else if side == 1 and i == 3 then 1.7 else 0.8 + (i % 4) * 0.18
			local m = k.asset(env, "ReefJellyfish", cf, size, nil, "Jellyfish")
			local hue = C(if side == -1 then "EB95D3" else "8CE3EE")
			for _, p in m:GetChildren() do
				if p:IsA("UnionOperation") then
					p.UsePartColor = true
					p.Color = hue
					p.Material = Enum.Material.Glass
					p.Transparency = if p.Name == "Body" then 0.18 else 0.06
				end
			end
			local core = m:FindFirstChild("Features") or m:FindFirstChildWhichIsA("BasePart")
			k.light(core, hue, 26, 0.8)
			local glow = Look.ellipsoid(
				env,
				"CanyonPulse",
				k.at(side * 38.4, 4.2, s),
				Vector3.one * 1.8,
				hue,
				Enum.Material.Neon
			)
			glow:SetAttribute("OceanPulse", i * 0.32)
			k.light(glow, hue, 11, 0.35)
		end
	end
	-- A supported niche on the left, assembled as a back wall and two side pillars.
	local grotto = Look.model(env, "JellyfishAlcove")
	for _, s in { 48, 112 } do
		local pier, cf = k.root(grotto, "AlcovePier", k.at(-74.4, k.shore, s), Vector2.new(19.2, 19.2))
		k.box(pier, "NichePillar", cf * CFrame.new(0, 19.2, 0), Vector3.new(19.2, 38.4, 19.2), blue)
	end
	k.box(grotto, "AlcoveLintel", k.at(-100.8, k.shore + 40.8, 80), Vector3.new(72, 4.8, 84), blue)
	for n = 1, 3 do
		local m =
			k.asset(grotto, "ReefJellyfish", k.at(-96, 25 + (n % 2) * 3, 48 + n * 16), 1.1 + n * 0.2, nil, "Jellyfish")
		for _, p in m:GetChildren() do
			if p:IsA("UnionOperation") then
				p.UsePartColor = true
				p.Color = C("EE9AE0")
				p.Material = Enum.Material.Glass
				p.Transparency = 0.14
			end
		end
		k.light(m:FindFirstChildWhichIsA("BasePart"), C("F49DE6"), 28, 0.85)
	end
end

local function vents(k: any, env: Instance)
	for _, side in { -1, 1 } do
		for i = 1, 7 do
			local s = 24 + (i - 1) * 44 + (if side == 1 then 9.6 else 0)
			local x = side * (if side == -1 then 108 else 96)
			local hero = if side == -1 then i == 1 or i == 3 or i == 6 else i == 2 or i == 4 or i == 7
			local tiers = if hero then 3 + i % 2 else 1 + i % 2
			local top = k.terrace(env, k.at(x, k.shore, s), 48, 38.4, tiers, C("395A77"))
			local count = if hero then 3 else 1
			for n = 1, count do
				local cf = top * CFrame.new((n - (count + 1) / 2) * 8.4, 0, 0)
				Kit.chimney(k, env, cf, if hero then 18 + (i % 3) * 9.6 + n * 2.4 else 9.6 + i % 2 * 4.8, 4.8)
			end
			Kit.worms(k, env, top * CFrame.new(0, 0, 4.8), 7)
			Kit.worms(k, env, k.at(side * 72, k.shore, s + 6), 5)
		end
	end
	local ridge = Look.model(env, "BasaltCathedralRidge")
	for _, site in { { -1, 96 }, { 1, 228 } } do
		local side, s = table.unpack(site)
		local p =
			k.box(ridge, "BasaltRidge", k.at(side * 142.8, k.shore + 8.4, s), Vector3.new(24, 16.8, 139.2), C("35536D"))
		Ground.add(k.surfaces, p)
		for n = 1, 3 do
			Kit.chimney(
				k,
				ridge,
				k.at(side * 142.8, k.shore + 16.8, s + (n - 2) * 13.2),
				43.2 + (n + side) % 2 * 12,
				4.8
			)
		end
	end
end

local function abyss(k: any, env: Instance)
	-- Both banks are continuous: the former deep right-hand trench is filled.
	for _, side in { -1, 1 } do
		local wall, base =
			k.root(env, "ContinuousAmphitheatreWall", k.at(side * 138, k.shore, 162), Vector2.new(36, 321.6))
		k.box(wall, "ContinuousStrata", base * CFrame.new(0, 18, 0), Vector3.new(36, 36, 321.6), C("245179"))
		for i = 1, 10 do
			local phase = if side == 1 then 1 else 0
			local s = (i - 0.5) * k.field.Size.Z / 10 + phase * 1.2
			local top = k.terrace(env, k.at(side * 93.6, k.shore, s), 43.2, 28.8, 2 + (i + phase) % 2, C("285880"))
			local profile = Look.model(env, "AmphitheatreWall")
			local summit
			for tier = 1, 3 + (i + phase) % 3 do
				local stratum = k.box(
					profile,
					"ToweringStrata",
					k.at(side * 138, k.shore + 36 + (tier - 0.5) * 12, s),
					Vector3.new(36 - tier * 4.8, 12, 26.4 - tier * 2.4),
					C("245179")
				)
				Ground.add(k.surfaces, stratum)
				summit = stratum.CFrame * CFrame.new(0, 6, 0)
			end
			local crown = k.asset(env, "MintCrystals", assert(summit), 0.7, Vector2.new(7.2, 7.2) * 0.7)
			k.light(crown:FindFirstChildWhichIsA("BasePart"), C("73D9EE"), 18, 0.45)
			k.asset(env, "MintCrystals", top * CFrame.new(-side * 12, 0, 0), 0.7, Vector2.new(7.2, 7.2) * 0.7)
			plant(k, env, k.at(side * 70.8, k.shore, s), 0.5)
			coral(k, env, k.at(side * 66, k.shore, s + (if side == 1 then -8 else 8)), i + phase, 0.7)
			if (i + phase) % 2 == 0 then
				local fish = k.asset(
					env,
					"Anglerfish",
					k.at(side * 84, k.shore + 13 + (i % 3) * 5, s + 6),
					1.1,
					nil,
					"Anglerfish"
				)
				k.light(fish:FindFirstChild("Features"), C("FFD37B"), 14, 0.7)
			end
		end
	end
	k.asset(env, "AbyssSquid", k.at(102, 44, 258) * CFrame.Angles(0, -0.5, -0.3), 2.2, nil, "Squid")
end

local function pearl(k: any, env: Instance)
	local displayBase
	for _, side in { -1, 1 } do
		for i = 1, 8 do
			local s = 20 + (i - 1) * 40
			local top = k.terrace(env, k.at(side * 100.8, k.shore, s), 57.6, 33.6, 2 + i % 3, blue)
			if side == 1 and i == 1 then
				displayBase = top
			end
			local wall = Look.model(env, "MineralGrottoWall")
			local wallBase = k.at(side * 132, k.shore, s)
			-- Bury the whole lower edge of each leaning mass, giving a continuous sand contact.
			local depth = if i == 1 or i == 8 then 38.4 else 40.8
			local height = 108 + ((i + side) % 3) * 12
			local lean = wallBase * CFrame.Angles(0, 0, side * 0.4)
			local bury = 21.6 * math.tan(0.4)
			k.grounded(wall, wallBase, Vector2.new(48, depth))
			k.box(
				wall,
				"LeaningVaultMass",
				lean * CFrame.new(0, height / 2 - bury, 0),
				Vector3.new(43.2, height, depth),
				blue:Lerp(C("649EC5"), (i % 3) * 0.04)
			)
			for band = 1, 3 do
				for vein = 1, 3 do
					k.box(
						wall,
						"CreamMineralVein",
						lean * CFrame.new(-side * 21.7, band * 24 - bury + (vein % 2) * 1.2, (vein - 2) * 12),
						Vector3.new(1.2, 2.4, 14.4),
						C("E9DDB8")
					)
				end
			end
			if not (side == 1 and i == 1) then
				k.asset(
					env,
					"MintCrystals",
					top * CFrame.new(-side * 12, 0, 0) * CFrame.Angles(0, i * 0.63, 0),
					1.5 + (i % 3) * 0.16,
					Vector2.new(7.2, 7.2) * (1.5 + (i % 3) * 0.16)
				)
			end
			k.shell(env, k.at(side * 66, k.shore, s), 0.4)
			if i % 2 == 0 then
				coral(k, env, k.at(side * 55.2, 2.474, s + 12), i, 0.8)
			end
		end
	end
	local display = Look.model(env, "PearlDisplay")
	local top = k.terrace(display, assert(displayBase), 33.6, 16.8, 2, C("E2D6AD"))
	for i = -1, 1 do
		Look.ellipsoid(
			display,
			"Pearl",
			top * CFrame.new(i * 7.2, if i == 0 then 4.5 else 2.4, 0),
			Vector3.one * (if i == 0 then 9 else 4.8),
			C("F3E7F2"),
			Enum.Material.Glass
		)
	end
	-- The finale has its own foundation beyond the playable pitch, not an obstacle on the field.
	local finale = Look.model(env, "PearlFinale")
	local base = k.box(finale, "FinaleBedrock", k.at(0, -3, 354), Vector3.new(144, 18, 60), blue)
	base.CanCollide = true
	Ground.add(k.surfaces, base)
	local top2 = k.terrace(finale, k.at(0, 6, 354), 96, 48, 3, blue)
	local lower = k.shell(finale, top2 * CFrame.new(0, 7.2, -8) * CFrame.Angles(math.pi / 2, 0, 0), 2.6)
	lower.Name = "LowerValve"
	local upper = k.shell(finale, top2 * CFrame.new(0, 7.2, -8), 2.6)
	upper.Name = "UpperValve"
	upper:SetAttribute("OceanMotion", "ShellValve")
	local orb = Look.ellipsoid(
		finale,
		"HeartPearl",
		top2 * CFrame.new(0, 9.6, 10),
		Vector3.one * 16.8,
		C("E2FFF4"),
		Enum.Material.Glass
	)
	k.light(orb, C("A4F7E8"), 58, 2)
	finale:SetAttribute("ArrivalIllumination", true)
end

local builders = { [2] = kelp, [3] = fleet, [4] = city, [5] = jelly, [6] = vents, [7] = abyss, [8] = pearl }

function Course.applyZone(world: any, index: number): Model
	assert(RunService:IsStudio() and not RunService:IsRunning(), "Author locations in Studio Edit")
	assert(world:GetAttribute("OceanDepthsPreview") == true and builders[index], "Expected Ocean Depths zone 2–8")
	local zones = world.FootballCourse.Zones
	local source = zones.Zone01
	local zone = Instance.new("Model")
	zone.Name = ("Zone%02d"):format(index)
	zone:SetAttribute("BiomeName", Course.Names[index])
	zone:SetAttribute("OceanCourseVersion", 1)
	zone:SetAttribute("Reference", "Assets/OceanDepths/" .. Course.Keys[index] .. "/prompts.json")
	local old = zones:FindFirstChild(zone.Name)
	assert(not old or old:GetAttribute("OceanCourseVersion"), "Preserve unowned existing zone")
	local geometry = Instance.new("Folder")
	geometry.Name = "Geometry"
	geometry.Parent = zone
	local environment = Instance.new("Folder")
	environment.Name = "Environment"
	environment.Parent = zone
	local boundaries = Instance.new("Folder")
	boundaries.Name = "Boundaries"
	boundaries.Parent = zone
	local field = source.Field:Clone()
	-- The complete Turf/Line cladding covers this physical pitch. Retire its redundant top texture.
	for _, child in field:GetChildren() do
		if child:IsA("Texture") and child.Face == Enum.NormalId.Top then
			child:Destroy()
		end
	end
	field.CFrame = source.Field.CFrame * CFrame.new(0, 0, -source.Field.Size.Z * (index - 1))
	field.Parent = zone
	local delta = field.Position - source.Field.Position
	local pitch = Look.model(geometry, "PitchCladding")
	local tile = Look.studsTile(source.Geometry.GroundCladding:FindFirstChild("Turf", true))
	local k = Kit.new(field, tile)
	local colors = if index == 4
		then { C("8DE0D8"), C("B7E9DE") }
		elseif index == 5 or index == 6 then { C("B7D8E7"), C("E8F0E8") }
		else { C("F6D79A"), C("FFE6B0") }
	for _, p in source.Geometry.GroundCladding:GetDescendants() do
		if p:IsA("BasePart") and (p.Name == "Turf" or p.Name == "Line") then
			local clone = p:Clone()
			HDStuds.apply(clone, tile)
			for _, child in clone:GetChildren() do
				if child:IsA("Texture") and child.Texture == HDStuds.LegacyImage then
					child:Destroy()
				end
			end
			clone.CFrame = p.CFrame + delta
			if p.Name == "Turf" then
				clone.Color = colors[if p.Color.R > 0.98 then 2 else 1]
			end
			clone.Parent = pitch
		end
	end
	local banks = Look.model(geometry, "SeabedBanks")
	for _, side in { -1, 1 } do
		for _, entry in { { 50.4, 2.474, 24, 18 }, { 110.4, k.shore, 96, 24 } } do
			local x, top, width, h = table.unpack(entry)
			local p = k.box(
				banks,
				"SandBank",
				k.at(side * x, top - h / 2, field.Size.Z / 2),
				Vector3.new(width, h, field.Size.Z),
				sand
			)
			p.CanCollide = true
			Ground.add(k.surfaces, p)
		end
		k.box(
			banks,
			"TurquoiseCoping",
			k.at(side * 36, 2.474, field.Size.Z / 2),
			Vector3.new(4.8, 1.2, field.Size.Z),
			C("22BDCB")
		)
	end
	local decor = Look.model(environment, Course.Keys[index])
	local bed = k.box(geometry, "Seabed", k.at(0, -15, 162), Vector3.new(480, 12, 324), C("277EA2"))
	Ground.add(k.surfaces, bed)
	builders[index](k, decor)
	local atmosphere = Look.model(environment, "WaterAtmosphere")
	for _, side in { -1, 1 } do
		for n = 1, 3 do
			if index < 7 then
				local ray = game.ServerStorage.Assets.OceanDepths.Effects.OceanSunShaft:Clone()
				ray.CFrame = k.at(side * 100, 145, n * 87)
				ray.Parent = atmosphere
			end
			local bubble = game.ServerStorage.Assets.OceanDepths.Effects.OceanBubbleSpring:Clone()
			bubble.CFrame = k.at(side * 61, 4, n * 87 + 12)
			bubble.Parent = atmosphere
		end
		if index ~= 7 then
			for n = 1, 6 do
				local top = k.terrace(
					decor,
					k.at(side * (184.8 + n % 2 * 26.4), -9, (n - 0.5) * 54),
					28.8,
					28.8,
					1 + n % 3,
					C("357FA7")
				)
				if index == 2 then
					plant(k, decor, top, 0.55)
				end
			end
		end
	end
	if index == 2 or index == 3 then
		for _, side in { -1, 1 } do
			Look.school(decor, k.at(side * 172, 35, 130).Position, index, Random.new(170 + side), 10)
		end
	end
	zone.WorldPivot = field.CFrame
	zone.Parent = zones
	if old then
		old:Destroy()
	end
	task.wait()
	return zone
end

function Course.extendWater(world: any)
	local backdrop = world.Lobby.Environment.OpenWater.WaterBackdrop
	for _, p in backdrop:GetChildren() do
		if p:GetAttribute("OceanWaterSegment") then
			p:Destroy()
		end
	end
	local center = world.FootballCourse.Zones.Zone01.Field.Position
	local length = 8 * 324 + 700
	local origin = Vector3.new(center.X, 80, center.Z - 3.5 * 324)
	for _, wall in backdrop:GetChildren() do
		if wall.Name == "WaterSurface" then
			wall.Size = Vector3.new(800, 0.12, length / 2)
			wall.Position = origin + Vector3.new(0, 180, -length / 4)
			local segment = wall:Clone()
			segment.Name = "WaterSurfaceSegment"
			segment:SetAttribute("OceanWaterSegment", true)
			segment.Position = origin + Vector3.new(0, 180, length / 4)
			segment.Parent = backdrop
		end
	end
end

return Course
