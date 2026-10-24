--!strict
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

export type Context = {
	parent: Instance,
	snapshot: () -> any?,
	playSound: (string, number?, number?) -> (),
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
	-- Draw the transition beyond device insets; position the resting banner in the safe area.
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
	local progress, updateProgress = React.createBinding(0)
	local motion = Ripple.createMotion(0, { start = true })
	local changed = motion:onChange(updateProgress)
	local alive, visible = true, false
	local revision = 0
	local message, category = "", "Info"
	local lastRaw, lastRawTime = "", -math.huge
	local lastSound = -math.huge
	local gain: number? = nil
	local count = 0
	local function reduced(): boolean
		local snapshot = context.snapshot()
		return snapshot ~= nil and snapshot.data.settings.effects == false
	end
	local function render()
		if not alive then
			return
		end
		local area = Insets.area(workspace.CurrentCamera.ViewportSize, probe)
		local width = math.min(area.size.X - 24, math.clamp(area.size.X * 0.48, 300, 500))
		local height = 48
		-- The centre of the Roblox top bar is empty. Use the device-safe top strip
		-- above Auto Kick; CoreUISafeInsets would push the toast into the phone counters.
		local top = Insets.insets().top + 6
		local color = if category == "Error"
			then Style.Colors.Red
			elseif category == "Success" then Style.Colors.Green
			else Style.Colors.Blue
		local icon = if category == "Error"
			then "Alert"
			elseif gain ~= nil then "Wins"
			elseif category == "Success" then "Check"
			else "Ball"
		root:render(e("Frame", {
			Name = "Banner",
			Visible = visible,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = progress:map(function(value)
				return UDim2.fromOffset(area.offset.X + area.size.X / 2, -height - 12 + (top + height + 12) * value)
			end),
			Size = UDim2.fromOffset(width, height),
		}, {
			Shadow = e("Frame", {
				Position = UDim2.fromOffset(0, 4),
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Style.Ink,
				BackgroundTransparency = 0.35,
				BorderSizePixel = 0,
				ZIndex = 1,
			}, { Corner = U.corner(12) }),
			Plate = e(U.Surface, {
				Color = color,
				Radius = 12,
				NoShadow = true,
				ZIndex = 2,
				Children = {
					Accent = e("Frame", {
						Position = UDim2.fromOffset(9, 10),
						Size = UDim2.fromOffset(4, height - 20),
						BackgroundColor3 = color,
						BorderSizePixel = 0,
						ZIndex = 10,
					}, { Corner = U.corner(2) }),
					Icon = e(
						U.Icon,
						{ Kind = icon, Position = UDim2.fromOffset(21, 6), Size = UDim2.fromOffset(36, 36) }
					),
					Message = e(U.Label, {
						Name = "Message",
						Text = message,
						Position = UDim2.fromOffset(68, 4),
						Size = UDim2.fromOffset(width - 82, height - 8),
						TextSize = if area.size.Y < 500 then 18 else 20,
						Color = if gain ~= nil then Style.Gold else Style.Text,
						Wrap = true,
						Align = Enum.TextXAlignment.Left,
					}),
				},
			}),
		}))
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
		local same = visible and raw == message
		local merging = visible and gain ~= nil and wins ~= nil
		if merging then
			gain = (gain or 0) + (wins or 0)
			count += 1
		else
			gain, count = wins, 1
		end
		category = kind or classify(raw)
		message = if gain ~= nil and count > 1
			then "+" .. Config.format(gain) .. " Wins • " .. count .. " kicks"
			else raw
		if distance and count == 1 then
			message = "+" .. Config.format(wins or 0) .. " Wins • " .. Config.format(distance) .. " m"
		end
		visible = true
		revision += 1
		local id = revision
		render()
		if reduced() then
			motion:setPosition(1)
			motion:tween(1, { duration = 0 })
		else
			motion:spring(1, { frequency = 4, dampingRatio = 0.85 })
		end
		if not same and not merging and now - lastSound >= 0.4 then
			lastSound = now
			local sound = Sounds[category]
			context.playSound(sound.id, sound.volume)
		end
		task.delay(2.8, function()
			if not alive or revision ~= id then
				return
			end
			motion:tween(0, { duration = if reduced() then 0 else 0.25, easing = "quadIn" })
			task.delay(if reduced() then 0 else 0.26, function()
				if alive and revision == id then
					visible = false
					gain = nil
					render()
				end
			end)
		end)
	end
	local resize = probe:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
	render()
	return {
		show = show,
		destroy = function()
			alive = false
			revision += 1
			resize:Disconnect()
			changed()
			motion:destroy()
			root:unmount()
			gui:Destroy()
		end,
	}
end

return Notifications
