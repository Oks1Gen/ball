-- Narrow, repeatable Edit migration. Back up captions; leave all old part volumes intact.
assert(not game:GetService("RunService"):IsRunning(), "Run this migration in Edit")
local Shared = game.ReplicatedStorage.Shared
local freshConfig = Shared.GameConfig:Clone()
freshConfig.Name = "LaneSignConfigCheck"
freshConfig.Parent = Shared
local config = require(freshConfig)
local source = game.ServerScriptService.Server.TrainingLaneSigns:Clone()
source.Name = "LaneSignMigration"
source.Parent = game.ServerScriptService.Server
local signs = require(source)
local backups = game.ServerStorage:FindFirstChild("WorldBackups") or Instance.new("Folder")
backups.Name = "WorldBackups"
backups.Parent = game.ServerStorage
local backupName = "BeforeTrainingLaneSignsReference_20261026"
local firstRun = backups:FindFirstChild(backupName) == nil
local backup = backups:FindFirstChild(backupName) or Instance.new("Folder")
backup.Name = backupName
backup.Parent = backups
local originals = {}
local count = 0
for _, part in workspace.Map:GetDescendants() do
	if part:IsA("BasePart") and part.Name ~= "GoalSignAnchor" then
		originals[part] = { part.CFrame, part.Size, part.CanCollide, part.CanTouch, part.CanQuery }
		count += 1
		if count % 1000 == 0 then
			task.wait()
		end
	end
end
local total = 0
local ok, result = pcall(function()
	for _, map in workspace.Map:GetChildren() do
		local zone = map:FindFirstChild("TrainingZone")
		if not zone then
			continue
		end
		if firstRun then
			local saved = Instance.new("Folder")
			saved.Name = map.Name
			saved.Parent = backup
			for i = 1, 7 do
				local lane = zone:FindFirstChild("TrainingLane" .. i)
				for _, name in { "UIAnchor", "GoalSignAnchor" } do
					local anchor = lane and lane:FindFirstChild(name)
					if anchor then
						local copy = anchor:Clone()
						copy.Name = "Lane" .. i .. "_" .. name
						copy:SetAttribute("OriginalPath", anchor:GetFullName())
						copy.Parent = saved
					end
				end
			end
			local skipping = map:FindFirstChild("SkippingWorld")
			if skipping then
				for _, anchor in skipping:GetChildren() do
					if anchor.Name == "LabelAnchor" then
						local gui = anchor:FindFirstChildOfClass("BillboardGui")
						local caption = gui and gui:FindFirstChildOfClass("TextLabel")
						if caption and caption.Text:match("^RB %d+\n") then
							local copy = anchor:Clone()
							copy:SetAttribute("OriginalPath", anchor:GetFullName())
							copy.Parent = saved
						end
					end
				end
			end
		end
		signs.apply(map, config.Lanes)
		signs.apply(map, config.Lanes)
		for i, definition in config.Lanes do
			local lane = zone:FindFirstChild("TrainingLane" .. i)
			if lane then
				local anchor = lane:FindFirstChild("GoalSignAnchor")
				assert(anchor and anchor:FindFirstChild("TrainingLaneSign"), "Missing goal sign")
				assert(
					anchor.TrainingLaneSign.Multiplier.Text == definition.multiplier .. "x SKILL",
					"Sign matches configuration"
				)
				total += 1
			end
		end
	end
	for part, before in originals do
		assert(part.Parent and part.CFrame == before[1] and part.Size == before[2], "Original part moved/resized")
		assert(
			part.CanCollide == before[3] and part.CanTouch == before[4] and part.CanQuery == before[5],
			"Original collision changed"
		)
	end
	return { signs = total, preservedParts = count, backup = backup:GetFullName(), firstRun = firstRun }
end)
source:Destroy()
freshConfig:Destroy()
assert(ok, result)
return result
