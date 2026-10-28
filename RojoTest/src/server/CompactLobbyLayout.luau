--!strict
-- Approved reference 3: cosmetic paving around the existing, protected lobby stations.
local Layout = {}
local V, P, RGB = Vector3.new, Vector2.new, Color3.fromRGB
local WHITE = RGB(242, 237, 221)
local STONE = RGB(216, 218, 213)
local VERSION = 1
type Region = { name: string, polygon: { Vector2 }, fill: Color3, edge: Color3, openX: number?, openZ: number? }

local function cross(a: Vector2, b: Vector2): number
	return a.X * b.Y - a.Y * b.X
end

local function rectangle(x0: number, x1: number, z0: number, z1: number): { Vector2 }
	return { P(x0, z0), P(x1, z0), P(x1, z1), P(x0, z1) }
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

local function inset(polygon: { Vector2 }, amount: number): { Vector2 }
	local result = {}
	for i, p in polygon do
		local before, after = polygon[(i - 2) % #polygon + 1], polygon[i % #polygon + 1]
		local a, b = (p - before).Unit, (after - p).Unit
		local start = before + P(-a.Y, a.X) * amount
		local finish = p + P(-b.Y, b.X) * amount
		local t = cross(finish - start, b) / cross(a, b)
		table.insert(result, start + a * t)
	end
	return result
end

local function hideOldPaving(map: Instance)
	local old = map:FindFirstChild("GeometryPolish")
	if not old then
		return
	end
	for _, p in old:GetDescendants() do
		if p:IsA("BasePart") then
			if p:GetAttribute("BeforeCompactLobbyTransparency") == nil then
				p:SetAttribute("BeforeCompactLobbyTransparency", p.Transparency)
			end
			p.Transparency = 1
		elseif p:IsA("Decal") then
			p.Transparency = 1
		end
	end
end

function Layout.apply(map: Instance): Instance?
	if map.Name ~= "World1" then
		return nil
	end
	local existing = map:FindFirstChild("CompactLobbyLayout")
	if existing then
		assert(
			(existing:IsA("Folder") or existing:IsA("Model")) and existing:GetAttribute("Version") == VERSION,
			"Inspect partial compact lobby before retry"
		)
		hideOldPaving(map)
		return existing
	end
	local lobby = assert(map:FindFirstChild("Lobby"))
	local apron = assert(lobby:FindFirstChild("ThrowingApron")) :: BasePart
	local zone = assert(map:FindFirstChild("TrainingZone"))
	local first = assert(zone:FindFirstChild("TrainingLane1"))
	local strip = assert(first:FindFirstChild("TrainingStrip")) :: BasePart
	assert((strip.Position - V(103, 21.4, 177)).Magnitude < 0.02, "Authored lobby changed: remeasure before applying")
	local top = apron.Position.Y - 0.3 + 0.26
	local root = Instance.new("Folder")
	root.Name = "CompactLobbyLayout"
	root.Parent = map
	local regions: { Region } = {
		{
			name = "Boulevard",
			polygon = rectangle(58, 77, 149, 300),
			fill = STONE,
			edge = RGB(169, 176, 183),
			openZ = 149,
		},
		{
			name = "PortalCourt",
			polygon = {
				P(-15, 150),
				P(21, 150),
				P(29, 158),
				P(29, 186),
				P(21, 194),
				P(-15, 194),
				P(-23, 186),
				P(-23, 158),
			},
			fill = RGB(226, 218, 233),
			edge = RGB(172, 155, 196),
		},
		{ name = "PortalApproach", polygon = rectangle(29, 58, 165, 179), fill = STONE, edge = RGB(169, 176, 183) },
		{
			name = "BallCourt",
			polygon = { P(-29, 197), P(26, 197), P(38, 209), P(38, 231), P(26, 243), P(-29, 243) },
			fill = RGB(214, 220, 224),
			edge = RGB(137, 159, 181),
		},
		{ name = "BallApproach", polygon = rectangle(38, 58, 211, 225), fill = STONE, edge = RGB(169, 176, 183) },
		{
			name = "EggCourt",
			polygon = { P(-44, 275), P(-25, 250), P(41, 250), P(41, 297), P(-25, 297) },
			fill = RGB(226, 218, 201),
			edge = RGB(190, 177, 148),
		},
		{ name = "EggApproach", polygon = rectangle(41, 58, 271, 283), fill = STONE, edge = RGB(169, 176, 183) },
		-- Preserve the existing hall-of-fame footprint and all its boards.
		{ name = "HallArrival", polygon = rectangle(8, 122, 300, 343), fill = STONE, edge = RGB(169, 176, 183) },
	}
	for i = 1, 7 do
		local lane = assert(zone:FindFirstChild("TrainingLane" .. i))
		local surface = assert(lane:FindFirstChild("TrainingStrip")) :: BasePart
		local foundation = assert(lane:FindFirstChild("Foundation")) :: BasePart
		local front = foundation.Position.X - foundation.Size.X / 2
		table.insert(regions, {
			name = "TrainingApproach" .. i,
			polygon = rectangle(77, front, surface.Position.Z - 6.5, surface.Position.Z + 6.5),
			fill = STONE,
			edge = RGB(169, 176, 183),
			openX = front,
		})
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
	local function block(
		parent: Instance,
		name: string,
		x: number,
		y: number,
		z: number,
		sx: number,
		sy: number,
		sz: number,
		color: Color3
	): Part
		return part(parent, name, V(sx, sy, sz), CFrame.new(x, y, z), color)
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
	local function triangle(
		parent: Instance,
		name: string,
		a: Vector3,
		b: Vector3,
		c: Vector3,
		thickness: number,
		color: Color3
	)
		local ab, ac, bc = b - a, c - a, c - b
		if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
			c, a = a, c
		elseif ac.Magnitude > bc.Magnitude then
			a, b = b, a
		end
		ab, ac, bc = b - a, c - a, c - b
		if ac:Cross(ab).Magnitude < 0.00001 then
			return
		end
		local right, back = ac:Cross(ab).Unit, bc.Unit
		local up = back:Cross(right).Unit
		local height = math.abs(ab:Dot(up))
		local pieces = {
			{ center = (a + b) / 2, right = right, back = back, span = math.abs(ab:Dot(back)) },
			{ center = (a + c) / 2, right = -right, back = -back, span = math.abs(ac:Dot(back)) },
		}
		for _, data in pieces do
			if data.span < 0.0001 or height < 0.0001 then
				continue
			end
			local p = Instance.new("WedgePart")
			p.Name, p.Size, p.CFrame =
				name, V(thickness, height, data.span), CFrame.fromMatrix(data.center, data.right, up, data.back)
			p.Anchored = true
			p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = false, false, false, false
			p.Material, p.Color = Enum.Material.SmoothPlastic, color
			p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			p.Parent = parent
		end
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
	local function scan(polygon: { Vector2 }, value: number, alongX: boolean): (number?, number?)
		local hits = {}
		for i, a in polygon do
			local b = polygon[i % #polygon + 1]
			local av, bv = if alongX then a.X else a.Y, if alongX then b.X else b.Y
			if (av <= value and bv > value) or (bv <= value and av > value) then
				local p = a + (b - a) * ((value - av) / (bv - av))
				table.insert(hits, if alongX then p.Y else p.X)
			end
		end
		if #hits < 2 then
			return nil, nil
		end
		table.sort(hits)
		return hits[1], hits[#hits]
	end
	for _, region in regions do
		local group = Instance.new("Model")
		group.Name, group.WorldPivot = region.name, CFrame.new(65, top, 224)
		for i = 2, #region.polygon - 1 do
			local a, b, c = region.polygon[1], region.polygon[i], region.polygon[i + 1]
			triangle(
				group,
				"PavingSurface",
				V(a.X, top - 0.02, a.Y),
				V(b.X, top - 0.02, b.Y),
				V(c.X, top - 0.02, c.Y),
				0.04,
				region.fill
			)
		end
		local inner = inset(region.polygon, 1.4)
		local lo, hi = P(math.huge, math.huge), P(-math.huge, -math.huge)
		for _, p in inner do
			lo = P(math.min(lo.X, p.X), math.min(lo.Y, p.Y))
			hi = P(math.max(hi.X, p.X), math.max(hi.Y, p.Y))
		end
		local joint = region.fill:Lerp(RGB(125, 139, 146), 0.35)
		for x = math.ceil(lo.X / 4) * 4, hi.X, 4 do
			local z0, z1 = scan(inner, x, true)
			if z0 and z1 and z1 - z0 > 0.01 then
				bar(group, "StoneJoint", P(x, z0), P(x, z1), 0.075, 0.012, top + 0.040, joint)
			end
		end
		for z = math.ceil(lo.Y / 4) * 4, hi.Y, 4 do
			local x0, x1 = scan(inner, z, false)
			if x0 and x1 and x1 - x0 > 0.01 then
				bar(group, "StoneJoint", P(x0, z), P(x1, z), 0.075, 0.012, top + 0.042, joint)
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
					bar(group, "IvoryCurb", p + outward * 0.25, q + outward * 0.25, 0.50, 0.08, top - 0.03, WHITE)
					bar(
						group,
						"InsetBorder",
						p - outward * 0.66,
						q - outward * 0.66,
						0.58,
						0.025,
						top + 0.024,
						region.edge
					)
				end
			end
		end
		group.Parent = root
		task.wait()
	end

	-- Simple junction medallions emphasize the three destinations without directional arrows.
	local details = Instance.new("Model")
	details.Name, details.WorldPivot = "BoulevardInlays", CFrame.new(65, top, 224)
	for _, z in { 172, 218, 277 } do
		block(details, "ThresholdFrame", 67.5, top + 0.03, z, 5.2, 0.025, 5.2, RGB(182, 189, 192)).CastShadow = false
		block(details, "ThresholdInset", 67.5, top + 0.055, z, 3.7, 0.02, 3.7, RGB(204, 209, 208)).CastShadow = false
	end
	for z = 156, 296, 12 do
		block(details, "BoulevardPaverAccent", 67.5, top + 0.028, z, 2.0, 0.02, 2.0, RGB(196, 201, 200)).CastShadow =
			false
	end
	details.Parent = root

	local world = assert(map:FindFirstChild("SkippingWorld"))
	local flowers = world:FindFirstChild("ImprovedLobbyFlowers")
	local flowerTemplate = flowers and flowers:FindFirstChild("Flower")
	local function planter(x: number, z: number, tree: boolean, index: number)
		local group = Instance.new("Model")
		group.Name, group.WorldPivot = "Planter", CFrame.new(x, top, z)
		local width, depth = 3.8, 2.9
		block(group, "PlanterFoot", x, top + 0.16, z, width + 0.3, 0.32, depth + 0.3, RGB(157, 164, 156))
		block(group, "PlanterStone", x, top + 0.44, z, width, 0.36, depth, WHITE)
		block(group, "Soil", x, top + 0.65, z, width - 0.42, 0.08, depth - 0.42, RGB(74, 94, 55))
		if tree then
			block(group, "ShrubTrunk", x - 0.45, top + 1.35, z, 0.30, 1.40, 0.30, RGB(112, 85, 51))
			for layer = 0, 2 do
				local size = 2.25 - layer * 0.46
				local base = top + 1.20 + layer * 0.88
				local peak = V(x - 0.45, base + 1.60, z)
				local ring = {
					V(x - 0.45 - size / 2, base, z - size / 2),
					V(x - 0.45 + size / 2, base, z - size / 2),
					V(x - 0.45 + size / 2, base, z + size / 2),
					V(x - 0.45 - size / 2, base, z + size / 2),
				}
				for j = 1, 4 do
					triangle(
						group,
						"EvergreenCrown",
						ring[j],
						ring[j % 4 + 1],
						peak,
						0.035,
						RGB(42 + layer * 7, 123 + layer * 10, 57 + layer * 4)
					)
				end
			end
		else
			for j = 0, 2 do
				local p = block(
					group,
					"LowHedge",
					x - 0.95 + j * 0.72,
					top + 1.11,
					z,
					1.12,
					0.90,
					1.58,
					RGB(58 + j * 8, 151 + j * 6, 54)
				)
				p.CFrame *= CFrame.Angles(0, math.rad(j * 8 - 8), 0)
			end
		end
		if flowerTemplate and flowerTemplate:IsA("Model") then
			for j = 1, 2 do
				local clone = flowerTemplate:Clone()
				clone.Name = "PlantedFlower"
				clone:ScaleTo(0.58)
				clone:PivotTo(CFrame.new(x + 0.70 + (j - 1) * 0.5, top + 0.72, z - 0.50 + (j - 1) * 0.85))
				for _, p in clone:GetDescendants() do
					if p:IsA("BasePart") then
						p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
						if p.Name == "Petal" then
							p.Color = if (index + j) % 3 == 0 then RGB(250, 195, 216) else WHITE
						end
					end
				end
				clone.Parent = group
			end
		end
		group.Parent = root
		task.wait()
	end
	local function lamp(x: number, z: number)
		local group = Instance.new("Model")
		group.Name, group.WorldPivot = "PromenadeLamp", CFrame.new(x, top, z)
		local dark = RGB(45, 57, 63)
		block(group, "StoneFoot", x, top + 0.18, z, 1.60, 0.36, 1.60, WHITE)
		block(group, "LampBase", x, top + 0.43, z, 0.83, 0.24, 0.83, dark)
		block(group, "Post", x, top + 2.9, z, 0.40, 4.8, 0.40, dark)
		block(group, "LanternCase", x, top + 5.15, z, 1.20, 1.35, 1.20, dark)
		local window = block(group, "WarmWindow", x, top + 5.15, z, 1.23, 0.85, 0.79, RGB(255, 223, 150))
		window.Material = Enum.Material.Neon
		local second = block(group, "WarmWindow", x, top + 5.15, z, 0.79, 0.85, 1.23, RGB(255, 223, 150))
		second.Material = Enum.Material.Neon
		block(group, "LanternCap", x, top + 5.87, z, 1.44, 0.16, 1.44, dark)
		group.Parent = root
	end
	local beds = {
		P(54, 155),
		P(54, 190),
		P(54, 201),
		P(54, 241),
		P(54, 253),
		P(54, 293),
		P(-22, 200),
		P(26, 202),
		P(26, 238),
		P(-22, 240),
		P(-21, 254),
		P(35, 255),
		P(35, 292),
		P(-22, 292),
		P(20, 155),
		P(20, 189),
	}
	for i = 1, 7 do
		table.insert(beds, P(81, 177 + (i - 1) * 17 + 8.5))
	end
	for i, p in beds do
		planter(p.X, p.Y, i % 3 ~= 0, i)
	end
	for _, p in
		{
			P(56.7, 157),
			P(56.7, 190),
			P(56.7, 201),
			P(56.7, 241),
			P(56.7, 253),
			P(56.7, 293),
			P(-24, 201),
			P(31, 207),
			P(31, 234),
			P(-24, 239),
			P(-24, 255),
			P(38, 255),
			P(38, 292),
			P(-24, 291),
			P(23, 157),
			P(23, 187),
		}
	do
		lamp(p.X, p.Y)
	end
	for i = 1, 6 do
		lamp(77.9, 177 + (i - 1) * 17 + 8.5)
	end
	-- Hide only the retired render layer. Every original collision and gameplay part remains.
	hideOldPaving(map)
	root:SetAttribute("Version", VERSION)
	root:SetAttribute("PavingTop", top)
	return root
end

return Layout
