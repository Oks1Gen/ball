-- Edit migration: full-height lobby waterfall (2026-11-01). Run once in Edit, then save the place.
-- The old curtain started 20 studs below the rear terrace top. The rocks and water now rise to the
-- top terrace, where a stone channel feeds the lip. Animated layers are VFX (VFX_Waterfall).
-- Resized parts keep their previous Size/CFrame in BeforeFullWaterfall* attributes; removed
-- parts go to ServerStorage.WorldBackups.BeforeFullWaterfall_20261101.
assert(not game:GetService("RunService"):IsRunning(), "Run in Edit")
local map = workspace.Map.World1
local fall = map.SpawnGarden.CornerWaterfall1
assert(not fall:GetAttribute("FullWaterfall"), "Waterfall already upgraded")
local V, RGB = Vector3.new, Color3.fromRGB
local TOP = 84 -- rock top; the rear terrace grass is at Y 81.4
local WATER_TOP = 82.3
local STONE = RGB(135, 151, 157)
local WATER = RGB(40, 209, 226)
game:GetService("ChangeHistoryService"):SetWaypoint("Before full waterfall")

local backups = game.ServerStorage:FindFirstChild("WorldBackups") or Instance.new("Folder")
backups.Name, backups.Parent = "WorldBackups", game.ServerStorage
local backup = Instance.new("Folder")
backup.Name, backup.Parent = "BeforeFullWaterfall_20261101", backups

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
local function reshape(p, size, position)
	p:SetAttribute("BeforeFullWaterfallSize", p.Size)
	p:SetAttribute("BeforeFullWaterfallCFrame", p.CFrame)
	p.Size, p.CFrame = size, CFrame.new(position)
end
local function studs(p, faces)
	for _, face in faces do
		local t = Instance.new("Texture")
		t.Name, t.Texture, t.Face = "GardenStuds", "rbxassetid://88156646156237", face
		t.StudsPerTileU, t.StudsPerTileV, t.Transparency = 8, 8, 0.45
		t.Parent = p
	end
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

-- 1. Rocks rise to the top terrace and reach back into it; the curtain spans the full drop.
for _, rock in fall:GetChildren() do
	if rock.Name == "WaterfallRock" then
		reshape(rock, V(5, TOP - 20, 29), V(rock.Position.X, (TOP + 20) / 2, 321.5))
		studs(rock, { Enum.NormalId.Left, Enum.NormalId.Right })
	elseif rock.Name == "RockGrassCap" then
		reshape(rock, V(5.8, 1.2, 29.8), V(rock.Position.X, TOP + 0.6, 321.5))
	end
end
local curtain = fall.WaterCurtain
reshape(curtain, V(10, WATER_TOP - 20.7, 0.7), V(67.5, (WATER_TOP + 20.7) / 2, 306.1))
for _, streak in fall:GetChildren() do
	if streak.Name == "WaterStreak" then
		retire(streak, "Replaced by animated VFX_Waterfall beams")
	end
end

-- 2. A dark gorge wall behind the water gives the curtain depth.
local back = part("GorgeBack", V(11, 61, 1), V(67.5, 50.5, 308.1), RGB(92, 110, 124))
studs(back, { Enum.NormalId.Front })

-- 3. A stone channel on the top terrace feeds the lip.
local bed = part("ChannelBed", V(11, 1.2, 41.5), V(67.5, 81.1, 327.25), STONE)
studs(bed, { Enum.NormalId.Top })
for _, x in { 61, 74 } do
	studs(part("ChannelWall", V(2, 2.4, 12.5), V(x, 82.6, 342.25), STONE), { Enum.NormalId.Top, Enum.NormalId.Front })
end
studs(part("ChannelHead", V(15, 2.4, 1.5), V(67.5, 82.6, 349.25), STONE), { Enum.NormalId.Top, Enum.NormalId.Front })
local water = part("ChannelWater", V(10.6, 0.3, 41.3), V(67.5, WATER_TOP - 0.15, 327.75), WATER, Enum.Material.Glass)
water.Transparency, water.CastShadow = 0.15, false
local lip = part("WaterLip", V(10.6, 1, 1), V(67.5, WATER_TOP - 0.4, 306.3), WATER, Enum.Material.Glass)
lip.Shape, lip.Transparency, lip.CastShadow = Enum.PartType.Cylinder, 0.15, false

-- 4. Flowers on the channel footprint would poke through the water.
for _, p in map:GetDescendants() do
	if p:IsA("BasePart") and not p:IsDescendantOf(fall) and p.Parent ~= map.SurfaceSeparation then
		local q = p.Position
		if q.X > 60 and q.X < 75 and q.Z > 305 and q.Z < 350 and q.Y > 80 and q.Y < 90 and p.Size.Magnitude < 12 then
			-- Retire a whole flower model only when it is small; never a planting group.
			local owner = p:FindFirstAncestorWhichIsA("Model")
			if not owner or owner:GetExtentsSize().Magnitude > 6 then
				owner = p
			end
			if owner.Parent and not owner:IsDescendantOf(backup) then
				retire(owner, "On the waterfall channel")
			end
		end
	end
end
map.SurfaceSeparation:SetAttribute("RetiredRecordIds", table.concat(retiredIds, ","))
fall:SetAttribute("FullWaterfall", true)
game:GetService("ChangeHistoryService"):SetWaypoint("Full waterfall")
return #backup:GetChildren()
