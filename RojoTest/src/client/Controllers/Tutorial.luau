--!strict
-- Live onboarding. Roblox tutorial Beam texture and a free Creator Store
-- hand cursor; no generated artwork, recording, autoplay or synthetic input.
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local GuiService = game:GetService("GuiService")
local Shared = game.ReplicatedStorage.Shared
local Config: any = require(Shared.GameConfig)
local Insets = require(script.Parent.Parent.Modules.GuiInsets)
local Kit: any = require(script.Parent.HudKit)
local Guide = {}
local HAND = "rbxassetid://9071533698"

function Guide.mount(context: any)
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "BallTutorial"
	Insets.prepare(gui)
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 58
	gui.Parent = player:WaitForChild("PlayerGui")
	local safe = Instance.new("Frame")
	safe.Name = "SafeArea"
	safe.BackgroundTransparency = 1
	safe.Size = UDim2.fromScale(1, 1)
	safe.Parent = gui
	local title = Kit.text(safe, "Instruction", "", 0, 0, 600, 58, 24)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.TextWrapped = true
	local hand = Instance.new("ImageLabel")
	hand.Name = "TapPointer"
	hand.BackgroundTransparency = 1
	hand.Image = HAND
	hand.Size = UDim2.fromOffset(58, 58)
	hand.AnchorPoint = Vector2.new(0.5, 0)
	hand.Parent = safe
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync({ hand })
		end)
	end)
	local arrows = require(Shared.DirectionGuide).new({ name = "TutorialChevrons", automatic = false })
	local summary = Kit.frame(safe, "FirstKickHelp", 0, 0, 500, 184, Color3.fromRGB(39, 41, 48))
	summary.AnchorPoint = Vector2.new(0.5, 0.5)
	Kit.corner(summary, 12)
	Kit.stroke(summary, 2)
	Kit.text(summary, "Heading", "GREAT KICK! WHAT'S NEXT?", 14, 10, 472, 32, 23, Color3.fromRGB(255, 221, 38))
	Kit.text(
		summary,
		"Explanation",
		"Train for Skill. Kick for Wins.\nSpend Wins on balls and pets to train faster.",
		16,
		51,
		468,
		64,
		21
	)
	local summaryDismissed = false
	Kit.button(summary, "Continue", "LET'S GO!", 145, 128, 210, 44, Color3.fromRGB(85, 233, 19), 22, function()
		summaryDismissed = true
	end)
	local lastStage: number? = nil
	local hasSeenShot = false
	local cachedTarget: BasePart? = nil
	local cachedKey = ""
	local lookupAt = 0
	local searchAt = 0
	local cachedButton: GuiObject? = nil
	local function visible(node: Instance): boolean
		local current: Instance? = node
		while current and current ~= player.PlayerGui do
			if current:IsA("GuiObject") and not current.Visible then
				return false
			end
			if current:IsA("ScreenGui") and not current.Enabled then
				return false
			end
			current = current.Parent
		end
		return current == player.PlayerGui
	end
	local function findButton(names: { string }, now: number): GuiObject?
		if now < searchAt and cachedButton and visible(cachedButton) and table.find(names, cachedButton.Name) then
			return cachedButton
		end
		searchAt = now + 0.25
		cachedButton = nil
		for _, name in names do
			for _, node in player.PlayerGui:GetDescendants() do
				if node.Name == name and node:IsA("GuiButton") and visible(node) then
					cachedButton = node
					return node
				end
			end
		end
		return nil
	end
	local function target(arena: Instance, key: string, now: number): BasePart?
		if key == cachedKey and cachedTarget and cachedTarget:IsDescendantOf(arena) then
			return cachedTarget
		end
		if key == cachedKey and now < lookupAt then
			return nil
		end
		cachedKey, cachedTarget, lookupAt = key, nil, now + 1
		if key == "Train" then
			local zone = arena:FindFirstChild("TrainingZone")
			local lane = zone and zone:FindFirstChild("TrainingLane1")
			local strip = lane and lane:FindFirstChild("TrainingStrip")
			if strip and strip:IsA("BasePart") then
				cachedTarget = strip
			end
		elseif key == "Kick" then
			local lobby = arena:FindFirstChild("Lobby")
			local apron = lobby and lobby:FindFirstChild("ThrowingApron")
			if apron and apron:IsA("BasePart") then
				cachedTarget = apron
			end
		elseif key == "Egg" then
			local world = arena:FindFirstChild("SkippingWorld")
			local egg = world and world:FindFirstChild("Egg_Common")
			local shell = egg and egg:FindFirstChild("EggShell")
			if shell and shell:IsA("BasePart") then
				cachedTarget = shell
			end
		elseif key == "Ball" then
			local stand = arena:FindFirstChild("EmptyItemStand")
			if stand then
				for _, node in stand:GetDescendants() do
					if node:IsA("ProximityPrompt") and node:GetAttribute("BallId") == "Smooth" then
						local parent = node.Parent
						if parent and parent:IsA("Attachment") then
							parent = parent.Parent
						end
						if parent and parent:IsA("BasePart") then
							cachedTarget = parent
						end
						break
					end
				end
			end
		end
		return cachedTarget
	end
	local function clear()
		arrows:setEnabled(false)
		hand.Visible = false
		summary.Visible = false
		title.Visible = false
	end
	return {
		frame = function(now: number)
			clear()
			local info = context.snapshot()
			if not info then
				return
			end
			local d = info.data
			local stage = d.tutorialStage or 0
			if lastStage == 0 and stage == 1 then
				summaryDismissed = false
			end
			if lastStage == 1 and stage >= 2 then
				hasSeenShot = true
			end
			if lastStage and stage < lastStage then
				summaryDismissed, hasSeenShot = false, false
			end
			lastStage = stage
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if
				stage >= 5
				or not root
				or not root:IsA("BasePart")
				or not hum
				or hum.Health <= 0
				or context.flying()
				or player:GetAttribute("MapIntroActive") ~= false
				or GuiService.MenuIsOpen
			then
				return
			end
			local panel = context.panel()
			if panel and panel ~= "Inventory" and panel ~= "Pets" and not string.find(panel, "Egg") then
				return
			end
			local size = safe.AbsoluteSize
			local phone = size.Y < 520
			local auto = context.autoButton
			local top = auto.AbsolutePosition.Y + auto.AbsoluteSize.Y - safe.AbsolutePosition.Y + 10
			title.Position = UDim2.new(0.5, 0, 0, math.max(if phone then 64 else 100, top))
			title.Size = UDim2.fromOffset(math.min(620, size.X - 160), if phone then 44 else 58)
			title.TextSize = if phone then 18 else 24
			title.Visible = true
			local key = ""
			local button: GuiObject? = nil
			if stage == 0 then
				if info.training then
					title.Text = "Train on the field: " .. tostring(math.floor(d.tutorialSkill or 0)) .. " / 30 Skill"
				else
					title.Text, key = "Walk onto the first training field", "Train"
				end
			elseif stage == 1 then
				key = "Kick"
				title.Text = if info.training
					then "Leave the field and follow the arrows to KICK"
					else "Go to the yellow zone and KICK your ball"
				if info.canThrow and not info.training then
					key = ""
					button = context.throwButton
					title.Text = "Press KICK, then time your power and accuracy"
				end
				if context.timing() then
					button = nil
					title.Text = "Click / tap or press Space to lock each meter"
				end
			elseif stage == 2 then
				local cost = Config.find(Config.Stones, "Smooth").cost
				if d.wins < cost and not d.stones.Smooth then
					key = "Kick"
					title.Text = "Kick to earn "
						.. Config.format(cost)
						.. " Wins for your first better ball ("
						.. Config.format(d.wins)
						.. ")"
					if info.canThrow and not info.training and not context.timing() then
						button = context.throwButton
						key = ""
					end
				else
					key = "Ball"
					local ballName = Config.find(Config.Stones, "Smooth").name
					title.Text = if d.stones.Smooth
						then "Open Balls and select " .. ballName .. " to continue"
						else "Buy " .. ballName .. " for " .. Config.format(cost) .. " Wins to train faster"
					if panel == "Inventory" then
						key = ""
						local selected = false
						local collector = player.PlayerGui:FindFirstChild("CollectorUI")
						if collector then
							local details = collector:FindFirstChild("BallDetails", true)
							if details then
								for _, node in details:GetDescendants() do
									if
										node:IsA("TextLabel")
										and node.Text == Config.find(Config.Stones, "Smooth").name
									then
										selected = true
										break
									end
								end
							end
						end
						button = findButton(if selected then { "EquipBall" } else { "BallCardSmooth" }, now)
					end
				end
			elseif stage == 3 then
				local cost = Config.find(Config.Eggs, "Common").cost
				if d.wins < cost then
					key = "Kick"
					title.Text = "Earn "
						.. Config.format(cost)
						.. " Wins to hatch your first pet ("
						.. Config.format(d.wins)
						.. ")"
					if info.canThrow and not info.training and not context.timing() then
						button = context.throwButton
						key = ""
					end
				else
					key = "Egg"
					title.Text = "Hatch a Common Egg for " .. Config.format(cost) .. " Wins"
					if panel == "Common Egg" then
						key = ""
						button = findButton({ "Hatch" }, now)
					end
				end
			elseif stage == 4 then
				title.Text = "Open Pets and Equip Best to boost your training"
				button = findButton(
					if panel == "Pets"
						then { "HatchTap", "HatchContinue", "EquipBest" }
						else { "HatchTap", "HatchContinue", "NavPets" },
					now
				)
			end
			if hasSeenShot and not summaryDismissed and not panel and not context.timing() then
				summary.Position = UDim2.fromScale(0.5, 0.48)
				local scale = summary:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
				scale.Scale = math.min(1, (size.X - 120) / 500, (size.Y - 140) / 184)
				scale.Parent = summary
				summary.Visible = true
				return
			end
			if button and visible(button) and not context.timing() then
				hand.Position = UDim2.fromOffset(
					math.clamp(
						button.AbsolutePosition.X + button.AbsoluteSize.X * 0.65 - safe.AbsolutePosition.X,
						32,
						size.X - 32
					),
					math.clamp(
						button.AbsolutePosition.Y
							+ button.AbsoluteSize.Y
							- safe.AbsolutePosition.Y
							- 5
							+ (if d.settings.effects then math.sin(now * 5) * 5 else 0),
						0,
						size.Y - 60
					)
				)
				hand.Visible = true
			end
			if panel or key == "" or context.timing() then
				return
			end
			local map = workspace:FindFirstChild("Map")
			local arena = map and map:FindFirstChild(if d.world == 2 then "World2" else "World1")
			local goal = arena and target(arena, key, now)
			if not goal then
				return
			end
			local destination = goal.Position
			if key == "Train" or key == "Kick" then
				local localRoot = goal.CFrame:PointToObjectSpace(root.Position)
				destination = goal.CFrame:PointToWorldSpace(
					Vector3.new(
						math.clamp(localRoot.X, -goal.Size.X / 2 + 3, goal.Size.X / 2 - 3),
						goal.Size.Y / 2 + 1.2,
						math.clamp(localRoot.Z, -goal.Size.Z / 2 + 3, goal.Size.Z / 2 - 3)
					)
				)
			end
			local start = root.Position - Vector3.new(0, 1, 0)
			arrows:setSource(start)
			arrows:setTarget(destination)
			arrows:setEnabled(true)
			arrows:update(now, d.settings.effects == false)
		end,
		destroy = function()
			arrows:destroy()
			gui:Destroy()
		end,
	}
end

return Guide
