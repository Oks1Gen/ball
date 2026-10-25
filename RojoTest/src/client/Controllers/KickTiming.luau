--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Actions = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Shared = game.ReplicatedStorage.Shared
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Ripple = require(game.ReplicatedStorage.Packages.Ripple)
local Timing = require(Shared.Core.KickTiming)
local Style = require(script.Parent.Parent.UiStyle)
local Insets = require(script.Parent.Parent.Modules.GuiInsets)
local U = require(script.Parent.Parent.CollectorUI.Components)
local e = React.createElement
local KickTiming = {}

function KickTiming.mount(context: any)
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "KickTiming"
	Insets.prepare(gui)
	gui.DisplayOrder = 45
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	local probe = Instance.new("Frame")
	probe.Name = "TimingArea"
	probe.Size = UDim2.fromScale(1, 1)
	probe.BackgroundTransparency = 1
	probe.Parent = gui
	local root = ReactRoblox.createRoot(probe)
	local height, setHeight = React.createBinding(0)
	local power, setPower = React.createBinding(0.5)
	local flash, setFlash = React.createBinding(0)
	local progress, setProgress = React.createBinding(0)
	local motion = Ripple.createMotion(0, { start = true })
	local disconnectMotion = motion:onChange(setProgress)
	local pending: any = nil
	local waiting = false
	local submitted = false
	local shown = false
	local alive = true
	local revision = 0
	local startedRequest = 0
	local resultAt = -math.huge
	local resultQuality = 0
	local resultPower = 1
	local resultVisible = false
	local measured = Vector2.zero

	local function effects(): boolean
		local snapshot = context.snapshot()
		return not snapshot or snapshot.data.settings.effects ~= false
	end
	local function color(h: number): Color3
		return if h >= 0.5
			then Style.Gold:Lerp(Style.Colors.Green, (h - 0.5) * 2)
			else Style.Colors.Red:Lerp(Style.Gold, h * 2)
	end
	local function render()
		local area = Insets.area(workspace.CurrentCamera.ViewportSize, probe)
		local factor = math.clamp(area.size.Y / 440, 0.6, 1.1)
		local hint = if resultVisible
			then (if resultPower >= Timing.multiplier(Timing.PerfectHeight)
				then "PERFECT!"
				elseif resultPower > 1 then "GREAT KICK!"
				else "KICK!")
			elseif waiting then "GET READY"
			elseif Input.PreferredInput == Enum.PreferredInput.Touch then "TAP TO KICK"
			elseif Input.PreferredInput == Enum.PreferredInput.Gamepad then "A / X TO KICK"
			else "CLICK / SPACE"
		root:render(e(React.Fragment, nil, {
			Flash = e("Frame", {
				Name = "TimingFlash",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Style.Colors.Green,
				BackgroundTransparency = flash:map(function(value: number)
					return 1 - value * 0.12
				end),
				BorderSizePixel = 0,
				ZIndex = 1,
			}),
			Panel = e("CanvasGroup", {
				Name = "PowerMeter",
				Visible = shown,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(area.offset.X + area.size.X * 0.64, area.offset.Y + area.size.Y * 0.40),
				-- Padding keeps the ink border and moving pointer inside the compositor.
				Size = UDim2.fromOffset(208, 362),
				GroupTransparency = progress:map(function(value: number)
					return 1 - math.clamp(value, 0, 1)
				end),
				BackgroundTransparency = 1,
				ZIndex = 3,
			}, {
				Scale = e("UIScale", {
					Scale = progress:map(function(value: number)
						return factor * (0.78 + value * 0.22)
					end),
				}),
				Content = e("Frame", {
					Name = "MeterContent",
					Position = UDim2.fromOffset(16, 16),
					Size = UDim2.fromOffset(176, 330),
					BackgroundTransparency = 1,
					ZIndex = 3,
				}, {
					Title = e(U.Label, {
						Text = "POWER",
						Position = UDim2.fromOffset(8, 1),
						Size = UDim2.fromOffset(160, 28),
						TextSize = 18,
						Color = Style.Muted,
						ZIndex = 5,
					}),
					Value = e(U.Label, {
						Name = "Multiplier",
						Text = power:map(function(value)
							return string.format("×%.2f", value)
						end),
						Position = UDim2.fromOffset(0, 24),
						Size = UDim2.fromOffset(176, 54),
						TextSize = 46,
						Color = height:map(color),
						ZIndex = 5,
					}),
					Bar = e("Frame", {
						Name = "GradientBar",
						Position = UDim2.fromOffset(79, 91),
						Size = UDim2.fromOffset(30, 192),
						BackgroundColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						ZIndex = 5,
					}, {
						Corner = U.corner(10),
						Stroke = e("UIStroke", { Color = Style.Ink, Thickness = 4 }),
						Rim = e("Frame", {
							Position = UDim2.fromOffset(-2, -2),
							Size = UDim2.new(1, 4, 1, 4),
							BackgroundTransparency = 1,
							ZIndex = 6,
						}, {
							Corner = U.corner(11),
							Stroke = e("UIStroke", { Color = Style.Text, Thickness = 1.5, Transparency = 0.15 }),
						}),
						Shine = e("Frame", {
							Position = UDim2.fromOffset(3, 4),
							Size = UDim2.new(0, 8, 1, -8),
							BackgroundColor3 = Style.Text,
							BackgroundTransparency = 0.65,
							BorderSizePixel = 0,
							ZIndex = 6,
						}, {
							Corner = U.corner(5),
							Fade = e("UIGradient", {
								Transparency = NumberSequence.new(0, 1),
							}),
						}),
						UpperTick = e("Frame", {
							Position = UDim2.fromScale(0.72, 0.25),
							Size = UDim2.new(0.28, 6, 0, 2),
							BackgroundColor3 = Style.Text,
							BackgroundTransparency = 0.25,
							BorderSizePixel = 0,
							ZIndex = 7,
						}),
						NeutralTick = e("Frame", {
							Position = UDim2.fromScale(0, 0.5),
							Size = UDim2.new(1, 0, 0, 2),
							BackgroundColor3 = Style.Text,
							BackgroundTransparency = 0.3,
							BorderSizePixel = 0,
							ZIndex = 7,
						}),
						LowerTick = e("Frame", {
							Position = UDim2.fromScale(0.72, 0.75),
							Size = UDim2.new(0.28, 6, 0, 2),
							BackgroundColor3 = Style.Text,
							BackgroundTransparency = 0.25,
							BorderSizePixel = 0,
							ZIndex = 7,
						}),
						Gradient = e("UIGradient", {
							Rotation = 90,
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Style.Colors.Green),
								ColorSequenceKeypoint.new(0.5, Style.Gold),
								ColorSequenceKeypoint.new(1, Style.Colors.Red),
							}),
						}),
						Perfect = e("Frame", {
							Name = "PerfectZone",
							Size = UDim2.fromScale(1, 1 - Timing.PerfectHeight),
							BackgroundColor3 = Color3.new(1, 1, 1),
							BackgroundTransparency = 0.55,
							BorderSizePixel = 0,
							ZIndex = 6,
						}, { Corner = U.corner(5) }),
						Arrow = e("Frame", {
							Name = "Arrow",
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = height:map(function(value)
								return UDim2.fromScale(0.5, 1 - value)
							end),
							Size = UDim2.new(1, 24, 0, 4),
							BackgroundColor3 = Style.Text,
							BorderSizePixel = 0,
							ZIndex = 8,
						}, {
							Stroke = e("UIStroke", { Color = Style.Ink, Thickness = 2 }),
							Tip = e("Frame", {
								AnchorPoint = Vector2.new(0.5, 0.5),
								Position = UDim2.new(0, -6, 0.5, 0),
								Size = UDim2.fromOffset(13, 13),
								Rotation = 45,
								BackgroundColor3 = height:map(color),
								BorderSizePixel = 0,
								ZIndex = 9,
							}, { Stroke = e("UIStroke", { Color = Style.Ink, Thickness = 2 }) }),
						}),
					}),
					Top = e(U.Label, {
						Text = "×2",
						Position = UDim2.fromOffset(12, 81),
						Size = UDim2.fromOffset(54, 26),
						TextSize = 22,
						Color = Style.Colors.Green,
						ZIndex = 5,
					}),
					Middle = e(U.Label, {
						Text = "×1",
						Position = UDim2.fromOffset(12, 174),
						Size = UDim2.fromOffset(54, 26),
						TextSize = 22,
						Color = Style.Gold,
						ZIndex = 5,
					}),
					Bottom = e(U.Label, {
						Text = "×0.5",
						Position = UDim2.fromOffset(8, 270),
						Size = UDim2.fromOffset(60, 26),
						TextSize = 20,
						Color = Style.Colors.Red,
						ZIndex = 5,
					}),
					Hint = e(U.Label, {
						Name = "TimingHint",
						Text = hint,
						Position = UDim2.fromOffset(5, 306),
						Size = UDim2.fromOffset(166, 25),
						TextSize = 18,
						ZIndex = 5,
					}),
				}),
			}),
		}))
	end
	local function show(value: boolean)
		revision += 1
		local ticket = revision
		if value then
			shown = true
			render()
			if effects() then
				motion:spring(1, { frequency = 6.5, dampingRatio = 0.7 })
			else
				motion:setPosition(1)
			end
		else
			if effects() then
				motion:tween(0, { duration = 0.24, easing = "quadIn" })
			end
			task.delay(if effects() then 0.24 else 0, function()
				if alive and revision == ticket then
					shown = false
					render()
				end
			end)
		end
	end
	local function cancel()
		if pending or waiting or submitted then
			context.send("KickCancel")
		end
		pending, waiting, submitted = nil, false, false
		resultVisible = false
		resultQuality = 0
		setFlash(0)
		show(false)
	end
	local function release()
		if not pending or submitted or Input:GetFocusedTextBox() or GuiService.MenuIsOpen then
			return
		end
		local now = workspace:GetServerTimeNow()
		if now < pending.startedAt then
			return
		end
		local h = Timing.height(now - pending.startedAt)
		resultPower = Timing.multiplier(h)
		setHeight(h)
		setPower(resultPower)
		resultQuality = Timing.quality(resultPower)
		resultAt = os.clock()
		resultVisible = true
		submitted = true
		render()
		context.send("KickRelease", pending.token, now)
	end
	local function request()
		if pending then
			release()
			return
		end
		if waiting or submitted or not context.canStart() then
			return
		end
		waiting = true
		resultVisible = false
		startedRequest = os.clock()
		setHeight(0)
		setPower(0.5)
		show(true)
		context.send("Throw")
	end
	Actions:BindActionAtPriority("KickTimingConfirm", function(_, state)
		if not (pending or waiting or submitted) then
			return Enum.ContextActionResult.Pass
		end
		if state == Enum.UserInputState.Begin then
			release()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value + 10, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
	local began = Input.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if input.KeyCode == Enum.KeyCode.Escape and (pending or waiting) then
			cancel()
			return
		end
		if processed then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			release()
		end
	end)
	local unfocused = Input.WindowFocusReleased:Connect(cancel)
	local menu = GuiService.MenuOpened:Connect(cancel)
	local frame = RunService.RenderStepped:Connect(function()
		if (pending or waiting or submitted) and not context.canContinue() then
			cancel()
		end
		if pending and not submitted then
			local h = Timing.height(workspace:GetServerTimeNow() - pending.startedAt)
			setHeight(h)
			setPower(Timing.multiplier(h))
		end
		if waiting and os.clock() - startedRequest > 5 then
			cancel()
		end
		if submitted and os.clock() - resultAt > 5 then
			cancel()
		end
		local age = os.clock() - resultAt
		setFlash(if effects() then resultQuality * math.max(0, 1 - age / 0.45) ^ 2 else 0)
		if probe.AbsoluteSize ~= measured then
			measured = probe.AbsoluteSize
			render()
		end
	end)
	render()
	return {
		request = request,
		cancel = cancel,
		active = function()
			return pending ~= nil or waiting or submitted
		end,
		ready = function(info: any)
			if not waiting or not context.canContinue() then
				context.send("KickCancel")
				return
			end
			waiting = false
			pending = info
			render()
		end,
		accepted = function(multiplier: number)
			pending, waiting, submitted = nil, false, false
			if shown then
				resultPower = multiplier
				resultVisible = true
				setPower(multiplier)
				render()
				task.delay(0.5, function()
					if alive and not pending and not waiting then
						show(false)
					end
				end)
			end
		end,
		destroy = function()
			alive = false
			Actions:UnbindAction("KickTimingConfirm")
			began:Disconnect()
			unfocused:Disconnect()
			menu:Disconnect()
			frame:Disconnect()
			disconnectMotion()
			motion:destroy()
			root:unmount()
			gui:Destroy()
		end,
	}
end

return KickTiming
