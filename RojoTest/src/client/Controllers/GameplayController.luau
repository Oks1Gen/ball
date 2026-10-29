--!strict
local Controller = {}
function Controller:Init(_context: any) end
function Controller:Start()
	local clientRoot = script.Parent.Parent
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local Lighting = game:GetService("Lighting")
	local ProximityPrompts = game:GetService("ProximityPromptService")
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
	local TrainingMotion = require(ReplicatedStorage.Shared:WaitForChild("TrainingMotion"))
	local TrainingShot = require(clientRoot.Modules:WaitForChild("TrainingShot"))
	local KickAnimation = require(clientRoot:WaitForChild("KickAnimation"))
	local FlightVisuals = require(clientRoot:WaitForChild("FlightVisuals"))
	local Snapshot = require(clientRoot.Modules:WaitForChild("Snapshot"))
	local GuiInsets = require(clientRoot.Modules:WaitForChild("GuiInsets"))
	local HudLayout = require(clientRoot.Modules:WaitForChild("HudLayout"))
	local Presentation = require(clientRoot.Modules:WaitForChild("UiPresentation"))
	local Kit = require(clientRoot.Controllers:WaitForChild("HudKit"))
	local HudBuilder = require(clientRoot.Controllers:WaitForChild("HudBuilder"))
	local TopbarControls = require(clientRoot.Controllers:WaitForChild("TopbarControls"))
	local HudMotion = require(clientRoot.Controllers:WaitForChild("HudMotion"))
	local MotionConfig = require(ReplicatedStorage.Shared:WaitForChild("UiMotionConfig"))
	local HudPanels = require(clientRoot.Controllers:WaitForChild("HudPanels"))
	local PetFollowers = require(clientRoot.Controllers:WaitForChild("PetFollowers"))
	local InputController = require(clientRoot.Controllers:WaitForChild("InputController"))
	local AudioEffects = require(clientRoot.Controllers:WaitForChild("AudioEffects"))
	local LevelUpEffects = require(clientRoot.Controllers:WaitForChild("LevelUpEffects"))
	local GoalImpactEffects = require(clientRoot.Controllers:WaitForChild("GoalImpactEffects"))
	local TrainingBoost = require(clientRoot.Controllers:WaitForChild("TrainingBoost"))
	local BallHolder = require(clientRoot.Controllers:WaitForChild("BallHolder"))
	local WorldVisuals = require(clientRoot.Controllers:WaitForChild("WorldVisuals"))
	task.spawn(function()
		require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VolcanicEggVisual")).start()
	end)
	task.spawn(function()
		game:GetService("ContentProvider"):PreloadAsync({ ReplicatedStorage.Shared:WaitForChild("PetTemplates") })
	end)
	local player = Players.LocalPlayer
	local remotes = require(ReplicatedStorage.Shared:WaitForChild("Net")).client()
	local function remote(name: string): RemoteEvent
		local node = remotes:WaitForChild(name)
		if node and node:IsA("RemoteEvent") then
			return node
		end
		error("Missing gameplay remote: " .. name)
	end
	local action = remote("Action")
	local update = remote("Update")
	local effect = remote("Effect")
	local C = Color3.fromRGB
	local yellow = C(255, 225, 66)
	local latest: any = nil
	local currentPanel: string? = nil
	local topbar: any = nil
	local flight: any = nil
	local trainingShot: any = nil
	local hatchBusy = false
	local hatchPromptState: boolean? = nil
	local activeEgg = "Common"
	local collectorUI: any = nil
	local adminUI: any = nil
	local panels: any = nil
	local kickTiming: any = nil
	local openPanel: (string) -> () = function() end

	local function send(command: string, value: any?, extra: any?)
		if command == "Throw" and kickTiming then
			kickTiming.request()
			return
		end
		if player:GetAttribute("MapIntroActive") and command ~= "Snapshot" then
			return
		end
		action:FireServer(command, value, extra)
	end

	-- The HUD lives on a probe frame that reports the area the engine really
	-- granted, so the board never reaches into the notch or the gesture bar.
	local gui = Instance.new("ScreenGui")
	gui.Name = "SkippingHUD"
	GuiInsets.prepare(gui)
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 20
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	local probe = Instance.new("Frame")
	probe.Name = "SafeArea"
	probe.Size = UDim2.fromScale(1, 1)
	probe.BackgroundTransparency = 1
	probe.Parent = gui
	local canvas = Instance.new("Frame")
	canvas.Name = "Canvas"
	canvas.AnchorPoint = Vector2.new(0.5, 0.5)
	canvas.Position = UDim2.fromScale(0.5, 0.5)
	canvas.Size = UDim2.fromOffset(1280, 720)
	canvas.BackgroundTransparency = 1
	canvas.Parent = probe
	local scale = Instance.new("UIScale")
	scale.Parent = canvas
	local blur = Instance.new("BlurEffect")
	blur.Name = "SkippingMenuBlur"
	blur.Size = 0
	blur.Parent = Lighting

	local effectsFolder = Instance.new("Folder")
	effectsFolder.Name = "SkippingClientEffects"
	effectsFolder.Parent = workspace

	local hudRefs = HudBuilder.build({
		canvas = canvas,
		send = send,
		openPanel = function(name: string)
			openPanel(name)
		end,
		snapshot = function()
			return latest
		end,
	})
	local hud = hudRefs.hud
	local hudMotion = HudMotion.mount(hud, canvas, scale)
	local blurTween: Tween? = nil
	local levelTween: Tween? = nil
	local notifications: any = nil
	local function syncPresentation()
		local modal = currentPanel ~= nil
		local reduced = latest ~= nil and latest.data.settings.effects == false
		if notifications then
			notifications.setReduced(reduced)
		end
		if topbar then
			topbar.setHidden(modal, latest and latest.data.settings.effects == false)
		end
		if modal and kickTiming and kickTiming.active() then
			kickTiming.cancel()
		end
		hud.Visible = true
		hudMotion.setHidden(modal, latest and latest.data.settings.effects == false)
		if collectorUI then
			collectorUI:setModalOpen(modal)
		end
		if adminUI then
			adminUI.setIndicatorHidden(modal)
		end
		local goal = if modal then MotionConfig.Blur.Size else 0
		if blur:GetAttribute("Goal") ~= goal or reduced then
			if blurTween then
				blurTween:Cancel()
			end
			blur:SetAttribute("Goal", goal)
			blurTween = nil
			if reduced then
				blur.Size = goal
			else
				local tween = TweenService:Create(blur, TweenInfo.new(MotionConfig.Blur.Time), { Size = goal })
				blurTween = tween
				tween:Play()
			end
		end
	end

	local layout =
		{ mode = "landscape", portrait = false, width = 1280, height = 720, levelWidth = 592, levelHeight = 61 }
	local pins = HudLayout.pins(HudLayout.landscape(), hud)
	local measured = Vector2.zero
	-- The probe reports the granted rectangle only after the engine runs its
	-- first layout pass. The first real measurement therefore only sets the
	-- orientation, it never switches it, so no panel is closed on startup.
	local orientationKnown = false

	local function closePanel(switching: boolean?, onClosed: (() -> ())?)
		if currentPanel == "Offline" and not switching and latest and not latest.welcome.claimed then
			return
		end
		if hatchPromptState ~= nil then
			ProximityPrompts.Enabled = hatchPromptState
			hatchPromptState = nil
		end
		if collectorUI then
			collectorUI:close()
			collectorUI:setHidden(false)
		end
		if adminUI then
			adminUI.close()
		end
		currentPanel = nil
		panels.close(onClosed)
		hatchBusy = false
		if not switching then
			syncPresentation()
		end
	end

	panels = HudPanels.mount({
		canvas = canvas,
		send = send,
		snapshot = function()
			return latest
		end,
		closePanel = closePanel,
		showPanel = function(name: string)
			currentPanel = name
			syncPresentation()
		end,
		finishWelcome = function()
			closePanel(true, function()
				if currentPanel == nil and latest and latest.dailyReward.ready then
					panels.open("Daily")
				else
					syncPresentation()
				end
			end)
		end,
	})

	-- Landscape keeps the wide board, portrait rebuilds the same elements as a
	-- narrow column with the primary buttons at the bottom of the screen.
	local function applyLayout()
		local camera = workspace.CurrentCamera
		local viewport = camera.ViewportSize
		local area = GuiInsets.area(viewport, probe)
		local granted = probe.AbsoluteSize
		local portrait = area.size.X < area.size.Y
		if not orientationKnown then
			layout.portrait = portrait
			if granted.X > 0 and granted.Y > 0 then
				orientationKnown = true
			end
		elseif portrait ~= layout.portrait then
			layout.portrait = portrait
			closePanel()
		end
		layout.mode = if portrait then "portrait" else "landscape"
		layout.width = area.size.X
		layout.height = area.size.Y
		local spec = if portrait then HudLayout.portrait(area.size.X, area.size.Y) else HudLayout.landscape()
		local phone = game:GetService("UserInputService").TouchEnabled and area.size.Y < 520
		if not portrait and phone then
			spec = HudLayout.phoneLandscape(math.min(area.size.X / 1280, area.size.Y / 720), area.size.X)
		end
		hudMotion.layout(phone)
		HudLayout.apply(spec, { hud, canvas })
		-- Scale the entire offer, including its artwork, price and hover motion.
		for _, name in { "StarterPack", "DoubleSkill", "DoubleWins" } do
			local offer = HudLayout.findNode(hud, name)
			local base = if phone or portrait then 1 else 1.4
			if offer then
				offer:SetAttribute("RestScale", base)
				local motion = offer:FindFirstChild("RestScale")
				if not motion then
					local resting = Instance.new("UIScale")
					resting.Name = "RestScale"
					resting.Parent = offer
					motion = resting
				end
				if motion and motion:IsA("UIScale") then
					motion.Scale = base
				end
			end
			local shadow = HudLayout.findNode(hud, name .. "Shadow")
			if shadow then
				local motion = shadow:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
				motion.Scale = base
				motion.Parent = shadow
			end
		end
		local level = spec.elements["LevelBar"]
		layout.levelWidth = level.w
		layout.levelHeight = level.h
		if portrait then
			scale.Scale = 1
			canvas.Size = UDim2.fromOffset(area.size.X, area.size.Y)
			canvas.Position = UDim2.fromOffset(area.offset.X + area.size.X / 2, area.offset.Y + area.size.Y / 2)
		else
			local factor = math.max(0.01, math.min(area.size.X / 1280, area.size.Y / 720))
			scale.Scale = factor
			canvas.Size = UDim2.fromOffset(1280, 720)
			-- The canvas is anchored in its middle, so the board is centred
			-- inside the granted rectangle.
			canvas.Position = UDim2.fromOffset(area.offset.X + area.size.X / 2, area.offset.Y + area.size.Y / 2)
			local gutter = (area.size.X / factor - 1280) / 2
			local margin = 16 / factor
			pins = HudLayout.pins(spec, hud)
			for _, pin in pins do
				local x = pin.side == "left" and (-gutter + margin + pin.offset)
					or (1280 + gutter - margin + pin.offset)
				local position = pin.node.Position
				pin.node.Position = UDim2.new(0, x, position.Y.Scale, position.Y.Offset)
			end
		end
		-- TextScaled constraints cap physical pixels, so they must follow the
		-- board and the larger side offers as well as their containing plates.
		for _, label in hud:GetDescendants() do
			if label:IsA("TextLabel") then
				local limit = label:FindFirstChildOfClass("UITextSizeConstraint")
				if limit then
					local extra = 1
					local ancestor = label.Parent
					while ancestor and ancestor ~= hud do
						local rest = ancestor:GetAttribute("RestScale")
						if typeof(rest) == "number" then
							extra *= rest
						end
						ancestor = ancestor.Parent
					end
					local factor = scale.Scale * extra
					limit.MinTextSize = 1
					limit.MaxTextSize = math.max(1, math.floor(label.TextSize * factor))
					limit.MinTextSize = math.min(limit.MaxTextSize, math.max(1, math.floor(10 * factor)))
				end
			end
		end
		hudMotion.refresh()
		panels.layout()
	end

	local function notice(message: string?, kind: string?, wins: number?, distance: number?)
		if notifications then
			notifications.show(message, kind, wins, distance)
		end
	end

	local function openCollector(name: string, kind: string, eggId: string?)
		local inventoryTab = kind == "Pets" or kind == "Eggs" or kind == "Inventory"
		if not (inventoryTab and collectorUI:isInventoryOpen()) then
			closePanel(true)
		end
		currentPanel = name
		syncPresentation()
		collectorUI:setHidden(false)
		collectorUI:open(kind, eggId)
	end

	local function openEgg(id: string)
		local egg = Config.find(Config.Eggs, id)
		if not egg then
			return
		end
		activeEgg = id
		openCollector(egg.name, "Eggs", id)
	end

	collectorUI = require(clientRoot.CollectorUI).mount({
		send = send,
		close = closePanel,
		open = function(name: string)
			if name == "Eggs" and currentPanel == Config.find(Config.Eggs, activeEgg).name then
				closePanel()
			else
				openPanel(name)
			end
		end,
		selectEgg = function(id: string)
			activeEgg = id
			currentPanel = Config.find(Config.Eggs, id).name
		end,
	})

	openPanel = function(name: string)
		if currentPanel == name then
			closePanel()
			return
		end
		if name == "Eggs" then
			openEgg(activeEgg)
			return
		end
		if name == "Trails" then
			openCollector("Trails", "Trails")
		elseif name == "Settings" then
			panels.open("Settings")
		elseif name == "UpdateLog" then
			panels.open("UpdateLog")
		elseif name == "Dev" then
			if adminUI then
				adminUI.open()
			end
		elseif name == "Rebirth" then
			panels.open("Rebirth")
		elseif name == "Inventory" then
			openCollector("Inventory", "Inventory")
		elseif name == "Pets" then
			openCollector("Pets", "Pets")
		elseif name == "Gifts" then
			panels.open("Gifts")
		elseif name == "Daily" then
			panels.open("Daily")
		elseif name == "Shop" then
			openCollector("Shop", "Shop")
		end
	end

	topbar = TopbarControls.mount(player, function(name: string)
		openPanel(name)
	end)

	applyLayout()
	local viewportConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout)
	probe:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyLayout)

	local effects = AudioEffects.mount({
		canvas = canvas,
		distanceLabel = hudRefs.distanceText,
		effectsFolder = effectsFolder,
		snapshot = function()
			return latest
		end,
		panelOpen = function()
			return currentPanel ~= nil
		end,
	})
	local levelUp = LevelUpEffects.mount({
		player = player,
		effectsFolder = effectsFolder,
		snapshot = function()
			return latest
		end,
		playSound = effects.playSound,
		blocked = function()
			return flight ~= nil or player:GetAttribute("MapIntroActive") == true
		end,
	})
	notifications = require(clientRoot.Controllers.Notifications).mount({
		parent = player:WaitForChild("PlayerGui"),
		snapshot = function()
			return latest
		end,
		playSound = effects.playSound,
	})
	local followers = PetFollowers.mount({
		effectsFolder = effectsFolder,
		effects = function()
			return latest == nil or latest.data.settings.effects
		end,
	})
	local balls = BallHolder.mount()
	local world = WorldVisuals.mount({
		ownedBalls = function()
			return latest and latest.data.stones
		end,
		rebirths = function()
			return latest and latest.data.rebirths
		end,
		effects = function()
			return latest == nil or latest.data.settings.effects
		end,
	})
	local goalEffects = GoalImpactEffects.mount({
		folder = effectsFolder,
		enabled = function()
			return latest == nil or latest.data.settings.effects ~= false
		end,
	})
	local trainingBoost = TrainingBoost.mount({
		skillLabel = hudRefs.skillText,
		playSound = effects.playSound,
		folder = effectsFolder,
		snapshot = function()
			return latest
		end,
		blocked = function()
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			return currentPanel ~= nil
				or flight ~= nil
				or player:GetAttribute("MapIntroActive") == true
				or not hum
				or hum.Health <= 0
		end,
		send = send,
	})
	kickTiming = require(clientRoot.Controllers.KickTiming).mount({
		snapshot = function()
			return latest
		end,
		canStart = function()
			return latest ~= nil
				and latest.canThrow
				and not latest.training
				and not flight
				and currentPanel == nil
				and not player:GetAttribute("MapIntroActive")
		end,
		canContinue = function()
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			return latest ~= nil
				and latest.canThrow
				and not latest.training
				and not flight
				and currentPanel == nil
				and hum ~= nil
				and hum.Health > 0
				and not player:GetAttribute("MapIntroActive")
		end,
		send = function(command: string, value: any?, extra: any?)
			action:FireServer(command, value, extra)
		end,
	})
	local input = InputController.mount({
		player = player,
		send = send,
		openPanel = function(name: string)
			openPanel(name)
		end,
		closePanel = closePanel,
		panel = function()
			return currentPanel
		end,
		clearHatch = function()
			hatchBusy = false
		end,
		snapshot = function()
			return latest
		end,
		activeEgg = function()
			return activeEgg
		end,
		eggName = function(id: string)
			local egg = Config.find(Config.Eggs, id)
			return egg and egg.name or ""
		end,
		hatch = function(id: string, count: number)
			collectorUI:request("Hatch", id, count)
		end,
	})

	local tutorial = require(clientRoot.Controllers.Tutorial).mount({
		snapshot = function()
			return latest
		end,
		panel = function()
			return currentPanel
		end,
		flying = function()
			return flight ~= nil
		end,
		timing = function()
			return kickTiming.active()
		end,
		throwButton = hudRefs.throwButton,
		autoButton = hudRefs.auto,
	})

	local function beginThrow(info: any)
		KickAnimation.play(info.userId, info.startedAt or workspace:GetServerTimeNow(), info.perfectCount)
		local me = info.userId == player.UserId
		local token = {}
		if me then
			kickTiming.accepted(info.timingMultiplier or 1)
			closePanel()
			flight = token
			hudRefs.powerText.Visible = false
			collectorUI:setHidden(true)
		end
		local saved = FlightVisuals.start(info, {
			me = me,
			player = player,
			active = function()
				return flight == token
			end,
			effects = function()
				return not latest or latest.data.settings.effects
			end,
			shake = function()
				return latest and latest.data.settings.shake
			end,
			ripple = effects.ripple,
			bounce = effects.bounce,
			zone = effects.zoneTransition,
			distance = function(value: string)
				hudRefs.distanceText.Text = value
			end,
			kick = function(feedback: any)
				followers.kick()
				effects.playSound("rbxasset://sounds/action_jump.mp3", feedback.kickVolume, feedback.kickPlayback)
			end,
			finish = function()
				flight = nil
				hudRefs.distanceText.Text = ""
				hudRefs.powerText.Visible = true
			end,
		})
		token.saved = saved
	end

	local function hatchAnimation(pets: any)
		if hatchBusy then
			return
		end
		closePanel(true)
		hatchBusy = true
		hatchPromptState = ProximityPrompts.Enabled
		ProximityPrompts.Enabled = false
		currentPanel = "Hatch"
		syncPresentation()
		collectorUI:setHidden(false)
		collectorUI:hatch(pets)
	end

	effect.OnClientEvent:Connect(function(kind: string, info: any)
		if kind == "KickReady" then
			kickTiming.ready(info)
		elseif kind == "KickAccuracyReady" then
			kickTiming.accuracyReady(info)
		elseif kind == "KickCancelled" then
			kickTiming.cancel()
		elseif kind == "Throw" then
			beginThrow(info)
		elseif kind == "ShotBounce" then
			effects.floatingGain(info.gain)
		elseif kind == "Train" then
			effects.floatingGain(info.gain, info.boosted, info.multiplier)
			balls.setPractice(latest and latest.data.stone or "Pebble")
		elseif kind == "TrainingBoost" then
			trainingBoost.confirmed(info)
		elseif kind == "Result" then
			notice(
				"+" .. Config.format(info.wins) .. " WINS • " .. Config.format(info.distance) .. " m",
				"Success",
				info.wins,
				info.distance
			)
		elseif kind == "Hatch" then
			task.spawn(hatchAnimation, info)
		elseif kind == "Egg" then
			openEgg(info)
		elseif kind == "AdminEgg" then
			local modal = panels.shell("Volcanic Inferno Egg", "Egg", 620, 385)
			Kit.icon(modal, "Pets", 210, 65, 200, 195, Config.AdminPet.color)
			Kit.text(modal, "PetName", "Glitched Dragon • MYTHIC", 20, 30, 580, 37, 27, Config.AdminPet.color)
			Kit.text(modal, "Boost", "×25 Skill", 180, 252, 260, 41, 29, yellow)
			Kit.button(modal, "BuyAdmin", "Hatch • 175 Robux", 143, 312, 334, 49, C(94, 238, 22), 27, function()
				send("Product", "AdminEgg")
			end)
		elseif kind == "Open" then
			openPanel(info)
		elseif kind == "OpenBall" then
			openCollector("Inventory", "Inventory", info)
		elseif kind == "Rebirth" then
			notice("REBIRTH! Your skill multiplier increased!", "Success")
			closePanel()
			levelUp.rebirth()
		elseif kind == "AdminResetView" or kind == "ShotCancelled" then
			kickTiming.cancel()
			if flight then
				local saved = flight.saved
				if saved and saved.cancel then
					saved.cancel()
				end
				flight = nil
				-- The camera goes back to the character, the stale frame of the
				-- cancelled shot is dropped.
				FlightVisuals.releaseCamera(player, saved, saved and saved.fov or 70)
				hudRefs.distanceText.Text = ""
				hudRefs.powerText.Visible = true
			end
		elseif kind == "World" then
			notice(info == 2 and "WORLD 2 • ×3 SKILL & WINS" or "Welcome back to World 1")
		end
	end)

	update.OnClientEvent:Connect(function(payload: any)
		local info = Snapshot.apply(payload)
		latest = info
		levelUp.observe(info)
		if adminUI then
			adminUI.update(info)
		end
		topbar.setAdmin(info.isAdmin == true)
		collectorUI:update(info)
		collectorUI:setHidden(flight ~= nil)
		local d = info.data
		gui:SetAttribute("ReducedMotion", d.settings.effects == false)
		hudRefs.skillText.Text = Config.format(d.skill) .. " SKILL"
		hudRefs.multiText.Text = "×" .. string.format("%.2f", info.multiplier) .. " Multiplier"
		local gainedLevels = info.trainingLevelsGained or 0
		hudRefs.levelUpText.Text = "Level Up! [x" .. tostring(gainedLevels) .. "]"
		hudRefs.levelUpText.Visible = info.training ~= nil and gainedLevels > 0
		hudRefs.levelText.Text = "Level " .. info.level
		hudRefs.maxText.Text = info.level == Config.MaxLevel and "MAX LEVEL"
			or Config.format(d.skill - info.levelStart) .. " / " .. Config.format(info.nextLevel - info.levelStart)
		local progress = info.level == Config.MaxLevel and 1
			or math.clamp((d.skill - info.levelStart) / math.max(1, info.nextLevel - info.levelStart), 0, 1)
		if levelTween then
			levelTween:Cancel()
			levelTween = nil
		end
		if d.settings.effects == false then
			hudRefs.levelFill.Size = UDim2.fromScale(progress, 1)
		else
			local tween = TweenService:Create(hudRefs.levelFill, TweenInfo.new(0.3), {
				Size = UDim2.fromScale(progress, 1),
			})
			levelTween = tween
			tween:Play()
		end
		hudRefs.rebirthText.Text = tostring(d.rebirths)
		hudRefs.winsText.Text = Config.format(d.wins)
		hudRefs.friendText.Text = "Friend Boost +" .. info.friendBoost .. "%"
		hudRefs.powerText.Text = "HIT: "
			.. Config.format(info.shotDistance or Config.shotDistance(d.skill, 1, d.world))
			.. " m"
		hudRefs.powerText.Visible = not flight
		hudRefs.bestText.Text = d.best > 0 and "BEST: " .. Config.format(d.best) .. " m" or ""
		hudRefs.rebirthPercent.Text = math.floor((info.rebirthProgress or 0) * 100) .. "%"
		hudRefs.throwButton.Visible = info.canThrow and not flight and not info.training
		local throwShadow = HudLayout.findNode(hud, "ThrowShadow")
		if throwShadow and throwShadow:IsA("GuiObject") then
			throwShadow.Visible = hudRefs.throwButton.Visible
		end
		local autoCaption = Kit.captionOf(hudRefs.auto)
		if autoCaption then
			autoCaption.Text = info.auto and "AUTO: ON" or "AUTO KICK"
		end
		syncPresentation()
		hudRefs.tutorial.Visible = not flight
		hudRefs.tutorial.Text = Presentation.kickHint(info.canThrow, info.training ~= nil)
		if not info.training then
			balls.setPractice(nil)
		else
			balls.setPractice(d.stone)
		end
		balls.setStone(d.stone)
		panels.refresh()
		followers.refresh(Snapshot.equipped(), Snapshot.pets())
		notice(info.notice)
	end)

	effect.OnClientEvent:Connect(function(kind: string)
		if kind == "Hatch" then
			effects.playSound("rbxasset://sounds/volume_slider.ogg", 0.25, 1.4)
		end
	end)

	adminUI = require(clientRoot.AdminPanel).mount({
		closePanel = closePanel,
		activate = function()
			closePanel(true)
			currentPanel = "Admin"
			syncPresentation()
		end,
	})

	local appliedSoundVolume = -1
	local appliedMusicVolume = -1
	local welcomeShown = false

	RunService.RenderStepped:Connect(function(dt: number)
		local now = os.clock()
		if
			not welcomeShown
			and latest
			and latest.welcome
			and player:GetAttribute("MapIntroActive") == false
			and not currentPanel
			and not flight
		then
			welcomeShown = true
			if not latest.welcome.claimed then
				panels.open("Offline")
			end
		end
		-- The safe area is only known after the first layout pass, so the
		-- board is rebuilt whenever the granted rectangle changes. A zero
		-- measurement means the probe is not laid out yet, it is ignored.
		local granted = probe.AbsoluteSize
		if granted.X > 0 and granted.Y > 0 and granted ~= measured then
			measured = granted
			applyLayout()
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		world.frame()
		local hand = player.Character
			and (player.Character:FindFirstChild("RightHand") or player.Character:FindFirstChild("Right Arm"))
		if hand and latest then
			balls.held():PivotTo(hand.CFrame * CFrame.new(0, -0.4, -0.2))
		end
		balls.showHeld(hand ~= nil and latest ~= nil and not flight and not latest.training)
		followers.update(root, now)
		local practice = balls.practice()
		if practice and latest and latest.training and root then
			local lane = world.lane(latest.data.world, latest.training)
			local started = player.Character:GetAttribute("TrainingStarted") or latest.trainingStarted
			if lane and started then
				local elapsed = math.max(0, workspace:GetServerTimeNow() - started)
				local phase = elapsed % Config.TrainingCycle
				local seed = player.Character:GetAttribute("TrainingSeed")
					or latest.trainingSeed
					or math.floor(started * 1000) % 2147483647
				trainingShot = TrainingShot.update(trainingShot, lane, root.Position, seed, elapsed, started)
				local shot = trainingShot.shot
				if shot then
					local position = TrainingMotion.position(shot.start, shot.finish, phase, latest.training)
					local boosted = trainingBoost.frame(trainingShot, elapsed, position)
					goalEffects.training(
						lane,
						shot.start,
						shot.finish,
						elapsed,
						latest.training,
						started,
						shot.seed,
						boosted
					)
					local distance = (position - shot.start).Magnitude
					local facing = shot.finish - shot.start
					practice:PivotTo(CFrame.lookAt(position, position + facing) * CFrame.Angles(distance / 0.8, 0, 0))
				end
				if not shot then
					trainingBoost.clear()
				end
				balls.showPractice(shot ~= nil and phase < 1.15)
			else
				trainingBoost.clear()
			end
		else
			trainingShot = nil
			trainingBoost.clear()
			goalEffects.clearTraining()
		end
		if latest then
			local timingActive = kickTiming.active()
			hudRefs.throwButton.Visible = latest.canThrow and not flight and not latest.training and not timingActive
			local throwShadow = HudLayout.findNode(hud, "ThrowShadow")
			if throwShadow and throwShadow:IsA("GuiObject") then
				throwShadow.Visible = hudRefs.throwButton.Visible
			end
			hudRefs.tutorial.Visible = not flight and not timingActive
			hudRefs.tutorial.Text = Presentation.kickHint(latest.canThrow, latest.training ~= nil)
			local soundVolume = latest.data.settings.sound / 100
			local musicVolume = latest.data.settings.music / 100
			if soundVolume ~= appliedSoundVolume or musicVolume ~= appliedMusicVolume then
				appliedSoundVolume = soundVolume
				appliedMusicVolume = musicVolume
				effects.applyVolumes(soundVolume, musicVolume)
			end
		end
		levelUp.frame(dt)
		tutorial.frame(now)
	end)

	player.CharacterAdded:Connect(function()
		kickTiming.cancel()
		trainingBoost.clear()
		if flight then
			local saved = flight.saved
			flight = nil
			-- The character respawned during the shot: the camera follows the
			-- new one instead of staying at the ball.
			FlightVisuals.releaseCamera(player, saved, saved and saved.fov or 70)
			hudRefs.distanceText.Text = ""
		end
	end)

	clientRoot.Destroying:Connect(function()
		tutorial.destroy()
		kickTiming.destroy()
		viewportConnection:Disconnect()
		input.destroy()
		levelUp.destroy()
		goalEffects.destroy()
		trainingBoost.destroy()
		followers.destroy()
		notifications.destroy()
		effects.destroy()
		balls.destroy()
		world.destroy()
		if adminUI then
			adminUI.destroy()
		end
		collectorUI:destroy()
		panels.destroy()
		hudMotion.destroy()
		topbar.destroy()
		if blurTween then
			blurTween:Cancel()
		end
		if levelTween then
			levelTween:Cancel()
		end
		blur:Destroy()
	end)

	send("Snapshot")
	print("StoneSkipping HUD ready")
end
return Controller
