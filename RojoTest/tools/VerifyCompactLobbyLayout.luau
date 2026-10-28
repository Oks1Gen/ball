-- Read-only original scene verification, plus disposable query copies of the actual paving.
local map = workspace.Map.World1
local layout = assert(map:FindFirstChild("CompactLobbyLayout"))
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
		-- Query hulls can miss an exact shared edge even when the rendered faces meet.
		if not hit then
			for _, offset in
				{ Vector3.new(0.02, 0, 0), Vector3.new(-0.02, 0, 0), Vector3.new(0, 0, 0.02), Vector3.new(0, 0, -0.02) }
			do
				hit = workspace:Raycast(start + offset, Vector3.new(0, -2, 0), renderParams)
				if hit then
					break
				end
			end
		end
		-- Primitive wedge query hulls add a small margin to the rendered top face.
		assert(hit and math.abs(hit.Position.Y - top) < 0.015, "Visible paving gap at " .. x .. ", " .. z)
		renderProbes += 1
		local support = workspace:Raycast(start, Vector3.new(0, -3, 0), physicalParams)
		assert(support, "Walkable support missing")
		supportProbes += 1
		if renderProbes % 100 == 0 then
			task.wait()
		end
	end
	-- Routes between protected gameplay destinations and the main boulevard.
	for z = 149.2, 299.8, 1.5 do
		for _, x in { 59, 64, 71, 76 } do
			probe(x, z)
		end
	end
	for _, route in { { 20, 65, 172 }, { -20, 65, 218 }, { -30, 65, 275 } } do
		for x = route[1], route[2], 1.5 do
			for _, dz in { -4, 0, 4 } do
				probe(x, route[3] + dz)
			end
		end
	end
	for i = 1, 7 do
		local strip = map.TrainingZone["TrainingLane" .. i].TrainingStrip
		for x = 77.1, 83.9, 1.0 do
			for _, dz in { -5.8, 0, 5.8 } do
				probe(x, strip.Position.Z + dz)
			end
		end
	end
	for _, p in
		{
			Vector2.new(-15, 158),
			Vector2.new(20, 186),
			Vector2.new(-20, 235),
			Vector2.new(25, 207),
			Vector2.new(-25, 290),
			Vector2.new(34, 255),
			Vector2.new(34, 292),
			Vector2.new(65, 301),
		}
	do
		probe(p.X, p.Y)
	end
	-- The retired perimeter roads should now be lawn, not replacement paving.
	for _, p in { Vector2.new(150, 157), Vector2.new(150, 295), Vector2.new(112, 295) } do
		assert(
			not workspace:Raycast(Vector3.new(p.X, top + 1, p.Y), Vector3.new(0, -2, 0), renderParams),
			"Old perimeter road remains in new layout"
		)
	end
	for _, p in map.GeometryPolish:GetDescendants() do
		if p:IsA("BasePart") or p:IsA("Decal") then
			assert(p.Transparency == 1, "Retired paving still renders")
		end
	end
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
