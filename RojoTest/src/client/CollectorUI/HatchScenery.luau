--!strict
-- The stage of the clicked reveal: a garden at golden hour with a stone
-- pedestal under every egg. The 3D garden lives in one viewport behind the 2D
-- egg layers. Every pedestal stands where the ray through its egg's foot meets
-- the ground, so the eggs land on them at any screen aspect.
local React = require(game.ReplicatedStorage.Packages.React)
local Run = game:GetService("RunService")
local e = React.createElement

local C = Color3.fromRGB
local GLOW = "rbxasset://textures/particles/smoke_main.dds"
local FOV = 40
local TAN = math.tan(math.rad(FOV / 2))
local PITCH = math.rad(8)
-- Camera height above the pedestal tops, the plaza below them and the grass
-- below the plaza.
local EYE = 5.6
local FLOOR = 2.4
local GRASS = -FLOOR - 0.4
local UP = CFrame.Angles(0, 0, math.pi / 2)

local LEAVES = { C(58, 142, 70), C(88, 170, 78), C(44, 120, 66), C(122, 186, 86) }
local PETALS = { C(255, 118, 158), C(255, 212, 88), C(255, 255, 255), C(184, 130, 255), C(255, 148, 90) }
local STONE = C(232, 222, 204)
local TRUNK = C(118, 82, 56)
local IRON = C(58, 60, 72)

local Scenery = {}
-- The sky above the garden, top to horizon; the top colour also fills the bar
-- of the core UI above the stage.
Scenery.SkyTop = C(38, 46, 112)
local SKY = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Scenery.SkyTop),
	ColorSequenceKeypoint.new(0.16, C(104, 82, 168)),
	ColorSequenceKeypoint.new(0.3, C(255, 146, 112)),
	ColorSequenceKeypoint.new(1, C(255, 176, 120)),
})
-- The horizon as a share of the stage height.
Scenery.Horizon = 0.5 - math.tan(PITCH) / TAN / 2

-- The foot of an egg and its size, in stage units.
export type Spot = { x: number, y: number, size: number }
-- The light of one egg as the garden sees it, all by the stage clock:
-- colour and tier of the light, a fresh flare (0..1) and the epic mood (0..1).
export type Light = {
	color: (number) -> Color3,
	tier: (number) -> number,
	flare: (number) -> number,
	epic: (number) -> number,
}
type Props = {
	At: ((number) -> any) -> any,
	Now: () -> number,
	Width: number,
	Height: number,
	Spots: { Spot },
	-- One per spot; without them the garden stays still (effects off).
	Lights: { Light }?,
}

local GOLD = C(255, 190, 70)
local BULB = C(255, 224, 150)
local AMBIENT = C(92, 88, 140)
local SUNLIGHT = C(255, 196, 150)
local NIGHT = C(14, 10, 34)

-- The flare that colours the garden and its colour: of the eggs still
-- flaring, the strongest tier wins, so a triple's Legendary is not lost.
local function strongest(lights: { Light }, t: number): (number, Color3)
	local best, score, color = 0, 0, Color3.new(1, 1, 1)
	for _, light in lights do
		local flare = light.flare(t)
		local rank = if flare > 0.05 then light.tier(t) + flare else 0
		if rank > score then
			best, score, color = flare, rank, light.color(t)
		end
	end
	return best, color
end
local function epic(lights: { Light }, t: number): number
	local mood = 0
	for _, light in lights do
		mood = math.max(mood, light.epic(t))
	end
	return mood
end

local function add(
	parent: Instance,
	shape: Enum.PartType,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	part.CastShadow = false
	part.Shape = shape
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- An upright cylinder whose top face lies at `top`.
local function disc(
	parent: Instance,
	x: number,
	z: number,
	top: number,
	radius: number,
	height: number,
	color: Color3,
	material: Enum.Material?
): Part
	return add(
		parent,
		Enum.PartType.Cylinder,
		Vector3.new(height, radius * 2, radius * 2),
		CFrame.new(x, top - height / 2, z) * UP,
		color,
		material
	)
end

local function ball(parent: Instance, position: Vector3, radius: number, color: Color3, material: Enum.Material?): Part
	return add(parent, Enum.PartType.Ball, Vector3.one * radius * 2, CFrame.new(position), color, material)
end

local function tree(parent: Instance, x: number, z: number, height: number, shade: number, haze: number?)
	local function leaf(k: number): Color3
		return LEAVES[(shade + k - 1) % #LEAVES + 1]:Lerp(C(150, 170, 210), haze or 0)
	end
	disc(parent, x, z, GRASS + height * 0.55, height * 0.06, height * 0.55, TRUNK:Lerp(C(150, 160, 200), haze or 0))
	local crown = Vector3.new(x, GRASS + height * 0.64, z)
	ball(parent, crown, height * 0.27, leaf(1))
	ball(parent, crown + Vector3.new(-height * 0.21, -height * 0.08, height * 0.08), height * 0.2, leaf(2))
	ball(parent, crown + Vector3.new(height * 0.2, -height * 0.05, height * 0.06), height * 0.21, leaf(3))
	ball(parent, crown + Vector3.new(height * 0.03, height * 0.18, -height * 0.02), height * 0.18, leaf(2))
end

local function bush(parent: Instance, x: number, z: number, radius: number, shade: number)
	ball(parent, Vector3.new(x, GRASS + radius * 0.45, z), radius, LEAVES[shade])
	ball(
		parent,
		Vector3.new(x - radius * 0.75, GRASS + radius * 0.25, z + radius * 0.2),
		radius * 0.7,
		LEAVES[shade % 4 + 1]
	)
	ball(
		parent,
		Vector3.new(x + radius * 0.8, GRASS + radius * 0.2, z + radius * 0.1),
		radius * 0.66,
		LEAVES[(shade + 1) % 4 + 1]
	)
end

local function flower(parent: Instance, x: number, z: number, height: number, color: Color3)
	disc(parent, x, z, GRASS + height, 0.05, height, C(70, 140, 60))
	ball(parent, Vector3.new(x, GRASS + height + 0.08, z), 0.24, color)
	ball(parent, Vector3.new(x, GRASS + height + 0.14, z + 0.14), 0.1, C(255, 232, 120))
end

local function lamp(parent: Instance, x: number, z: number)
	disc(parent, x, z, GRASS + 0.3, 0.38, 0.3, IRON)
	disc(parent, x, z, GRASS + 4.3, 0.12, 4, IRON)
	ball(parent, Vector3.new(x, GRASS + 4.7, z), 0.46, BULB, Enum.Material.Neon).Name = "HatchLampBulb"
	disc(parent, x, z, GRASS + 5.25, 0.4, 0.16, IRON)
	disc(parent, x, z, GRASS + 5.45, 0.16, 0.2, IRON)
end

local function rock(parent: Instance, x: number, z: number, size: number, angle: number)
	add(
		parent,
		Enum.PartType.Block,
		Vector3.new(size * 1.3, size * 0.8, size),
		CFrame.new(x, GRASS + size * 0.25, z) * CFrame.Angles(0.15, angle, 0.12),
		C(150, 148, 162)
	)
end

-- A stone pedestal whose top lies at y = 0; returns its glowing rim.
local function pedestal(parent: Instance, x: number, z: number, radius: number): Part
	disc(parent, x, z, 0, radius, 0.42, C(244, 236, 220))
	local rim = disc(parent, x, z, -0.1, radius * 1.04, 0.16, GOLD, Enum.Material.Neon)
	rim.Name = "HatchPedestalRim"
	disc(parent, x, z, -0.42, radius * 0.8, FLOOR - 0.92, C(214, 204, 188))
	disc(parent, x, z, -FLOOR + 0.5, radius * 1.1, 0.5, C(198, 186, 170))
	disc(parent, x, z, -FLOOR + 0.12, radius * 1.26, 0.2, C(176, 162, 146))
	return rim
end

-- The garden around the plaza; the plaza centre lies at the origin.
local function garden(parent: Instance)
	disc(parent, 0, -40, GRASS, 170, 1, C(100, 176, 76))
	-- The round stone plaza with an inlaid ring.
	disc(parent, 0, 0, -FLOOR, 11, 0.6, STONE)
	disc(parent, 0, 0, -FLOOR - 0.2, 11.7, 0.6, C(178, 160, 140))
	disc(parent, 0, 0, -FLOOR + 0.02, 8.3, 0.1, C(204, 188, 166))
	disc(parent, 0, 0, -FLOOR + 0.03, 7.8, 0.1, STONE)
	-- Far mountains in the haze, then green hills: x, z, radius, height.
	local mountain, hill = C(126, 106, 180), C(110, 166, 126)
	local hills: { { number } } = {
		{ -95, -190, 90, 30 },
		{ 70, -210, 100, 36 },
		{ 160, -170, 80, 22 },
		{ -60, -120, 60, 13 },
		{ 40, -130, 70, 15 },
		{ 115, -110, 55, 10 },
		{ -130, -105, 55, 11 },
	}
	for k, item in hills do
		local color = if k <= 3
			then mountain:Lerp(Scenery.SkyTop, (k % 2) * 0.08)
			else hill:Lerp(LEAVES[k % 4 + 1], 0.2)
		ball(parent, Vector3.new(item[1], GRASS + item[4] - item[3], item[2]), item[3], color)
	end
	-- Trees framing the plaza, a lighter row behind them and a few on the hills.
	local trees = {
		{ -15, -10, 10, 1 },
		{ -21, -20, 12, 2 },
		{ -12, -27, 8, 3 },
		{ -27, -8, 11, 4 },
		{ -32, -30, 13, 1 },
		{ 15, -12, 11, 3 },
		{ 22, -22, 13, 1 },
		{ 13, -29, 8, 2 },
		{ 28, -9, 10, 4 },
		{ 34, -32, 12, 2 },
	}
	for _, item in trees do
		tree(parent, item[1], item[2], item[3], item[4])
	end
	for k = -6, 6 do
		if math.abs(k) > 1 then
			tree(parent, k * 9 + math.sin(k) * 3, -58 - math.abs(k) * 2, 9 + (k % 3) * 2, k % 4 + 1, 0.3)
		end
	end
	for k = 1, 8 do
		tree(parent, -80 + k * 20, -112 - (k % 3) * 6, 10, k % 4 + 1, 0.45)
	end
	-- Bushes, lamps and rocks around the plaza.
	for _, item in { { -9.5, -11, 1.4, 1 }, { -5, -13.5, 1.1, 2 }, { 5.5, -13, 1.2, 3 }, { 10, -10, 1.5, 2 } } do
		bush(parent, item[1], item[2], item[3], item[4])
	end
	for _, item in { { -13, -2, 1.6, 4 }, { 13.5, -3, 1.7, 1 }, { -18, -14, 1.8, 2 }, { 18.5, -15, 1.8, 3 } } do
		bush(parent, item[1], item[2], item[3], item[4])
	end
	lamp(parent, -13.5, -4.5)
	lamp(parent, 13.5, -4.5)
	lamp(parent, -6.5, -14)
	lamp(parent, 6.5, -14)
	for _, item in { { -16, -4, 1.4, 0.4 }, { 17, -6, 1.2, 1.3 }, { -24, -15, 1.8, 2.1 }, { 25, -17, 1.5, 0.8 } } do
		rock(parent, item[1], item[2], item[3], item[4])
	end
	-- A ring of flowers around the plaza; the front stays open for the stage.
	local random = Random.new(11)
	for k = 1, 64 do
		local angle = math.rad(random:NextNumber(-150, 150)) + math.pi
		local radius = random:NextNumber(12.3, 15.5)
		flower(
			parent,
			math.sin(angle) * radius,
			math.cos(angle) * radius,
			random:NextNumber(0.5, 0.9),
			PETALS[k % #PETALS + 1]
		)
	end
end

type GardenProps = {
	At: ((number) -> any) -> any,
	Now: () -> number,
	Width: number,
	Height: number,
	Spots: { Spot },
	Lights: { Light }?,
}

-- Rims take the light of their egg and the lamps the colour of a fresh flare.
local function paint(rims: { Part }, bulbs: { Part }, lights: { Light }, t: number)
	for i, rim in rims do
		local light = lights[i]
		if light then
			local tier = light.tier(t)
			local color = GOLD:Lerp(light.color(t), if tier > 1 then 0.85 else 0)
			rim.Color = color:Lerp(Color3.new(1, 1, 1), light.flare(t) * 0.5)
		end
	end
	local flare, color = strongest(lights, t)
	local bulb = BULB:Lerp(color, flare * 0.85)
	for _, part in bulbs do
		part.Color = bulb
	end
end

-- The garden is built once per client and moved between hatch screens. It
-- lives only in this player's ViewportFrame, so other players never see it.
type Built = { model: Model, bulbs: { Part } }
local built: Built? = nil

function Scenery.garden(): Built
	if built == nil then
		local model = Instance.new("Model")
		model.Name = "HatchGarden"
		garden(model)
		local bulbs: { Part } = {}
		for _, part in model:GetChildren() do
			if part.Name == "HatchLampBulb" and part:IsA("Part") then
				table.insert(bulbs, part)
			end
		end
		Scenery.builds += 1
		local entry = { model = model, bulbs = bulbs }
		-- A destroyed garden is built again on the next screen.
		model.Destroying:Connect(function()
			if built == entry then
				built = nil
			end
		end)
		built = entry
	end
	return built :: Built
end

-- How many times the garden was built; the verification checks it stays one.
Scenery.builds = 0

local function Garden(p: GardenProps)
	local ref = React.useRef(nil :: ViewportFrame?)
	local live = React.useRef(p)
	live.current = p
	local key = {}
	for _, spot in p.Spots do
		table.insert(key, string.format("%d,%d,%d", spot.x, spot.y, spot.size))
	end
	-- A layout effect: its cleanup takes the shared garden out before React
	-- destroys the viewport with everything inside it.
	React.useLayoutEffect(function()
		local viewport = assert(ref.current, "Garden viewport must be mounted")
		local w, h = p.Width, p.Height
		local camera = Instance.new("Camera")
		camera.FieldOfView = FOV
		camera.Parent = viewport
		viewport.CurrentCamera = camera
		local cached = Scenery.garden()
		-- A second screen at once (never expected) gets its own copy.
		local shared = cached.model.Parent == nil
		local model = if shared then cached.model else cached.model:Clone()
		-- Pedestals follow the layout, so they are rebuilt with it.
		local stands = Instance.new("Model")
		stands.Name = "HatchPedestals"
		stands.Parent = model
		-- The camera looks down on the plaza, so the first egg's foot lands on its
		-- centre.
		local first = p.Spots[1] or { x = w / 2, y = h * 0.72, size = 0 }
		local below = PITCH + math.atan((first.y / h - 0.5) * 2 * TAN)
		local eye = CFrame.new(0, EYE, EYE / math.tan(math.max(below, math.rad(4)))) * CFrame.Angles(-PITCH, 0, 0)
		camera.CFrame = eye
		local unitsPerStud = function(depth: number): number
			return h / (2 * depth * TAN)
		end
		local rims: { Part } = {}
		for i, spot in p.Spots do
			local direction = eye:VectorToWorldSpace(
				Vector3.new(((spot.x / w) * 2 - 1) * TAN * w / h, (1 - (spot.y / h) * 2) * TAN, -1)
			)
			if direction.Y < -1e-3 then
				local point = eye.Position + direction * (-eye.Position.Y / direction.Y)
				local depth = (point - eye.Position):Dot(eye.LookVector)
				rims[i] = pedestal(stands, point.X, point.Z, spot.size * 0.36 / unitsPerStud(depth))
			end
		end
		local bulbs: { Part } = cached.bulbs
		if not shared then
			bulbs = {}
			for _, part in model:GetChildren() do
				if part.Name == "HatchLampBulb" and part:IsA("Part") then
					table.insert(bulbs, part)
				end
			end
		end
		for _, part in bulbs do
			part.Color = BULB
		end
		model.Parent = viewport
		local function update()
			local current = live.current
			if current.Lights then
				paint(rims, bulbs, current.Lights, current.Now())
			end
		end
		update()
		local connection = Run.RenderStepped:Connect(update)
		return function()
			connection:Disconnect()
			stands:Destroy()
			if shared then
				model.Parent = nil
			else
				model:Destroy()
			end
			camera:Destroy()
		end
	end, { p.Width, p.Height, table.concat(key, ";") } :: { any })
	local lights = p.Lights
	return e("ViewportFrame", {
		ref = ref,
		Name = "HatchGardenView",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		-- A fresh upgrade washes the garden in its colour.
		Ambient = if lights
			then p.At(function(t)
				local flare, color = strongest(lights, t)
				return AMBIENT:Lerp(color, flare * 0.4)
			end)
			else AMBIENT,
		LightColor = if lights
			then p.At(function(t)
				local flare, color = strongest(lights, t)
				return SUNLIGHT:Lerp(color, flare * 0.3)
			end)
			else SUNLIGHT,
		LightDirection = Vector3.new(0.55, -1, -0.45),
		ZIndex = 4,
	})
end

-- Light pillars fall onto the pedestal of a Legendary or Mythic egg.
local function Beams(p: { At: ((number) -> any) -> any, Spot: Spot, Light: Light })
	local at, spot, light = p.At, p.Spot, p.Light
	local beams = {}
	local layout = { { 0, 0.62, 1 }, { -7, 0.34, 0.7 }, { 7, 0.34, 0.7 }, { -15, 0.22, 0.45 }, { 15, 0.22, 0.45 } }
	for k, item in layout do
		local angle, width, strength = item[1], item[2], item[3]
		beams["Beam" .. k] = e("Frame", {
			Name = "HatchHeavenBeam",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromOffset(spot.x, spot.y),
			Size = UDim2.fromOffset(spot.size * width, spot.y + spot.size),
			Rotation = at(function(t)
				return angle + math.sin(t * 0.9 + k) * 1.5
			end),
			BackgroundColor3 = at(function(t)
				return light.color(t):Lerp(Color3.new(1, 1, 1), 0.25)
			end),
			BackgroundTransparency = at(function(t)
				local pulse = 0.85 + 0.15 * math.sin(t * 3 + k)
				return 1 - light.epic(t) * 0.6 * strength * pulse
			end),
			BorderSizePixel = 0,
			ZIndex = 7,
		}, {
			-- Soft edges across the pillar; its foot hides behind the egg.
			Fade = e("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.3, 0.6),
					NumberSequenceKeypoint.new(0.5, 0.1),
					NumberSequenceKeypoint.new(0.7, 0.6),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		})
	end
	return e(
		"Frame",
		{ Name = "HatchHeavenBeams", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 7 },
		beams
	)
end

function Scenery.View(p: Props)
	local at, w, h = p.At, p.Width, p.Height
	local horizon = h * Scenery.Horizon
	local children: { [string]: any } = {
		Sky = e("Frame", {
			Name = "HatchSky",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 1,
		}, { Gradient = e("UIGradient", { Color = SKY, Rotation = 90 }) }),
		-- The low sun behind the hills.
		Sun = e("ImageLabel", {
			Name = "HatchSun",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(w * 0.24, horizon - h * 0.03),
			Size = UDim2.fromOffset(h * 0.5, h * 0.5),
			Image = GLOW,
			ImageColor3 = C(255, 222, 160),
			ImageTransparency = 0.1,
			ZIndex = 2,
		}),
		Garden = e(Garden, { At = at, Now = p.Now, Width = w, Height = h, Spots = p.Spots, Lights = p.Lights }),
		-- The floor darkens under the hint and the buttons.
		Shade = e("Frame", {
			Name = "HatchFloorShade",
			Position = UDim2.fromOffset(0, h * 0.8),
			Size = UDim2.fromOffset(w, h * 0.2 + 1),
			BackgroundColor3 = C(20, 22, 40),
			BorderSizePixel = 0,
			ZIndex = 8,
		}, {
			Fade = e("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new(1, 0.45),
			}),
		}),
	}
	-- Soft clouds drift behind the trees.
	for k = 1, 5 do
		local width = w * (0.18 + (k % 3) * 0.05)
		children["Cloud" .. k] = e("ImageLabel", {
			Name = "HatchCloud",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = GLOW,
			ImageColor3 = C(255, 196, 206),
			ImageTransparency = 0.35,
			Size = UDim2.fromOffset(width, width * 0.32),
			Position = at(function(t)
				local span = w + width
				local x = (k * 0.29 * span + t * (5 + k)) % span - width / 2
				return UDim2.fromOffset(x, horizon * (0.18 + (k % 4) * 0.17))
			end),
			ZIndex = 2,
		})
	end
	-- Warm motes rise from the garden and twinkle.
	for k = 1, 16 do
		local seed = (k * 0.618) % 1
		local speed = 9 + (k % 5) * 3
		local size = 8 + (k % 4) * 4
		children["Mote" .. k] = e("ImageLabel", {
			Name = "HatchMote",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = GLOW,
			ImageColor3 = C(255, 238, 170),
			Size = UDim2.fromOffset(size, size),
			Position = at(function(t)
				local rise = (t * speed + k * 53) % (h * 0.6)
				return UDim2.fromOffset(w * seed + math.sin(t * 0.7 + k) * 22, h * 0.92 - rise)
			end),
			ImageTransparency = at(function(t)
				return 0.25 + 0.35 * (0.5 + 0.5 * math.sin(t * 2.3 + k * 1.7))
			end),
			ZIndex = 6,
		})
	end
	local lights = p.Lights
	if lights then
		-- A fresh upgrade tints the sky behind the garden. The mood layers reach a
		-- stage height above it to cover the top bar strip of the full screen.
		children.Wash = e("Frame", {
			Name = "HatchSkyWash",
			Position = UDim2.fromOffset(0, -h),
			Size = UDim2.fromScale(1, 2),
			BackgroundColor3 = at(function(t)
				local _, color = strongest(lights, t)
				return color
			end),
			BackgroundTransparency = at(function(t)
				return 1 - strongest(lights, t) * 0.32
			end),
			BorderSizePixel = 0,
			ZIndex = 3,
		}, {
			Fade = e("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.3),
					NumberSequenceKeypoint.new(0.5 + Scenery.Horizon / 2, 0),
					NumberSequenceKeypoint.new(1, 0.6),
				}),
			}),
		})
		-- Legendary and Mythic: the evening turns to night around the egg.
		children.Dim = e("Frame", {
			Name = "HatchEpicDim",
			Position = UDim2.fromOffset(0, -h),
			Size = UDim2.fromScale(1, 2),
			BackgroundColor3 = NIGHT,
			BackgroundTransparency = at(function(t)
				return 1 - epic(lights, t) * 0.5
			end),
			BorderSizePixel = 0,
			ZIndex = 5,
		})
		for i, spot in p.Spots do
			local light = lights[i]
			if light then
				children["Beams" .. i] = e(Beams, { At = at, Spot = spot, Light = light })
			end
		end
	end
	return e("Frame", {
		Name = "HatchScenery",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 0,
	}, children)
end

return Scenery
