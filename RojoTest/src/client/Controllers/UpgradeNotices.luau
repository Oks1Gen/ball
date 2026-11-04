--!strict
local Shared = game.ReplicatedStorage.Shared
local Packages = game.ReplicatedStorage.Packages
local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)
local Ripple = require(Packages.Ripple)
local Config = require(Shared.GameConfig)
local Notices = require(Shared.Core.UpgradeNotices)
local DirectionGuide = require(Shared.DirectionGuide)
local WorldRefs = require(Shared.WorldRefs)
local U = require(script.Parent.Parent.CollectorUI.Components)
local BallArt = require(script.Parent.Parent.Modules.BallCardArt)
local Insets = require(script.Parent.Parent.Modules.GuiInsets)
local Style = require(script.Parent.Parent.UiStyle)
local e = React.createElement
local UpgradeNotices = {}
local WIDTH, HEIGHT = 480, 128
local SCALE = 0.75 -- Compact card; half size made the small text unreadable.

function UpgradeNotices.mount(context: any)
	local gui = Instance.new("ScreenGui")
	gui.Name = "UpgradeNotices"
	Insets.prepare(gui)
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.DisplayOrder = 75
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = context.parent
	local probe = Instance.new("Frame")
	probe.Name = "NoticeArea"
	probe.BackgroundTransparency = 1
	probe.Size = UDim2.fromScale(1, 1)
	probe.Parent = gui
	local root = ReactRoblox.createRoot(probe)
	local state = Notices.new()
	state.onAnnounce = function(kind: string, rank: number)
		context.send("NoticeSeen", kind, rank)
	end
	local slide, setSlide = React.createBinding(0)
	local timer, setTimer = React.createBinding(1)
	local motion = Ripple.createMotion(0, { start = true })
	local slideValue = 0
	local disconnect = motion:onChange(function(value: number)
		slideValue = value
		setSlide(value)
	end)
	local top, factor = 0, SCALE
	local displayed: any = nil
	local info: any = nil
	local guiding: number? = nil
	local guideRemaining = 0
	local lastKey = ""
	local alive = true
	local guide = DirectionGuide.new({
		name = "UpgradeTrainingGuide",
		automatic = false,
		enabled = false,
		target = function()
			local map = workspace:FindFirstChild("Map")
			local lanes = WorldRefs.training(map and map:FindFirstChild("World1"))
			local lane = guiding and lanes and lanes:FindFirstChild("TrainingLane" .. guiding)
			return lane and lane:FindFirstChild("TrainingStrip")
		end,
	})
	local function reduced(): boolean
		return info ~= nil and info.data.settings.effects == false
	end
	local function dismiss()
		state:dismiss()
	end
	local function activate()
		local notice = state.current
		if not notice or context.blocked() or not state.enabled then
			return
		end
		dismiss()
		if notice.kind == "Training" then
			guiding = notice.lane
			guideRemaining = 120
		else
			guiding = nil
			context.open(notice)
		end
	end
	local function render()
		if not alive then
			return
		end
		local area = Insets.area(workspace.CurrentCamera.ViewportSize, probe)
		factor = math.min(1, (area.size.X - 32) / WIDTH) * SCALE
		-- Directly under the top HUD cluster (Auto Kick), not in the screen middle.
		top = context.top() - probe.AbsolutePosition.Y + 6
		local notice = displayed
		local children = {}
		if notice then
			local icon = if notice.kind == "Training"
				then "Skill"
				elseif notice.kind == "Trail" then notice.itemId .. "Trail"
				else notice.kind
			local heading = if notice.kind == "Training"
				then "NEW TRAINING FIELD"
				elseif notice.kind == "Rebirth" then "REBIRTH READY"
				else "NEW " .. string.upper(notice.kind) .. " AVAILABLE"
			children.Card = e("Frame", {
				Name = "Banner",
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0),
				Size = UDim2.fromOffset(WIDTH, HEIGHT),
				Position = slide:map(function(value)
					return UDim2.fromOffset(
						area.offset.X + area.size.X / 2,
						-HEIGHT * factor - 14 + (top + HEIGHT * factor + 14) * value
					)
				end),
			}, {
				Scale = e("UIScale", { Scale = factor }),
				Plate = e(U.Surface, {
					-- Match the plain translucent window body in HudPanels.shell.
					Color = Color3.fromRGB(55, 63, 79),
					Transparency = 0.3,
					Quiet = true,
					Studs = false,
					NoShadow = true,
					Outline = Style.WindowStroke,
					Radius = Style.PanelRadius,
					Children = {
						Art = if notice.kind == "Ball"
							then e("ImageLabel", {
								Name = "BallArt",
								BackgroundTransparency = 1,
								Position = UDim2.fromOffset(16, 16),
								Size = UDim2.fromOffset(84, 84),
								Image = BallArt.image(notice.itemId),
								ScaleType = Enum.ScaleType.Fit,
								ZIndex = 16,
							})
							else e(U.Icon, {
								Kind = icon,
								Position = UDim2.fromOffset(16, 16),
								Size = UDim2.fromOffset(84, 84),
								ZIndex = 16,
							}),
						Heading = e(U.Label, {
							Name = "Heading",
							Text = heading,
							Color = Style.Gold,
							Position = UDim2.fromOffset(116, 13),
							Size = UDim2.fromOffset(310, 18),
							TextSize = 14,
							Align = Enum.TextXAlignment.Left,
						}),
						Title = e(U.Label, {
							Name = "Title",
							Text = notice.title,
							Position = UDim2.fromOffset(116, 35),
							Size = UDim2.fromOffset(310, 27),
							TextSize = 23,
							Scaled = true,
							Align = Enum.TextXAlignment.Left,
						}),
						Detail = e(U.Label, {
							Name = "Detail",
							Text = notice.detail,
							Position = UDim2.fromOffset(116, 65),
							Size = UDim2.fromOffset(348, 18),
							TextSize = 13,
							Align = Enum.TextXAlignment.Left,
						}),
						Action = e(U.Button, {
							Name = "Action",
							Text = notice.action,
							TextSize = 16,
							Position = UDim2.fromOffset(304, 88),
							Size = UDim2.fromOffset(160, 28),
							Color = Style.Colors.Green,
							NoShadow = true,
							Radius = 6,
							OnActivated = activate,
						}),
						Close = e(U.CloseButton, {
							Name = "Dismiss",
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(1, 0),
							Size = UDim2.fromOffset(32, 32),
							OnActivated = dismiss,
						}),
						Track = e("Frame", {
							Name = "Countdown",
							Position = UDim2.fromOffset(16, 122),
							Size = UDim2.fromOffset(448, 2),
							BackgroundColor3 = Style.Ink,
							BorderSizePixel = 0,
							ZIndex = 15,
						}, {
							Fill = e("Frame", {
								Size = timer:map(function(value)
									return UDim2.fromScale(value, 1)
								end),
								BackgroundColor3 = Style.Gold,
								BorderSizePixel = 0,
								ZIndex = 16,
							}),
						}),
					},
				}),
			})
		end
		if guiding and not state.current then
			children.Stop = e(U.Button, {
				Name = "StopGuide",
				Text = "FOLLOW THE ARROWS  ·  STOP",
				TextSize = 15,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromOffset(area.offset.X + area.size.X / 2, top),
				Size = UDim2.fromOffset(300, 32),
				Color = Style.Panel,
				OnActivated = function()
					guiding = nil
				end,
			})
		end
		root:render(e(U.MotionContext.Provider, { value = reduced() }, children))
	end
	local resize = probe:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
	return {
		update = function(snapshot: any)
			info = snapshot
			gui:SetAttribute("ReducedMotion", reduced())
			state:update(snapshot, Config)
			if not state.enabled or (guiding and snapshot.training == guiding) then
				guiding = nil
			end
		end,
		frame = function(dt: number)
			local blocked = context.blocked()
			local current = state:step(dt, blocked)
			gui.Enabled = state.enabled == true and not blocked
			if guiding then
				guideRemaining -= dt
				if guideRemaining <= 0 then
					guiding = nil
				end
			end
			guide:setEnabled(guiding ~= nil and not blocked and state.enabled == true)
			guide:update(os.clock(), reduced())
			setTimer(state.remaining / Notices.Duration)
			local key = (if current then current.id else "") .. ":" .. tostring(guiding) .. ":" .. tostring(reduced())
			local moved = math.abs(context.top() - probe.AbsolutePosition.Y + 6 - top) > 0.5
			if moved and key == lastKey then
				render()
			end
			if key ~= lastKey then
				lastKey = key
				if current then
					displayed = current
				end
				gui:SetAttribute("NoticeId", if current then current.id else nil)
				gui:SetAttribute("GuidingLane", guiding)
				render()
				local goal = if current then 1 else 0
				if reduced() then
					motion:setPosition(goal)
				end
				motion:tween(goal, { duration = if reduced() then 0 else 0.25, easing = "quadOut" })
			end
		end,
		-- Absolute Y below whatever this module shows, so toasts stack under it.
		bottom = function(): number
			local base = probe.AbsolutePosition.Y + top
			if not gui.Enabled then
				return base - 6
			end
			local extra = if guiding and not state.current then 32 + 6 else 0
			return base + math.max(extra, (HEIGHT * factor + 6) * math.clamp(slideValue, 0, 1)) - 6
		end,
		destroy = function()
			alive = false
			resize:Disconnect()
			disconnect()
			motion:destroy()
			guide:destroy()
			root:unmount()
			gui:Destroy()
		end,
	}
end

return UpgradeNotices
