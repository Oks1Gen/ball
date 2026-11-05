-- Edit-time import finalization. Only consumes generated template clones.
-- Native CSG retains its geometry in the saved place; no mesh upload is needed.
return function()
	local ServerStorage = game:GetService("ServerStorage")
	local GeometryService = game:GetService("GeometryService")
	assert(not game:GetService("RunService"):IsRunning(), "Use Edit mode")
	local source = assert(ServerStorage:FindFirstChild("OceanEggTemplates"), "Import source first")
	local function folder(parent, name)
		local existing = parent:FindFirstChild(name)
		if existing then
			assert(existing:IsA("Folder"), "Expected category Folder")
			return existing
		end
		local value = Instance.new("Folder")
		value.Name = name
		value.Parent = parent
		return value
	end
	local category = folder(folder(ServerStorage, "Assets"), "Eggs")
	assert(not category:FindFirstChild("Ocean"), "Optimized set already exists")
	local set = Instance.new("Model")
	set.Name = "Ocean"
	set:SetAttribute("Status", "Building")
	set:SetAttribute("CompletedComponents", 0)
	set:SetAttribute("FailedComponents", 0)
	set:SetAttribute("Source", "Blender ocean-v1")
	set.Parent = category
	task.spawn(function()
		local success, err = pcall(function()
			local completed, failures = 0, 0
			for _, theme in { "Kelp", "Leviathan", "Treasure", "Abyss", "Jelly" } do
				local template = assert(source:FindFirstChild(theme))
				local egg = Instance.new("Model")
				egg.Name = theme
				egg:SetAttribute("AssetTheme", theme)
				egg:SetAttribute("DisplayHeightStuds", 10)
				egg:SetAttribute("PivotAtBase", true)
				egg:SetAttribute("GeometryKind", "PersistentNativeCSG")
				egg.Parent = set
				for _, original in template:GetChildren() do
					if original:IsA("Model") then
						local group = original:Clone()
						local cf = group:GetBoundingBox()
						local parts = group:GetChildren()
						local anchor = Instance.new("Part")
						anchor.Size = Vector3.one * 0.001
						anchor.CFrame = CFrame.new(cf.Position)
						anchor.Color = parts[1].Color
						anchor.Material = parts[1].Material
						local ok, results = pcall(function()
							return GeometryService:UnionAsync(anchor, parts, {
								SplitApart = false,
								CollisionFidelity = Enum.CollisionFidelity.Box,
								RenderFidelity = Enum.RenderFidelity.Precise,
							})
						end)
						if ok and #results > 0 then
							for i, part in results do
								part.Name = original.Name .. (if #results > 1 then tostring(i) else "")
								part.Anchored = true
								part.CanCollide = false
								part.CanTouch = false
								part.CanQuery = false
								part.Transparency = parts[1].Transparency
								part.Material = parts[1].Material
								part.CastShadow = parts[1].CastShadow
								part.UsePartColor = false
								part.Parent = egg
							end
							group:Destroy()
						else
							group.Parent = egg
							group:SetAttribute("UnionFailure", tostring(results))
							failures += 1
							set:SetAttribute("FailedComponents", failures)
						end
						anchor:Destroy()
						completed += 1
						set:SetAttribute("CompletedComponents", completed)
						set:SetAttribute("CurrentTheme", theme)
						task.wait()
					end
				end
				egg.WorldPivot = CFrame.identity
			end
			set:SetAttribute("Status", "Ready")
		end)
		if not success then
			set:SetAttribute("Status", "Error")
			set:SetAttribute("Error", tostring(err))
		end
	end)
	return set:GetFullName()
end
