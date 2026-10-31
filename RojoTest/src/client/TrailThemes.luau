--!strict
-- Recipes for the themed trails: flight ribbons and particles, the kick burst
-- and the bounce impact. Ids stay stable for saved profiles; names live in
-- GameConfig. Red keeps its hand-built flame flight in BallEffects.
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Kit = require(script.Parent.TrailKit)
local Shapes = require(script.Parent.BallEffectShapes)
local seq, range, colors, flat = Kit.seq, Kit.range, Kit.colors, Kit.flat
local C = Color3.fromRGB

-- Creator Store textures from the VfxForgeUltra library (see docs/trails.md).
local TEX = {
	Spark = "rbxasset://textures/particles/sparkles_main.dds",
	Glow = "rbxassetid://1075864321",
	Dot = "rbxassetid://9997556038",
	Star4 = "rbxassetid://4963436775",
	StarThin = "rbxassetid://10598374841",
	Sparkle = "rbxassetid://8037777212",
	StarFlip = "rbxassetid://11372772717",
	StarCore = "rbxassetid://1084970835",
	Rays = "rbxassetid://1084975295",
	Bubble = "rbxassetid://1084955488",
	Feather = "rbxassetid://7096972007",
	Streak = "rbxassetid://6660412891",
	RingSoft = "rbxassetid://8888098483",
	RingSpiky = "rbxassetid://8904012224",
	RingThin = "rbxassetid://6862984716",
	StreakRing = "rbxassetid://14412529554",
	Shard = "rbxassetid://10439119562",
	Arc = "rbxassetid://16676250078",
	ArcSmall = "rbxassetid://16951501423",
	Zap = "rbxassetid://16664675233",
	Bolt = "rbxassetid://13771290435",
	SpikeBurst = "rbxassetid://16954586568",
	StarFlash = "rbxassetid://16670162492",
	LightningRing = "rbxassetid://7150933366",
	Crack = "rbxassetid://16937144632",
	Splat = "rbxassetid://16937229477",
	LavaCrack = "rbxassetid://17067057050",
	Scorch = "rbxassetid://17067103637",
	Ash = "rbxassetid://16955854038",
	Fire = "rbxassetid://13818306392",
	Ember = "rbxassetid://11187840108",
	BeamWave = "rbxassetid://12781828706",
	BeamHoles = "rbxassetid://12781780964",
	BeamWisp = "rbxassetid://9541055154",
	BeamStreak = "rbxassetid://10365550877",
	Wisp = "rbxassetid://10337713824",
	WindRing = "rbxassetid://16950679789",
	WindSwirl = "rbxassetid://14494884246",
	Splash = "rbxassetid://17063077953",
	Water = "rbxassetid://16664772965",
	Blob = "rbxassetid://17086409913",
	ShockRing = "rbxassetid://17086390547",
	Crescent = "rbxassetid://17088300017",
	Smoke = "rbxassetid://16669188960",
	SmokeRing = "rbxassetid://15011478368",
	Rune = "rbxassetid://8095997435",
	Vortex = "rbxassetid://14426307916",
	Constellation = "rbxassetid://14354336687",
}

local GRID4 = Enum.ParticleFlipbookLayout.Grid4x4
local GRID2 = Enum.ParticleFlipbookLayout.Grid2x2
local ONESHOT = Enum.ParticleFlipbookMode.OneShot
local BACK = Enum.NormalId.Back
local TOP = Enum.NormalId.Top
local PARALLEL = Enum.ParticleOrientation.VelocityParallel
local UPRIGHT = Enum.ParticleOrientation.FacingCameraWorldUp
local GRAVITY = Vector3.new(0, -32, 0)
local TWO_PI = math.pi * 2

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C(255, 82, 119)),
	ColorSequenceKeypoint.new(0.2, C(255, 208, 61)),
	ColorSequenceKeypoint.new(0.4, C(99, 255, 128)),
	ColorSequenceKeypoint.new(0.6, C(67, 217, 255)),
	ColorSequenceKeypoint.new(0.8, C(145, 98, 255)),
	ColorSequenceKeypoint.new(1, C(255, 106, 230)),
})

export type Ribbon = {
	color: ColorSequence,
	width: number,
	texture: string?,
	lightEmission: number?,
	lightInfluence: number?,
	transparency: NumberSequence?,
	-- Helix strand: radius around the flight axis and spin in radians/s.
	radius: number?,
	spin: number?,
	phase: number?,
	-- Random sideways jump every frame gives a jagged lightning ribbon.
	jitter: number?,
	-- Multiplies the speed-based ribbon lifetime.
	life: number?,
}

export type Orbit = {
	count: number,
	size: Vector3,
	colors: { Color3 },
	material: Enum.Material,
	radius: number,
	speed: number,
	transparency: number,
}

export type Theme = {
	color: Color3,
	ribbons: { Ribbon },
	emitters: { Kit.Props },
	orbit: Orbit?,
	glow: { color: Color3, range: number, brightness: number, flicker: number }?,
	-- Called every `pulseEvery` seconds while the ball is visible.
	pulse: ((host: BasePart, position: Vector3, direction: Vector3) -> ())?,
	pulseEvery: number?,
	kick: { Kit.Layer },
	-- Burst the ball carries away from a fast bounce; defaults to `kick`.
	carry: { Kit.Layer }?,
	impact: (host: BasePart, center: Vector3, normal: Vector3, scale: number) -> (),
}

-- Strands seen over the bright pitch need a low `glow` to keep their hue:
-- additive colour washes out to white there.
local function helix(
	color: ColorSequence,
	width: number,
	radius: number,
	spin: number,
	phase: number,
	glow: number?
): Ribbon
	return {
		color = color,
		width = width,
		radius = radius,
		spin = spin,
		phase = phase,
		lightEmission = glow or 0.9,
		transparency = seq(0, 0.1, 1, 1),
		life = 1.2,
	}
end

local function rock(index: number): BasePart
	local piece = Instance.new("Part")
	piece.Name = "QuakeRock"
	piece.Anchored = true
	piece.CanCollide, piece.CanTouch, piece.CanQuery = false, false, false
	piece.CastShadow = false
	piece.Material = Enum.Material.Slate
	piece.Color = index % 2 == 0 and C(118, 86, 60) or C(150, 112, 78)
	piece.Size = Vector3.new(0.42, 0.34, 0.38) * (0.75 + (index % 3) * 0.2)
	return piece
end

local function iceSpikes(host: BasePart, center: Vector3, normal: Vector3, scale: number)
	local up = math.abs(normal.Y) > 0.99 and Vector3.zAxis or Vector3.yAxis
	local basis = CFrame.lookAt(center, center + normal, up)
	local count = scale < 0.5 and 4 or 7
	for i = 1, count do
		local angle = i / count * TWO_PI + math.random() * 0.4
		local outward = basis.RightVector * math.cos(angle) + basis.UpVector * math.sin(angle)
		local base = center + outward * (0.7 + math.random() * 0.5) * scale
		-- Spikes lean outwards; the part grows from its base along `axis`.
		local axis = (normal + outward * 0.55).Unit
		local height = (1.6 + math.random() * 1.2) * scale
		local spike = Instance.new("Part")
		spike.Name = "FrostSpike"
		spike.Anchored = true
		spike.CanCollide, spike.CanTouch, spike.CanQuery = false, false, false
		spike.CastShadow = false
		spike.Material = Enum.Material.Ice
		spike.Color = i % 2 == 0 and C(176, 236, 255) or C(120, 204, 255)
		spike.Transparency = 0.15
		local width = (0.32 + math.random() * 0.12) * scale
		local function frame(length: number): CFrame
			return CFrame.lookAt(base + axis * length / 2, base + axis * length + outward, outward)
				* CFrame.Angles(math.pi / 2, 0, i)
		end
		spike.Size = Vector3.new(width, 0.05, width)
		spike.CFrame = frame(0.05)
		spike.Parent = host
		TweenService:Create(spike, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = Vector3.new(width, height, width),
			CFrame = frame(height),
		}):Play()
		task.delay(0.5, function()
			if spike.Parent then
				TweenService:Create(spike, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Size = Vector3.new(width * 0.4, height * 0.3, width * 0.4),
					CFrame = frame(height * 0.3),
					Transparency = 1,
				}):Play()
			end
		end)
	end
end

local function rainbowStars(host: BasePart, center: Vector3, normal: Vector3, scale: number)
	local up = math.abs(normal.Y) > 0.99 and Vector3.zAxis or Vector3.yAxis
	local basis = CFrame.lookAt(center, center + normal, up)
	local count = scale < 0.5 and 4 or 8
	for i = 1, count do
		local angle = i / count * TWO_PI
		local outward = basis.RightVector * math.cos(angle) + basis.UpVector * math.sin(angle)
		local star = Shapes.part(host, "RainbowStar", Color3.fromHSV(i / count, 0.7, 1))
		star.Size = Vector3.one * 0.1
		star.Transparency = 1
		star.Position = center + outward * 0.4
		local gui = Instance.new("BillboardGui")
		local starSize = 1.8 * math.max(scale, 0.6)
		gui.Size = UDim2.fromScale(starSize, starSize)
		gui.LightInfluence = 0
		gui.Parent = star
		local art = Instance.new("TextLabel")
		art.BackgroundTransparency = 1
		art.Size = UDim2.fromScale(1, 1)
		art.Font = Enum.Font.GothamBlack
		art.Text = "★"
		art.TextScaled = true
		art.TextColor3 = star.Color
		art.TextStrokeColor3 = C(70, 42, 105)
		art.TextStrokeTransparency = 0.25
		art.Parent = gui
		TweenService:Create(
			star,
			TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = center + outward * 4.8 * scale + normal * (1.2 + i % 3) * scale }
		):Play()
		TweenService:Create(
			art,
			TweenInfo.new(0.65),
			{ Rotation = i % 2 == 0 and 140 or -140, TextTransparency = 1, TextStrokeTransparency = 1 }
		):Play()
	end
end

local function pebble(host: BasePart, position: Vector3, direction: Vector3)
	local side = direction:Cross(Vector3.yAxis)
	if side.Magnitude < 0.01 then
		side = Vector3.xAxis
	end
	local start = position + side.Unit * (math.random() - 0.5) * 0.9 - direction * 0.4
	local piece = rock(math.random(1, 3))
	piece.Size *= 0.55
	piece.CFrame = CFrame.new(start) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
	piece.Parent = host.Parent
	TweenService:Create(piece, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		CFrame = CFrame.new(start - Vector3.yAxis * 2.6) * CFrame.Angles(math.random() * 6, math.random() * 6, 3),
		Transparency = 1,
	}):Play()
	Debris:AddItem(piece, 0.5)
end

local Themes: { [string]: Theme } = {}

-- Gale: helix of white wind, wisps and speed lines; a swirling gust on landing.
local GALE, GALE_SKY = C(244, 251, 255), C(160, 224, 255)
Themes.White = {
	color = GALE,
	ribbons = {
		helix(colors(GALE, GALE_SKY), 0.26, 0.75, 9, 0),
		helix(colors(GALE, GALE_SKY), 0.26, 0.75, 9, math.pi),
		{ color = colors(GALE), width = 0.75, texture = TEX.BeamStreak, transparency = seq(0, 0.3, 1, 1), life = 0.8 },
	},
	emitters = {
		{
			Name = "GaleWisps",
			Texture = TEX.Wisp,
			Color = colors(GALE, GALE_SKY),
			Rate = 14,
			Lifetime = range(0.3, 0.5),
			Speed = range(1, 3),
			EmissionDirection = BACK,
			SpreadAngle = Vector2.new(25, 25),
			Size = seq(0, 0.6, 1, 2.6),
			Transparency = seq(0, 1, 0.2, 0.5, 1, 1),
			RotSpeed = range(-120, 120),
			LightEmission = 0.6,
			Drag = 2,
		},
		{
			Name = "GaleSpeedLines",
			Texture = TEX.Streak,
			Orientation = PARALLEL,
			Color = colors(GALE),
			Rate = 22,
			Lifetime = range(0.12, 0.2),
			Speed = range(14, 26),
			EmissionDirection = BACK,
			SpreadAngle = Vector2.new(10, 10),
			Size = seq(0, 0.45, 1, 0.25),
			Transparency = seq(0, 0.2, 1, 1),
			Rotation = range(90),
		},
	},
	kick = {
		{
			props = {
				Texture = TEX.Glow,
				Color = colors(GALE),
				Size = seq(0, 1.5, 1, 4),
				Lifetime = range(0.2),
				Speed = range(0.001),
				Transparency = seq(0, 0.3, 1, 1),
			},
			count = 1,
		},
		{
			props = flat({
				Texture = TEX.WindRing,
				Color = colors(GALE),
				Size = seq(0, 1, 1, 6),
				Lifetime = range(0.4),
				Transparency = seq(0, 0.3, 1, 1),
			}),
			count = 2,
		},
		{
			props = {
				Texture = TEX.Streak,
				Orientation = PARALLEL,
				Rotation = range(90),
				Color = colors(GALE),
				Size = seq(0, 0.6, 1, 0.2),
				Lifetime = range(0.15, 0.25),
				Speed = range(20, 35),
				SpreadAngle = Vector2.new(25, 25),
				EmissionDirection = TOP,
			},
			count = 10,
		},
	},
	impact = function(host, center, normal, scale)
		Kit.burst(host, center, normal, {
			{
				props = flat({
					Texture = TEX.WindRing,
					Color = colors(GALE),
					Size = seq(0, 0.8, 1, 7),
					Lifetime = range(0.45),
					Transparency = seq(0, 0.15, 1, 1),
					LightEmission = 0.7,
				}),
				count = 1,
			},
			{
				props = flat({
					Texture = TEX.WindSwirl,
					Color = colors(GALE_SKY),
					Size = seq(0, 2, 1, 5.5),
					Lifetime = range(0.55),
					Transparency = seq(0, 0.35, 1, 1),
					RotSpeed = range(260, 320),
					Brightness = 2,
				}),
				count = 1,
				lift = 0.05,
			},
			{
				props = {
					Texture = TEX.Wisp,
					Color = colors(GALE, GALE_SKY),
					Size = seq(0, 0.6, 1, 3),
					Transparency = seq(0, 1, 0.15, 0.35, 1, 1),
					Lifetime = range(0.35, 0.6),
					Speed = range(9, 16),
					Drag = 5,
					SpreadAngle = Vector2.new(80, 80),
					EmissionDirection = TOP,
					RotSpeed = range(-200, 200),
					LightEmission = 0.6,
				},
				count = 10,
			},
			{
				props = {
					Texture = TEX.Streak,
					Orientation = PARALLEL,
					Rotation = range(90),
					Color = colors(GALE),
					Size = seq(0, 0.55, 1, 0.1),
					Lifetime = range(0.2, 0.35),
					Speed = range(14, 24),
					Drag = 4,
					SpreadAngle = Vector2.new(85, 85),
					EmissionDirection = TOP,
					Transparency = seq(0, 0, 1, 1),
				},
				count = 12,
			},
		}, scale)
	end,
}

-- Tidal: a rolling water ribbon with spray; a splash crown and droplets.
local TIDE, AQUA, FOAM, DEEP = C(40, 150, 255), C(110, 232, 255), C(235, 252, 255), C(24, 104, 228)
Themes.Tidal = {
	color = AQUA,
	ribbons = {
		-- Deep blue and barely additive so the wave shows over the bright pitch.
		{
			color = colors(C(30, 130, 255), DEEP),
			width = 1.05,
			texture = TEX.BeamWave,
			lightEmission = 0.1,
			transparency = seq(0, 0, 1, 1),
		},
		{
			color = colors(FOAM),
			width = 0.35,
			texture = TEX.BeamWisp,
			lightEmission = 1,
			transparency = seq(0, 0.25, 1, 1),
			life = 0.7,
		},
		helix(colors(TIDE, DEEP), 0.17, 0.7, 7, 0, 0.3),
		helix(colors(FOAM, AQUA), 0.14, 0.7, 7, math.pi),
	},
	emitters = {
		{
			Name = "TideDroplets",
			Texture = TEX.Dot,
			Color = colors(FOAM, AQUA),
			Rate = 24,
			Lifetime = range(0.35, 0.6),
			Speed = range(2, 6),
			EmissionDirection = BACK,
			SpreadAngle = Vector2.new(40, 40),
			Acceleration = Vector3.new(0, -35, 0),
			Size = seq(0, 0.3, 1, 0.08),
			LightEmission = 0.3,
		},
		{
			Name = "TideSpray",
			Texture = TEX.Water,
			FlipbookLayout = GRID4,
			FlipbookMode = ONESHOT,
			Color = colors(TIDE, DEEP),
			Rate = 10,
			Lifetime = range(0.35, 0.45),
			Speed = range(1, 2),
			EmissionDirection = BACK,
			SpreadAngle = Vector2.new(30, 30),
			Size = seq(0, 0.6, 1, 1.6),
			Transparency = seq(0, 0.15, 1, 1),
			RotSpeed = range(-60, 60),
			LightEmission = 0.1,
		},
	},
	kick = {
		{
			props = flat({
				Texture = TEX.Splash,
				FlipbookLayout = GRID4,
				FlipbookMode = ONESHOT,
				Color = colors(FOAM),
				LightEmission = 0.4,
				Size = seq(0, 1, 1, 4),
				Lifetime = range(0.45),
			}),
			count = 1,
		},
		{
			props = {
				Texture = TEX.Dot,
				Color = colors(FOAM, AQUA),
				Size = seq(0, 0.35, 1, 0.1),
				Lifetime = range(0.35, 0.6),
				Speed = range(14, 24),
				SpreadAngle = Vector2.new(30, 30),
				EmissionDirection = TOP,
				Acceleration = GRAVITY,
			},
			count = 14,
		},
	},
	impact = function(host, center, normal, scale)
		Kit.burst(host, center, normal, {
			{
				props = flat({
					Texture = TEX.Splash,
					FlipbookLayout = GRID4,
					FlipbookMode = ONESHOT,
					Color = colors(FOAM),
					LightEmission = 0.5,
					Size = seq(0, 1, 1, 4.5),
					Lifetime = range(0.6),
				}),
				count = 1,
				lift = 0.05,
			},
			{
				-- Deep blue, not additive: the crown has to read on the bright pitch.
				props = flat({
					Texture = TEX.Splash,
					FlipbookLayout = GRID4,
					FlipbookMode = ONESHOT,
					Color = colors(DEEP),
					LightEmission = 0,
					Size = seq(0, 1.2, 1, 6),
					Lifetime = range(0.65),
				}),
				count = 1,
				delay = 0.05,
			},
			{
				props = flat({
					Texture = TEX.RingSoft,
					Color = colors(TIDE),
					LightEmission = 0,
					Size = seq(0, 1, 1, 7),
					Lifetime = range(0.5),
					Transparency = seq(0, 0.3, 1, 1),
				}),
				count = 1,
			},
			{
				props = {
					Texture = TEX.Water,
					FlipbookLayout = GRID4,
					FlipbookMode = ONESHOT,
					Color = colors(TIDE, DEEP),
					EmissionDirection = TOP,
					Speed = range(4, 8),
					SpreadAngle = Vector2.new(25, 25),
					Acceleration = Vector3.new(0, -25, 0),
					Size = seq(0, 0.8, 1, 2.2),
					Lifetime = range(0.5, 0.7),
					LightEmission = 0.1,
					RotSpeed = range(-40, 40),
				},
				count = 5,
			},
			{
				props = {
					Texture = TEX.Dot,
					Color = colors(FOAM, AQUA),
					EmissionDirection = TOP,
					Speed = range(9, 16),
					SpreadAngle = Vector2.new(50, 50),
					Acceleration = Vector3.new(0, -45, 0),
					Size = seq(0, 0.36, 1, 0.1),
					Lifetime = range(0.5, 0.8),
					LightEmission = 0.2,
				},
				count = 18,
			},
		}, scale)
	end,
}

-- Volcanic (Red): the flame flight is in BallEffects; here a lava crack,
-- scorch mark, fire fountain, embers and ash.
local FIRE, CINDER = C(255, 91, 20), C(70, 52, 46)
-- Typed apart: an optional field gives the literal no expected type to check.
local RED_CARRY: { Kit.Layer } = {
	{
		props = {
			Texture = TEX.Fire,
			FlipbookLayout = GRID4,
			FlipbookMode = ONESHOT,
			Color = colors(C(255, 214, 96), FIRE),
			EmissionDirection = TOP,
			Speed = range(2, 5),
			SpreadAngle = Vector2.new(60, 60),
			Size = seq(0, 0.6, 0.3, 2.6, 1, 0.4),
			Lifetime = range(0.3, 0.45),
			LightEmission = 0.6,
		},
		count = 6,
	},
	{
		props = {
			Texture = TEX.Ember,
			Color = colors(C(255, 232, 122), FIRE),
			EmissionDirection = TOP,
			Speed = range(8, 16),
			SpreadAngle = Vector2.new(70, 70),
			Drag = 3,
			Size = seq(0, 0.3, 1, 0),
			Lifetime = range(0.35, 0.5),
			Brightness = 2,
		},
		count = 12,
	},
}
Themes.Red = {
	color = FIRE,
	ribbons = {},
	emitters = {},
	kick = {},
	carry = RED_CARRY,
	impact = function(host, center, normal, scale)
		Kit.burst(host, center, normal, {
			{
				props = flat({
					Texture = TEX.Scorch,
					Color = colors(Color3.new()),
					LightEmission = 0,
					Size = seq(0, 6.5, 1, 6.5),
					Transparency = seq(0, 1, 0.08, 0.25, 0.7, 0.35, 1, 1),
					Lifetime = range(1.1),
				}),
				count = 1,
			},
			{
				props = flat({
					Texture = TEX.LavaCrack,
					Color = colors(C(255, 126, 36)),
					Brightness = 3,
					Size = seq(0, 4.5, 1, 6),
					Transparency = seq(0, 1, 0.12, 0, 0.6, 0.1, 1, 1),
					Lifetime = range(0.8),
				}),
				count = 1,
				lift = 0.04,
			},
			{
				props = {
					Texture = TEX.Fire,
					FlipbookLayout = GRID4,
					FlipbookMode = ONESHOT,
					Color = colors(C(255, 214, 96), FIRE),
					EmissionDirection = TOP,
					Speed = range(3, 8),
					SpreadAngle = Vector2.new(35, 35),
					Drag = 3,
					Size = seq(0, 0.4, 0.25, 2.3, 1, 0.5),
					Lifetime = range(0.4, 0.55),
					LightEmission = 0.6,
				},
				count = 8,
			},
			{
				props = {
					Texture = TEX.Ember,
					Color = colors(C(255, 232, 122), FIRE),
					EmissionDirection = TOP,
					Speed = range(10, 22),
					SpreadAngle = Vector2.new(45, 45),
					Acceleration = Vector3.new(0, -30, 0),
					Drag = 1.5,
					Size = seq(0, 0.32, 1, 0),
					Lifetime = range(0.5, 0.8),
					Brightness = 2,
				},
				count = 18,
			},
			{
				props = {
					Texture = TEX.Ash,
					FlipbookLayout = GRID4,
					FlipbookMode = ONESHOT,
					Color = colors(CINDER),
					LightEmission = 0,
					EmissionDirection = TOP,
					Speed = range(2, 5),
					SpreadAngle = Vector2.new(30, 30),
					Size = seq(0, 1, 1, 3.2),
					Transparency = seq(0, 0.3, 1, 1),
					Lifetime = range(0.7, 0.9),
				},
				count = 4,
				lift = 0.4,
			},
		}, scale)
		Kit.flash(host, FIRE, 10 * scale, 3, 0.35)
	end,
}

-- Electric: a jagged yellow bolt with arcs and sparks; a lightning strike on landing.
local VOLT, VOLT_CORE, VOLT_BLUE = C(255, 226, 64), C(255, 252, 214), C(130, 222, 255)
Themes.Electric = {
	color = VOLT,
	ribbons = {
		{
			color = colors(VOLT_CORE, VOLT),
			width = 0.3,
			jitter = 0.35,
			lightEmission = 1,
			transparency = seq(0, 0, 1, 1),
			life = 0.9,
		},
		{
			color = colors(C(255, 214, 40)),
			width = 0.95,
			texture = TEX.BeamStreak,
			lightEmission = 1,
			transparency = seq(0, 0.55, 1, 1),
			life = 0.7,
		},
		{
			color = colors(VOLT_BLUE, VOLT_CORE),
			width = 0.12,
			jitter = 0.6,
			lightEmission = 1,
			transparency = seq(0, 0.1, 1, 1),
			life = 0.6,
		},
	},
	emitters = {
		{
			Name = "VoltArcs",
			Texture = TEX.Arc,
			FlipbookLayout = GRID4,
			FlipbookMode = ONESHOT,
			Color = colors(C(255, 240, 120)),
			Rate = 20,
			Lifetime = range(0.18, 0.25),
			Speed = range(0.5, 1),
			SpreadAngle = Vector2.new(180, 180),
			Size = seq(0, 1.8, 1, 2.2),
			Brightness = 4,
		},
		{
			Name = "VoltArcsBlue",
			Texture = TEX.ArcSmall,
			FlipbookLayout = GRID2,
			FlipbookMode = ONESHOT,
			Color = colors(VOLT_BLUE),
			Rate = 12,
			Lifetime = range(0.15, 0.2),
			Speed = range(0.5, 1),
			SpreadAngle = Vector2.new(180, 180),
			Size = seq(0, 1.4, 1, 1.6),
			Brightness = 3,
		},
		{
			Name = "VoltSparks",
			Texture = TEX.Spark,
			Orientation = PARALLEL,
			Squash = seq(0, -0.6, 1, -0.6),
			Color = colors(VOLT_CORE, VOLT),
			Rate = 26,
			Lifetime = range(0.2, 0.35),
			Speed = range(8, 16),
			Drag = 4,
			EmissionDirection = BACK,
			SpreadAngle = Vector2.new(50, 50),
			Size = seq(0, 0.35, 1, 0),
			Rotation = range(0),
		},
		{
			Name = "VoltCore",
			Texture = TEX.Glow,
			LockedToPart = true,
			Color = colors(VOLT),
			Rate = 30,
			Lifetime = range(0.12),
			Speed = range(0),
			Size = seq(0, 2.2, 1, 1.4),
			Transparency = seq(0, 0.35, 1, 1),
		},
	},
	glow = { color = VOLT, range = 9, brightness = 1.2, flicker = 0.9 },
	kick = {
		{
			props = {
				Texture = TEX.StarFlash,
				Color = colors(VOLT_CORE),
				Size = seq(0, 3.5, 1, 0.5),
				Lifetime = range(0.15),
				Speed = range(0.001),
				Rotation = range(0, 360),
				Transparency = seq(0, 0, 1, 1),
				Brightness = 3,
			},
			count = 1,
		},
		{
			props = {
				Texture = TEX.Arc,
				FlipbookLayout = GRID4,
				FlipbookMode = ONESHOT,
				Color = colors(VOLT),
				Size = seq(0, 2.6, 1, 3),
				Lifetime = range(0.22),
				Speed = range(2, 4),
				SpreadAngle = Vector2.new(60, 60),
				EmissionDirection = TOP,
				Brightness = 4,
			},
			count = 4,
		},
		{
			props = {
				Texture = TEX.Spark,
				Orientation = PARALLEL,
				Squash = seq(0, -0.6, 1, -0.6),
				Rotation = range(0),
				Color = colors(VOLT_CORE, VOLT),
				Size = seq(0, 0.45, 1, 0),
				Lifetime = range(0.2, 0.35),
				Speed = range(18, 32),
				Drag = 5,
				SpreadAngle = Vector2.new(35, 35),
				EmissionDirection = TOP,
			},
			count = 14,
		},
	},
	impact = function(host, center, normal, scale)
		Kit.burst(host, center, normal, {
			{
				props = {
					Texture = TEX.Bolt,
					FlipbookLayout = GRID4,
					FlipbookMode = ONESHOT,
					Orientation = UPRIGHT,
					Color = colors(C(255, 248, 170)),
					Size = seq(0, 7.5, 1, 7.5),
					Transparency = seq(0, 0, 0.8, 0, 1, 1),
					Lifetime = range(0.4),
					Speed = range(0.001),
					Rotation = range(0),
					Brightness = 3,
				},
				count = 1,
				lift = 3.4,
			},
			{
				props = flat({
					Texture = TEX.SpikeBurst,
					Color = colors(VOLT),
					Size = seq(0, 3, 1, 6.5),
					Transparency = seq(0, 1, 0.2, 0, 1, 1),
					Lifetime = range(0.3),
					Brightness = 2,
				}),
				count = 1,
			},
			{
				props = flat({
					Texture = TEX.LightningRing,
					Color = colors(VOLT_CORE),
					Size = seq(0, 2, 1, 7),
					Transparency = seq(0, 0, 0.6, 0.2, 1, 1),
					Lifetime = range(0.4),
					Brightness = 2,
				}),
				count = 1,
				lift = 0.05,
			},
			{
				props = {
					Texture = TEX.StarFlash,
					Color = colors(VOLT_CORE),
					Size = seq(0, 4.5, 1, 1),
					Transparency = seq(0, 0, 1, 1),
					Lifetime = range(0.18),
					Speed = range(0.001),
					Brightness = 3,
				},
				count = 1,
				lift = 0.4,
			},
			{
				props = {
					Texture = TEX.Arc,
					FlipbookLayout = GRID4,
					FlipbookMode = ONESHOT,
					Color = colors(VOLT, VOLT_BLUE),
					Size = seq(0, 2.6, 1, 3),
					Lifetime = range(0.25),
					Speed = range(2, 5),
					SpreadAngle = Vector2.new(70, 70),
					EmissionDirection = TOP,
					Brightness = 4,
				},
				count = 5,
				lift = 0.6,
			},
			{
				props = {
					Texture = TEX.Zap,
					FlipbookLayout = GRID4,
					FlipbookMode = ONESHOT,
					Color = colors(VOLT_BLUE),
					Size = seq(0, 3, 1, 3),
					Lifetime = range(0.3),
					Speed = range(0.001),
					Brightness = 3,
				},
				count = 2,
				lift = 0.5,
			},
			{
				props = {
					Texture = TEX.Spark,
					Orientation = PARALLEL,
					Squash = seq(0, -0.6, 1, -0.6),
					Rotation = range(0),
					Color = colors(VOLT_CORE, VOLT),
					Size = seq(0, 0.45, 1, 0),
					Lifetime = range(0.25, 0.45),
					Speed = range(18, 34),
					Drag = 6,
					SpreadAngle = Vector2.new(70, 70),
					Acceleration = Vector3.new(0, -20, 0),
					EmissionDirection = TOP,
				},
				count = 22,
			},
		}, scale)
		Kit.flash(host, VOLT, 14 * scale, 4, 0.25)
	end,
}

-- Frost (Blue): icy wisps, snowflakes and orbiting crystals; spikes of ice
-- burst out of the ground and shatter.
local ICE, ICE_WHITE, ICE_DEEP = C(150, 230, 255), C(235, 252, 255), C(60, 160, 255)
Themes.Blue = {
	color = ICE,
	ribbons = {
		-- Deep ice under the white wisp: pale blue alone vanishes on the pitch.
		{
			color = colors(C(50, 130, 245), C(20, 65, 195)),
			width = 1,
			texture = TEX.BeamWave,
			lightEmission = 0.1,
			transparency = seq(0, 0.05, 1, 1),
		},
		{
			color = colors(ICE_WHITE, ICE),
			width = 0.4,
			texture = TEX.BeamWisp,
			lightEmission = 1,
			transparency = seq(0, 0.2, 1, 1),
		},
		helix(colors(ICE_WHITE, ICE_DEEP), 0.16, 0.6, 5, 0, 0.4),
	},
	emitters = {
		{
			Name = "Snowflakes",
			Texture = TEX.Sparkle,
			Color = colors(ICE_WHITE, ICE),
			Rate = 18,
			Lifetime = range(0.5, 0.9),
			Speed = range(0.5, 2),
			EmissionDirection = BACK,
			SpreadAngle = Vector2.new(60, 60),
			Acceleration = Vector3.new(0, -3, 0),
			Size = seq(0, 0.45, 1, 0.15),
			RotSpeed = range(-90, 90),
			Brightness = 2,
		},
		{
			Name = "FrostMist",
			Texture = TEX.Wisp,
			Color = colors(ICE_DEEP),
			Rate = 10,
			Lifetime = range(0.45, 0.55),
			Speed = range(0.5, 1.5),
			EmissionDirection = BACK,
			SpreadAngle = Vector2.new(30, 30),
			Size = seq(0, 0.5, 1, 2),
			Transparency = seq(0, 0.55, 1, 1),
			LightEmission = 0.1,
		},
	},
	orbit = {
		count = 3,
		size = Vector3.new(0.15, 0.55, 0.15),
		colors = { ICE_WHITE, ICE },
		material = Enum.Material.Neon,
		radius = 1.35,
		speed = 2,
		transparency = 0.15,
	},
	kick = {
		{
			props = {
				Texture = TEX.Blob,
				Color = colors(ICE_WHITE),
				Size = seq(0, 1.2, 1, 3.5),
				Lifetime = range(0.2),
				Speed = range(0.001),
				Transparency = seq(0, 0.3, 1, 1),
			},
			count = 1,
		},
		{
			props = flat({
				Texture = TEX.ShockRing,
				FlipbookLayout = GRID4,
				FlipbookMode = ONESHOT,
				Color = colors(ICE),
				Size = seq(0, 1, 1, 4.5),
				Lifetime = range(0.4),
				Brightness = 3,
			}),
			count = 1,
		},
		{
			props = {
				Texture = TEX.Crescent,
				Color = colors(ICE_WHITE, ICE),
				Size = seq(0, 0.7, 1, 0.1),
				Lifetime = range(0.25, 0.4),
				Speed = range(14, 22),
				SpreadAngle = Vector2.new(35, 35),
				EmissionDirection = TOP,
				Drag = 2,
			},
			count = 10,
		},
	},
	impact = function(host, center, normal, scale)
		iceSpikes(host, center, normal, scale)
		Kit.burst(host, center, normal, {
			{
				props = flat({
					Texture = TEX.Blob,
					Color = colors(ICE_WHITE),
					Size = seq(0, 4.5, 1, 5),
					Transparency = seq(0, 1, 0.1, 0.55, 1, 1),
					Lifetime = range(0.9),
					LightEmission = 0.5,
				}),
				count = 1,
			},
			{
				props = flat({
					Texture = TEX.ShockRing,
					FlipbookLayout = GRID4,
					FlipbookMode = ONESHOT,
					Color = colors(ICE),
					Size = seq(0, 1.5, 1, 6),
					Lifetime = range(0.5),
					Brightness = 3,
				}),
				count = 1,
				lift = 0.05,
			},
			{
				props = {
					Texture = TEX.Crescent,
					Color = colors(ICE_WHITE, ICE),
					EmissionDirection = TOP,
					Size = seq(0, 0.7, 1, 0.1),
					Lifetime = range(0.3, 0.5),
					Speed = range(10, 18),
					SpreadAngle = Vector2.new(75, 75),
					Drag = 2,
				},
				count = 10,
				lift = 0.3,
			},
			{
				props = {
					Texture = TEX.Smoke,
					FlipbookLayout = GRID4,
					FlipbookMode = ONESHOT,
					Color = colors(ICE_WHITE),
					LightEmission = 0.2,
					EmissionDirection = TOP,
					Speed = range(2, 4),
					SpreadAngle = Vector2.new(60, 60),
					Size = seq(0, 1, 1, 2.5),
					Lifetime = range(0.6),
				},
				count = 4,
			},
			{
				props = {
					Texture = TEX.Spark,
					Color = colors(ICE_WHITE, ICE_DEEP),
					EmissionDirection = TOP,
					Speed = range(6, 12),
					SpreadAngle = Vector2.new(60, 60),
					Size = seq(0, 0.35, 1, 0),
					Lifetime = range(0.3, 0.5),
				},
				count = 10,
			},
		}, scale)
	end,
}

-- Earthquake: a dusty trail with orbiting rocks and falling pebbles; the
-- ground cracks with glowing fissures, rocks fly and a dust ring rolls out.
local SAND, DIRT, MAGMA = C(214, 170, 110), C(90, 62, 40), C(255, 130, 40)
Themes.Earthquake = {
	color = SAND,
	ribbons = {
		-- Dark earth: sand-coloured ribbons blend into the desert pitch.
		{
			color = colors(C(165, 115, 66), DIRT),
			width = 1,
			texture = TEX.BeamWave,
			lightEmission = 0,
			lightInfluence = 0.8,
			transparency = seq(0, 0.1, 1, 1),
			life = 1.1,
		},
	},
	emitters = {
		{
			Name = "QuakeDust",
			Texture = TEX.Smoke,
			FlipbookLayout = GRID4,
			FlipbookMode = ONESHOT,
			Color = colors(C(186, 145, 96)),
			LightEmission = 0,
			LightInfluence = 0.6,
			Rate = 16,
			Lifetime = range(0.5, 0.8),
			Speed = range(1, 3),
			EmissionDirection = BACK,
			SpreadAngle = Vector2.new(30, 30),
			Size = seq(0, 0.7, 1, 2.4),
			Transparency = seq(0, 0.3, 1, 1),
			RotSpeed = range(-60, 60),
			Drag = 2,
		},
		{
			Name = "QuakeGrit",
			Texture = TEX.Dot,
			Color = colors(DIRT),
			LightEmission = 0,
			Rate = 22,
			Lifetime = range(0.4, 0.6),
			Speed = range(2, 5),
			EmissionDirection = BACK,
			SpreadAngle = Vector2.new(40, 40),
			Acceleration = Vector3.new(0, -30, 0),
			Size = seq(0, 0.24, 1, 0.12),
		},
	},
	orbit = {
		count = 4,
		size = Vector3.new(0.36, 0.3, 0.34),
		colors = { C(118, 86, 60), C(152, 112, 76) },
		material = Enum.Material.Slate,
		radius = 1.1,
		speed = 3.4,
		transparency = 0,
	},
	pulse = pebble,
	pulseEvery = 0.09,
	kick = {
		{
			props = {
				Texture = TEX.Smoke,
				FlipbookLayout = GRID4,
				FlipbookMode = ONESHOT,
				Color = colors(SAND),
				LightEmission = 0,
				LightInfluence = 0.6,
				Size = seq(0, 1, 1, 3),
				Lifetime = range(0.5, 0.7),
				Speed = range(6, 12),
				Drag = 4,
				SpreadAngle = Vector2.new(45, 45),
				EmissionDirection = TOP,
			},
			count = 6,
		},
		{
			props = {
				Texture = TEX.SmokeRing,
				FlipbookLayout = GRID4,
				FlipbookMode = ONESHOT,
				Color = colors(SAND),
				LightEmission = 0,
				LightInfluence = 0.6,
				Size = seq(0, 2.5, 1, 4),
				Lifetime = range(0.5),
				Speed = range(0.001),
			},
			count = 1,
		},
	},
	impact = function(host, center, normal, scale)
		Kit.burst(host, center, normal, {
			{
				props = flat({
					Texture = TEX.Splat,
					Color = colors(C(70, 48, 32)),
					LightEmission = 0,
					Size = seq(0, 3, 1, 5.5),
					Transparency = seq(0, 1, 0.1, 0.15, 0.8, 0.3, 1, 1),
					Lifetime = range(0.9),
				}),
				count = 1,
			},
			{
				props = flat({
					Texture = TEX.Crack,
					Color = colors(MAGMA),
					Brightness = 1.5,
					Size = seq(0, 4, 1, 6),
					Transparency = seq(0, 1, 0.1, 0, 0.7, 0.2, 1, 1),
					Lifetime = range(0.8),
				}),
				count = 1,
				lift = 0.04,
			},
			{
				props = flat({
					Texture = TEX.StreakRing,
					Color = colors(SAND),
					Size = seq(0, 1, 1, 8),
					Transparency = seq(0, 0.2, 1, 1),
					Lifetime = range(0.45),
				}),
				count = 1,
				lift = 0.08,
			},
			{
				props = {
					Texture = TEX.SmokeRing,
					FlipbookLayout = GRID4,
					FlipbookMode = ONESHOT,
					Color = colors(SAND),
					LightEmission = 0,
					LightInfluence = 0.6,
					Size = seq(0, 3.5, 1, 5.5),
					Lifetime = range(0.6),
					Speed = range(0.001),
				},
				count = 1,
				lift = 0.6,
			},
			{
				props = {
					Texture = TEX.Smoke,
					FlipbookLayout = GRID4,
					FlipbookMode = ONESHOT,
					Color = colors(C(186, 145, 96)),
					LightEmission = 0,
					LightInfluence = 0.6,
					EmissionDirection = TOP,
					Speed = range(4, 9),
					SpreadAngle = Vector2.new(70, 70),
					Drag = 4,
					Size = seq(0, 1.2, 1, 3.4),
					Lifetime = range(0.6, 0.9),
				},
				count = 8,
			},
			{
				props = {
					Texture = TEX.Dot,
					Color = colors(DIRT),
					LightEmission = 0,
					EmissionDirection = TOP,
					Speed = range(10, 18),
					SpreadAngle = Vector2.new(55, 55),
					Acceleration = Vector3.new(0, -40, 0),
					Size = seq(0, 0.3, 1, 0.15),
					Lifetime = range(0.4, 0.7),
				},
				count = 16,
			},
		}, scale)
		Kit.chunks(host, center, normal, scale < 0.5 and 4 or 7, scale, rock)
	end,
}

-- Void (Purple): a dark core edged with violet glow, a spinning vortex and
-- runes; a magic circle and an imploding vortex on landing.
local VOID, VOID_DARK, VOID_PINK, VOID_DEEP = C(181, 92, 255), C(36, 10, 64), C(255, 123, 240), C(90, 18, 200)
Themes.Purple = {
	color = VOID,
	ribbons = {
		{ color = colors(VOID_DARK), width = 0.7, lightEmission = 0, transparency = seq(0, 0.15, 1, 1) },
		{
			color = colors(VOID, VOID_PINK),
			width = 1.25,
			lightEmission = 1,
			transparency = seq(0, 0.55, 1, 1),
			life = 0.9,
		},
		helix(colors(VOID_PINK, VOID), 0.14, 0.65, 6, 0, 0.4),
		helix(colors(VOID_PINK, VOID), 0.14, 0.65, 6, math.pi, 0.4),
	},
	emitters = {
		{
			-- The vortex texture is black: it only shows alpha-blended, as a dark swirl.
			Name = "VoidVortex",
			Texture = TEX.Vortex,
			Color = colors(VOID, VOID_DEEP),
			LightEmission = 0,
			Rate = 12,
			Lifetime = range(0.35, 0.45),
			Speed = range(0.5, 1),
			EmissionDirection = BACK,
			Size = seq(0, 2.2, 1, 0.4),
			Transparency = seq(0, 0.4, 1, 1),
			RotSpeed = range(420, 520),
		},
		{
			Name = "VoidMotes",
			Texture = TEX.Dot,
			Color = colors(C(30, 8, 52)),
			LightEmission = 0,
			Rate = 18,
			Lifetime = range(0.4, 0.7),
			Speed = range(1, 3),
			EmissionDirection = BACK,
			SpreadAngle = Vector2.new(50, 50),
			Size = seq(0, 0.4, 1, 0),
		},
		{
			Name = "VoidSparks",
			Texture = TEX.Spark,
			Color = colors(VOID_PINK, VOID),
			Rate = 14,
			Lifetime = range(0.3, 0.5),
			Speed = range(2, 5),
			EmissionDirection = BACK,
			SpreadAngle = Vector2.new(60, 60),
			Size = seq(0, 0.32, 1, 0),
		},
	},
	orbit = {
		count = 3,
		size = Vector3.new(0.25, 0.25, 0.08),
		colors = { VOID, VOID_PINK },
		material = Enum.Material.Neon,
		radius = 1.35,
		speed = 4,
		transparency = 0.15,
	},
	kick = {
		{
			props = flat({
				Texture = TEX.RingSpiky,
				Color = colors(VOID_PINK, VOID),
				LightEmission = 0.15,
				Size = seq(0, 1, 1, 5),
				Lifetime = range(0.35),
				Transparency = seq(0, 0.2, 1, 1),
			}),
			count = 1,
		},
		{
			props = {
				Texture = TEX.Shard,
				Orientation = PARALLEL,
				Rotation = range(90),
				Color = colors(VOID_PINK, VOID),
				Size = seq(0, 0.2, 0.25, 1.6, 1, 0),
				Lifetime = range(0.25, 0.4),
				Speed = range(18, 30),
				Drag = 8,
				SpreadAngle = Vector2.new(35, 35),
				EmissionDirection = TOP,
			},
			count = 10,
		},
	},
	impact = function(host, center, normal, scale)
		Kit.burst(host, center, normal, {
			{
				-- A violet pool under the glowing rune keeps the colour on the bright pitch.
				props = flat({
					Texture = TEX.Blob,
					Color = colors(C(104, 34, 200)),
					LightEmission = 0,
					Size = seq(0, 4, 1, 5.5),
					Transparency = seq(0, 1, 0.12, 0.3, 0.75, 0.45, 1, 1),
					Lifetime = range(0.9),
				}),
				count = 1,
				lift = 0.01,
			},
			{
				props = flat({
					Texture = TEX.Rune,
					Color = colors(VOID),
					Brightness = 2,
					Size = seq(0, 3.5, 0.3, 5, 1, 5.2),
					Transparency = seq(0, 1, 0.15, 0, 0.75, 0.1, 1, 1),
					Lifetime = range(0.9),
					RotSpeed = range(90, 120),
				}),
				count = 1,
				lift = 0.02,
			},
			{
				props = flat({
					Texture = TEX.Vortex,
					Color = colors(VOID_DEEP),
					LightEmission = 0,
					Size = seq(0, 5, 1, 0.5),
					Transparency = seq(0, 0.6, 0.3, 0.2, 1, 1),
					Lifetime = range(0.55),
					RotSpeed = range(450, 550),
				}),
				count = 1,
				lift = 0.06,
			},
			{
				props = flat({
					Texture = TEX.RingSpiky,
					Color = colors(VOID_PINK, VOID),
					LightEmission = 0.15,
					Size = seq(0, 1, 1, 6.5),
					Transparency = seq(0, 0.2, 1, 1),
					Lifetime = range(0.4),
				}),
				count = 1,
				lift = 0.1,
			},
			{
				props = {
					Texture = TEX.Shard,
					Orientation = PARALLEL,
					Rotation = range(90),
					Color = colors(VOID_PINK, VOID),
					LightEmission = 0.3,
					EmissionDirection = TOP,
					Speed = range(14, 26),
					Drag = 8,
					SpreadAngle = Vector2.new(60, 60),
					Size = seq(0, 0.2, 0.25, 1.8, 1, 0),
					Lifetime = range(0.3, 0.45),
				},
				count = 12,
			},
			{
				props = {
					Texture = TEX.Smoke,
					FlipbookLayout = GRID4,
					FlipbookMode = ONESHOT,
					Color = colors(C(40, 12, 70)),
					LightEmission = 0,
					EmissionDirection = TOP,
					Speed = range(2, 5),
					SpreadAngle = Vector2.new(50, 50),
					Size = seq(0, 1, 1, 2.8),
					Lifetime = range(0.7),
				},
				count = 4,
				lift = 0.3,
			},
		}, scale)
		Kit.flash(host, VOID, 10 * scale, 2.5, 0.4)
	end,
}

-- Cosmic: a nebula ribbon with twin helices, twinkling stars and
-- constellations; a star burst with rings on landing.
local NEBULA, MAGENTA, TEAL, INDIGO, STAR =
	C(160, 110, 255), C(255, 95, 216), C(111, 243, 255), C(48, 32, 140), C(255, 255, 255)
Themes.Cosmic = {
	color = NEBULA,
	ribbons = {
		-- A band of night sky under the additive wisp, which washes out on the pitch.
		{
			color = colors(INDIGO, C(24, 16, 70)),
			width = 1,
			texture = TEX.BeamWave,
			lightEmission = 0,
			transparency = seq(0, 0.1, 1, 1),
			life = 1.2,
		},
		{
			color = colors(C(80, 60, 255), MAGENTA),
			width = 0.9,
			texture = TEX.BeamWisp,
			lightEmission = 1,
			transparency = seq(0, 0.3, 1, 1),
			life = 1.2,
		},
		helix(colors(MAGENTA, NEBULA), 0.16, 0.8, 6, 0, 0.4),
		helix(colors(TEAL, NEBULA), 0.16, 0.8, 6, math.pi, 0.4),
	},
	emitters = {
		{
			Name = "CosmicStars",
			Texture = TEX.StarThin,
			Color = colors(STAR, TEAL),
			Rate = 18,
			Lifetime = range(0.5, 0.9),
			Speed = range(0.3, 1.5),
			EmissionDirection = BACK,
			SpreadAngle = Vector2.new(70, 70),
			Size = seq(0, 0, 0.15, 0.9, 0.5, 0.4, 0.7, 0.8, 1, 0),
			Rotation = range(0),
			Brightness = 3,
		},
		{
			Name = "CosmicNebula",
			Texture = TEX.Glow,
			Color = colors(MAGENTA, INDIGO),
			LightEmission = 0.3,
			Rate = 10,
			Lifetime = range(0.6, 0.9),
			Speed = range(0.5, 1.5),
			EmissionDirection = BACK,
			Size = seq(0, 1.2, 1, 3.2),
			Transparency = seq(0, 0.75, 1, 1),
		},
		{
			Name = "CosmicConstellation",
			Texture = TEX.Constellation,
			FlipbookLayout = GRID4,
			FlipbookMode = ONESHOT,
			Color = colors(C(200, 220, 255)),
			Rate = 3,
			Lifetime = range(0.9),
			Speed = range(0.2),
			Size = seq(0, 2.6, 1, 3),
			Transparency = seq(0, 0.3, 1, 1),
		},
	},
	kick = {
		{
			props = {
				Texture = TEX.Star4,
				Color = colors(STAR, MAGENTA),
				Size = seq(0, 0.5, 0.25, 3.5, 1, 0),
				Lifetime = range(0.3),
				Speed = range(0.001),
				Rotation = range(0),
				Brightness = 3,
			},
			count = 1,
		},
		{
			props = {
				Texture = TEX.StarThin,
				Color = colors(STAR, TEAL),
				Size = seq(0, 1, 1, 0),
				Lifetime = range(0.3, 0.5),
				Speed = range(18, 30),
				Drag = 6,
				SpreadAngle = Vector2.new(40, 40),
				EmissionDirection = TOP,
				Rotation = range(0),
				Brightness = 3,
			},
			count = 10,
		},
	},
	impact = function(host, center, normal, scale)
		Kit.burst(host, center, normal, {
			{
				-- A patch of night sky on the pitch for the stars to sit on.
				props = flat({
					Texture = TEX.Blob,
					Color = colors(C(40, 26, 120)),
					LightEmission = 0,
					Size = seq(0, 3.5, 1, 5.5),
					Transparency = seq(0, 1, 0.1, 0.25, 0.7, 0.4, 1, 1),
					Lifetime = range(0.85),
				}),
				count = 1,
				lift = 0.01,
			},
			{
				props = {
					Texture = TEX.Star4,
					Color = colors(STAR, MAGENTA),
					Size = seq(0, 1, 0.25, 5, 1, 0),
					Lifetime = range(0.4),
					Speed = range(0.001),
					Rotation = range(0),
					Brightness = 3,
				},
				count = 1,
				lift = 0.5,
			},
			{
				props = flat({
					Texture = TEX.RingThin,
					Color = colors(MAGENTA),
					LightEmission = 0.2,
					Size = seq(0, 1, 1, 7),
					Transparency = seq(0, 0, 1, 1),
					Lifetime = range(0.45),
					Brightness = 2,
				}),
				count = 1,
				lift = 0.05,
			},
			{
				props = flat({
					Texture = TEX.RingSoft,
					Color = colors(TEAL),
					LightEmission = 0.2,
					Size = seq(0, 0.5, 1, 5),
					Transparency = seq(0, 0.2, 1, 1),
					Lifetime = range(0.5),
				}),
				count = 1,
				delay = 0.06,
			},
			{
				props = {
					Texture = TEX.StarThin,
					Color = colors(STAR, TEAL),
					EmissionDirection = TOP,
					Speed = range(16, 32),
					Drag = 7,
					SpreadAngle = Vector2.new(80, 80),
					Size = seq(0, 1.1, 1, 0),
					Lifetime = range(0.35, 0.6),
					Rotation = range(0),
					Brightness = 3,
				},
				count = 14,
			},
			{
				props = {
					Texture = TEX.Constellation,
					FlipbookLayout = GRID4,
					FlipbookMode = ONESHOT,
					Color = colors(C(210, 225, 255)),
					Size = seq(0, 3.5, 1, 4.5),
					Lifetime = range(0.8),
					Speed = range(0.001),
					Transparency = seq(0, 0.2, 1, 1),
				},
				count = 2,
				lift = 0.8,
			},
			{
				props = {
					Texture = TEX.Glow,
					Color = colors(MAGENTA, INDIGO),
					LightEmission = 0.3,
					EmissionDirection = TOP,
					Speed = range(1, 3),
					SpreadAngle = Vector2.new(60, 60),
					Size = seq(0, 2, 1, 5.5),
					Transparency = seq(0, 0.5, 1, 1),
					Lifetime = range(0.6),
				},
				count = 3,
				lift = 0.4,
			},
			{
				props = {
					Texture = TEX.StarFlip,
					FlipbookLayout = GRID4,
					FlipbookMode = ONESHOT,
					Color = colors(STAR),
					EmissionDirection = TOP,
					Speed = range(4, 8),
					SpreadAngle = Vector2.new(80, 80),
					Size = seq(0, 1.6, 1, 1.6),
					Lifetime = range(0.5),
					Brightness = 3,
				},
				count = 3,
				lift = 0.5,
			},
		}, scale)
		Kit.flash(host, MAGENTA, 10 * scale, 2, 0.4)
	end,
}

-- Rainbow: three rainbow helices around a white core with rainbow stars; a
-- burst of rays, rainbow rings and cartoon stars on landing.
Themes.Rainbow = {
	color = C(255, 220, 85),
	ribbons = {
		-- Barely additive so every colour of the band survives the bright pitch.
		{
			color = RAINBOW,
			width = 0.8,
			texture = TEX.BeamWave,
			lightEmission = 0.2,
			transparency = seq(0, 0.1, 1, 1),
			life = 0.9,
		},
		{ color = colors(STAR), width = 0.25, lightEmission = 1, transparency = seq(0, 0.3, 1, 1), life = 0.8 },
		helix(RAINBOW, 0.18, 0.7, 5, 0, 0.35),
		helix(RAINBOW, 0.18, 0.7, 5, TWO_PI / 3, 0.35),
		helix(RAINBOW, 0.18, 0.7, 5, TWO_PI * 2 / 3, 0.35),
	},
	emitters = {
		{
			Name = "RainbowStars",
			Texture = TEX.Star4,
			Color = RAINBOW,
			LightEmission = 0.25,
			Rate = 12,
			Lifetime = range(0.5, 0.8),
			Speed = range(1, 3),
			EmissionDirection = BACK,
			SpreadAngle = Vector2.new(50, 50),
			Size = seq(0, 0, 0.2, 0.7, 1, 0),
			RotSpeed = range(-120, 120),
			Brightness = 2,
		},
		{
			Name = "RainbowSparkles",
			Texture = TEX.Spark,
			Color = RAINBOW,
			Rate = 18,
			Lifetime = range(0.3, 0.6),
			Speed = range(1, 4),
			EmissionDirection = BACK,
			SpreadAngle = Vector2.new(40, 40),
			Size = seq(0, 0.35, 1, 0),
		},
	},
	kick = {
		{
			props = {
				Texture = TEX.Rays,
				Color = RAINBOW,
				Size = seq(0, 1, 1, 5),
				Lifetime = range(0.35),
				Speed = range(0.001),
				Transparency = seq(0, 0.2, 1, 1),
				Brightness = 2,
			},
			count = 1,
		},
		{
			props = {
				Texture = TEX.Star4,
				Color = RAINBOW,
				LightEmission = 0.25,
				Size = seq(0, 0.9, 1, 0),
				Lifetime = range(0.3, 0.5),
				Speed = range(14, 24),
				Drag = 5,
				SpreadAngle = Vector2.new(40, 40),
				EmissionDirection = TOP,
				Brightness = 2,
			},
			count = 10,
		},
	},
	impact = function(host, center, normal, scale)
		Kit.burst(host, center, normal, {
			{
				props = {
					Texture = TEX.Rays,
					Color = RAINBOW,
					Size = seq(0, 1, 0.3, 6, 1, 7.5),
					Transparency = seq(0, 0.2, 1, 1),
					Lifetime = range(0.5),
					Speed = range(0.001),
					RotSpeed = range(60),
					Brightness = 2,
				},
				count = 1,
				lift = 0.4,
			},
			{
				props = {
					Texture = TEX.Star4,
					Color = colors(STAR),
					Size = seq(0, 0.5, 0.3, 3.5, 1, 0),
					Lifetime = range(0.3),
					Speed = range(0.001),
					Rotation = range(0),
					Brightness = 3,
				},
				count = 1,
				lift = 0.5,
			},
			{
				props = flat({
					Texture = TEX.RingThin,
					Color = RAINBOW,
					LightEmission = 0.2,
					Size = seq(0, 1, 1, 6.5),
					Transparency = seq(0, 0, 1, 1),
					Lifetime = range(0.5),
					Brightness = 2,
				}),
				count = 1,
				lift = 0.05,
			},
			{
				-- Different lifetimes put every star at its own point of the rainbow.
				props = {
					Texture = TEX.Star4,
					Color = RAINBOW,
					LightEmission = 0.2,
					EmissionDirection = TOP,
					Speed = range(12, 22),
					Drag = 5,
					SpreadAngle = Vector2.new(75, 75),
					Size = seq(0, 0.9, 1, 0),
					Lifetime = range(0.35, 0.65),
					RotSpeed = range(-180, 180),
				},
				count = 12,
				lift = 0.3,
			},
		}, scale)
		for i, hue in { 0, 0.33, 0.66 } do
			Shapes.ring(
				host,
				center + normal * (0.2 + i * 0.2),
				normal,
				Color3.fromHSV(hue, 0.65, 1),
				(2 + i * 0.7) * scale
			)
		end
		rainbowStars(host, center, normal, scale)
	end,
}

-- Divine: a golden ribbon with a soft halo, sparkles and drifting feathers;
-- a pillar of light, golden rays and a flash sphere on landing.
local HOLY, HOLY_WHITE, HOLY_ORANGE = C(255, 213, 74), C(255, 248, 220), C(255, 162, 43)
Themes.Divine = {
	color = HOLY,
	ribbons = {
		-- Gold band first: a white-gold additive core alone reads as plain white.
		{
			color = colors(C(255, 175, 30), C(225, 115, 15)),
			width = 1,
			texture = TEX.BeamWave,
			lightEmission = 0,
			transparency = seq(0, 0.05, 1, 1),
			life = 0.9,
		},
		{ color = colors(HOLY_WHITE, HOLY), width = 0.35, lightEmission = 1, transparency = seq(0, 0.1, 1, 1) },
		{
			color = colors(HOLY, HOLY_ORANGE),
			width = 1.4,
			texture = TEX.BeamWisp,
			lightEmission = 1,
			transparency = seq(0, 0.65, 1, 1),
			life = 0.8,
		},
		helix(colors(HOLY_WHITE, HOLY), 0.12, 0.75, 4, 0, 0.5),
		helix(colors(HOLY_WHITE, HOLY), 0.12, 0.75, 4, math.pi, 0.5),
	},
	emitters = {
		{
			Name = "DivineSparkles",
			Texture = TEX.Sparkle,
			Color = colors(HOLY_WHITE, HOLY),
			LightEmission = 0.5,
			Rate = 18,
			Lifetime = range(0.5, 0.9),
			Speed = range(0.5, 2),
			EmissionDirection = BACK,
			SpreadAngle = Vector2.new(60, 60),
			Size = seq(0, 0, 0.2, 0.8, 1, 0),
			Rotation = range(0),
			Brightness = 2,
		},
		{
			Name = "DivineFeathers",
			Texture = TEX.Feather,
			Color = colors(HOLY_WHITE),
			LightEmission = 0.3,
			Rate = 5,
			Lifetime = range(0.8, 1.2),
			Speed = range(1, 2),
			EmissionDirection = BACK,
			SpreadAngle = Vector2.new(60, 60),
			Acceleration = Vector3.new(0, -2, 0),
			Size = seq(0, 0.35, 1, 0.3),
			Transparency = seq(0, 0.1, 0.7, 0.2, 1, 1),
			RotSpeed = range(-60, 60),
		},
		{
			Name = "DivineHalo",
			Texture = TEX.StarCore,
			LockedToPart = true,
			Color = colors(HOLY),
			Rate = 6,
			Lifetime = range(0.3),
			Speed = range(0),
			Size = seq(0, 1.5, 1, 2.8),
			Transparency = seq(0, 0.5, 1, 1),
			Rotation = range(0, 90),
		},
	},
	glow = { color = HOLY, range = 8, brightness = 0.8, flicker = 0.1 },
	kick = {
		{
			props = {
				Texture = TEX.Rays,
				Color = colors(HOLY),
				Size = seq(0, 1, 1, 5),
				Lifetime = range(0.35),
				Speed = range(0.001),
				Transparency = seq(0, 0.1, 1, 1),
				Brightness = 2,
			},
			count = 1,
		},
		{
			props = {
				Texture = TEX.Bubble,
				Color = colors(HOLY_WHITE),
				Size = seq(0, 0.5, 1, 3.5),
				Lifetime = range(0.25),
				Speed = range(0.001),
				Transparency = seq(0, 0, 1, 1),
			},
			count = 1,
		},
		{
			props = {
				Texture = TEX.Sparkle,
				Color = colors(HOLY_WHITE, HOLY),
				Size = seq(0, 0.9, 1, 0),
				Lifetime = range(0.3, 0.5),
				Speed = range(14, 24),
				Drag = 5,
				SpreadAngle = Vector2.new(40, 40),
				EmissionDirection = TOP,
				Rotation = range(0),
				Brightness = 2,
			},
			count = 10,
		},
	},
	impact = function(host, center, normal, scale)
		Kit.pillar(host, center, normal, 9 * scale, {
			Color = colors(HOLY_WHITE, HOLY),
			Transparency = seq(0, 0.1, 0.6, 0.5, 1, 1),
			LightEmission = 0.5,
			Width0 = 2.2 * scale,
			Width1 = 0.8 * scale,
		}, 0.5)
		Kit.burst(host, center, normal, {
			{
				-- Gold that survives the bright pitch; the rays above stay additive.
				props = flat({
					Texture = TEX.RingSoft,
					Color = colors(HOLY_ORANGE),
					LightEmission = 0,
					Size = seq(0, 1.5, 1, 7),
					Transparency = seq(0, 0.15, 1, 1),
					Lifetime = range(0.55),
				}),
				count = 1,
				lift = 0.02,
			},
			{
				props = {
					Texture = TEX.Rays,
					Color = colors(HOLY),
					Size = seq(0, 2, 1, 8),
					Transparency = seq(0, 0, 1, 1),
					Lifetime = range(0.5),
					Speed = range(0.001),
					RotSpeed = range(40),
					Brightness = 2,
				},
				count = 1,
				lift = 0.5,
			},
			{
				props = {
					Texture = TEX.Bubble,
					Color = colors(HOLY_WHITE),
					Size = seq(0, 0.5, 1, 5),
					Transparency = seq(0, 0, 1, 1),
					Lifetime = range(0.35),
					Speed = range(0.001),
				},
				count = 1,
				lift = 0.5,
			},
			{
				props = flat({
					Texture = TEX.RingThin,
					Color = colors(HOLY),
					LightEmission = 0.2,
					Size = seq(0, 1, 1, 6.5),
					Transparency = seq(0, 0, 1, 1),
					Lifetime = range(0.45),
					Brightness = 2,
				}),
				count = 1,
				lift = 0.05,
			},
			{
				props = {
					Texture = TEX.Sparkle,
					Color = colors(HOLY_WHITE, HOLY),
					LightEmission = 0.4,
					EmissionDirection = TOP,
					Speed = range(4, 10),
					SpreadAngle = Vector2.new(35, 35),
					Acceleration = Vector3.new(0, 4, 0),
					Size = seq(0, 0.9, 1, 0),
					Lifetime = range(0.6, 1),
					Rotation = range(0),
					Brightness = 2,
				},
				count = 14,
			},
			{
				props = {
					Texture = TEX.Feather,
					Color = colors(HOLY_WHITE),
					LightEmission = 0.3,
					EmissionDirection = TOP,
					Speed = range(3, 6),
					SpreadAngle = Vector2.new(70, 70),
					Acceleration = Vector3.new(0, -4, 0),
					Drag = 2,
					Size = seq(0, 0.45, 1, 0.35),
					Lifetime = range(0.9, 1.2),
					RotSpeed = range(-90, 90),
				},
				count = 5,
				lift = 0.6,
			},
		}, scale)
		Kit.flash(host, HOLY, 12 * scale, 3, 0.45)
	end,
}

return Themes
