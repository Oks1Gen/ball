-- Run in Studio with new sources synced. Uses temporary shot state, no player data changes.
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.GameConfig)
local Goal = require(Shared.TrainingGoal)
local Tracker = require(game.StarterPlayer.StarterPlayerScripts.Client.Modules.TrainingShot)
local checks, lanes = 0, 0
local function check(value, message)
	assert(value, message)
	checks += 1
end

local zone = workspace.Map.World1.TrainingZone
for index = 1, 7 do
	local lane = zone:FindFirstChild("TrainingLane" .. index)
	local strip = lane and lane:FindFirstChild("TrainingStrip")
	if not strip or not Goal.net(lane) then
		continue
	end
	lanes += 1
	local origin = strip.Position + Vector3.new(-8, 3, -2)
	local moved = origin + Vector3.new(4, 0, 2)
	local kickOrigin = moved + Vector3.new(2, 0, -1)
	local state = Tracker.update(nil, lane, origin, 73123, 0.05, 100)
	local first = state.shot
	check(first and not state.launched, "Windup starts while moving")
	state = Tracker.update(state, lane, moved, 73123, 0.25, 100)
	check((state.shot.start - first.start).Magnitude > 2, "Ball follows the player's moving foot")
	check((state.shot.finish - first.finish).Magnitude < 0.001, "Target stays chosen during windup")
	state = Tracker.update(state, lane, kickOrigin, 73123, Config.KickContact + 0.01, 100)
	local launched = state.shot
	local expected = Goal.shot(lane, kickOrigin, 73123, 0)
	check(
		state.launched and (launched.start - expected.start).Magnitude < 0.001,
		"Launch uses the current position at contact"
	)
	state = Tracker.update(state, lane, kickOrigin + Vector3.new(8, 0, 3), 73123, 0.8, 100)
	check(state.shot == launched, "Walking after contact cannot bend or restart the shot")
	check(state.started == 100 and state.cycle == 0, "Moving preserves the training timeline")
	local nextOrigin = kickOrigin + Vector3.new(7, 0, -1)
	state = Tracker.update(state, lane, nextOrigin, 73123, Config.TrainingCycle + 0.05, 100)
	check(state.cycle == 1 and not state.launched, "Next kick begins without cancelling training")
	check((state.shot.start - launched.start).Magnitude > 2, "Next kick follows the new running position")
	local standing = state.shot.start
	state = Tracker.update(state, lane, nextOrigin, 73123, Config.TrainingCycle + 0.2, 100)
	check((state.shot.start - standing).Magnitude < 0.001, "Standing still remains supported")
	state = Tracker.update(state, lane, nextOrigin, 73123, 0.05, 200)
	check(
		state.started == 200 and state.cycle == 0 and not state.launched,
		"A new session clears the old launched shot"
	)
	task.wait()
end
check(lanes > 0, "At least one loaded lane was tested")
return { checks = checks, lanes = lanes }
