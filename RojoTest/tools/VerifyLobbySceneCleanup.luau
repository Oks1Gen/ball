-- Read-only broad-phase contact audit. Results are candidates, not deletion rules.
local lobby = workspace.Map.World1.Lobby
local parts, data, parent, grid, seeds = {}, {}, {}, {}, {}
local function find(i)
	while parent[i] ~= i do
		parent[i] = parent[parent[i]]
		i = parent[i]
	end
	return i
end
local function join(i, j)
	parent[find(i)] = find(j)
end
local function touching(a, b)
	local d = b.p.Position - a.p.Position
	local axes = { a.axes[1], a.axes[2], a.axes[3], b.axes[1], b.axes[2], b.axes[3] }
	for _, u in a.axes do
		for _, v in b.axes do
			local n = u:Cross(v)
			if n.Magnitude > 0.001 then
				table.insert(axes, n.Unit)
			end
		end
	end
	for _, axis in axes do
		local radius = 0
		for k = 1, 3 do
			radius += math.abs(a.axes[k]:Dot(axis)) * a.h[k] + math.abs(b.axes[k]:Dot(axis)) * b.h[k]
		end
		if math.abs(d:Dot(axis)) > radius + 0.08 then
			return false
		end
	end
	return true
end
for _, p in workspace.Map.World1:GetDescendants() do
	if
		p:IsA("BasePart")
		and (p:IsDescendantOf(lobby) and p.Transparency < 1 or p.CanCollide or p.Name:match("^BiomeBank") and p.Transparency < 1)
		and not p:IsDescendantOf(lobby.BallShop)
		and not p:IsDescendantOf(lobby.EggShop)
	then
		local i = #parts + 1
		parts[i] = p
		parent[i] = i
		local cf, h = p.CFrame, p.Size / 2
		local e = Vector3.new(
			math.abs(cf.RightVector.X) * h.X + math.abs(cf.UpVector.X) * h.Y + math.abs(cf.LookVector.X) * h.Z,
			math.abs(cf.RightVector.Y) * h.X + math.abs(cf.UpVector.Y) * h.Y + math.abs(cf.LookVector.Y) * h.Z,
			math.abs(cf.RightVector.Z) * h.X + math.abs(cf.UpVector.Z) * h.Y + math.abs(cf.LookVector.Z) * h.Z
		)
		data[i] = {
			p = p,
			h = { h.X, h.Y, h.Z },
			axes = { cf.RightVector, cf.UpVector, cf.LookVector },
			lo = p.Position - e,
			hi = p.Position + e,
		}
		if p.CanCollide and p.Anchored then
			seeds[i] = true
		end
	end
end
for i, a in data do
	local seen = {}
	for x = math.floor((a.lo.X - 0.08) / 8), math.floor((a.hi.X + 0.08) / 8) do
		for y = math.floor((a.lo.Y - 0.08) / 8), math.floor((a.hi.Y + 0.08) / 8) do
			for z = math.floor((a.lo.Z - 0.08) / 8), math.floor((a.hi.Z + 0.08) / 8) do
				local key = x .. ":" .. y .. ":" .. z
				for _, j in grid[key] or {} do
					if not seen[j] then
						seen[j] = true
						local b = data[j]
						if
							find(i) ~= find(j)
							and a.lo.X <= b.hi.X + 0.08
							and a.hi.X >= b.lo.X - 0.08
							and a.lo.Y <= b.hi.Y + 0.08
							and a.hi.Y >= b.lo.Y - 0.08
							and a.lo.Z <= b.hi.Z + 0.08
							and a.hi.Z >= b.lo.Z - 0.08
							and touching(a, b)
						then
							join(i, j)
						end
					end
				end
				grid[key] = grid[key] or {}
				table.insert(grid[key], i)
			end
		end
	end
	if i % 100 == 0 then
		task.wait()
	end
end
local grounded, clusters = {}, {}
for i in seeds do
	grounded[find(i)] = true
end
for i, p in parts do
	local root = find(i)
	if p:IsDescendantOf(lobby) and not grounded[root] then
		clusters[root] = clusters[root] or {}
		table.insert(clusters[root], p)
	end
end
local report = {}
for _, nodes in clusters do
	local names = {}
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, p in nodes do
		names[p.Name] = (names[p.Name] or 0) + 1
		lo = lo:Min(p.Position)
		hi = hi:Max(p.Position)
	end
	table.insert(
		report,
		{ count = #nodes, names = names, path = nodes[1]:GetFullName(), lo = tostring(lo), hi = tostring(hi) }
	)
end
table.sort(report, function(a, b)
	return a.count > b.count
end)
assert(#report == 0, "Detached lobby decoration: " .. game.HttpService:JSONEncode(report))
local root = game.ServerScriptService:FindFirstChild("LobbySceneCleanup", true)
local clone = root:Clone()
clone.Parent = root.Parent
local cleanup = require(clone)
clone:Destroy()
local plan = cleanup.plan(workspace.Map.World1)
assert(#plan.moves == 0 and #plan.remove == 0 and #plan.props == 0 and plan.blooms == 0, "Lobby cleanup is not stable")
return {
	contactParts = #parts,
	detached = #report,
	overlappingFlowers = plan.buried,
	unsupportedFlowers = plan.floating,
}
