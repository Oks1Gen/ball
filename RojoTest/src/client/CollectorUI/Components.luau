local Packages = game.ReplicatedStorage.Packages
local React = require(Packages.React)
local Ripple = require(Packages.Ripple)
local Input = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local Theme = require(script.Parent.Theme)
local Art = require(script.Parent.Art)
local OldArt = require(script.Parent.Parent.UIAssets)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Visuals = require(game.ReplicatedStorage.Shared.PetVisuals)
local Hooks = require(script.Parent.createHooks)(React, Ripple, Input)
local e, C = React.createElement, Color3.fromRGB
local U = {Hooks = Hooks}
U.MotionContext = React.createContext(false)
function U.corner(r) return e("UICorner", {CornerRadius = UDim.new(0, r or 12)}) end
function U.Label(p)
	return e("TextLabel", {Name = p.Name or "Label", BackgroundTransparency = 1,
		Position = p.Position, Size = p.Size or UDim2.fromScale(1, 1), AnchorPoint = p.AnchorPoint,
		Text = p.Text or "", Font = Enum.Font.FredokaOne, TextSize = p.TextSize or 22,
		TextColor3 = p.Color or Theme.Text, TextWrapped = p.Wrap == true,
		TextTruncate = p.Wrap and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
		TextXAlignment = p.Align or Enum.TextXAlignment.Center, ZIndex = p.ZIndex or 12,
	}, {Stroke = e("UIStroke", {Color = Theme.Outline, Thickness = p.Small and 1.5 or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual})})
end
function U.Icon(p)
	local slot = Art.Slots[p.Kind]
	local image, offset, size = Art.Image, nil, nil
	if slot then
		offset, size = Vector2.new(slot % 4 * 256, math.floor(slot / 4) * 256), Vector2.new(256, 256)
	else
		local rect = OldArt.Rects[p.Kind]
		image = OldArt.Image
		if rect then
			offset, size = Vector2.new(rect[1] * OldArt.Width, rect[2] * OldArt.Height), Vector2.new(rect[3] * OldArt.Width, rect[4] * OldArt.Height)
		end
	end
	return e("ImageLabel", {Name = p.Name or (p.Kind .. "Art"), BackgroundTransparency = 1,
		Position = p.Position, Size = p.Size or UDim2.fromScale(1, 1), AnchorPoint = p.AnchorPoint,
		Image = image, ImageRectOffset = offset, ImageRectSize = size, ScaleType = Enum.ScaleType.Fit,
		ImageColor3 = p.Color or Color3.new(1, 1, 1), Rotation = p.Rotation or 0,
		Active = false, ZIndex = p.ZIndex or 14})
end
function U.Surface(p)
	local color = p.Color or Theme.Body
	local radius, z = p.Radius or 12, p.ZIndex or 2
	local layers = {Corner = U.corner(radius)}
	layers.Outline = e("UIStroke", {Thickness = p.Outline or 3, Color = p.Selected and Theme.Colors.Green or Theme.Outline})
	local decoration = {
		Corner = U.corner(radius - 3),
		Inner = e("UIStroke", {Color = color:Lerp(Color3.new(1, 1, 1), 0.35), Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}),
		Gradient = e("UIGradient", {Rotation = 90, Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), p.Quiet and 0.035 or 0.14), color)}),
	}
	if p.Studs ~= false then
		decoration.Studs = e("ImageLabel", {Name = "Studs", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
			Image = Config.StudTexture, ImageColor3 = p.Quiet and C(145, 180, 220) or Color3.new(1, 1, 1),
			ImageTransparency = p.Quiet and 0.93 or 0.87, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(44, 44),
			ZIndex = z + 3, Active = false}, {Corner = U.corner(radius - 3)})
	end
	if p.Shine then
		decoration.Shine = e("Frame", {BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.88,
			Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ZIndex = z + 4}, {
			Corner = U.corner(radius - 3), Fade = e("UIGradient", {Rotation = 25, Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 1), NumberSequenceKeypoint.new(0.21, 0),
				NumberSequenceKeypoint.new(0.4, 0), NumberSequenceKeypoint.new(0.41, 1), NumberSequenceKeypoint.new(1, 1)})})})
	end
	if p.Motion then
		decoration.Tint = e("Frame", {Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ZIndex = z + 5,
			BackgroundColor3 = p.Motion:map(function(t) return t >= 0 and Color3.new(1, 1, 1) or Color3.new() end),
			BackgroundTransparency = p.Motion:map(function(t) return 1 - math.abs(t) * 0.12 end)}, {Corner = U.corner(radius - 3)})
	end
	layers.Face = e("Frame", {Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -10),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = z + 2}, decoration)
	layers.Content = e("Frame", {Name = "Content", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = z + 6}, p.Children)
	return e("Frame", {Name = p.Name or "Surface", Size = p.Size or UDim2.fromScale(1, 1), Position = p.Position,
		AnchorPoint = p.AnchorPoint, BackgroundTransparency = 1, ZIndex = z}, {
		Shadow = not p.NoShadow and e("Frame", {Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(0, 5),
			BackgroundColor3 = Color3.new(), BorderSizePixel = 0, ZIndex = z}, {Corner = U.corner(radius)}),
		Body = e("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1),
			Position = p.Motion and p.Motion:map(function(t) return UDim2.fromOffset(0, math.round(-t * (t > 0 and 4 or 3))) end) or nil,
			BackgroundColor3 = color:Lerp(Theme.Outline, 0.5), BorderSizePixel = 0, ZIndex = z + 1}, layers),
	})
end
function U.Button(p)
	local reduced = React.useContext(U.MotionContext)
	local motionProps = table.clone(p)
	motionProps.ReducedMotion = reduced or p.ReducedMotion
	local progress, events = Hooks.useButtonMotion(motionProps, Theme)
	local props = {Name = p.Name or "Button", Text = "", BackgroundTransparency = 1,
		Size = p.Size, Position = p.Position, AnchorPoint = p.AnchorPoint, AutoButtonColor = false,
		Active = not p.Disabled, Selectable = not p.Disabled, ZIndex = p.ZIndex or 20,
		[React.Event.Activated] = function() if not p.Disabled and p.OnActivated then p.OnActivated() end end}
	for key, value in events do props[key] = value end
	local children = table.clone(p.Children or {})
	if p.Text then children.Caption = e(U.Label, {Name = "Caption", Text = p.Text,
		Position = UDim2.fromOffset(p.Icon and 42 or 8, 3), Size = UDim2.new(1, p.Icon and -50 or -16, 1, -6),
		TextSize = p.TextSize or 22, ZIndex = 30}) end
	if p.Icon then children.Icon = e(U.Icon, {Kind = p.Icon, Position = UDim2.fromOffset(6, 5), Size = UDim2.fromOffset(32, 32), ZIndex = 30}) end
	return e("TextButton", props, {Visual = e(U.Surface, {Color = p.Disabled and Theme.Colors.Slate or (p.Color or Theme.Colors.Green),
		Radius = p.Radius or 10, Shine = true, Motion = progress, Children = children, Studs = p.Studs, ZIndex = p.ZIndex or 20})})
end
function U.FloatingIcon(p)
	local time, updateTime = React.useBinding(0)
	React.useEffect(function()
		if p.Reduced then updateTime(0) return end
		local start = os.clock()
		local connection = Run.RenderStepped:Connect(function() updateTime(os.clock() - start) end)
		return function() connection:Disconnect() end
	end, {p.Reduced == true})
	return e(U.Icon, {Kind = p.Kind, Size = p.Size, AnchorPoint = p.AnchorPoint,
		Position = time:map(function(t) return (p.Position or UDim2.new()) + UDim2.fromOffset(0, math.round(math.sin(t * 1.4) * 4)) end),
		Rotation = time:map(function(t) return math.sin(t * 0.8) * 3 end)})
end
local function fallbackPet(def)
	local m = Instance.new("Model")
	local function part(name, size, pos, color)
		local p = Instance.new("Part") p.Name = name p.Size = size p.Position = pos p.Color = color
		p.Anchored = true p.CanCollide = false p.Material = Enum.Material.SmoothPlastic p.Parent = m return p
	end
	local fur = def.color or C(255, 203, 71)
	part("Body", Vector3.new(2.4, 2.1, 2), Vector3.zero, fur)
	for _, side in {-1, 1} do
		part("Ear", Vector3.new(0.65, def.id == "Bunny" and 1.8 or 0.8, 0.7), Vector3.new(side * 0.8, 1.2, 0), fur)
		part("Eye", Vector3.new(0.45, 0.6, 0.1), Vector3.new(side * 0.52, 0.2, -1.04), C(18, 23, 38))
		part("Highlight", Vector3.new(0.13, 0.18, 0.04), Vector3.new(side * 0.52 - 0.08, 0.35, -1.1), C(255, 255, 255))
		part("Foot", Vector3.new(0.65, 0.35, 0.7), Vector3.new(side * 0.65, -1.15, -0.4), fur)
		if def.id == "Dragon" then
			local wing = part("Wing", Vector3.new(1, 0.15, 1.4), Vector3.new(side * 1.55, 0.2, 0.2), fur)
			wing.CFrame *= CFrame.Angles(0, 0, side * 0.5)
		end
	end
	part("Nose", Vector3.new(0.3, 0.2, 0.1), Vector3.new(0, -0.35, -1.08), C(110, 70, 59))
	m.WorldPivot = CFrame.identity
	return m
end
function U.PetView(p)
	local ref = React.useRef(nil)
	React.useEffect(function()
		local viewport = ref.current
		local model = Visuals.create(p.Def.visual or p.Def.id, 2.8) or fallbackPet(p.Def)
		local world = Instance.new("WorldModel") world.Parent = viewport model.Parent = world
		local cf, size = model:GetBoundingBox() model.WorldPivot = cf model:PivotTo(CFrame.identity)
		local camera = Instance.new("Camera") camera.FieldOfView = 34
		local radius = math.max(size.X, size.Y, size.Z) * 0.54
		camera.CFrame = CFrame.lookAt(Vector3.new(0.7, 0.4, -1).Unit * radius / math.tan(math.rad(17)) * 1.3, Vector3.zero)
		camera.Parent = viewport viewport.CurrentCamera = camera
		local connection
		if p.Animated and not p.ReducedMotion then
			local start = os.clock()
			connection = Run.RenderStepped:Connect(function()
				local t = os.clock() - start
				model:PivotTo(CFrame.new(0, math.sin(t * 1.7) * 0.07, 0) * CFrame.Angles(0, math.sin(t * 0.65) * 0.16, 0))
			end)
		end
		return function() if connection then connection:Disconnect() end world:Destroy() camera:Destroy() end
	end, {p.Def.id, p.Animated == true, p.ReducedMotion == true})
	return e("ViewportFrame", {ref = ref, Name = "PetPreview", BackgroundTransparency = 1,
		Size = p.Size or UDim2.fromScale(1, 1), Position = p.Position, ZIndex = p.ZIndex or 15,
		Ambient = C(210, 216, 235), LightColor = C(255, 245, 225), LightDirection = Vector3.new(-1, -1, -1), Active = false})
end
function U.Scroll(p)
	return e("ScrollingFrame", {Name = p.Name or "Scroll", Size = p.Size, Position = p.Position,
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Muted, CanvasSize = UDim2.fromOffset(0, p.Height or 0),
		ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 10, ClipsDescendants = true}, p.Children)
end
function U.TrailPreview(p)
	local ref = React.useRef(nil)
	React.useEffect(function()
		local viewport = ref.current
		local world = Instance.new("WorldModel") world.Parent = viewport
		local function part(size, cf, color)
			local piece = Instance.new("Part") piece.Size = size piece.CFrame = cf piece.Color = color
			piece.Anchored = true piece.CanCollide = false piece.Material = Enum.Material.SmoothPlastic piece.Parent = world return piece
		end
		part(Vector3.new(1, 1, 1), CFrame.new(1.8, 1.7, 0), C(255, 210, 71))
		part(Vector3.new(1.4, 1.4, 0.75), CFrame.new(1.8, 0.5, 0) * CFrame.Angles(0, 0, -0.15), C(39, 148, 244))
		for _, side in {-1, 1} do
			part(Vector3.new(0.5, 1.2, 0.5), CFrame.new(1.8 + side * 0.47, -0.65, 0) * CFrame.Angles(0, 0, side * 0.45), C(44, 78, 123))
			part(Vector3.new(0.5, 1.2, 0.5), CFrame.new(1.8 + side * 0.93, 0.5, 0) * CFrame.Angles(0, 0, -side * 0.7), C(255, 210, 71))
		end
		for strand = 1, 3 do
			for i = 1, 10 do
				local t = i / 10
				local color = p.Rainbow and Color3.fromHSV((t + strand / 5) % 1, 0.7, 1) or p.Color
				local v = Vector3.new(1.1 - t * 5, 0.1 + math.sin(t * 3.5 + strand) * 0.22, (strand - 2) * 0.38)
				local piece = part(Vector3.new(0.75, 0.08 + (1 - t) * 0.13, 0.25), CFrame.new(v), color)
				piece.Material = Enum.Material.Neon piece.Transparency = t * 0.4
			end
		end
		local camera = Instance.new("Camera") camera.FieldOfView = 34
		camera.CFrame = CFrame.lookAt(Vector3.new(1, 4, -12), Vector3.new(-0.5, 0.3, 0))
		camera.Parent = viewport viewport.CurrentCamera = camera
		return function() world:Destroy() camera:Destroy() end
	end, {p.Color, p.Rainbow == true})
	return e("ViewportFrame", {Name = "TrailPreview", ref = ref, BackgroundTransparency = 1,
		Size = p.Size, Position = p.Position, ZIndex = 16, Ambient = C(210, 220, 235), LightColor = Color3.new(1, 1, 1), Active = false})
end
return U
