-- Read-only verification of the compact lobby (layout v2), plus disposable query copies of the paving.
local map = workspace.Map.World1
local layout = assert(map:FindFirstChild("CompactLobbyLayout"))
assert(layout:GetAttribute("Version") == 2, "Expected compact lobby layout v2")
local top = layout:GetAttribute("PavingTop")
assert(typeof(top) == "number", "Missing paving height")
local temporary = Instance.new("Folder")
temporary.Name = "CompactPavingVerification"
local floorCount, decorations = 0, 0
for _, p in layout:GetDescendants() do
	if p:IsA("BasePart") then
		assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery, "Cosmetic part affects physics")
		decorations += 1
		if p.Name == "PavingSurface" then
			local copy = p:Clone()
			copy.Transparency, copy.CanQuery, copy.CastShadow = 1, true, false
			copy:ClearAllChildren()
			copy.Parent = temporary
			floorCount += 1
		end
	end
end
temporary.Parent = workspace
task.wait() -- Let the query broad phase register the disposable floor copies.
local ok, result = pcall(function()
	local renderParams = RaycastParams.new()
	renderParams.FilterType = Enum.RaycastFilterType.Include
	renderParams.FilterDescendantsInstances = { temporary }
	local physicalParams = RaycastParams.new()
	physicalParams.FilterType = Enum.RaycastFilterType.Include
	physicalParams.FilterDescendantsInstances = { map }
	physicalParams.RespectCanCollide = true
	local renderProbes, supportProbes = 0, 0
	local function probe(x, z)
		local start = Vector3.new(x, top + 1, z)
		local hit = workspace:Raycast(start, Vector3.new(0, -2, 0), renderParams)
		assert(hit and math.abs(hit.Position.Y - top) < 0.015, "Visible paving gap at " .. x .. ", " .. z)
		renderProbes += 1
		assert(workspace:Raycast(start, Vector3.new(0, -3, 0), physicalParams), "Walkable support missing")
		supportProbes += 1
		if renderProbes % 100 == 0 then
			task.wait()
		end
	end
	local function area(x0, x1, z0, z1, step)
		for x = x0, x1, step do
			for z = z0, z1, step do
				probe(x, z)
			end
		end
	end
	-- Boulevard, trophy plaza and the hall walk in front of the ranking row.
	area(58.5, 76.5, 150.5, 278.5, 1.5)
	area(47.5, 87.5, 279.5, 300.5, 2)
	area(-8.5, 143.5, 293.5, 300.5, 1.75)
	-- Branches to the portal, ball stand and egg court.
	area(30.5, 57.5, 165.5, 178.5, 1.5)
	area(-5.5, 29.5, 150.5, 193.5, 2)
	area(21, 33.5, 189.5, 254.5, 1.5)
	area(34.5, 57.5, 215.5, 228.5, 1.5)
	area(-5.5, 57.5, 255.5, 278.5, 2)
	area(-5.5, 46.5, 279.5, 292.5, 2)
	for i = 1, 7 do
		local strip = map.TrainingZone["TrainingLane" .. i].TrainingStrip
		for x = 77.1, 83.9, 1.0 do
			for _, dz in { -5.8, 0, 5.8 } do
				probe(x, strip.Position.Z + dz)
			end
		end
	end
	-- Every egg's hatch teleport point and every ball pad lies on paving; the eggs of the
	-- arc (EggCourtRelayout) keep apart from each other and from the Volcanic egg.
	assert(map:GetAttribute("EggArc"), "Egg arc not applied")
	local eggs = { map.SkippingWorld.HackedAdminEgg.Position }
	for _, id in { "Common", "Uncommon", "Rare", "Rainbow" } do
		local shell = map.SkippingWorld["Egg_" .. id].EggShell
		local front = shell.Position + shell.CFrame.LookVector * Vector3.new(1, 0, 1) * 10
		probe(front.X, front.Z)
		table.insert(eggs, shell.Position)
	end
	for i = 1, #eggs do
		for j = i + 1, #eggs do
			local gap = (eggs[i] - eggs[j]) * Vector3.new(1, 0, 1)
			assert(gap.Magnitude > 14, "Eggs too close together")
		end
	end
	for slot = 1, 5 do
		local pad = map.EmptyItemStand["EmptyPedestal" .. slot]
		probe(pad.Position.X + 6, pad.Position.Z)
	end
	-- Lawn islands stay open lawn.
	for _, p in { Vector2.new(46, 197), Vector2.new(46, 242), Vector2.new(150, 157), Vector2.new(150, 250) } do
		assert(
			not workspace:Raycast(Vector3.new(p.X, top + 1, p.Y), Vector3.new(0, -2, 0), renderParams),
			"Lawn island covered by paving"
		)
	end
	-- Boundary blockers follow the compacted terraces (the rear blocker keeps its original 1-stud setback).
	local walls = map.PerimeterWalls
	assert(math.abs(walls.LobbyLeft.Position.X + walls.LobbyLeft.Size.X / 2 - -17) < 0.01, "West boundary moved")
	assert(math.abs(walls.LobbyRight.Position.X - walls.LobbyRight.Size.X / 2 - 155) < 0.01, "East boundary moved")
	assert(math.abs(walls.LobbyBack.Position.Z - walls.LobbyBack.Size.Z / 2 - 316) < 0.01, "Rear boundary moved")
	for _, p in map.GeometryPolish:GetDescendants() do
		if p:IsA("BasePart") or p:IsA("Decal") then
			assert(p.Transparency == 1, "Retired paving still renders")
		end
	end
	-- The waterfall falls from the top terrace (Y 81.4) and its flow layers are live.
	local fall = map.SpawnGarden.CornerWaterfall1
	local curtain = fall.WaterCurtain
	assert(fall:GetAttribute("FullWaterfall"), "Waterfall not upgraded")
	assert(curtain.Position.Y + curtain.Size.Y / 2 >= 82, "Waterfall starts below the terrace top")
	local beams = 0
	for _, b in fall.VFX_Waterfall:GetChildren() do
		if b:IsA("Beam") and b.Enabled and b.TextureSpeed > 0 then
			beams += 1
		end
	end
	assert(beams == 4, "Waterfall flow beams missing")
	return {
		renderProbes = renderProbes,
		supportProbes = supportProbes,
		floorParts = floorCount,
		cosmeticParts = decorations,
	}
end)
temporary:Destroy()
assert(ok, result)
return result
