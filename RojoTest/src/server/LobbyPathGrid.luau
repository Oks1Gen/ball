--!strict
-- One paving lattice: complete checker cells, flat joints and one outer studded rim.
local Palette = require(script.Parent.LobbyPalette)
local Grid = {}
local V = Vector3.new
local CELL, STEP = 6.4, 1.6
local STUDS_PER_CELL = math.round(CELL / STEP)

function Grid.build(root: Instance, regions: { any }, top: number, selected: { [string]: boolean }, origin: Vector2)
	local groups: { [string]: Model } = {}
	local fill: { [string]: any } = {}
	local checker: { [string]: any } = {}
	local plain: { [string]: any } = {}
	local rim: { [string]: any } = {}
	local function key(x: number, z: number): string
		return x .. ":" .. z
	end
	local function model(name: string): Model
		if not groups[name] then
			local m = Instance.new("Model")
			m.Name, m.WorldPivot = name, CFrame.new(origin.X, top, origin.Y)
			groups[name] = m
		end
		return groups[name]
	end
	local function part(owner: string, name: string, x0: number, x1: number, z0: number, z1: number, color: Color3)
		local p = Instance.new("Part")
		p.Name, p.Size = name, V(x1 - x0, 0.2, z1 - z0)
		p.CFrame, p.Color, p.Material =
			CFrame.new((x0 + x1) / 2, top - 0.1, (z0 + z1) / 2), color, Enum.Material.Plastic
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		local t = Instance.new("Texture")
		t.Name, t.Texture, t.Face = "PathStuds", Palette.Studs, Enum.NormalId.Top
		t.StudsPerTileU, t.StudsPerTileV = 6.4, 6.4 -- Four-by-four source: pitch 1.6.
		-- Face-edge UV origin: whole-pitch rectangles need no offset. A half-pitch
		-- shift cuts the single stud row on a narrow rim.
		t.OffsetStudsU, t.OffsetStudsV = 0, 0
		t.Transparency, t.Parent = Palette.StudsTransparency, p
		p.Parent = model(owner)
		return p
	end
	-- Rasterisation is shared by all owners. A junction cannot contain duplicate layers.
	for _, region in regions do
		if not selected[region.name] then
			continue
		end
		local lo, hi = region.polygon[1], region.polygon[3]
		local owner = region.group or region.name
		local step = if region.plain then STEP else CELL
		for x = math.floor((lo.X - origin.X) / step + 0.0001), math.ceil((hi.X - origin.X) / step - 0.0001) - 1 do
			for z = math.floor((lo.Y - origin.Y) / step + 0.0001), math.ceil((hi.Y - origin.Y) / step - 0.0001) - 1 do
				if not region.plain then
					local id = key(x, z)
					if not checker[id] then
						checker[id] = { x = x, z = z, owner = owner }
					end
					for dx = 0, STUDS_PER_CELL - 1 do
						for dz = 0, STUDS_PER_CELL - 1 do
							local sx, sz = x * STUDS_PER_CELL + dx, z * STUDS_PER_CELL + dz
							fill[key(sx, sz)] = { x = sx, z = sz, owner = owner }
						end
					end
				else
					plain[key(x, z)] = { x = x, z = z, owner = owner }
				end
			end
		end
	end
	for id, cell in plain do
		if fill[id] then
			plain[id] = nil
		else
			fill[id] = cell
		end
	end
	local function covered(x: number, z: number): boolean
		local point = Vector2.new(origin.X + (x + 0.5) * STEP, origin.Y + (z + 0.5) * STEP)
		for _, region in regions do
			local lo, hi = region.polygon[1], region.polygon[3]
			-- Training foundations cover the sub-stud raster overlap below their top.
			if
				not selected[region.name]
				and point.X > lo.X
				and point.X < hi.X
				and point.Y > lo.Y
				and point.Y < hi.Y
			then
				return true
			end
			if region.openZ and point.Y < region.openZ then
				return true
			end
		end
		return false
	end
	for _, cell in fill do
		for dx = -1, 1 do
			for dz = -1, 1 do
				local x, z = cell.x + dx, cell.z + dz
				local id = key(x, z)
				if not fill[id] and not rim[id] and not covered(x, z) then
					rim[id] = { x = x, z = z, owner = cell.owner }
				end
			end
		end
	end
	local ordered = {}
	for _, cell in checker do
		table.insert(ordered, cell)
	end
	table.sort(ordered, function(a, b)
		return if a.z ~= b.z then a.z < b.z else a.x < b.x
	end)
	for i, cell in ordered do
		local x, z = origin.X + cell.x * CELL, origin.Y + cell.z * CELL
		local p = part(
			cell.owner,
			"PavingSurface",
			x,
			x + CELL,
			z,
			z + CELL,
			if (cell.x + cell.z) % 2 == 0 then Palette.PathChecker else Palette.Path
		)
		p:SetAttribute("CheckerCell", true)
		p:SetAttribute("GridX", cell.x)
		p:SetAttribute("GridZ", cell.z)
		if i % 250 == 0 then
			task.wait()
		end
	end
	-- Merge fine cells into disjoint rectangles. Rim corners are actual cells,
	-- rather than overlapping bars, so no mitre gaps or doubled corner outlines.
	local function merge(cells: { [string]: any }, name: string, color: Color3)
		local rows = {}
		for _, cell in cells do
			table.insert(rows, cell)
		end
		table.sort(rows, function(a, b)
			return if a.z ~= b.z then a.z < b.z else a.x < b.x
		end)
		for i, first in rows do
			if not cells[key(first.x, first.z)] then
				continue
			end
			local x1, z1 = first.x + 1, first.z + 1
			while cells[key(x1, first.z)] and cells[key(x1, first.z)].owner == first.owner do
				x1 += 1
			end
			while true do
				local full = true
				for x = first.x, x1 - 1 do
					local cell = cells[key(x, z1)]
					if not cell or cell.owner ~= first.owner then
						full = false
						break
					end
				end
				if not full then
					break
				end
				z1 += 1
			end
			for x = first.x, x1 - 1 do
				for z = first.z, z1 - 1 do
					cells[key(x, z)] = nil
				end
			end
			part(
				first.owner,
				name,
				origin.X + first.x * STEP,
				origin.X + x1 * STEP,
				origin.Y + first.z * STEP,
				origin.Y + z1 * STEP,
				color
			)
			if i % 250 == 0 then
				task.wait()
			end
		end
	end
	merge(plain, "PavingSurface", Palette.Path)
	merge(rim, "PathCurb", Palette.PathEdge)
	for _, m in groups do
		m:SetAttribute("PathGridVersion", 2)
		m.Parent = root
	end
end

return Grid
