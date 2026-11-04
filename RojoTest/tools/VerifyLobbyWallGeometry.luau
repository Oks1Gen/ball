-- Read-only Edit/Server audit of the real dimensions, fourth storey and waterfalls.
local world = workspace.Map.World1
local modules = Instance.new("Folder")
modules.Parent = game.ServerStorage
for _, name in { "LobbyPalette", "LobbyWallCoverage" } do
	game.ServerScriptService.Server[name]:Clone().Parent = modules
end
local plan = require(modules.LobbyWallCoverage).plan(world)
modules:Destroy()
-- Heights and lengths measured in the 0.8 scene; both follow the world scale.
local r = world:GetAttribute("WorldScale") / 0.8
local originY = world:GetAttribute("WorldScaleOrigin").Y
local function y(value)
	return originY + (value - originY) * r
end
local PITCH = 1.6 * r
local function aligned(value, origin, step)
	assert(
		math.abs((value - origin) / step - math.round((value - origin) / step)) < 0.0001,
		"Wall boundary cuts a stud row"
	)
end
local caps, top = 0, -math.huge
for _, source in plan.sources do
	for _, edge in { source.lo, source.hi } do
		aligned(edge.X, plan.origin.X, PITCH)
		aligned(edge.Y, plan.origin.Y, PITCH)
		aligned(edge.Z, plan.origin.Z, PITCH)
	end
	if source.cap then
		assert(math.abs(source.part.Size.Y - PITCH) < 0.0001, "Grass fascia cannot fit a whole stud")
		top = math.max(top, source.hi.Y)
		caps += 1
	end
	local original = source.part:FindFirstChild("OriginalPart")
	if original and original.Value and original.Value:IsDescendantOf(world) then
		assert(
			original.Value.CFrame == source.part.CFrame and original.Value.Size == source.part.Size,
			"Wall collision mismatches its render"
		)
	end
end
local upperParts = 0
local shelfProbes = 0
local setback = world:GetAttribute("LobbyWallUpperSetback")
assert(math.abs(setback - 6.4 * r) < 0.001, "Upper tier needs the measured terrace setback")
local function close(a, b)
	assert(math.abs(a - b) < 0.001, "Upper terrace profile changed")
end
local shelves = {}
for _, source in plan.sources do
	if source.cap and source.part.Parent.Name ~= "UpperTier" and math.abs(source.hi.Y - y(69.72)) < 0.001 then
		table.insert(shelves, source)
	end
end
for _, owner in plan.owners do
	local upper = assert(owner:FindFirstChild("UpperTier"), "Missing fourth storey")
	assert(upper:GetAttribute("Builder") == "LobbyWallGeometry")
	local keys = {}
	for _, p in upper:GetChildren() do
		local key = p:GetAttribute("WallTierKey")
		assert(key and not keys[key], "Duplicate upper storey source")
		keys[key] = true
		local support = assert(p:FindFirstChild("SupportCap"), "Missing measured lower shelf").Value
		assert(support and support.Parent == owner, "Upper tier support belongs to another wall")
		local lo, hi = p.Position - p.Size / 2, p.Position + p.Size / 2
		local lowerLo, lowerHi = support.Position - support.Size / 2, support.Position + support.Size / 2
		if owner.Name == "RearTerraces" then
			close(lo.Z - lowerLo.Z, setback)
			close(hi.Z, lowerHi.Z)
		elseif p.Position.X < plan.origin.X then
			close(lowerHi.X - hi.X, setback)
			close(lo.X, lowerLo.X)
		else
			close(lo.X - lowerLo.X, setback)
			close(hi.X, lowerHi.X)
		end
		if owner.Name == "EntranceTunnel" then
			close(lo.Z - lowerLo.Z, setback)
			close(hi.Z, lowerHi.Z)
		end
		if p.Name == "TerraceEarth" then
			assert(math.abs(p.Size.Y - 14.4 * r) < 0.001)
			for x = 0, math.round(p.Size.X / PITCH) - 1 do
				for z = 0, math.round(p.Size.Z / PITCH) - 1 do
					local point = lo + Vector3.new((x + 0.5) * PITCH, 0, (z + 0.5) * PITCH)
					local supported = false
					for _, shelf in shelves do
						if
							point.X > shelf.lo.X
							and point.X < shelf.hi.X
							and point.Z > shelf.lo.Z
							and point.Z < shelf.hi.Z
						then
							supported = true
							break
						end
					end
					assert(supported, "Upper terrace hangs beyond its supporting shelf")
					shelfProbes += 1
				end
			end
		else
			assert(p.Name == "GrassShelf" and math.abs(p.Size.Y - PITCH) < 0.001)
		end
		upperParts += 1
	end
end
assert(math.abs(world:GetAttribute("LobbyWallUpperRise") - 16 * r) < 0.001 and math.abs(top - y(85.72)) < 0.001)
for _, name in { "CornerWaterfall1", "SideWaterfall" } do
	local waterfall = world.Lobby.Environment[name]
	local carrier = waterfall.VFX_Waterfall
	assert(math.abs(waterfall.WaterLip.Position.Y - top) < 0.001, "Waterfall starts below the new top")
	assert(math.abs(carrier.FallTop.WorldPosition.Y - top - 0.24 * r) < 0.001)
	assert(math.abs(carrier.FallBottom.WorldPosition.Y - y(20.76)) < 0.001, "Waterfall basin moved")
	assert(math.abs(waterfall.PoolWater.Position.Y - y(20.44)) < 0.001)
	local face = if name == "CornerWaterfall1"
		then world.Lobby.Environment.RearTerraces.UpperTier:FindFirstChild("TerraceEarth")
		else world.Lobby.Environment.SideTerraces2.UpperTier:FindFirstChild("TerraceEarth")
	local edge = if name == "CornerWaterfall1"
		then face.Position.Z - face.Size.Z / 2
		else face.Position.X - face.Size.X / 2
	local lip = if name == "CornerWaterfall1" then waterfall.WaterLip.Position.Z else waterfall.WaterLip.Position.X
	local fall = if name == "CornerWaterfall1" then carrier.FallTop.WorldPosition.Z else carrier.FallTop.WorldPosition.X
	close(lip, edge - 0.32 * r)
	close(fall, edge - 0.48 * r)
end
return {
	sources = #plan.sources,
	caps = caps,
	upperParts = upperParts,
	top = top,
	rise = 16 * r,
	setback = setback,
	shelfProbes = shelfProbes,
}
