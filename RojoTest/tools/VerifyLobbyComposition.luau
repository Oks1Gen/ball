-- Read-only Edit/Server audit of the cleared lobby, activities and main walking routes.
local world = workspace.Map.World1
local lobby = world.Lobby
local refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local allowed = {
	Flowers = true,
	SideTerraces1 = true,
	SideTerraces2 = true,
	RearTerraces = true,
	EntranceTunnel = true,
	CornerWaterfall1 = true,
	SideWaterfall = true,
}
for _, owner in lobby.Environment:GetChildren() do
	assert(allowed[owner.Name], "Loose lobby decoration returned: " .. owner.Name)
end
assert(#lobby.Environment.Flowers:GetChildren() == 0, "Lobby flowers returned")
assert(not lobby.Paths:FindFirstChild("LawnTrees"), "Trees must not be in Paths")
for _, group in lobby.Paths:GetChildren() do
	assert(group:GetAttribute("PathGridVersion") == 2 or group.Name == "KickPathArrows", "Unexpected path object")
end
local source = game.ServerScriptService.Server.LobbyDecorRemoval:Clone()
source.Parent = game.ServerStorage
local ok, plan = pcall(function()
	return require(source).plan(world)
end)
source:Destroy()
assert(ok, plan)
assert(#plan.targets == 0 and #plan.inputs == 0, "Lobby decoration cleanup is not stable")

local function bounds(object)
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	local nodes = object:GetDescendants()
	table.insert(nodes, object)
	for _, p in nodes do
		if p:IsA("BasePart") and p.Transparency < 1 then
			local cf, h = p.CFrame, p.Size / 2
			local radius = Vector3.new(
				math.abs(cf.RightVector.X) * h.X + math.abs(cf.UpVector.X) * h.Y + math.abs(cf.LookVector.X) * h.Z,
				math.abs(cf.RightVector.Y) * h.X + math.abs(cf.UpVector.Y) * h.Y + math.abs(cf.LookVector.Y) * h.Z,
				math.abs(cf.RightVector.Z) * h.X + math.abs(cf.UpVector.Z) * h.Y + math.abs(cf.LookVector.Z) * h.Z
			)
			lo, hi = lo:Min(p.Position - radius), hi:Max(p.Position + radius)
		end
	end
	assert(lo.X < hi.X, "Missing activity geometry")
	return { lo = lo, hi = hi, name = object.Name }
end
local activities = { bounds(lobby.BallShop), bounds(lobby.EggShop) }
for i = 1, 7 do
	table.insert(activities, bounds(refs.training(world)["TrainingLane" .. i]))
end
for i, a in activities do
	for j = i + 1, #activities do
		local b = activities[j]
		assert(
			math.min(a.hi.X, b.hi.X) - math.max(a.lo.X, b.lo.X) < 0.01
				or math.min(a.hi.Z, b.hi.Z) - math.max(a.lo.Z, b.lo.Z) < 0.01,
			"Activity footprints overlap: " .. a.name .. " / " .. b.name
		)
	end
end
local hub = bounds(lobby.Paths.Hub)
local centre = (hub.lo + hub.hi) / 2
local floorY = hub.hi.Y
local routes = {
	{
		Vector3.new(centre.X, floorY, centre.Z),
		Vector3.new(centre.X, floorY, refs.kickZoneFloor(world).Position.Z + 8),
	},
	{ Vector3.new(centre.X, floorY, centre.Z), Vector3.new(centre.X, floorY, bounds(lobby.Paths.EggPlaza).lo.Z + 2) },
	{ Vector3.new(centre.X, floorY, centre.Z), Vector3.new(bounds(lobby.Paths.BallCourt).hi.X - 2, floorY, centre.Z) },
	{
		Vector3.new(centre.X, floorY, centre.Z),
		Vector3.new(bounds(lobby.Paths.TrainingFrame).lo.X + 2, floorY, centre.Z),
	},
}
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { world }
params.RespectCanCollide = true
local probes = 0
for _, route in routes do
	local delta = route[2] - route[1]
	local sideways = Vector3.new(-delta.Z, 0, delta.X).Unit
	local steps = math.ceil(delta.Magnitude / 1.6)
	for n = 0, steps do
		for _, offset in { -1.6, 0, 1.6 } do
			local point = route[1]:Lerp(route[2], n / steps) + sideways * offset
			assert(workspace:Raycast(point + Vector3.new(0, 2, 0), Vector3.new(0, -5, 0), params), "Unsupported route")
			assert(
				not workspace:Raycast(point + Vector3.new(0, 0.8, 0), Vector3.new(0, 6.4, 0), params),
				"Blocked route headroom"
			)
			probes += 1
		end
	end
end
return {
	looseDecor = 0,
	activities = #activities,
	mainRoutes = #routes,
	clearanceProbes = probes,
	halfWidth = 1.6,
	headroom = 6.4,
}
