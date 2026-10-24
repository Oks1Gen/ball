--!strict
-- Shared GUI factories for the legacy HUD, the legacy panels and the admin
-- window. Every helper returns the instance it created so the caller can
-- adjust it further.
local Motion = require(game.ReplicatedStorage.Shared.UiMotion)
local Icons = require(script.Parent.Parent.Icons)
local PetVisuals = require(game.ReplicatedStorage.Shared.PetVisuals)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Style = require(script.Parent.Parent.UiStyle)
local Assets = require(script.Parent.Parent.UIAssets)

local Kit = {}
local C = Color3.fromRGB
local white, dark = Style.Text, Style.Ink

-- Logical buttons keep a fixed hitbox; all artwork lives in this centred layer.
function Kit.visualOf(node: Instance): any
	return node:FindFirstChild("ButtonVisual") or node
end

function Kit.corner(obj: GuiObject, radius: number): UICorner
	obj = Kit.visualOf(obj)
	local r = Instance.new("UICorner")
	r.CornerRadius = UDim.new(0, radius)
	r.Parent = obj
	return r
end

function Kit.stroke(obj: GuiObject, thickness: number?, color: Color3?): UIStroke
	obj = Kit.visualOf(obj)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 2
	s.Color = color or dark
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = obj
	return s
end

function Kit.text(
	parent: Instance,
	name: string,
	value: string,
	x: number,
	y: number,
	w: number,
	h: number,
	size: number?,
	color: Color3?
): TextLabel
	parent = Kit.visualOf(parent)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Position = UDim2.fromOffset(x, y)
	l.Size = UDim2.fromOffset(w, h)
	l.Text = value
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBlack
	l.TextSize = size or 24
	l.TextColor3 = color or white
	l.TextStrokeColor3 = dark
	l.TextStrokeTransparency = 1
	l.Parent = parent
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Thickness = (size or 24) >= 40 and 3.5 or 2
	s.Color = dark
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = l
	return l
end

function Kit.frame(parent: Instance, name: string, x: number, y: number, w: number, h: number, color: Color3?): Frame
	parent = Kit.visualOf(parent)
	local f = Instance.new("Frame")
	f.Name = name
	f.Position = UDim2.fromOffset(x, y)
	f.Size = UDim2.fromOffset(w, h)
	f.BackgroundColor3 = color or dark
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

function Kit.pattern(parent: Instance, color: Color3?): ImageLabel
	parent = Kit.visualOf(parent)
	local tile = Instance.new("ImageLabel")
	tile.Name = "Studs"
	tile.Size = UDim2.fromScale(1, 1)
	tile.BackgroundTransparency = 1
	tile.Image = Config.StudTexture
	tile.ImageColor3 = color or white
	tile.ImageTransparency = Style.StudAlpha
	tile.ScaleType = Enum.ScaleType.Tile
	tile.TileSize = UDim2.fromOffset(Style.StudTile, Style.StudTile)
	tile.ZIndex = parent:IsA("GuiObject") and parent.ZIndex or 1
	tile.Parent = parent
	Kit.corner(tile, 6)
	return tile
end

function Kit.icon(parent: Instance, kind: string, x: number, y: number, w: number, h: number, color: Color3?): Frame
	local box = Kit.frame(parent, kind .. "Icon", x, y, w, h)
	box.BackgroundTransparency = 1
	Icons.draw(box, kind, color)
	return box
end

function Kit.burst(parent: GuiObject): ImageLabel
	local image = Instance.new("ImageLabel")
	image.Name = "RewardBurst"
	image.Image = Assets.Burst
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.ImageTransparency = 0.55
	image.ZIndex = 2
	image.Parent = parent
	Assets.bind(image)
	return image
end

function Kit.petIcon(parent: Instance, def: any, x: number, y: number, w: number, h: number): Instance?
	parent = Kit.visualOf(parent)
	local preview = PetVisuals.preview(parent, def.visual or def.id, x, y, w, h)
	if preview then
		return preview
	end
	return Kit.icon(parent, "Pets", x, y, w, h, def.color)
end

-- A brick plate. It is the surface of the whole interface: a saturated face
-- with the stud texture, a bright top edge and a dark ink border.
function Kit.brick(
	parent: Instance,
	name: string,
	x: number,
	y: number,
	w: number,
	h: number,
	color: Color3,
	radius: number?
): Frame
	local f = Kit.frame(parent, name, x, y, w, h, color)
	Kit.corner(f, radius or 9)
	Kit.stroke(f, 2)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color:Lerp(white, 0.22)),
		ColorSequenceKeypoint.new(1, color),
	})
	gradient.Parent = f
	Kit.pattern(f, color:Lerp(white, 0.25))
	return f
end

function Kit.button(
	parent: Instance,
	name: string,
	value: string,
	x: number,
	y: number,
	w: number,
	h: number,
	color: Color3,
	size: number?,
	callback: (() -> ())?
): TextButton
	local shadow = Kit.frame(parent, name .. "Shadow", x, y + 4, w, h, C(26, 26, 34))
	shadow.ZIndex = 0 -- Reparenting into HUD blocks must never put a shadow over its button.
	shadow.BackgroundTransparency = 0.25
	Kit.corner(shadow, 8)
	local shadowVisual = Instance.new("Frame")
	shadowVisual.Name = "ButtonVisual"
	shadowVisual.Size = UDim2.fromScale(1, 1)
	shadowVisual.AnchorPoint = Vector2.new(0.5, 0.5)
	shadowVisual.Position = UDim2.fromScale(0.5, 0.5)
	shadowVisual.BackgroundColor3 = shadow.BackgroundColor3
	shadowVisual.BackgroundTransparency = shadow.BackgroundTransparency
	shadowVisual.BorderSizePixel = 0
	for _, child in shadow:GetChildren() do
		child.Parent = shadowVisual
	end
	shadow.BackgroundTransparency = 1
	shadowVisual.Parent = shadow
	local shadowScale = Instance.new("UIScale")
	shadowScale.Name = "FeedbackScale"
	shadowScale.Parent = shadowVisual
	local b = Instance.new("TextButton")
	b.Name = name
	b.Position = UDim2.fromOffset(x, y)
	b.Size = UDim2.fromOffset(w, h)
	b.BackgroundTransparency = 1
	b.BorderSizePixel = 0
	b.Text = ""
	b.AutoButtonColor = false
	b.Parent = parent
	local visual = Instance.new("Frame")
	visual.Name = "ButtonVisual"
	visual.Size = UDim2.fromScale(1, 1)
	visual.BorderSizePixel = 0
	visual.BackgroundColor3 = color
	visual.Parent = b
	Kit.corner(b, 7)
	Kit.stroke(b, 2)
	Kit.pattern(b, color:Lerp(white, 0.25))
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, white),
		ColorSequenceKeypoint.new(0.45, C(246, 246, 246)),
		ColorSequenceKeypoint.new(1, C(210, 210, 210)),
	})
	gradient.Parent = visual
	local caption = Kit.text(b, "Caption", value, 4, 2, w - 8, h - 4, size or 26)
	caption.TextScaled = true
	caption.ZIndex = 3
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 10
	limit.MaxTextSize = size or 26
	limit.Parent = caption
	Motion.button(b, visual, shadowVisual)
	if callback then
		b.Activated:Connect(function()
			if Motion.enabled(b) then
				callback()
			end
		end)
	end
	return b
end

-- Hides a child without touching the instance type of the parent.
function Kit.hide(parent: Instance, name: string)
	local node = Kit.visualOf(parent):FindFirstChild(name)
	if node and node:IsA("GuiObject") then
		node.Visible = false
	elseif node and node:IsA("UIStroke") then
		node.Enabled = false
	end
end

-- The caption of a button built by Kit.button.
function Kit.captionOf(button: Instance): TextLabel?
	local caption = Kit.visualOf(button):FindFirstChild("Caption")
	if caption and caption:IsA("TextLabel") then
		return caption
	end
	return nil
end

function Kit.cornerOf(node: Instance): UICorner?
	local corner = Kit.visualOf(node):FindFirstChildOfClass("UICorner")
	if corner and corner:IsA("UICorner") then
		return corner
	end
	return nil
end

function Kit.studsOf(node: Instance): ImageLabel?
	local studs = Kit.visualOf(node):FindFirstChild("Studs")
	if studs and studs:IsA("ImageLabel") then
		return studs
	end
	return nil
end

-- Repaints the visual plate; motion never alters its colour.
function Kit.paint(button: TextButton, color: Color3): TextButton
	Kit.visualOf(button).BackgroundColor3 = color
	local studs = Kit.studsOf(button)
	if studs then
		studs.ImageColor3 = color:Lerp(white, 0.25)
	end
	return button
end

return Kit
