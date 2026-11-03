-- Edit migration: shrink World1 (lobby, training area and the whole course) by 0.8 (2026-11-02).
-- Run once in Edit, then save the place. Every position moves towards ORIGIN — the top of the
-- kick zone's front edge, where the kick happens — and every size shrinks by the same factor,
-- so the layout is unchanged and the kick spot stays where it is. Gameplay keeps its metres:
-- GameConfig.DistancePerStud grows by 1/0.8 in the same change.
-- Material-like detail keeps its size: stud textures (8 studs a tile) and the 4-stud wall
-- checker, which LobbyWalls redraws on the smaller walls. The pre-scale state is the inverse
-- transform (factor 1.25 about the same origin) or Ctrl+Z to "Before world scale".
-- The layout journal's retired visuals in ServerStorage are scaled too: WorldLayout returns them
-- to the world during startup. WorldBackups keep their historical coordinates.
assert(not game:GetService("RunService"):IsRunning(), "Run in Edit")
local world = workspace.Map.World1
assert(world:GetAttribute("WorldScale") == nil, "World1 already scaled")
local K = 0.8
local ORIGIN = Vector3.new(55, 20.6, 124)

local apron = world.Lobby.KickZone.KickZoneFloor
local front = apron.CFrame * Vector3.new(0, apron.Size.Y / 2, -apron.Size.Z / 2)
assert(math.abs(front.Y - ORIGIN.Y) < 0.01 and math.abs(front.Z - ORIGIN.Z) < 0.01, "Throw line moved: remeasure")
assert(math.abs(front.X - ORIGIN.X) < 0.2, "Kick zone moved off the field axis: remeasure")

local function point(p: Vector3): Vector3
	return ORIGIN + (p - ORIGIN) * K
end
local function frame(cf: CFrame): CFrame
	return cf.Rotation + point(cf.Position)
end
local function scaleLocal(cf: CFrame): CFrame
	return cf.Rotation + cf.Position * K
end
local function sequence(s: NumberSequence): NumberSequence
	local keys = {}
	for _, key in s.Keypoints do
		table.insert(keys, NumberSequenceKeypoint.new(key.Time, key.Value * K, key.Envelope * K))
	end
	return NumberSequence.new(keys)
end

-- Attributes the game reads as geometry. "Before*" attributes are history and stay as recorded.
local WORLD_FRAMES = { DisplayBasePivot = true, MossSupportFrame = true, SnowSupportFrame = true, MapPivot = true }
local WORLD_POINTS = { DisplayLabelBase = true }
local LOCAL_FRAMES = { DisplayBaseLocal = true }
local LOCAL_VECTORS = { DisplayLabelLocal = true, MossSupportSize = true, SnowSupportSize = true }
local LENGTHS = { DisplayDiameter = true, LaneLength = true }
local WORLD_HEIGHTS = { CrestWorldY = true }

local function attributes(item: Instance)
	for name, value in item:GetAttributes() do
		if WORLD_FRAMES[name] and typeof(value) == "CFrame" then
			item:SetAttribute(name, frame(value))
		elseif WORLD_POINTS[name] and typeof(value) == "Vector3" then
			item:SetAttribute(name, point(value))
		elseif LOCAL_FRAMES[name] and typeof(value) == "CFrame" then
			item:SetAttribute(name, scaleLocal(value))
		elseif
			(LOCAL_VECTORS[name] and typeof(value) == "Vector3") or (LENGTHS[name] and typeof(value) == "number")
		then
			item:SetAttribute(name, value * K)
		elseif WORLD_HEIGHTS[name] and typeof(value) == "number" then
			item:SetAttribute(name, ORIGIN.Y + (value - ORIGIN.Y) * K)
		end
	end
end

local roots = { world }
local journal = game.ServerStorage:FindFirstChild("WorldLayoutState")
journal = journal and journal:FindFirstChild(world.Name)
if journal then
	table.insert(roots, journal)
end

game:GetService("ChangeHistoryService"):SetWaypoint("Before world scale")
local counts = { parts = 0, models = 0, other = 0 }
for _, root in roots do
	local items = root:GetDescendants()
	-- Pivots first: a model whose pivot was never set follows its parts.
	local pivots = {}
	for _, item in items do
		if item:IsA("Model") then
			pivots[item] = item:GetPivot()
		end
	end
	for i, item in items do
		if i % 2000 == 0 then
			task.wait()
		end
		attributes(item)
		if item:IsA("BasePart") then
			local cf = item.CFrame
			item.Size *= K
			item.CFrame = frame(cf)
			counts.parts += 1
		elseif item:IsA("Attachment") then
			item.CFrame = scaleLocal(item.CFrame)
			counts.other += 1
		elseif item:IsA("Beam") then
			item.Width0, item.Width1 = item.Width0 * K, item.Width1 * K
			item.CurveSize0, item.CurveSize1 = item.CurveSize0 * K, item.CurveSize1 * K
			if item.TextureMode ~= Enum.TextureMode.Stretch then
				item.TextureLength *= K
			end
			counts.other += 1
		elseif item:IsA("ParticleEmitter") then
			item.Size = sequence(item.Size)
			item.Speed = NumberRange.new(item.Speed.Min * K, item.Speed.Max * K)
			item.Acceleration *= K
			counts.other += 1
		elseif item:IsA("Light") then
			item.Range *= K
			counts.other += 1
		elseif item:IsA("BillboardGui") then
			local s = item.Size
			item.Size = UDim2.new(s.X.Scale * K, s.X.Offset, s.Y.Scale * K, s.Y.Offset)
			item.StudsOffset *= K
			item.StudsOffsetWorldSpace *= K
			item.ExtentsOffset *= K
			item.ExtentsOffsetWorldSpace *= K
			counts.other += 1
		end
	end
	for model, pivot in pivots do
		model.WorldPivot = frame(pivot)
		counts.models += 1
	end
end
attributes(world)

-- Route description of the course: front edge stays at the throw line.
local first, last = world.FootballCourse.Zones.Zone01.Field, world.FootballCourse.Zones.Zone08.Field
local routeFront = first.Position.Z + first.Size.Z / 2
local routeEnd = last.Position.Z - last.Size.Z / 2
world:SetAttribute("RouteFrontZ", routeFront)
world:SetAttribute("RouteEndZ", routeEnd)
world:SetAttribute("RouteLengthStuds", routeFront - routeEnd)
world:SetAttribute("BiomeLengthStuds", first.Size.Z)
world:SetAttribute("WorldScale", K)
world:SetAttribute("WorldScaleOrigin", ORIGIN)
world:SetAttribute("WorldScaled", "2026-11-02")

-- Redraw the cosmetic layers from the scaled geometry. Fresh copies of the modules and the
-- palette they share bypass Studio's require cache from earlier Edit runs.
local server = game.ServerScriptService.Server
local fresh = Instance.new("Folder")
fresh.Name = "WorldScaleMigration"
for _, name in { "LobbyPalette", "LobbyPathRegions", "LobbyWallCoverage", "LobbyWalls", "LobbyPaths", "KickZoneStyle" } do
	server[name]:Clone().Parent = fresh
end
fresh.Parent = game.ServerScriptService
local results = {}
local ok, problem = pcall(function()
	for _, name in { "LobbyWalls", "KickZoneStyle", "LobbyPaths" } do
		results[name] = require(fresh[name]).apply(world)
	end
end)
fresh:Destroy()
assert(ok, problem)

game:GetService("ChangeHistoryService"):SetWaypoint("After world scale")
return string.format(
	"scaled %d parts, %d models, %d other; route %.1f studs (%.1f..%.1f); walls rebuilt=%s, paving regions %s, throw tiles %s",
	counts.parts,
	counts.models,
	counts.other,
	routeFront - routeEnd,
	routeFront,
	routeEnd,
	tostring(type(results.LobbyWalls) == "table" and results.LobbyWalls.rebuilt),
	tostring(results.LobbyPaths),
	tostring(results.KickZoneStyle)
)
