--!strict
local Aura = {}
local C = Color3.fromRGB

-- Transparent sprites from the VfxForge library.
type Layer = {
	asset: number,
	color: Color3,
	accent: Color3?,
	size: number,
	speed: number,
	travel: number,
	opacity: number,
	copies: number?,
	radius: number?,
}

local THEMES: { [string]: { Layer } } = {
	Meadow = {
		{
			asset = 7096972007,
			color = C(203, 255, 125),
			accent = C(87, 213, 52),
			size = 0.17,
			speed = 14,
			travel = 0.025,
			opacity = 0.94,
			copies = 8,
			radius = 0.36,
		},
		{ asset = 6862984716, color = C(160, 246, 96), size = 0.88, speed = 0, travel = 0.04, opacity = 0.84 },
	},
	Glacier = {
		{
			asset = 10439119562,
			color = C(236, 255, 255),
			accent = C(133, 218, 255),
			size = 0.48,
			speed = -10,
			travel = 0.04,
			opacity = 1,
			copies = 6,
			radius = 0.23,
		},
		{ asset = 6862984716, color = C(189, 246, 255), size = 0.63, speed = 0, travel = 0.46, opacity = 0.96 },
	},
	Celestial = {
		{ asset = 8048608283, color = C(255, 170, 43), size = 1.12, speed = 18, travel = 0.035, opacity = 1 },
		{ asset = 10176632695, color = C(255, 237, 155), size = 0.99, speed = -25, travel = 0.05, opacity = 1 },
		{ asset = 4963436775, color = C(255, 246, 183), size = 0.70, speed = 13, travel = 0.08, opacity = 0.96 },
	},
	Magma = {
		{ asset = 7150933366, color = C(212, 57, 18), size = 1.14, speed = 0, travel = 0, opacity = 1 },
		{ asset = 7150933366, color = C(255, 204, 80), size = 1.14, speed = 0, travel = 0, opacity = 1 },
	},
	Void = {
		{ asset = 12318428842, color = C(146, 73, 255), size = 1.13, speed = -32, travel = -0.12, opacity = 1 },
		{ asset = 5726444189, color = C(228, 153, 255), size = 0.99, speed = 29, travel = -0.13, opacity = 0.95 },
	},
}

THEMES.Kelp = {
	{
		asset = 7096972007,
		color = C(236, 190, 52),
		accent = C(56, 184, 139),
		size = 0.19,
		speed = 11,
		travel = 0.025,
		opacity = 0.85,
		copies = 6,
		radius = 0.35,
	},
	{ asset = 6862984716, color = C(52, 211, 175), size = 0.8, speed = 0, travel = 0.07, opacity = 0.65 },
}
THEMES.Leviathan = {
	{ asset = 10176632695, color = C(255, 213, 84), size = 0.95, speed = 16, travel = 0.04, opacity = 0.9 },
	{ asset = 4963436775, color = C(35, 217, 230), size = 0.65, speed = -13, travel = 0.05, opacity = 0.85 },
}
THEMES.Treasure = {
	{ asset = 10176632695, color = C(255, 209, 69), size = 0.92, speed = -14, travel = 0.04, opacity = 0.85 },
	{ asset = 4963436775, color = C(112, 239, 240), size = 0.6, speed = 20, travel = 0.04, opacity = 0.8 },
}
THEMES.Abyss = {
	{ asset = 12318428842, color = C(45, 84, 180), size = 1.05, speed = -22, travel = -0.08, opacity = 0.85 },
	{ asset = 5726444189, color = C(35, 217, 246), size = 0.85, speed = 25, travel = -0.06, opacity = 0.85 },
}
THEMES.Jelly = {
	{ asset = 6862984716, color = C(103, 230, 255), size = 0.8, speed = 0, travel = 0.3, opacity = 0.85 },
	{ asset = 5726444189, color = C(195, 139, 255), size = 0.97, speed = 17, travel = 0.08, opacity = 0.8 },
}

function Aura.create(folder: Folder, theme: string, position: Vector3, scale: number)
	local specs = THEMES[theme]
	local plane = Instance.new("Part")
	plane.Name = theme .. "EggAura"
	plane.Size = Vector3.new(13.4 * scale, 0.05, 13.4 * scale)
	plane.Position = position + Vector3.new(0, 0.12 * scale, 0)
	plane.Transparency = 1
	plane.Anchored = true
	plane.CanCollide, plane.CanTouch, plane.CanQuery = false, false, false
	plane.CastShadow = false
	plane.Parent = folder

	local gui = Instance.new("SurfaceGui")
	gui.Name = "AuraTextures"
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(768, 768)
	gui.LightInfluence = 0
	gui.Enabled = false
	gui.Parent = plane

	local layers: { { ImageLabel } } = {}
	for index, spec in specs do
		local images = {}
		for copy = 1, spec.copies or 1 do
			local image = Instance.new("ImageLabel")
			image.Name = string.format("Layer%d_%d", index, copy)
			image.BackgroundTransparency = 1
			image.AnchorPoint = Vector2.new(0.5, 0.5)
			image.Image = "rbxassetid://" .. spec.asset
			image.ImageColor3 = if copy % 2 == 0 then spec.accent or spec.color else spec.color
			image.ZIndex = index
			image.Parent = gui
			images[copy] = image
		end
		layers[index] = images
	end

	return {
		plane = plane,
		update = function(active: boolean, time: number, phase: number)
			if gui.Enabled ~= active then
				gui.Enabled = active
			end
			if not active then
				return
			end
			local breath = (1 + math.sin(phase)) * 0.5
			for index, spec in specs do
				local progress = breath
				local strength = 0.66 + breath * 0.34
				if theme == "Glacier" and index == 2 then
					progress = (phase / (2 * math.pi)) % 1
					strength = math.sin(math.pi * progress)
				elseif theme == "Magma" and index == 2 then
					strength = 0.35 + 0.55 * breath + 0.10 * math.sin(time * 4.7)
				end
				local size = spec.size + spec.travel * progress
				local images = layers[index]
				local radius = spec.radius or 0
				for copy, image in images do
					local angle = (time * spec.speed + (copy - 1) * 360 / #images) % 360
					local radians = math.rad(angle)
					image.Position = UDim2.fromScale(0.5 + math.cos(radians) * radius, 0.5 + math.sin(radians) * radius)
					image.Size = UDim2.fromScale(size, size)
					image.Rotation = angle + 90
					image.ImageTransparency = 1 - spec.opacity * strength
				end
			end
		end,
	}
end

return Aura
