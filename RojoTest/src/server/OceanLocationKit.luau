-- Authoring kit for the approved Ocean Depths locations. Units follow the 1.2 stud grid.
local Look = require(script.Parent.OceanDepthsLook)
local Ground = require(script.Parent.OceanReefGround)
local HDStuds = require(script.Parent.HDStuds)
local Kit = {}
local C = Color3.fromHex
local faces = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }

function Kit.new(field: BasePart, tile: number)
	local k: any = { field = field, tile = tile, surfaces = {}, shore = 6.074 }
	function k.at(x: number, y: number, s: number): CFrame
		return field.CFrame * CFrame.new(x, y, field.Size.Z / 2 - s)
	end
	function k.studs(p: BasePart)
		for _, face in faces do
			local a = if face == Enum.NormalId.Left or face == Enum.NormalId.Right then p.Size.Y else p.Size.X
			local b = if face == Enum.NormalId.Top
				then p.Size.Z
				elseif face == Enum.NormalId.Left or face == Enum.NormalId.Right then p.Size.Z
				else p.Size.Y
			if
				math.min(a, b) < 1.19
				or math.abs(a / 1.2 - math.round(a / 1.2)) > 0.002
				or math.abs(b / 1.2 - math.round(b / 1.2)) > 0.002
			then
				continue
			end
			HDStuds.apply(p, tile)
			return
		end
	end
	function k.box(parent: Instance, name: string, cf: CFrame, size: Vector3, tone: Color3, smooth: boolean?): Part
		local p = Look.part(parent, name, cf, size, tone)
		if not smooth then
			k.studs(p)
		end
		return p
	end
	function k.wedge(parent: Instance, name: string, cf: CFrame, size: Vector3, tone: Color3): WedgePart
		local p = Instance.new("WedgePart")
		p.Name = name
		p.CFrame = cf
		p.Size = size
		p.Color = tone
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		k.studs(p)
		p.Parent = parent
		return p
	end
	function k.grounded(model: Model, cf: CFrame, footprint: Vector2)
		model.WorldPivot = cf
		model:SetAttribute("SupportFootprint", footprint)
		model:SetAttribute("PlacementRole", "Grounded")
	end
	function k.root(parent: Instance, name: string, cf: CFrame, footprint: Vector2): (Model, CFrame)
		local settled = Ground.fit(k.surfaces, cf, footprint, 0.2, 10)
		local m = Look.model(parent, name)
		k.grounded(m, settled, footprint)
		return m, settled
	end
	function k.asset(
		parent: Instance,
		name: string,
		cf: CFrame,
		scale: number,
		footprint: Vector2?,
		motion: string?
	): Model
		local ocean = game.ServerStorage.Assets.OceanDepths
		local pack = ocean:FindFirstChild("LocationKit")
		local template = (pack and pack:FindFirstChild(name)) or ocean.SeaLife:FindFirstChild(name)
		assert(template and template:IsA("Model"), "Import location kit first: " .. name)
		local m = template:Clone()
		m:ScaleTo(scale)
		if footprint then
			cf = Ground.fit(k.surfaces, cf, footprint, 0.2, 10)
		else
			m:SetAttribute("PlacementRole", "Waterborne")
		end
		m:PivotTo(cf)
		if footprint then
			k.grounded(m, cf, footprint)
		end
		if motion then
			m:SetAttribute("OceanMotion", motion)
		end
		m.Parent = parent
		return m
	end
	function k.terrace(parent: Instance, cf: CFrame, width: number, depth: number, tiers: number, tone: Color3): CFrame
		local m, base = k.root(parent, "StoneTerrace", cf, Vector2.new(width, depth))
		for tier = 1, tiers do
			local h = 3.6
			local offset = (tier - 1) % 2 * 1.2
			local size = Vector3.new(width - (tier - 1) * 4.8, h, depth - (tier - 1) * 4.8)
			local p = k.box(
				m,
				"StoneTier",
				base * CFrame.new(offset, (tier - 0.5) * h, -offset),
				size,
				tone:Lerp(C("86C4E4"), (tier - 1) * 0.1)
			)
			p:SetAttribute("SupportBase", base.Position.Y + (tier - 1) * h)
			p.CanCollide = true
			Ground.add(k.surfaces, p)
		end
		return base * CFrame.new((tiers - 1) % 2 * 1.2, tiers * 3.6, -((tiers - 1) % 2) * 1.2)
	end
	function k.segment(
		parent: Instance,
		name: string,
		a: Vector3,
		b: Vector3,
		width: number,
		tone: Color3,
		smooth: boolean?
	): Part
		local d = b - a
		local up = if math.abs(d.Unit.Y) > 0.98 then Vector3.zAxis else Vector3.yAxis
		return k.box(
			parent,
			name,
			CFrame.lookAt((a + b) / 2, b, up),
			Vector3.new(width, width, d.Magnitude + 0.05),
			tone,
			smooth
		)
	end
	function k.light(parent: BasePart, tone: Color3, range: number, brightness: number): PointLight
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = tone, range, brightness
		l.Shadows = false
		l.Parent = parent
		return l
	end
	function k.shell(parent: Instance, cf: CFrame, scale: number): Model
		return k.asset(parent, "PearlShellValve", cf, scale, nil, nil)
	end
	return k
end

function Kit.column(k: any, parent: Instance, cf: CFrame, height: number): Model
	local m = Look.model(parent, "SandstoneColumn")
	k.box(m, "Foot", cf * CFrame.new(0, 1.2, 0), Vector3.new(7.2, 2.4, 7.2), C("EBD49E"))
	k.box(m, "Shaft", cf * CFrame.new(0, 2.4 + height / 2, 0), Vector3.new(4.8, height, 4.8), C("FFF0C5"))
	k.box(m, "TurquoiseCapital", cf * CFrame.new(0, height + 3.6, 0), Vector3.new(6, 2.4, 6), C("4EC4C4"))
	k.box(m, "Capital", cf * CFrame.new(0, height + 5.4, 0), Vector3.new(7.2, 1.2, 7.2), C("F4E4B2"))
	return m
end

function Kit.chimney(k: any, parent: Instance, cf: CFrame, height: number, radius: number): Model
	cf = Ground.fit(k.surfaces, cf, Vector2.new(radius * 2.4, radius * 2.4), 0.2)
	local m = Look.model(parent, "HydrothermalChimney")
	k.grounded(m, cf, Vector2.new(radius * 2.4, radius * 2.4))
	for side = 0, 7 do
		local turn = cf * CFrame.Angles(0, side * math.pi / 4, 0)
		k.box(
			m,
			"BasaltWall",
			turn * CFrame.new(0, height / 2, radius * 0.86),
			Vector3.new(radius * 0.82, height, 2.4),
			C("2D4156")
		)
		k.box(
			m,
			"MineralRim",
			turn * CFrame.new(0, height + 0.6, radius * 0.86),
			Vector3.new(radius * 0.82, 1.2, 2.4),
			C("BCCFD3")
		)
	end
	k.box(
		m,
		"DarkMouth",
		cf * CFrame.new(0, height - 2.4, 0),
		Vector3.new(radius * 1.2, 1.2, radius * 1.2),
		C("172D43"),
		true
	)
	local plume = game.ServerStorage.Assets.OceanDepths.Effects.MineralPlume:Clone()
	plume.CFrame = cf * CFrame.new(0, height + 1.2, 0)
	plume.Parent = m
	return m
end

function Kit.worms(k: any, parent: Instance, cf: CFrame, count: number)
	local m, settled = k.root(parent, "TubeWormColony", cf, Vector2.new(8.4, 8.4))
	cf = settled
	for i = 1, count do
		local a = i * 2.4
		local radius = 1.4 + (i % 3) * 0.9
		local p = (cf * CFrame.new(math.cos(a) * radius, 0, math.sin(a) * radius)).Position
		local top = p + Vector3.new(0.4, 5.6 + (i % 4) * 1.5, 0.3)
		k.segment(m, "IvoryTube", p, top, 0.8, C("F8F1D7"), true)
		for j = 1, 5 do
			local b = top + Vector3.new(math.cos(j * 1.26) * 1.8, 1.9, math.sin(j * 1.26) * 1.8)
			k.segment(m, "CrimsonCrown", top, b, 0.3, C("ED4F67"), true)
		end
	end
	return m
end

function Kit.ship(k: any, parent: Instance, cf: CFrame, scale: number): Model
	local m = Look.model(parent, "SandfilledGalleon")
	m.WorldPivot = cf
	local brown = C("975625")
	local gold = C("E6AD47")
	local function box(name, at, size, tone, smooth)
		return k.box(m, name, cf * at, size, tone, smooth)
	end
	-- The continuous keel sits in the sand. Upper plank courses flare into the recognizable hull.
	box("Keel", CFrame.new(0, 1.2, 0), Vector3.new(10.8, 2.4, 67.2), C("734126"))
	for row = 1, 4 do
		for section = 1, 7 do
			local z = (section - 4) * 9.6
			local width = 13.2 + row * 2.4 - math.abs(section - 4) * 2.4
			for _, side in { -1, 1 } do
				local broken = row >= 2
					and ((section == 3 or section == 4) and side == 1 or row >= 3 and section == 5 and side == -1)
				if not broken then
					box(
						"HullPlank",
						CFrame.new(side * width / 2, row * 2.4, z),
						Vector3.new(2.4, 2.4, 9.6),
						if row == 4 then gold else brown:Lerp(C("C98A40"), (section % 3) * 0.12)
					)
				end
			end
			if row == 1 then
				box("SandInHull", CFrame.new(0, 3.1, z), Vector3.new(width, 1.2, 9.6), C("E4C991"), true)
			end
		end
	end
	for _, z in { -24, -12, 0, 12, 24 } do
		box("DeckRib", CFrame.new(0, 6, z), Vector3.new(19.2, 1.2, 1.2), C("6C3E28"))
	end
	box("SternDeck", CFrame.new(0, 10.8, 24), Vector3.new(21.6, 2.4, 14.4), C("B77838"))
	box("RaisedProw", CFrame.new(0, 10.8, -36), Vector3.new(2.4, 16.8, 3.6), gold)
	for _, side in { -1, 1 } do
		k.segment(
			m,
			"SweptBowRail",
			(cf * CFrame.new(side * 7.2, 10.8, -28.8)).Position,
			(cf * CFrame.new(0, 16.8, -37.2)).Position,
			2.4,
			gold
		)
	end
	for i = 1, 5 do
		local a = (i - 1) * math.pi / 4
		local b = i * math.pi / 4
		k.segment(
			m,
			"ProwScroll",
			(cf * CFrame.new(0, 18 + 2.4 * math.sin(a), -36 + 2.4 * math.cos(a))).Position,
			(cf * CFrame.new(0, 18 + 2.4 * math.sin(b), -36 + 2.4 * math.cos(b))).Position,
			1.2,
			gold
		)
	end
	for _, x in { -7.2, 7.2 } do
		box("CabinFrame", CFrame.new(x, 15.6, 25.2), Vector3.new(2.4, 7.2, 9.6), C("986031"))
	end
	box("BrokenCabinRoof", CFrame.new(-3.6, 19.8, 25.2), Vector3.new(12, 1.2, 12), gold)
	box("CabinSill", CFrame.new(0, 12.6, 30), Vector3.new(16.8, 1.2, 1.2), brown)
	box("CabinLintel", CFrame.new(-2.4, 18.6, 30), Vector3.new(12, 1.2, 1.2), brown)
	for _, x in { -7.2, 7.2 } do
		box("CabinWindow", CFrame.new(x, 16.8, 30.05), Vector3.new(2.4, 3.6, 0.2), C("193D50"), true)
	end
	for _, side in { -1, 1 } do
		for _, z in { -19.2, 0, 19.2 } do
			if side == 1 and z == 0 then
				continue
			end
			local section = math.round(z / 9.6) + 4
			local outerFace = (20.4 - math.abs(section - 4) * 2.4) / 2 + 1.2
			local port = Look.ellipsoid(
				m,
				"BrassPorthole",
				cf * CFrame.new(side * (outerFace + 0.25), 7.2, z),
				Vector3.new(0.6, 3.1, 3.1),
				gold
			)
			Look.ellipsoid(
				m,
				"PortholeGlass",
				port.CFrame * CFrame.new(side * 0.33, 0, 0),
				Vector3.new(0.12, 2.2, 2.2),
				C("16485B")
			)
		end
	end
	for index, z in { -14.4, 16.8 } do
		local mast = cf * CFrame.new(0, 3.6, z) * CFrame.Angles(0, 0, if index == 1 then -0.19 else 0.12)
		k.segment(m, "BrokenMast", mast.Position, (mast * CFrame.new(0, 33 - index * 4, 0)).Position, 1.2, C("87522B"))
		local spar = mast * CFrame.new(0, 24 - index * 3, 0)
		k.box(m, "Spar", spar, Vector3.new(25.2, 1.2, 1.2), brown)
		for strip = -3, 3 do
			if strip == 0 or strip == 2 and index == 1 then
				continue
			end
			local h = ({ 9.6, 4.8, 12, 3.6, 7.2, 6, 10.8 })[strip + 4]
			k.box(
				m,
				"TornCreamSail",
				spar * CFrame.new(strip * 3.6, -h / 2 - 0.6, 0.4),
				Vector3.new(2.4, h, 0.12),
				C("F2DCAA")
			)
		end
		for _, side in { -1, 1 } do
			k.segment(
				m,
				"Rigging",
				(spar * CFrame.new(side * 12, 0, 0)).Position,
				(cf * CFrame.new(side * 10, 8, z + 10)).Position,
				0.16,
				C("BCA271"),
				true
			)
		end
	end
	-- Scale around the root, so the footprint remains predictable when planted.
	m:ScaleTo(scale)
	if scale < 1.75 then
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") and p.MaterialVariant:match("^HDStuds_") then
				HDStuds.apply(p, k.tile * 0.75)
			end
		end
	end
	return m
end

return Kit
