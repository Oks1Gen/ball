--!strict
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Aura = require(script.Parent:WaitForChild("EggAura"))
local Display = {}
local TAG = "FloatingDisplayEgg"
local C = Color3.fromRGB

-- Particle textures also used by TrailThemes. Each egg emits from a slow orbit.
local THEMES = {
	Meadow = {
		name = "Fireflies",
		texture = 9997556038,
		bright = C(222, 255, 128),
		faded = C(117, 231, 69),
		rate = 4,
		size = 0.45,
		rise = 0.8,
		phase = 0,
		accent = { name = "FallingLeaves", texture = 7096972007, rate = 6, size = 0.94, rise = -3.1, height = 8.2 },
	},
	Glacier = {
		name = "IceFlakes",
		texture = 10439119562,
		bright = C(235, 255, 255),
		faded = C(73, 218, 255),
		rate = 4,
		size = 0.52,
		rise = -0.8,
		phase = 1.2,
		accent = { name = "CrystalFlurry", texture = 8037777212, rate = 6, size = 0.76, rise = -1.25, height = 6.6 },
	},
	Celestial = {
		name = "SolarStars",
		texture = 4963436775,
		bright = C(255, 250, 198),
		faded = C(255, 186, 54),
		rate = 12,
		size = 0.86,
		rise = 0.65,
		phase = 2.4,
		accent = { name = "CrownStarOrbit", texture = 4963436775, rate = 16, size = 1.15, rise = 0.25, height = 6 },
	},
	Magma = {
		name = "Embers",
		texture = 9997556038,
		bright = C(255, 214, 98),
		faded = C(255, 74, 24),
		rate = 5,
		size = 0.44,
		rise = 1.45,
		phase = 3.6,
		accent = { name = "RisingCinders", texture = 10439119562, rate = 9, size = 0.65, rise = 3.4, height = 2.1 },
	},
	Void = {
		name = "VoidSparks",
		texture = 10598374841,
		bright = C(223, 161, 255),
		faded = C(129, 66, 255),
		rate = 5,
		size = 0.56,
		rise = 0.25,
		phase = 4.8,
		accent = { name = "VoidShards", texture = 8037777212, rate = 8, size = 0.86, rise = 0.55, height = 5.8 },
	},
}

THEMES.Kelp = {
	name = "GoldenPlankton",
	texture = 9997556038,
	bright = C(255, 220, 110),
	faded = C(60, 199, 155),
	rate = 4,
	size = 0.4,
	rise = 0.6,
	phase = 0,
	accent = { name = "DriftingKelp", texture = 7096972007, rate = 5, size = 0.8, rise = -0.8, height = 6 },
}
THEMES.Leviathan = {
	name = "ScaleGlints",
	texture = 4963436775,
	bright = C(255, 215, 84),
	faded = C(35, 217, 230),
	rate = 5,
	size = 0.5,
	rise = 0.4,
	phase = 1.2,
	accent = { name = "OceanCrown", texture = 8037777212, rate = 5, size = 0.7, rise = 0.7, height = 7 },
}
THEMES.Treasure = {
	name = "GoldDust",
	texture = 9997556038,
	bright = C(255, 224, 128),
	faded = C(224, 168, 46),
	rate = 5,
	size = 0.4,
	rise = 0.6,
	phase = 2.4,
	accent = { name = "GemGlints", texture = 4963436775, rate = 6, size = 0.7, rise = 0.35, height = 5 },
}
THEMES.Abyss = {
	name = "DeepSeaMotes",
	texture = 10598374841,
	bright = C(35, 217, 246),
	faded = C(88, 72, 155),
	rate = 4,
	size = 0.5,
	rise = 0.3,
	phase = 3.6,
	accent = { name = "AbyssShards", texture = 8037777212, rate = 5, size = 0.8, rise = 0.5, height = 5.5 },
}
THEMES.Jelly = {
	name = "JellyGlow",
	texture = 9997556038,
	bright = C(85, 235, 255),
	faded = C(194, 130, 255),
	rate = 6,
	size = 0.5,
	rise = 0.8,
	phase = 4.8,
	accent = { name = "BioluminescentStars", texture = 4963436775, rate = 7, size = 0.85, rise = 0.55, height = 6.5 },
}

local function particleSize(size: number): NumberSequence
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.22, size),
		NumberSequenceKeypoint.new(1, size * 0.35),
	})
end

type Entry = {
	base: CFrame,
	phase: number,
	scale: number,
	source: Part,
	emitters: { ParticleEmitter },
	accent: Attachment,
	accentHeight: number,
	shell: Highlight,
	caption: BillboardGui?,
	aura: { plane: Part, update: (boolean, number, number) -> () },
}

function Display.mount(folder: Folder, effectsEnabled: () -> boolean)
	local entries: { [Model]: Entry } = {}
	local function add(instance: Instance)
		if not instance:IsA("Model") or entries[instance] or not instance:IsDescendantOf(workspace) then
			return
		end
		local theme = instance:GetAttribute("ElementalEggTheme")
		local spec = if typeof(theme) == "string" then THEMES[theme] else nil
		if not spec then
			return
		end
		local effectScale = instance:GetAttribute("DisplayEffectScale")
		local scale = if typeof(effectScale) == "number" then effectScale else instance:GetScale()
		local source = Instance.new("Part")
		source.Name = spec.name
		source.Size = Vector3.one * 0.1
		source.Transparency = 1
		source.Anchored = true
		source.CanCollide, source.CanTouch, source.CanQuery = false, false, false
		source.CastShadow = false
		source.CFrame = instance:GetPivot()
		source.Parent = folder
		local forge = game.ReplicatedStorage:FindFirstChild("OceanEggVFX")
		local recipe = forge and forge:FindFirstChild(theme :: string)
		local forgeEmitters: { ParticleEmitter } = {}
		if recipe then
			for _, node in recipe:GetChildren() do
				local copy = node:Clone()
				copy.Parent = source
				for _, child in copy:GetDescendants() do
					if child:IsA("ParticleEmitter") then
						child.Enabled = false
						table.insert(forgeEmitters, child)
					end
				end
			end
		end

		local emitter = Instance.new("ParticleEmitter")
		emitter.Enabled = false
		emitter.Texture = "rbxassetid://" .. spec.texture
		emitter.Color = ColorSequence.new(spec.bright, spec.faded)
		emitter.Rate = spec.rate
		emitter.Lifetime = NumberRange.new(1.1, 1.65)
		emitter.Speed = NumberRange.new(0.45, 1.05)
		emitter.SpreadAngle = Vector2.new(45, 45)
		emitter.Acceleration = Vector3.new(0, spec.rise, 0)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-35, 35)
		emitter.LightEmission = 0.76
		emitter.Brightness = 1.45
		emitter.LightInfluence = 0.2
		emitter.Size = particleSize(spec.size * scale)
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.24, 0.12),
			NumberSequenceKeypoint.new(0.65, 0.34),
			NumberSequenceKeypoint.new(1, 1),
		})
		emitter.Parent = source
		local accentSpec = spec.accent
		local accent = Instance.new("Attachment")
		accent.Name = accentSpec.name
		accent.Parent = source
		local accentEmitter = emitter:Clone()
		accentEmitter.Name = accentSpec.name
		accentEmitter.Texture = "rbxassetid://" .. accentSpec.texture
		accentEmitter.Rate = accentSpec.rate
		accentEmitter.Size = particleSize(accentSpec.size * scale)
		accentEmitter.Acceleration = Vector3.new(0, accentSpec.rise, 0) * scale
		accentEmitter.EmissionDirection = if accentSpec.rise < 0 then Enum.NormalId.Bottom else Enum.NormalId.Top
		accentEmitter.Lifetime = if theme == "Meadow" then NumberRange.new(1.7, 2.15) else NumberRange.new(1, 1.55)
		accentEmitter.LightEmission = if theme == "Meadow" then 0.28 else 0.85
		accentEmitter.Parent = accent
		local shell = Instance.new("Highlight")
		shell.Name = "ElementalShellGlow"
		shell.Adornee = instance
		shell.DepthMode = Enum.HighlightDepthMode.Occluded
		shell.FillColor = spec.faded
		shell.OutlineColor = spec.bright
		shell.Enabled = false
		shell.Parent = source

		local base = instance:GetPivot()
		entries[instance] = {
			base = base,
			phase = spec.phase,
			scale = scale,
			source = source,
			emitters = { emitter, accentEmitter, table.unpack(forgeEmitters) },
			accent = accent,
			accentHeight = accentSpec.height,
			shell = shell,
			aura = Aura.create(folder, theme :: string, base.Position, scale),
		}
	end

	CollectionService:GetInstanceAddedSignal(TAG):Connect(add)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(instance)
		if instance:IsA("Model") then
			local entry = entries[instance]
			if entry then
				if entry.caption then
					entry.caption.StudsOffsetWorldSpace = Vector3.zero
				end
				entry.source:Destroy()
				entry.aura.plane:Destroy()
				entries[instance] = nil
			end
		end
	end)
	for _, instance in CollectionService:GetTagged(TAG) do
		add(instance)
	end

	RunService.PreRender:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local time = os.clock()
		local enabled = effectsEnabled()
		for visual, entry in entries do
			local near = (camera.CFrame.Position - entry.base.Position).Magnitude < 120
			local active = near and enabled
			local phase = time * 1.4 + entry.phase
			entry.aura.update(active, time, phase)
			if entry.shell.Enabled ~= active then
				entry.shell.Enabled = active
				for _, emitter in entry.emitters do
					emitter.Enabled = active
					if not active then
						emitter:Clear()
					end
				end
			end
			if near then
				local lift = (1.12 + 0.57 * math.sin(phase)) * entry.scale
				local pose = entry.base + Vector3.new(0, lift, 0)
				visual:PivotTo(pose * CFrame.Angles(0, 0.13 * math.sin(phase * 0.75), 0))
				if not entry.caption or not entry.caption:IsDescendantOf(workspace) then
					local stand = visual.Parent
					local anchor = stand and stand:FindFirstChild("EggSignAnchor", true)
					local caption = anchor and anchor:FindFirstChild("EggSign")
					entry.caption = if caption and caption:IsA("BillboardGui") then caption else nil
				end
				if entry.caption then
					entry.caption.StudsOffsetWorldSpace = Vector3.new(0, lift, 0)
				end
				if active then
					local orbit = time * 1.25 + entry.phase
					local offset = Vector3.new(5.25 * math.cos(orbit), 3.2 + math.sin(phase), 5.25 * math.sin(orbit))
					entry.source.Position = pose.Position + offset * entry.scale
					local counter = -time * 1.75 + entry.phase + math.pi
					local accentOffset = Vector3.new(
						4.7 * math.cos(counter),
						entry.accentHeight + 0.9 * math.sin(counter),
						4.7 * math.sin(counter)
					)
					entry.accent.WorldPosition = pose.Position + accentOffset * entry.scale
					local glow = 0.5 + 0.5 * math.sin(phase)
					entry.shell.FillTransparency = 0.95 - 0.10 * glow
					entry.shell.OutlineTransparency = 0.55 - 0.34 * glow
				end
			end
		end
	end)
end

return Display
