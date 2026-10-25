-- No player/profile changes. Check safe destinations at real and moved stands.
local Interaction = require(game.ServerScriptService.Server.Gameplay.EggInteraction)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local checked = 0
for _, world in { workspace.Map.World1, workspace.Map.World2 } do
	for _, egg in Config.Eggs do
		local shell = world.SkippingWorld["Egg_" .. egg.id].EggShell
		local destination = Interaction.destination(world, egg.id, 3)
		assert(destination, "No safe destination for " .. world.Name .. "/" .. egg.id)
		local offset = (destination.Position - shell.Position) * Vector3.new(1, 0, 1)
		assert(math.abs(offset.Magnitude - 10) < 0.01, "Destination is not beside the egg")
		checked += 1
	end
end
local fixture = Instance.new("Model")
fixture.Name = "EggDestinationFixture"
local ok, result = pcall(function()
	local scenery = Instance.new("Folder")
	scenery.Name = "SkippingWorld"
	scenery.Parent = fixture
	local stand = Instance.new("Model")
	stand.Name = "Egg_Common"
	stand.Parent = scenery
	local shell = Instance.new("Part")
	shell.Name = "EggShell"
	shell.Anchored = true
	shell.CanCollide = false
	shell.Position = Vector3.new(500, 80, -300)
	shell.Parent = stand
	local floor = Instance.new("Part")
	floor.Anchored = true
	floor.Size = Vector3.new(300, 2, 100)
	floor.Position = Vector3.new(550, 74, -300)
	floor.Parent = fixture
	fixture.Parent = workspace
	local initial = assert(Interaction.destination(fixture, "Common", 3))
	assert(math.abs(initial.Y - 78.1) < 0.01, "Character feet do not clear the floor")
	shell.Position += Vector3.new(100, 0, 0)
	local moved = assert(Interaction.destination(fixture, "Common", 3))
	assert(math.abs(moved.X - initial.X - 100) < 0.01, "Moved stand not tracked")
	assert(not Interaction.destination(fixture, "Missing", 3), "Missing egg accepted")
	floor:Destroy()
	assert(not Interaction.destination(fixture, "Common", 3), "Destination without floor accepted")
	return { eggsChecked = checked, movedStand = "passed", missingEgg = "rejected", missingFloor = "rejected" }
end)
fixture:Destroy()
assert(ok, result)
return result
