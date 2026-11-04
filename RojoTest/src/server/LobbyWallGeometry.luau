--!strict
-- Fit the actual wall solids to the stud lattice; add one upper storey (20 authored studs).
local Palette = require(script.Parent.LobbyPalette)
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local Geometry = {}
local V = Vector3.new
local EARTH = { TerraceEarth = true, RearEarthLedge = true, LeftAbutment = true, RightAbutment = true }
local CAPS = { GrassShelf = true, RearGrassLedge = true, LeftAbutmentGrassCap = true, RightAbutmentGrassCap = true }
local OWNERS = { "SideTerraces1", "SideTerraces2", "RearTerraces", "EntranceTunnel" }
-- Authored studs, multiplied by the world scale. The setback continues the measured step
-- between the upper two terraces; the waterfall top is the authored height of its lip.
local RISE_STUDS, SETBACK_STUDS, WATERFALL_TOP = 20, 8, 83

local function snap(value: number, origin: number, step: number): number
	local relative = (value - origin) / step
	return origin + math.sign(relative) * math.floor(math.abs(relative) + 0.50001) * step
end

local function base(part: BasePart): (CFrame, Vector3)
	local cf, size = part:GetAttribute("WallGridBaseCFrame"), part:GetAttribute("WallGridBaseSize")
	if typeof(cf) ~= "CFrame" or typeof(size) ~= "Vector3" then
		cf, size = part.CFrame, part.Size
		part:SetAttribute("WallGridBaseCFrame", cf)
		part:SetAttribute("WallGridBaseSize", size)
	end
	return cf :: CFrame, size :: Vector3
end

function Geometry.apply(world: any): any
	local k = Scale.factor(world)
	local PITCH, CELL = Palette.WallStudPitch * k, Palette.WallCheckerCell * k
	local RISE, SETBACK = RISE_STUDS * k, SETBACK_STUDS * k
	local field = assert(Refs.field(world, 1))
	local ground = 20.12
	for _, p in world.Lobby.Geometry:GetChildren() do
		if p:IsA("BasePart") and p.Name == "GroundTile" and p.Transparency < 1 then
			ground = p.Position.Y + p.Size.Y / 2
			break
		end
	end
	local origin = V(field.Position.X, ground, field.Position.Z + field.Size.Z / 2)
	local env = world.Lobby.Environment
	local upperBase = -math.huge
	for _, name in { "SideTerraces1", "SideTerraces2", "RearTerraces" } do
		for _, p in env[name]:GetChildren() do
			if p:IsA("BasePart") and CAPS[p.Name] then
				local cf, size = base(p)
				upperBase = math.max(upperBase, snap(cf.Y - size.Y / 2, ground, CELL))
			end
		end
	end
	local rearFront = math.huge
	for _, p in env.RearTerraces:GetChildren() do
		if p:IsA("BasePart") and CAPS[p.Name] then
			local cf, size = base(p)
			if math.abs(snap(cf.Y - size.Y / 2, ground, CELL) - upperBase) < 0.001 then
				rearFront = snap(cf.Z - size.Z / 2, origin.Z, PITCH)
			end
		end
	end
	local changed, added = 0, 0
	for _, name in OWNERS do
		local owner = env[name]
		local caps = {}
		for _, p in owner:GetChildren() do
			if not p:IsA("BasePart") or not (EARTH[p.Name] or CAPS[p.Name]) or p.Transparency == 1 then
				continue
			end
			local cf, size = base(p)
			local lo, hi = cf.Position - size / 2, cf.Position + size / 2
			local x0, x1 = snap(lo.X, origin.X, PITCH), snap(hi.X, origin.X, PITCH)
			local z0, z1 = snap(lo.Z, origin.Z, PITCH), snap(hi.Z, origin.Z, PITCH)
			local y0, y1
			if CAPS[p.Name] then
				y0 = if name == "EntranceTunnel" then upperBase else snap(lo.Y, ground, CELL)
				y1 = y0 + PITCH
				if math.abs(y0 - upperBase) < 0.001 then
					table.insert(caps, p)
				end
			else
				y0 = snap(lo.Y, ground, PITCH)
				y1 = if name == "EntranceTunnel" then upperBase else snap(hi.Y, ground, CELL)
			end
			local nextSize, nextCF =
				V(x1 - x0, y1 - y0, z1 - z0), CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
			if p.Size ~= nextSize or p.CFrame ~= nextCF then
				changed += 1
			end
			p.Size, p.CFrame = nextSize, nextCF
			local ref = p:FindFirstChild("OriginalPart")
			if
				ref
				and ref:IsA("ObjectValue")
				and ref.Value
				and ref.Value:IsA("BasePart")
				and ref.Value:IsDescendantOf(world)
			then
				local collision = ref.Value
				assert(collision.Transparency == 1, "Visible original wall needs measurement")
				base(collision)
				collision.Size, collision.CFrame = nextSize, nextCF
			end
		end
		local tier = owner:FindFirstChild("UpperTier")
		if tier then
			assert(tier:GetAttribute("Builder") == "LobbyWallGeometry", "Unowned upper wall tier")
		else
			tier = Instance.new("Model")
			tier.Name = "UpperTier"
			tier:SetAttribute("Builder", "LobbyWallGeometry")
			tier.Parent = owner
		end
		tier:SetAttribute("Setback", SETBACK)
		-- Stable source keys let a normal startup reuse the new storey.
		for index, cap in caps do
			for _, isCap in { false, true } do
				local key = (if isCap then "Grass" else "Earth") .. index
				local part
				for _, candidate in tier:GetChildren() do
					if candidate:GetAttribute("WallTierKey") == key then
						part = candidate
						break
					end
				end
				if not part then
					part = Instance.new("Part")
					part:SetAttribute("WallTierKey", key)
					part.Parent = tier
					added += 1
				end
				-- Names participate in Coverage; lookup by the persistent key below.
				local target = part :: BasePart
				local support: ObjectValue? = target:FindFirstChild("SupportCap") :: ObjectValue?
				if not support then
					local created = Instance.new("ObjectValue")
					created.Name, created.Parent = "SupportCap", target
					support = created
				end
				assert(support)
				support.Value = cap
				local y0 = if isCap then upperBase + RISE else upperBase + PITCH
				local height = if isCap then PITCH else RISE - PITCH
				local x0, x1 = cap.Position.X - cap.Size.X / 2, cap.Position.X + cap.Size.X / 2
				local z0, z1 = cap.Position.Z - cap.Size.Z / 2, cap.Position.Z + cap.Size.Z / 2
				if name == "RearTerraces" then
					z0 += SETBACK
				else
					if cap.Position.X < origin.X then
						x1 -= SETBACK
					else
						x0 += SETBACK
					end
					if name == "EntranceTunnel" then
						z0 += SETBACK
					elseif math.abs(z1 - rearFront) < 0.001 then
						-- Continue over the supported rear shelf to meet its recessed face.
						z1 += SETBACK
					end
				end
				assert(x1 > x0 and z1 > z0, "Upper tier setback exceeds its support")
				target.Size = V(x1 - x0, height, z1 - z0)
				target.CFrame = CFrame.new((x0 + x1) / 2, y0 + height / 2, (z0 + z1) / 2)
				target.Name = if isCap then "GrassShelf" else "TerraceEarth"
				target.Color = if isCap then cap.Color else Palette.Earth
				target.Material = Enum.Material.Plastic
				target.Anchored, target.CanCollide, target.CanTouch, target.CanQuery = true, false, false, false
				target.TopSurface, target.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			end
		end
		task.wait()
	end
	local delta = upperBase + RISE + PITCH - Scale.point(world, V(0, WATERFALL_TOP, 0)).Y
	for _, name in { "CornerWaterfall1", "SideWaterfall" } do
		local waterfall = env[name]
		local carrier = waterfall.VFX_Waterfall
		local outward = carrier.CFrame:VectorToWorldSpace(V(0, 0, SETBACK))
		for _, p in waterfall:GetChildren() do
			if
				p:IsA("BasePart")
				and (
					p.Name == "StreamWater"
					or p.Name == "WaterLip"
					or p.Name == "VFX_WaterfallSpring"
					or p.Name == "VFX_WaterfallTopMist"
					or p.Name == "VFX_WaterfallLipFoam"
				)
			then
				local cf, size = base(p)
				local offset = if p.Name == "VFX_WaterfallSpring"
					then Vector3.zero
					elseif p.Name == "StreamWater" then outward / 2
					else outward
				p.CFrame = cf + V(0, delta, 0) + offset
				if p.Name == "StreamWater" then
					p.Size = V(size.X, size.Y, size.Z - SETBACK)
				end
			end
		end
		for _, attachment in carrier:GetChildren() do
			if attachment:IsA("Attachment") and attachment.Name ~= "FallBottom" then
				local initial = attachment:GetAttribute("WallGridBasePosition")
				if typeof(initial) ~= "Vector3" then
					initial = attachment.Position
					attachment:SetAttribute("WallGridBasePosition", initial)
				end
				local offset = if attachment.Name == "ChannelStart" then Vector3.zero else V(0, 0, SETBACK)
				attachment.Position = (initial :: Vector3) + carrier.CFrame:VectorToObjectSpace(V(0, delta, 0)) + offset
			end
		end
	end
	world:SetAttribute("LobbyWallUpperRise", RISE)
	world:SetAttribute("LobbyWallUpperSetback", SETBACK)
	return { changed = changed, added = added, top = upperBase + RISE + PITCH, rise = RISE, setback = SETBACK }
end
return Geometry
