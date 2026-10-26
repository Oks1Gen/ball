--!strict
-- One local target follows the current net point. Only a server acknowledgement
-- turns on the boosted trail/impact; pressing the button alone never grants Skill.
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.GameConfig)
local Motion = require(Shared.TrainingMotion)
local Area = require(Shared.TrainingArea)
local Rules = require(Shared.Core.TrainingBoost)
local Aura = require(script.Parent.TrainingBoostAura)
local Feedback = require(script.Parent.TrainingBoostFeedback)
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Ripple = require(game.ReplicatedStorage.Packages.Ripple)
local Style = require(script.Parent.Parent.UiStyle)
local e = React.createElement
local Boost = {}
local PURPLE = Style.Colors.Eggs
local LIGHT = Color3.fromRGB(231, 199, 255)

function Boost.mount(context: any)
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "TrainingBoost"
	gui.IgnoreGuiInset = true
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 19
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	local root = ReactRoblox.createRoot(gui)
	local shown, setShown = React.createBinding(false)
	local position, setPosition = React.createBinding(UDim2.new())
	local lastPosition = UDim2.new()
	local locked, setLocked = React.createBinding(false)
	local pending, setPending = React.createBinding(false)
	local pulse, setPulse = React.createBinding(0)
	local animation = Ripple.createMotion(0, { start = true })
	local disconnect = animation:onChange(setPulse)
	local current: any = nil
	local submitted, accepted, visible, alive = false, false, false, true
	local kickShown, goalShown = false, false
	local phase = 0
	local diameter = if Input.TouchEnabled then 60 else 52

	local host = Instance.new("Part")
	host.Name = "TrainingBoostTrail"
	host.Anchored = true
	host.CanCollide, host.CanTouch, host.CanQuery = false, false, false
	host.CastShadow = false
	host.Transparency = 1
	host.Size = Vector3.one * 0.1
	host.Parent = context.folder
	local a, b = Instance.new("Attachment"), Instance.new("Attachment")
	a.Position, b.Position = Vector3.new(0, 0.24, 0), Vector3.new(0, -0.24, 0)
	a.Parent, b.Parent = host, host
	local trail = Instance.new("Trail")
	trail.Name = "PurpleBoostTrail"
	trail.Attachment0, trail.Attachment1 = a, b
	trail.Color = ColorSequence.new(LIGHT, PURPLE)
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	trail.Lifetime = 0.22
	trail.MinLength = 0.05
	trail.FaceCamera = true
	trail.LightEmission, trail.LightInfluence = 1, 0
	trail.Enabled = false
	trail.Parent = host

	local function effects(): boolean
		local snapshot = context.snapshot()
		return not snapshot or snapshot.data.settings.effects ~= false
	end
	local aura = Aura.mount({ folder = context.folder, enabled = effects })
	local feedback = Feedback.create(diameter, effects)
	local function hide()
		if visible then
			visible = false
			setShown(false)
		end
		trail.Enabled = false
		trail:Clear()
	end
	local function press()
		if not alive or not visible or submitted or not current or context.blocked() then
			return
		end
		local elapsed = workspace:GetServerTimeNow() - current.started
		if
			math.floor(elapsed / Config.TrainingCycle) ~= current.cycle
			or elapsed % Config.TrainingCycle >= Config.KickContact
			or not Rules.available(current.cycle, Config.TrainingCycle, Config.KickContact)
		then
			return
		end
		submitted = true
		setPending(true)
		-- The bubble pops immediately as input feedback. Skill, kick and goal
		-- effects still require the server acknowledgement for this exact cycle.
		visible = false
		setShown(false)
		feedback.play(lastPosition)
		if current.shot then
			aura.emit(current.shot.finish, "Pop")
		end
		context.send("TrainingBoost", current.seed, current.cycle)
	end
	local function round()
		return e("UICorner", { CornerRadius = UDim.new(0.5, 0) })
	end
	local target = e("TextButton", {
		Name = "BoostTarget",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = UDim2.fromOffset(diameter + 12, diameter + 12),
		Visible = shown,
		Selectable = true,
		ZIndex = 1,
		[React.Event.InputBegan] = function(_, input: InputObject)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				press()
			end
		end,
		[React.Event.Activated] = function()
			press()
		end,
	}, {
		Halo = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = pulse:map(function(value: number)
				return UDim2.fromOffset(diameter + 8 + math.round(value * 12), diameter + 8 + math.round(value * 12))
			end),
			BackgroundTransparency = 1,
			ZIndex = 2,
		}, {
			Round = round(),
			Ring = e("UIStroke", {
				Color = LIGHT,
				Thickness = 1.5,
				Transparency = pulse:map(function(value: number)
					return 0.25 + value * 0.65
				end),
			}),
		}),
		Shadow = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 3),
			Size = UDim2.fromOffset(diameter, diameter),
			BackgroundColor3 = Style.Ink,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, { Round = round() }),
		Core = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(diameter, diameter),
			BackgroundColor3 = locked:map(function(value: boolean)
				return if value then PURPLE:Lerp(LIGHT, 0.35) else PURPLE
			end),
			BackgroundTransparency = 0.12,
			BorderSizePixel = 0,
			ZIndex = 4,
		}, {
			Round = round(),
			Border = e("UIStroke", { Color = Color3.fromRGB(62, 18, 104), Thickness = 2.5 }),
			Shading = e("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(118, 65, 175)),
			}),
			Inner = e("Frame", {
				Position = UDim2.fromOffset(4, 4),
				Size = UDim2.new(1, -8, 1, -8),
				BackgroundTransparency = 1,
				ZIndex = 5,
			}, {
				Round = round(),
				Ring = e("UIStroke", { Color = LIGHT, Thickness = 1.5, Transparency = 0.1 }),
			}),
			Label = e("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "×2",
				Font = Enum.Font.GothamBlack,
				TextSize = 23,
				TextColor3 = Style.Text,
				TextTransparency = pending:map(function(value: boolean)
					return if value then 0.35 else 0
				end),
				TextStrokeColor3 = Color3.fromRGB(62, 18, 104),
				TextStrokeTransparency = 0,
				ZIndex = 6,
			}),
		}),
	})
	root:render(e(React.Fragment, nil, { Target = target, Feedback = feedback.element }))

	return {
		confirmed = function(info: any)
			if
				not alive
				or not current
				or info.seed ~= current.seed
				or info.started ~= current.started
				or info.cycle ~= current.cycle
			then
				return
			end
			accepted = true
			setLocked(true)
			setPending(false)
			if effects() then
				animation:setPosition(0)
				animation:tween(1, { duration = 0.2 })
			end
		end,
		frame = function(state: any, elapsed: number, ballPosition: Vector3): boolean
			if not alive then
				return false
			end
			if
				not current
				or state.started ~= current.started
				or state.seed ~= current.seed
				or state.cycle ~= current.cycle
			then
				current = state
				submitted, accepted = false, false
				kickShown, goalShown = false, false
				setLocked(false)
				setPending(false)
				trail.Enabled = false
				trail:Clear()
				animation:setPosition(0)
				if effects() then
					animation:tween(1, { duration = Config.KickContact })
				end
			end
			phase = elapsed % Config.TrainingCycle
			local camera = workspace.CurrentCamera
			local shot = state.shot
			local character = player.Character
			local characterRoot = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local strip = state.lane:FindFirstChild("TrainingStrip") :: BasePart?
			if
				not camera
				or not shot
				or context.blocked()
				or not characterRoot
				or not strip
				or not Area.contains(strip, characterRoot.Position)
			then
				hide()
				aura.clear()
				feedback.clear()
				return false
			end
			local point, onScreen = camera:WorldToViewportPoint(shot.finish)
			local edge = diameter / 2 + 10
			local canShow = onScreen
				and point.Z > 0
				and point.X >= edge
				and point.X <= camera.ViewportSize.X - edge
				and point.Y >= edge + 36
				and point.Y <= camera.ViewportSize.Y - edge
				and Rules.available(state.cycle, Config.TrainingCycle, Config.KickContact)
				and not submitted
				and phase < Config.KickContact
			if visible ~= canShow then
				visible = canShow
				setShown(canShow)
			end
			if visible then
				lastPosition = UDim2.fromOffset(math.round(point.X), math.round(point.Y))
				setPosition(lastPosition)
			end
			host.Position = ballPosition
			if accepted and not kickShown and phase >= Config.KickContact then
				kickShown = true
				if phase - Config.KickContact < 0.2 then
					aura.emit(ballPosition, "Kick")
				end
			end
			local contact = Config.KickContact + Motion.FlightTime
			if accepted and not goalShown and phase >= contact then
				goalShown = true
				if phase - contact < 0.2 then
					aura.emit(shot.finish, "Goal")
				end
			end
			trail.Enabled = accepted
				and effects()
				and phase >= Config.KickContact
				and phase < Config.KickContact + Motion.FlightTime
			if not effects() then
				trail:Clear()
				aura.clear()
			end
			return accepted
		end,
		clear = function()
			current = nil
			submitted, accepted = false, false
			kickShown, goalShown = false, false
			hide()
			aura.clear()
			feedback.clear()
		end,
		destroy = function()
			alive = false
			disconnect()
			animation:destroy()
			aura.destroy()
			feedback.destroy()
			root:unmount()
			gui:Destroy()
			host:Destroy()
		end,
	}
end

return Boost
