--!strict
-- Flat vector chevrons: no image permissions or font substitution at runtime.
local Palette = require(script.Parent.LobbyPalette)
local Arrows = {}
local V = Vector3.new
local points = {
	Vector2.new(24, 112),
	Vector2.new(24, 48),
	Vector2.new(128, 136),
	Vector2.new(232, 48),
	Vector2.new(232, 112),
	Vector2.new(128, 200),
}
local triangles = { { 1, 2, 3 }, { 3, 4, 5 }, { 1, 3, 6 }, { 3, 5, 6 } }

local function triangle(parent: Model, a: Vector3, b: Vector3, c: Vector3)
	local ab, ac, bc = b - a, c - a, c - b
	if ab:Dot(ab) > ac:Dot(ac) and ab:Dot(ab) > bc:Dot(bc) then
		a, c = c, a
	elseif ac:Dot(ac) > bc:Dot(bc) then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	for _, spec in
		{
			{ length = math.abs(ab:Dot(back)), frame = CFrame.fromMatrix((a + b) / 2, right, up, back) },
			{ length = math.abs(ac:Dot(back)), frame = CFrame.fromMatrix((a + c) / 2, -right, up, -back) },
		}
	do
		if spec.length > 0.001 then
			local p = Instance.new("WedgePart")
			p.Name, p.Size, p.CFrame = "Ink", V(0.05, height, spec.length), spec.frame
			p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
			p.Color, p.Material = Palette.PathArrow, Enum.Material.SmoothPlastic
			p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			p.Parent = parent
		end
	end
end

-- Authored chevron spacing; the glyph is 1.5 spacings wide and one spacing long.
Arrows.Spacing = 10

-- `scale` is the world scale factor.
function Arrows.apply(paths: Instance, start: Vector3, finish: Vector3, scale: number): Model
	local spacing = Arrows.Spacing * scale
	local s = spacing / 8 -- every other length was measured at an 8-stud spacing
	local found = paths:FindFirstChild("KickPathArrows")
	local root: Model
	if found then
		assert(found:IsA("Model"))
		root = found
	else
		root = Instance.new("Model")
		root.Name, root.Parent = "KickPathArrows", paths
	end
	local legacy = paths:FindFirstChild("VFX_KickPathArrows", true)
	if legacy then
		for _, beam in legacy:GetDescendants() do
			if beam:IsA("Beam") then
				beam.Enabled = false
				beam.Texture = "rbxasset://textures/ui/Settings/LeaveGame/artAssets_DownArrow@3x.png"
			end
		end
		legacy.Parent = root
	end
	local foundOrigin = root:FindFirstChild("Origin")
	local origin: BasePart
	if foundOrigin then
		assert(foundOrigin:IsA("BasePart"))
		origin = foundOrigin
	else
		origin = Instance.new("Part")
		origin.Name, origin.Size, origin.Transparency = "Origin", V(0.2, 0.2, 0.2), 1
		origin.Anchored, origin.CanCollide, origin.CanTouch, origin.CanQuery = true, false, false, false
		origin.Parent = root
	end
	origin:SetAttribute("PartRole", "HiddenVisual")
	origin:SetAttribute("Purpose", "Origin for animated kick direction chevrons")
	origin.CFrame = CFrame.lookAt(start, finish)
	local length = (finish - start).Magnitude
	local count = math.ceil(length / spacing)
	if
		root:GetAttribute("GeometryVersion") ~= 2
		or root:GetAttribute("ArrowCount") ~= count
		or root:GetAttribute("ArrowSpacing") ~= spacing
	then
		for _, child in root:GetChildren() do
			if child:IsA("Model") and child:GetAttribute("ArrowSlot") ~= nil then
				child:Destroy()
			end
		end
		for i = 0, count - 1 do
			local arrow = Instance.new("Model")
			arrow.Name = "Chevron" .. i
			arrow.WorldPivot = CFrame.identity
			arrow:SetAttribute("ArrowSlot", i)
			for _, ids in triangles do
				local positions = {}
				for _, id in ids do
					local p = points[id]
					table.insert(positions, V((p.X - 128) * 12 * s / 256, 0, (128 - p.Y) * 8 * s / 256))
				end
				triangle(arrow, positions[1], positions[2], positions[3])
			end
			arrow:PivotTo(origin.CFrame * CFrame.new(0, 0, -2.5 * s - i * spacing))
			for _, p in arrow:GetChildren() do
				if p:IsA("BasePart") then
					p.Transparency = if i > 0 and i * spacing < length - 5 * s then 0 else 1
				end
			end
			arrow.Parent = root
		end
	end
	root:SetAttribute("GeometryVersion", 2)
	root:SetAttribute("ArrowCount", count)
	root:SetAttribute("ArrowSpacing", spacing)
	root:SetAttribute("PathLength", length)
	for _, arrow in root:GetChildren() do
		if arrow:IsA("Model") and arrow:GetAttribute("ArrowSlot") ~= nil then
			for _, ink in arrow:GetChildren() do
				if ink:IsA("BasePart") then
					ink:SetAttribute("PartRole", "HiddenVisual")
					ink:SetAttribute("Purpose", "Animated direction chevron; hidden while fading at the path ends")
				end
			end
		end
	end
	root:AddTag("LobbyPathArrowRoot")
	return root
end
return Arrows
