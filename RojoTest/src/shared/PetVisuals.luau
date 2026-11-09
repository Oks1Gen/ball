--!strict
local Visuals = {}
-- Imported pets share a 1.8-stud body width. Match the existing Watermelon
-- follower scale without shrinking bodies to fit wings, ears or decorations.
Visuals.FollowerBodyWidth = 2.8 * 1.8 / 2.14

-- MeshSize is engine-owned and cannot be hydrated by Rojo's property writes.
-- Apply a natively loaded mesh before these templates replicate to clients.
function Visuals.prepare()
	local run = game:GetService("RunService")
	assert(not run:IsRunning() or run:IsServer(), "Prepare pet meshes on the server")
	local templates = script.Parent:WaitForChild("PetTemplates")
	for _, model in templates:GetChildren() do
		for _, p in model:GetDescendants() do
			if p:IsA("MeshPart") and p.MeshSize.Magnitude == 0 then
				local loaded = game:GetService("AssetService"):CreateMeshPartAsync(Content.fromUri(p.MeshId))
				local size, cf = p.Size, p.CFrame
				local texture = p.TextureID
				p:ApplyMesh(loaded)
				p.Size = size
				p.CFrame = cf
				p.TextureID = texture
				loaded:Destroy()
				assert(p.MeshSize.Magnitude > 0, "Pet mesh failed to load: " .. model.Name)
			end
		end
	end
	templates:SetAttribute("Ready", true)
end

function Visuals.create(id, diameter)
	local templates = script.Parent:FindFirstChild("PetTemplates")
	local template = templates and templates:FindFirstChild(id)
	if not template then
		return nil
	end
	local model = template:Clone()
	model.Name = "Pet_" .. id
	model:SetAttribute("PetId", id)
	local cf, size = model:GetBoundingBox()
	model.WorldPivot = cf
	model:ScaleTo(model:GetScale() * (diameter or 2.8) / math.max(size.X, size.Y, size.Z))
	model:PivotTo(CFrame.identity)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
		end
	end
	return model
end

function Visuals.follower(id)
	local templates = script.Parent:FindFirstChild("PetTemplates")
	local template = templates and templates:FindFirstChild(id)
	if not template then
		return nil
	end
	local _, size = template:GetBoundingBox()
	return Visuals.create(id, math.max(size.X, size.Y, size.Z) * Visuals.FollowerBodyWidth / 1.8)
end

function Visuals.preview(parent, id, x, y, width, height): ViewportFrame?
	local model = Visuals.create(id, 2.8)
	if not model then
		return nil
	end
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "PetPreview"
	viewport.BackgroundTransparency = 1
	viewport.Position = UDim2.fromOffset(x, y)
	viewport.Size = UDim2.fromOffset(width, height)
	viewport.Ambient = Color3.new(0.8, 0.8, 0.8)
	viewport.LightColor = Color3.new(1, 1, 1)
	viewport.LightDirection = Vector3.new(-1, -1, -1)
	viewport.Active = false
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	model.Parent = world
	local camera = Instance.new("Camera")
	camera.FieldOfView = 35
	local aspect = math.max(0.1, width / height)
	local distance = 1.65 / (math.tan(math.rad(17.5)) * math.min(1, aspect))
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 0.3, -distance), Vector3.zero)
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	viewport.Parent = parent
	return viewport
end

-- Native material/color variants retain eyes and texture detail. No mesh duplication.
function Visuals.applyVariant(model: Model, pet: any)
	if not pet then
		return
	end
	local colors = {
		Golden = Color3.fromRGB(255, 204, 40),
		Diamond = Color3.fromRGB(100, 225, 255),
		Rainbow = Color3.fromRGB(227, 126, 255),
	}
	local color = colors[pet.form]
	if color then
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") and not string.find(string.lower(part.Name), "eye") then
				part.Color = part.Color:Lerp(color, 0.75)
				part.Material = if pet.form == "Diamond" then Enum.Material.Glass else Enum.Material.Metal
				part.Reflectance = 0.15
			elseif part:IsA("SurfaceAppearance") then
				part.Color = color
			end
		end
	end
	local mutationColors = {
		Wind = Color3.fromRGB(140, 255, 220),
		Frost = Color3.fromRGB(150, 240, 255),
		Flame = Color3.fromRGB(255, 130, 40),
		Storm = Color3.fromRGB(175, 120, 255),
		Cosmic = Color3.fromRGB(255, 220, 90),
	}
	if mutationColors[pet.mutation] then
		local highlight = Instance.new("Highlight")
		highlight.Name = "MutationOutline"
		highlight.FillTransparency = 0.92
		highlight.OutlineTransparency = 0.15
		highlight.FillColor = mutationColors[pet.mutation]
		highlight.OutlineColor = mutationColors[pet.mutation]
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Parent = model
	end
	if color and game:GetService("RunService"):IsClient() then
		require(script.Parent.PetVariantMeshes).apply(model, pet.form)
	end
	model:SetAttribute("VariantKey", tostring(pet.form) .. ":" .. tostring(pet.mutation))
end
return Visuals
