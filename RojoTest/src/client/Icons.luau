--!strict
local Assets = require(script.Parent.UIAssets)
local Icons = {}
local C = Color3.fromRGB
function Icons.draw(parent, kind, color)
	local key = kind
	if kind == "Trails" then
		if color == C(244, 247, 255) then
			key = "WhiteTrail"
		elseif color == C(255, 48, 84) then
			key = "RedTrail"
		elseif color == C(30, 191, 255) then
			key = "BlueTrail"
		end
	end
	local asset, offset, size = Assets.resolve(key)
	local image = Instance.new("ImageLabel")
	image.Name = "Icon_" .. key
	image.BackgroundTransparency = 1
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(0.5, 0.5)
	image.Size = UDim2.fromScale(1, 1)
	image.Image = asset
	image.ImageRectOffset = offset
	image.ImageRectSize = size
	image.ScaleType = Enum.ScaleType.Fit
	image.Parent = parent
	Assets.bind(image)
	return image
end
return Icons
