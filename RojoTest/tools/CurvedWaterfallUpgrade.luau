-- Edit migration: wide curved lobby waterfall (2026-11-01). Run once in Edit, then save the place.
-- The water used to fall in a narrow slot between two rock walls that stood 28 studs out from the
-- top terrace. Now a 28-stud sheet leaves the top terrace lip and arcs over the lower ledges into
-- a pool at the foot of the cliff; the rock walls, gorge back and stone channel are gone.
-- Removed parts go to ServerStorage.WorldBackups.BeforeCurvedWaterfall_20261101; reused VFX parts
-- keep their previous Size/CFrame in BeforeCurvedWaterfall* attributes.
-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
local map = workspace.Map.World1
local fall = map.SpawnGarden.CornerWaterfall1
assert(fall:GetAttribute("FullWaterfall"), "Run FullWaterfallUpgrade first")
assert(not fall:GetAttribute("CurvedWaterfall"), "Waterfall already curved")
local V, RGB = Vector3.new, Color3.fromRGB
local X = 67.5
local WIDTH = 28
local LIP = V(X, 83.3, 333.4) -- top terrace grass is at Y 83, its face at Z 334
local FOOT = V(X, 20.8, 311) -- ground is at Y 20, the first terrace face at Z 316
local STONE = RGB(135, 151, 157)
local WATER = RGB(40, 209, 226)
local STUDS = "rbxassetid://88156646156237"
game:GetService("ChangeHistoryService"):SetWaypoint("Before curved waterfall")

local backups = game.ServerStorage:FindFirstChild("WorldBackups") or Instance.new("Folder")
backups.Name, backups.Parent = "WorldBackups", game.ServerStorage
local backup = Instance.new("Folder")
backup.Name, backup.Parent = "BeforeCurvedWaterfall_20261101", backups

local renders = {}
for _, render in map.SurfaceSeparation:GetChildren() do
	local link = render:FindFirstChild("OriginalPart")
	if link and link.Value then
		renders[link.Value] = renders[link.Value] or {}
		table.insert(renders[link.Value], render)
	end
end
local retiredIds = {}
for id in string.gmatch(map.SurfaceSeparation:GetAttribute("RetiredRecordIds") or "", "%d+") do
	table.insert(retiredIds, id)
end
local function retire(item, reason)
	local link = Instance.new("ObjectValue")
	link.Name, link.Value = "WaterfallOriginalParent", item.Parent
	item:SetAttribute("WaterfallOriginalPath", item:GetFullName())
	item:SetAttribute("WaterfallReason", reason)
	local parts = item:IsA("BasePart") and { item } or {}
	for _, d in item:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	for _, p in parts do
		local id = p:GetAttribute("SurfaceSeparationId")
		if id then
			table.insert(retiredIds, tostring(id))
		end
		for _, r in renders[p] or {} do
			r.Parent = item
		end
	end
	item.Parent = backup
	link.Parent = item
end
local function part(name, size, position, color, material)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, CFrame.new(position), color
	p.Material = material or Enum.Material.Plastic
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = fall
	return p
end
local function studs(p, faces)
	for _, face in faces do
		local t = Instance.new("Texture")
		t.Name, t.Texture, t.Face = "GardenStuds", STUDS, face
		t.StudsPerTileU, t.StudsPerTileV, t.Transparency = 8, 8, 0.45
		t.Parent = p
	end
end
local function water(name, size, position)
	local p = part(name, size, position, WATER, Enum.Material.Glass)
	p.Transparency, p.CastShadow = 0.15, false
	return p
end
local function reshape(p, size, position)
	p:SetAttribute("BeforeCurvedWaterfallSize", p.Size)
	p:SetAttribute("BeforeCurvedWaterfallCFrame", p.CFrame)
	p.Size, p.CFrame = size, CFrame.new(position)
end

-- 1. Side rock walls, the slot geometry, the old pool and bushes standing in the new pool.
local templates = fall.VFX_Waterfall:Clone()
local retiring = {
	WaterfallRock = true,
	RockGrassCap = true,
	WaterCurtain = true,
	GorgeBack = true,
	ChannelBed = true,
	ChannelWall = true,
	ChannelHead = true,
	ChannelWater = true,
	WaterLip = true,
	PoolBasin = true,
	PoolRim = true,
	PoolWater = true,
	Bush = true,
	VFX_Waterfall = true,
}
for _, item in fall:GetChildren() do
	if retiring[item.Name] then
		retire(item, "Replaced by the curved waterfall")
	end
end

-- 2. Planting on the new stream bed would poke through the water.
for _, p in map:GetDescendants() do
	if p:IsA("BasePart") and not p:IsDescendantOf(fall) and p.Parent ~= map.SurfaceSeparation then
		local q = p.Position
		local onBed = q.X > X - WIDTH / 2 - 2 and q.X < X + WIDTH / 2 + 2 and q.Z > 332 and q.Z < 357
		if onBed and q.Y > 82 and q.Y < 92 and p.Size.Magnitude < 12 then
			local owner = p:FindFirstAncestorWhichIsA("Model")
			if not owner or owner:GetExtentsSize().Magnitude > 6 then
				owner = p
			end
			if owner.Parent and not owner:IsDescendantOf(backup) then
				retire(owner, "On the waterfall stream")
			end
		end
	end
end
map.SurfaceSeparation:SetAttribute("RetiredRecordIds", table.concat(retiredIds, ","))

-- 3. A shallow stream on the top terrace rolls over a rounded lip.
water("StreamWater", V(WIDTH, 0.3, 22), V(X, 83.2, 344.6))
local lip = water("WaterLip", V(WIDTH, 0.7, 0.7), V(X, 83, 333.6))
lip.Shape = Enum.PartType.Cylinder

-- 4. A low studded pool at the foot of the cliff.
water("PoolWater", V(WIDTH + 1, 0.7, 11.8), V(X, 20.4, 309.9))
studs(part("PoolRim", V(WIDTH + 3, 1, 1), V(X, 20.5, 303.5), STONE), { Enum.NormalId.Top, Enum.NormalId.Front })
for _, side in { -1, 1 } do
	local rim = part("PoolRim", V(1, 1, 11.9), V(X + side * (WIDTH / 2 + 1), 20.5, 309.95), STONE)
	studs(rim, { Enum.NormalId.Top, side < 0 and Enum.NormalId.Left or Enum.NormalId.Right })
end

-- 5. Animated sheet: Beams on one cubic curve. The sheet leaves the lip forward (CurveSize0)
-- and lands vertically (CurveSize1); these sizes clear the ledges and their planting by 2 studs.
local vfx = part("VFX_Waterfall", V(1, 1, 1), V(X, 52, 322), STONE)
vfx.Transparency = 1
local function attachment(name, position, axis)
	local a = Instance.new("Attachment")
	a.Name, a.Parent = name, vfx
	-- Flat Beams spread their width along the attachment's secondary axis (world X here).
	a.WorldCFrame = CFrame.fromMatrix(position, axis, V(1, 0, 0))
	return a
end
local top = attachment("FallTop", LIP, V(0, 0, -1))
local bottom = attachment("FallBottom", FOOT, V(0, -1, 0))
local streamStart = attachment("ChannelStart", V(X, 83.36, 355.4), V(0, 0, -1))
local streamEnd = attachment("ChannelEnd", V(X, 83.36, 333.6), V(0, 0, -1))
local function beam(name, template, a0, a1, width, changes)
	local b = templates[template]:Clone()
	b.Name, b.Attachment0, b.Attachment1 = name, a0, a1
	b.Width0, b.Width1, b.Segments = width, width + (a0 == top and 2 or 0), 40
	b.CurveSize0, b.CurveSize1 = a0 == top and 8 or 0, a0 == top and 40 or 0
	for key, value in changes do
		(b :: any)[key] = value
	end
	b.Parent = vfx
	return b
end
local function opacity(edge, body)
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, edge),
		NumberSequenceKeypoint.new(0.03, body),
		NumberSequenceKeypoint.new(0.97, body),
		NumberSequenceKeypoint.new(1, edge),
	})
end
-- The pack's body texture has wavy transparent edges; a plain sheet underneath keeps the full width.
beam("FallSheet", "FallBody", top, bottom, WIDTH, {
	Texture = "",
	Color = ColorSequence.new(RGB(32, 178, 228)),
	Transparency = opacity(0.5, 0.2),
	LightEmission = 0.1,
	ZOffset = -0.1,
})
beam("FallBody", "FallBody", top, bottom, WIDTH + 0.4, { Transparency = opacity(0.5, 0.12) })
beam("FallRibbons", "FallRibbons", top, bottom, WIDTH, {})
beam("FallRibbonsSlow", "FallRibbons", top, bottom, WIDTH - 0.6, {
	TextureLength = 23,
	TextureSpeed = 1.1,
	ZOffset = 0.15,
	Transparency = opacity(1, 0.6),
})
beam("FallStreaks", "FallStreaks", top, bottom, WIDTH - 0.4, {})
beam("ChannelFlow", "ChannelFlow", streamStart, streamEnd, WIDTH - 1, {})

-- 6. Foam, splash, mist and ripples follow the wider sheet.
local function emitters(p, scale)
	for _, e in p:GetChildren() do
		if e:IsA("ParticleEmitter") then
			e.Rate = math.round(e.Rate * scale)
		end
	end
end
reshape(fall.VFX_WaterfallLipFoam, V(WIDTH, 0.4, 0.8), LIP + V(0, 0, -0.2))
emitters(fall.VFX_WaterfallLipFoam, 2.5)
reshape(fall.VFX_WaterfallSplash, V(WIDTH, 0.5, 2), FOOT + V(0, 0.2, 0))
emitters(fall.VFX_WaterfallSplash, 2.5)
reshape(fall.VFX_WaterfallMist, V(WIDTH + 4, 1, 6), FOOT + V(0, 1.7, -1.5))
emitters(fall.VFX_WaterfallMist, 2.3)
reshape(fall.VFX_WaterfallRipples, V(WIDTH - 2, 0.1, 9), V(X, 20.8, 309.5))
emitters(fall.VFX_WaterfallRipples, 2.4)
reshape(fall.VFX_WaterfallSpring, V(WIDTH - 4, 0.3, 1.5), V(X, 83.45, 354.5))
emitters(fall.VFX_WaterfallSpring, 2)
local topMist = fall.VFX_WaterfallMist:Clone()
topMist.Name = "VFX_WaterfallTopMist"
topMist.Size, topMist.CFrame = V(WIDTH, 1, 3), CFrame.new(LIP + V(0, 1, -1.5))
topMist.Mist.Rate = 4
topMist.Parent = fall

templates:Destroy()
fall:SetAttribute("CurvedWaterfall", true)
game:GetService("ChangeHistoryService"):SetWaypoint("Curved waterfall")
return #backup:GetChildren()
