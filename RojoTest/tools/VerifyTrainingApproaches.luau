-- Read-only scene checks with disposable query copies of cosmetic paving.
local world = workspace.Map.World1
local paths = world.Lobby.Paths
local refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local lanes = refs.training(world)
local road = paths.Boulevard.PavingSurface
local edge = road.Position.X + road.Size.X / 2
local top = road.Position.Y + road.Size.Y / 2
assert(
	math.abs(road.Size.X - 38) < 0.001 and math.abs(road.Position.X - 55.5) < 0.001,
	"Boulevard did not widen equally"
)
local temporary = Instance.new("Folder")
temporary.Name = "TrainingPathVerification"
for _, group in paths:GetChildren() do
	local surface = group:FindFirstChild("PavingSurface")
	if surface and (group.Name == "Boulevard" or group.Name:match("^TrainingApproach%d+$")) then
		local copy = surface:Clone()
		copy:ClearAllChildren()
		copy.CanQuery, copy.Transparency = true, 1
		copy.Parent = temporary
	end
end
temporary.Parent = workspace
task.wait()
local ok, result = pcall(function()
	local render = RaycastParams.new()
	render.FilterType = Enum.RaycastFilterType.Include
	render.FilterDescendantsInstances = { temporary }
	local physical = RaycastParams.new()
	physical.FilterType = Enum.RaycastFilterType.Include
	physical.FilterDescendantsInstances = { world }
	physical.RespectCanCollide = true
	local probes = 0
	local tiles = 0
	local surfaces = {}
	for _, group in paths:GetChildren() do
		local surface = group:FindFirstChild("PavingSurface")
		if surface then
			table.insert(surfaces, surface)
		end
		for _, part in group:GetChildren() do
			if part:IsA("BasePart") and part.Name == "CheckerTile" then
				assert(part.Size.X <= 8.001 and part.Size.Z <= 8.001, "Checker grid is too large")
				assert(not part.CanCollide and not part.CanTouch and not part.CanQuery, "Checker affects physics")
				tiles += 1
			end
		end
	end
	assert(tiles > 0, "Missing checker grid")
	for i, a in surfaces do
		for j = i + 1, #surfaces do
			local b = surfaces[j]
			local dx = math.min(a.Position.X + a.Size.X / 2, b.Position.X + b.Size.X / 2)
				- math.max(a.Position.X - a.Size.X / 2, b.Position.X - b.Size.X / 2)
			local dz = math.min(a.Position.Z + a.Size.Z / 2, b.Position.Z + b.Size.Z / 2)
				- math.max(a.Position.Z - a.Size.Z / 2, b.Position.Z - b.Size.Z / 2)
			assert(dx <= 0.001 or dz <= 0.001, "Paving surfaces overlap")
		end
	end
	for i = 1, 7 do
		local lane = lanes["TrainingLane" .. i]
		local front = lane.Foundation.Position.X - lane.Foundation.Size.X / 2
		local surface = paths["TrainingApproach" .. i].PavingSurface
		assert(math.abs(surface.Position.Z - lane.StartingPad.Position.Z) < 0.001, "Path is not centred on entrance")
		assert(math.abs(surface.Position.X - surface.Size.X / 2 - edge) < 0.001, "Path misses boulevard")
		assert(math.abs(surface.Position.X + surface.Size.X / 2 - front) < 0.001, "Path misses training field")
		for x = edge - 1, front - 0.1, 1 do
			for _, offset in { -5.5, 0, 5.5 } do
				local point = Vector3.new(x, top + 2, lane.StartingPad.Position.Z + offset)
				local hit = workspace:Raycast(point, Vector3.new(0, -4, 0), render)
				assert(hit and math.abs(hit.Position.Y - top) < 0.01, "Paving gap")
				assert(workspace:Raycast(point, Vector3.new(0, -12, 0), physical), "Missing walkable support")
				probes += 1
			end
		end
	end
	return {
		approaches = 7,
		pavingProbes = probes,
		supportProbes = probes,
		boulevardWidth = road.Size.X,
		checkerTiles = tiles,
		overlapPairs = 0,
	}
end)
temporary:Destroy()
assert(ok, result)
return result
