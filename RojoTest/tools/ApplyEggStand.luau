-- Narrow Edit-only placement. The durable template and module arrive through Rojo.
-- Does not execute WorldLayout.prepare or any legacy construction module.
assert(not game:GetService("RunService"):IsRunning(), "Apply in Edit")
local world = workspace.Map.World1
local shop = world.Lobby.EggShop
local storage = game:GetService("ServerStorage")
local backups = storage:FindFirstChild("WorldBackups") or Instance.new("Folder")
backups.Name = "WorldBackups"
backups.Parent = storage
local backup = backups:FindFirstChild("BeforeEggStand_20261103")
if not backup then
	backup = Instance.new("Folder")
	backup.Name = "BeforeEggStand_20261103"
	backup.Parent = backups
	shop:Clone().Parent = backup
end
local source = game.ServerScriptService.Server.EggStandStyle
local fresh = source:Clone()
fresh.Name = "EggStandApply"
fresh.Parent = source.Parent
local ok, count = pcall(function()
	return require(fresh).apply(world)
end)
fresh:Destroy()
assert(ok, tostring(count))
print("Shared egg stand ready: " .. tostring(count) .. " eggs")
