--!strict
-- Screen-space targets use an independent shared offer clock, not goal projection.
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Shared = game.ReplicatedStorage.Shared
local Area = require(Shared.TrainingArea)
local Rules = require(Shared.Core.TrainingBoost)
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Insets = require(script.Parent.Parent.Modules.GuiInsets)
local Assets = require(script.Parent.Parent.UIAssets)
local Feedback = require(script.Parent.TrainingBoostFeedback)
local Style = require(script.Parent.Parent.UiStyle)
local Boost = {}
local e = React.createElement

function Boost.mount(context: any)
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "TrainingBoost"
	Insets.prepare(gui)
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 42
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	local safe = Instance.new("Frame")
	safe.Name = "SafeArea"
	safe.BackgroundTransparency = 1
	safe.Size = UDim2.fromScale(1, 1)
	safe.Parent = gui
	local layer = Instance.new("Frame")
	layer.Name = "BubbleLayer"
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundTransparency = 1
	layer.Parent = safe
	local root = ReactRoblox.createRoot(layer)
	local shown, setShown = React.createBinding(false)
	local position, setPosition = React.createBinding(UDim2.new())
	local fade, setFade = React.createBinding(1)
	local remaining, setRemaining = React.createBinding(1)
	local caption, setCaption = React.createBinding("×2")
	local color, setColor = React.createBinding(Style.Colors.Eggs)
	local diameter = if Input.TouchEnabled then 76 else 72
	local alive = true
	local current: any = nil
	local acceptedCycle: number? = nil
	local cacheSize = Vector2.zero
	local lastPosition = Vector2.zero
	local visible = false
	local function effects(): boolean
		local s = context.snapshot()
		return (not s or s.data.settings.effects ~= false) and not context.blocked()
	end
	local feedback = Feedback.create({
		parent = safe,
		skillLabel = context.skillLabel,
		playSound = context.playSound,
		effects = effects,
		blocked = context.blocked,
	})
	local function isVisible(node: Instance): boolean
		local parent: Instance? = node
		while parent and parent ~= player.PlayerGui do
			if parent:IsA("GuiObject") and not parent.Visible then
				return false
			end
			if parent:IsA("ScreenGui") and not parent.Enabled then
				return false
			end
			parent = parent.Parent
		end
		return parent == player.PlayerGui
	end
	local function choose(seed: number, offer: number): Vector2?
		local size = safe.AbsoluteSize
		local radius = diameter + 16
		local travel = if size.Y < 500 then 25 else 42
		local excluded = {}
		for _, screen in player.PlayerGui:GetChildren() do
			if screen.Name == "SkippingHUD" or screen.Name == "CollectorUI" or screen.Name == "BallTopbar" then
				for _, node in screen:GetDescendants() do
					if
						node:IsA("GuiObject")
						and (node:IsA("GuiButton") or node.Name == "LevelBar" or node.Name == "Skill" or node.Name == "WinsCount" or node.Name == "LevelUpText")
						and isVisible(node)
					then
						local p = node.AbsolutePosition - safe.AbsolutePosition
						table.insert(excluded, { x = p.X, y = p.Y, w = node.AbsoluteSize.X, h = node.AbsoluteSize.Y })
					end
				end
			end
		end
		local minX, maxX = radius + 18, size.X - radius - 18
		local minY, maxY = radius + 18 + travel, size.Y - radius - 24 - travel
		local function fits(x: number, y: number): boolean
			if x < minX or x > maxX or y < minY or y > maxY then
				return false
			end
			for _, rect in excluded do
				local dx = math.max(rect.x - x, 0, x - rect.x - rect.w)
				local dy = math.max(rect.y - y - travel, 0, y - travel - rect.y - rect.h)
				if dx * dx + dy * dy < (diameter + 6) ^ 2 then
					return false
				end
			end
			return true
		end
		for attempt = 1, 180 do
			local x = minX + Rules.sample(seed, offer, attempt * 2) * math.max(0, maxX - minX)
			local y = minY + Rules.sample(seed, offer, attempt * 2 + 1) * math.max(0, maxY - minY)
			if fits(x, y) then
				return Vector2.new(math.round(x), math.round(y))
			end
		end
		-- Narrow landscape gaps can be missed by random sampling. Test HUD edges too.
		for _, rect in excluded do
			for _, x in { rect.x - radius - 1, rect.x + rect.w + radius + 1 } do
				for step = 0, 12 do
					local y = minY + (maxY - minY) * step / 12
					if fits(x, y) then
						return Vector2.new(math.round(x), math.round(y))
					end
				end
			end
		end
		return nil
	end
	local function hide()
		visible = false
		setShown(false)
	end
	local function press()
		if not alive or not visible or not current or current.submitted or context.blocked() then
			return
		end
		if not Rules.inWindow(current.started, current.offer, workspace:GetServerTimeNow(), 0) then
			return
		end
		current.submitted = true
		hide()
		context.send("TrainingBoost", current.seed, current.offer)
	end
	local function round()
		return e("UICorner", { CornerRadius = UDim.new(1, 0) })
	end
	root:render(e("CanvasGroup", {
		Name = "BoostBubble",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = UDim2.fromOffset((diameter + 16) * 2, (diameter + 20) * 2),
		BackgroundTransparency = 1,
		GroupTransparency = fade,
		Visible = shown,
	}, {
		Target = e("TextButton", {
			Name = "BoostTarget",
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(diameter + 16, diameter + 16),
			Selectable = true,
			[React.Event.Activated] = press,
		}, {
			Scale = e("UIScale", { Scale = 2 }),
			Shadow = e("Frame", {
				Position = UDim2.fromOffset(8, 11),
				Size = UDim2.fromOffset(diameter, diameter),
				BackgroundColor3 = Style.Ink,
				BorderSizePixel = 0,
				ZIndex = 1,
			}, { Round = round() }),
			Core = e("Frame", {
				Position = UDim2.fromOffset(8, 7),
				Size = UDim2.fromOffset(diameter, diameter),
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, {
				Round = round(),
				Border = e("UIStroke", { Color = Style.Ink, Thickness = 2.5 }),
				Shade = e("UIGradient", {
					Rotation = 90,
					Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(140, 115, 160)),
				}),
				Shine = e("Frame", {
					Position = UDim2.fromOffset(14, 9),
					Size = UDim2.fromOffset(22, 5),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 0.2,
					BorderSizePixel = 0,
					ZIndex = 3,
				}, { Round = round() }),
				Lightning = e("ImageLabel", {
					Image = Assets.Images.Skill,
					Position = UDim2.new(0.5, -11, 0, 9),
					Size = UDim2.fromOffset(22, 22),
					BackgroundTransparency = 1,
					ZIndex = 4,
				}),
				Label = e("TextLabel", {
					Name = "Multiplier",
					Text = caption,
					Position = UDim2.fromOffset(0, 28),
					Size = UDim2.new(1, 0, 0, 34),
					Font = Enum.Font.GothamBlack,
					TextSize = 26,
					TextColor3 = Style.Text,
					TextStrokeColor3 = Style.Ink,
					TextStrokeTransparency = 0,
					BackgroundTransparency = 1,
					ZIndex = 4,
				}),
			}),
			Timer = e("Frame", {
				Position = UDim2.fromOffset(13, diameter + 13),
				Size = remaining:map(function(v: number)
					return UDim2.fromOffset(math.max(1, math.round((diameter - 10) * v)), 3)
				end),
				BackgroundColor3 = Color3.fromRGB(238, 195, 255),
				BorderSizePixel = 0,
				ZIndex = 5,
			}, { Round = round() }),
		}),
	}))
	return {
		confirmed = function(info: any)
			if
				not alive
				or not current
				or info.seed ~= current.seed
				or info.started ~= current.started
				or info.offer ~= current.offer
				or not current.submitted
			then
				return
			end
			acceptedCycle = info.cycle
			feedback.play(lastPosition, info.multiplier)
		end,
		frame = function(state: any, elapsed: number, _ballPosition: Vector3): boolean
			if not alive then
				return false
			end
			if current and (current.seed ~= state.seed or current.started ~= state.started) then
				current = nil
				acceptedCycle = nil
				feedback.clear()
			end
			local index = Rules.index(elapsed)
			local character = player.Character
			local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
			local strip = state.lane:FindFirstChild("TrainingStrip")
			if
				index < 0
				or not characterRoot
				or not characterRoot:IsA("BasePart")
				or not strip
				or not strip:IsA("BasePart")
				or not Area.contains(strip, characterRoot.Position)
				or context.blocked()
				or GuiService.MenuIsOpen
			then
				hide()
				feedback.clear()
				return false
			end
			if not current or current.offer ~= index then
				current = {
					seed = state.seed,
					started = state.started,
					offer = index,
					submitted = false,
					goal = choose(state.seed, index),
				}
				local multiplier = Rules.multiplier(state.seed, index)
				setCaption("×" .. tostring(multiplier))
				setColor(if multiplier >= 4 then Color3.fromRGB(255, 212, 67) else Style.Colors.Eggs)
				cacheSize = safe.AbsoluteSize
			end
			if cacheSize ~= safe.AbsoluteSize then
				current.goal = choose(state.seed, index)
				cacheSize = safe.AbsoluteSize
			end
			local age = Rules.age(state.started, index, workspace:GetServerTimeNow())
			if age < 0 or age > Rules.Lifetime or current.submitted or not current.goal then
				hide()
				return acceptedCycle == state.cycle
			end
			local travel = if safe.AbsoluteSize.Y < 500 then 25 else 42
			local direction = if Rules.sample(state.seed, index, 99) < 0.5 then -1 else 1
			local progress = math.clamp(age / Rules.TravelTime, 0, 1)
			local offset = if effects() then direction * travel * (1 - progress) ^ 3 else 0
			lastPosition = current.goal + Vector2.new(0, math.round(offset))
			setPosition(UDim2.fromOffset(lastPosition.X, lastPosition.Y))
			setFade(if effects() then math.clamp(1 - age / 0.18, 0, 1) else 0)
			setRemaining(math.clamp((Rules.Lifetime - age) / Rules.Lifetime, 0, 1))
			visible = true
			setShown(true)
			return acceptedCycle == state.cycle
		end,
		clear = function()
			current = nil
			acceptedCycle = nil
			hide()
			feedback.clear()
		end,
		destroy = function()
			alive = false
			feedback.destroy()
			root:unmount()
			gui:Destroy()
		end,
	}
end
return Boost
