--!strict
-- Exposed-edge paving construction shared with the compact lobby style.
local Palette = require(script.Parent.LobbyPalette)
local Regions = {}
local V, P = Vector3.new, Vector2.new
local FILL, EDGE, CURB, STUDS = Palette.Path, Palette.PathEdge, Palette.PathCurb, Palette.Studs
-- Regions with the same `group` share one Model (e.g. the frame around the training lanes).
type Region = { name: string, polygon: { Vector2 }, openX: number?, openZ: number?, group: string? }
local function cross(a: Vector2, b: Vector2): number
	return a.X * b.Y - a.Y * b.X
end

local function inside(p: Vector2, polygon: { Vector2 }): boolean
	for i, a in polygon do
		local b = polygon[i % #polygon + 1]
		if cross(b - a, p - a) < -0.0001 then
			return false
		end
	end
	return true
end

function Regions.build(
	root: Instance,
	regions: { Region },
	top: number,
	selected: { [string]: boolean },
	gridOrigin: Vector2?,
	scale: number?
)
	if gridOrigin then
		require(script.Parent.LobbyPathGrid).build(root, regions, top, selected, gridOrigin, scale or 1)
		return
	end
	local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): Part
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
		p.Anchored = true
		p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = parent
		return p
	end
	local function bar(
		parent: Instance,
		name: string,
		a: Vector2,
		b: Vector2,
		width: number,
		height: number,
		y: number,
		color: Color3
	): Part
		local start, finish = V(a.X, y, a.Y), V(b.X, y, b.Y)
		local p = part(
			parent,
			name,
			V(width, height, (finish - start).Magnitude),
			CFrame.lookAt((start + finish) / 2, finish),
			color
		)
		p.CastShadow = false
		return p
	end
	local function boundaryCuts(a: Vector2, b: Vector2, current: Region): { number }
		local values = { 0, 1 }
		local d = b - a
		for _, other in regions do
			if other == current then
				continue
			end
			for j, c in other.polygon do
				local e = other.polygon[j % #other.polygon + 1] - c
				local denominator = cross(d, e)
				if math.abs(denominator) > 0.00001 then
					local t, u = cross(c - a, e) / denominator, cross(c - a, d) / denominator
					if t > 0 and t < 1 and u >= -0.0001 and u <= 1.0001 then
						table.insert(values, t)
					end
				elseif math.abs(cross(c - a, d)) < 0.0001 then
					for _, p in { c, c + e } do
						local t = (p - a):Dot(d) / d:Dot(d)
						if t > 0 and t < 1 then
							table.insert(values, t)
						end
					end
				end
			end
		end
		table.sort(values)
		return values
	end
	local groups: { [string]: Model } = {}
	for _, region in regions do
		if not selected[region.name] then
			continue
		end
		local groupName = region.group or region.name
		if not groups[groupName] then
			local model = Instance.new("Model")
			model.Name, model.WorldPivot = groupName, CFrame.new(65, top, 224)
			groups[groupName] = model
		end
		local group = groups[groupName]
		local lo, hi = region.polygon[1], region.polygon[3]
		local surface = part(
			group,
			"PavingSurface",
			V(hi.X - lo.X, 0.2, hi.Y - lo.Y),
			CFrame.new((lo.X + hi.X) / 2, top - 0.1, (lo.Y + hi.Y) / 2),
			FILL
		)
		surface.Material = Enum.Material.Plastic
		local studs = Instance.new("Texture")
		studs.Name, studs.Texture, studs.Face = "PathStuds", STUDS, Enum.NormalId.Top
		studs.StudsPerTileU, studs.StudsPerTileV = Palette.StudsPerTile, Palette.StudsPerTile
		studs.Transparency = Palette.StudsTransparency
		-- Keep one stud phase across every rectangle.
		studs.OffsetStudsU, studs.OffsetStudsV = lo.X % 8, lo.Y % 8
		studs.Parent = surface
		-- Shared world grid: only dark cells need an overlay. Their top sits
		-- 0.06 studs above the base, avoiding coincident textured surfaces.
		local cell = Palette.PathCheckerCell
		for ix = math.floor(lo.X / cell), math.ceil(hi.X / cell) - 1 do
			for iz = math.floor(lo.Y / cell), math.ceil(hi.Y / cell) - 1 do
				if (ix + iz) % 2 == 0 then
					local x0, x1 = math.max(lo.X, ix * cell), math.min(hi.X, (ix + 1) * cell)
					local z0, z1 = math.max(lo.Y, iz * cell), math.min(hi.Y, (iz + 1) * cell)
					if x1 - x0 > 0.001 and z1 - z0 > 0.001 then
						local tile = part(
							group,
							"CheckerTile",
							V(x1 - x0, 0.02, z1 - z0),
							CFrame.new((x0 + x1) / 2, top + 0.05, (z0 + z1) / 2),
							Palette.PathChecker
						)
						tile.Material = Enum.Material.Plastic
						local texture = studs:Clone()
						texture.OffsetStudsU, texture.OffsetStudsV = x0 % 8, z0 % 8
						texture.Parent = tile
					end
				end
			end
		end
		for i, a in region.polygon do
			local b = region.polygon[i % #region.polygon + 1]
			if region.openX and math.abs(a.X - region.openX) < 0.001 and math.abs(b.X - region.openX) < 0.001 then
				continue
			end
			if region.openZ and math.abs(a.Y - region.openZ) < 0.001 and math.abs(b.Y - region.openZ) < 0.001 then
				continue
			end
			local d = b - a
			local outward = P(d.Y, -d.X).Unit
			local cuts = boundaryCuts(a, b, region)
			for j = 1, #cuts - 1 do
				if cuts[j + 1] - cuts[j] < 0.0001 then
					continue
				end
				local middle = a + d * ((cuts[j] + cuts[j + 1]) / 2) + outward * 0.02
				local exposed = true
				for _, other in regions do
					if other ~= region and inside(middle, other.polygon) then
						exposed = false
						break
					end
				end
				if exposed then
					local p, q = a + d * cuts[j], a + d * cuts[j + 1]
					bar(group, "PathCurb", p + outward * 0.35, q + outward * 0.35, 0.7, 0.32, top - 0.06, CURB)
					bar(group, "InsetBorder", p - outward * 0.8, q - outward * 0.8, 1.0, 0.025, top + 0.11, EDGE)
				end
			end
		end
		task.wait()
	end
	for _, group in groups do
		group.Parent = root
	end
end
return Regions
