--!strict
-- Общая реализация для React и обычных Instances. Раскладка не анимируется:
-- кнопки меняют только свой визуальный слой, HUD — отдельные контейнеры.
local Ripple = require(game.ReplicatedStorage.Packages.Ripple)
local Input = game:GetService("UserInputService")
local Config = require(script.Parent.UiMotionConfig)
local Motion = {}
local resets: { [GuiButton]: () -> () } = {}

function Motion.reduced(node: Instance): boolean
	local gui = node:FindFirstAncestorOfClass("ScreenGui")
	return gui ~= nil and gui:GetAttribute("ReducedMotion") == true
end

function Motion.enabled(button: GuiButton): boolean
	if not button.Active then
		return false
	end
	local node: Instance? = button
	while node do
		if node:IsA("GuiObject") and (not node.Visible or not node.Interactable) then
			return false
		end
		if node:IsA("ScreenGui") and not node.Enabled then
			return false
		end
		node = node.Parent
	end
	return true
end

function Motion.resetButtons(root: Instance)
	for button, reset in resets do
		if button == root or button:IsDescendantOf(root) then
			reset()
		end
	end
end

-- visual центрирован внутри неподвижной кнопки. Размер hitbox не меняется.
function Motion.button(button: GuiButton, visual: GuiObject, shadow: GuiObject?): () -> ()
	local settings = Config.Button
	local scale = Instance.new("UIScale")
	scale.Name = "ButtonMotion"
	scale.Parent = visual
	visual.AnchorPoint = Vector2.new(0.5, 0.5)
	visual.Position = UDim2.fromScale(0.5, 0.5)
	local spring = Ripple.createMotion(1, { start = true })
	local hover, focus = false, false
	local pressed: InputObject? = nil
	local connections: { RBXScriptConnection } = {}
	local destroyed = false
	local limits: { [UITextSizeConstraint]: { min: number, max: number, lastMin: number, lastMax: number } } = {}
	local function target(release: boolean?)
		local enabled = Motion.enabled(button)
		local value = if not enabled
			then 1
			elseif pressed then settings.PressScale
			elseif hover or focus then settings.HoverScale
			else 1
		if Motion.reduced(button) then
			spring:setPosition(1)
			spring:setVelocity(0)
			spring:spring(1)
		elseif release then
			spring:spring(value, { frequency = settings.ReleaseFrequency, dampingRatio = settings.ReleaseDamping })
		else
			spring:tween(
				value,
				{ duration = if pressed then settings.PressTime else settings.HoverTime, easing = "quadOut" }
			)
		end
	end
	local disconnect = spring:onChange(function(value)
		-- Layout reserves this exact maximum, including during spring reversals.
		value = math.min(value, settings.HoverScale)
		scale.Scale = value
		-- TextScaled uses physical pixel caps: follow the visual scale too,
		-- otherwise the plate grows while its caption stays at the old cap.
		for _, limit in visual:GetDescendants() do
			if limit:IsA("UITextSizeConstraint") then
				local saved = limits[limit]
				if not saved then
					saved = {
						min = limit.MinTextSize,
						max = limit.MaxTextSize,
						lastMin = limit.MinTextSize,
						lastMax = limit.MaxTextSize,
					}
					limits[limit] = saved
				end
				if limit.MaxTextSize ~= saved.lastMax then
					saved.max = limit.MaxTextSize
				end
				if limit.MinTextSize ~= saved.lastMin then
					saved.min = limit.MinTextSize
				end
				local max = math.max(1, math.round(saved.max * value))
				local min = math.min(max, math.max(1, math.round(saved.min * value)))
				limit.MinTextSize = 1
				limit.MaxTextSize = max
				limit.MinTextSize = min
				saved.lastMin, saved.lastMax = min, max
			end
		end
		if shadow then
			-- Shadow keeps its own resting scale; feedback is applied to its inner visual.
			local shadowScale = shadow:FindFirstChild("FeedbackScale")
			if shadowScale and shadowScale:IsA("UIScale") then
				shadowScale.Scale = value
			end
		end
	end)
	local function reset()
		hover, focus, pressed = false, false, nil
		target()
	end
	resets[button] = reset
	local function connect(signal: RBXScriptSignal, callback: (...any) -> ())
		table.insert(connections, signal:Connect(callback))
	end
	connect(button.MouseEnter, function()
		-- Touch devices must never retain a synthetic hover after tapping.
		hover = Input:GetLastInputType() ~= Enum.UserInputType.Touch
		target()
	end)
	connect(button.MouseLeave, function()
		hover = false
		if pressed and pressed.UserInputType == Enum.UserInputType.MouseButton1 then
			pressed = nil
		end
		target()
	end)
	connect(button.SelectionGained, function()
		focus = true
		target()
	end)
	connect(button.SelectionLost, function()
		focus = false
		pressed = nil
		target()
	end)
	connect(button.InputBegan, function(input: InputObject)
		if not Motion.enabled(button) then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA
		then
			pressed = input
			if input.UserInputType == Enum.UserInputType.Touch then
				hover = false
			end
			target()
		end
	end)
	connect(Input.InputEnded, function(input: InputObject)
		if
			pressed
			and (
				input == pressed
				or (
					pressed.UserInputType == Enum.UserInputType.MouseButton1
					and input.UserInputType == pressed.UserInputType
				)
			)
		then
			pressed = nil
			target(true)
		end
	end)
	connect(Input.WindowFocusReleased, reset)
	connect(button:GetPropertyChangedSignal("Active"), reset)
	connect(button:GetPropertyChangedSignal("Interactable"), reset)
	connect(button:GetPropertyChangedSignal("Visible"), reset)
	local function destroy()
		if destroyed then
			return
		end
		destroyed = true
		resets[button] = nil
		for _, connection in connections do
			connection:Disconnect()
		end
		disconnect()
		spring:destroy()
		scale:Destroy()
	end
	connect(button.Destroying, destroy)
	return destroy
end

-- Одинаковый pop для всех окон. Новая цель продолжает текущий размер;
-- единственный phase заменяет старую последовательность при быстрых кликах.
function Motion.window(group: CanvasGroup, baseScale: number?, reduced: (() -> boolean)?)
	local settings = Config.Window
	local scale = Instance.new("UIScale")
	scale.Name = "WindowMotion"
	scale.Parent = group
	local base = baseScale or 1
	local size = Ripple.createMotion(settings.ClosedScale, { start = true })
	local opacity = Ripple.createMotion(1, { start = true })
	local phase = "closed"
	local opened = false
	local destroyed = false
	local closed: (() -> ())? = nil
	scale.Scale = base * settings.ClosedScale
	group.GroupTransparency = 1
	local sizeChanged = size:onChange(function(value)
		scale.Scale = base * value
	end)
	local opacityChanged = opacity:onChange(function(value)
		group.GroupTransparency = math.clamp(value, 0, 1)
	end)
	local completed = size:onComplete(function()
		if phase == "opening" then
			phase = "settling"
			size:spring(1, { frequency = settings.SettleFrequency, dampingRatio = settings.SettleDamping })
		elseif phase == "anticipating" then
			phase = "closing"
			size:tween(settings.ClosedScale, { duration = settings.CloseTime, easing = "quadIn" })
			opacity:tween(1, { duration = settings.FadeOutTime })
		elseif phase == "closing" then
			phase = "closed"
			if closed then
				closed()
			end
		elseif phase == "settling" then
			phase = "open"
		end
	end)
	local function destroy()
		if destroyed then
			return
		end
		destroyed = true
		sizeChanged()
		opacityChanged()
		completed()
		size:destroy()
		opacity:destroy()
	end
	local destroying = group.Destroying:Connect(destroy)
	return {
		setOpen = function(value: boolean, onClosed: (() -> ())?, instant: boolean?)
			if destroyed then
				return
			end
			closed = onClosed
			if opened == value and phase ~= "closed" then
				return
			end
			opened = value
			group.Interactable = value
			Motion.resetButtons(group)
			if instant or (reduced and reduced()) or Motion.reduced(group) then
				phase = if value then "open" else "closed"
				size:setPosition(if value then 1 else settings.ClosedScale)
				size:tween(if value then 1 else settings.ClosedScale, { duration = 0 })
				opacity:setPosition(if value then 0 else 1)
				opacity:tween(if value then 0 else 1, { duration = 0 })
				if not value and closed then
					task.defer(closed)
				end
			elseif value then
				phase = "opening"
				opacity:tween(0, { duration = settings.FadeInTime })
				size:tween(settings.OvershootScale, { duration = settings.OpenTime, easing = "quadOut" })
			elseif phase == "closed" then
				if closed then
					task.defer(closed)
				end
			else
				phase = "anticipating"
				size:tween(settings.OvershootScale, { duration = settings.CloseAnticipationTime, easing = "quadOut" })
			end
		end,
		destroy = function()
			destroying:Disconnect()
			destroy()
			scale:Destroy()
		end,
	}
end

-- Контейнер занимает весь свой слой; Position управляется только этим модулем.
-- unitsPerPixel нужен для HUD в масштабируемом пространстве 1280x720.
function Motion.slide(group: GuiObject, direction: string, unitsPerPixel: (() -> number)?)
	local progress = Ripple.createMotion(0, { start = true })
	local hidden = false
	local function place(value: number)
		local viewport = workspace.CurrentCamera.ViewportSize
		local unit = if unitsPerPixel then unitsPerPixel() else 1
		local padding = Config.Hud.OffscreenPadding
		local x = if direction == "Left"
			then -viewport.X - padding
			elseif direction == "Right" then viewport.X + padding
			else 0
		local y = if direction == "Top"
			then -viewport.Y - padding
			elseif direction == "Bottom" then viewport.Y + padding
			else 0
		group.Position = UDim2.fromOffset(x * unit * value, y * unit * value)
	end
	local changed = progress:onChange(place)
	local destroying = group.Destroying:Connect(function()
		changed()
		progress:destroy()
	end)
	return {
		setHidden = function(value: boolean, instant: boolean?)
			group.Interactable = not value
			if hidden == value and not instant then
				return
			end
			hidden = value
			if value then
				Motion.resetButtons(group)
			end
			local goal = if value then 1 else 0
			if instant or Motion.reduced(group) then
				progress:setPosition(goal)
			end
			progress:tween(goal, {
				duration = if instant or Motion.reduced(group) then 0 else Config.Hud.SlideTime,
				easing = "sineInOut",
			})
		end,
		refresh = function()
			place(progress:getPosition())
		end,
		destroy = function()
			destroying:Disconnect()
			changed()
			progress:destroy()
		end,
	}
end

return Motion
