--!strict
-- Final, narrow egg-shop placement; never reruns historical world builders.
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local Palette = require(script.Parent.LobbyPalette)
local HDStuds = require(script.Parent.HDStuds)
local Style = {}
local VERSION = "arc-native-v1"
local V = Vector3.new
local SLOTS = {
	{ slot = "Common", model = "Egg_Common" },
	{ slot = "Uncommon", model = "Egg_Uncommon" },
	{ slot = "Volcanic", model = "VolcanicEgg" },
	{ slot = "Rare", model = "Egg_Rare" },
	{ slot = "Rainbow", model = "Egg_Rainbow" },
}

local SEAT_COLORS: { [string]: { Color3 } } = {
	Common = { Color3.fromRGB(72, 193, 16), Color3.fromRGB(121, 231, 43) },
	Uncommon = { Color3.fromRGB(16, 171, 225), Color3.fromRGB(101, 222, 250) },
	Volcanic = { Color3.fromRGB(226, 157, 17), Color3.fromRGB(255, 214, 65) },
	Rare = { Color3.fromRGB(102, 22, 37), Color3.fromRGB(142, 35, 42) },
	Rainbow = { Color3.fromRGB(170, 14, 244), Color3.fromRGB(191, 74, 247) },
}

function Style.colorSeats(stand: Instance): number
	local changed = 0
	for slotName, colors in SEAT_COLORS do
		local slot = stand:FindFirstChild(slotName)
		if slot then
			for _, part in slot:GetDescendants() do
				if part:IsA("BasePart") then
					local color = if part.Name:find("_SeatRim", 1, true)
						then colors[1]
						elseif part.Name:find("_SeatInset", 1, true) then colors[2]
						else nil
					if color and part.Color ~= color then
						part.Color = color
						changed += 1
					end
				end
			end
		end
	end
	return changed
end

local function extents(root: Instance, onlyPaving: boolean?): (Vector3, Vector3)
	local low, high = V(math.huge, math.huge, math.huge), V(-math.huge, -math.huge, -math.huge)
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 and (not onlyPaving or p.Name == "PavingSurface") then
			for _, x in { -0.5, 0.5 } do
				for _, y in { -0.5, 0.5 } do
					for _, z in { -0.5, 0.5 } do
						local q = p.CFrame:PointToWorldSpace(p.Size * V(x, y, z))
						low, high = low:Min(q), high:Max(q)
					end
				end
			end
		end
	end
	return low, high
end

local function verticalAxis(part: BasePart): number?
	local up = part.CFrame:VectorToObjectSpace(Vector3.yAxis)
	for i, value in { up.X, up.Y, up.Z } do
		if math.abs(value) > 0.999 then
			return i
		end
	end
	return nil
end

local function height(part: BasePart): number
	local axis = assert(verticalAxis(part), "Tilted egg stand part")
	return ({ part.Size.X, part.Size.Y, part.Size.Z })[axis]
end

-- Squash the whole stand about its base so the front band is exactly one stud row; the plan
-- shape stays. The modelled bump blocks are retired outside Workspace, textured studs replace them.
local function lower(stand: Model, pitch: number)
	if stand:GetAttribute("EggStandLowered") ~= nil then
		return
	end
	local backups = game.ServerStorage:FindFirstChild("WorldBackups")
	if not backups then
		backups = Instance.new("Folder")
		backups.Name, backups.Parent = "WorldBackups", game.ServerStorage
	end
	local retired = Instance.new("Folder")
	retired.Name = "EggStandStudBumps_20261103"
	local parts, base = {}, math.huge
	for _, p in stand:GetDescendants() do
		if p:IsA("BasePart") then
			if p.Name:match("_Studs%d+$") then
				p:SetAttribute("OriginalParent", p.Parent and p.Parent.Name)
				p.Parent = retired
			else
				table.insert(parts, p)
				base = math.min(base, p.Position.Y - height(p) / 2)
			end
		end
	end
	retired.Parent = backups
	local f = pitch / height(assert(stand:FindFirstChild("Volcanic_Bay", true)) :: BasePart)
	for _, p in parts do
		local axis = verticalAxis(p) :: number
		local s = { p.Size.X, p.Size.Y, p.Size.Z }
		s[axis] *= f
		local y = base + (p.Position.Y - base) * f
		p.Size = V(s[1], s[2], s[3])
		p.CFrame = p.CFrame.Rotation + V(p.Position.X, y, p.Position.Z)
	end
	stand:SetAttribute("EggStandLowered", f)
end

-- The stand top and the one-row front bands share the lobby stud material.
-- Seats use their own lattice (see `seats`).
local function studs(stand: Model, pitch: number)
	local tile = pitch * Palette.StudsPerTexture
	for _, p in stand:GetDescendants() do
		if not p:IsA("BasePart") or p.Transparency >= 1 then
			continue
		end
		for _, t in p:GetChildren() do
			if t:IsA("Texture") and t.Name == "StandStuds" then
				t:Destroy()
			end
		end
		if p.Name:find("Seat", 1, true) or p.Name:find("RaisedBay", 1, true) or p:GetAttribute("RimJoint") then
			continue
		end
		local band = math.abs(height(p) - pitch) < 0.001
		if band and p:IsA("WedgePart") then
			HDStuds.apply(p, tile)
			continue
		end
		for _, face in Enum.NormalId:GetEnumItems() do
			-- A wedge's Top and Front are its slope, drawn below.
			if p:IsA("WedgePart") and (face == Enum.NormalId.Top or face == Enum.NormalId.Front) then
				continue
			end
			local normal = p.CFrame:VectorToWorldSpace(Vector3.FromNormalId(face))
			if normal.Y > 0.999 or (band and math.abs(normal.Y) < 0.001) then
				HDStuds.apply(p, tile)
				break
			end
		end
	end
end

local RIM_THICKNESS = 0.05
local SIDE = { "Foundation", "RearRim" } -- dark like the path rim; the rest of the stand is path grey

local function recolor(stand: Model)
	for _, p in stand:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 and not p.Name:find("Seat", 1, true) then
			local dark = false
			for _, name in SIDE do
				dark = dark or p.Name:find(name, 1, true) ~= nil
			end
			p.Color = if dark then Palette.PathEdge else Palette.Path
		end
	end
end

-- Corners of the upward face, counter-clockwise seen from above (X/Z).
local function topFace(p: BasePart): ({ Vector2 }, number)
	local s = p.Size / 2
	local corners = {}
	if p:IsA("WedgePart") then
		for _, x in { -1, 1 } do
			for _, yz in { { -1, -1 }, { -1, 1 }, { 1, 1 } } do
				table.insert(corners, p.CFrame:PointToWorldSpace(V(x * s.X, yz[1] * s.Y, yz[2] * s.Z)))
			end
		end
	else
		for _, x in { -1, 1 } do
			for _, y in { -1, 1 } do
				for _, z in { -1, 1 } do
					table.insert(corners, p.CFrame:PointToWorldSpace(V(x, y, z) * s))
				end
			end
		end
	end
	local top = -math.huge
	for _, c in corners do
		top = math.max(top, c.Y)
	end
	local polygon, centre = {}, Vector2.zero
	for _, c in corners do
		if top - c.Y < 0.001 then
			table.insert(polygon, Vector2.new(c.X, c.Z))
			centre += Vector2.new(c.X, c.Z)
		end
	end
	centre /= #polygon
	table.sort(polygon, function(a, b)
		return math.atan2(a.Y - centre.Y, a.X - centre.X) < math.atan2(b.Y - centre.Y, b.X - centre.X)
	end)
	return polygon, top
end

local function cross(a: Vector2, b: Vector2): number
	return a.X * b.Y - a.Y * b.X
end

local function inside(polygon: { Vector2 }, q: Vector2): boolean
	for i, a in polygon do
		if cross(polygon[i % #polygon + 1] - a, q - a) < 0 then
			return false
		end
	end
	return true
end

-- Outer outline of the union of convex polygons, as closed loops of directed edges (CCW).
local function outline(polygons: { { Vector2 } }): { { Vector2 } }
	local points = {}
	for _, polygon in polygons do
		for _, q in polygon do
			table.insert(points, q)
		end
	end
	local function key(q: Vector2): string
		return string.format("%.2f:%.2f", q.X, q.Y)
	end
	local nextOf: { [string]: Vector2 } = {}
	local starts: { Vector2 } = {}
	for _, polygon in polygons do
		for i, a in polygon do
			local b = polygon[i % #polygon + 1]
			local length = (b - a).Magnitude
			local cuts = { 0, 1 }
			for _, q in points do
				local t = (q - a):Dot(b - a) / length ^ 2
				if t > 0.0001 and t < 0.9999 and math.abs(cross((b - a).Unit, q - a)) < 0.002 then
					table.insert(cuts, t)
				end
			end
			table.sort(cuts)
			for c = 1, #cuts - 1 do
				local p0, p1 = a:Lerp(b, cuts[c]), a:Lerp(b, cuts[c + 1])
				if (p1 - p0).Magnitude < 0.002 then
					continue
				end
				local direction = (p1 - p0).Unit
				local probe = (p0 + p1) / 2 + Vector2.new(direction.Y, -direction.X) * 0.02
				local covered = false
				for _, other in polygons do
					covered = covered or inside(other, probe)
				end
				if not covered then
					nextOf[key(p0)] = p1
					table.insert(starts, p0)
				end
			end
		end
	end
	local loops, used = {}, {}
	for _, start in starts do
		if used[key(start)] then
			continue
		end
		local loop, q = {}, start
		while q and not used[key(q)] do
			used[key(q)] = true
			table.insert(loop, q)
			q = nextOf[key(q)]
		end
		-- Merge collinear runs so mitres only fall on real corners.
		local merged = {}
		for i, b in loop do
			local a, c = loop[(i - 2) % #loop + 1], loop[i % #loop + 1]
			if math.abs(cross((b - a).Unit, (c - b).Unit)) > 0.0005 then
				table.insert(merged, b)
			end
		end
		if #merged >= 3 then
			table.insert(loops, merged)
		end
	end
	return loops
end

local function wedge(
	parent: Instance,
	corner: Vector2,
	e1: Vector2,
	l1: number,
	e2: Vector2,
	l2: number,
	y: number,
	thickness: number?
): WedgePart
	-- Right triangle in the horizontal plane: legs l1 along e1 and l2 along e2 from the corner.
	local localY, localZ = V(e2.X, 0, e2.Y), V(-e1.X, 0, -e1.Y)
	local centre = corner + e1 * (l1 / 2) + e2 * (l2 / 2)
	local p = Instance.new("WedgePart")
	p.Size = V(thickness or RIM_THICKNESS, l2, l1)
	p.CFrame = CFrame.fromMatrix(V(centre.X, y, centre.Y), localY:Cross(localZ), localY, localZ)
	p:SetAttribute("RimJoint", true)
	p.Parent = parent
	return p
end

-- A path-style dark rim one stud row wide around the stand top, mitred so no two pieces overlap.
local function rim(stand: Model, width: number)
	local old = stand:FindFirstChild("Rim")
	if old then
		old:Destroy()
	end
	local polygons, level = {}, -math.huge
	for _, p in stand:GetDescendants() do
		if p:IsA("BasePart") and p.Name:find("_Bay", 1, true) and not p.Name:find("RaisedBay", 1, true) then
			local polygon, top = topFace(p)
			table.insert(polygons, polygon)
			level = math.max(level, top)
		end
	end
	local model = Instance.new("Model")
	model.Name = "Rim"
	local y = level + RIM_THICKNESS / 2
	local innerLoops = {}
	for _, loop in outline(polygons) do
		local inner = {}
		table.insert(innerLoops, inner)
		for i, b in loop do
			local a, c = loop[(i - 2) % #loop + 1], loop[i % #loop + 1]
			local d0, d1 = (b - a).Unit, (c - b).Unit
			local n0, n1 = Vector2.new(-d0.Y, d0.X), Vector2.new(-d1.Y, d1.X)
			-- Intersection of the two edges offset inward by the rim width.
			local o = b + n0 * width
			local t = cross((b + n1 * width) - o, d1) / cross(d0, d1)
			inner[i] = o + d0 * t
		end
		for i, a in loop do
			local b = loop[i % #loop + 1]
			local length = (b - a).Magnitude
			local u = (b - a) / length
			local v = Vector2.new(-u.Y, u.X)
			local t0, t1 = (inner[i] - a):Dot(u), (inner[i % #loop + 1] - a):Dot(u)
			local lo, hi = math.max(0, t0), math.min(length, t1)
			-- Only whole studs carry the texture, centred on the edge; the leftovers at both
			-- ends and the mitre triangles are smooth joints in the same colour.
			local whole = math.floor((hi - lo) / width + 0.0001) * width
			local spans = {
				{ from = lo, to = (lo + hi - whole) / 2, joint = true },
				{ from = (lo + hi - whole) / 2, to = (lo + hi + whole) / 2, joint = false },
				{ from = (lo + hi + whole) / 2, to = hi, joint = true },
			}
			for _, span in spans do
				if span.to - span.from > 0.001 then
					local centre = a + u * ((span.from + span.to) / 2) + v * (width / 2)
					local p = Instance.new("Part")
					p.Size = V(span.to - span.from, RIM_THICKNESS, width)
					p.CFrame = CFrame.fromMatrix(V(centre.X, y, centre.Y), V(u.X, 0, u.Y), Vector3.yAxis)
					p:SetAttribute("RimJoint", span.joint)
					p.Parent = model
				end
			end
			if t0 > 0.001 then
				wedge(model, a + u * t0, -u, t0, v, width, y)
			elseif t0 < -0.001 then
				wedge(model, a + v * width, -u, -t0, -v, width, y)
			end
			if t1 < length - 0.001 then
				wedge(model, a + u * t1, u, length - t1, v, width, y)
			elseif t1 > length + 0.001 then
				wedge(model, b + v * width, u, t1 - length, -v, width, y)
			end
		end
	end
	for _, p in model:GetChildren() do
		local part = p :: BasePart
		part.Name, part.Color, part.Material = "RimEdge", Palette.PathEdge, Enum.Material.SmoothPlastic
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = true, false, false, false, false
		part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	end
	model.Parent = stand
	return innerLoops
end

-- The centre steps get the same dark rim along their open front and sides. Both treads snap to
-- whole studs (the lower one a stud wider on each side), so the rim and the grey inside stay whole.
local function steps(stand: Model, pitch: number)
	local model = stand:FindFirstChild("CenterSteps")
	local upper = model and model:FindFirstChild("Center_Step_Upper")
	local bottomStep = model and model:FindFirstChild("Center_Step_Lower")
	if not (model and upper and bottomStep and upper:IsA("BasePart") and bottomStep:IsA("BasePart")) then
		return
	end
	local authored = {}
	for _, p in { upper, bottomStep } do
		if typeof(p:GetAttribute("OriginalSize")) ~= "Vector3" then
			p:SetAttribute("OriginalSize", p.Size)
			p:SetAttribute("OriginalCFrame", p.CFrame)
		end
		local cf = p:GetAttribute("OriginalCFrame") :: CFrame
		assert(cf.Rotation:FuzzyEq(CFrame.identity, 0.001), "Turned centre step")
		table.insert(authored, { size = p:GetAttribute("OriginalSize") :: Vector3, cf = cf })
	end
	local function snap(x: number): number
		return math.max(1, math.round(x / pitch)) * pitch
	end
	-- The steps face -Z and share the back line where the upper tread meets the stand.
	local u, l = authored[1], authored[2]
	local back = u.cf.Z + u.size.Z / 2
	local width, depth = snap(u.size.X), snap(u.size.Z)
	local exposed = snap((u.cf.Z - u.size.Z / 2) - (l.cf.Z - l.size.Z / 2))
	local treads = {
		{ part = upper, width = width, depth = depth, cf = u.cf, size = u.size },
		{ part = bottomStep, width = width + 2 * pitch, depth = depth + exposed, cf = l.cf, size = l.size },
	}
	local old = model:FindFirstChild("StepRim")
	if old then
		old:Destroy()
	end
	local rimModel = Instance.new("Model")
	rimModel.Name = "StepRim"
	for _, tread in treads do
		local p = tread.part
		p.Size = V(tread.width, tread.size.Y, tread.depth)
		p.CFrame = CFrame.new(tread.cf.X, tread.cf.Y, back - tread.depth / 2)
		local x, y, front = tread.cf.X, tread.cf.Y + tread.size.Y / 2 + RIM_THICKNESS / 2, back - tread.depth
		local half = tread.width / 2
		local strips = {
			{ x - half, x + half, front, front + pitch },
			{ x - half, x - half + pitch, front + pitch, back },
			{ x + half - pitch, x + half, front + pitch, back },
		}
		for _, s in strips do
			if s[4] - s[3] > 0.001 then
				local strip = Instance.new("Part")
				strip.Name, strip.Color, strip.Material = "StepEdge", Palette.PathEdge, Enum.Material.SmoothPlastic
				strip.Size = V(s[2] - s[1], RIM_THICKNESS, s[4] - s[3])
				strip.CFrame = CFrame.new((s[1] + s[2]) / 2, y, (s[3] + s[4]) / 2)
				strip.Anchored, strip.CanCollide, strip.CanTouch, strip.CanQuery, strip.CastShadow =
					true, false, false, false, false
				strip.TopSurface, strip.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
				strip.Parent = rimModel
			end
		end
	end
	rimModel.Parent = model
end

-- Seat pads and the volcanic plinth stay inside the rim: each slot's octagons shrink
-- horizontally about the seat until every corner clears the rim's inner edge.
local SEAT_CLEARANCE = 0.15

-- Distance from q to the rim's inner edge; negative outside it.
local function clearance(loops: { { Vector2 } }, q: Vector2): number
	local within, nearest = false, math.huge
	for _, loop in loops do
		for i, a in loop do
			local b = loop[i % #loop + 1]
			if (a.Y > q.Y) ~= (b.Y > q.Y) and q.X < a.X + (q.Y - a.Y) / (b.Y - a.Y) * (b.X - a.X) then
				within = not within
			end
			local t = math.clamp((q - a):Dot(b - a) / (b - a):Dot(b - a), 0, 1)
			nearest = math.min(nearest, (a:Lerp(b, t) - q).Magnitude)
		end
	end
	return if within then nearest else -nearest
end

local function fitSeats(stand: Model, loops: { { Vector2 } })
	local function clear(q: Vector2): boolean
		return clearance(loops, q) >= SEAT_CLEARANCE
	end
	for _, slot in stand:GetChildren() do
		local seat = slot:FindFirstChild("SeatCenter")
		if not (slot:IsA("Model") and seat and seat:IsA("BasePart")) then
			continue
		end
		local centre = Vector2.new(seat.Position.X, seat.Position.Z)
		local parts, corners = {}, {}
		for _, p in slot:GetChildren() do
			if p:IsA("BasePart") and (p.Name:find("Seat", 1, true) or p.Name:find("RaisedBay", 1, true)) then
				if p ~= seat then
					table.insert(parts, p)
					for _, q in (topFace(p)) do
						table.insert(corners, q)
					end
				end
			end
		end
		local function fits(f: number): boolean
			for _, q in corners do
				if not clear(centre + (q - centre) * f) then
					return false
				end
			end
			return true
		end
		if fits(1) then
			continue
		end
		local lo, hi = 0.5, 1
		assert(fits(lo), "Egg seat cannot fit inside the stand rim")
		for _ = 1, 30 do
			local mid = (lo + hi) / 2
			if fits(mid) then
				lo = mid
			else
				hi = mid
			end
		end
		for _, p in parts do
			local axis = verticalAxis(p) :: number
			local s = { p.Size.X, p.Size.Y, p.Size.Z }
			for i = 1, 3 do
				if i ~= axis then
					s[i] *= lo
				end
			end
			local q = centre + (Vector2.new(p.Position.X, p.Position.Z) - centre) * lo
			p.Size = V(s[1], s[2], s[3])
			p.CFrame = p.CFrame.Rotation + V(q.X, p.Position.Y, q.Y)
		end
		local previous = slot:GetAttribute("SeatFit")
		slot:SetAttribute("SeatFit", (if typeof(previous) == "number" then previous else 1) * lo)
	end
end

-- Every slot gets the volcanic seat: a dark plinth, a coloured pad and a lighter inset. Each layer
-- is an octagon on the stud lattice (width and corner cut in whole studs), so the lobby texture
-- only shows whole studs; the half studs along the diagonals are smooth wedges.
local SEAT_LAYERS = {
	-- Thickness in stud pitches, as measured on the volcanic seat after lowering.
	{ name = "SeatPlinth", cells = 8, corner = 2, thickness = 0.375 },
	{ name = "SeatRim", cells = 6, corner = 1, thickness = 0.27 },
	{ name = "SeatInset", cells = 4, corner = 1, thickness = 0.03 },
}
local FAN_SEAT = { "_SeatRim", "_SeatInset", "_RaisedBay" }

local function seats(stand: Model, pitch: number, loops: { { Vector2 } })
	local level = -math.huge
	for _, p in stand:GetDescendants() do
		if p:IsA("BasePart") and p.Name:find("_Bay", 1, true) and not p.Name:find("RaisedBay", 1, true) then
			local _, top = topFace(p)
			level = math.max(level, top)
		end
	end
	local tile = pitch * Palette.StudsPerTexture
	local retired: Folder? = nil
	for _, slot in stand:GetChildren() do
		local seat = slot:FindFirstChild("SeatCenter")
		if not (slot:IsA("Model") and seat and seat:IsA("BasePart")) then
			continue
		end
		-- The original wedge fans are kept outside Workspace.
		for _, p in slot:GetChildren() do
			local fan = false
			for _, key in FAN_SEAT do
				fan = fan or p.Name:find(key, 1, true) ~= nil
			end
			if fan and p:IsA("BasePart") then
				if not retired then
					local backups = game.ServerStorage:FindFirstChild("WorldBackups")
					if not backups then
						backups = Instance.new("Folder")
						backups.Name, backups.Parent = "WorldBackups", game.ServerStorage
					end
					local found = backups:FindFirstChild("EggStandSeatFans_20261103")
					local folder: Folder = if found and found:IsA("Folder") then found else Instance.new("Folder")
					folder.Name, folder.Parent = "EggStandSeatFans_20261103", backups
					retired = folder
				end
				p:SetAttribute("OriginalParent", slot.Name)
				p.Parent = retired
			end
		end
		local old = slot:FindFirstChild("SeatPad")
		if old then
			old:Destroy()
		end
		local pad = Instance.new("Model")
		pad.Name = "SeatPad"
		local colors = SEAT_COLORS[slot.Name]
		-- The authored seat position, kept so a re-apply nudges from the same point.
		local origin = slot:GetAttribute("SeatOrigin")
		if typeof(origin) ~= "Vector3" then
			origin = seat.Position
			slot:SetAttribute("SeatOrigin", origin)
		end
		local home = Vector2.new((origin :: Vector3).X, (origin :: Vector3).Z)
		-- The seat turns with the stand segment under it: the nearest rim edge, folded to ±45°.
		local direction, nearest = Vector2.xAxis, math.huge
		for _, loop in loops do
			for k, a in loop do
				local b = loop[k % #loop + 1]
				local t = math.clamp((home - a):Dot(b - a) / (b - a):Dot(b - a), 0, 1)
				local d = (a:Lerp(b, t) - home).Magnitude
				if d < nearest then
					direction, nearest = (b - a).Unit, d
				end
			end
		end
		local yaw = (math.atan2(direction.Y, direction.X) + math.pi / 4) % (math.pi / 2) - math.pi / 4
		local ex = Vector2.new(math.cos(yaw), math.sin(yaw))
		local ez = Vector2.new(-ex.Y, ex.X)
		local function at(x: number, z: number): Vector2
			return ex * x + ez * z
		end
		slot:SetAttribute("SeatYaw", math.deg(yaw))
		-- Sample points along the plinth outline, measured against the rim.
		local base = SEAT_LAYERS[1]
		local outer, cut = base.cells * pitch / 2, (base.cells / 2 - base.corner) * pitch
		local outlinePoints = {}
		for k = 0, 7 do
			local a = math.rad(k * 45)
			local d = Vector2.new(math.cos(a), math.sin(a))
			local n = Vector2.new(-d.Y, d.X)
			local apothem = if k % 2 == 0 then outer else (outer + cut) / math.sqrt(2)
			local side = if k % 2 == 0 then cut else (outer - cut) / math.sqrt(2)
			for s = -1, 1, 0.25 do
				local q = d * apothem + n * side * s
				table.insert(outlinePoints, at(q.X, q.Y))
			end
		end
		local function margin(centre: Vector2): number
			local m = math.huge
			for _, q in outlinePoints do
				m = math.min(m, clearance(loops, centre + q))
			end
			return m
		end
		-- Centre the seat across its segment (front to back rim); its place along the arc stays.
		local c, best = home, margin(home)
		for t = -1.5, 1.5, 0.02 do
			local q = home + ez * t
			local m = margin(q)
			if m > best + 0.0001 then
				c, best = q, m
			end
		end
		seat.CFrame = seat.CFrame.Rotation + V(c.X, seat.Position.Y, c.Y)
		local bottom, worst = level, margin(c)
		for i, layer in SEAT_LAYERS do
			local half, inner = layer.cells * pitch / 2, (layer.cells / 2 - layer.corner) * pitch
			local h = layer.thickness * pitch
			local y = bottom + h / 2
			local pieces: { BasePart } = {}
			local function block(x0: number, x1: number, z0: number, z1: number)
				local p = Instance.new("Part")
				p.Size = V(math.abs(x1 - x0), h, math.abs(z1 - z0))
				local w = c + at((x0 + x1) / 2, (z0 + z1) / 2)
				p.CFrame = CFrame.fromMatrix(V(w.X, y, w.Y), V(ex.X, 0, ex.Y), Vector3.yAxis)
				p.Material = Enum.Material.SmoothPlastic
				HDStuds.apply(p, tile)
				p.Parent = pad
				table.insert(pieces, p)
			end
			block(-inner, inner, -half, half)
			block(-half, -inner, -inner, inner)
			block(inner, half, -inner, inner)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					for j = 0, layer.corner - 1 do
						-- Row j of the cut corner: whole cells, then the inner half of the diagonal cell.
						local whole = layer.corner - 1 - j
						local z0 = inner + j * pitch
						if whole > 0 then
							block(sx * inner, sx * (inner + whole * pitch), sz * z0, sz * (z0 + pitch))
						end
						local corner = c + at(sx * (inner + whole * pitch), sz * z0)
						table.insert(pieces, wedge(pad, corner, ex * sx, pitch, ez * sz, pitch, y, h))
					end
				end
			end
			-- The plinth takes the rim's dark edge colour so it reads as its own base, not the stand.
			local color = if i == 1 then Palette.PathEdge elseif colors then colors[i - 1] else Palette.PathEdge
			for _, p in pieces do
				p.Name, p.Color, p.Material = slot.Name .. "_" .. layer.name, color, Enum.Material.SmoothPlastic
				p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, true, false, true
				p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			end
			bottom += h
		end
		pad.Parent = slot
		seat.CFrame = seat.CFrame.Rotation + V(seat.Position.X, bottom, seat.Position.Z)
		slot:SetAttribute("SeatClearance", worst)
		if worst < SEAT_CLEARANCE then
			warn(string.format("[EggStandStyle] %s seat is %.2f from the rim", slot.Name, worst))
		end
	end
end

local function hideSupport(p: Instance?)
	if not p or not p:IsA("BasePart") then
		return
	end
	p.Transparency, p.CastShadow = 1, false
	-- A Texture still draws on a transparent part: the old pedestal studs would show through the seat.
	for _, t in p:GetChildren() do
		if t:IsA("Texture") or t:IsA("Decal") then
			t:Destroy()
		end
	end
	p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
	p:SetAttribute("PartRole", "HiddenVisual")
	p:SetAttribute("Purpose", "Legacy egg placement support; visible stand is EggShop.EggStand")
end

function Style.apply(world: Instance): number
	if world.Name ~= "World1" then
		return 0
	end
	local shop = Refs.eggs(world)
	local lobby = world:FindFirstChild("Lobby")
	local paths = lobby and lobby:FindFirstChild("Paths")
	local plaza = paths and paths:FindFirstChild("EggPlaza")
	local boards = Refs.rankings(world)
	if not shop or not plaza or not boards then
		return 0
	end
	local template = game.ServerStorage:FindFirstChild("EggStandTemplate")
	assert(template and template:IsA("Model"), "Missing persistent EggStandTemplate")
	for _, entry in SLOTS do
		local egg = shop:FindFirstChild(entry.model)
		assert(egg and egg:IsA("Model"), "Missing existing egg: " .. entry.model)
		assert(egg:FindFirstChild(if entry.slot == "Volcanic" then "Fallback" else "ImportedVisual"))
	end
	local low, high = extents(plaza, true)
	local boardLow = extents(boards)
	local centerX = (low.X + high.X) / 2
	local scale = math.min(120, high.X - low.X - 10) / 121
	assert(scale > 0.5 and scale < 1.5, "Unexpected egg plaza size")
	local baseY = high.Y + 0.025
	local centerZ = boardLow.Z - 2.5 - 9.25 * scale
	local existing = shop:FindFirstChild("EggStand")
	local stand: Model
	if existing then
		assert(existing:IsA("Model") and existing:GetAttribute("EggStandVersion") == VERSION, "Unknown EggStand")
		stand = existing
	else
		stand = template:Clone()
		stand.Name = "EggStand"
		stand:SetAttribute("EggStandVersion", VERSION)
		stand.WorldPivot = CFrame.identity
		stand:ScaleTo(scale)
		stand:PivotTo(CFrame.new(centerX, baseY, centerZ))
		for _, p in stand:GetDescendants() do
			if p:IsA("BasePart") then
				p.Anchored = true
				p.CanTouch = false
				if p.Name == "SeatCenter" then
					p.Transparency = 1
					p.CanCollide, p.CanQuery = false, false
					p:SetAttribute("PartRole", "InteractionAnchor")
					p:SetAttribute("Purpose", "Egg seat top and symmetry marker")
				end
			end
		end
		stand.Parent = shop
	end
	Style.colorSeats(stand)
	local pitch = Palette.GroundStudPitch * Scale.factor(world)
	lower(stand, pitch)
	recolor(stand)
	local loops = rim(stand, pitch)
	fitSeats(stand, loops)
	steps(stand, pitch)
	studs(stand, pitch)
	seats(stand, pitch, loops)
	-- Clearances were measured in the 0.8 scene and follow the world scale.
	local s = Scale.relative(world)
	-- Position by the visible egg's bounds, not its possibly offset authored pivot.
	for _, entry in SLOTS do
		local egg = shop:FindFirstChild(entry.model) :: Model
		local slot = stand:FindFirstChild(entry.slot)
		local seat = slot and slot:FindFirstChild("SeatCenter") :: BasePart?
		assert(seat and seat:IsA("BasePart"), "Missing seat marker")
		local premium = entry.slot == "Volcanic"
		local visual = egg:FindFirstChild(if premium then "Fallback" else "ImportedVisual")
		local cf: CFrame
		local size: Vector3
		if visual and visual:IsA("Model") then
			cf, size = visual:GetBoundingBox()
		else
			assert(visual and visual:IsA("BasePart"))
			cf, size = visual.CFrame, visual.Size
		end
		local gap = 0.08 * s
		local delta = V(seat.Position.X - cf.X, seat.Position.Y + gap - (cf.Y - size.Y / 2), seat.Position.Z - cf.Z)
		egg:PivotTo(egg:GetPivot() + delta)
		local anchor = egg:FindFirstChild(if premium then "InteractionAnchor" else "EggShell")
		assert(anchor and anchor:IsA("BasePart"))
		anchor.CFrame = CFrame.new(seat.Position.X, anchor.Position.Y, seat.Position.Z) * anchor.CFrame.Rotation
		anchor:SetAttribute("PartRole", "InteractionAnchor")
		local support = egg:FindFirstChild(if premium then "Pedestal" else "EggPedestal")
		assert(support and support:IsA("BasePart"))
		support.CFrame = CFrame.new(seat.Position.X, seat.Position.Y - support.Size.Y / 2, seat.Position.Z)
		hideSupport(support)
		local ring = egg:FindFirstChild("EggRing")
		if ring and ring:IsA("BasePart") then
			ring.CFrame =
				CFrame.new(seat.Position.X, seat.Position.Y + gap - 0.3 * s - ring.Size.Y / 2, seat.Position.Z)
			hideSupport(ring)
		end
		local caption = egg:FindFirstChild("EggSignAnchor", true)
		if caption and caption:IsA("BasePart") then
			caption.CFrame = CFrame.new(seat.Position.X, seat.Position.Y + gap + size.Y + 2.4 * s, seat.Position.Z)
		end
		if premium then
			egg:SetAttribute("EggDisplayHeight", size.Y)
			egg:SetAttribute("EggDisplayGap", gap)
		end
		egg:SetAttribute("EggStandVersion", VERSION)
	end
	world:SetAttribute("EggStandVersion", VERSION)
	return #SLOTS
end

return Style
