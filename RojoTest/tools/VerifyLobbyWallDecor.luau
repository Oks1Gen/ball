-- Read-only Edit/Server audit: terrace dressing stays removed after normal startup.
local world = workspace.Map.World1
local module = game.ServerScriptService.Server.LobbyWallDecor:Clone()
module.Parent = game.ServerStorage
local ok, targets = pcall(function()
	return require(module).plan(world)
end)
module:Destroy()
assert(ok, targets)
assert(#targets == 0, "Wall decoration returned")
local environment = world.Lobby.Environment
for _, name in { "CornerWaterfall1", "SideWaterfall" } do
	local waterfall = assert(environment:FindFirstChild(name), "Missing waterfall")
	assert(waterfall:FindFirstChild("StreamWater") and waterfall:FindFirstChild("PoolWater"), "Incomplete waterfall")
	assert(waterfall:FindFirstChild("VFX_Waterfall"), "Missing waterfall VFX")
end
return { remainingDecor = 0, waterfalls = 2 }
