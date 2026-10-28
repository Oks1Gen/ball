-- Edit-only migration for the approved biome reference. Keeps a full pre-change snapshot.
assert(not game:GetService("RunService"):IsRunning(), "Run in Edit")
local map = workspace.Map.World1
local zone = map.TrainingZone
local storage = game:GetService("ServerStorage")
local backups = storage:FindFirstChild("WorldBackups") or Instance.new("Folder")
backups.Name, backups.Parent = "WorldBackups", storage
local backupName = "BeforeBiomeTrainingReferenceB_20261029"
local backup = backups:FindFirstChild(backupName)
if not backup then
	backup = Instance.new("Folder")
	backup.Name, backup.Parent = backupName, backups
	for i = 1, 7 do
		zone["TrainingLane" .. i]:Clone().Parent = backup
		task.wait()
	end
	local overlays = Instance.new("Folder")
	overlays.Name, overlays.Parent = "DetachedOverlays", backup
	local repairs = map:FindFirstChild("SurfaceRepairs")
	if repairs then
		for _, item in repairs:GetChildren() do
			local source = item:GetAttribute("SurfaceSource")
			if type(source) == "string" and source:find("TrainingLane", 1, true) then
				item:Clone().Parent = overlays
			end
		end
	end
end
local states, pivots, attributes = {}, {}, {}
for _, item in map:GetDescendants() do
	if item.Name == "BiomeReferenceVisuals" or item:FindFirstAncestor("BiomeReferenceVisuals") then
		continue
	end
	if item:IsA("BasePart") then
		states[item] = { item.CFrame, item.Size, item.CanCollide, item.CanTouch, item.CanQuery }
	end
	if item:IsA("Model") then
		pivots[item] = item:GetPivot()
	end
end
for i = 1, 7 do
	local lane = zone["TrainingLane" .. i]
	attributes[lane] = lane:GetAttributes()
end
game:GetService("ChangeHistoryService"):SetWaypoint("Before biome training reference B")
local fresh = game.ServerScriptService.Server.TrainingLaneThemes:Clone()
fresh.Name, fresh.Parent = "TrainingLaneThemesEditMigration", game.ServerScriptService.Server
local ok, result = pcall(function()
	local themes = require(fresh)
	themes.apply(map)
	local count = #map:GetDescendants()
	themes.apply(map)
	assert(#map:GetDescendants() == count, "Repeated apply created duplicates")
	local checked = 0
	for p, state in states do
		assert(p.Parent, "Original part removed: " .. p.Name)
		assert(p.Size == state[2], "Original part resized: " .. p:GetFullName())
		if p.Name ~= "GoalSignAnchor" then
			assert(p.CFrame == state[1], "Original part moved: " .. p:GetFullName())
		end
		assert(p.CanCollide == state[3] and p.CanTouch == state[4] and p.CanQuery == state[5], "Collision changed")
		checked += 1
		if checked % 1000 == 0 then
			task.wait()
		end
	end
	for model, pivot in pivots do
		assert(model:GetPivot() == pivot, "Original model pivot changed: " .. model:GetFullName())
	end
	local parts = 0
	for i = 1, 7 do
		local lane = zone["TrainingLane" .. i]
		for key, value in attributes[lane] do
			assert(lane:GetAttribute(key) == value, "Gameplay attribute changed")
		end
		local visual = assert(lane:FindFirstChild("BiomeReferenceVisuals"))
		for _, p in visual:GetDescendants() do
			if p:IsA("BasePart") then
				assert(
					p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery,
					"Decoration affects physics"
				)
				parts += 1
			end
		end
	end
	return { preservedOriginalParts = checked, cosmeticParts = parts, backup = backup:GetFullName(), idempotent = true }
end)
fresh:Destroy()
assert(ok, result)
game:GetService("ChangeHistoryService"):SetWaypoint("Biome training reference B")
return game.HttpService:JSONEncode(result)
