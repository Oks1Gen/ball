-- No player/profile changes. Check moved stands and isolation between worlds.
local Interaction = require(game.ServerScriptService.Server.Gameplay.EggInteraction)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local worlds = { workspace.ProgressionMap, workspace.World2Map }
local checked = 0
for _, world in worlds do
	for _, egg in Config.Eggs do
		local shell = world.SkippingWorld["Egg_" .. egg.id].EggShell
		assert(Interaction.inRange(world, egg.id, shell.Position + Vector3.new(0, -3, 5)))
		assert(Interaction.inRange(world, egg.id, shell.Position + Vector3.new(19, 0, 0)))
		assert(not Interaction.inRange(world, egg.id, shell.Position + Vector3.new(19.1, 0, 0)))
		assert(not Interaction.inRange(world, egg.id, nil))
		local other = world == worlds[1] and worlds[2] or worlds[1]
		assert(not Interaction.inRange(other, egg.id, shell.Position), "Wrong-world egg accepted")
		checked += 1
	end
end
local moved = Instance.new("Folder")
local scenery = Instance.new("Folder")
scenery.Name = "SkippingWorld"
scenery.Parent = moved
local stand = Instance.new("Model")
stand.Name = "Egg_Common"
stand.Parent = scenery
local shell = Instance.new("Part")
shell.Name = "EggShell"
shell.Position = Vector3.new(500, 80, -300)
shell.Parent = stand
assert(Interaction.inRange(moved, "Common", shell.Position))
shell.Position += Vector3.new(100, 0, 0)
assert(Interaction.inRange(moved, "Common", shell.Position), "Moved shell not tracked")
assert(not Interaction.inRange(moved, "Common", Vector3.new(500, 80, -300)))
assert(not Interaction.inRange(moved, "Missing", shell.Position))
moved:Destroy()
return { eggsChecked = checked, movedStand = "passed", distanceLimit = 19, worldsIsolated = true }
