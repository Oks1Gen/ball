--!strict
-- Hub path network: a square in the middle of the lobby (the spawn) and one path from it to
-- each activity — the throw zone, a frame around all training lanes, the ball stand, and the
-- egg plaza in front of the leaderboards at the back wall. Rationale: docs/lobby-paths.md.
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local Regions = require(script.Parent.LobbyPathRegions)
local Palette = require(script.Parent.LobbyPalette)
local ThrowZone = require(script.Parent.ThrowZoneStyle)
local Hub = {}
local V, P = Vector3.new, Vector2.new

local VERSION = "lobby-hub-5"
-- Layout numbers are in the authored (unscaled) lobby and map through Shared.WorldScale like the
-- rest of the scene. Paving trim (curbs, checker cells, studs, the 0.26 rise) keeps its size,
-- like a material.
local HUB = { x0 = 41, x1 = 69, z0 = 200, z1 = 228 } -- 28 x 28, centred on the field axis X 55
local SPINE = { x0 = 46, x1 = 64 } -- throw zone and north paths
local SIDE = { z0 = 205, z1 = 223 } -- ball stand and training paths
local FRAME_FRONT = 6 -- path in front of the lane entrances
local FRAME_MARGIN = 4 -- path around the other lane sides
local BALL_COURT_WIDTH = 16.4
local BALL_COURT_MARGIN = 3 -- past either end of the ball stand
-- Scrolling arrows on the throw zone path: a Beam authored with VfxForgeUltra, kept in the
-- scene; this module only stretches it along the current path.
local ARROWS = "VFX_ThrowPathArrows"
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

local function marking(parent: Instance, a: Vector2, b: Vector2, width: number, y: number)
	local start, finish = V(a.X, y, a.Y), V(b.X, y, b.Y)
	local p = Instance.new("Part")
	p.Name = "PathMarking"
	p.Size = V(width, 0.03, (finish - start).Magnitude)
	p.CFrame = CFrame.lookAt((start + finish) / 2, finish)
	p.Color, p.Material = Palette.PathArrow, Enum.Material.SmoothPlastic
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
end

function Hub.apply(world: Instance): number
	if world.Name ~= "World1" then
		return 0
	end
	local lobby = world:FindFirstChild("Lobby")
	local paths = lobby and lobby:FindFirstChild("Paths")
	local lanes = Refs.training(world)
	local apron = Refs.apron(world)
	local shop = Refs.balls(world)
	local eggs = Refs.eggs(world)
	local spawn = Refs.spawn(world)
	local boards = Refs.rankings(world)
	if not paths or not lanes or not apron or not shop or not eggs or not spawn or not boards then
		return 0
	end
	assert(math.abs(apron.CFrame.RightVector.X) > 0.999, "Measure a rotated throwing apron")
	-- The apron stands on the lawn: paving rises 0.26 above its base.
	local top = apron.Position.Y - apron.Size.Y / 2 + 0.26
	-- The throw zone curb frames the apron; the path stops at its outer face.
	local apronEdge = apron.Position.Z + apron.Size.Z / 2 + ThrowZone.CurbWidth
	local k = Scale.factor(world)
	local c0, c1 = Scale.point(world, V(HUB.x0, 0, HUB.z0)), Scale.point(world, V(HUB.x1, 0, HUB.z1))
	local hub = { x0 = c0.X, x1 = c1.X, z0 = c0.Z, z1 = c1.Z }
	c0, c1 = Scale.point(world, V(SPINE.x0, 0, SIDE.z0)), Scale.point(world, V(SPINE.x1, 0, SIDE.z1))
	local spine = { x0 = c0.X, x1 = c1.X }
	local side = { z0 = c0.Z, z1 = c1.Z }
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
		x0 = math.floor(boardX0) - PLAZA_SIDE * k,
		x1 = math.ceil(boardX1) + PLAZA_SIDE * k,
		z0 = math.floor(eggLow) - PLAZA_FRONT * k,
		z1 = boardFront,
	}
	assert(plaza.z0 > hub.z1 and plaza.x0 < spine.x0 and plaza.x1 > spine.x1, "Egg plaza must face the hub")

	add("Hub", hub.x0, hub.x1, hub.z0, hub.z1)
	add("ThrowZonePath", spine.x0, spine.x1, apronEdge, hub.z0, { openZ = apronEdge })
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
	local frameX = (front :: number) - FRAME_FRONT * k
	assert(frameX > hub.x1, "Training lanes moved into the hub")
	add("TrainingPath", hub.x1, frameX, side.z0, side.z1)
	for i, f in footprints do
		local low = if i == 1 then f[3] - FRAME_MARGIN * k else (footprints[i - 1][4] + f[3]) / 2
		local high = if i == 7 then f[4] + FRAME_MARGIN * k else (f[4] + footprints[i + 1][3]) / 2
		local back = f[2] + FRAME_MARGIN * k
		local frame = { group = "TrainingFrame" }
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
	local ballX1 = shopFront + BALL_COURT_WIDTH * k
	assert(ballX1 < hub.x0, "Ball stand moved into the hub")
	add(
		"BallCourt",
		shopBack - FRAME_MARGIN * k,
		ballX1,
		math.floor(shopLow - BALL_COURT_MARGIN * k),
		math.ceil(shopHigh + BALL_COURT_MARGIN * k)
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
	-- Arrows run from the hub (Attachment0) to the throw zone (Attachment1); a positive
	-- TextureSpeed scrolls them that way. They float clear of the checker overlay (+0.08).
	local arrows = paths:FindFirstChild(ARROWS)
	if arrows and arrows:IsA("BasePart") then
		local from, to = hub.z0 - ARROW_END_INSET, apronEdge + ARROW_END_INSET
		arrows.CFrame = CFrame.new((spine.x0 + spine.x1) / 2, top + 0.15, (from + to) / 2)
		local start, finish = arrows:FindFirstChild("Start"), arrows:FindFirstChild("Finish")
		if start and finish and start:IsA("Attachment") and finish:IsA("Attachment") then
			start.Position, finish.Position = V(0, 0, (from - to) / 2), V(0, 0, (to - from) / 2)
		end
	end
	if paths:GetAttribute("HubLayout") == key then
		return 0
	end

	-- Stage the replacement before touching the existing cosmetic layer.
	local staging = Instance.new("Folder")
	Regions.build(staging, regions, top, selected)
	local markY = top + 0.095
	local hubModel = staging:FindFirstChild("Hub")
	if hubModel then
		-- A square frame marks the centre of the map.
		local inset = 3 * k
		local a, b = P(hub.x0 + inset, hub.z0 + inset), P(hub.x1 - inset, hub.z1 - inset)
		local corners = { a, P(b.X, a.Y), b, P(a.X, b.Y) }
		for i, c in corners do
			local d = corners[i % 4 + 1]
			local along = (d - c).Unit
			marking(hubModel, c - along * 0.6, d + along * 0.6, 1.2, markY)
		end
	end
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
