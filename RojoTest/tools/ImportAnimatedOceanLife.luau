-- Call after Studio MCP insert_asset into ServerStorage, using the matching rig-manifest entry.
-- Removes the package link before authoring so these are independent game assets.
return function(raw: Model, entry: any, pack: Instance): Model
	assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning())
	for _, node in raw:GetDescendants() do
		if node:IsA("PackageLink") then
			node:Destroy()
		end
	end
	local mesh = raw:FindFirstChildWhichIsA("MeshPart", true)
	assert(mesh, entry.name .. ": missing skinned MeshPart")
	local root = mesh:FindFirstChild("Root", true)
	assert(root and root:IsA("Bone"), entry.name .. ": missing Root bone")
	local model = Instance.new("Model")
	model.Name = entry.name
	model.WorldPivot = root.WorldCFrame
	mesh.Parent = model
	model:PivotTo(CFrame.identity)
	mesh.PivotOffset = mesh.CFrame:ToObjectSpace(root.WorldCFrame)
	model.PrimaryPart = mesh
	mesh.Anchored = true
	mesh.CanCollide = false
	mesh.CanTouch = false
	mesh.CanQuery = false
	mesh.CastShadow = false
	for _, node in mesh:GetDescendants() do
		if node:IsA("Bone") then
			node.Transform = CFrame.identity
		end
	end
	model:SetAttribute("WildlifeKind", entry.kind)
	model:SetAttribute("NavigationRadius", entry.radius)
	model:SetAttribute("MotionRecipe", game:GetService("HttpService"):JSONEncode(entry.motion))
	model:SetAttribute("Source", "Assets/OceanDepths/AnimatedSeaLife/animated-wildlife.blend")
	local old = pack:FindFirstChild(model.Name)
	model.Parent = pack
	if old then
		old:Destroy()
	end
	raw:Destroy()
	return model
end
