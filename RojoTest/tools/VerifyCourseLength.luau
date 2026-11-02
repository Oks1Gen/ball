--!strict
-- Run in Studio Edit and Server. Pure inspection after capture; no player data.
local Verify = {}
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local baseline: any = nil

local function snapshot(root: Instance): any
	local parts = {}
	for _, node in root:GetDescendants() do
		if node:IsA("BasePart") then
			parts[node] = { node.CFrame, node.Size, node.Transparency, node.CanCollide, node.CanTouch, node.CanQuery }
		end
	end
	return parts
end

local function unchanged(parts: any): number
	local checked = 0
	for part, values in parts do
		assert(part.Parent, "Original part removed")
		assert(
			(part.Position - values[1].Position).Magnitude < 0.001 and (part.Size - values[2]).Magnitude < 0.001,
			"Geometry changed: " .. part:GetFullName()
		)
		assert(part.CFrame.Rotation == values[1].Rotation, "Rotation changed")
		assert(
			part.Transparency == values[3]
				and part.CanCollide == values[4]
				and part.CanTouch == values[5]
				and part.CanQuery == values[6],
			"Visibility/physics changed"
		)
		checked += 1
	end
	return checked
end

function Verify.capture()
	local world = workspace.Map.World1
	local fields = {}
	for index = 1, 8 do
		local f = Refs.field(world, index)
		fields[index] = { frame = f.CFrame, size = f.Size }
	end
	baseline = {
		lobby = snapshot(world.Lobby),
		training = snapshot(world.TrainingArea),
		fields = fields,
		finish = Refs.finish(world):GetPivot().Position,
	}
	return { lobbyParts = unchanged(baseline.lobby), trainingParts = unchanged(baseline.training) }
end

function Verify.run(factor: number, checkExcluded: boolean?): any
	local world = workspace.Map.World1
	local course = Refs.course(world)
	local front = 124
	local rays = 0
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { course }
	params.RespectCanCollide = true
	for index = 1, 8 do
		local f = Refs.field(world, index)
		assert(math.abs(f.Size.Z - 216 * factor) < 0.001, "Wrong location length")
		assert(math.abs(f.Position.Z - (front - (index - 0.5) * 216 * factor)) < 0.002, "Wrong location position")
		assert(f.CanCollide, "Missing pitch collision")
		for station = 0, 32 do
			for _, x in { -0.45, -0.22, 0, 0.22, 0.45 } do
				local z = -f.Size.Z / 2 + 0.2 + station / 32 * (f.Size.Z - 0.4)
				local point = f.CFrame:PointToWorldSpace(Vector3.new(f.Size.X * x, 0, z))
				local hit = workspace:Raycast(point + Vector3.new(0, 8, 0), Vector3.new(0, -16, 0), params)
				assert(
					-- The authored entrance glow is a 0.264-stud walkable lip.
					hit and math.abs(hit.Position.Y - (f.Position.Y + f.Size.Y / 2)) < 0.5,
					"Pitch gap or obstruction"
				)
				rays += 1
			end
		end
	end
	local tooLarge = 0
	for index, p in course:GetDescendants() do
		if p:IsA("BasePart") and math.max(p.Size.X, p.Size.Y, p.Size.Z) > 2048.001 then
			tooLarge += 1
		end
		if index % 2000 == 0 then
			task.wait()
		end
	end
	assert(tooLarge == 0, "Oversized part")
	if baseline then
		for index, original in baseline.fields do
			local f = Refs.field(world, index)
			assert(
				f.Size.X == original.size.X
					and f.Size.Y == original.size.Y
					and f.CFrame.Rotation == original.frame.Rotation,
				"Width/height changed"
			)
		end
		local finish = Refs.finish(world):GetPivot().Position
		assert(
			math.abs(finish.Z - (front + (baseline.finish.Z - front) * factor)) < 0.003,
			"Finish anchor did not follow the course"
		)
	end
	return {
		length = 216 * 8 * factor,
		supportRays = rays,
		lobbyUnchanged = if baseline and checkExcluded ~= false then unchanged(baseline.lobby) else nil,
		trainingUnchanged = if baseline and checkExcluded ~= false then unchanged(baseline.training) else nil,
	}
end

function Verify.snapshotCourse(): any
	return snapshot(workspace.Map.World1.FootballCourse)
end

function Verify.compareCourse(parts: any): number
	return unchanged(parts)
end

return Verify
