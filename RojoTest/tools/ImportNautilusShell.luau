-- Exact Blender triangles, authoring only. Local native CSG needs no asset upload.
return function(data)
	assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(), "Edit only")
	local storage = game:GetService("ServerStorage")
	local geometry = game:GetService("GeometryService")
	local assets = assert(storage:FindFirstChild("Assets"))
	local category = assets:FindFirstChild("EggStands") or Instance.new("Folder")
	category.Name = "EggStands"
	category.Parent = assets
	assert(not category:FindFirstChild("NautilusShell"), "Template already exists")
	local template = Instance.new("Model")
	template.Name = "NautilusShell"
	template:SetAttribute("Status", "Building")
	template:SetAttribute("Revision", data.revision)
	template:SetAttribute("CompletedComponents", 0)
	template:SetAttribute("FailedComponents", 0)
	template:SetAttribute("GeometryKind", "PersistentNativeCSG")
	template:SetAttribute("Source", "Blender selected shell concept 5")
	template.Parent = category
	task.spawn(function()
		local ok, err = pcall(function()
			for index, source in data.meshes do
				local points = {}
				for i, v in source.vertices do
					points[i] = Vector3.new(v[1], v[2], v[3])
				end
				local colors = {}
				for i, c in source.colors do
					colors[i] = Color3.new(c[1], c[2], c[3])
				end
				local parts = {}
				local function wedge(center, size, right, up, back, color)
					if math.min(size.Y, size.Z) < 0.0005 then
						return
					end
					local part = Instance.new("WedgePart")
					part.Size = size
					part.CFrame = CFrame.fromMatrix(center, right, up, back)
					part.Color = color
					part.Material = Enum.Material.SmoothPlastic
					part.Anchored = true
					part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
					table.insert(parts, part)
				end
				for i, triangle in source.triangles do
					local a, b, c = points[triangle[1] + 1], points[triangle[2] + 1], points[triangle[3] + 1]
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
						local color = colors[triangle[4] + 1]
						wedge((a + b) / 2, Vector3.new(0.008, height, math.abs(ab:Dot(back))), right, up, back, color)
						wedge((a + c) / 2, Vector3.new(0.008, height, math.abs(ac:Dot(back))), -right, up, -back, color)
					end
					if i % 400 == 0 then
						task.wait()
					end
				end
				local anchor = Instance.new("Part")
				anchor.Size = Vector3.one * 0.001
				local minimum, maximum = Vector3.one * math.huge, Vector3.one * -math.huge
				for _, point in points do
					minimum = minimum:Min(point)
					maximum = maximum:Max(point)
				end
				anchor.CFrame = CFrame.new((minimum + maximum) / 2)
				anchor.Color = parts[1].Color
				anchor.Material = Enum.Material.SmoothPlastic
				local unionOk, results = pcall(function()
					return geometry:UnionAsync(anchor, parts, {
						SplitApart = false,
						CollisionFidelity = Enum.CollisionFidelity.Box,
						RenderFidelity = Enum.RenderFidelity.Precise,
					})
				end)
				if not unionOk or #results == 0 then
					template:SetAttribute("FailedComponents", template:GetAttribute("FailedComponents") + 1)
					error(source.name .. ": " .. tostring(results))
				end
				for i, part in results do
					part.Name = source.name .. (if #results > 1 then tostring(i) else "")
					part.Anchored = true
					part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
					part.UsePartColor = false
					part.Material = Enum.Material.SmoothPlastic
					part.Parent = template
				end
				anchor:Destroy()
				for _, part in parts do
					part:Destroy()
				end
				template:SetAttribute("CompletedComponents", index)
				template:SetAttribute("CurrentComponent", source.name)
				task.wait()
			end
			template.WorldPivot = CFrame.identity
			template:SetAttribute("Status", "Ready")
			game:GetService("ChangeHistoryService"):SetWaypoint("Imported nautilus shell template")
		end)
		if not ok then
			template:SetAttribute("Status", "Error")
			template:SetAttribute("Error", tostring(err))
		end
	end)
	return template:GetFullName()
end
