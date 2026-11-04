--!strict
-- Ball stand in the egg stand's look: path-grey tiers on whole lobby studs, a dark rim one stud
-- wide around each tread and dark frames under the pads. Runs on the final BallShop after
-- WorldLayout and before LobbyPaths, which paves around the stand's new footprint.
-- Idempotent: tier geometry is recomputed from the authored parts kept in attributes.
local Palette = require(script.Parent.LobbyPalette)
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local Style = {}
local V = Vector3.new
local RIM_THICKNESS = 0.05
local CLEARANCE = 0.3 -- grey between a pad frame and the rim, per side; the frame ring is as wide

local function studs(part: BasePart, faces: { Enum.NormalId }, tile: number)
	for _, t in part:GetChildren() do
		if t:IsA("Texture") then
			t:Destroy()
		end
	end
	for _, face in faces do
		local t = Instance.new("Texture")
		t.Name, t.Texture, t.Face = "Studs" .. face.Name, Palette.Studs, face
		t.StudsPerTileU, t.StudsPerTileV = tile, tile
		t.Transparency, t.Parent = Palette.StudsTransparency, part
	end
end

local function authored(part: BasePart): (Vector3, CFrame)
	if typeof(part:GetAttribute("OriginalSize")) ~= "Vector3" then
		part:SetAttribute("OriginalSize", part.Size)
		part:SetAttribute("OriginalCFrame", part.CFrame)
	end
	local cf = part:GetAttribute("OriginalCFrame") :: CFrame
	assert(cf.Rotation:FuzzyEq(CFrame.identity, 0.001), "Turned ball stand tier")
	return part:GetAttribute("OriginalSize") :: Vector3, cf
end

function Style.apply(world: Instance): number
	if world.Name ~= "World1" then
		return 0
	end
	local shop = Refs.balls(world)
	local structure = shop and shop:FindFirstChild("Structure")
	local displays = shop and shop:FindFirstChild("Displays")
	local lower = structure and structure:FindFirstChild("LowerTier")
	local upper = structure and structure:FindFirstChild("UpperTier")
	if not (structure and displays and lower and upper and lower:IsA("BasePart") and upper:IsA("BasePart")) then
		return 0
	end
	local p = Palette.GroundStudPitch * Scale.factor(world)
	local tile = p * Palette.StudsPerTexture
	local function cells(x: number): number
		return math.max(1, math.round(x / p)) * p
	end
	local lowerSize, lowerCf = authored(lower)
	local _, upperCf = authored(upper)
	-- The stand faces +X: the front line, floor, upper top and centre line stay as authored.
	local front = lowerCf.X + lowerSize.X / 2
	local floor = lowerCf.Y - lowerSize.Y / 2
	local upperTop = upperCf.Y + upper:GetAttribute("OriginalSize").Y / 2
	local centreZ = lowerCf.Z
	local length = cells(lowerSize.Z)
	local z0, z1 = centreZ - length / 2, centreZ + length / 2
	-- Each tread: a rim at its open edges and four studs of grey for the pads between them.
	local grey = 4 * p
	local lowerTop = floor + p
	local exposed = p + grey
	local upperDepth = p + grey + p
	local riser = front - exposed
	local back = riser - upperDepth
	lower.Size = V(front - back, lowerTop - floor, length)
	lower.CFrame = CFrame.new((front + back) / 2, (floor + lowerTop) / 2, centreZ)
	upper.Size = V(upperDepth, upperTop - lowerTop, length)
	upper.CFrame = CFrame.new((riser + back) / 2, (lowerTop + upperTop) / 2, centreZ)
	for _, tier in { lower, upper } do
		tier.Color, tier.Material = Palette.Path, Enum.Material.SmoothPlastic
		studs(
			tier,
			{ Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right },
			tile
		)
	end

	local old = structure:FindFirstChild("Rim")
	if old then
		old:Destroy()
	end
	local rim = Instance.new("Model")
	rim.Name = "Rim"
	local strips = {
		-- x0, x1, z0, z1, top
		{ front - p, front, z0, z1, lowerTop },
		{ riser, front - p, z0, z0 + p, lowerTop },
		{ riser, front - p, z1 - p, z1, lowerTop },
		{ riser - p, riser, z0, z1, upperTop },
		{ back, back + p, z0, z1, upperTop },
		{ back + p, riser - p, z0, z0 + p, upperTop },
		{ back + p, riser - p, z1 - p, z1, upperTop },
	}
	for _, s in strips do
		local strip = Instance.new("Part")
		strip.Name, strip.Color, strip.Material = "RimEdge", Palette.PathEdge, Enum.Material.SmoothPlastic
		strip.Size = V(s[2] - s[1], RIM_THICKNESS, s[4] - s[3])
		strip.CFrame = CFrame.new((s[1] + s[2]) / 2, s[5] + RIM_THICKNESS / 2, (s[3] + s[4]) / 2)
		strip.Anchored, strip.CanCollide, strip.CanTouch, strip.CanQuery, strip.CastShadow =
			true, false, false, false, false
		strip.TopSurface, strip.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		studs(strip, { Enum.NormalId.Top }, tile)
		strip.Parent = rim
	end
	rim.Parent = structure

	-- Pads: three by four studs of grey on a dark frame, centred on their tread's grey band.
	local padSize = V(3 * p, 0, 4 * p)
	local ring = (grey - 2 * CLEARANCE - padSize.X) / 2
	local frameSize = V(padSize.X + 2 * ring, 0, padSize.Z + 2 * ring)
	local moved = 0
	for _, display in displays:GetChildren() do
		local pedestal = display:FindFirstChild("Pedestal")
		local top = display:FindFirstChild("DisplayTop")
		if not (display:IsA("Model") and pedestal and top and pedestal:IsA("BasePart") and top:IsA("BasePart")) then
			continue
		end
		local onLower = pedestal.Position.X > riser - 0.5 * p
		local x = if onLower then riser + grey / 2 else back + p + grey / 2
		local y = (if onLower then lowerTop else upperTop) + pedestal.Size.Y / 2
		local delta = V(x, y, pedestal.Position.Z) - pedestal.Position
		if delta.Magnitude > 0.0001 then
			display:PivotTo(display:GetPivot() + delta)
			-- World-space fallbacks of the ball animation follow; the local ones ride with DisplayTop.
			local ball = display:FindFirstChild("Ball")
			if ball then
				local base = ball:GetAttribute("DisplayBasePivot")
				if typeof(base) == "CFrame" then
					ball:SetAttribute("DisplayBasePivot", base + delta)
				end
				local label = ball:GetAttribute("DisplayLabelBase")
				if typeof(label) == "Vector3" then
					ball:SetAttribute("DisplayLabelBase", label + delta)
				end
			end
			moved += 1
		end
		pedestal.Size = V(frameSize.X, pedestal.Size.Y, frameSize.Z)
		pedestal.Color, pedestal.Material = Palette.PathEdge, Enum.Material.SmoothPlastic
		studs(pedestal, {}, tile)
		top.Size = V(padSize.X, top.Size.Y, padSize.Z)
		top.CFrame = pedestal.CFrame * CFrame.new(0, pedestal.Size.Y / 2 + top.Size.Y / 2, 0)
		top.Color, top.Material = Palette.Path, Enum.Material.SmoothPlastic
		studs(top, { Enum.NormalId.Top }, tile)
	end
	return moved
end

return Style
