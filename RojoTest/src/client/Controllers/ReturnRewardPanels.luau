--!strict
local Kit = require(script.Parent.HudKit)
local Motion = require(game.ReplicatedStorage.Shared.UiMotion)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Rewards = require(game.ReplicatedStorage.Shared.Core.ReturnRewards)
local RunService = game:GetService("RunService")
local Panels = {}
local C = Color3.fromRGB
local gold = C(255, 205, 31)

local function label(
	parent: Instance,
	name: string,
	value: string,
	x: number,
	y: number,
	w: number,
	h: number,
	size: number,
	color: Color3?
): TextLabel
	local text = Kit.text(parent, name, value, x, y, w, h, size, color)
	text.TextWrapped = true
	text.ZIndex = 5
	return text
end

function Panels.offline(modal: Frame, context: any): () -> ()
	local width = modal.Size.X.Offset
	label(modal, "Subtitle", "You trained while you were offline:", 24, 45, width - 48, 58, 32)
	local reward = Kit.frame(modal, "Reward", (width - 250) / 2, 115, 250, 230)
	reward.BackgroundTransparency = 1
	Kit.burst(reward)
	Kit.icon(reward, "Skill", 35, 5, 180, 205).ZIndex = 3
	local amount = label(modal, "OfflineSkill", "+0 SKILL", 20, 338, width - 40, 62, 48, gold)
	local sentAt = 0
	local finished = false
	local claim: TextButton
	claim = Kit.button(modal, "OfflineClaim", "Claim!", (width - 280) / 2, 410, 280, 100, C(83, 240, 19), 42, function()
		if sentAt == 0 then
			sentAt = os.clock()
			context.send("OfflineClaim")
		end
	end)
	return function()
		local snapshot = context.snapshot()
		if not snapshot or not snapshot.welcome then
			return
		end
		if snapshot.welcome.claimed and sentAt > 0 and not finished then
			finished = true
			context.finishWelcome()
			return
		end
		amount.Text = "+" .. Config.format(snapshot.welcome.skill) .. " SKILL"
		if sentAt > 0 and os.clock() - sentAt > 8 then
			sentAt = 0
		end
		local caption = Kit.captionOf(claim)
		if caption then
			caption.Text = if sentAt > 0 then "Claiming..." else "Claim!"
		end
	end
end

function Panels.daily(modal: Frame, context: any): () -> ()
	local cards: { any } = {}
	local sentAt = 0
	for day, reward in Rewards.Days do
		local final = day == 7
		local w, h = if final then 190 else 170, if final then 406 else 174
		local x = if final then 610 else 20 + ((day - 1) % 3) * 196
		local y = if final or day <= 3 then 68 else 300
		local holder = Kit.frame(modal, "Day" .. day, x + w / 2, y + h / 2, w, h)
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.BackgroundTransparency = 1
		local pulse = Instance.new("UIScale")
		pulse.Name = "RewardPulse"
		pulse.Parent = holder
		local button = Kit.button(
			holder,
			"RewardButton",
			"",
			0,
			0,
			w,
			h,
			if final then C(151, 64, 246) else gold,
			28,
			function()
				local snapshot = context.snapshot()
				local calendar = snapshot and snapshot.dailyReward
				if calendar and calendar.ready and calendar.day == day and sentAt == 0 then
					sentAt = os.clock()
					context.send("Daily")
				end
			end
		)
		local face = Kit.visualOf(button)
		if final then
			local gradient = face:FindFirstChildOfClass("UIGradient")
			if gradient then
				face.BackgroundColor3 = Color3.new(1, 1, 1)
				gradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, C(181, 30, 255)),
					ColorSequenceKeypoint.new(0.33, C(32, 154, 255)),
					ColorSequenceKeypoint.new(0.66, C(122, 255, 20)),
					ColorSequenceKeypoint.new(1, C(255, 139, 25)),
				})
			end
		end
		local badge = Kit.brick(button, "DayBadge", 14, -22, w - 28, 50, C(255, 180, 20), 8)
		badge.ZIndex = 3
		label(badge, "DayLabel", "DAY " .. day, 0, 0, w - 28, 50, 30)
		local burst = Kit.burst(face)
		burst.Position = UDim2.fromOffset(6, if final then 70 else 30)
		burst.Size = UDim2.fromOffset(w - 12, if final then 250 else 140)
		burst.ImageTransparency = 0.7
		if final then
			label(button, "Bonus", "BONUS!", 4, 38, w - 8, 45, 32, gold)
			Kit.icon(button, "Skill", 28, 92, 132, 145).ZIndex = 3
			Kit.icon(button, "Wins", 91, 197, 85, 90).ZIndex = 4
			label(
				button,
				"Amount",
				"+" .. Config.format(reward.skill) .. " SKILL\n+" .. Config.format(reward.wins) .. " WINS",
				6,
				295,
				w - 12,
				70,
				27
			)
		else
			local kind = if reward.skill > 0 then "Skill" else "Wins"
			local value = if reward.skill > 0 then reward.skill else reward.wins
			label(button, "Amount", "+" .. Config.format(value) .. " " .. string.upper(kind), 4, 33, w - 8, 39, 24)
			Kit.icon(button, kind, (w - 90) / 2, 72, 90, 90).ZIndex = 3
		end
		local shade = Kit.frame(button, "ClaimedShade", 0, 0, w, h, C(10, 13, 22))
		shade.BackgroundTransparency = 0.48
		shade.ZIndex = 7
		Kit.corner(shade, 7)
		local check = Kit.icon(button, "Check", (w - 130) / 2, (h - 130) / 2, 130, 130)
		check.ZIndex = 8
		table.insert(cards, { button = button, shade = shade, check = check, pulse = pulse, available = false })
	end
	local hint = label(modal, "DailyHint", "CLAIM YOUR REWARD", 20, 493, 780, 43, 32, C(123, 255, 32))
	local connection = RunService.RenderStepped:Connect(function()
		for _, card in cards do
			card.pulse.Scale = if card.available and not Motion.reduced(modal)
				then 1 + 0.025 * (0.5 + 0.5 * math.sin(os.clock() * math.pi * 2 / 1.6))
				else 1
		end
	end)
	modal.Destroying:Once(function()
		connection:Disconnect()
	end)
	return function()
		local snapshot = context.snapshot()
		local calendar = snapshot and snapshot.dailyReward
		if not calendar then
			return
		end
		if not calendar.ready or (sentAt > 0 and os.clock() - sentAt > 8) then
			sentAt = 0
		end
		for day, card in cards do
			local claimed = day <= calendar.claimed
			local available = calendar.ready and day == calendar.day and sentAt == 0
			card.available = available
			card.button.Active = not claimed
			card.button.Interactable = not claimed
			card.shade.Visible = claimed
			card.check.Visible = claimed
		end
		hint.Text = if sentAt > 0
			then "CLAIMING..."
			elseif calendar.ready then "CLAIM YOUR REWARD"
			else "COME BACK TOMORROW!"
	end
end

return Panels
