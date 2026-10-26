-- Edit-only, guarded 45-degree left turn of the World1 egg shown by the user.
assert(not game:GetService("RunService"):IsRunning(), "Run in Edit")
local world = workspace.Map.World1.SkippingWorld
local anchor = world.HackedAdminEgg
local originals = {}
for _, part in world:GetDescendants() do
	if part:IsA("BasePart") then
		originals[part] = { part.CFrame, part.Size, part.CanCollide, part.CanTouch, part.CanQuery }
	end
end
local backups = game.ServerStorage:FindFirstChild("WorldBackups") or Instance.new("Folder")
backups.Name = "WorldBackups"
backups.Parent = game.ServerStorage
local backupName = "BeforeVolcanicEggLeft45_20261027"
if not backups:FindFirstChild(backupName) then
	local backup = Instance.new("Folder")
	backup.Name = backupName
	backup.Parent = backups
	for _, name in { "HackedAdminEgg", "VolcanicEggFallback", "VolcanicEggVisual" } do
		local part = world:FindFirstChild(name)
		if part then
			part:Clone().Parent = backup
		end
	end
end
local source = game.ServerScriptService.Server.VolcanicEgg:Clone()
source.Name = "VolcanicEggTurnCheck"
source.Parent = game.ServerScriptService.Server
local egg = require(source)
local before = anchor.CFrame
local changed = egg.turnLeft(workspace.Map.World1)
local after = anchor.CFrame
assert(not egg.turnLeft(workspace.Map.World1), "Turn must not accumulate on refresh")
assert(anchor.CFrame == after, "Repeated turn changed pose")
if changed then
	local delta = before:ToObjectSpace(after)
	local _, yaw = delta:ToOrientation()
	assert(math.abs(math.deg(yaw) - 45) < 0.001, "Expected a 45 degree left yaw")
end
local checked = 0
for part, old in originals do
	assert(part.Size == old[2] and part.Position == old[1].Position, "Position/size changed")
	assert(part.CanCollide == old[3] and part.CanTouch == old[4] and part.CanQuery == old[5], "Collision changed")
	if part ~= anchor and part.Name ~= "VolcanicEggFallback" and part.Name ~= "VolcanicEggVisual" then
		assert(part.CFrame == old[1], "Unrelated object rotated")
	end
	checked += 1
end
source:Destroy()
return { turned = changed, degreesLeft = 45, preservedParts = checked, position = anchor.Position }
