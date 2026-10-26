-- Edit-only caption migration. Preserves the existing egg geometry and purchase prompts.
assert(not game:GetService("RunService"):IsRunning(), "Run in Edit")
local Shared = game.ReplicatedStorage.Shared
local configCopy = Shared.GameConfig:Clone()
configCopy.Name = "EggSignConfigCheck"
configCopy.Parent = Shared
local config = require(configCopy)
local moduleCopy = game.ServerScriptService.Server.EggSigns:Clone()
moduleCopy.Name = "EggSignMigration"
moduleCopy.Parent = game.ServerScriptService.Server
local signs = require(moduleCopy)
local backups = game.ServerStorage:FindFirstChild("WorldBackups") or Instance.new("Folder")
backups.Name = "WorldBackups"
backups.Parent = game.ServerStorage
local backupName = "BeforeEggSigns_20261027"
local firstRun = backups:FindFirstChild(backupName) == nil
local backup = backups:FindFirstChild(backupName) or Instance.new("Folder")
backup.Name = backupName
backup.Parent = backups
local originals, count = {}, 0
for _, part in workspace.Map:GetDescendants() do
	if part:IsA("BasePart") and part.Name ~= "EggSignAnchor" then
		originals[part] = { part.CFrame, part.Size, part.CanCollide, part.CanTouch, part.CanQuery }
		count += 1
		if count % 1000 == 0 then
			task.wait()
		end
	end
end
local ok, result = pcall(function()
	local total = 0
	for _, map in workspace.Map:GetChildren() do
		local world = map:FindFirstChild("SkippingWorld")
		if not world then
			continue
		end
		if firstRun then
			local saved = Instance.new("Folder")
			saved.Name = map.Name
			saved.Parent = backup
			for _, node in world:GetDescendants() do
				if node.Name == "LabelAnchor" and node:IsA("BasePart") then
					local gui = node:FindFirstChildOfClass("BillboardGui")
					local label = gui and gui:FindFirstChildOfClass("TextLabel")
					if label and label.Text:find("Egg", 1, true) then
						local copy = node:Clone()
						copy:SetAttribute("OriginalPath", node:GetFullName())
						copy.Parent = saved
					end
				end
			end
		end
		local saved = backup:FindFirstChild(map.Name)
		local admin = world:FindFirstChild("HackedAdminEgg")
		if saved and admin and not saved:FindFirstChild("AdminMarketingLabel") then
			for _, anchor in world:GetChildren() do
				if anchor.Name == "LabelAnchor" and anchor:IsA("BasePart") then
					local label = anchor:FindFirstChildWhichIsA("TextLabel", true)
					if
						label
						and label.Text:find("BEST IN GAME", 1, true)
						and (Vector3.new(anchor.Position.X, 0, anchor.Position.Z) - Vector3.new(
								admin.Position.X,
								0,
								admin.Position.Z
							)).Magnitude
							< 0.5
					then
						local copy = anchor:Clone()
						copy.Name = "AdminMarketingLabel"
						copy.Parent = saved
					end
				end
			end
		end
		signs.apply(map, config)
		signs.apply(map, config)
		for _, egg in config.Eggs do
			local gui = world["Egg_" .. egg.id].EggSignAnchor.EggSign
			local price = config.format(egg.cost * (if map.Name == "World2" then 10 else 1)) .. " Wins"
			assert(gui.PriceRow.Amount.Text == price, "Caption price disagrees with gameplay")
			assert(gui:GetAttribute("Currency") == "Wins", "Wrong egg currency")
			local old = world["Egg_" .. egg.id]:FindFirstChild("LabelAnchor")
			local legacyGui = old and old:FindFirstChildOfClass("BillboardGui")
			assert(not legacyGui or not legacyGui.Enabled, "Duplicate old caption")
			total += 1
		end
		local premium = world:FindFirstChild("AdminEggCaption")
		if premium then
			assert(
				premium.EggSignAnchor.EggSign.PriceRow.Amount.Text == config.format(config.Products.AdminEgg.price),
				"Wrong premium price"
			)
			total += 1
		end
	end
	for part, before in originals do
		assert(part.Parent and part.CFrame == before[1] and part.Size == before[2], "Existing geometry changed")
		assert(
			part.CanCollide == before[3] and part.CanTouch == before[4] and part.CanQuery == before[5],
			"Existing collision changed"
		)
	end
	return { signs = total, preservedParts = count, backup = backup:GetFullName(), firstRun = firstRun }
end)
moduleCopy:Destroy()
configCopy:Destroy()
assert(ok, result)
return result
