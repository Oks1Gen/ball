-- Read-only Edit/Server verification of ground support, paving and lighting.
local report = {}
for _, world in workspace.Map:GetChildren() do
	local low, high = Vector3.new(math.huge, 0, math.huge), Vector3.new(-math.huge, 0, -math.huge)
	for _, p in world.Lobby:GetChildren() do
		if p:IsA("BasePart") and p.Name == "GroundTile" then
			local a, b = p.Position - p.Size / 2, p.Position + p.Size / 2
			low = Vector3.new(math.min(low.X, a.X), b.Y, math.min(low.Z, a.Z))
			high = Vector3.new(math.max(high.X, b.X), b.Y, math.max(high.Z, b.Z))
		end
	end
	assert(low.X < high.X, "Missing lobby tiles")
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { world }
	params.RespectCanCollide = true
	local probes, holes = 0, 0
	local function probe(x, z, y)
		probes += 1
		local hit = workspace:Raycast(Vector3.new(x, y + 1.5, z), Vector3.new(0, -3, 0), params)
		if not hit then
			holes += 1
		end
	end
	for x = low.X + 2, high.X - 1, 4 do
		for z = low.Z + 2, high.Z - 1, 4 do
			probe(x, z, low.Y)
		end
	end
	for _, bank in world.SkippingWorld:GetChildren() do
		if bank:IsA("BasePart") and bank.Name:match("^BiomeBank%d+_") then
			for z = bank.Position.Z - bank.Size.Z / 2 + 0.1, bank.Position.Z + bank.Size.Z / 2 - 0.1, 4 do
				for _, dx in { -0.4, 0, 0.4 } do
					probe(bank.Position.X + dx * bank.Size.X, z, bank.Position.Y + bank.Size.Y / 2)
				end
			end
		end
	end
	local maxSeam = 0
	for i = 1, 8 do
		local p = world.SkippingWorld["Water_" .. i]
		for z = p.Position.Z - p.Size.Z / 2 + 0.1, p.Position.Z + p.Size.Z / 2 - 0.1, 4 do
			for _, dx in { -54, -27, 0, 27, 54 } do
				probe(p.Position.X + dx, z, p.Position.Y + p.Size.Y / 2)
			end
		end
		if i < 8 then
			local nextPitch = world.SkippingWorld["Water_" .. (i + 1)]
			maxSeam = math.max(
				maxSeam,
				math.abs((p.Position.Z - p.Size.Z / 2) - (nextPitch.Position.Z + nextPitch.Size.Z / 2))
			)
		end
	end
	assert(holes == 0, world.Name .. ": collision support holes: " .. holes)
	assert(maxSeam < 0.002, world.Name .. ": pitch gap")
	local polish = assert(world:FindFirstChild("GeometryPolish"))
	local compact = world:FindFirstChild("CompactLobbyLayout")
	local pieces = {}
	for _, p in polish:GetChildren() do
		if p:IsA("BasePart") and p.Transparency < 1 then
			assert(not p.CanCollide and not p.CanTouch and not p.CanQuery, "Cosmetic part has physics")
			assert(p.CFrame.UpVector:Dot(Vector3.yAxis) > 0.99999, "Tilted paving")
			table.insert(pieces, p)
		end
	end
	local samples = 0
	local layout = world:FindFirstChild("TwoAxesLayout")
	if layout and not compact then
		local top = world.Lobby.ThrowingApron.Position.Y - 0.3 + 0.26
		for _, p in pieces do
			assert(math.abs(p.Position.Y + p.Size.Y / 2 - top) < 0.00002, "Uneven paving")
		end
		for _, original in layout.Paving:GetChildren() do
			if original:IsA("BasePart") then
				for _, dx in { -0.4999, 0, 0.4999 } do
					for _, dz in { -0.4999, 0, 0.4999 } do
						local point = original.Position + Vector3.new(dx * original.Size.X, 0, dz * original.Size.Z)
						local covered = false
						for _, p in pieces do
							local q = p.CFrame:PointToObjectSpace(point)
							if math.abs(q.X) <= p.Size.X / 2 + 0.0001 and math.abs(q.Z) <= p.Size.Z / 2 + 0.0001 then
								covered = true
							end
						end
						assert(covered, "Paving coverage gap")
						samples += 1
					end
				end
			end
		end
		for i, a in pieces do
			for j = i + 1, #pieces do
				local b = pieces[j]
				local x = math.min(a.Position.X + a.Size.X / 2, b.Position.X + b.Size.X / 2)
					- math.max(a.Position.X - a.Size.X / 2, b.Position.X - b.Size.X / 2)
				local z = math.min(a.Position.Z + a.Size.Z / 2, b.Position.Z + b.Size.Z / 2)
					- math.max(a.Position.Z - a.Size.Z / 2, b.Position.Z - b.Size.Z / 2)
				assert(x < 0.001 or z < 0.001, "Paving layers overlap")
			end
		end
	end
	report[world.Name] = {
		supportProbes = probes,
		holes = holes,
		maxFieldSeam = maxSeam,
		pavingPieces = #pieces,
		pavingSamples = samples,
		activePaving = compact and "CompactLobbyLayout" or "GeometryPolish",
	}
end
local gradeCount, bloomCount = 0, 0
for _, effect in game.Lighting:GetChildren() do
	if effect:IsA("ColorCorrectionEffect") and effect.Enabled then
		gradeCount += 1
	elseif effect:IsA("BloomEffect") and effect.Enabled then
		bloomCount += 1
	end
end
assert(gradeCount == 1 and bloomCount == 1, "Stacked lighting effects")
assert(game.Lighting.BalancedDaylightBloom.Intensity <= 0.1, "Excess bloom")
return report
