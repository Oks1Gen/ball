--!strict
-- One egg of the clicked reveal: the 3D egg winds up, jumps with a spin around
-- its own axis and lands with a squash; every landing adds cracks, and the
-- light behind it shows the tier revealed so far. Everything reads the stage
-- clock, so the stage owns the only timeline.
local React = require(game.ReplicatedStorage.Packages.React)
local Run = game:GetService("RunService")
local Sequence = require(game.ReplicatedStorage.Shared.Core.HatchSequence)
local Framing = require(script.Parent.PetViewCamera)
local e = React.createElement

local C = Color3.fromRGB
local WHITE = C(255, 255, 255)
local INK = C(12, 13, 19)
local GLOW = "rbxasset://textures/particles/smoke_main.dds"

local Egg = {}
-- Light colours in the order of HatchSequence.Tiers: white, green, purple,
-- yellow, red.
Egg.TierColors = { C(255, 246, 214), C(70, 236, 92), C(181, 92, 255), C(255, 208, 46), C(255, 48, 72) }
Egg.TierNames = { "COMMON", "UNCOMMON", "RARE", "LEGENDARY", "MYTHIC" }
-- A stronger tier gets a brighter light.
local GLOW_ALPHA = { 0.55, 0.45, 0.38, 0.3, 0.24 }
local RAY_ALPHA = { 0.82, 0.68, 0.58, 0.48, 0.4 }
local RAYS = 12
local CHIPS = 5
-- The bottom of every egg model lies this many egg sizes below the centre of
-- its view: the stage stands the egg on its pedestal with it.
Egg.Foot = 0.28

export type Track = {
	clicks: { number },
	plan: { number },
	delay: number,
	frames: { Sequence.Frame },
	stop: number,
}

type Pose = {
	lift: number,
	sx: number,
	sy: number,
	spin: number,
	tilt: number,
	x: number,
	y: number,
	grow: number,
	white: number,
	alpha: number,
}

local function clamp(x: number): number
	return math.clamp(x, 0, 1)
end
local function smooth(x: number): number
	local q = clamp(x)
	return q * q * (3 - 2 * q)
end
local function pop(t: number): number
	local x = clamp(t) - 1
	return 1 + 2.7 * x * x * x + 1.7 * x * x
end
Egg.clamp, Egg.smooth, Egg.pop = clamp, smooth, pop

-- Moments of the track that follow from its clicks.
function Egg.burst(track: Track): number?
	return Sequence.burst(track.clicks, track.delay)
end
function Egg.rouletteStart(track: Track): number?
	local burst = Egg.burst(track)
	return burst and burst + Sequence.RouletteDelay
end
function Egg.fill(track: Track): number?
	local start = Egg.rouletteStart(track)
	return start and start + track.stop + Sequence.Hold
end

-- The light colour at `t`: a fresh upgrade blends from the old tier.
function Egg.lightColor(track: Track, t: number): Color3
	local tier, changed, previous = Sequence.tierAt(track.plan, track.clicks, t, track.delay)
	local color = Egg.TierColors[tier]
	if changed and t - changed < 0.22 then
		return Egg.TierColors[previous]:Lerp(color, smooth((t - changed) / 0.22))
	end
	return color
end

-- The latest moment the light flares: an upgrade, the burst or the reveal.
local function flareAt(track: Track, t: number): number?
	local _, changed = Sequence.tierAt(track.plan, track.clicks, t, track.delay)
	local latest = changed
	for _, moment in { Egg.burst(track), Egg.fill(track) } do
		if moment and moment <= t and (latest == nil or moment > latest) then
			latest = moment
		end
	end
	return latest
end

-- How strongly the latest flare still shines, fading over `fade` seconds.
function Egg.flare(track: Track, t: number, fade: number): number
	local moment = flareAt(track, t)
	return if moment then 1 - smooth((t - moment) / fade) else 0
end

local function computePose(track: Track, t: number): Pose
	local clicks, delay = track.clicks, track.delay
	local landed = Sequence.landed(clicks, t, delay)
	local pose: Pose = {
		lift = 0,
		sx = 1,
		sy = 1,
		spin = 0,
		-- Idle rock that gets more restless with every crack.
		tilt = math.sin(t * (2.2 + landed * 0.9)) * (3 + landed * 0.8),
		x = 0,
		y = 0,
		grow = 0.88 + 0.12 * pop(t / 0.35),
		white = 0,
		alpha = 1,
	}
	local start, index = nil, 0
	for k = math.min(#clicks, Sequence.Clicks), 1, -1 do
		if clicks[k] + delay <= t then
			start, index = clicks[k] + delay, k
			break
		end
	end
	if start then
		local u = t - start
		local direction = if index % 2 == 0 then -1 else 1
		if u < Sequence.Windup then
			local q = smooth(u / Sequence.Windup)
			pose.sy, pose.sx = 1 - 0.14 * q, 1 + 0.09 * q
		elseif u < Sequence.Jump then
			local p = (u - Sequence.Windup) / (Sequence.Jump - Sequence.Windup)
			local stretch = math.max(0, 1 - p * 2.5)
			pose.lift = 4 * p * (1 - p)
			pose.sy, pose.sx = 1 + 0.12 * stretch, 1 - 0.07 * stretch
			pose.spin = smooth(p) * math.pi * 2 * direction
			pose.tilt = math.sin(p * math.pi) * 10 * direction
		elseif u < Sequence.Jump + 0.32 then
			local q = (u - Sequence.Jump) / 0.32
			local squash = (1 - q) ^ 2 * math.cos(q * math.pi * 2.6)
			pose.sy, pose.sx = 1 - 0.17 * squash, 1 + 0.11 * squash
			pose.tilt *= q
		end
	end
	local finale = Sequence.finale(clicks, delay)
	if finale and t >= finale then
		local v = t - finale
		local charge = clamp(v / Sequence.Charge)
		-- The still moment before the burst: no shaking, a last breath in.
		local still = if v >= Sequence.Charge then 0 else 1
		pose.tilt = math.sin(v * 48) * (3 + 11 * charge ^ 1.5) * still
		pose.x = math.sin(v * 67) * charge * 0.025 * still
		pose.y = math.cos(v * 59) * charge * 0.015 * still
		pose.spin = math.sin(v * 21) * 0.35 * charge * still
		pose.grow = 1 + 0.28 * charge * charge + 0.05 * smooth((v - Sequence.Charge) / Sequence.Freeze)
		pose.white = charge ^ 1.6
		pose.alpha = 1 - clamp((v - Sequence.Charge - Sequence.Freeze + 0.03) / 0.08)
	end
	return pose
end

-- Crack network in egg coordinates; the number is the landing that opens it.
local POINTS: { [string]: Vector2 } = {
	A = Vector2.new(0.5, 0.44),
	B = Vector2.new(0.45, 0.5),
	C = Vector2.new(0.53, 0.56),
	D = Vector2.new(0.47, 0.63),
	E = Vector2.new(0.55, 0.38),
	F = Vector2.new(0.48, 0.32),
	G = Vector2.new(0.54, 0.69),
	H = Vector2.new(0.39, 0.47),
	I = Vector2.new(0.53, 0.26),
	J = Vector2.new(0.61, 0.52),
	K = Vector2.new(0.36, 0.56),
	L = Vector2.new(0.49, 0.75),
	M = Vector2.new(0.64, 0.43),
	N = Vector2.new(0.4, 0.63),
	O = Vector2.new(0.61, 0.34),
}
local CRACKS: { { any } } = {
	{ "A", "B", 1 },
	{ "B", "C", 1 },
	{ "C", "D", 2 },
	{ "A", "E", 2 },
	{ "E", "F", 3 },
	{ "D", "G", 3 },
	{ "B", "H", 3 },
	{ "F", "I", 4 },
	{ "C", "J", 4 },
	{ "H", "K", 4 },
	{ "G", "L", 5 },
	{ "J", "M", 5 },
	{ "K", "N", 5 },
	{ "E", "O", 5 },
}
Egg.CrackCount = #CRACKS

local function EggView(p: { World: number, Id: string, Color: Color3, Drive: () -> (number, number, number) })
	local ref = React.useRef(nil :: ViewportFrame?)
	local drive = React.useRef(p.Drive)
	drive.current = p.Drive
	React.useEffect(function()
		local viewport = assert(ref.current, "Egg viewport must be mounted")
		local map = (
			workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild(p.World == 2 and "World2" or "World1")
		)
		local scenery = map and map:FindFirstChild("SkippingWorld")
		local stand = scenery and scenery:FindFirstChild("Egg_" .. p.Id)
		local source = stand and stand:FindFirstChild("ImportedVisual")
		local model
		if source and source:IsA("Model") then
			model = source:Clone()
		else
			model = Instance.new("Model")
			local shell = Instance.new("Part")
			shell.Size = Vector3.new(2.2, 3, 2.2)
			shell.Color = p.Color
			shell.Material = Enum.Material.SmoothPlastic
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = shell
			shell.Parent = model
		end
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
			end
		end
		local cf, size = model:GetBoundingBox()
		model.WorldPivot = cf
		model:PivotTo(CFrame.identity)
		-- Parts relative to the pivot: the spin and the squash are applied
		-- around the centre of the egg every frame.
		local parts = {}
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				table.insert(parts, { part = part, offset = part.CFrame, size = part.Size })
			end
		end
		local world = Instance.new("WorldModel")
		world.Parent = viewport
		model.Parent = world
		local camera = Instance.new("Camera")
		camera.FieldOfView = 34
		camera.Parent = viewport
		viewport.CurrentCamera = camera
		local function fit()
			-- Headroom for the stretch of the jump and the spin.
			Framing.fit(camera, size * 1.22, viewport.AbsoluteSize)
		end
		fit()
		local lastSpin, lastX, lastY = 0, 1, 1
		local function apply()
			local spin, sx, sy = drive.current()
			if spin == lastSpin and sx == lastX and sy == lastY then
				return
			end
			lastSpin, lastX, lastY = spin, sx, sy
			local base = CFrame.Angles(0, spin, 0)
			local scale = Vector3.new(sx, sy, sx)
			for _, item in parts do
				local offset = item.offset
				item.part.Size = item.size
					* Vector3.new(
						(offset.RightVector * scale).Magnitude,
						(offset.UpVector * scale).Magnitude,
						(offset.LookVector * scale).Magnitude
					)
				item.part.CFrame = base * CFrame.new(offset.Position * scale) * offset.Rotation
			end
		end
		apply()
		local connections = {
			viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit),
			Run.RenderStepped:Connect(apply),
		}
		return function()
			for _, connection in connections do
				connection:Disconnect()
			end
			world:Destroy()
			camera:Destroy()
		end
	end, { p.Id, tostring(p.World) })
	return e("ViewportFrame", {
		ref = ref,
		Name = "HatchingEgg",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(215, 215, 235),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1, -1),
		ZIndex = 16,
		Active = false,
	})
end

type Props = {
	At: ((number) -> any) -> any,
	Now: () -> number,
	Track: Track,
	Center: Vector2,
	Size: number,
	EggId: string,
	World: number,
	ShellColor: Color3,
}

function Egg.View(p: Props)
	local at, track, size = p.At, p.Track, p.Size
	local cx, cy = p.Center.X, p.Center.Y
	local ground = cy + size * Egg.Foot
	local cacheT, cache = -math.huge, nil :: Pose?
	local function pose(t: number): Pose
		if t ~= cacheT or cache == nil then
			cacheT, cache = t, computePose(track, t)
		end
		return cache :: Pose
	end
	local function tier(t: number): number
		return (Sequence.tierAt(track.plan, track.clicks, t, track.delay))
	end
	local function flare(t: number): number
		return Egg.flare(track, t, 0.45)
	end
	local function intro(t: number): number
		return smooth(t / 0.3)
	end
	local children = {}

	-- Light behind the egg.
	children.Glow = e("ImageLabel", {
		Name = "HatchTierGlow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(cx, cy),
		Image = GLOW,
		ImageColor3 = at(function(t)
			return Egg.lightColor(track, t)
		end),
		Size = at(function(t)
			local s = size * 1.55 * (1 + 0.35 * flare(t) + 0.05 * math.sin(t * 3))
			return UDim2.fromOffset(s, s)
		end),
		ImageTransparency = at(function(t)
			return 1 - (1 - GLOW_ALPHA[tier(t)] + 0.3 * flare(t)) * intro(t)
		end),
		ZIndex = 9,
	})
	local rays = {}
	local span = size * 2.2
	for k = 1, RAYS do
		local angle = math.rad(k * 360 / RAYS)
		local length = size * (if k % 2 == 0 then 1.05 else 0.78)
		rays["Ray" .. k] = e("Frame", {
			Name = "HatchTierRay",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(
				0.5 + math.sin(angle) * length / 2 / span,
				0.5 - math.cos(angle) * length / 2 / span
			),
			Size = UDim2.fromOffset(size * (if k % 3 == 0 then 0.075 else 0.048), length),
			Rotation = k * 360 / RAYS,
			BackgroundColor3 = at(function(t)
				return Egg.lightColor(track, t)
			end),
			BackgroundTransparency = at(function(t)
				return 1 - (1 - RAY_ALPHA[tier(t)] + 0.25 * flare(t)) * intro(t)
			end),
			BorderSizePixel = 0,
			ZIndex = 10,
		}, {
			Fade = e("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.6, 0.35),
					NumberSequenceKeypoint.new(1, 0.15),
				}),
			}),
		})
	end
	children.Rays = e("Frame", {
		Name = "HatchTierRays",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(cx, cy),
		Size = UDim2.fromOffset(span, span),
		Rotation = at(function(t)
			return t * 16 + pose(t).white * 40
		end),
		ZIndex = 10,
	}, rays)
	children.Ring = e("Frame", {
		Name = "HatchUpgradeRing",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(cx, cy),
		Size = at(function(t)
			local _, changed = Sequence.tierAt(track.plan, track.clicks, t, track.delay)
			local q = if changed then clamp((t - changed) / 0.55) else 1
			local s = size * (0.5 + (1 - (1 - q) ^ 3) * 1.4)
			return UDim2.fromOffset(s, s)
		end),
		ZIndex = 11,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Edge = e("UIStroke", {
			Color = at(function(t)
				return Egg.lightColor(track, t)
			end),
			Thickness = at(function(t)
				local _, changed = Sequence.tierAt(track.plan, track.clicks, t, track.delay)
				return if changed then 2 + 6 * (1 - clamp((t - changed) / 0.55)) else 0
			end),
			Transparency = at(function(t)
				local _, changed = Sequence.tierAt(track.plan, track.clicks, t, track.delay)
				return if changed then clamp(0.1 + (t - changed) / 0.55) else 1
			end),
		}),
	})

	-- Shadow and landing dust on the ground.
	children.Shadow = e("ImageLabel", {
		Name = "HatchEggShadow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(cx, ground),
		Size = at(function(t)
			local q = pose(t)
			local width = size * 0.7 * (1 - q.lift * 0.35) * q.sx * q.grow
			return UDim2.fromOffset(width, width * 0.24)
		end),
		Image = GLOW,
		ImageColor3 = INK,
		ImageTransparency = at(function(t)
			local q = pose(t)
			return 1 - (0.75 - q.lift * 0.3) * q.alpha
		end),
		ZIndex = 12,
	})
	local function sinceLanding(t: number): (number, number)
		local count, latest = Sequence.landed(track.clicks, t, track.delay)
		return if latest then t - latest else math.huge, count
	end
	children.Dust = e("Frame", {
		Name = "HatchLandingDust",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(cx, ground),
		Size = at(function(t)
			local q = clamp(sinceLanding(t) / 0.35)
			local width = size * (0.35 + 0.6 * (1 - (1 - q) ^ 2))
			return UDim2.fromOffset(width, width * 0.26)
		end),
		ZIndex = 13,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Edge = e("UIStroke", {
			Color = WHITE,
			Thickness = 3,
			Transparency = at(function(t)
				return clamp(0.25 + sinceLanding(t) / 0.35)
			end),
		}),
	})
	for k = 1, CHIPS do
		local chipSize = size * (0.035 + (k % 3) * 0.01)
		children["Chip" .. k] = e("Frame", {
			Name = "HatchShellChip",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(chipSize, chipSize * (if k % 2 == 0 then 1.4 else 0.9)),
			Position = at(function(t)
				local age, count = sinceLanding(t)
				local q = clamp(age / 0.5)
				local angle = -math.pi / 2 + (k - (CHIPS + 1) / 2) * 0.6 + count * 0.37
				local distance = size * (0.12 + q * 0.38)
				return UDim2.fromOffset(
					cx + math.cos(angle) * distance,
					cy - size * 0.05 + math.sin(angle) * distance * 0.8 + q * q * size * 0.45
				)
			end),
			Rotation = at(function(t)
				return k * 47 + math.min(sinceLanding(t), 1) * (if k % 2 == 0 then 420 else -360)
			end),
			BackgroundColor3 = p.ShellColor:Lerp(WHITE, 0.35),
			BackgroundTransparency = at(function(t)
				local age = sinceLanding(t)
				return if age > 0.5 then 1 else clamp((age - 0.25) / 0.25)
			end),
			BorderSizePixel = 0,
			ZIndex = 22,
		}, { Corner = e("UICorner", { CornerRadius = UDim.new(0.25, 0) }) })
	end

	-- The egg: 3D view, cracks of the landings and the white charge glow.
	local eggChildren: { [string]: any } = {
		Art = e(EggView, {
			Id = p.EggId,
			World = p.World,
			Color = p.ShellColor,
			Drive = function()
				local q = pose(p.Now())
				return q.spin, q.sx, q.sy
			end,
		}),
		WhiteGlow = e("ImageLabel", {
			Name = "HatchChargeGlow",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.95, 0.95),
			Image = GLOW,
			ImageColor3 = WHITE,
			ImageTransparency = at(function(t)
				return 1 - pose(t).white * 0.95
			end),
			ZIndex = 21,
		}),
	}
	local crackGlow = math.max(4, size * 0.026)
	local crackCore = math.max(2, size * 0.009)
	for k, crack in CRACKS do
		local a: Vector2 = POINTS[crack[1]] :: Vector2
		local b: Vector2 = POINTS[crack[2]] :: Vector2
		local stage: number = crack[3]
		local function facing(t: number): number
			return math.cos(pose(t).spin)
		end
		local function shown(t: number): number
			local landing = track.clicks[stage]
			if landing == nil then
				return 0
			end
			return smooth((t - landing - track.delay - Sequence.Jump) / 0.08) * clamp((facing(t) - 0.2) / 0.5)
		end
		for layer = 1, 2 do
			eggChildren["Crack" .. k .. "Layer" .. layer] = e("Frame", {
				Name = if layer == 1 then "CrackGlow" else "CrackCore",
				AnchorPoint = Vector2.new(0.5, 0.5),
				-- A spin squeezes the cracks of the front face like the egg.
				Position = at(function(t)
					local squeeze = facing(t)
					return UDim2.fromScale(0.5 + ((a.X + b.X) / 2 - 0.5) * squeeze, (a.Y + b.Y) / 2)
				end),
				Size = at(function(t)
					local dx = (b.X - a.X) * facing(t)
					local dy = b.Y - a.Y
					return UDim2.new(math.sqrt(dx * dx + dy * dy), 0, 0, if layer == 1 then crackGlow else crackCore)
				end),
				Rotation = at(function(t)
					return math.deg(math.atan2(b.Y - a.Y, (b.X - a.X) * facing(t)))
				end),
				BackgroundColor3 = if layer == 1
					then at(function(t)
						return Egg.lightColor(track, t):Lerp(WHITE, 0.2 + pose(t).white * 0.8)
					end)
					else C(255, 252, 230),
				BackgroundTransparency = at(function(t)
					return 1 - shown(t) * (if layer == 1 then 0.6 + pose(t).white * 0.4 else 0.95)
				end),
				BorderSizePixel = 0,
				ZIndex = if layer == 1 then 19 else 20,
			})
		end
	end
	children.Egg = e("CanvasGroup", {
		Name = "HatchEggStage",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		GroupTransparency = at(function(t)
			return 1 - pose(t).alpha
		end),
		Position = at(function(t)
			local q = pose(t)
			-- The squash keeps the bottom of the egg on the ground.
			return UDim2.fromOffset(
				math.round(cx + q.x * size),
				math.round(cy + (q.y - q.lift * 0.3 + (1 - q.sy) * Egg.Foot) * size)
			)
		end),
		Size = at(function(t)
			local s = size * pose(t).grow
			return UDim2.fromOffset(s, s)
		end),
		Rotation = at(function(t)
			return pose(t).tilt
		end),
		ZIndex = 15,
	}, eggChildren)

	-- Upgrade flash and the name of the new tier.
	children.Flash = e("ImageLabel", {
		Name = "HatchUpgradeFlash",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(cx, cy),
		Size = UDim2.fromOffset(size * 1.2, size * 1.2),
		Image = GLOW,
		ImageColor3 = WHITE,
		ImageTransparency = at(function(t)
			local _, changed = Sequence.tierAt(track.plan, track.clicks, t, track.delay)
			return if changed then 1 - (1 - clamp((t - changed) / 0.3)) * 0.75 else 1
		end),
		ZIndex = 23,
	})
	local function popupAge(t: number): number
		local _, changed = Sequence.tierAt(track.plan, track.clicks, t, track.delay)
		local burst = Egg.burst(track)
		if changed == nil or (burst and t >= burst) then
			return math.huge
		end
		return t - changed
	end
	local function popupAlpha(t: number): number
		return clamp((popupAge(t) - 0.85) / 0.25)
	end
	children.Popup = e("TextLabel", {
		Name = "HatchTierPopup",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = at(function(t)
			return UDim2.fromOffset(cx, cy - size * 0.64 - clamp(popupAge(t) / 1.1) * size * 0.08)
		end),
		Size = UDim2.fromOffset(size * 1.8, size * 0.24),
		Text = at(function(t)
			return Egg.TierNames[tier(t)] .. "!"
		end),
		Font = Enum.Font.GothamBlack,
		TextSize = math.floor(math.max(20, size * 0.15)),
		TextColor3 = at(function(t)
			return Egg.TierColors[tier(t)]
		end),
		TextTransparency = at(popupAlpha),
		ZIndex = 26,
	}, {
		Stroke = e("UIStroke", {
			Color = INK,
			Thickness = 3,
			Transparency = at(popupAlpha),
		}),
		Scale = e("UIScale", {
			Scale = at(function(t)
				return math.max(0.05, pop(popupAge(t) / 0.28))
			end),
		}),
	})
	return e("Frame", {
		Name = "HatchEggLayers",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
	}, children)
end

return Egg
