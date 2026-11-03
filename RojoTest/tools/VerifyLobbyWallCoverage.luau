-- Complete-cell coverage and physical backing of the actual facade.
local world = workspace.Map.World1
local modules = Instance.new("Folder")
modules.Name = "WallAuditModules"
modules.Parent = game.ServerStorage
for _, name in { "LobbyPalette", "LobbyWallCoverage" } do
	game.ServerScriptService.Server[name]:Clone().Parent = modules
end
local plan = require(modules.LobbyWallCoverage).plan(world)
modules:Destroy()
local temporary = Instance.new("Folder")
temporary.Name = "WallAuditQuery"
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { temporary }
for _, source in plan.sources do
	local p = Instance.new("Part")
	p.Size, p.CFrame = source.part.Size, source.part.CFrame
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.Transparency = true, false, false, true, 1
	p:SetAttribute("PartRole", "QueryVolume")
	p.Parent = temporary
	for _, t in source.part:GetChildren() do
		assert(not t:IsA("Texture"), "Old wall/cap stud layer remains")
	end
end
temporary.Parent = workspace
local function component(v, axis)
	return if axis == "X" then v.X elseif axis == "Y" then v.Y else v.Z
end
local ok, result = pcall(function()
	local cells, probes, faces = 0, 0, 0
	for _, surface in plan.planes do
		local group
		for _, candidate in surface.owner.WallCladding:GetChildren() do
			if candidate:GetAttribute("PlaneKey") == surface.key then
				assert(not group, "Duplicate plane")
				group = candidate
			end
		end
		if #surface.cells == 0 then
			assert(not group, "Skin on an empty plane")
			continue
		end
		assert(group, "Missing exposed plane " .. surface.key)
		faces += 1
		local expected = {}
		for _, cell in surface.cells do
			expected[cell.u .. ":" .. cell.v] = true
		end
		local covered = 0
		for _, p in group:GetChildren() do
			local a, b = component(p.Size, surface.u), component(p.Size, surface.v)
			local u0, v0 = component(p.Position, surface.u) - a / 2, component(p.Position, surface.v) - b / 2
			local area = 0
			for _, r in surface.rectangles do
				area += math.max(0, math.min(u0 + a, r[2]) - math.max(u0, r[1])) * math.max(
					0,
					math.min(v0 + b, r[4]) - math.max(v0, r[3])
				)
			end
			-- Bound the positional Float32 error, including long merged cap strips.
			assert(
				area >= a * b - (a + b) * 0.0001,
				string.format("Cell crosses boundary: %s area %.9f expected %.9f", p:GetFullName(), area, a * b)
			)
			if surface.cap then
				covered += math.round(a * b / (1.6 * 1.6))
			else
				local id = p:GetAttribute("GridU") .. ":" .. p:GetAttribute("GridV")
				assert(expected[id], "Unexpected/repeated cell")
				expected[id] = nil
				cells += 1
			end
			local normal = Vector3.FromNormalId(p.WallStuds.Face)
			local hit = workspace:Raycast(p.Position + normal * 0.2, -normal * 0.5, params)
			assert(
				hit and math.abs(component(hit.Position, surface.axis) - surface.plane) < 0.001,
				"Floating or hidden wall skin"
			)
			probes += 1
			if probes % 300 == 0 then
				task.wait()
			end
		end
		if surface.cap then
			assert(covered == #surface.cells, "Incomplete cap")
		else
			assert(next(expected) == nil, "Missing complete checker cells")
		end
	end
	return { cells = cells, backingProbes = probes, faces = faces, sources = #plan.sources }
end)
temporary:Destroy()
assert(ok, result)
return result
