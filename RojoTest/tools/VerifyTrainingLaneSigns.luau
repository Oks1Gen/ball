-- Run in Client Play. Real training rewards, isolated with Admin Begin/End.
local player = game.Players.LocalPlayer
assert(player, "Run in Client Play")
local remotes = game.ReplicatedStorage.SkippingRemotes
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Motion = require(game.ReplicatedStorage.Shared.TrainingMotion)
local expected = { 1, 2, 4, 8, 16, 32, 64 }
local snapshot, watchedLane, hits = nil, nil, {}
local update = remotes.Update.OnClientEvent:Connect(function(info)
	snapshot = info
end)
local effect = remotes.Effect.OnClientEvent:Connect(function(kind, info)
	if kind == "Train" and info.lane == watchedLane and info.boosted ~= true then
		table.insert(hits, info)
	end
end)
local function invoke(command, value)
	task.wait(0.22)
	local result = remotes.Admin:InvokeServer(command, value)
	assert(result.ok, result.message)
	return result
end
local before = invoke("Status").status
assert(not before.testing, "Finish the existing admin test first")
local began = false
local ok, result = pcall(function()
	invoke("Begin")
	began = true
	invoke("Reset")
	invoke("SetStat", { key = "rebirths", amount = 16 })
	local results = {}
	for index, multiplier in expected do
		assert(Config.Lanes[index].multiplier == multiplier, "Configured lane multiplier")
		watchedLane, hits = index, {}
		invoke("Training", index)
		remotes.Action:FireServer("Snapshot")
		local deadline = os.clock() + 5
		local count = Motion.hitCount(index)
		while #hits < count and os.clock() < deadline do
			task.wait(0.03)
		end
		assert(#hits >= count and snapshot, "Training did not produce a complete kick")
		local total = 0
		for hit = 1, count do
			assert(hits[hit].hit == hit, "Ordered contacts")
			total += hits[hit].gain
		end
		local wanted = multiplier * snapshot.multiplier * 7 * Config.TrainingCycle / 0.8
		assert(math.abs(total - wanted) <= 1.00001, "Actual reward disagrees with lane multiplier")
		local lane = workspace.Map.World1.TrainingZone["TrainingLane" .. index]
		local gui = lane.GoalSignAnchor.TrainingLaneSign
		assert(gui.Multiplier.Text == multiplier .. "x SKILL", "Displayed multiplier")
		assert(gui.Status.Text == "UNLOCKED", "All lanes unlocked at 16 rebirths")
		assert(gui.Requirement:FindFirstChildOfClass("UICorner"), "Rounded requirement capsule")
		assert(gui.Requirement.Count.Text == tostring(Config.Lanes[index].rebirths), "Required rebirth count")
		assert(gui.Requirement.RebirthIcon.IsLoaded, "Rebirth UI image did not load")
		table.insert(results, { lane = index, multiplier = multiplier, gain = total, expected = wanted })
	end
	return results
end)
watchedLane = nil
local restored = if began then invoke("End").status else before
update:Disconnect()
effect:Disconnect()
assert(
	restored.skill == before.skill and restored.wins == before.wins and restored.rebirths == before.rebirths,
	"Test must restore progression"
)
assert(ok, result)
return { lanes = result, restored = true, errors = restored.errors }
