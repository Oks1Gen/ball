-- Run through Studio MCP with the shared modules synced. Does not change player data or the scene.
local Shared = game.ReplicatedStorage.Shared
local Motion = require(Shared.TrainingMotion)
local Goal = require(Shared.TrainingGoal)
local Area = require(Shared.TrainingArea)
local Config = require(Shared.GameConfig)
local checks, shots, lanes = 0, 0, 0
local function check(value, message)
	assert(value, message)
	checks += 1
end

for _, worldName in { "World1", "World2" } do
	local map = workspace.Map:FindFirstChild(worldName)
	local zone = map and map:FindFirstChild("TrainingZone")
	for index = 1, 7 do
		local lane = zone and zone:FindFirstChild("TrainingLane" .. index)
		local strip = lane and lane:FindFirstChild("TrainingStrip")
		local net = lane and Goal.net(lane)
		if not strip or not net then
			continue -- Another world may not yet be streamed to the client.
		end
		lanes += 1
		local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
		for _, fractions in
			{
				Vector2.new(-0.43, -0.32),
				Vector2.new(-0.43, 0.32),
				Vector2.zero,
				Vector2.new(0.36, -0.32),
				Vector2.new(0.36, 0.32),
				Vector2.new(0.45, 0),
			}
		do
			local offset =
				strip.CFrame:PointToWorldSpace(Vector3.new(strip.Size.X * fractions.X, 0, strip.Size.Z * fractions.Y))
			local root = Vector3.new(offset.X, Config.trainingSurface(lane) + 3, offset.Z)
			check(Area.contains(strip, root), "Any playable strip location is accepted")
			for cycle = 0, 23 do
				local shot = Goal.shot(lane, root, 73123, cycle)
				check(shot ~= nil, "Shot exists from every location")
				local repeatShot = Goal.shot(lane, root, 73123, cycle)
				check((shot.finish - repeatShot.finish).Magnitude < 1e-5, "Cycle target is deterministic")
				local point = net.CFrame:PointToObjectSpace(shot.finish)
				check(math.abs(point.X) <= net.Size.X / 2 - 0.97, "Ball clears side posts")
				check(math.abs(point.Y) <= net.Size.Y / 2 - 0.97, "Ball clears crossbar and ground edge")
				local hit = Goal.contact(net, shot.start, shot.finish, index)
				check(hit ~= nil, "Shot actually reaches the net")
				check(
					math.abs(hit.phase - Motion.hitTime(index, Motion.hitCount(index))) < 0.002,
					"Net contact matches final server reward"
				)
				check(
					(Motion.position(shot.start, shot.finish, hit.phase, index) - shot.finish).Magnitude < 0.01,
					"Effect and ball reach the same target"
				)
				for contact = 1, Motion.hitCount(index) - 1 do
					local position = Motion.position(shot.start, shot.finish, Motion.hitTime(index, contact), index)
					check(math.abs(position.Y - shot.start.Y) < 1e-4, "Earlier bounces stay on the turf")
				end
				minX, maxX = math.min(minX, point.X), math.max(maxX, point.X)
				minY, maxY = math.min(minY, point.Y), math.max(maxY, point.Y)
				shots += 1
			end
		end
		check(maxX - minX > net.Size.X * 0.4, "Targets cover both sides of the goal")
		check(maxY - minY > net.Size.Y * 0.35, "Targets cover low and high parts of the goal")
		local center = strip.Position + Vector3.new(0, 3, 0)
		check(not Area.contains(strip, center + strip.CFrame.RightVector * strip.Size.X), "Outside strip is rejected")
		check(
			not Area.repositioned(center, center + Vector3.new(0, 8, 0)),
			"Jump alone does not count as repositioning"
		)
		check(
			Area.repositioned(center, center + Vector3.new(2, 0, 0)),
			"Moving to a new spot permits another training session"
		)
		task.wait()
	end
end
check(lanes > 0, "At least one loaded lane was checked")
return { checks = checks, shots = shots, lanes = lanes }
