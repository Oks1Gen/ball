--!strict
-- Hub path network: a square in the middle of the lobby (the spawn) and one path from it to
-- each activity — the kick zone, a frame around all training lanes, the ball stand, and the
-- egg plaza in front of the leaderboards at the back wall. Rationale: docs/lobby-paths.md.
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local Regions = require(script.Parent.LobbyPathRegions)
local Palette = require(script.Parent.LobbyPalette)
local KickZone = require(script.Parent.KickZoneStyle)
local Hub = {}
local V, P = Vector3.new, Vector2.new

local VERSION = "lobby-hub-grid-9"
-- Layout numbers are in the authored (unscaled) lobby and map through Shared.WorldScale like the
-- rest of the scene. Paving trim (curbs, checker cells, studs, the 0.26 rise) keeps its size,
-- like a material.
local HUB = { x0 = 39, x1 = 71, z0 = 198, z1 = 230 } -- 32 x 32, centred on the field axis X 55
local SPINE = { x0 = 47, x1 = 63 } -- kick zone and north paths
local SIDE = { z0 = 206, z1 = 222 } -- ball stand and training paths
local FRAME_FRONT = 6 -- path in front of the lane entrances
local FRAME_MARGIN = 4 -- path around the other lane sides
local BALL_COURT_WIDTH = 16.4
local BALL_COURT_MARGIN = 3 -- past either end of the ball stand
-- Flat vector chevrons scroll from the hub to the kick zone.
local ARROW_END_INSET = 2 -- arrows fade out this far before either end of the path
local PLAZA_SIDE = 2 -- egg plaza past the outer leaderboards
local PLAZA_FRONT = 6 -- egg plaza in front of the front-most egg
-- Replaced layers: the old boulevard, the removed portal, per-lane approaches and the compact
-- lobby's trophy plaza, leaderboard walks and egg courts.
local RETIRED = {
	Boulevard = true,
	PortalCourt = true,
	PortalPath = true,
	BallPath = true,
	BallCourtEntry = true,
	BallCourt = true,
	EggCourt = true,
	EggCourtBack = true,
	TrophyPlaza = true,
	HallWalkWest = true,
	HallWalkEast = true,
}

local function rectangle(x0: number, x1: number, z0: number, z1: number): { Vector2 }
	return { P(x0, z0), P(x1, z0), P(x1, z1), P(x0, z1) }
end

-- World-space X/Z extents of every visible part of a model.
local function extents(model: Instance): (number, number, number, number)
	local x0, x1, z0, z1 = math.huge, -math.huge, math.huge, -math.huge
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 then
			local cf, s = p.CFrame, p.Size / 2
			local ex = math.abs(cf.RightVector.X) * s.X
				+ math.abs(cf.UpVector.X) * s.Y
				+ math.abs(cf.LookVector.X) * s.Z
			local ez = math.abs(cf.RightVector.Z) * s.X
				+ math.abs(cf.UpVector.Z) * s.Y
				+ math.abs(cf.LookVector.Z) * s.Z
			x0, x1 = math.min(x0, p.Position.X - ex), math.max(x1, p.Position.X + ex)
			z0, z1 = math.min(z0, p.Position.Z - ez), math.max(z1, p.Position.Z + ez)
		end
	end
	return x0, x1, z0, z1
end

function Hub.apply(world: Instance): number
	if world.Name ~= "World1" then
		return 0
	end
	local lobby = world:FindFirstChild("Lobby")
	local paths = lobby and lobby:FindFirstChild("Paths")
	local lanes = Refs.training(world)
	local apron = Refs.kickZoneFloor(world)
	local shop = Refs.balls(world)
	local eggs = Refs.eggs(world)
	local spawn = Refs.spawn(world)
	local boards = Refs.rankings(world)
	if not paths or not lanes or not apron or not shop or not eggs or not spawn or not boards then
		return 0
	end
	assert(math.abs(apron.CFrame.RightVector.X) > 0.999, "Measure a rotated Kick Zone floor")
	-- The apron stands on the lawn: paving rises 0.26 above its base.
	local top = apron.Position.Y - apron.Size.Y / 2 + 0.26
	-- The kick zone curb frames the apron; the path stops at its outer face.
	local apronEdge = apron.Position.Z + apron.Size.Z / 2 + KickZone.CurbWidth
	local k = Scale.factor(world)
	local c0, c1 = Scale.point(world, V(HUB.x0, 0, HUB.z0)), Scale.point(world, V(HUB.x1, 0, HUB.z1))
	local hub = { x0 = c0.X, x1 = c1.X, z0 = c0.Z, z1 = c1.Z }
	c0, c1 = Scale.point(world, V(SPINE.x0, 0, SIDE.z0)), Scale.point(world, V(SPINE.x1, 0, SIDE.z1))
	local spine = { x0 = c0.X, x1 = c1.X }
	local side = { z0 = c0.Z, z1 = c1.Z }
	local gridOrigin = P(hub.x0, hub.z0)
	local cell = 6.4
	local function down(value: number, axis: number): number
		return axis + math.floor((value - axis) / cell + 0.0001) * cell
	end
	local function up(value: number, axis: number): number
		return axis + math.ceil((value - axis) / cell - 0.0001) * cell
	end

	local regions: { any } = {}
	local selected: { [string]: boolean } = {}
	local function add(name: string, x0: number, x1: number, z0: number, z1: number, extra: { [string]: any }?)
		assert(x1 - x0 > 0.01 and z1 - z0 > 0.01, "Empty lobby path " .. name)
		local region: any = { name = name, polygon = rectangle(x0, x1, z0, z1) }
		local fields: { [string]: any } = extra or {}
		for key, value in pairs(fields) do
			region[key] = value
		end
		selected[name] = true
		table.insert(regions, region)
	end

	-- Eggs: one plaza from the front-most egg back to the leaderboards along the rear wall.
	local boardX0, boardX1, boardFront = extents(boards)
	local eggLow = math.huge
	for _, egg in eggs:GetChildren() do
		if egg:IsA("Model") and (egg.Name:match("^Egg_") or egg.Name == "VolcanicEgg") then
			local _, _, z0 = extents(egg)
			eggLow = math.min(eggLow, z0)
		end
	end
	local plaza = {
		x0 = down(math.floor(boardX0) - PLAZA_SIDE * k, gridOrigin.X),
		x1 = up(math.ceil(boardX1) + PLAZA_SIDE * k, gridOrigin.X),
		z0 = down(math.floor(eggLow) - PLAZA_FRONT * k, gridOrigin.Y),
		z1 = up(boardFront, gridOrigin.Y),
	}
	assert(plaza.z0 > hub.z1 and plaza.x0 < spine.x0 and plaza.x1 > spine.x1, "Egg plaza must face the hub")

	add("Hub", hub.x0, hub.x1, hub.z0, hub.z1)
	local throwStart = up(apronEdge, gridOrigin.Y)
	add("KickZonePath", spine.x0, spine.x1, throwStart, hub.z0, { openZ = apronEdge })
	add(
		"KickZoneThreshold",
		spine.x0,
		spine.x1,
		apronEdge,
		throwStart,
		{ group = "KickZonePath", plain = true, openZ = apronEdge }
	)
	add("NorthPath", spine.x0, spine.x1, hub.z1, plaza.z0)
	add("EggPlaza", plaza.x0, plaza.x1, plaza.z0, plaza.z1)

	-- Training: a path to the lane entrances and a frame around every lane.
	local footprints = {}
	local front: number? = nil
	for i = 1, 7 do
		local lane = assert(lanes:FindFirstChild("TrainingLane" .. i), "Missing training lane")
		local foundation = lane:FindFirstChild("Foundation")
		assert(foundation and foundation:IsA("BasePart"), "Missing training foundation")
		assert(math.abs(foundation.CFrame.RightVector.X) > 0.999, "Measure rotated training lanes before rebuilding")
		local p, s = foundation.Position, foundation.Size / 2
		footprints[i] = { p.X - s.X, p.X + s.X, p.Z - s.Z, p.Z + s.Z }
		front = front or footprints[i][1]
		assert(math.abs(footprints[i][1] - (front :: number)) < 0.01, "Lane entrances must stay in one row")
		-- Lanes are not paved; their edges count as covered so no curb runs along them.
		table.insert(regions, { name = "Lane" .. i, polygon = rectangle(p.X - s.X, p.X + s.X, p.Z - s.Z, p.Z + s.Z) })
	end
	local frameX = down((front :: number) - FRAME_FRONT * k, gridOrigin.X)
	assert(frameX > hub.x1, "Training lanes moved into the hub")
	add("TrainingPath", hub.x1, frameX, side.z0, side.z1)
	for i, f in footprints do
		local low = if i == 1 then f[3] - FRAME_MARGIN * k else (footprints[i - 1][4] + f[3]) / 2
		local high = if i == 7 then f[4] + FRAME_MARGIN * k else (f[4] + footprints[i + 1][3]) / 2
		local back = f[2] + FRAME_MARGIN * k
		local frame = { group = "TrainingFrame", plain = true }
		add("TrainingFrame" .. i .. "Front", frameX, f[1], low, high, frame)
		add("TrainingFrame" .. i .. "End", f[2], back, f[3], f[4], frame)
		if f[3] - low > 0.01 then
			add("TrainingFrame" .. i .. "Low", f[1], back, low, f[3], frame)
		end
		if high - f[4] > 0.01 then
			add("TrainingFrame" .. i .. "High", f[1], back, f[4], high, frame)
		end
	end

	-- Ball stand: like a training lane, the stand stands on paving that runs past its back and
	-- ends, with a court along its front and a path back to the hub.
	local shopBack, shopFront, shopLow, shopHigh = extents(shop)
	local ballX1 = up(shopFront + BALL_COURT_WIDTH * k, gridOrigin.X)
	assert(ballX1 < hub.x0, "Ball stand moved into the hub")
	add(
		"BallCourt",
		down(shopBack - FRAME_MARGIN * k, gridOrigin.X),
		ballX1,
		down(math.floor(shopLow - BALL_COURT_MARGIN * k), gridOrigin.Y),
		up(math.ceil(shopHigh + BALL_COURT_MARGIN * k), gridOrigin.Y)
	)
	add("BallShopPath", ballX1, hub.x0, side.z0, side.z1)

	-- Rectangles may touch but never overlap: overlapping paving fights for the same pixels.
	for i, a in regions do
		for j = i + 1, #regions do
			local b = regions[j]
			local a0, a1, b0, b1 = a.polygon[1], a.polygon[3], b.polygon[1], b.polygon[3]
			local overlapX = math.min(a1.X, b1.X) - math.max(a0.X, b0.X)
			local overlapZ = math.min(a1.Y, b1.Y) - math.max(a0.Y, b0.Y)
			assert(overlapX < 0.01 or overlapZ < 0.01, "Lobby paths overlap: " .. a.name .. " / " .. b.name)
		end
	end

	local signature = { VERSION, tostring(Palette.Path), tostring(Palette.PathChecker), tostring(Palette.PathArrow) }
	for _, region in regions do
		local lo, hi = region.polygon[1], region.polygon[3]
		table.insert(signature, string.format("%s:%.3f:%.3f:%.3f:%.3f:%.3f", region.name, lo.X, hi.X, lo.Y, hi.Y, top))
	end
	table.sort(signature)
	local key = table.concat(signature, "|")
	-- The spawn stands in the hub, so every player starts in the centre of the map.
	local centre = V((hub.x0 + hub.x1) / 2, spawn.Position.Y, (hub.z0 + hub.z1) / 2)
	if (spawn.Position - centre).Magnitude > 0.001 then
		spawn.CFrame = CFrame.new(centre) * spawn.CFrame.Rotation
	end
	local from, to = hub.z0 - ARROW_END_INSET, apronEdge + ARROW_END_INSET
	require(script.Parent.LobbyPathArrows).apply(
		paths,
		V((spine.x0 + spine.x1) / 2, top + 0.08, from),
		V((spine.x0 + spine.x1) / 2, top + 0.08, to)
	)

	if paths:GetAttribute("HubLayout") == key then
		-- Earlier legacy palette passes know only one paving colour. Restore
		-- the final checker and edge style without rebuilding geometry.
		for _, group in paths:GetChildren() do
			if group:GetAttribute("PathGridVersion") == 2 then
				for _, p in group:GetChildren() do
					if p:IsA("BasePart") then
						if p:GetAttribute("CheckerCell") then
							local parity = ((p:GetAttribute("GridX") :: number) + (p:GetAttribute("GridZ") :: number))
								% 2
							p.Color = if parity == 0 then Palette.PathChecker else Palette.Path
						else
							p.Color = if p.Name == "PathCurb" then Palette.PathEdge else Palette.Path
						end
						local texture = p:FindFirstChild("PathStuds")
						if texture and texture:IsA("Texture") then
							texture.OffsetStudsU, texture.OffsetStudsV = 0, 0
							texture.StudsPerTileU, texture.StudsPerTileV = 6.4, 6.4
							texture.Texture, texture.Transparency = Palette.Studs, Palette.StudsTransparency
						end
					end
				end
			end
		end
		return 0
	end

	-- Stage the replacement before touching the existing cosmetic layer.
	local staging = Instance.new("Folder")
	Regions.build(staging, regions, top, selected, gridOrigin)
	for _, group in staging:GetChildren() do
		group:SetAttribute("HubPath", true)
	end
	for _, group in paths:GetChildren() do
		if group:GetAttribute("HubPath") or RETIRED[group.Name] or group.Name:match("^TrainingApproach%d+$") then
			group:Destroy()
		end
	end
	for _, group in staging:GetChildren() do
		group.Parent = paths
	end
	staging:Destroy()
	paths:SetAttribute("TrainingApproachLayout", nil)
	paths:SetAttribute("HubLayout", key)
	return #regions
end

return Hub
