--!strict
-- Continuous lawn checker beneath paving; physics and stations remain authored.
local Grid = require(game.ReplicatedStorage.Shared.Core.SurfaceGrid)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local Palette = require(script.Parent.LobbyPalette)
local Lawn = {}
local DEPTH = 0.02
local VERSION = "lobby-lawn-2-continuous"
local EARTH = { TerraceEarth = true, RearEarthLedge = true, LeftAbutment = true, RightAbutment = true }

local function bounds(p: BasePart): { number }
	assert(math.abs(p.CFrame.RightVector.X) > 0.9999 and p.CFrame.UpVector.Y > 0.9999, "Measure rotated lawn support")
	local lo, hi = p.Position - p.Size / 2, p.Position + p.Size / 2
	return { lo.X, hi.X, lo.Z, hi.Z }
end

function Lawn.plan(world: any): any
	local k = Scale.factor(world)
	local CELL, PITCH = Palette.LawnCell * k, Palette.GroundStudPitch * k
	local lobby = world.Lobby
	local origin = Vector2.zero
	local sources, rectangles = {}, {}
	local top: number? = nil
	local signature =
		{ VERSION, tostring(origin), tostring(CELL), tostring(Palette.Lawn), tostring(Palette.LawnChecker) }
	for _, p in lobby.Geometry:GetChildren() do
		if p:IsA("BasePart") and p.Name == "GroundTile" and p.Transparency < 1 then
			local height = p.Position.Y + p.Size.Y / 2
			assert(not top or math.abs(height - top) < 0.001, "Lawn has different support heights")
			top = height
			table.insert(sources, p)
			table.insert(rectangles, bounds(p))
			table.insert(signature, tostring(p.CFrame) .. tostring(p.Size))
		end
	end
	assert(top and #sources > 0, "Missing lawn support")
	-- The lawn is one continuous checker field, including beneath paths and stations.
	-- Align its outer envelope to whole squares; any overhang must be buried in walls.
	local envelope = { math.huge, -math.huge, math.huge, -math.huge }
	for _, r in rectangles do
		envelope[1], envelope[2] = math.min(envelope[1], r[1]), math.max(envelope[2], r[2])
		envelope[3], envelope[4] = math.min(envelope[3], r[3]), math.max(envelope[4], r[4])
	end
	local columns = math.ceil((envelope[2] - envelope[1]) / CELL - 0.0001)
	local rows = math.ceil((envelope[4] - envelope[3]) / CELL - 0.0001)
	origin = Vector2.new(envelope[2] - columns * CELL, envelope[3])
	local raw = Grid.wholeCells(rectangles, PITCH, origin.X, origin.Y)
	local sourceArea, sourcePerimeter = 0, 0
	for _, r in Grid.union(rectangles) do
		sourceArea += (r[2] - r[1]) * (r[4] - r[3])
		sourcePerimeter += r[2] - r[1] + r[4] - r[3]
	end
	assert(
		math.abs(sourceArea - #raw * PITCH * PITCH) <= sourcePerimeter * 0.0001,
		"Original lawn has an uncovered sub-stud boundary"
	)
	local masks, occluders = {}, {}
	local function mask(p: BasePart)
		if p.Transparency >= 1 then
			return
		end
		table.insert(occluders, p)
		table.insert(masks, bounds(p))
		table.insert(signature, "mask:" .. tostring(p.CFrame) .. tostring(p.Size))
	end
	for _, p in lobby.Environment:GetDescendants() do
		if
			p:IsA("BasePart")
			and EARTH[p.Name]
			and p.Position.Y - p.Size.Y / 2 <= (top :: number) + 0.001
			and p.Position.Y + p.Size.Y / 2 > (top :: number) + 0.02
		then
			mask(p)
		end
	end
	local checker = {}
	for v = 0, rows - 1 do
		for u = 0, columns - 1 do
			table.insert(checker, { u = u, v = v })
		end
	end
	local coverage = { { origin.X, origin.X + columns * CELL, origin.Y, origin.Y + rows * CELL } }
	-- Only solid earth may hide the extension beyond the physical lawn boundary.
	local uncovered = coverage
	for _, cut in Grid.union(rectangles) do
		local rest = {}
		for _, r in uncovered do
			for _, piece in Grid.subtract(r, cut) do
				table.insert(rest, piece)
			end
		end
		uncovered = rest
	end
	for _, cut in Grid.union(masks) do
		local rest = {}
		for _, r in uncovered do
			for _, piece in Grid.subtract(r, cut) do
				table.insert(rest, piece)
			end
		end
		uncovered = rest
	end
	local excess = 0
	for _, r in uncovered do
		excess += (r[2] - r[1]) * (r[4] - r[3])
	end
	assert(excess <= sourcePerimeter * 0.0001, "Lawn checker extends outside floor and solid walls")
	table.sort(signature)
	return {
		sources = sources,
		occluders = occluders,
		rectangles = rectangles,
		coverage = coverage,
		checker = checker,
		origin = origin,
		top = top,
		cell = CELL,
		tile = PITCH * Palette.StudsPerTexture,
		signature = table.concat(signature, "|"),
	}
end

function Lawn.apply(world: any): any
	local plan = Lawn.plan(world)
	local CELL, TILE = plan.cell, plan.tile
	for _, p in plan.sources do
		if p:GetAttribute("BeforeLawnGridColor") == nil then
			p:SetAttribute("BeforeLawnGridColor", p.Color)
		end
		p.Color = Palette.Lawn
		for _, t in p:GetChildren() do
			if t:IsA("Texture") and t.Face == Enum.NormalId.Top then
				t:Destroy()
			end
		end
	end
	local root = world.Lobby.Geometry:FindFirstChild("Lawn")
	if root then
		assert(root:GetAttribute("Builder") == "LobbyLawn", "Unowned lawn")
	end
	if root and root:GetAttribute("GeometrySignature") == plan.signature then
		for _, p in root:GetChildren() do
			if p:IsA("BasePart") then
				local parity = ((p:GetAttribute("GridU") or 0) + (p:GetAttribute("GridV") or 0)) % 2
				p.Color = if p.Name == "LawnCell" and parity == 1 then Palette.LawnChecker else Palette.Lawn
				local t = p:FindFirstChild("LawnStuds") :: Texture
				t.Texture, t.Transparency = Palette.Studs, Palette.StudsTransparency
				t.StudsPerTileU, t.StudsPerTileV, t.OffsetStudsU, t.OffsetStudsV = TILE, TILE, 0, 0
			end
		end
		return { rebuilt = false, checker = #plan.checker, parts = #root:GetChildren() }
	end
	if root then
		root:Destroy()
	end
	root = Instance.new("Model")
	root.Name = "Lawn"
	root:SetAttribute("Builder", "LobbyLawn")
	root.Parent = world.Lobby.Geometry
	local function part(name: string, r: { number }, color: Color3, cell: any?)
		local p = Instance.new("Part")
		p.Name, p.Size = name, Vector3.new(r[2] - r[1], DEPTH, r[4] - r[3])
		p.CFrame = CFrame.new((r[1] + r[2]) / 2, plan.top + DEPTH / 2, (r[3] + r[4]) / 2)
		p.Color, p.Material = color, Enum.Material.Plastic
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if cell then
			p:SetAttribute("GridU", cell.u)
			p:SetAttribute("GridV", cell.v)
		end
		local t = Instance.new("Texture")
		t.Name, t.Texture, t.Face = "LawnStuds", Palette.Studs, Enum.NormalId.Top
		t.StudsPerTileU, t.StudsPerTileV, t.OffsetStudsU, t.OffsetStudsV = TILE, TILE, 0, 0
		t.Transparency, t.Parent = Palette.StudsTransparency, p
		p.Parent = root
	end
	for i, c in plan.checker do
		local x, z = plan.origin.X + c.u * CELL, plan.origin.Y + c.v * CELL
		part(
			"LawnCell",
			{ x, x + CELL, z, z + CELL },
			if (c.u + c.v) % 2 == 0 then Palette.Lawn else Palette.LawnChecker,
			c
		)
		if i % 200 == 0 then
			task.wait()
		end
	end
	root:SetAttribute("GeometrySignature", plan.signature)
	return { rebuilt = true, checker = #plan.checker, parts = #root:GetChildren() }
end
return Lawn
