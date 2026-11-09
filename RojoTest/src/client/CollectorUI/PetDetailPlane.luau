--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Ripple = require(game.ReplicatedStorage.Packages.Ripple)
local Motion = require(game.ReplicatedStorage.Shared.UiMotion)
local e = React.createElement

-- A single client-only UI plane. The invisible support has no rendered edge:
-- all artwork, text and controls are on the same rounded SurfaceGui face.
return function(p: any): any
	local color = p.Color or Color3.fromRGB(43, 176, 255)
	local border = p.BorderColor or color:Lerp(Color3.new(1, 1, 1), 0.4)
	local glow = p.GlowColor or color
	local anchor: any = React.useRef(nil)
	local gui: any = React.useRef(nil)
	local canvas: any = React.useRef(nil)
	local latest: any = React.useRef(p)
	latest.current = p
	local plane, setPlane = React.useState(nil :: BasePart?)
	React.useEffect(function()
		local part = Instance.new("Part")
		part.Name = "PetDetailPlane"
		part:SetAttribute("PartRole", "Client-only camera-relative pet UI support")
		part.Anchored = true
		part.Transparency = 1
		part.CastShadow = false
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = true
		part.Parent = workspace.CurrentCamera
		setPlane(part)
		local tilt = Ripple.createMotion({ x = 0, y = 0 })
		local previous = Vector2.zero
		local wasReduced = false
		local elapsed = 0
		local renderName = "PetDetailPlane_" .. HttpService:GenerateGUID(false)
		RunService:BindToRenderStep(renderName, Enum.RenderPriority.Camera.Value + 1, function(dt)
			local camera = workspace.CurrentCamera
			local slot = anchor.current
			local surface = gui.current
			if not camera or not slot or not surface or not canvas.current then
				return
			end
			if part.Parent ~= camera then
				part.Parent = camera
			end
			local state = latest.current
			-- AbsolutePosition is inset-relative even in the granted ScreenGui
			-- area; the camera projection and mouse location use viewport pixels.
			local size = slot.AbsoluteSize
			local position = slot.AbsolutePosition + GuiService:GetGuiInset()
			local group = slot:FindFirstAncestorWhichIsA("CanvasGroup")
			local opacity = if group then group.GroupTransparency else 0
			surface.Enabled = size.X > 1 and size.Y > 1 and opacity < 0.999
			surface.Active = state.Visible and state.Interactive ~= false
			part.CanQuery = surface.Active
			canvas.current.Interactable = surface.Active
			canvas.current.GroupTransparency = opacity
			if surface:GetAttribute("ReducedMotion") ~= state.Reduced then
				surface:SetAttribute("ReducedMotion", state.Reduced)
				Motion.resetButtons(surface)
			end
			if not surface.Enabled then
				return
			end
			local target = Vector2.zero
			if not state.Reduced and state.Visible and Input.MouseEnabled then
				local point = Input:GetMouseLocation()
				local normalized = (point - position) / size
				if normalized.X >= 0 and normalized.X <= 1 and normalized.Y >= 0 and normalized.Y <= 1 then
					target = (normalized - Vector2.new(0.5, 0.5)) * 2
				end
			end
			if state.Reduced and not wasReduced then
				tilt:setPosition({ x = 0, y = 0 })
				tilt:setVelocity({ x = 0, y = 0 })
				tilt:tween({ x = 0, y = 0 }, { duration = 0 })
			end
			wasReduced = state.Reduced
			if (target - previous).Magnitude > 0.01 then
				previous = target
				tilt:spring({ x = target.X, y = target.Y }, { frequency = 4, dampingRatio = 0.9 })
			end
			local value = tilt:step(math.min(dt, 0.1))
			if not state.Reduced then
				elapsed += dt
			end
			local x = if state.Reduced then 0 else value.x
			local y = if state.Reduced then 0 else value.y
			local idle = if state.Reduced then 0 else math.sin(elapsed * 0.7) * 0.5
			local viewport = camera.ViewportSize
			local distance = 8
			local unit = 2 * distance * math.tan(math.rad(camera.FieldOfView) / 2) / math.max(1, viewport.Y)
			local center = position + size / 2
			part.Size = Vector3.new(math.max(0.001, size.X * unit), math.max(0.001, size.Y * unit), 0.01)
			part.CFrame = camera.CFrame
				* CFrame.new((center.X - viewport.X / 2) * unit, (viewport.Y / 2 - center.Y) * unit, -distance)
				-- Measured against the four corners of 01D at the desktop viewport.
				-- The off-centre camera projection is part of the composition.
				* CFrame.Angles(math.rad(4.6 - y * 2), math.rad(-26.4 + x * 4 + idle), math.rad(-0.8 + x * 0.5))
		end)
		return function()
			RunService:UnbindFromRenderStep(renderName)
			tilt:destroy()
			part:Destroy()
		end
	end, {})
	local portal = plane
			and ReactRoblox.createPortal({
				Surface = e("SurfaceGui", {
					ref = gui,
					Name = "PetDetailSurface",
					Adornee = plane,
					Face = Enum.NormalId.Back,
					SizingMode = Enum.SurfaceGuiSizingMode.FixedSize,
					CanvasSize = Vector2.new((p.Width + 24) * 2, (p.Height + 24) * 2),
					AlwaysOnTop = true,
					LightInfluence = 0,
					MaxDistance = 20,
					ToolPunchThroughDistance = 20,
					ClipsDescendants = false,
					ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
					Active = p.Visible,
				}, {
					Canvas = e("CanvasGroup", {
						ref = canvas,
						Name = "PetDetailCanvas",
						Size = UDim2.fromOffset(p.Width + 24, p.Height + 24),
						BackgroundTransparency = 1,
					}, {
						Resolution = e("UIScale", { Scale = 2 }),
						Glow = e("Frame", {
							Position = UDim2.fromOffset(12, 12),
							Size = UDim2.new(1, -24, 1, -24),
							BackgroundTransparency = 1,
							ZIndex = 1,
						}, {
							Corner = e("UICorner", { CornerRadius = UDim.new(0, 24) }),
							Halo = e("UIStroke", { Color = glow, Thickness = 10, Transparency = 0.88 }),
						}),
						Card = e("Frame", {
							Name = "PetDetails",
							Position = UDim2.fromOffset(12, 12),
							Size = UDim2.new(1, -24, 1, -24),
							BackgroundColor3 = Color3.new(1, 1, 1),
							BorderSizePixel = 0,
							ZIndex = 2,
						}, {
							Corner = e("UICorner", { CornerRadius = UDim.new(0, 24) }),
							Rim = e("UIStroke", { Color = border, Thickness = 2.5 }),
							Shade = e("UIGradient", {
								Rotation = 90,
								Color = ColorSequence.new(
									color:Lerp(Color3.new(0, 0, 0), 0.2),
									color:Lerp(Color3.new(0, 0, 0), 0.6)
								),
							}),
							Content = e("Frame", {
								Name = "Content",
								Size = UDim2.fromScale(1, 1),
								BackgroundTransparency = 1,
								ZIndex = 5,
							}, p.Children),
						}),
					}),
				}),
			}, Players.LocalPlayer.PlayerGui)
		or nil
	return e(React.Fragment, nil, {
		Anchor = e("Frame", {
			ref = anchor,
			Name = "PetDetailAnchor",
			Position = UDim2.fromOffset(p.X, p.Y),
			Size = UDim2.fromOffset(p.AnchorWidth or p.Width, p.AnchorHeight or p.Height),
			BackgroundTransparency = 1,
			Active = false,
		}),
		Portal = portal,
	})
end
