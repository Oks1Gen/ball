-- Edit migration: the east lobby waterfall matches the rear one (2026-11-01). Run once in Edit after
-- CurvedWaterfallUpgrade, then save the place. The east terraces repeat the rear ones (faces 9 studs
-- apart, same ledge heights), so the rear waterfall's stream, sheet, pool and VFX are cloned and
-- turned 90 degrees onto the east wall. The two-stage LobbyWaterfallGarden with its stone columns,
-- and decor standing in the new pool or stream or crossing the sheet, go to
-- ServerStorage.WorldBackups.BeforeSideWaterfall_20261101.
-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
local map = workspace.Map.World1
local main = map.SpawnGarden.CornerWaterfall1
assert(main:GetAttribute("CurvedWaterfall"), "Run CurvedWaterfallUpgrade first")
assert(not map.SpawnGarden:FindFirstChild("SideWaterfall"), "Side waterfall already built")
local V = Vector3.new
-- Rear top-terrace face (Z 334) at the main sheet centre -> east top-terrace face (X 173), facing -X.
local MOVE = CFrame.new(173, 0, 168.5) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(67.5, 0, 334):Inverse()
local old = map:FindFirstChild("LobbyWaterfallGarden")

-- 1. Where the cloned water will be: points on the sheet, and boxes over the pool and the stream.
local vfx = main.VFX_Waterfall
local beam = vfx.FallSheet
local top, bottom = MOVE * vfx.FallTop.WorldCFrame, MOVE * vfx.FallBottom.WorldCFrame
local p0, p3 = top.Position, bottom.Position
local p1, p2 = p0 + top.XVector * beam.CurveSize0, p3 - bottom.XVector * beam.CurveSize1
local samples = {}
for i = 0, 40 do
	local t = i / 40
	local u = 1 - t
	local centre = p0 * u ^ 3 + p1 * 3 * u * u * t + p2 * 3 * u * t * t + p3 * t ^ 3
	local half = (beam.Width0 + (beam.Width1 - beam.Width0) * t) / 2
	for k = -4, 4 do
		table.insert(samples, centre + top.YVector * half * k / 4)
	end
end
local zones = {}
for _, name in { "PoolWater", "StreamWater" } do
	local p = main[name]
	table.insert(zones, { cf = MOVE * p.CFrame * CFrame.new(0, 1.5, 0), size = p.Size + V(1, 3, 1) })
end
local function inside(cf: CFrame, size: Vector3, point: Vector3): boolean
	local q = cf:PointToObjectSpace(point)
	return math.abs(q.X) < size.X / 2 and math.abs(q.Y) < size.Y / 2 and math.abs(q.Z) < size.Z / 2
end
local function inTheWay(p: BasePart): boolean
	local padded = p.Size + V(0.6, 0.6, 0.6)
	for _, s in samples do
		if inside(p.CFrame, padded, s) then
			return true
		end
	end
	for _, z in zones do
		if inside(z.cf, z.size, p.Position) then
			return true
		end
	end
	return false
end

-- 2. Decor in the way. Terrace blocks and the ground must already be clear; stone props may go.
local owners, ownerList, blocking = {}, {}, {}
for _, p in map:GetDescendants() do
	if not p:IsA("BasePart") or p.Transparency >= 0.9 or (old and p:IsDescendantOf(old)) then
		continue
	end
	if p:FindFirstAncestor("TerraceChecker") or not inTheWay(p) then
		continue
	end
	local link = p.Parent == map.SurfaceSeparation and p:FindFirstChild("OriginalPart")
	local original = link and link.Value or p
	if old and original:IsDescendantOf(old) then
		continue
	end
	if original.Size.Magnitude > 12 and not original.Name:match("^Rock") then
		table.insert(blocking, original:GetFullName())
		continue
	end
	local owner = original:FindFirstAncestorWhichIsA("Model")
	if not owner or owner:GetExtentsSize().Magnitude > 8 then
		owner = original
	end
	if not owners[owner] then
		owners[owner] = true
		table.insert(ownerList, owner)
	end
end
assert(#blocking == 0, "Large parts in the way: " .. table.concat(blocking, ", "))

game:GetService("ChangeHistoryService"):SetWaypoint("Before side waterfall")
local backups = game.ServerStorage:FindFirstChild("WorldBackups") or Instance.new("Folder")
backups.Name, backups.Parent = "WorldBackups", game.ServerStorage
local backup = Instance.new("Folder")
backup.Name, backup.Parent = "BeforeSideWaterfall_20261101", backups
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
if old then
	retire(old, "Replaced by the curved east waterfall")
end
local names = {}
for _, owner in ownerList do
	if owner.Parent and not owner:IsDescendantOf(backup) then
		table.insert(names, owner.Name)
		retire(owner, "In the east waterfall pool, stream or sheet")
	end
end
map.SurfaceSeparation:SetAttribute("RetiredRecordIds", table.concat(retiredIds, ","))

-- 3. Clone the rear waterfall onto the east wall.
local fall = Instance.new("Model")
fall.Name = "SideWaterfall"
local copied = {
	StreamWater = true,
	WaterLip = true,
	PoolWater = true,
	PoolRim = true,
	VFX_Waterfall = true,
	VFX_WaterfallLipFoam = true,
	VFX_WaterfallSplash = true,
	VFX_WaterfallMist = true,
	VFX_WaterfallRipples = true,
	VFX_WaterfallSpring = true,
	VFX_WaterfallTopMist = true,
}
for _, item in main:GetChildren() do
	if copied[item.Name] and item:IsA("BasePart") then
		local copy = item:Clone()
		for _, key in { "BeforeCurvedWaterfallSize", "BeforeCurvedWaterfallCFrame" } do
			copy:SetAttribute(key, nil)
		end
		copy.CFrame = MOVE * item.CFrame
		copy.Parent = fall
	end
end
fall:SetAttribute("SourceWaterfall", main:GetFullName())
fall.Parent = map.SpawnGarden
game:GetService("ChangeHistoryService"):SetWaypoint("Side waterfall")
return string.format("cloned %d parts, moved %d: %s", #fall:GetChildren(), #names, table.concat(names, ", "))
