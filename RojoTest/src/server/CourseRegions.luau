--!strict
-- The eight live pitch footprints own shore colours, skins and complete natural props.
-- Legacy five-section collision remains untouched underneath these cosmetic skins.
local Palette = require(script.Parent.CoursePalette)
local Studs = require(script.Parent.LobbyPalette)
local Regions = {}
local V = Vector3.new
local leaves = { Shrub = true, LeafBlock = true, LeafCrown = true, PalmBlade = true }
local lights = { PalmHeart = true, CliffCap = true }
local rocks = {
	SmallStone = true,
	RockShoulder = true,
	StoneChip = true,
	RockMass = true,
	RockCore = true,
	RockCrest = true,
	RockSlope = true,
	SmallRock = true,
	CliffPillar = true,
	CliffShoulder = true,
}

local function hide(p: BasePart): boolean
	local changed = p.Transparency ~= 1
	if p:GetAttribute("BeforeCourseRegionTransparency") == nil then
		p:SetAttribute("BeforeCourseRegionTransparency", p.Transparency)
	end
	p.Transparency = 1
	p:SetAttribute("PartRole", if p.CanCollide then "Collision" else "SourceGeometry")
	for _, t in p:GetChildren() do
		if t:IsA("Decal") then
			t.Transparency = 1
		end
	end
	return changed
end

local function body(bank: BasePart, field: BasePart, color: Color3, bottom: number): BasePart
	local top = bank.Position.Y - bank.Size.Y / 2
	local height = top - bottom
	assert(height > 0, "Bank body must have positive height")
	local p = Instance.new("Part")
	local tier = if bank.Name:match("_1$") then "Inner" else "Outer"
	p.Name = tier .. (if bank.Position.X < field.Position.X then "West" else "East")
	p.Size = V(bank.Size.X, height, field.Size.Z)
	p.CFrame = CFrame.new(bank.Position.X, (top + bottom) / 2, field.Position.Z) * bank.CFrame.Rotation
	p.Color, p.Material = color, Enum.Material.Plastic
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p:SetAttribute("PartRole", "BankSkin")
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
		local t = Instance.new("Texture")
		t.Name, t.Texture, t.Face = "BankStuds", Studs.Studs, face
		t.StudsPerTileU, t.StudsPerTileV, t.Transparency = 8, 8, Studs.StudsTransparency
		t.Parent = p
	end
	return p
end

local function natural(detail: Model, zone: any, palette: any): boolean
	if not detail:FindFirstChildWhichIsA("BasePart", true) then
		return false
	end
	local canMove = true
	for _, p in detail:GetDescendants() do
		if p:IsA("BasePart") then
			canMove = canMove and not (p.CanCollide or p.CanTouch or p.CanQuery)
			local color = if leaves[p.Name]
				then palette.leaf
				elseif lights[p.Name] then palette.light
				elseif rocks[p.Name] then palette.rock
				elseif p.Name == "FlowerPetals" then palette.flower
				else nil
			if color then
				if p:GetAttribute("BeforeCourseRegionColor") == nil then
					p:SetAttribute("BeforeCourseRegionColor", p.Color)
				end
				p.Color = color
				for _, t in p:GetChildren() do
					if t:IsA("Texture") then
						t.Color3 = color
					end
				end
			end
		end
	end
	detail:SetAttribute("CourseRegionIndex", zone:GetAttribute("ZoneIndex"))
	if not canMove then
		return false
	end
	local cf, size = detail:GetBoundingBox()
	local field = zone.Field
	local low, high = field.Position.Z - field.Size.Z / 2 + 1, field.Position.Z + field.Size.Z / 2 - 1
	if size.Z > high - low then
		return false
	end
	local z = math.clamp(cf.Z, low + size.Z / 2, high - size.Z / 2)
	local delta = z - cf.Z
	if math.abs(delta) < 0.001 then
		return false
	end
	if detail:GetAttribute("BeforeCourseRegionPivot") == nil then
		detail:SetAttribute("BeforeCourseRegionPivot", detail:GetPivot())
	end
	detail:PivotTo(detail:GetPivot() + V(0, 0, delta))
	return true
end

function Regions.apply(world: any): any
	local course = world.FootballCourse
	local hidden, rebuilt, details, moved = 0, 0, 0, 0
	local bottom = math.huge
	for i, p in course:GetDescendants() do
		if p:IsA("BasePart") then
			if p.Name == "InnerBankEarth" then
				bottom = math.min(bottom, p.Position.Y - p.Size.Y / 2)
			end
			if
				p.Name == "GroundTile"
				or p.Name == "InnerBankEarth_Surface"
				or p.Name == "OuterBankEarth_Surface"
				or p.Name == "BankExtension"
			then
				if hide(p) then
					hidden += 1
				end
			end
		end
		if i % 1500 == 0 then
			task.wait()
		end
	end
	assert(bottom < math.huge, "Missing authored bank supports")
	for _, zone in course.Zones:GetChildren() do
		local index = zone:GetAttribute("ZoneIndex")
		local field = zone.Field
		local banks, signature =
			{}, { tostring(field.CFrame), tostring(field.Size), tostring(bottom), tostring(Palette[index].earth) }
		for _, p in zone.Geometry:GetChildren() do
			if p:IsA("BasePart") and p.Name:match("^BiomeBank%d+_[12]$") then
				table.insert(banks, p)
				table.insert(signature, p.Name .. tostring(p.CFrame) .. tostring(p.Size))
			end
		end
		assert(#banks == 4, "Each current zone needs four shore tops")
		table.sort(signature)
		local key = table.concat(signature, "|")
		local current = zone.Geometry:FindFirstChild("Banks")
		if not current or current:GetAttribute("GeometrySignature") ~= key then
			if current then
				current:Destroy()
			end
			local model = Instance.new("Model")
			model.Name = "Banks"
			model:SetAttribute("ZoneIndex", index)
			for _, bank in banks do
				body(bank, field, Palette[index].earth, bottom).Parent = model
			end
			model:SetAttribute("GeometrySignature", key)
			model.Parent = zone.Geometry
			rebuilt += 1
		end
		for _, detail in zone.Environment:GetChildren() do
			if detail:IsA("Model") and detail:GetAttribute("CourseNaturalDetail") then
				details += 1
				if natural(detail, zone, Palette[index]) then
					moved += 1
				end
			end
		end
		task.wait()
	end
	require(script.Parent.ZoneDividers).align(world)
	world:SetAttribute("CourseRegionsVersion", 1)
	return { hiddenLayers = hidden, rebuiltZones = rebuilt, naturalDetails = details, movedDetails = moved }
end

return Regions
