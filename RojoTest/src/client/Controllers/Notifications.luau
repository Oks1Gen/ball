--!strict
-- Compact notices. Up to two plates sit in a column under the top HUD cluster
-- (Auto Kick and the upgrade card), centred on Auto Kick.
local TextService = game:GetService("TextService")
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Ripple = require(game.ReplicatedStorage.Packages.Ripple)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Sounds = require(game.ReplicatedStorage.Shared.NotificationSounds)
local U = require(script.Parent.Parent.CollectorUI.Components)
local Style = require(script.Parent.Parent.UiStyle)
local Insets = require(script.Parent.Parent.Modules.GuiInsets)
local e = React.createElement
local Notifications = {}

local HEIGHT = 42
local GAP = 10
local TEXT_SIZE = 20
local ICON = 30
-- The same inset on both sides of the icon + caption group keeps it centred.
local PAD = 12
local SPACING = 8
local MAX_STACK = 2
local LIFETIME = 2.8
local LEAVE_TIME = 0.25

export type Context = {
	parent: Instance,
	snapshot: () -> any?,
	playSound: (string, number?, number?) -> (),
	-- Absolute GUI position: X of the column centre, Y of the top cluster bottom.
	anchor: () -> Vector2,
}

type Toast = {
	id: number,
	text: string,
	category: string,
	gain: number?,
	count: number,
	expires: number,
	leaving: boolean,
	appear: any,
	slot: any,
	setSlot: (number) -> (),
	slotValue: number,
	scale: any,
	setScale: (number) -> (),
}

-- Existing server notices are plain strings. Keep their presentation policy here.
local function classify(message: string): string
	local lower = string.lower(message)
	for _, phrase in
		{
			"need",
			"not ",
			"full",
			"already",
			"unknown",
			"wait ",
			"equip up to",
			"unlocks",
			"go to",
			"walk to",
			"заверши",
		}
	do
		if string.find(lower, phrase, 1, true) then
			return "Error"
		end
	end
	for _, phrase in { "claimed!", "received!", "daily gift:", "rebirth!", "unlocked", "purchased", "bought" } do
		if string.find(lower, phrase, 1, true) then
			return "Success"
		end
	end
	if string.sub(message, 1, 1) == "+" then
		return "Success"
	end
	return "Info"
end

function Notifications.mount(context: Context)
	local gui = Instance.new("ScreenGui")
	gui.Name = "Notifications"
	Insets.prepare(gui)
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.DisplayOrder = 80
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = context.parent
	local probe = Instance.new("Frame")
	probe.Name = "NotificationArea"
	probe.BackgroundTransparency = 1
	probe.Size = UDim2.fromScale(1, 1)
	probe.Parent = gui
	local root = ReactRoblox.createRoot(probe)
	local anchor, setAnchor = React.createBinding(Vector2.zero)
	local toasts: { Toast } = {}
	local alive = true
	local revision = 0
	local lastRaw, lastRawTime = "", -math.huge
	local lastSound = -math.huge

	local function reduced(): boolean
		local snapshot = context.snapshot()
		return snapshot ~= nil and snapshot.data.settings.effects == false
	end

	local function textWidth(text: string): number
		return TextService:GetTextSize(text, TEXT_SIZE, Enum.Font.GothamBlack, Vector2.new(2000, HEIGHT)).X + 4
	end

	local function plate(toast: Toast)
		local color = if toast.category == "Error"
			then Style.Colors.Red
			elseif toast.category == "Success" then Style.Colors.Green
			else Style.Colors.Blue
		local icon = if toast.category == "Error"
			then "Alert"
			elseif toast.gain ~= nil then "Wins"
			elseif toast.category == "Success" then "Check"
			else "Ball"
		local area = Insets.area(workspace.CurrentCamera.ViewportSize, probe)
		local limit = math.min(480, area.size.X - 24)
		local caption = math.min(textWidth(toast.text), limit - PAD * 2 - ICON - SPACING)
		local width = PAD * 2 + ICON + SPACING + caption
		-- The same brick plate as the HUD buttons: studs, top light, ink edge,
		-- drop shadow and a white caption with its outline. It pops in and out
		-- by scale; a CanvasGroup fade dulled all of it.
		return e("Frame", {
			Name = "Toast" .. toast.id,
			BackgroundTransparency = 1,
			-- Centre anchor: UIScale grows the pop from the middle of the plate.
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(width, HEIGHT),
			Position = React.joinBindings({ anchor = anchor, slot = toast.slot }):map(function(values: any)
				local origin = values.anchor - probe.AbsolutePosition
				return UDim2.fromOffset(
					math.round(origin.X),
					math.round(origin.Y + 8 + HEIGHT / 2 + values.slot * (HEIGHT + GAP))
				)
			end),
		}, {
			Scale = e("UIScale", {
				Scale = toast.scale:map(function(value: number)
					return math.max(value, 0.001)
				end),
			}),
			Plate = e(U.Surface, {
				Color = color:Lerp(Style.Ink, 0.12),
				Radius = 10,
				Children = {
					Icon = e(U.Icon, {
						Kind = icon,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, PAD, 0.5, 0),
						Size = UDim2.fromOffset(ICON, ICON),
					}),
					Message = e(U.Label, {
						Name = "Message",
						Text = toast.text,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, PAD + ICON + SPACING, 0.5, 0),
						Size = UDim2.fromOffset(caption, HEIGHT - 8),
						TextSize = TEXT_SIZE,
						Color = if toast.gain ~= nil then Style.Gold else Style.Text,
						Align = Enum.TextXAlignment.Left,
					}),
				},
			}),
		})
	end

	local function render()
		if not alive then
			return
		end
		local children = {}
		for _, toast in toasts do
			children["Toast" .. toast.id] = plate(toast)
		end
		root:render(e(React.Fragment, nil, children))
	end

	local function newToast(text: string, category: string, gain: number?): Toast
		revision += 1
		local scale, setScale = React.createBinding(0)
		local slot, setSlot = React.createBinding(0)
		local toast: Toast = {
			id = revision,
			text = text,
			category = category,
			gain = gain,
			count = 1,
			expires = os.clock() + LIFETIME,
			leaving = false,
			appear = Ripple.createMotion(0, { start = true }),
			slot = slot,
			setSlot = setSlot,
			slotValue = 0,
			scale = scale,
			setScale = setScale,
		}
		-- The spring overshoots a little: the bouncy pop of the game's windows.
		toast.appear:onChange(function(value: number)
			if not toast.leaving then
				setScale(math.max(value, 0))
			end
		end)
		return toast
	end

	local function leave(toast: Toast)
		if toast.leaving then
			return
		end
		toast.leaving = true
		toast.expires = os.clock() + (if reduced() then 0 else LEAVE_TIME)
	end

	local function show(raw: string?, kind: string?, wins: number?, distance: number?)
		if not alive or raw == nil or raw == "" then
			return
		end
		local now = os.clock()
		-- Result/World arrive both as an Effect and as an Update on older servers.
		if raw == lastRaw and now - lastRawTime < 0.5 then
			return
		end
		lastRaw, lastRawTime = raw, now
		local category = kind or classify(raw)
		local text = raw
		if distance then
			text = "+" .. Config.format(wins or 0) .. " Wins • " .. Config.format(distance) .. " m"
		end
		-- Kick results that arrive while one is shown merge into it; a repeated
		-- message only stays longer.
		local newest = toasts[1]
		if newest and not newest.leaving and newest.gain ~= nil and wins ~= nil then
			newest.gain = (newest.gain :: number) + wins
			newest.count += 1
			newest.text = "+" .. Config.format(newest.gain :: number) .. " Wins • " .. newest.count .. " kicks"
			newest.expires = now + LIFETIME
			render()
			return
		end
		if newest and not newest.leaving and newest.text == text then
			newest.expires = now + LIFETIME
			return
		end
		local toast = newToast(text, category, wins)
		table.insert(toasts, 1, toast)
		while #toasts > MAX_STACK + 1 do
			local dropped = table.remove(toasts)
			if dropped then
				dropped.appear:destroy()
			end
		end
		for index, item in toasts do
			if index > MAX_STACK then
				leave(item)
			end
		end
		render()
		if reduced() then
			toast.appear:setPosition(1)
			toast.appear:tween(1, { duration = 0 })
		else
			toast.appear:spring(1, { frequency = 4, dampingRatio = 0.55 })
		end
		if now - lastSound >= 0.4 then
			lastSound = now
			local sound = Sounds[category]
			context.playSound(sound.id, sound.volume)
		end
	end

	-- Leaving toasts shrink away; the rest glide to their slot under the
	-- current bottom of the top cluster.
	local function frame(dt: number)
		if not alive then
			return
		end
		setAnchor(context.anchor())
		local now = os.clock()
		local quick = reduced()
		local changed = false
		for index = #toasts, 1, -1 do
			local toast = toasts[index]
			if not toast.leaving and now >= toast.expires then
				leave(toast)
			end
			if toast.leaving then
				local progress = if quick then 1 else math.clamp(1 - (toast.expires - now) / LEAVE_TIME, 0, 1)
				toast.setScale(1 - progress * progress)
				if progress >= 1 then
					toast.appear:destroy()
					table.remove(toasts, index)
					changed = true
				end
			end
		end
		local slot = 0
		for _, toast in toasts do
			toast.slotValue = if quick then slot else toast.slotValue + (slot - toast.slotValue) * math.min(1, dt * 14)
			toast.setSlot(toast.slotValue)
			if not toast.leaving then
				slot += 1
			end
		end
		if changed then
			render()
		end
	end

	local resize = probe:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
	render()
	return {
		show = show,
		frame = frame,
		setReduced = function(value: boolean)
			gui:SetAttribute("ReducedMotion", value)
		end,
		destroy = function()
			alive = false
			resize:Disconnect()
			for _, toast in toasts do
				toast.appear:destroy()
			end
			root:unmount()
			gui:Destroy()
		end,
	}
end

return Notifications
