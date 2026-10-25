--!strict
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Config = require(script.Parent.Config)
local View = {}

function View.mount(screen: ScreenGui, skip: () -> ())
	local packages = game:GetService("ReplicatedStorage"):WaitForChild("Packages")
	local React = require(packages:WaitForChild("React"))
	local ReactRoblox = require(packages:WaitForChild("ReactRoblox"))
	local Ripple = require(packages:WaitForChild("Ripple"))
	local e = React.createElement
	local progress, setProgress = React.createBinding(0)
	local count, setCount = React.createBinding("0/0 assets loaded")
	local rotation, setRotation = React.createBinding(0)
	local fade, setFade = React.createBinding(0)
	local viewport, setViewport = React.createBinding(Vector2.new(1280, 720))
	local layout, setLayout =
		React.createBinding({ track = 595, loading = 647, count = 672, hint = 704, iconY = 313, iconSize = 403 })
	local motion = Ripple.createMotion(0, { start = true })
	local disconnectFade = motion:onChange(setFade)
	local alive = true
	local elapsed = 0
	local function measure()
		local camera = workspace.CurrentCamera
		local ok, inset = pcall(function()
			local all = GuiService:GetInsetArea(Enum.ScreenInsets.None)
			local safe = GuiService:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets)
			return math.max(0, all.Max.Y - safe.Max.Y)
		end)
		local v = if camera then camera.ViewportSize else Vector2.new(1280, 720)
		local height = v.Y
		local hint = height - (if ok then inset else 0) - 5 - math.max(12, height * 0.017) / 2
		local countY = math.min(height * 0.934, hint - math.max(18, height * 0.036))
		local loadingY = math.min(height * 0.898, countY - math.max(18, height * 0.036))
		local trackY = math.min(height * 0.827, loadingY - math.max(22, height * 0.071))
		local iconSize = math.min(height * 0.56, (trackY - 20 - height * 0.13) / 1.09)
		setLayout({
			track = trackY,
			loading = loadingY,
			count = countY,
			hint = hint,
			iconY = math.min(height * 0.435, trackY - 20 - iconSize * 0.55),
			iconSize = iconSize,
		})
		setViewport(v)
	end
	measure()
	local lastViewport = Vector2.zero
	local step = RunService.RenderStepped:Connect(function(dt: number)
		elapsed += dt
		setRotation(
			if screen:GetAttribute("ReducedMotion")
				then 0
				else math.sin(elapsed * 2 * math.pi / Config.TiltPeriod) * Config.TiltDegrees
		)
		local camera = workspace.CurrentCamera
		if camera and camera.ViewportSize ~= lastViewport then
			lastViewport = camera.ViewportSize
			measure()
		end
	end)
	local function label(name: string, text: any, key: string, size: number)
		return e("TextLabel", {
			Name = name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = layout:map(function(value)
				return UDim2.new(0.5, 0, 0, value[key])
			end),
			Size = viewport:map(function(v: Vector2)
				return UDim2.new(0.8, 0, 0, math.clamp(v.Y * size, 12, size * 1280) + 4)
			end),
			BackgroundTransparency = 1,
			Text = text,
			Font = Enum.Font.GothamBold,
			TextSize = viewport:map(function(v: Vector2)
				return math.clamp(v.Y * size, 12, size * 1280)
			end),
			TextColor3 = Config.Colors.Text,
			ZIndex = 2,
		}, {
			Stroke = e("UIStroke", {
				Color = Config.Colors.Ink,
				Thickness = viewport:map(function(v: Vector2)
					return math.clamp(v.Y / 420, 1, 3)
				end),
			}),
		})
	end
	local root = ReactRoblox.createRoot(screen)
	root:render(e("CanvasGroup", {
		Name = "LoadingScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		GroupTransparency = fade,
		ZIndex = 1,
	}, {
		Backdrop = e("Frame", {
			Name = "Backdrop",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Config.Colors.Text,
			BorderSizePixel = 0,
			ZIndex = 0,
		}, {
			Gradient = e("UIGradient", {
				Rotation = 125,
				Color = ColorSequence.new(Config.Colors.Top, Config.Colors.Bottom),
			}),
		}),
		Icon = e("ImageLabel", {
			Name = "GameIcon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = layout:map(function(value)
				return UDim2.new(0.5, 0, 0, value.iconY)
			end),
			Size = layout:map(function(value)
				return UDim2.fromOffset(value.iconSize, value.iconSize)
			end),
			BackgroundColor3 = Config.Colors.Placeholder,
			BackgroundTransparency = if Config.Icon == "" then 0.7 else 1,
			BorderSizePixel = 0,
			Image = Config.Icon,
			ScaleType = Enum.ScaleType.Fit,
			Rotation = rotation,
			ZIndex = 2,
		}, {
			Aspect = e("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }),
			Corner = e("UICorner", { CornerRadius = UDim.new(0.015, 0) }),
		}),
		Track = e("Frame", {
			Name = "LoadingTrack",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = layout:map(function(value)
				return UDim2.new(0.5, 0, 0, value.track)
			end),
			Size = UDim2.fromScale(0.4, 0.025),
			BackgroundColor3 = Config.Colors.Track,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			Stroke = e("UIStroke", {
				Color = Config.Colors.Ink,
				Thickness = viewport:map(function(v: Vector2)
					return math.clamp(v.Y / 320, 2, 4)
				end),
			}),
			Fill = e("Frame", {
				Name = "LoadingFill",
				Size = progress:map(function(value: number)
					return UDim2.fromScale(math.clamp(value, 0, 1), 1)
				end),
				Visible = progress:map(function(value: number)
					return value > 0
				end),
				BackgroundColor3 = Config.Colors.Fill,
				BorderSizePixel = 0,
			}, { Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }) }),
		}),
		Loading = label("LoadingLabel", "Loading..", "loading", 0.025),
		Count = label("AssetCount", count, "count", 0.017),
		Hint = label("SkipHint", "Click anywhere to skip!", "hint", 0.017),
		-- The entire screen is one fixed hit target. The hint is decoration.
		Skip = e("TextButton", {
			Name = "SkipAnywhere",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Modal = true,
			ZIndex = 5,
			[React.Event.Activated] = skip,
		}),
	}))
	return {
		update = function(loaded: number, total: number, failed: number)
			if alive then
				setProgress(if total > 0 then loaded / total else 0)
				setCount(
					string.format(
						"%d/%d assets loaded%s",
						loaded,
						total,
						if failed > 0 then string.format(" · %d failed", failed) else ""
					)
				)
			end
		end,
		finish = function()
			if alive then
				motion:tween(1, { time = Config.FadeTime, style = "sineOut" })
			end
		end,
		destroy = function()
			if not alive then
				return
			end
			alive = false
			step:Disconnect()
			disconnectFade()
			motion:destroy()
			root:unmount()
		end,
	}
end

return View
