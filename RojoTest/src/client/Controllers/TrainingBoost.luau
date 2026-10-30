--!strict
-- Falling screen-space offers. Rewards wait for the server acknowledgement.
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local Shared = game.ReplicatedStorage.Shared
local Rules = require(Shared.Core.TrainingBoost)
local Config = require(Shared.GameConfig)
local Area = require(Shared.TrainingArea)
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Ripple = require(game.ReplicatedStorage.Packages.Ripple)
local Bubble = require(script.Parent.TrainingBoostBubble)
local Feedback = require(script.Parent.TrainingBoostFeedback)
local Collect = require(script.Parent.TrainingBoostCollect)
local Placement = require(script.Parent.TrainingBoostPlacement)
local Boost = {}

function Boost.mount(context: any)
	local gui = Instance.new("ScreenGui")
	gui.Name = "TrainingBoost"
	gui.IgnoreGuiInset = true
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.ResetOnSpawn = false
	-- SkillGain lives in the gameplay HUD at DisplayOrder 20.
	gui.DisplayOrder = 21
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local layer = Instance.new("Frame")
	layer.Name = "BubbleLayer"
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundTransparency = 1
	layer.Parent = gui
	local collectLayer = Instance.new("Frame")
	collectLayer.Name = "CollectLayer"
	collectLayer.Size = UDim2.fromScale(1, 1)
	collectLayer.BackgroundTransparency = 1
	collectLayer.Active, collectLayer.Interactable = false, false
	collectLayer.ZIndex = 2
	collectLayer.Parent = gui
	local root = ReactRoblox.createRoot(layer)
	local shown, setShown = React.createBinding(false)
	local ready, setReady = React.createBinding(false)
	local position, setPosition = React.createBinding(UDim2.new())
	local diameter, setDiameter = React.createBinding(144)
	local definition, setDefinition = React.createBinding(Rules.offer(1, 0))
	local fall = Ripple.createMotion(0, { start = true })
	local fallValue = 0
	local changed = fall:onChange(function(value: number)
		fallValue = value
	end)
	local current: any = nil
	local offer = -1
	local consumed = false
	local alive = true
	local visible = false
	local lastPosition = UDim2.new()
	local acceptedCycle: number? = nil
	local size = 144
	local goal: Vector2? = nil
	local placementReady = false
	local placementViewport = Vector2.zero
	local function effects(): boolean
		local snapshot = context.snapshot()
		return not snapshot or snapshot.data.settings.effects ~= false
	end
	local feedback = Feedback.create(diameter, effects, Config.StudTexture)
	local collect = Collect.mount({
		parent = collectLayer,
		skillLabel = context.skillLabel,
		playSound = context.playSound,
		enabled = effects,
		blocked = function()
			return context.blocked() or GuiService.MenuIsOpen
		end,
	})
	local function hide()
		visible = false
		setShown(false)
		setReady(false)
	end
	local function press()
		if not alive or not visible or consumed or not current or context.blocked() then
			return
		end
		local now = workspace:GetServerTimeNow()
		if not Rules.inWindow(current.started, offer, now, 0) then
			return
		end
		local def = Rules.offer(current.seed, offer)
		consumed = true
		hide()
		-- Release is handled by the shared button motion. The separate pop keeps
		-- a squash, overshoot and confetti visible after the hitbox disappears.
		feedback.play(lastPosition, def, def.product ~= nil)
		if context.pop then
			context.pop(def.product ~= nil)
		end
		if def.product then
			context.send("Product", def.product)
		else
			context.send("TrainingBoost", current.seed, offer)
		end
	end
	root:render(React.createElement(React.Fragment, nil, {
		Target = React.createElement(Bubble.Button, {
			shown = shown,
			ready = ready,
			position = position,
			diameter = diameter,
			definition = definition,
			studs = Config.StudTexture,
			press = press,
		}),
		Feedback = feedback.element,
	}))
	return {
		confirmed = function(info: any)
			if not alive or not current or info.seed ~= current.seed or info.started ~= current.started then
				return
			end
			acceptedCycle = info.cycle
			if info.offer == offer then
				consumed = true
				hide()
			end
			feedback.confirm(info.multiplier)
			if lastPosition.X.Offset > 0 then
				collect.play(Vector2.new(lastPosition.X.Offset, lastPosition.Y.Offset), info.multiplier)
			end
		end,
		frame = function(state: any, elapsed: number, _ballPosition: Vector3): boolean
			if not alive then
				return false
			end
			local reset = not current or current.started ~= state.started or current.seed ~= state.seed
			if reset then
				offer = -1
				acceptedCycle = nil
				consumed = false
				feedback.clear()
				collect.clear()
				placementReady = false
			end
			current = state
			local camera = workspace.CurrentCamera
			local character = Players.LocalPlayer.Character
			local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
			local strip = state.lane and state.lane:FindFirstChild("TrainingStrip")
			if
				not camera
				or context.blocked()
				or GuiService.MenuIsOpen
				or not characterRoot
				or not characterRoot:IsA("BasePart")
				or not strip
				or not strip:IsA("BasePart")
				or not Area.contains(strip, characterRoot.Position)
			then
				hide()
				feedback.clear()
				collect.clear()
				placementReady = false
				return acceptedCycle == state.cycle
			end
			local viewport = camera.ViewportSize
			local small = Input.TouchEnabled or viewport.Y < 600
			local nextSize = if small
				then math.clamp(viewport.Y * 0.27, 88, 110)
				else math.clamp(viewport.Y * 0.19, 132, 174)
			if math.abs(nextSize - size) > 0.1 then
				size = nextSize
				setDiameter(size)
			end
			local nextOffer = Rules.index(elapsed)
			local age = Rules.age(state.started, nextOffer, workspace:GetServerTimeNow())
			if nextOffer < 0 or age < 0 or age >= Rules.Lifetime then
				hide()
				return acceptedCycle == state.cycle
			end
			if nextOffer ~= offer then
				offer = nextOffer
				placementReady = false
				consumed = false
				setDefinition(Rules.offer(state.seed, offer))
				fall:setPosition(if effects() then 1 - (1 - math.clamp(age / Rules.TravelTime, 0, 1)) ^ 4 else 1)
				if effects() and age < Rules.TravelTime then
					fall:tween(1, { duration = Rules.TravelTime - age, easing = "quartOut" })
				end
			end
			gui:SetAttribute("ReducedMotion", not effects())
			if not effects() then
				fall:setPosition(1)
				feedback.reduce()
			end
			if consumed then
				hide()
				return acceptedCycle == state.cycle
			end
			local safe = GuiService:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets)
			local margin = size * 0.62 + 8
			local left = math.max(margin, safe.Min.X + margin)
			local right = math.min(viewport.X - margin, safe.Max.X - margin)
			local x = math.clamp(
				viewport.X * (0.36 + Rules.sample(state.seed, offer, 19) * 0.28),
				left,
				math.max(left, right)
			)
			local landing = math.clamp(
				viewport.Y
					* (
						if small
							then 0.48 + Rules.sample(state.seed, offer, 23) * 0.05
							else 0.31 + Rules.sample(state.seed, offer, 23) * 0.12
					),
				safe.Min.Y + margin + 38,
				viewport.Y - margin
			)
			if not placementReady or placementViewport ~= viewport then
				goal = Placement.choose(layer, Vector2.new(x, landing), size, state.seed, offer)
				placementReady = true
				placementViewport = viewport
			end
			if not goal then
				hide()
				return acceptedCycle == state.cycle
			end
			x = goal.X
			local y = -size + (goal.Y + size) * fallValue
			if effects() and age > Rules.TravelTime then
				y += math.sin((age - Rules.TravelTime) * 2.8) * 3
			end
			lastPosition = UDim2.fromOffset(math.round(x), math.round(y))
			setPosition(lastPosition)
			visible = true
			setShown(true)
			setReady(age >= Rules.TravelTime)
			gui:SetAttribute("Offer", offer)
			gui:SetAttribute("Multiplier", Rules.offer(state.seed, offer).multiplier)
			return acceptedCycle == state.cycle
		end,
		clear = function()
			current = nil
			acceptedCycle = nil
			offer = -1
			consumed = false
			hide()
			feedback.clear()
			collect.clear()
			placementReady = false
		end,
		destroy = function()
			alive = false
			changed()
			fall:destroy()
			feedback.destroy()
			collect.destroy()
			root:unmount()
			gui:Destroy()
		end,
	}
end

return Boost
