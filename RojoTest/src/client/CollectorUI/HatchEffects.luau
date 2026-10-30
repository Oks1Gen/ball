--!strict
-- Shell burst of the clicked reveal, tinted with the final tier.
-- Screen-space layers share the stage clock; no extra frame connections or uploaded assets.
local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local WHITE = Color3.fromRGB(255, 250, 222)
type Props = {
	At: ((number) -> any) -> any,
	Center: Vector2,
	Size: number,
	-- Seconds since the shell burst; negative before it.
	Age: (number) -> number,
	ShellColor: Color3,
	Color: Color3,
}
local function clamp(x: number): number
	return math.clamp(x, 0, 1)
end

return function(p: Props)
	local at, size = p.At, p.Size
	local x, y = p.Center.X, p.Center.Y
	local children = {}
	local function age(t: number): number
		return p.Age(t)
	end
	local function opacity(t: number): number
		local a = age(t)
		return a < 0 and 1 or clamp((a - 0.1) / 0.85)
	end
	for k = 1, 16 do
		children["Ray" .. k] = e("Frame", {
			Name = "HatchLightRay",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = at(function(t)
				local q = clamp(age(t) / 0.4)
				local length = size * (0.3 + q * (k % 2 == 0 and 0.6 or 0.45))
				local angle = math.rad(k * 22.5 + 11)
				return UDim2.fromOffset(x + math.sin(angle) * length / 2, y - math.cos(angle) * length / 2)
			end),
			Size = at(function(t)
				local q = clamp(age(t) / 0.4)
				return UDim2.fromOffset(
					size * (k % 3 == 0 and 0.045 or 0.022),
					size * (0.3 + q * (k % 2 == 0 and 0.6 or 0.45))
				)
			end),
			Rotation = k * 22.5 + 11,
			BackgroundColor3 = k % 3 == 0 and WHITE or p.Color,
			BackgroundTransparency = at(opacity),
			BorderSizePixel = 0,
			ZIndex = 11,
		}, {
			Fade = e("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0.45),
					NumberSequenceKeypoint.new(1, 0.9),
				}),
			}),
		})
	end
	for k = 1, 2 do
		children["Ring" .. k] = e("Frame", {
			Name = "HatchShockwave",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(x, y),
			Size = at(function(t)
				local q = clamp((age(t) - (k - 1) * 0.07) / 0.65)
				local s = size * (0.25 + (1 - (1 - q) ^ 3) * 1.05)
				return UDim2.fromOffset(s, s)
			end),
			BackgroundTransparency = 1,
			ZIndex = 12,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
			Edge = e("UIStroke", {
				Color = k == 1 and WHITE or p.Color,
				Thickness = k == 1 and 3 or 2,
				Transparency = at(function(t)
					local a = age(t) - (k - 1) * 0.07
					return a < 0 and 1 or clamp(0.15 + a / 0.65)
				end),
			}),
		})
	end
	for k = 1, 14 do
		local angle = k / 14 * math.pi * 2
		local starSize = size * (k % 3 == 0 and 0.13 or 0.08)
		children["Star" .. k] = e("ImageLabel", {
			Name = "HatchStar",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = "rbxasset://textures/particles/sparkles_main.dds",
			ImageColor3 = k % 3 == 0 and WHITE or p.Color,
			Size = UDim2.fromOffset(starSize, starSize),
			Position = at(function(t)
				local q = clamp((age(t) - 0.02) / 1.05)
				local distance = size * (0.1 + (1 - (1 - q) ^ 2) * (0.4 + k % 3 * 0.09))
				return UDim2.fromOffset(
					x + math.cos(angle) * distance,
					y + math.sin(angle) * distance * 0.7 + q * q * size * 0.22
				)
			end),
			Rotation = at(function(t)
				return k * 27 + math.max(0, age(t)) * (k % 2 == 0 and 130 or -130)
			end),
			ImageTransparency = at(function(t)
				local a = age(t) - 0.02
				return a < 0 and 1 or clamp((a - 0.35) / 0.65)
			end),
			ZIndex = 22,
		})
	end
	for k = 1, 10 do
		local angle = k / 10 * math.pi * 2 + 0.15
		local shardSize = size * (0.045 + k % 3 * 0.012)
		children["Shell" .. k] = e("CanvasGroup", {
			Name = "HatchShellShard",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(shardSize, shardSize * (k % 2 == 0 and 1.5 or 0.8)),
			Position = at(function(t)
				local q = clamp(age(t) / 0.85)
				local distance = size * (0.13 + q * 0.55)
				return UDim2.fromOffset(
					x + math.cos(angle) * distance,
					y + math.sin(angle) * distance * 0.5 - math.sin(q * math.pi) * size * 0.2 + q * q * size * 0.4
				)
			end),
			Rotation = at(function(t)
				return k * 41 + math.max(0, age(t)) * (k % 2 == 0 and 300 or -240)
			end),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			GroupTransparency = at(function(t)
				local a = age(t)
				return a < 0 and 1 or clamp((a - 0.25) / 0.55)
			end),
			BorderSizePixel = 0,
			ZIndex = 20,
		}, {
			Piece = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.8),
				Size = UDim2.fromScale(1, 1),
				Rotation = 45,
				BackgroundColor3 = k % 3 == 0 and WHITE or p.ShellColor:Lerp(WHITE, 0.3),
				BorderSizePixel = 0,
				ZIndex = 20,
			}, {
				Shade = e("UIGradient", { Rotation = 40, Color = ColorSequence.new(WHITE, p.ShellColor) }),
			}),
		})
	end
	children.Flash = e("ImageLabel", {
		Name = "HatchFlash",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x, y),
		Image = "rbxasset://textures/particles/smoke_main.dds",
		ImageColor3 = WHITE,
		Size = at(function(t)
			local q = clamp(age(t) / 0.24)
			return UDim2.fromOffset(size * (0.6 + q * 0.7), size * (0.6 + q * 0.7))
		end),
		ImageTransparency = at(function(t)
			local a = age(t)
			return a < -0.06 and 1 or clamp((a + 0.06) / 0.3)
		end),
		ZIndex = 23,
	})
	children.RevealGlow = e("ImageLabel", {
		Name = "PetRevealGlow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(size * 1.1, size * 1.1),
		Image = "rbxasset://textures/particles/smoke_main.dds",
		ImageColor3 = p.Color,
		ImageTransparency = at(function(t)
			local a = age(t)
			return a < 0.12 and 1 or 0.78 + clamp((a - 0.12) / 0.9) * 0.22
		end),
		ZIndex = 12,
	})
	return e(
		"Frame",
		{ Name = "HatchReferenceEffects", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2 },
		children
	)
end
