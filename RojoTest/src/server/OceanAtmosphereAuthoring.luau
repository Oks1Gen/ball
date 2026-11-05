-- Edit-only atmosphere dressing. Never rebuilds an existing landscape.
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Swim = require(game.ReplicatedStorage.Shared.Core.OceanSwimming)
local Navigation = require(script.Parent.OceanWildlifeAuthoring)
local HDStuds = require(script.Parent.HDStuds)
local Author = {}

function Author.removeOldBackground(world: any): number
	assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning())
	local count = 0
	local backdrop = world.Lobby.Environment.OpenWater.WaterBackdrop
	for _, n in backdrop:GetChildren() do
		if n:IsA("BasePart") and (n.Name == "WaterGradient" or n.Name == "WaterGradientSegment") then
			assert(not n.CanCollide and not n.CanTouch and not n.CanQuery, "Background has a physical role")
			n:Destroy()
			count += 1
		end
	end
	local environment = world.FootballCourse:FindFirstChild("Environment")
	local old = environment and environment:FindFirstChild("DepthHorizon")
	if old then
		for _, n in old:GetDescendants() do
			if n:IsA("BasePart") then
				assert(not n.CanCollide and not n.CanTouch and not n.CanQuery)
				count += 1
			end
		end
		old:Destroy()
	end
	return count
end
local C = Color3.fromHex
type Reservation = { origin: CFrame, rx: number, rz: number, radius: number }

local function part(parent: Instance, name: string, cf: CFrame, size: Vector3, color: Color3): Part
	local p = Instance.new("Part")
	p.Name, p.CFrame, p.Size, p.Color = name, cf, size, color
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

local function model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name, m.Parent = name, parent
	return m
end

local function reserveClear(cf: CFrame, rx: number, rz: number, radius: number, reservations: { Reservation }): boolean
	for _, r in reservations do
		local d = cf.Position - r.origin.Position
		if
			math.abs(d.X) < rx + r.rx + radius + r.radius
			and math.abs(d.Z) < rz + r.rz + radius + r.radius
			and math.abs(d.Y) < radius + r.radius + 3
		then
			return false
		end
	end
	return true
end

local function route(
	parent: Instance,
	field: BasePart,
	template: Model,
	cf: CFrame,
	rx: number,
	rz: number,
	count: number,
	scale: number,
	seed: number,
	reservations: { Reservation }
): Model
	local group = model(parent, count > 1 and "ForegroundSchool" or "MantaEncounter")
	group.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local limit = if count > 1 then 8 else 0
	local radius = (template:GetAttribute("NavigationRadius") :: number) * scale + limit + 1.8
	local attributes: { [string]: any } = {
		WildlifeRoute = true,
		AmbientAuthored = true,
		ForegroundSchool = count > 1,
		AnchorIndex = field:GetAttribute("WildlifeAnchorIndex") or 0,
		RouteOrigin = field.CFrame:ToObjectSpace(cf),
		RouteX = rx,
		RouteZ = rz,
		RouteSpeed = if count > 1 then 12 else 10,
		RouteSeed = seed,
		MemberLimit = limit,
		MemberMotionScale = 1,
		MotionRate = if count > 1 then 2 else 1,
		ClearanceRadius = radius,
		FishScaleMultiplier = 2,
		FishSpeedMultiplier = 2,
	}
	for name, value in attributes do
		group:SetAttribute(name, value)
	end
	if count == 1 then
		group:SetAttribute("Encounter", "Manta")
		group:SetAttribute("EncounterPeriod", 78)
		group:SetAttribute("EncounterDuration", 30)
	end
	local offsets = { Vector3.new(-6, 0, -3.5), Vector3.new(6, 0, -3.5), Vector3.new(0, 0, 7) }
	for i = 1, count do
		local animal = template:Clone()
		animal.Name = template.Name .. string.format("%02d", i)
		animal:ScaleTo(scale)
		local offset = if count == 1 then Vector3.zero else offsets[i]
		animal:SetAttribute("MemberIndex", i)
		animal:SetAttribute("MemberOffset", offset)
		animal:SetAttribute("PoseSeed", seed + i * 1.79)
		animal:PivotTo(cf.Rotation + cf:PointToWorldSpace(Swim.route(0, rx, rz, 1, seed) + offset))
		animal.Parent = group
	end
	table.insert(reservations, { origin = cf, rx = rx, rz = rz, radius = radius })
	return group
end

function Author.apply(world: any)
	assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning())
	local templates = game.ReplicatedStorage:FindFirstChild("OceanAmbientTemplates")
	assert(templates, "Create OceanAmbientTemplates with VfxForgeUltra first")
	local pack = game.ServerStorage.Assets.OceanDepths.AnimatedSeaLife
	local stage = Instance.new("Model")
	stage.Name = "AtmosphereStaging"
	local staged = {}
	local report = { foreground = 0, mantas = 0, patches = 0, plankton = 0, bubbles = 0, reefs = 0, failures = {} }
	local oldRoots = {}
	for _, n in world:GetDescendants() do
		if n:GetAttribute("OceanAtmosphereRoot") then
			table.insert(oldRoots, n)
		end
	end
	-- Prior authored atmosphere is excluded from navigation while a replacement is staged.
	local oldParents = {}
	for _, n in oldRoots do
		oldParents[n] = n.Parent
		n.Parent = nil
	end
	local ok, err = pcall(function()
		local obstacles = Navigation.obstacles(world)
		local reservations: { Reservation } = {}
		for _, r in world:GetDescendants() do
			if r:IsA("Model") and r:GetAttribute("WildlifeRoute") then
				local index = r:GetAttribute("AnchorIndex")
				local f = if index == 0 then Refs.kickZoneFloor(world) else Refs.field(world, index)
				table.insert(reservations, {
					origin = f.CFrame * (r:GetAttribute("RouteOrigin") :: CFrame),
					rx = r:GetAttribute("RouteX") :: number,
					rz = r:GetAttribute("RouteZ") :: number,
					radius = r:GetAttribute("ClearanceRadius") :: number,
				})
			end
		end
		local zones = { world.Lobby }
		for i = 1, 8 do
			table.insert(zones, world.FootballCourse.Zones[string.format("Zone%02d", i)])
		end
		for index, zone in zones do
			local field = if index == 1 then Refs.kickZoneFloor(world) else Refs.field(world, index - 1)
			local root = model(stage, "OceanAtmosphere")
			root:SetAttribute("OceanAtmosphereRoot", true)
			root:SetAttribute("ZoneIndex", math.max(index - 1, 1))
			table.insert(staged, { root = root, parent = zone.Environment })
			local surfaces = {}
			for _, p in zone:GetDescendants() do
				if
					p:IsA("Part")
					and p.Transparency < 0.1
					and p.Size.X >= 6
					and p.Size.Z >= 6
					and p.Size.Y >= 0.08
					and p.CFrame.UpVector.Y > 0.999
					and p.Position.Y < field.Position.Y + 85
					and p.Position.Y > field.Position.Y - 2
				then
					table.insert(surfaces, p)
				end
			end
			table.sort(surfaces, function(a, b)
				return a:GetFullName() < b:GetFullName()
			end)
			for n = 1, #surfaces, math.max(1, math.ceil(#surfaces / 32)) do
				local p = surfaces[n]
				local patch = templates.CausticSurface:Clone()
				patch.Name = "CausticPatch"
				patch.Size = Vector3.new(math.min(p.Size.X - 0.24, 24), 0.02, math.min(p.Size.Z - 0.24, 32))
				patch.CFrame = p.CFrame * CFrame.new(0, p.Size.Y / 2 + 0.035, 0)
				patch:SetAttribute("SurfaceHeight", p.Position.Y + p.Size.Y / 2)
				local receiver = Instance.new("ObjectValue")
				receiver.Name = "Receiver"
				receiver.Value = p
				receiver.Parent = patch
				patch.Parent = root
				report.patches += 1
			end
			local horizon = model(root, "DistantReef")
			for _, side in { -1, 1 } do
				local bed = part(
					horizon,
					"SeabedExtension",
					field.CFrame * CFrame.new(side * 246, -15, 0),
					Vector3.new(240, 12, 324),
					C("155675")
				)
				for n = 1, 9 do
					local height = 19.2 + ((n * 7 + index * 3 + (if side == 1 then 3 else 0)) % 6) * 9.6
					local reef = part(
						horizon,
						"ReefColumn",
						field.CFrame * CFrame.new(side * (270 + (n % 3) * 14.4), -9 + height / 2, (n - 5) * 34.8),
						Vector3.new(28.8, height, 34.8),
						C(if index < 6 then "176887" else "153F60")
					)
					HDStuds.apply(reef, 4.8)
					report.reefs += 1
				end
				bed:SetAttribute("PartRole", "Distant seabed foundation")
			end
			-- Open-water pockets are swept-volume certified; particles cannot drift into scenery.
			for _, side in { -1, 1 } do
				local found
				for _, height in { 16, 24, 32, 44, 56 } do
					local cf = field.CFrame * CFrame.new(side * 24, height, side * 55)
					if Navigation.clear(cf, 8, 10, 7, obstacles) then
						found = cf
						break
					end
				end
				assert(found, "No clear particle pocket in " .. zone.Name)
				local pocket = templates.Plankton:Clone()
				pocket.CFrame = found
				pocket.Parent = root
				pocket:SetAttribute("ClearanceRadius", 7)
				report.plankton += 1
			end
			-- Small bubble streams originate at a visible sand/rock surface and expire in clear water.
			local count = 0
			for _, p in surfaces do
				if count >= 2 then
					break
				end
				local cf = p.CFrame * CFrame.new(0, p.Size.Y / 2 + 0.08, 0)
				local clear = math.abs(cf.Position.X - field.Position.X) > 36
				for _, o in obstacles do
					if not clear then
						break
					end
					if o.cf.UpVector.Y > 0.999 and o.cf.Position.Y + o.half.Y <= cf.Position.Y + 0.45 then
						continue
					end
					if
						not Swim.clearBox(
							o.cf:PointToObjectSpace(cf.Position + Vector3.yAxis * 0.3),
							o.cf:PointToObjectSpace(cf.Position + Vector3.yAxis * 12.6),
							o.half,
							2
						)
					then
						clear = false
					end
				end
				if clear then
					local bubble = templates.Bubbles:Clone()
					bubble.CFrame = cf
					bubble.Parent = root
					count += 1
					report.bubbles += 1
				end
			end
			local audio = part(root, "LocalSoundOrigin", field.CFrame * CFrame.new(45, 15, 0), Vector3.one, C("FFFFFF"))
			audio.Transparency = 1
			audio:SetAttribute("PartRole", "Spatial ambience source")
			if index == 2 then
				local template = pack.MantaRay
				local radius = template:GetAttribute("NavigationRadius") * 0.56 + 1.8
				local selected
				for _, height in { 52, 60, 68, 76, 84, 92, 100, 108, 116 } do
					for _, z in { 3, 20, -20, 42, -42 } do
						local cf = field.CFrame * CFrame.new(0, height, z)
						if
							cf.Position.Y + radius < 144
							and reserveClear(cf, 52, 3, radius, reservations)
							and Navigation.clear(cf, 52, 3, radius, obstacles)
						then
							selected = cf
							break
						end
					end
					if selected then
						break
					end
				end
				assert(selected, "No certified manta crossing")
				route(root, field, template, selected, 52, 3, 1, 0.56, 2201, reservations)
				report.mantas += 1
			end
			if index > 1 then
				for _, side in { -1, 1 } do
					local species = ({
						"YellowTang",
						"Butterflyfish",
						"BlueTang",
						"YellowTang",
						"BlueTang",
						"SilverSprat",
						"BlueTang",
						"Butterflyfish",
					})[index - 1]
					local template = pack[species]
					local scale = if species == "SilverSprat" then 0.88 else 1.08
					local radius = template:GetAttribute("NavigationRadius") * scale + 8 + 1.8
					local selected
					for _, x in { 44, 32, 24, 16, 62, 78, 96 } do
						for _, height in { 18, 22, 26, 30, 34, 38, 46, 54 } do
							for _, z in
								{ side * 82, side * 32, side * 122, -side * 35, -side * 100, 0, 150, -150, 55, -55 }
							do
								local cf = field.CFrame * CFrame.new(side * x, height, z)
								if
									reserveClear(cf, 3, 12, radius, reservations)
									and Navigation.clear(cf, 3, 12, radius, obstacles)
								then
									selected = cf
									break
								end
							end
							if selected then
								break
							end
						end
						task.wait()
						if selected then
							break
						end
					end
					assert(selected, "No clear foreground lane in " .. zone.Name .. " side " .. side)
					route(root, field, template, selected, 3, 12, 3, scale, 3000 + index * 17 + side, reservations)
					report.foreground += 3
				end
			end
			task.wait()
		end
	end)
	for n, parent in oldParents do
		n.Parent = parent
	end
	if not ok then
		stage:Destroy()
		error(err)
	end
	for _, n in oldRoots do
		n:Destroy()
	end
	for _, entry in staged do
		entry.root.Parent = entry.parent
		task.wait()
	end
	stage:Destroy()
	if not world.FootballCourse:FindFirstChild("Environment") then
		local environment = Instance.new("Folder")
		environment.Name = "Environment"
		environment.Parent = world.FootballCourse
	end
	world:SetAttribute("OceanAtmosphereVersion", 1)
	Author.removeOldBackground(world)
	return report
end

return Author
