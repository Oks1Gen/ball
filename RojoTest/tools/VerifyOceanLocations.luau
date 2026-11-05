-- Read-only, independent geometry checks for the authored Ocean Depths course.
return function(world: Model, Ground: any)
	local HDStuds = require(game.ServerScriptService.Server.HDStuds)
	local failures = {}
	local function check(ok, message)
		if not ok then
			table.insert(failures, message)
		end
	end
	local report = { zones = 0, grounded = 0, tiers = 0, studded = 0, walkSamples = 0, failures = failures }
	local shore = {
		SandBank = true,
		SandShoulder = true,
		SandShelf = true,
		Seabed = true,
		TurquoiseCoping = true,
		BlueLimestone = true,
		StoneTier = true,
		ReefColumn = true,
	}
	local ship = {
		HullPlank = true,
		CabinSill = true,
		CabinLintel = true,
		BrokenMast = true,
		Spar = true,
		DeckRib = true,
		ProwScroll = true,
		TornCreamSail = true,
	}
	local prior
	for i = 1, 8 do
		local zone = world.FootballCourse.Zones:FindFirstChild(("Zone%02d"):format(i))
		check(zone ~= nil, "Missing zone " .. i)
		if not zone then
			continue
		end
		report.zones += 1
		local f = zone.Field
		if prior then
			check(
				(f.Position - prior.Position - Vector3.new(0, 0, -prior.Size.Z)).Magnitude < 0.01,
				"Course join " .. i
			)
		end
		check(f.CanCollide, "Pitch collision " .. i)
		prior = f
		for _, node in zone:GetDescendants() do
			if node:IsA("BasePart") then
				local isShip = ship[node.Name] and node.Parent:IsA("Model") and node.Parent.Name == "SandfilledGalleon"
				local hasStuds = node.MaterialVariant:match("^HDStuds_")
				if
					node.Transparency == 0
					and (shore[node.Name] or isShip or node.Name == "Turf" or node.Name == "Line")
				then
					local tile = if isShip and node.Parent:GetScale() == 1.5 then 3.6 else 4.8
					local variant = HDStuds.variant(node.Material, tile)
					check(
						variant and variant.Name == node.MaterialVariant,
						"Missing or mis-scaled HD Studs: " .. node:GetFullName()
					)
				end
				if hasStuds then
					report.studded += 1
				end
			elseif node:IsA("Texture") and node.Texture == HDStuds.LegacyImage and node.Transparency < 1 then
				local host = node.Parent
				check(
					host.Transparency == 1 or host.Material == Enum.Material.Neon,
					"Visible old studs: " .. host:GetFullName()
				)
			end
		end
		if i == 1 then
			continue
		end
		local surfaces = Ground.collect(zone, {
			SandBank = true,
			StoneTier = true,
			Seabed = true,
			FinaleBedrock = true,
			BasaltRidge = true,
			ToweringStrata = true,
		})
		local function support(cf, footprint, label)
			local sameLevel = {}
			for _, surface in surfaces do
				if math.abs(surface.top - cf.Position.Y) < 0.13 then
					table.insert(sameLevel, surface)
				end
			end
			local ok, result = pcall(Ground.fit, sameLevel, cf, footprint, 0.13)
			check(ok, label .. ": " .. tostring(result))
		end
		for _, node in zone:GetDescendants() do
			if node:IsA("Model") and node:GetAttribute("PlacementRole") == "Grounded" then
				report.grounded += 1
				support(node:GetPivot(), node:GetAttribute("SupportFootprint"), node:GetFullName())
			elseif node:IsA("BasePart") then
				if node.Name == "StoneTier" then
					report.tiers += 1
					local cf = node.CFrame * CFrame.new(0, -node.Size.Y / 2, 0)
					support(cf, Vector2.new(node.Size.X, node.Size.Z), node:GetFullName())
				end
				if node.Transparency >= 1 then
					check(node:GetAttribute("PartRole") ~= nil, "Unlabelled invisible " .. node:GetFullName())
				end
				if node.Transparency < 0.95 and node:IsDescendantOf(zone.Environment) then
					local min, max = Vector3.one * math.huge, -Vector3.one * math.huge
					local size = node.Size
					local mesh = node:FindFirstChildWhichIsA("SpecialMesh")
					if mesh then
						size = Vector3.new(size.X * mesh.Scale.X, size.Y * mesh.Scale.Y, size.Z * mesh.Scale.Z)
					end
					for _, x in { -1, 1 } do
						for _, y in { -1, 1 } do
							for _, z in { -1, 1 } do
								local p = f.CFrame:PointToObjectSpace(
									node.CFrame:PointToWorldSpace(size * Vector3.new(x, y, z) / 2)
								)
								min = Vector3.new(math.min(min.X, p.X), math.min(min.Y, p.Y), math.min(min.Z, p.Z))
								max = Vector3.new(math.max(max.X, p.X), math.max(max.Y, p.Y), math.max(max.Z, p.Z))
							end
						end
					end
					local overlap = min.X < f.Size.X / 2 - 0.02
						and max.X > -f.Size.X / 2 + 0.02
						and min.Z < f.Size.Z / 2 - 0.02
						and max.Z > -f.Size.Z / 2 + 0.02
						and max.Y > 0.25
						and min.Y < 85
					check(not overlap, "Flight corridor: " .. node:GetFullName())
				end
			end
		end
		local ray = RaycastParams.new()
		ray.FilterType = Enum.RaycastFilterType.Include
		ray.FilterDescendantsInstances = { f }
		for _, x in { -30, 0, 30 } do
			for s = 0, 10 do
				local p = f.Position + Vector3.new(x, 12, f.Size.Z * (s / 10 - 0.5) * 0.999)
				local hit = workspace:Raycast(p, Vector3.new(0, -20, 0), ray)
				report.walkSamples += 1
				check(hit ~= nil, "Walkable field " .. i .. "/" .. x .. "/" .. s)
			end
		end
	end
	for _, root in world:GetChildren() do
		check(
			root.Name == "Lobby" or root.Name == "FootballCourse" or root.Name == "TrainingArea",
			"Extra world root " .. root.Name
		)
	end
	report.passed = #failures == 0
	return report
end
