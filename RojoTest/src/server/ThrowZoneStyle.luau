--!strict
-- Warm orange throw zone with a yellow studded checker under the "THROW ZONE" lettering,
-- framed by a darker orange band and a low curb all the way round; the hub path ends at the curb.
-- Only colours and cosmetic overlays change; the apron keeps its size, place and physics.
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Palette = require(script.Parent.LobbyPalette)
local Style = {}
local V = Vector3.new

local VERSION = 3
local CURB_WIDTH, CURB_RISE = 1, 0.18 -- curb top stands this far above the apron
-- LobbyPaths stops the hub path at the curb's outer face.
Style.CurbWidth = CURB_WIDTH

local function studs(parent: BasePart, x0: number, z0: number): Texture
	local t = Instance.new("Texture")
	t.Name, t.Texture, t.Face = "ThrowZoneStuds", Palette.Studs, Enum.NormalId.Top
	t.StudsPerTileU, t.StudsPerTileV = Palette.StudsPerTile, Palette.StudsPerTile
	t.Transparency = Palette.StudsTransparency
	-- Same world phase as the lobby paving.
	t.OffsetStudsU, t.OffsetStudsV = x0 % 8, z0 % 8
	t.Parent = parent
	return t
end

local function tile(
	parent: Instance,
	name: string,
	color: Color3,
	x0: number,
	x1: number,
	y0: number,
	y1: number,
	z0: number,
	z1: number
)
	local p = Instance.new("Part")
	p.Name, p.Color, p.Material = name, color, Enum.Material.Plastic
	p.Size = V(x1 - x0, y1 - y0, z1 - z0)
	p.CFrame = CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	studs(p, x0, z0)
	p.Parent = parent
end

function Style.apply(world: Instance): number
	if world.Name ~= "World1" then
		return 0
	end
	local apron = Refs.apron(world)
	if not apron then
		return 0
	end
	assert(math.abs(apron.CFrame.RightVector.X) > 0.999, "Measure a rotated throwing apron")
	local p, s = apron.Position, apron.Size / 2
	local x0, x1, z0, z1, top = p.X - s.X, p.X + s.X, p.Z - s.Z, p.Z + s.Z, p.Y + s.Y
	apron.Color = Palette.ThrowZone
	for _, t in apron:GetChildren() do
		if t:IsA("Texture") then
			t.Color3 = Palette.ThrowZone
			t.Transparency = Palette.StudsTransparency
			t.OffsetStudsU, t.OffsetStudsV = x0 % 8, z0 % 8
		end
	end
	local owner = apron.Parent :: Instance
	local key = string.format(
		"%d|%s|%s|%s|%.3f|%.3f|%.3f|%.3f|%.3f",
		VERSION,
		tostring(Palette.ThrowZoneChecker),
		tostring(Palette.ThrowZoneEdge),
		tostring(Palette.ThrowZoneCell),
		x0,
		x1,
		z0,
		z1,
		top
	)
	local existing = owner:FindFirstChild("ThrowZoneChecker")
	if existing and existing:GetAttribute("Signature") == key then
		return 0
	end
	local model = Instance.new("Model")
	model.Name = "ThrowZoneChecker"
	-- Overlays sit 0.04 above the apron top and never overlap each other: the checker fills
	-- the inside of the band, the band runs round the edge.
	local band, cell, tiles = Palette.ThrowZoneBand, Palette.ThrowZoneCell, 0
	local i0, i1, k0, k1 = x0 + band, x1 - band, z0 + band, z1 - band
	local y0, y1 = top + 0.03, top + 0.05
	for ix = math.floor(i0 / cell), math.ceil(i1 / cell) - 1 do
		for iz = math.floor(k0 / cell), math.ceil(k1 / cell) - 1 do
			if (ix + iz) % 2 ~= 0 then
				continue
			end
			local a0, a1 = math.max(i0, ix * cell), math.min(i1, (ix + 1) * cell)
			local b0, b1 = math.max(k0, iz * cell), math.min(k1, (iz + 1) * cell)
			if a1 - a0 < 0.01 or b1 - b0 < 0.01 then
				continue
			end
			tile(model, "CheckerTile", Palette.ThrowZoneChecker, a0, a1, y0, y1, b0, b1)
			tiles += 1
		end
	end
	local frame = Instance.new("Model")
	frame.Name = "ThrowZoneFrame"
	tile(frame, "EdgeBand", Palette.ThrowZoneEdge, x0, x1, y0, y1, z0, k0)
	tile(frame, "EdgeBand", Palette.ThrowZoneEdge, x0, x1, y0, y1, k1, z1)
	tile(frame, "EdgeBand", Palette.ThrowZoneEdge, x0, i0, y0, y1, k0, k1)
	tile(frame, "EdgeBand", Palette.ThrowZoneEdge, i1, x1, y0, y1, k0, k1)
	-- The curb stands outside the apron, from the ground to just above its top.
	local c0, c1 = x0 - CURB_WIDTH, x1 + CURB_WIDTH
	local base, rim = p.Y - s.Y, top + CURB_RISE
	tile(frame, "EdgeCurb", Palette.ThrowZoneEdge, c0, c1, base, rim, z0 - CURB_WIDTH, z0)
	tile(frame, "EdgeCurb", Palette.ThrowZoneEdge, c0, x0, base, rim, z0, z1 + CURB_WIDTH)
	tile(frame, "EdgeCurb", Palette.ThrowZoneEdge, x1, c1, base, rim, z0, z1 + CURB_WIDTH)
	tile(frame, "EdgeCurb", Palette.ThrowZoneEdge, x0, x1, base, rim, z1, z1 + CURB_WIDTH)
	frame.Parent = model
	model:SetAttribute("Signature", key)
	model.WorldPivot = apron.CFrame
	if existing then
		existing:Destroy()
	end
	model.Parent = owner
	return tiles
end

return Style
