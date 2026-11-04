-- Read-only surface-area audit from physical floor and mask geometry, not generated cells.
local world = workspace.Map.World1
local modules = Instance.new("Folder")
modules.Parent = game.ServerStorage
for _, name in { "LobbyPalette", "LobbyLawn" } do
	game.ServerScriptService.Server[name]:Clone().Parent = modules
end
game.ReplicatedStorage.Shared.Core.SurfaceGrid:Clone().Parent = modules
modules.LobbyLawn.Source = modules.LobbyLawn.Source:gsub(
	"require%(game.ReplicatedStorage.Shared.Core.SurfaceGrid%)",
	"require(script.Parent:FindFirstChild('SurfaceGrid'))"
)
local grid = require(modules.SurfaceGrid)
local palette = require(modules.LobbyPalette)
local ok, plan = pcall(function()
	-- Moving/removing paths and stations must not change the underlying lawn pattern.
	return require(modules.LobbyLawn).plan({
		Lobby = { Geometry = world.Lobby.Geometry, Environment = world.Lobby.Environment },
		-- The plan reads the world scale.
		GetAttribute = function(_, name)
			return world:GetAttribute(name)
		end,
	})
end)
modules:Destroy()
assert(ok, plan)
-- The lattice follows the world scale; the plan carries the current cell and tile.
local CELL, TILE = plan.cell, plan.tile
local PITCH = TILE / palette.StudsPerTexture
local root = assert(world.Lobby.Geometry:FindFirstChild("Lawn"))
local function area(rectangles)
	local result = 0
	for _, r in rectangles do
		result += (r[2] - r[1]) * (r[4] - r[3])
	end
	return result
end
local function difference(rectangles, cuts)
	local rest = rectangles
	for _, cut in cuts do
		local nextRectangles = {}
		for _, r in rest do
			for _, p in grid.subtract(r, cut) do
				table.insert(nextRectangles, p)
			end
		end
		rest = nextRectangles
	end
	return rest
end
local actual, checker = {}, 0
local expected = {}
for _, c in plan.checker do
	expected[c.u .. ":" .. c.v] = true
end
for _, p in root:GetChildren() do
	assert(
		p:IsA("BasePart") and p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery and not p.CastShadow
	)
	assert(p.Transparency == 0 and math.abs(p.Position.Y + p.Size.Y / 2 - plan.top - 0.02) < 0.001)
	local lo, hi = p.Position - p.Size / 2, p.Position + p.Size / 2
	local r = { lo.X, hi.X, lo.Z, hi.Z }
	for i, value in r do
		local origin = if i <= 2 then plan.origin.X else plan.origin.Y
		assert(math.abs((value - origin) / PITCH - math.round((value - origin) / PITCH)) < 0.0001, "Cut lawn stud row")
	end
	local textures = 0
	for _, t in p:GetChildren() do
		if t:IsA("Texture") then
			textures += 1
			assert(t.Name == "LawnStuds" and t.Face == Enum.NormalId.Top and t.Texture == palette.Studs)
			assert(math.abs(t.StudsPerTileU - TILE) < 0.001 and math.abs(t.StudsPerTileV - TILE) < 0.001)
			assert(t.OffsetStudsU == 0 and t.OffsetStudsV == 0)
		end
	end
	assert(textures == 1, "Missing or duplicate lawn texture")
	assert(p.Name == "LawnCell", "One-colour repair strip breaks the continuous lawn checker")
	do
		assert(math.abs(p.Size.X - CELL) < 0.001 and math.abs(p.Size.Z - CELL) < 0.001, "Clipped lawn checker")
		local u, v = p:GetAttribute("GridU"), p:GetAttribute("GridV")
		assert(expected[u .. ":" .. v], "Unexpected checker position")
		expected[u .. ":" .. v] = nil
		assert(math.abs(r[1] - plan.origin.X - u * CELL) < 0.001 and math.abs(r[3] - plan.origin.Y - v * CELL) < 0.001)
		assert(p.Color == (if (u + v) % 2 == 0 then palette.Lawn else palette.LawnChecker), "Wrong lawn parity")
		checker += 1
	end
	table.insert(actual, r)
end
assert(next(expected) == nil, "Missing complete lawn squares")
local union = grid.union(actual)
local missing = area(difference(plan.rectangles, union))
local wallBounds = {}
for _, p in plan.occluders do
	local lo, hi = p.Position - p.Size / 2, p.Position + p.Size / 2
	table.insert(wallBounds, { lo.X, hi.X, lo.Z, hi.Z })
end
local excess = area(difference(difference(union, plan.rectangles), grid.union(wallBounds)))
local missingField = area(difference(plan.coverage, union))
local duplicate = area(actual) - area(union)
local perimeter = 0
for _, r in plan.rectangles do
	perimeter += r[2] - r[1] + r[4] - r[3]
end
local tolerance = perimeter * 0.0001
assert(
	missing <= tolerance and excess <= tolerance and duplicate <= tolerance and missingField <= tolerance,
	string.format("Lawn coverage: missing %.8f excess %.8f duplicate %.8f", missing, excess, duplicate)
)
local query = Instance.new("Folder")
query.Name = "LawnAuditQuery"
for _, source in plan.sources do
	for _, t in source:GetChildren() do
		assert(not (t:IsA("Texture") and t.Face == Enum.NormalId.Top), "Old lawn texture returned")
	end
	local p = Instance.new("Part")
	-- Measured original tile seam: 0.0000305 stud at Z=200.8 (Float32).
	-- Expand query-only copies by 0.0001 total; the real floor stays unchanged.
	p.Size, p.CFrame = source.Size + Vector3.new(0.0001, 0, 0.0001), source.CFrame
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.Transparency = true, false, false, true, 1
	p:SetAttribute("PartRole", "QueryVolume")
	p.Parent = query
end
-- Whole checker squares can continue beyond the floor only inside solid earth.
for _, r in wallBounds do
	local p = Instance.new("Part")
	p.Size = Vector3.new(r[2] - r[1] + 0.0001, PITCH, r[4] - r[3] + 0.0001)
	p.CFrame = CFrame.new((r[1] + r[2]) / 2, plan.top - PITCH / 2, (r[3] + r[4]) / 2)
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.Transparency = true, false, false, true, 1
	p:SetAttribute("PartRole", "QueryVolume")
	p.Parent = query
end
query.Parent = workspace
task.wait()
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { query }
local probes = 0
local supported, result = pcall(function()
	for _, r in actual do
		for _, fraction in { { 0.01, 0.01 }, { 0.99, 0.01 }, { 0.01, 0.99 }, { 0.99, 0.99 }, { 0.5, 0.5 } } do
			local p =
				Vector3.new(r[1] + (r[2] - r[1]) * fraction[1], plan.top + 0.1, r[3] + (r[4] - r[3]) * fraction[2])
			local hit = workspace:Raycast(p, Vector3.new(0, -0.3, 0), params)
			assert(
				hit and math.abs(hit.Position.Y - plan.top) < 0.001,
				"Unsupported lawn at " .. tostring(p) .. "; hit=" .. (if hit then tostring(hit.Position) else "none")
			)
			probes += 1
		end
	end
end)
query:Destroy()
assert(supported, result)
return {
	checker = checker,
	edgeParts = 0,
	sources = #plan.sources,
	backingProbes = probes,
	missingArea = missing,
	missingCheckerFieldArea = missingField,
	excessArea = excess,
	overlapArea = duplicate,
	coveredArea = area(union),
}
