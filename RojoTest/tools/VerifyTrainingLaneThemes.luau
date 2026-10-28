-- Read-only Edit/Server verification: real lane targets, walkable support and physics isolation.
local map = workspace.Map.World1
local backup = game.ServerStorage.WorldBackups:FindFirstChild("BeforeBiomeTrainingReferenceB_20261029")
assert(backup, "Missing pre-change snapshot")
local checks, rays, cosmetics = 0, 0, 0
local function check(value, message)
	assert(value, message)
	checks += 1
end
local Goal = require(game.ReplicatedStorage.Shared.TrainingGoal)
for i = 1, 7 do
	local lane = map.TrainingZone["TrainingLane" .. i]
	local before = backup[lane.Name]
	for _, key in { "TrainingStrip", "StartingPad", "Foundation" } do
		local p, old = lane[key], before[key]
		check(p.CFrame == old.CFrame and p.Size == old.Size, "Gameplay volume changed: " .. key)
		check(
			p.CanCollide == old.CanCollide and p.CanTouch == old.CanTouch and p.CanQuery == old.CanQuery,
			"Gameplay physics changed"
		)
	end
	for key, value in before:GetAttributes() do
		check(lane:GetAttribute(key) == value, "Progression changed")
	end
	local net, oldNet = Goal.net(lane), Goal.net(before)
	check(net ~= nil and oldNet ~= nil, "Authored goal is missing")
	check(net.CFrame == oldNet.CFrame and net.Size == oldNet.Size, "Goal target moved or resized")
	local visual = assert(lane:FindFirstChild("BiomeReferenceVisuals"))
	for _, p in visual:GetDescendants() do
		if p:IsA("BasePart") then
			check(
				p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery,
				"Decoration affects character or raycast"
			)
			cosmetics += 1
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { lane }
	params.RespectCanCollide = true
	local strip = lane.TrainingStrip
	local top = strip.Position.Y + strip.Size.Y / 2
	for x = 0, 12 do
		for z = 0, 4 do
			local position = strip.CFrame:PointToWorldSpace(
				Vector3.new((x / 12 - 0.5) * strip.Size.X * 0.96, 0, (z / 4 - 0.5) * strip.Size.Z * 0.90)
			)
			local hit = workspace:Raycast(Vector3.new(position.X, top + 8, position.Z), Vector3.new(0, -12, 0), params)
			check(hit ~= nil and math.abs(hit.Position.Y - top) < 0.005, "Missing/raised walkable support")
			rays += 1
		end
	end
	local origin = strip.CFrame * CFrame.new(0, strip.Size.Y / 2, 0) * CFrame.Angles(0, -math.pi / 2, 0)
	check((visual:GetPivot().Position - origin.Position).Magnitude < 0.001, "Visual pivot is detached from lane")
	local crest = visual:GetAttribute("CrestWorldY")
	check(lane.GoalSignAnchor.Position.Y > crest + 3, "Sign overlaps goal decoration")
	task.wait()
end
return { lanes = 7, assertions = checks, supportRays = rays, cosmeticParts = cosmetics }
