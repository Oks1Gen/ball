-- Edit migration: flat river on both sides of the field corridor (2026-11-01). Run once in Edit,
-- then save the place. The old Terrain river stayed on the pre-centring axis (X -170..-62), sat
-- 15 studs below the banks, had rounded ends and stopped at Z -1440; its animated voxels cost
-- frame time. It is cleared, and each world gets two flat strips that touch both corridor sides
-- from the lobby facade to the corridor end. Surface VFX (glints, ripples, bank foam) are added
-- with the VfxForgeUltra plugin as VFX_* parts in the same RiverWater folder.
-- Rollback: Ctrl+Z to "Before flat river water" before saving, or place version history. The old
-- World1 water filled X -172..-60, Y -16..0, Z -1440..-32 (World2: the same, shifted by ArenaOffsetX).
-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
local V, RGB = Vector3.new, Color3.fromRGB
local WATER = RGB(40, 209, 226)
-- Corridor banks span X -49..159 and Y 14..29; the lobby facade starts at Z 81, the corridor ends at Z -2036.
local INNER_WEST, INNER_EAST = -49, 159
local WIDTH, OVERLAP = 112, 2
local TOP, DEPTH = 16, 3
local NEAR_Z, FAR_Z = 81, -2036
-- Old Terrain river of World1 (World2 has the same box shifted by its ArenaOffsetX).
local OLD_RIVER_MIN, OLD_RIVER_MAX = V(-180, -24, -1460), V(-48, 8, 0)
game:GetService("ChangeHistoryService"):SetWaypoint("Before flat river water")

for _, world in workspace.Map:GetChildren() do
	local offset = V(world:GetAttribute("ArenaOffsetX") or 0, 0, 0)
	if world:FindFirstChild("RiverWater") then
		continue
	end
	workspace.Terrain:FillRegion(
		Region3.new(OLD_RIVER_MIN + offset, OLD_RIVER_MAX + offset):ExpandToGrid(4),
		4,
		Enum.Material.Air
	)
	local folder = Instance.new("Folder")
	folder.Name = "RiverWater"
	folder:SetAttribute("FlatRiver", "2026-11-01")
	-- A part is at most 2048 studs long, so each strip is two halves that meet end to end.
	local half = (NEAR_Z - FAR_Z) / 2
	for side, inner in { West = INNER_WEST, East = INNER_EAST } do
		local sign = side == "West" and -1 or 1
		for i = 1, 2 do
			-- The strip tucks OVERLAP studs under the bank so no slit shows between water and earth.
			local p = Instance.new("Part")
			p.Name = "RiverWater" .. side
			p.Size = V(WIDTH + OVERLAP, DEPTH, half)
			p.Position = offset + V(inner + sign * (WIDTH - OVERLAP) / 2, TOP - DEPTH / 2, NEAR_Z - half * (i - 0.5))
			p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, true, false, false
			p.Material, p.Color, p.Reflectance = Enum.Material.SmoothPlastic, WATER, 0.08
			p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			p.CastShadow = false
			p.Parent = folder
		end
	end
	folder.Parent = world
end

-- Verify: no Terrain water is left anywhere near either world.
local left = 0
for _, world in workspace.Map:GetChildren() do
	local offset = V(world:GetAttribute("ArenaOffsetX") or 0, 0, 0)
	for z0 = -2200, 0, 400 do
		local region = Region3.new(V(-400, -40, z0) + offset, V(520, 40, z0 + 400) + offset):ExpandToGrid(4)
		local materials = workspace.Terrain:ReadVoxels(region, 4)
		for x = 1, materials.Size.X do
			for y = 1, materials.Size.Y do
				for z = 1, materials.Size.Z do
					if materials[x][y][z] == Enum.Material.Water then
						left += 1
					end
				end
			end
		end
	end
end
assert(left == 0, "Terrain water left: " .. left)
game:GetService("ChangeHistoryService"):SetWaypoint("After flat river water")
print("Flat river water ready")
