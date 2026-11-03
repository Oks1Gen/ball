-- Studio MCP, Edit only. Imports exact Blender facet surfaces into persistent native geometry.
-- Does not replace active eggs, alter their IDs/prompts, or rebuild the world.
return function(url: string)
	local HttpService = game:GetService("HttpService")
	local ServerStorage = game:GetService("ServerStorage")
	assert(not game:GetService("RunService"):IsRunning(), "Use Edit mode")
	assert(not ServerStorage:FindFirstChild("ElementalEggTemplates"), "Templates already exist; do not duplicate")
	local payload = HttpService:JSONDecode(HttpService:GetAsync(url))
	assert(payload.schema == 1 and #payload.eggs == 5, "Unexpected Blender payload")
	_G.ElementalEggBaseline = {}
	for _, p in workspace.Map:GetDescendants() do
		if p:IsA("BasePart") then
			_G.ElementalEggBaseline[p] = { p.CFrame, p.Size, p.Transparency, p.CanCollide, p.CanTouch, p.CanQuery }
		end
	end
	local root = Instance.new("Folder")
	root.Name = "ElementalEggTemplates"
	root:SetAttribute("Source", "Blender elemental-v1/geometry.json")
	root.Parent = ServerStorage
	local stats = {}
	local function wedge(parent, name, mid, right, up, back, height, length, color, glow)
		if math.min(height, length) < 0.0005 then
			return 0
		end
		local p = Instance.new("WedgePart")
		p.Name = name
		p.Size = Vector3.new(0.008, height, length)
		p.CFrame = CFrame.fromMatrix(mid, right, up, back)
		p.Color = Color3.new(color[1], color[2], color[3])
		p.Material = if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = not glow
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent
		return 1
	end
	for _, egg in payload.eggs do
		local model = Instance.new("Model")
		model.Name = egg.name
		model:SetAttribute("AssetTheme", egg.name)
		model:SetAttribute("DisplayHeightStuds", 10)
		model:SetAttribute("PivotAtBase", true)
		model.Parent = root
		local count = 0
		for _, source in egg.meshes do
			local group = Instance.new("Model")
			group.Name = source.name
			local vertices = {}
			for i, v in source.vertices do
				vertices[i] = Vector3.new(v[1], v[2], v[3])
			end
			for i, t in source.triangles do
				local a, b, c = vertices[t.v[1] + 1], vertices[t.v[2] + 1], vertices[t.v[3] + 1]
				local ab, ac, bc = b - a, c - a, c - b
				if ab:Dot(ab) > math.max(ac:Dot(ac), bc:Dot(bc)) then
					a, c = c, a
				elseif ac:Dot(ac) > math.max(ab:Dot(ab), bc:Dot(bc)) then
					a, b = b, a
				end
				ab, ac, bc = b - a, c - a, c - b
				local normal = ac:Cross(ab)
				if normal.Magnitude > 1e-8 then
					local right, back = normal.Unit, bc.Unit
					local up = bc:Cross(right).Unit
					local height = math.abs(ab:Dot(up))
					count += wedge(
						group,
						`Facet_{i}A`,
						(a + b) / 2,
						right,
						up,
						back,
						height,
						math.abs(ab:Dot(back)),
						t.c,
						t.glow
					)
					count += wedge(
						group,
						`Facet_{i}B`,
						(a + c) / 2,
						-right,
						up,
						-back,
						height,
						math.abs(ac:Dot(back)),
						t.c,
						t.glow
					)
				end
			end
			group.WorldPivot = CFrame.identity
			group.Parent = model
			task.wait()
		end
		model.WorldPivot = CFrame.identity
		table.insert(stats, { name = egg.name, parts = count })
	end
	return stats
end
