--!strict
-- Minimal studded look: lavender steps, and on each slot a periwinkle pad inside a cream frame.
-- Idempotent: colours, studs and pad height are recomputed from the authored parts every run.
local Style = {}
local C, V = Color3.fromRGB, Vector3.new
local STUDS = "rbxassetid://88156646156237"
local STUD_FACES =
	{ Enum.NormalId.Top, Enum.NormalId.Right, Enum.NormalId.Left, Enum.NormalId.Front, Enum.NormalId.Back }
local step = C(196, 196, 244)
local frame = C(244, 232, 226)
local pad = C(172, 188, 240)

local function studs(part: BasePart, faces: { Enum.NormalId })
	for _, t in part:GetChildren() do
		if t:IsA("Texture") then
			t:Destroy()
		end
	end
	for _, face in faces do
		local t = Instance.new("Texture")
		t.Name = "Studs" .. face.Name
		t.Texture = STUDS
		t.Face = face
		t.StudsPerTileU = 8
		t.StudsPerTileV = 8
		t.Color3 = part.Color
		t.Transparency = 0.22
		t.Parent = part
	end
end

local function paint(part: BasePart, color: Color3)
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
end

-- SurfaceSeparation draws offset copies of authored parts and hides the originals. The stand
-- touches no coplanar surfaces after the restyle, so drop its copies and show its own parts.
local function unseparate(map, stand)
	local folder = map:FindFirstChild("SurfaceSeparation")
	if folder then
		for _, render in folder:GetChildren() do
			local source = render:FindFirstChild("OriginalPart")
			local original = source and source:IsA("ObjectValue") and source.Value
			if original and (original:IsDescendantOf(stand) or original.Parent == nil) then
				render:Destroy()
			end
		end
	end
	for _, part in stand:GetDescendants() do
		if part:IsA("BasePart") then
			local saved = part:GetAttribute("SurfaceSeparationTransparency")
			if typeof(saved) == "number" then
				part.Transparency = saved
			end
			part:SetAttribute("SurfaceSeparationId", nil)
			part:SetAttribute("SurfaceSeparationTransparency", nil)
			part:SetAttribute("SurfaceSeparationSkip", nil)
		end
	end
	stand:SetAttribute("SurfaceSeparationSkip", true)
end

function Style.apply(map)
	local stand = assert(map:FindFirstChild("EmptyItemStand"))
	unseparate(map, stand)
	-- The earlier navy shop dressing (header, posts, neon rims, badges) is retired.
	local old = stand:FindFirstChild("BallShopDecor")
	if old then
		old:Destroy()
	end
	for _, name in { "LowerTier", "UpperTier" } do
		local tier = assert(stand:FindFirstChild(name))
		paint(tier, step)
		studs(tier, STUD_FACES)
	end
	for slot = 1, 10 do
		local top = assert(stand:FindFirstChild("DisplayTop" .. slot))
		local base = assert(stand:FindFirstChild("EmptyPedestal" .. slot))
		paint(base, frame)
		studs(base, {})
		paint(top, pad)
		-- A visibly raised inner pad sitting on the frame, as in the reference.
		local height = base.Size.Y * 1.5
		top.Size = V(top.Size.X, height, top.Size.Z)
		top.CFrame = base.CFrame * CFrame.new(0, base.Size.Y / 2 + height / 2, 0)
		studs(top, { Enum.NormalId.Top })
	end
end

return Style
