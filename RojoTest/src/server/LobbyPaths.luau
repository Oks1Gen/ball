--!strict
-- Light checker paving, a symmetrical boulevard and paths to authored entrances.
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Regions = require(script.Parent.LobbyPathRegions)
local Palette = require(script.Parent.LobbyPalette)
local Approaches = {}
local P = Vector2.new

local function rectangle(x0: number, x1: number, z0: number, z1: number): { Vector2 }
	return { P(x0, z0), P(x1, z0), P(x1, z1), P(x0, z1) }
end

function Approaches.apply(world: Instance): number
	if world.Name ~= "World1" then
		return 0
	end
	local lobby = world:FindFirstChild("Lobby")
	local paths = lobby and lobby:FindFirstChild("Paths")
	local lanes = Refs.training(world)
	if not paths or not lanes then
		return 0
	end
	local boulevard = paths:FindFirstChild("Boulevard")
	local road = boulevard and boulevard:FindFirstChild("PavingSurface")
	assert(road and road:IsA("BasePart"), "Missing boulevard paving")
	local halfWidth = 19 -- Twice the original width; preserve the authored centre.
	local left, edge = road.Position.X - halfWidth, road.Position.X + halfWidth
	local roadMinZ, roadMaxZ = road.Position.Z - road.Size.Z / 2, road.Position.Z + road.Size.Z / 2
	local top = road.Position.Y + road.Size.Y / 2
	local regions = {}
	local selected: { [string]: boolean } = { Boulevard = true }
	local signature = {
		"lobby-paths-checker-2",
		tostring(Palette.Path),
		tostring(Palette.PathChecker),
		tostring(Palette.PathCheckerCell),
	}
	for _, group in paths:GetChildren() do
		if not group.Name:match("^TrainingApproach%d+$") then
			local surface = group:FindFirstChild("PavingSurface")
			if surface and surface:IsA("BasePart") then
				local p, s = surface.Position, surface.Size / 2
				local x0, x1, z0, z1 = p.X - s.X, p.X + s.X, p.Z - s.Z, p.Z + s.Z
				if group.Name == "Boulevard" then
					x0, x1 = left, edge
				elseif z0 < roadMaxZ - 0.001 and z1 > roadMinZ + 0.001 and x1 > left and x0 < left then
					-- Shorten western branches/courts to the new edge, rather than
					-- stacking their surfaces under the wider boulevard.
					assert(z0 >= roadMinZ and z1 <= roadMaxZ, "Measure partially overlapping lobby paving")
					x1 = left
				end
				selected[group.Name] = true
				table.insert(regions, {
					name = group.Name,
					polygon = rectangle(x0, x1, z0, z1),
					openZ = if group.Name == "Boulevard" then p.Z - s.Z else nil,
				})
			end
		end
	end
	for i = 1, 7 do
		local lane = assert(lanes:FindFirstChild("TrainingLane" .. i))
		local foundation = lane:FindFirstChild("Foundation")
		local pad = lane:FindFirstChild("StartingPad")
		assert(foundation and foundation:IsA("BasePart") and pad and pad:IsA("BasePart"), "Missing training entrance")
		assert(
			math.abs(foundation.CFrame.RightVector.X) > 0.999,
			"Measure rotated training approaches before rebuilding"
		)
		local front = foundation.Position.X - foundation.Size.X / 2
		assert(front > edge and pad.Position.X < foundation.Position.X, "Training entrance must face the boulevard")
		local name = "TrainingApproach" .. i
		selected[name] = true
		table.insert(regions, {
			name = name,
			polygon = rectangle(edge, front, pad.Position.Z - 6.5, pad.Position.Z + 6.5),
			openX = front,
		})
	end
	-- The original portal court overlaps the ball court by 9.5 x 5 studs.
	-- Preserve their union as two touching ball-court rectangles.
	local portal, ball
	for _, region in regions do
		if region.name == "PortalCourt" then
			portal = region
		end
		if region.name == "BallCourt" then
			ball = region
		end
	end
	if portal and ball then
		local p0, p1 = portal.polygon[1], portal.polygon[3]
		local b0, b1 = ball.polygon[1], ball.polygon[3]
		if b0.X < p1.X and b1.X > p1.X and b0.Y < p1.Y and b1.Y > p1.Y and b0.Y >= p0.Y then
			ball.polygon = rectangle(b0.X, b1.X, p1.Y, b1.Y)
			selected.BallCourtEntry = true
			table.insert(regions, { name = "BallCourtEntry", polygon = rectangle(p1.X, b1.X, b0.Y, p1.Y) })
		end
	end
	for _, region in regions do
		local lo, hi = region.polygon[1], region.polygon[3]
		table.insert(signature, string.format("%s:%.4f:%.4f:%.4f:%.4f:%.4f", region.name, lo.X, hi.X, lo.Y, hi.Y, top))
	end
	table.sort(signature)
	local key = table.concat(signature, "|")
	if paths:GetAttribute("TrainingApproachLayout") == key then
		return 0
	end
	-- Stage the small replacement before touching the existing cosmetic layer.
	local staging = Instance.new("Folder")
	Regions.build(staging, regions, top, selected)
	for _, group in paths:GetChildren() do
		if selected[group.Name] then
			group:Destroy()
		end
	end
	for _, group in staging:GetChildren() do
		group.Parent = paths
	end
	staging:Destroy()
	paths:SetAttribute("TrainingApproachLayout", key)
	return 7
end

return Approaches
