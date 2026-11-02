--!strict
-- Read-only course proof plus a persistent pre-edit fingerprint for excluded areas.
local Verify = {}
local V = Vector3.new

local function signature(root: Instance): (number, number)
	local rows = {}
	for _, node in root:GetDescendants() do
		local path = node:GetFullName():sub(#root:GetFullName() + 2)
		if node:IsA("BasePart") then
			local numbers = { node.CFrame:GetComponents() }
			for _, n in
				{ node.Size.X, node.Size.Y, node.Size.Z, node.Color.R, node.Color.G, node.Color.B, node.Transparency }
			do
				table.insert(numbers, n)
			end
			local values = {}
			for _, n in numbers do
				table.insert(values, string.format("%.4f", if math.abs(n) < 0.00005 then 0 else n))
			end
			table.insert(
				rows,
				path
					.. table.concat(values, ",")
					.. tostring(node.CanCollide)
					.. tostring(node.CanTouch)
					.. tostring(node.CanQuery)
					.. node.Material.Name
			)
		elseif node:IsA("TextLabel") then
			table.insert(rows, path .. node.Text)
		elseif node:IsA("Texture") or node:IsA("Decal") then
			table.insert(rows, path .. node.Texture .. tostring(node.Transparency))
		end
	end
	table.sort(rows)
	local hash = 0
	for _, row in rows do
		for i = 1, #row do
			hash = (hash * 31 + string.byte(row, i)) % 2147483647
		end
	end
	return hash, #rows
end

function Verify.capture()
	local world = workspace.Map.World1
	local baseline = Instance.new("Folder")
	baseline.Name = "FootballCityVerification"
	for _, area in { world.Lobby, world.TrainingArea } do
		local hash, count = signature(area)
		baseline:SetAttribute(area.Name .. "Hash", hash)
		baseline:SetAttribute(area.Name .. "Count", count)
	end
	local config = require(game.ReplicatedStorage.Shared.GameConfig)
	baseline:SetAttribute("ShotLimit", config.shotLimit(1, world))
	for index = 1, 8 do
		local f = world.FootballCourse.Zones[string.format("Zone%02d", index)].Field
		baseline:SetAttribute("FieldFrame" .. index, f.CFrame)
		baseline:SetAttribute("FieldSize" .. index, f.Size)
	end
	baseline.Parent = game.ServerStorage
	return baseline:GetAttributes()
end

function Verify.areaSignatures(): any
	local world = workspace.Map.World1
	local result = {}
	for _, area in { world.Lobby, world.TrainingArea } do
		local hash, count = signature(area)
		result[area.Name] = { hash = hash, count = count }
	end
	return result
end

-- Compare exclusions in Edit; Play also compares areaSignatures around apply,
-- since the existing startup rebuilds labels and simulates loose parts.
function Verify.run(checkExcluded: boolean?): any
	local world = workspace.Map.World1
	local course = world.FootballCourse
	local shared = game.ReplicatedStorage.Shared
	local themes = require(shared.FootballCity)
	local config = require(shared.GameConfig)
	local baseline = assert(game.ServerStorage:FindFirstChild("FootballCityVerification"), "Capture before editing")
	local areaResults = {}
	for _, area in { world.Lobby, world.TrainingArea } do
		local hash, count = signature(area)
		if checkExcluded ~= false then
			assert(
				hash == baseline:GetAttribute(area.Name .. "Hash")
					and count == baseline:GetAttribute(area.Name .. "Count"),
				area.Name .. " changed"
			)
		end
		areaResults[area.Name] = count
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { course }
	params.RespectCanCollide = true
	local parts, rays = 0, 0
	for i, theme in themes do
		local zone = course.Zones[string.format("Zone%02d", i)]
		local f = zone.Field
		assert(
			f.CFrame == baseline:GetAttribute("FieldFrame" .. i) and f.Size == baseline:GetAttribute("FieldSize" .. i),
			"Field geometry changed"
		)
		assert(f.CanCollide and f.Color == theme.pitch and zone:GetAttribute("BiomeName") == theme.name, "Wrong pitch")
		local city = assert(zone.Environment:FindFirstChild("Cityscape"))
		assert(#zone.Environment:GetChildren() == 1, "Retired biome still active")
		assert(city:GetAttribute("Theme") == theme.name, "Wrong city identity")
		local low, high = f.Position.Z - f.Size.Z / 2, f.Position.Z + f.Size.Z / 2
		for _, p in city:GetDescendants() do
			if p:IsA("BasePart") then
				assert(
					not p.CanCollide and not p.CanTouch and not p.CanQuery and p.Anchored,
					"Cosmetic changes gameplay"
				)
				local half = (
					math.abs(p.CFrame.RightVector.Z) * p.Size.X
					+ math.abs(p.CFrame.UpVector.Z) * p.Size.Y
					+ math.abs(p.CFrame.LookVector.Z) * p.Size.Z
				) / 2
				assert(
					p.Position.Z - half >= low - 0.01 and p.Position.Z + half <= high + 0.01,
					"Prop crosses zone: " .. p:GetFullName()
				)
				parts += 1
			end
		end
		for _, x in { -0.45, 0, 0.45 } do
			for _, z in { -0.45, -0.2, 0, 0.2, 0.45 } do
				local pos = f.CFrame:PointToWorldSpace(V(x * f.Size.X, 8, z * f.Size.Z))
				local hit = workspace:Raycast(pos, V(0, -12, 0), params)
				assert(hit and math.abs(hit.Position.Y - f.Position.Y - f.Size.Y / 2) < 0.1, "Missing course support")
				rays += 1
			end
		end
		if i < 8 then
			local divider = course.Boundaries["Boundary" .. i]
			assert(divider:GetAttribute("ToZone") == themes[i + 1].name, "Old divider title")
		end
	end
	assert(config.shotLimit(1, world) == baseline:GetAttribute("ShotLimit"), "Maximum distance changed")
	assert(#workspace.Map:GetChildren() == 1, "Unexpected extra world")
	return {
		zones = 8,
		cosmeticParts = parts,
		supportRays = rays,
		excludedAreas = areaResults,
		maximumShotDistance = config.shotLimit(1, world),
	}
end

return Verify
