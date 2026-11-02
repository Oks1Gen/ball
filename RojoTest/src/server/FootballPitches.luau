--!strict
local Pitches = {}
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local WHITE = Color3.fromRGB(245, 248, 235)

function Pitches.apply(map: Instance)
	local world = assert(map:FindFirstChild("SkippingWorld"))
	local old = world:FindFirstChild("FootballPitchMarkings")
	if old then
		old:Destroy()
	end
	local container = Instance.new("Folder")
	container.Name = "FootballPitchMarkings"
	container.Parent = world
	-- Marking sizes are authored studs and shrink with the world.
	local k = Scale.factor(map)
	for i = 1, 8 do
		local surface = assert(world:FindFirstChild("Field_" .. i)) :: BasePart
		-- Keep the authored plane and all route/gameplay coordinates unchanged.
		local originalColor = surface:GetAttribute("OriginalPitchColor") :: Color3?
		if i == 1 then
			originalColor = (assert(world:FindFirstChild("BiomeBank1_1")) :: BasePart).Color
			surface:SetAttribute("OriginalPitchColor", originalColor)
		end
		if not originalColor then
			originalColor = surface:GetAttribute("FootballPitch") and Config.Biomes[i].color or surface.Color
			surface:SetAttribute("OriginalPitchColor", originalColor)
		end
		surface.Color = assert(originalColor)
		surface.Material = Enum.Material.SmoothPlastic
		surface.MaterialVariant = ""
		surface.Transparency = 0
		surface.Reflectance = 0
		surface.CanCollide = true
		surface:SetAttribute("FootballPitch", true)
		for _, texture in surface:GetChildren() do
			if texture:IsA("Decal") then
				texture.Transparency = 1
			end
		end
		local field = Instance.new("Model")
		field.Name = "Pitch" .. i
		local width, length = surface.Size.X, surface.Size.Z
		local top = surface.Size.Y / 2
		local function part(name: string, x: number, z: number, sx: number, sz: number, color: Color3, height: number?)
			local p = Instance.new("Part")
			p.Name = name
			p.Size = Vector3.new(sx, 0.025 * k, sz)
			-- Keep each overlapping render layer clear even at distant camera depths.
			local layers = { Touchline = 0.24, GoalLine = 0.32, HalfwayLine = 0.32, PenaltyAreaSide = 0.40 }
			p.CFrame = surface.CFrame * CFrame.new(x, top + (height or layers[name] or 0.32) * k, z)
			p.Anchored = true
			p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
			p.CastShadow = false
			p.Color = color
			p.Material = Enum.Material.SmoothPlastic
			p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			p.Parent = field
			return p
		end
		local stripeCount = math.max(8, math.round(length / (18 * k)))
		local stripeLength = length / stripeCount
		for stripe = 0, stripeCount - 1 do
			if stripe % 2 == 0 then
				part(
					"MownGrassStripe",
					0,
					-length / 2 + (stripe + 0.5) * stripeLength,
					width,
					stripeLength,
					originalColor:Lerp(Color3.new(0, 0, 0), 0.1),
					0.08
				)
			end
		end
		local halfWidth, halfLength = width / 2 - 2 * k, length / 2 - 2 * k
		local lineWidth = 0.45 * k
		for _, x in { -halfWidth, halfWidth } do
			part("Touchline", x, 0, lineWidth, halfLength * 2, WHITE)
		end
		for _, z in { -halfLength, 0, halfLength } do
			part(z == 0 and "HalfwayLine" or "GoalLine", 0, z, halfWidth * 2, lineWidth, WHITE)
		end
		local radius, segments = 14 * k, 48
		for segment = 0, segments - 1 do
			local a, b = segment * 2 * math.pi / segments, (segment + 1) * 2 * math.pi / segments
			local p1 = Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius)
			local p2 = Vector3.new(math.cos(b) * radius, 0, math.sin(b) * radius)
			local mid = (p1 + p2) / 2
			local height = 0.40 + (segment % 2) * 0.08
			local p = part("CentreCircle", mid.X, mid.Z, lineWidth, (p2 - p1).Magnitude + 0.025 * k, WHITE, height)
			p.CFrame = surface.CFrame
				* CFrame.lookAt(Vector3.new(mid.X, top + height * k, mid.Z), Vector3.new(p2.X, top + height * k, p2.Z))
		end
		part("CentreSpot", 0, 0, 0.9 * k, 0.9 * k, WHITE, 0.48)
		for _, direction in { -1, 1 } do
			for _, box in { { Width = 58, Depth = 30 }, { Width = 28, Depth = 12 } } do
				local edge = direction * halfLength
				local inner = edge - direction * box.Depth * k
				part("PenaltyArea", 0, inner, box.Width * k, lineWidth, WHITE)
				for _, x in { -box.Width / 2 * k, box.Width / 2 * k } do
					part("PenaltyAreaSide", x, (edge + inner) / 2, lineWidth, box.Depth * k, WHITE)
				end
			end
			part("PenaltySpot", 0, direction * (halfLength - 22 * k), 0.8 * k, 0.8 * k, WHITE)
		end
		field.WorldPivot = surface.CFrame
		field.Parent = container
		task.wait()
	end
	map:SetAttribute("FootballPitchVersion", 1)
	require(script.Parent.FootballSurface).apply(map)
end
return Pitches
