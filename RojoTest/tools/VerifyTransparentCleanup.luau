--!strict
-- Capture before deletion; verify retained geometry, targets and references after.
local Verify = {}
local Cleanup = require(game.ServerScriptService.Server.TransparentCleanup:Clone())
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Goal = require(game.ReplicatedStorage.Shared.TrainingGoal)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local snapshot: any = nil

local function gameplay(map: Instance): any
	local values = {}
	for _, world in map:GetChildren() do
		values[world.Name] = { limit = Config.shotLimit(1, world), lanes = {} }
		for i = 1, 7 do
			local lane = Refs.training(world):FindFirstChild("TrainingLane" .. i)
			local shot = assert(Goal.shot(lane, lane.StartingPad.Position, 17, 3), "Training shot has no net")
			values[world.Name].lanes[i] = { shot.start, shot.finish, lane.GoalSignAnchor.CFrame }
		end
	end
	return values
end

function Verify.capture(map: Instance): any
	local plan = Cleanup.plan(map)
	local excluded: { [Instance]: boolean } = {}
	for _, part in plan.parts do
		excluded[part] = true
	end
	snapshot = { parts = {}, models = {}, removed = plan.parts, gameplay = gameplay(map) }
	for _, node in map:GetDescendants() do
		if node:IsA("BasePart") and not excluded[node] then
			snapshot.parts[node] =
				{ node.CFrame, node.Size, node.Transparency, node.CanCollide, node.CanTouch, node.CanQuery }
		elseif node:IsA("Model") then
			snapshot.models[node] = node:GetPivot()
		end
	end
	return plan.report
end

function Verify.compare(map: Instance): any
	assert(snapshot, "Capture before cleanup")
	local checked = 0
	for node, properties in snapshot.parts do
		assert(node:IsDescendantOf(map), "Retained part was deleted: " .. node.Name)
		assert(node.CFrame == properties[1] and node.Size == properties[2], "Retained geometry moved")
		assert(node.Transparency == properties[3], "Retained visibility changed")
		assert(
			node.CanCollide == properties[4] and node.CanTouch == properties[5] and node.CanQuery == properties[6],
			"Retained physics changed"
		)
		checked += 1
	end
	for node, pivot in snapshot.models do
		assert(node:GetPivot() == pivot, "Model pivot changed: " .. node:GetFullName())
	end
	for _, part in snapshot.removed do
		assert(part.Parent == nil, "Reviewed garbage was not deleted")
	end
	local current = gameplay(map)
	for world, original in snapshot.gameplay do
		assert(current[world].limit == original.limit, "Shot limit changed")
		for i, lane in original.lanes do
			for j, value in lane do
				assert(current[world].lanes[i][j] == value, "Training trajectory or sign changed")
			end
		end
	end
	local nextPlan = Cleanup.plan(map)
	assert(#nextPlan.parts == 0, "Cleanup is not idempotent")
	return {
		removedParts = #snapshot.removed,
		unchangedParts = checked,
		verifiedTrainingLanes = 14,
		remainingCandidates = #nextPlan.parts,
	}
end

return Verify
