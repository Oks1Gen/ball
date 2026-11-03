--!strict
-- Both checker colours share one complete-cell lattice; thin cap sides stay smooth.
local Palette = require(script.Parent.LobbyPalette)
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Grid = require(game.ReplicatedStorage.Shared.Core.SurfaceGrid)
local Coverage = {}
local V = Vector3.new
local function component(vector: Vector3, axis: string): number
	return if axis == "X" then vector.X elseif axis == "Y" then vector.Y else vector.Z
end
local VERSION = "whole-wall-1"
local EARTH = { TerraceEarth = true, RearEarthLedge = true, LeftAbutment = true, RightAbutment = true }
local CAPS = { GrassShelf = true, RearGrassLedge = true, LeftAbutmentGrassCap = true, RightAbutmentGrassCap = true }
local OLD = {
	TerraceWallChecker = true,
	TerraceEarthChecker = true,
	RearEarthLedgeChecker = true,
	LeftAbutmentChecker = true,
	RightAbutmentChecker = true,
}

function Coverage.plan(world: any): any
	local environment = world.Lobby.Environment
	local owners, sources, solids = {}, {}, {}
	local signature = {
		VERSION,
		tostring(Palette.Earth),
		tostring(Palette.EarthDark),
		Palette.Studs,
		tostring(Palette.StudsTransparency),
		tostring(Palette.WallCheckerCell),
		tostring(Palette.WallStudPitch),
	}
	for _, name in { "SideTerraces1", "SideTerraces2", "RearTerraces", "EntranceTunnel" } do
		local owner = environment:FindFirstChild(name)
		if owner then
			table.insert(owners, owner)
			for _, p in owner:GetDescendants() do
				if p:IsA("BasePart") and p.Transparency < 1 and (EARTH[p.Name] or CAPS[p.Name]) then
					assert(
						p.CFrame.RightVector:Dot(Vector3.xAxis) > 0.9999
							and p.CFrame.UpVector:Dot(Vector3.yAxis) > 0.9999,
						"Measure rotated lobby walls"
					)
					local lo, hi = p.Position - p.Size / 2, p.Position + p.Size / 2
					table.insert(sources, { part = p, owner = owner, lo = lo, hi = hi, cap = CAPS[p.Name] == true })
					table.insert(solids, { part = p, lo = lo, hi = hi })
					table.insert(signature, name .. p.Name .. tostring(p.CFrame) .. tostring(p.Size))
					if CAPS[p.Name] then
						table.insert(signature, tostring(p.Color))
					end
				end
			end
		end
	end
	local ground = 20.12
	for _, p in world.Lobby.Geometry:GetChildren() do
		if p:IsA("BasePart") and p.Name == "GroundTile" and p.Transparency < 1 then
			ground = p.Position.Y + p.Size.Y / 2
			break
		end
	end
	local field = assert(Refs.field(world, 1))
	local origin = V(field.Position.X, ground, field.Position.Z + field.Size.Z / 2)
	table.insert(signature, tostring(origin))
	local planes = {}
	local byKey = {}
	for _, source in sources do
		local p, lo, hi = source.part, source.lo, source.hi
		local directions: { Enum.NormalId } = if source.cap
			then { Enum.NormalId.Top }
			elseif source.owner.Name == "RearTerraces" then { Enum.NormalId.Front }
			else {
				Enum.NormalId.Front,
				Enum.NormalId.Back,
				if p.Position.X < origin.X then Enum.NormalId.Right else Enum.NormalId.Left,
			}
		for _, face in directions do
			local normal = Vector3.FromNormalId(face)
			local axis = if normal.X ~= 0 then "X" elseif normal.Y ~= 0 then "Y" else "Z"
			local u, v = if axis == "X" then "Z" else "X", if axis == "Y" then "Z" else "Y"
			local sign = component(normal, axis)
			local plane = if sign > 0 then hi[axis] else lo[axis]
			local bottom = if source.cap then lo[v] else math.max(ground, lo[v])
			local visible = { { lo[u], hi[u], bottom, hi[v] } }
			for _, solid in solids do
				if solid.part == p then
					continue
				end
				local near = if sign > 0 then solid.lo[axis] else -solid.hi[axis]
				local far = if sign > 0 then solid.hi[axis] else -solid.lo[axis]
				if near <= sign * plane + 0.03 and far > sign * plane + 0.04 then
					local rest = {}
					for _, r in visible do
						for _, piece in Grid.subtract(r, { solid.lo[u], solid.hi[u], solid.lo[v], solid.hi[v] }) do
							table.insert(rest, piece)
						end
					end
					visible = rest
				end
			end
			if #visible == 0 then
				continue
			end
			local key = source.owner.Name .. ":" .. face.Name .. ":" .. math.round(plane * 1000)
			local surface = byKey[key]
			if not surface then
				surface = {
					key = key,
					owner = source.owner,
					axis = axis,
					u = u,
					v = v,
					sign = sign,
					plane = plane,
					face = face,
					cap = source.cap,
					color = p.Color,
					rectangles = {},
					originU = component(origin, u),
					originV = component(origin, v),
					parity = math.floor((plane - component(origin, axis)) / Palette.WallCheckerCell - sign * 0.0001),
				}
				byKey[key] = surface
				table.insert(planes, surface)
			end
			for _, r in visible do
				table.insert(surface.rectangles, r)
			end
		end
	end
	table.sort(planes, function(a, b)
		return a.key < b.key
	end)
	for _, surface in planes do
		surface.rectangles = Grid.union(surface.rectangles)
		local step = if surface.cap then Palette.WallStudPitch else Palette.WallCheckerCell
		surface.cells = Grid.wholeCells(surface.rectangles, step, surface.originU, surface.originV)
		surface.step = step
		surface.pieces = if surface.cap then Grid.merge(surface.cells) else nil
	end
	table.sort(signature)
	return {
		owners = owners,
		sources = sources,
		planes = planes,
		origin = origin,
		signature = table.concat(signature, "|"),
	}
end

local function normalize(plan: any)
	for _, source in plan.sources do
		for _, t in source.part:GetChildren() do
			if t:IsA("Texture") and (t.Texture == Palette.Studs or t.Name:find("Studs")) then
				t:Destroy()
			end
		end
		if not source.cap then
			source.part.Color = Palette.Earth
		end
	end
end

function Coverage.apply(world: any): any
	local plan = Coverage.plan(world)
	local legacy = {}
	for _, root in world.Lobby.Geometry:GetChildren() do
		if OLD[root.Name] then
			table.insert(legacy, root)
		end
	end
	local ready = #legacy == 0
	local total = 0
	for _, owner in plan.owners do
		local existing = owner:FindFirstChild("WallCladding")
		if existing then
			assert(existing:GetAttribute("Builder") == "LobbyWallCoverage", "Unowned WallCladding")
		end
		ready = ready and existing ~= nil and existing:GetAttribute("GeometrySignature") == plan.signature
		if existing then
			local count = existing:GetAttribute("Cells")
			total += if typeof(count) == "number" then count else 0
		end
	end
	normalize(plan)
	if ready then
		-- Legacy palette passes may touch an existing facade on startup.
		for _, surface in plan.planes do
			local root = surface.owner.WallCladding
			for _, group in root:GetChildren() do
				if group:GetAttribute("PlaneKey") == surface.key then
					for _, p in group:GetChildren() do
						if p:IsA("BasePart") then
							local u, v = p:GetAttribute("GridU") :: number, p:GetAttribute("GridV") :: number
							p.Color = if surface.cap
								then surface.color
								elseif (u + v + surface.parity) % 2 == 0 then Palette.Earth
								else Palette.EarthDark
							local t = p:FindFirstChild("WallStuds")
							if t and t:IsA("Texture") then
								t.Texture, t.Color3, t.Transparency =
									Palette.Studs, Color3.new(1, 1, 1), Palette.StudsTransparency
								t.StudsPerTileU, t.StudsPerTileV = Palette.WallStudPitch * 4, Palette.WallStudPitch * 4
								t.OffsetStudsU, t.OffsetStudsV = 0, 0
							end
						end
					end
				end
			end
		end
		return { rebuilt = false, tiles = total, faces = #plan.planes }
	end
	for _, root in legacy do
		root:Destroy()
	end
	local staged = {}
	for _, owner in plan.owners do
		if owner:IsA("Model") then
			owner.WorldPivot = owner:GetPivot()
		end
		local root = Instance.new("Model")
		root.Name, root.WorldPivot = "WallCladding", owner:GetPivot()
		root:SetAttribute("Builder", "LobbyWallCoverage")
		root:SetAttribute("Cells", 0)
		local old = owner:FindFirstChild("WallCladding")
		if old then
			old:Destroy()
		end
		root.Parent = owner
		staged[owner] = root
	end
	total = 0
	local parts = 0
	for index, surface in plan.planes do
		if #surface.cells == 0 then
			continue
		end
		local root = staged[surface.owner]
		local group = Instance.new("Model")
		group.Name, group.WorldPivot = surface.face.Name .. "Surface" .. index, surface.owner:GetPivot()
		group:SetAttribute("PlaneKey", surface.key)
		group:SetAttribute("Axis", surface.axis)
		group:SetAttribute("Plane", surface.plane)
		group:SetAttribute("Sign", surface.sign)
		group:SetAttribute("IsCap", surface.cap)
		group:SetAttribute("OriginU", surface.originU)
		group:SetAttribute("OriginV", surface.originV)
		group:SetAttribute("Parity", surface.parity)
		group.Parent = root
		local function make(u0: number, u1: number, v0: number, v1: number, color: Color3, cell: any?)
			local part = Instance.new("Part")
			local depth = Palette.WallCheckerDepth
			local along, up, out = (u0 + u1) / 2, (v0 + v1) / 2, surface.plane + surface.sign * depth / 2
			if surface.axis == "X" then
				part.Size, part.Position = V(depth, v1 - v0, u1 - u0), V(out, up, along)
			elseif surface.axis == "Y" then
				part.Size, part.Position = V(u1 - u0, depth, v1 - v0), V(along, out, up)
			else
				part.Size, part.Position = V(u1 - u0, v1 - v0, depth), V(along, up, out)
			end
			part.Name = if surface.cap then "CapSurface" else "WallCell"
			part.Color, part.Material = color, Enum.Material.Plastic
			part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow =
				true, false, false, false, false
			part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			if cell then
				part:SetAttribute("GridU", cell.u)
				part:SetAttribute("GridV", cell.v)
			end
			local t = Instance.new("Texture")
			t.Name, t.Texture, t.Face = "WallStuds", Palette.Studs, surface.face
			t.StudsPerTileU, t.StudsPerTileV = Palette.WallStudPitch * 4, Palette.WallStudPitch * 4
			t.OffsetStudsU, t.OffsetStudsV = 0, 0
			t.Transparency, t.Parent = Palette.StudsTransparency, part
			part.Parent = group
			parts += 1
		end
		if surface.cap then
			for _, r in surface.pieces do
				make(
					surface.originU + r[1] * surface.step,
					surface.originU + r[2] * surface.step,
					surface.originV + r[3] * surface.step,
					surface.originV + r[4] * surface.step,
					surface.color,
					nil
				)
			end
		else
			for i, cell in surface.cells do
				local u, v = surface.originU + cell.u * surface.step, surface.originV + cell.v * surface.step
				make(
					u,
					u + surface.step,
					v,
					v + surface.step,
					if (cell.u + cell.v + surface.parity) % 2 == 0 then Palette.Earth else Palette.EarthDark,
					cell
				)
				total += 1
				if i % 200 == 0 then
					task.wait()
				end
			end
			local count = root:GetAttribute("Cells")
			root:SetAttribute("Cells", (if typeof(count) == "number" then count else 0) + #surface.cells)
		end
		if index % 5 == 0 then
			task.wait()
		end
	end
	for _, owner in plan.owners do
		staged[owner]:SetAttribute("GeometrySignature", plan.signature)
		task.wait()
	end
	return { rebuilt = true, tiles = total, faces = #plan.planes, parts = parts }
end

return Coverage
