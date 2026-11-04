--!strict
local Shared = script.Parent
local _Config = require(Shared.GameConfig)
local Visuals = {}

function Visuals.create(id: string, diameter: number): Model
	local templates = Shared:WaitForChild("BallTemplates")
	local template = templates:FindFirstChild(id) or templates:FindFirstChild("Pebble")
	assert(template and template:IsA("Model"), "Missing ball template")
	local model = template:Clone()
	model.Name = "Ball_" .. id
	model:SetAttribute("BallId", id)
	-- Templates carry their largest outer dimension (rings, sparks and spikes included) and keep the
	-- ball centred on the template origin, so every ball fills the same size and spins about its centre.
	local fit = model:GetAttribute("FitSize")
	if typeof(fit) == "number" and fit > 0 then
		model.WorldPivot = CFrame.new()
		model:ScaleTo(model:GetScale() * diameter / fit)
	else
		local cf, size = model:GetBoundingBox()
		model.WorldPivot = cf
		model:ScaleTo(model:GetScale() * diameter / math.max(size.X, size.Y, size.Z))
	end
	model:PivotTo(CFrame.new())
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
	return model
end

-- Changes whenever a template's fit size changes, so placed display copies know to rebuild.
function Visuals.fitKey(id: string): string
	local templates = Shared:WaitForChild("BallTemplates")
	local template = templates:FindFirstChild(id) or templates:FindFirstChild("Pebble")
	return tostring(template and template:GetAttribute("FitSize"))
end

function Visuals.visible(model: Model, visible: boolean)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = visible and 0 or 1
		end
	end
end

function Visuals.preview(parent: Instance, id: string)
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "BallPreview"
	viewport.BackgroundTransparency = 1
	viewport.Size = UDim2.fromOffset(105, 83)
	viewport.Position = UDim2.fromOffset(10, 3)
	viewport.Ambient = Color3.new(1, 1, 1)
	viewport.LightColor = Color3.new(1, 1, 1)
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local ball = Visuals.create(id, 2.4)
	ball.Parent = world
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 0.5, -5), Vector3.zero)
	camera.FieldOfView = 35
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	viewport.Parent = parent
	return viewport
end

-- Deterministic cosmetic motion; never accumulates position error.
function Visuals.displayOrigin(model: Model): (CFrame?, Vector3?)
	local display = model.Parent
	local localBase = model:GetAttribute("DisplayBaseLocal")
	local localLabel = model:GetAttribute("DisplayLabelLocal")
	if display and display:IsA("Model") and typeof(localBase) == "CFrame" and typeof(localLabel) == "Vector3" then
		local top = display:FindFirstChild("DisplayTop")
		if not top or not top:IsA("BasePart") then
			return nil, nil -- A partially streamed display will retry next frame.
		end
		return top.CFrame * localBase, top.CFrame:PointToWorldSpace(localLabel)
	end
	return model:GetAttribute("DisplayBasePivot") :: CFrame?, model:GetAttribute("DisplayLabelBase") :: Vector3?
end

-- `amplitude`: the stand's DisplayBob attribute, which follows the world scale.
function Visuals.standPose(base: CFrame, time: number, phase: number, amplitude: number?)
	local bob = (amplitude or 0.45) * math.sin((time % 2.5) * math.pi * 2 / 2.5 + phase)
	return (base + Vector3.new(0, bob, 0)) * CFrame.Angles(0, (time % 22.5) * math.pi * 2 / 22.5, 0), bob
end

-- Equal visible clearance and text size across both depths of the stand.
-- Project the animated ball's complete bounds, then place its card directly
-- above that silhouette on the common camera-facing caption plane.
function Visuals.captionPosition(model: Model, camera: Camera, depth: number, gap: number, height: number): Vector3?
	if depth < 1 or depth == math.huge then
		return nil
	end
	local cf, size = model:GetBoundingBox()
	local left, right, top = math.huge, -math.huge, -math.huge
	for _, x in { -0.5, 0.5 } do
		for _, y in { -0.5, 0.5 } do
			for _, z in { -0.5, 0.5 } do
				local p = camera.CFrame:PointToObjectSpace(cf:PointToWorldSpace(size * Vector3.new(x, y, z)))
				if p.Z >= -1 then
					return nil
				end
				left, right = math.min(left, p.X / -p.Z), math.max(right, p.X / -p.Z)
				top = math.max(top, p.Y / -p.Z)
			end
		end
	end
	return camera.CFrame:PointToWorldSpace(
		Vector3.new((left + right) * depth / 2, top * depth + gap + height / 2, -depth)
	)
end

return Visuals
