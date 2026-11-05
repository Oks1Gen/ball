-- Edit-only, targeted wildlife migration. Does not run landscape builders.
local Swim = require(game.ReplicatedStorage.Shared.Core.OceanSwimming)
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Author = {}
local FISH_SCALE = 2
local FISH_SPEED = 2
type Obstacle = { cf: CFrame, half: Vector3, extent: Vector3, name: string }
type Reservation = { origin: CFrame, rx: number, rz: number, radius: number }

local function isAnimal(n: Instance): boolean
	return n:IsA("Model")
		and (
			n.Name == "FishSchool"
			or n.Name == "MantaRay"
			or n:GetAttribute("WildlifeRoute") == true
			or n:GetAttribute("OceanMotion") == "Jellyfish"
			or n:GetAttribute("OceanMotion") == "Seahorse"
			or n:GetAttribute("OceanMotion") == "Anglerfish"
			or n:GetAttribute("OceanMotion") == "Squid"
		)
end

function Author.obstacles(world: Model): { Obstacle }
	local out: { Obstacle } = {}
	for _, n in world:GetDescendants() do
		if not n:IsA("BasePart") or n.Transparency >= 0.99 then
			continue
		end
		local skip, padding = false, 0.4
		local p = n.Parent
		while p and p ~= world do
			if isAnimal(p) then
				skip = true
				break
			end
			if p:GetAttribute("OceanMotion") == "Kelp" then
				padding = 2
			end
			if p:GetAttribute("OceanMotion") == "ShellValve" then
				padding = 18
			end
			p = p.Parent
		end
		if skip then
			continue
		end
		local size = n.Size
		local mesh = n:FindFirstChildWhichIsA("SpecialMesh")
		if mesh then
			size *= mesh.Scale
		end
		local half = size / 2 + Vector3.one * padding
		local r, u, b = n.CFrame.RightVector, n.CFrame.UpVector, n.CFrame.LookVector
		local extent = Vector3.new(
			math.abs(r.X) * half.X + math.abs(u.X) * half.Y + math.abs(b.X) * half.Z,
			math.abs(r.Y) * half.X + math.abs(u.Y) * half.Y + math.abs(b.Y) * half.Z,
			math.abs(r.Z) * half.X + math.abs(u.Z) * half.Y + math.abs(b.Z) * half.Z
		)
		table.insert(out, { cf = n.CFrame, half = half, extent = extent, name = n:GetFullName() })
	end
	return out
end

function Author.clear(
	origin: CFrame,
	rx: number,
	rz: number,
	radius: number,
	obstacles: { Obstacle }
): (boolean, string?)
	local nearby = {}
	for _, o in obstacles do
		local d = origin.Position - o.cf.Position
		if
			math.abs(d.X) <= o.extent.X + rx + radius + 2
			and math.abs(d.Y) <= o.extent.Y + radius + 2
			and math.abs(d.Z) <= o.extent.Z + rz + radius + 2
		then
			table.insert(nearby, o)
		end
	end
	-- Every curve interval is covered by its chord plus a conservative curvature margin.
	local last = origin:PointToWorldSpace(Swim.route(0, rx, rz, 1, 0))
	for step = 1, 96 do
		local t = step / 96 * math.pi * 2 * math.max(rx, rz, 1)
		local point = origin:PointToWorldSpace(Swim.route(t, rx, rz, 1, 0))
		for _, o in nearby do
			if (o.cf.Position - point).Magnitude > o.half.Magnitude + radius + 12 then
				continue
			end
			if
				not Swim.clearBox(o.cf:PointToObjectSpace(last), o.cf:PointToObjectSpace(point), o.half, radius + 0.25)
			then
				return false, o.name
			end
		end
		last = point
	end
	return true, nil
end

local function safeOrigin(
	base: CFrame,
	rx: number,
	rz: number,
	radius: number,
	obstacles: { Obstacle },
	reservations: { Reservation }
): CFrame
	local reason = "no candidate below the water surface"
	local offsets = { Vector3.zero }
	-- Larger schools may need a neighbouring lane instead of being pushed above the water.
	for _, distance in { 16, 32, 48, 64, 80, 96 } do
		for _, side in { 1, -1 } do
			table.insert(offsets, Vector3.new(0, 0, distance * side))
			table.insert(offsets, Vector3.new(distance * side, 0, 0))
		end
	end
	for _, offset in offsets do
		for raise = 0, 108, 4 do
			local candidate = base + offset + Vector3.new(0, raise, 0)
			if candidate.Position.Y + radius > 144 then
				break
			end
			local ok = true
			local why: string? = nil
			for _, r in reservations do
				local delta = candidate.Position - r.origin.Position
				if
					math.abs(delta.X) < rx + r.rx + radius + r.radius
					and math.abs(delta.Z) < rz + r.rz + radius + r.radius
					and math.abs(delta.Y) < radius + r.radius + 3
				then
					ok, why = false, "other wildlife route"
					break
				end
			end
			if ok then
				ok, why = Author.clear(candidate, rx, rz, radius, obstacles)
			end
			if ok then
				return candidate
			end
			reason = why or reason
			task.wait()
		end
	end
	error("No safe wildlife route at " .. tostring(base.Position) .. ": " .. reason)
end

-- Targeted, idempotent migration. Plan/certify everything before changing the scene.
function Author.enlargeFish(world: Model): any
	assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning())
	local obstacles = Author.obstacles(world)
	local reservations: { Reservation } = {}
	local routes: { Model } = {}
	local plans = {}
	for _, route in world:GetDescendants() do
		if not route:IsA("Model") or not route:GetAttribute("WildlifeRoute") then
			continue
		end
		local child = route:FindFirstChildWhichIsA("Model")
		if child and child:GetAttribute("WildlifeKind") == "Fish" and not route:GetAttribute("AmbientAuthored") then
			table.insert(routes, route)
		else
			local index = route:GetAttribute("AnchorIndex") :: number
			local anchor = if index == 0 then Refs.kickZoneFloor(world) else Refs.field(world, index)
			table.insert(reservations, {
				origin = anchor.CFrame * (route:GetAttribute("RouteOrigin") :: CFrame),
				rx = route:GetAttribute("RouteX") :: number,
				rz = route:GetAttribute("RouteZ") :: number,
				radius = route:GetAttribute("ClearanceRadius") :: number,
			})
		end
	end
	table.sort(routes, function(a, b)
		return a:GetFullName() < b:GetFullName()
	end)
	for _, route in routes do
		local index = route:GetAttribute("AnchorIndex") :: number
		local anchor = if index == 0 then Refs.kickZoneFloor(world) else Refs.field(world, index)
		local previousScale = (route:GetAttribute("FishScaleMultiplier") :: number?) or 1
		local previousSpeed = (route:GetAttribute("FishSpeedMultiplier") :: number?) or 1
		local factor = FISH_SCALE / previousScale
		local memberLimit = (route:GetAttribute("MemberLimit") :: number) * factor
		local animalRadius = 0
		for _, animal in route:GetChildren() do
			if animal:IsA("Model") and animal:GetAttribute("MemberIndex") then
				animalRadius = math.max(
					animalRadius,
					(animal:GetAttribute("NavigationRadius") :: number) * animal:GetScale() * factor
				)
			end
		end
		local radius = animalRadius + memberLimit + 1.8
		local rx, rz = route:GetAttribute("RouteX") :: number, route:GetAttribute("RouteZ") :: number
		local origin = safeOrigin(
			anchor.CFrame * (route:GetAttribute("RouteOrigin") :: CFrame),
			rx,
			rz,
			radius,
			obstacles,
			reservations
		)
		table.insert(reservations, { origin = origin, rx = rx, rz = rz, radius = radius })
		table.insert(plans, {
			route = route,
			anchor = anchor,
			origin = origin,
			factor = factor,
			memberLimit = memberLimit,
			radius = radius,
			speed = (route:GetAttribute("RouteSpeed") :: number) / previousSpeed * FISH_SPEED,
		})
		task.wait()
	end
	local count = 0
	for _, plan in plans do
		local route = plan.route
		route:SetAttribute("RouteOrigin", plan.anchor.CFrame:ToObjectSpace(plan.origin))
		route:SetAttribute("RouteSpeed", plan.speed)
		route:SetAttribute("ClearanceRadius", plan.radius)
		route:SetAttribute("MemberLimit", plan.memberLimit)
		route:SetAttribute("MemberMotionScale", FISH_SCALE)
		route:SetAttribute("MotionRate", FISH_SPEED)
		route:SetAttribute("FishScaleMultiplier", FISH_SCALE)
		route:SetAttribute("FishSpeedMultiplier", FISH_SPEED)
		for _, animal in route:GetChildren() do
			if not animal:IsA("Model") or not animal:GetAttribute("MemberIndex") then
				continue
			end
			animal:ScaleTo(animal:GetScale() * plan.factor)
			local offset = (animal:GetAttribute("MemberOffset") :: Vector3) * plan.factor
			animal:SetAttribute("MemberOffset", offset)
			local center = Swim.route(
				0,
				route:GetAttribute("RouteX") :: number,
				route:GetAttribute("RouteZ") :: number,
				1,
				route:GetAttribute("RouteSeed") :: number
			)
			animal:PivotTo(plan.origin.Rotation + plan.origin:PointToWorldSpace(center + offset))
			count += 1
		end
		task.wait()
	end
	world:SetAttribute("FishScaleMultiplier", FISH_SCALE)
	world:SetAttribute("FishSpeedMultiplier", FISH_SPEED)
	return { fish = count, routes = #plans, sizeMultiplier = FISH_SCALE, speedMultiplier = FISH_SPEED }
end

function Author.apply(world: any): any
	assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning())
	local pack = game.ServerStorage.Assets.OceanDepths.AnimatedSeaLife
	local archive = game.ServerStorage.Assets.OceanDepths:FindFirstChild("LegacyWildlife") or Instance.new("Folder")
	archive.Name = "LegacyWildlife"
	archive.Parent = pack.Parent
	local obstacles = Author.obstacles(world)
	local reservations: { Reservation } = {}
	local report: any =
		{ schools = 0, fish = 0, individuals = 0, routes = 0, obstacles = #obstacles, animals = {}, failures = {} }
	local staged: { { parent: Instance, model: Model } } = {}
	local function route(
		parent: Instance,
		anchor: BasePart,
		species: string,
		localCenter: Vector3,
		rx: number,
		rz: number,
		count: number,
		scale: number,
		seed: number
	): Model
		local m = Instance.new("Model")
		m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		m.Name = if count > 1 then species .. "School" else species
		local template = pack[species]
		local animalRadius = template:GetAttribute("NavigationRadius") * scale
		local spacing = math.max(6, animalRadius * 2 + 0.6)
		local memberLimit = if count > 1 then math.max(8.8, math.sqrt(2) * spacing + 0.1) else 0
		local radius = animalRadius + memberLimit + 1.8
		local origin: CFrame?, reason: string?
		for raise = 0, 108, 4 do
			local candidate = anchor.CFrame * CFrame.new(localCenter + Vector3.new(0, raise, 0))
			if candidate.Position.Y + radius > 144 then
				break
			end
			local ok, why = Author.clear(candidate, rx, rz, radius, obstacles)
			if ok then
				for _, r in reservations do
					local a, b = candidate.Position, r.origin.Position
					local hx = rx + r.rx + radius + r.radius
					local hz = rz + r.rz + radius + r.radius
					if
						math.abs(a.X - b.X) < hx
						and math.abs(a.Z - b.Z) < hz
						and math.abs(a.Y - b.Y) < radius + r.radius + 3
					then
						ok = false
						why = "other wildlife route"
						break
					end
				end
			end
			if ok then
				origin = candidate
				break
			end
			reason = why
		end
		assert(origin, species .. " has no safe route: " .. tostring(reason))
		m.WorldPivot = origin
		m:SetAttribute("WildlifeRoute", true)
		m:SetAttribute("RouteOrigin", anchor.CFrame:ToObjectSpace(origin))
		m:SetAttribute("RouteX", rx)
		m:SetAttribute("RouteZ", rz)
		m:SetAttribute("RouteSeed", seed)
		m:SetAttribute("RouteSpeed", if count > 1 then 6 + seed % 3 else if species == "MantaRay" then 7 else 1.2)
		m:SetAttribute("ClearanceRadius", radius)
		m:SetAttribute("MemberLimit", memberLimit)
		m:SetAttribute("AnchorIndex", anchor:GetAttribute("WildlifeAnchorIndex") or 0)
		for i = 1, count do
			local animal = template:Clone()
			animal.Name = species .. string.format("%02d", i)
			animal:ScaleTo(scale * (if count > 1 then 0.84 + (i % 4) * 0.05 else 1))
			animal:SetAttribute("MemberIndex", i)
			animal:SetAttribute("PoseSeed", seed + i * 1.79)
			-- Non-overlapping initial grid; simulation then continuously reshuffles it.
			local offset = if count > 1
				then Vector3.new(((i - 1) % 3 - 1) * spacing, ((i - 1) // 9) * 7, (((i - 1) // 3) % 3 - 1) * spacing)
				else Vector3.zero
			animal:SetAttribute("MemberOffset", offset)
			local position = origin:PointToWorldSpace(Swim.route(0, rx, rz, 1, seed) + offset)
			animal:PivotTo(CFrame.new(position))
			animal.Parent = m
			if species == "Anglerfish" or template:GetAttribute("WildlifeKind") == "Jelly" then
				local light = Instance.new("PointLight")
				light.Color = if species == "Anglerfish" or species == "MoonJellyfish"
					then Color3.fromHex("B1F4DF")
					else Color3.fromHex("EEA5E4")
				light.Range = if species == "Anglerfish" then 8 else 10
				light.Brightness = 0.25
				light.Shadows = false
				light.Parent = animal.PrimaryPart
			end
		end
		table.insert(reservations, { origin = origin, rx = rx, rz = rz, radius = radius })
		table.insert(staged, { parent = parent, model = m })
		report.routes += 1
		if count > 1 then
			report.schools += 1
			report.fish += count
		else
			report.individuals += 1
		end
		table.insert(report.animals, { species = species, count = count, height = origin.Position.Y, radius = radius })
		return m
	end
	local lobbyAnchor = Refs.kickZoneFloor(world)
	lobbyAnchor:SetAttribute("WildlifeAnchorIndex", 0)
	local lobby = world.Lobby:FindFirstChild("Environment") or world.Lobby
	for i = 1, 4 do
		route(
			lobby,
			lobbyAnchor,
			({ "YellowTang", "Clownfish", "BlueTang", "Butterflyfish" })[i],
			Vector3.new(if i % 2 == 0 then 92 else -92, 62, (i // 3) * 92 + 40),
			12,
			25,
			9,
			0.62,
			100 + i
		)
	end
	for index = 1, 8 do
		local f = Refs.field(world, index)
		f:SetAttribute("WildlifeAnchorIndex", index)
		local zone = f.Parent
		local parent = zone.Environment
		local count = if index >= 5 and index <= 7 then 2 else 4
		local species = ({
			"YellowTang",
			"Butterflyfish",
			"BlueTang",
			"SilverSprat",
			"BlueTang",
			"SilverSprat",
			"BlueTang",
			"Butterflyfish",
		})[index]
		for i = 1, count do
			local side = if i % 2 == 0 then 1 else -1
			local memberSpecies = if index == 1
				then ({ "YellowTang", "BlueTang", "Clownfish", "YellowTang" })[i]
				else if index == 3 and i % 2 == 0 then "SilverSprat" else species
			local s = if count == 2 then 150 + side * 30 else if i <= 2 then 76 + side * 12 else 242 - side * 12
			route(
				parent,
				f,
				memberSpecies,
				Vector3.new(
					side
						* (
							if index == 8
									or index == 7
									or index == 6
									or index == 2
								then 56
								else if index == 3 then 60 else if index == 5 then 165 else 88
						),
					if index == 8 then 32 else 42,
					f.Size.Z / 2 - s
				),
				if index == 8 or index == 7 or index == 6 or index == 2 or index == 3 then 5 else 13,
				27,
				if index == 7 then 5 else 9,
				if species == "SilverSprat" then 0.52 else 0.64,
				index * 20 + i
			)
		end
		if index == 1 or index == 4 then
			route(
				parent,
				f,
				"MantaRay",
				Vector3.new(if index == 1 then -184 else 184, 80, -20),
				18,
				46,
				1,
				0.78,
				index * 29
			)
		end
		if index == 2 then
			for i = 1, 6 do
				route(
					parent,
					f,
					"GoldenSeahorse",
					Vector3.new((if i % 2 == 0 then 1 else -1) * 55, 33, 140 - i * 43),
					1.2,
					2.5,
					1,
					0.65,
					index * 70 + i
				)
			end
		elseif index == 5 then
			for i = 1, 12 do
				route(
					parent,
					f,
					if i % 3 == 0 then "MoonJellyfish" else "ReefJellyfish",
					Vector3.new((if i % 2 == 0 then 1 else -1) * 83, 35 + (i % 3) * 4, 142 - ((i - 1) // 2) * 53),
					2.5,
					3.6,
					1,
					0.7 + i % 3 * 0.15,
					index * 70 + i
				)
			end
		elseif index == 7 then
			for i = 1, 6 do
				route(
					parent,
					f,
					"Anglerfish",
					Vector3.new((if i % 2 == 0 then 1 else -1) * 62, 33, 120 - ((i - 1) // 2) * 105),
					2,
					4,
					1,
					0.8,
					index * 70 + i
				)
			end
			route(parent, f, "AbyssSquid", Vector3.new(78, 72, -58), 3, 9, 1, 1.5, 710)
		end
		task.wait()
	end
	route(lobby, lobbyAnchor, "MantaRay", Vector3.new(-174, 82, 88), 15, 38, 1, 0.8, 19)
	-- Only replace after all routes have a certificate. Preserve originals outside Workspace.
	local old = {}
	for _, n in world:GetDescendants() do
		if isAnimal(n) and not n:GetAttribute("WildlifeRoute") then
			local p = n.Parent
			local nested = false
			while p and p ~= world do
				if isAnimal(p) then
					nested = true
					break
				end
				p = p.Parent
			end
			if not nested then
				table.insert(old, n)
			end
		end
	end
	local previous = {}
	for _, n in world:GetDescendants() do
		if n:IsA("Model") and n:GetAttribute("WildlifeRoute") then
			table.insert(previous, n)
		end
	end
	for _, n in previous do
		n:Destroy()
	end
	for _, n in old do
		n:SetAttribute("OriginalScenePath", n:GetFullName())
		n.Parent = archive
	end
	for _, entry in staged do
		entry.model.Parent = entry.parent
	end
	world:SetAttribute("AnimatedWildlifeVersion", 1)
	Author.enlargeFish(world)
	return report
end

return Author
