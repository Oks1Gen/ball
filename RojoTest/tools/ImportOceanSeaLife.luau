-- Studio Edit. One Blender species per call; the input is a decoded geometry entry.
return function(name: string, groups: any, packName: string?, sourcePath: string?)
	local storage = game:GetService("ServerStorage")
	local geometry = game:GetService("GeometryService")
	assert(not game:GetService("RunService"):IsRunning(), "Import in Studio Edit")
	local function folder(parent: Instance, label: string): Instance
		local existing = parent:FindFirstChild(label)
		if existing then
			return existing
		end
		local category = Instance.new("Folder")
		category.Name = label
		category.Parent = parent
		return category
	end
	local kit = folder(folder(folder(storage, "Assets"), "OceanDepths"), packName or "SeaLife")

	local model = Instance.new("Model")
	model.Name = name
	model.WorldPivot = CFrame.identity
	model:SetAttribute("Source", sourcePath or "Assets/OceanDepths/sea-life.blend")
	for _, group in groups do
		local vertices = {}
		for i, v in group.v do
			vertices[i] = Vector3.new(v[1], v[2], v[3])
		end
		local facets = Instance.new("Folder")
		local function wedge(
			mid: Vector3,
			right: Vector3,
			up: Vector3,
			back: Vector3,
			h: number,
			length: number,
			tint: Color3
		)
			if math.min(h, length) < 0.001 then
				return
			end
			local part = Instance.new("WedgePart")
			part.Size = Vector3.new(0.006, h, length)
			part.CFrame = CFrame.fromMatrix(mid, right, up, back)
			part.Color = tint
			part.Material = Enum.Material.SmoothPlastic
			part.Parent = facets
		end
		for _, entry in group.t do
			local indices, hex = entry[1], entry[2]
			local a, b, c = vertices[indices[1]], vertices[indices[2]], vertices[indices[3]]
			local ab, ac, bc = (b - a).Magnitude, (c - a).Magnitude, (c - b).Magnitude
			if ab > math.max(ac, bc) then
				a, c = c, a
			elseif ac > math.max(ab, bc) then
				a, b = b, a
			end
			local edge, ray, base = b - a, c - a, c - b
			local right, back = ray:Cross(edge).Unit, base.Unit
			local up = back:Cross(right).Unit
			local height = math.abs(edge:Dot(up))
			local tint = Color3.fromHex(hex)
			wedge((a + b) / 2, right, up, back, height, math.abs(edge:Dot(back)), tint)
			wedge((a + c) / 2, -right, up, -back, height, math.abs(ray:Dot(back)), tint)
		end
		local anchor = Instance.new("Part")
		anchor.Size = Vector3.one * 0.001
		anchor.Material = Enum.Material.SmoothPlastic
		anchor.Color = (facets:GetChildren()[1] :: BasePart).Color
		local ok, results = pcall(function()
			return geometry:UnionAsync(anchor, facets:GetChildren(), {
				SplitApart = false,
				CollisionFidelity = Enum.CollisionFidelity.Box,
				RenderFidelity = Enum.RenderFidelity.Precise,
			})
		end)
		facets:Destroy()
		anchor:Destroy()
		assert(
			ok and #results == 1,
			("CSG conversion failed for %s.%s: %s"):format(name, group.name, tostring(results))
		)
		local part = results[1]
		part.Name = group.name
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.Material = Enum.Material.SmoothPlastic
		part.UsePartColor = false
		part.Parent = model
		task.wait()
	end
	local old = kit:FindFirstChild(name)
	model.Parent = kit
	if old then
		old:Destroy()
	end
	return #model:GetChildren()
end
