--!strict
-- Continuous paving and clean outside edging from the same rectangle union.
local Polish = {}
type Rect = { number }
local function hide(part: BasePart)
	if part:GetAttribute("BeforeGeometryPolish") == nil then
		part:SetAttribute("BeforeGeometryPolish", part.Transparency)
	end
	part.Transparency = 1
	for _, child in part:GetChildren() do
		if child:IsA("Decal") then
			child.Transparency = 1
		end
	end
end

function Polish.hideLobbyArrows(map: Instance): number
	if map.Name ~= "World1" then
		return 0
	end
	local hidden = 0
	for _, name in { "SkippingWorld", "SurfaceSeparation" } do
		local section = map:FindFirstChild(name)
		if section then
			for _, part in section:GetChildren() do
				if part:IsA("BasePart") and (part.Name == "ArrowStem" or part.Name == "ArrowArm") then
					if part.Transparency < 1 then
						hidden += 1
					end
					hide(part)
				end
			end
		end
	end
	return hidden
end

function Polish.apply(map: any)
	-- Run before the paving guard so an existing authored lobby is not rebuilt.
	Polish.hideLobbyArrows(map)
	if map:FindFirstChild("GeometryPolish") then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "GeometryPolish", map
	local function slab(name: string, r: Rect, y: number, color: Color3, textured: boolean)
		local part = Instance.new("Part")
		part.Name, part.Size = name, Vector3.new(r[2] - r[1], 0.05, r[4] - r[3])
		part.CFrame = CFrame.new((r[1] + r[2]) / 2, y - 0.025, (r[3] + r[4]) / 2)
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
		part.Material, part.Color = Enum.Material.Plastic, color
		part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if textured then
			local t = Instance.new("Texture")
			t.Name, t.Texture, t.Face = "Studs", "rbxassetid://88156646156237", Enum.NormalId.Top
			t.StudsPerTileU, t.StudsPerTileV, t.Transparency = 8, 8, 0.45
			t.Color3, t.OffsetStudsU, t.OffsetStudsV = color, r[1] % 8, r[3] % 8
			t.Parent = part
		end
		part.Parent = folder
		return part
	end
	local layout = map:FindFirstChild("TwoAxesLayout")
	if layout then
		local paths: { Rect } = {}
		local top = map.Lobby.ThrowingApron.Position.Y - 0.3 + 0.26
		local selected: { [Instance]: boolean } = {}
		for _, p in layout.Paving:GetChildren() do
			if p:IsA("BasePart") then
				selected[p] = true
				local a, b = p.Position - p.Size / 2, p.Position + p.Size / 2
				local r = { a.X, b.X, a.Z, b.Z }
				table.insert(paths, r)
				hide(p)
				slab(p.Name, r, top, p.Color, true)
			end
		end
		for _, p in layout.Borders:GetChildren() do
			if p:IsA("BasePart") then
				selected[p] = true
				hide(p)
			end
		end
		local function inside(x: number, z: number, padding: number): boolean
			for _, r in paths do
				if x > r[1] - padding and x < r[2] + padding and z > r[3] - padding and z < r[4] + padding then
					return true
				end
			end
			return false
		end
		local xs, zs = {}, {}
		for _, r in paths do
			for _, x in { r[1] - 0.35, r[1], r[2], r[2] + 0.35 } do
				xs[x] = true
			end
			for _, z in { r[3] - 0.35, r[3], r[4], r[4] + 0.35 } do
				zs[z] = true
			end
		end
		local function sorted(t: { [number]: boolean }): { number }
			local a = {}
			for key in t do
				table.insert(a, key)
			end
			table.sort(a)
			return a
		end
		local xValues, zValues = sorted(xs), sorted(zs)
		local open: { [string]: Rect } = {}
		local edges: { Rect } = {}
		for zi = 1, #zValues - 1 do
			local spans: { Rect } = {}
			local start: number? = nil
			for xi = 1, #xValues - 1 do
				local x, z = (xValues[xi] + xValues[xi + 1]) / 2, (zValues[zi] + zValues[zi + 1]) / 2
				local ring = inside(x, z, 0.35) and not inside(x, z, 0)
				if ring and not start then
					start = xValues[xi]
				end
				if start and (not ring or xi == #xValues - 1) then
					table.insert(spans, { start, ring and xValues[xi + 1] or xValues[xi] })
					start = nil
				end
			end
			local nextOpen: { [string]: Rect } = {}
			for _, span in spans do
				local key = span[1] .. ":" .. span[2]
				local r: Rect = open[key] or { span[1], span[2], zValues[zi], zValues[zi + 1] }
				if open[key] then
					r[4] = zValues[zi + 1]
				else
					table.insert(edges, r)
				end
				nextOpen[key] = r
			end
			open = nextOpen
		end
		for _, r in edges do
			slab("OutsideEdge", r, top, Color3.fromRGB(115, 135, 156), false)
		end
		-- Cut old stepping stones at the paving boundary instead of stacking them.
		for _, p in map.SkippingWorld.World2Portal.SakuraCourtyard:GetChildren() do
			if p:IsA("BasePart") and p.Name == "ApproachSlab" then
				selected[p] = true
				hide(p)
				local a, b = p.Position - p.Size / 2, p.Position + p.Size / 2
				local pieces: { Rect } = { { a.X, b.X, a.Z, b.Z } }
				for _, cut in paths do
					local remaining: { Rect } = {}
					for _, r in pieces do
						local x0, x1, z0, z1 =
							math.max(r[1], cut[1] - 0.35),
							math.min(r[2], cut[2] + 0.35),
							math.max(r[3], cut[3] - 0.35),
							math.min(r[4], cut[4] + 0.35)
						if x1 <= x0 or z1 <= z0 then
							table.insert(remaining, r)
						else
							for _, piece in
								{
									{ r[1], x0, r[3], r[4] },
									{ x1, r[2], r[3], r[4] },
									{ x0, x1, r[3], z0 },
									{ x0, x1, z1, r[4] },
								}
							do
								if piece[2] - piece[1] > 0.01 and piece[4] - piece[3] > 0.01 then
									table.insert(remaining, piece)
								end
							end
						end
					end
					pieces = remaining
				end
				for _, r in pieces do
					slab("PortalApproach", r, top, p.Color, true)
				end
			end
		end
		for _, render in map.SurfaceSeparation:GetChildren() do
			local original = render:FindFirstChild("OriginalPart")
			if
				original
				and original:IsA("ObjectValue")
				and original.Value
				and selected[original.Value]
				and render:IsA("BasePart")
			then
				hide(render)
			end
		end
	end
	-- World2 has a one-stud exposed strip between apron and the first pitch.
	local apron, pitch = map.Lobby.ThrowingApron, map.SkippingWorld.Water_1
	local front, back = pitch.Position.Z + pitch.Size.Z / 2, apron.Position.Z - apron.Size.Z / 2
	if back - front > 0.01 then
		slab(
			"ApronJoin",
			{ pitch.Position.X - pitch.Size.X / 2, pitch.Position.X + pitch.Size.X / 2, front, back },
			apron.Position.Y + apron.Size.Y / 2,
			apron.Color,
			true
		)
	end
	folder:SetAttribute("Version", 1)
end

return Polish
