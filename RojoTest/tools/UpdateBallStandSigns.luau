-- Edit-only caption refresh. Does not run ball/stand placement or touch purchase prompts.
assert(not game:GetService("RunService"):IsRunning(), "Run in Edit")
local source = game.ServerScriptService.Server.BallStandSigns:Clone()
source.Name = "BallSignMigration"
source.Parent = game.ServerScriptService.Server
local signs = require(source)
local originals, count = {}, 0
for _, root in { workspace.Map, workspace:FindFirstChild("AllBalls_NoTextures") } do
	if root then
		for _, part in root:GetDescendants() do
			if part:IsA("BasePart") and not originals[part] then
				originals[part] = { part.CFrame, part.Size, part.CanCollide, part.CanTouch, part.CanQuery }
				count += 1
				if count % 1000 == 0 then
					task.wait()
				end
			end
		end
	end
end
local backups = game.ServerStorage:FindFirstChild("WorldBackups") or Instance.new("Folder")
backups.Name = "WorldBackups"
backups.Parent = game.ServerStorage
local backupName = "BeforeBallStandSigns_20261027"
local firstRun = backups:FindFirstChild(backupName) == nil
local backup = backups:FindFirstChild(backupName) or Instance.new("Folder")
backup.Name = backupName
backup.Parent = backups
local ok, result = pcall(function()
	local total = 0
	for _, map in workspace.Map:GetChildren() do
		local world = map:FindFirstChild("SkippingWorld")
		if not world then
			continue
		end
		if not backup:FindFirstChild(map.Name) then
			local saved = Instance.new("Folder")
			saved.Name = map.Name
			saved.Parent = backup
			for _, model in game:GetService("CollectionService"):GetTagged("BallStandPreview") do
				if not model:IsDescendantOf(workspace) then
					continue
				end
				local link = model:FindFirstChild("DisplayLabel")
				local anchor = link and link.Value
				if anchor and anchor:IsDescendantOf(world) then
					local copy = anchor:Clone()
					copy.Name = "Slot_" .. model:GetAttribute("DisplaySlot")
					copy:SetAttribute("OriginalPath", anchor:GetFullName())
					-- An interrupted earlier refresh may have completed the other
					-- world already. The untouched legacy text still supplies its
					-- original appearance when filling the missing backup here.
					local gui = copy:FindFirstChildOfClass("BillboardGui")
					local legacy = gui and gui:FindFirstChild("TextLabel")
					if gui and legacy and legacy:IsA("TextLabel") and gui:HasTag("BallStandSign") then
						for _, name in { "Status", "Power", "Price" } do
							local added = gui:FindFirstChild(name)
							if added then
								added:Destroy()
							end
						end
						legacy.Visible = true
						gui:RemoveTag("BallStandSign")
						gui:SetAttribute("BallId", nil)
						gui:SetAttribute("BallName", nil)
					end
					copy.Parent = saved
				end
			end
		end
		local applied = signs.apply(map)
		assert(applied == 10, "Expected ten linked ball captions in " .. map.Name)
		assert(signs.apply(map) == 10, "Repeated refresh must not duplicate signs")
		total += applied
	end
	for part, before in originals do
		assert(part.Parent and part.CFrame == before[1] and part.Size == before[2], "Existing part moved/resized")
		assert(
			part.CanCollide == before[3] and part.CanTouch == before[4] and part.CanQuery == before[5],
			"Existing collision changed"
		)
	end
	return { signs = total, preservedParts = count, backup = backup:GetFullName(), firstRun = firstRun }
end)
source:Destroy()
assert(ok, result)
return result
