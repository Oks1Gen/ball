-- Support for the horizontal, axis-aligned shelves of Ocean Depths.
-- Visible cladding may have CanQuery disabled, so use its actual rectangles.
local Ground = {}
local EPSILON = 0.003

type Surface = { left: number, right: number, front: number, back: number, top: number }

function Ground.add(surfaces: { Surface }, part: BasePart)
	if part.CFrame.UpVector.Y < 0.999 then
		return
	end
	local size = part.Size
	local p = part.Position
	local right = part.CFrame.RightVector
	if math.max(math.abs(right.X), math.abs(right.Z)) < 0.999 then
		return
	end
	local look = part.CFrame.LookVector
	local x = (math.abs(right.X) * size.X + math.abs(look.X) * size.Z) / 2
	local z = (math.abs(right.Z) * size.X + math.abs(look.Z) * size.Z) / 2
	table.insert(surfaces, { left = p.X - x, right = p.X + x, front = p.Z - z, back = p.Z + z, top = p.Y + size.Y / 2 })
end

function Ground.collect(root: Instance, names: { [string]: boolean }): { Surface }
	local surfaces = {}
	for _, part in root:GetDescendants() do
		if part:IsA("BasePart") and names[part.Name] and part.Transparency < 1 then
			Ground.add(surfaces, part)
		end
	end
	return surfaces
end

local function topAt(surfaces: { Surface }, p: Vector3, x: number, z: number, tolerance: number): number?
	local left, right = p.X - x, p.X + x
	local front, back = p.Z - z, p.Z + z
	local overlapping = {}
	local top = -math.huge
	for _, tile in surfaces do
		if
			tile.right > left + EPSILON
			and tile.left < right - EPSILON
			and tile.back > front + EPSILON
			and tile.front < back - EPSILON
		then
			table.insert(overlapping, tile)
			top = math.max(top, tile.top)
		end
	end
	if math.abs(top - p.Y) > tolerance then
		return nil
	end

	-- Split at every X edge and check that the Z intervals cover each strip.
	local edges = { left, right }
	local tiles = {}
	for _, tile in overlapping do
		if math.abs(tile.top - top) <= 0.025 then
			table.insert(tiles, tile)
			table.insert(edges, math.max(left, tile.left))
			table.insert(edges, math.min(right, tile.right))
		end
	end
	table.sort(edges)
	table.sort(tiles, function(a, b)
		return a.front < b.front
	end)
	for i = 2, #edges do
		if edges[i] - edges[i - 1] > EPSILON then
			local mid = (edges[i] + edges[i - 1]) / 2
			local covered = front
			for _, tile in tiles do
				if tile.left <= mid and tile.right >= mid and tile.front <= covered + EPSILON then
					covered = math.max(covered, tile.back)
				end
			end
			if covered < back - EPSILON then
				return nil
			end
		end
	end
	return top
end

function Ground.fit(surfaces: { Surface }, cf: CFrame, footprint: Vector2, tolerance: number, search: number?): CFrame
	local right = cf.RightVector
	local look = cf.LookVector
	local x = (math.abs(right.X) * footprint.X + math.abs(look.X) * footprint.Y) / 2 + 0.12
	local z = (math.abs(right.Z) * footprint.X + math.abs(look.Z) * footprint.Y) / 2 + 0.12
	local point = cf.Position
	local best: Vector3? = nil
	local bestDistance = math.huge
	local radius = search or 0
	for ix = -radius, radius do
		for iz = -radius, radius do
			local distance = ix * ix + iz * iz
			if distance < bestDistance and distance <= radius * radius then
				local candidate = point + Vector3.new(ix * 0.6, 0, iz * 0.6)
				local top = topAt(surfaces, candidate, x, z, tolerance)
				if top then
					best = Vector3.new(candidate.X, top, candidate.Z)
					bestDistance = distance
				end
			end
		end
	end
	assert(best, "No full support at " .. tostring(point) .. " for " .. tostring(footprint))
	return CFrame.new(best) * cf.Rotation
end

return Ground
