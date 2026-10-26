--!strict
-- Client sound and short lived world effects.
-- The music and the effect bus live here so the render loop only writes a
-- volume when the setting actually changed.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Kit = require(script.Parent.HudKit)
local ZoneSound = require(game.ReplicatedStorage.Shared.ZoneTransitionSound)
local LevelSound = require(game.ReplicatedStorage.Shared.LevelUpSound)

local Effects = {}
local C = Color3.fromRGB
local yellow = C(255, 225, 66)
local IMPACT_SOUNDS = {
	None = { asset = "action_jump_land.mp3", speed = 1.1, volume = 0.13 },
	White = { asset = "action_jump.mp3", speed = 0.8, volume = 0.12 },
	Red = { asset = "impact_explosion_03.mp3", speed = 1.65, volume = 0.18 },
	Blue = { asset = "volume_slider.ogg", speed = 1.85, volume = 0.16 },
	Purple = { asset = "volume_slider.ogg", speed = 0.7, volume = 0.16 },
	Rainbow = { asset = "volume_slider.ogg", speed = 1.35, volume = 0.13 },
}

export type Context = {
	canvas: Frame,
	distanceLabel: TextLabel?,
	effectsFolder: Folder,
	snapshot: () -> any?,
	panelOpen: () -> boolean,
}

export type Handle = {
	playSound: (string, number?, number?) -> (),
	bounce: (Vector3, string, number, number) -> (),
	ripple: (Vector3, Color3?, number?) -> (),
	floatingGain: (number, boolean?) -> (),
	zoneTransition: (any) -> (),
	applyVolumes: (number, number) -> (),
	destroy: () -> (),
}

function Effects.mount(context: Context): Handle
	local canvas = context.canvas
	local alive = true
	local lastImpact = -math.huge
	local impactAudio = Instance.new("Folder")
	impactAudio.Name = "TrailImpactAudio"
	impactAudio.Parent = context.effectsFolder
	local musicGroup = Instance.new("SoundGroup")
	musicGroup.Name = "SkippingMusic"
	musicGroup.Parent = SoundService
	local effectsGroup = Instance.new("SoundGroup")
	effectsGroup.Name = "SkippingSounds"
	effectsGroup.Parent = SoundService
	local music = Instance.new("Sound")
	music.Name = "PlayfulTropicalHouse"
	music.SoundId = Config.Music
	music.Volume = 0.12
	music.Looped = true
	music.SoundGroup = musicGroup
	music.Parent = SoundService
	music:Play()

	local function playSound(id: string, volume: number?, speed: number?)
		local snapshot = context.snapshot()
		if snapshot and snapshot.data.settings.sound == 0 then
			return
		end
		local sound = Instance.new("Sound")
		sound.SoundId = id
		sound.Volume = volume or 0.3
		sound.PlaybackSpeed = speed or 1
		sound.SoundGroup = effectsGroup
		sound.Parent = SoundService
		sound:Play()
		Debris:AddItem(sound, 3)
	end

	-- Warm notification audio without delaying the HUD or creating overlapping sounds.
	local notificationSounds = require(game.ReplicatedStorage.Shared.NotificationSounds)
	local notificationAudio = Instance.new("Folder")
	notificationAudio.Name = "NotificationAudio"
	notificationAudio.Parent = context.effectsFolder
	local preload = {}
	local zoneAudio = Instance.new("Sound")
	zoneAudio.Name = "ZoneTransitionPreload"
	zoneAudio.SoundId = ZoneSound.id
	zoneAudio.Volume = 0
	zoneAudio.Parent = notificationAudio
	table.insert(preload, zoneAudio)
	local levelAudio = Instance.new("Sound")
	levelAudio.Name = "LevelUpPreload"
	levelAudio.SoundId = LevelSound.id
	levelAudio.Volume = 0
	levelAudio.Parent = notificationAudio
	table.insert(preload, levelAudio)
	for role, entry in notificationSounds do
		local sound = Instance.new("Sound")
		sound.Name = "Notification" .. role
		sound.SoundId = entry.id
		sound.Volume = 0
		sound.Parent = notificationAudio
		table.insert(preload, sound)
	end
	task.spawn(function()
		local ok, reason = pcall(function()
			game:GetService("ContentProvider"):PreloadAsync(preload)
		end)
		if not ok and alive then
			warn("Notification audio preload failed: " .. tostring(reason))
		end
	end)

	local function bounce(position: Vector3, trailId: string, contact: number, intensity: number)
		local snapshot = context.snapshot()
		local camera = workspace.CurrentCamera
		if
			not alive
			or (snapshot and snapshot.data.settings.sound == 0)
			or (camera and (camera.CFrame.Position - position).Magnitude > 100)
			or os.clock() - lastImpact < 0.045
			or #impactAudio:GetChildren() >= 8
		then
			return
		end
		lastImpact = os.clock()
		local profile = IMPACT_SOUNDS[trailId] or IMPACT_SOUNDS.None
		local strength = math.clamp((1 - (contact - 1) / 8) * (0.75 + intensity * 0.4), 0.25, 1.2)
		local source = Instance.new("Part")
		source.Name = "TrailImpactSound"
		source:SetAttribute("TrailStyle", trailId)
		source.Anchored = true
		source.CanCollide, source.CanTouch, source.CanQuery = false, false, false
		source.Transparency = 1
		source.Size = Vector3.one * 0.1
		source.Position = position
		source.Parent = impactAudio
		Debris:AddItem(source, 1.1)
		local function note(speed: number)
			if not alive or not source.Parent then
				return
			end
			local sound = Instance.new("Sound")
			sound.Name = trailId .. "Impact"
			sound.SoundId = "rbxasset://sounds/" .. profile.asset
			sound.Volume = profile.volume * strength * 2
			sound.PlaybackSpeed = speed
			sound.SoundGroup = effectsGroup
			sound.RollOffMinDistance, sound.RollOffMaxDistance = 8, 85
			sound.RollOffMode = Enum.RollOffMode.InverseTapered
			sound.Parent = source
			if trailId == "Red" or trailId == "White" then
				local equalizer = Instance.new("EqualizerSoundEffect")
				equalizer.LowGain = trailId == "Red" and 2 or -15
				equalizer.HighGain = trailId == "Red" and -10 or 2
				equalizer.Parent = sound
			elseif trailId == "Purple" then
				local echo = Instance.new("EchoSoundEffect")
				echo.Delay, echo.Feedback, echo.WetLevel = 0.09, 0.2, -12
				echo.Parent = sound
			end
			sound:Play()
			task.delay(trailId == "White" and 0.12 or 0.3, function()
				if sound.Parent then
					TweenService:Create(sound, TweenInfo.new(0.12), { Volume = 0 }):Play()
				end
			end)
		end
		note(profile.speed * (1 + (contact % 3 - 1) * 0.035))
		if trailId == "Rainbow" then
			task.delay(0.075, function()
				note(profile.speed * 1.25)
			end)
		end
	end

	local function makePart(name: string, size: Vector3, color: Color3): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Material = Enum.Material.SmoothPlastic
		p.Parent = context.effectsFolder
		return p
	end

	local function ripple(pos: Vector3, color: Color3?, splashScale: number?)
		local snapshot = context.snapshot()
		if snapshot and not snapshot.data.settings.effects then
			return
		end
		splashScale = splashScale or 1
		local p = makePart("Splash", Vector3.new(0.1, 1, 1), color or C(220, 255, 255))
		p.Shape = Enum.PartType.Cylinder
		p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2)
		p.Transparency = 0.4
		TweenService
			:Create(
				p,
				TweenInfo.new(0.5),
				{ Size = Vector3.new(0.02, 7 * splashScale, 7 * splashScale), Transparency = 1 }
			)
			:Play()
		Debris:AddItem(p, 0.6)
	end

	local function floatingGain(gain: number, boosted: boolean?)
		if context.panelOpen() then
			return
		end
		local t = Kit.text(
			canvas,
			"SkillGain",
			"+" .. Config.format(gain) .. (if boosted then " ×2" else ""),
			560 + math.random(-100, 100),
			340,
			160,
			45,
			30,
			if boosted then Color3.fromRGB(213, 166, 255) else yellow
		)
		t.ZIndex = 25
		Kit.icon(t, "Skill", -22, 4, 30, 36)
		TweenService
			:Create(t, TweenInfo.new(0.9), { Position = t.Position - UDim2.fromOffset(0, 70), TextTransparency = 1 })
			:Play()
		Debris:AddItem(t, 1)
	end

	local zoneLabel: TextLabel? = nil
	local zoneToken = 0
	local function zoneTransition(crossing: any)
		zoneToken += 1
		local token = zoneToken
		if zoneLabel then
			zoneLabel:Destroy()
		end
		local label = Instance.new("TextLabel")
		label.Name = "ZoneTransition"
		label.AnchorPoint = Vector2.new(0.5, 0)
		local top = 148
		local distanceLabel = context.distanceLabel
		if distanceLabel then
			local scale = canvas.AbsoluteSize.Y / math.max(1, canvas.Size.Y.Offset)
			top = (distanceLabel.AbsolutePosition.Y + distanceLabel.AbsoluteSize.Y - canvas.AbsolutePosition.Y)
					/ math.max(0.001, scale)
				+ 8
		end
		label.Position = UDim2.new(0.5, 0, 0, top)
		label.Size = UDim2.new(1, -24, 0, 42)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextSize = 28
		label.TextScaled = false
		label.TextColor3 = yellow
		label.TextStrokeColor3 = C(20, 24, 40)
		label.TextStrokeTransparency = 0
		label.Text = crossing.name .. "  ·  ×" .. string.format("%.1f", crossing.multiplier) .. " WINS"
		label.ZIndex = 30
		label.Parent = canvas
		zoneLabel = label
		playSound(ZoneSound.id, ZoneSound.volume, 1 + (crossing.zone - 2) * 0.035)
		task.delay(0.65, function()
			if not alive or zoneToken ~= token then
				return
			end
			TweenService:Create(label, TweenInfo.new(0.25), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end)
		Debris:AddItem(label, 1)
	end

	return {
		playSound = playSound,
		bounce = bounce,
		ripple = ripple,
		floatingGain = floatingGain,
		zoneTransition = zoneTransition,
		applyVolumes = function(sound: number, musicVolume: number)
			effectsGroup.Volume = sound
			musicGroup.Volume = musicVolume
		end,
		destroy = function()
			alive = false
			if zoneLabel then
				zoneLabel:Destroy()
			end
			impactAudio:Destroy()
			notificationAudio:Destroy()
			music:Stop()
			music:Destroy()
			musicGroup:Destroy()
			effectsGroup:Destroy()
		end,
	}
end

return Effects
