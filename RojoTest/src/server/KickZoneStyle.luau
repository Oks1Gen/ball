--!strict
-- One aligned footprint for the gameplay floor, whole cells and studded rim.
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Palette = require(script.Parent.LobbyPalette)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local Style = {}
local V = Vector3.new
Style.CurbWidth = 0 -- The rim is inside the floor; paths meet the physical edge.

function Style.apply(world: Instance): number
	if world.Name ~= "World1" then
		return 0
	end
	local floor = Refs.kickZoneFloor(world)
	if not floor then
		return 0
	end
	local owner = floor.Parent
	local field = assert(Refs.field(world, 1))
	if math.abs(floor.Position.X - field.Position.X) > 0.0001 then
		if floor:GetAttribute("BeforeLawnAlignment") == nil then
			floor:SetAttribute("BeforeLawnAlignment", floor.CFrame)
		end
		floor.CFrame += V(field.Position.X - floor.Position.X, 0, 0)
	end
	local k = Scale.factor(world)
	local cell, band = Palette.KickZoneCell * k, Palette.KickZoneBand * k
	local PITCH = Palette.GroundStudPitch * k
	local TILE = PITCH * Palette.StudsPerTexture
	local columns = math.round((floor.Size.X - 2 * band) / cell)
	local rows = math.round((floor.Size.Z - 2 * band) / cell)
	assert(columns > 0 and rows > 0, "Kick Zone needs complete checker cells")
	assert(math.abs(cell / PITCH - math.round(cell / PITCH)) < 0.0001, "Partial Kick Zone stud row")
	local footprint = V(columns * cell + 2 * band, floor.Size.Y, rows * cell + 2 * band)
	if (floor.Size - footprint).Magnitude > 0.0001 then
		if floor:GetAttribute("BeforeGridFloorSize") == nil then
			floor:SetAttribute("BeforeGridFloorSize", floor.Size)
			floor:SetAttribute("BeforeGridFloorCFrame", floor.CFrame)
		end
		-- Keep the course-facing edge and arenaFrame fixed while removing the lip.
		floor.CFrame *= CFrame.new(0, 0, (footprint.Z - floor.Size.Z) / 2)
		floor.Size = footprint
	end
	floor.Color = Palette.KickZoneEdge
	-- The base ends exactly at the rim. There is no exposed second outline.
	for _, texture in floor:GetChildren() do
		if texture:IsA("Texture") then
			texture:Destroy()
		end
	end
	local lobby = assert(world:FindFirstChild("Lobby"))
	local print = owner:FindFirstChild("KickZonePrint") or lobby:FindFirstChild("KickZonePrint", true)
	if print and print:IsA("BasePart") then
		print.Parent = owner
		print.Size = V(floor.Size.X, floor.Size.Z, print.Size.Z)
		print.CFrame = floor.CFrame * CFrame.new(0, floor.Size.Y / 2 + 0.12, 0) * CFrame.Angles(math.pi / 2, 0, 0)
		print:SetAttribute("PartRole", "LabelAnchor")
		for _, label in print:GetDescendants() do
			if label:IsA("TextLabel") then
				label.Text = "KICK ZONE"
			end
		end
	end
	local lettering = floor:FindFirstChild("KickZoneLettering")
	if lettering and lettering:IsA("SurfaceGui") then
		lettering.Enabled = false
	end
	local key = string.format(
		"whole-2|%s|%s|%s|%s|%d|%d|%.3f|%.3f|%.3f",
		tostring(floor.CFrame),
		tostring(floor.Size),
		tostring(Palette.KickZone),
		tostring(Palette.KickZoneChecker),
		columns,
		rows,
		cell,
		band,
		PITCH
	)
	local existing = owner:FindFirstChild("KickZoneChecker")
	if existing and existing:GetAttribute("Signature") == key then
		return 0
	end
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = "KickZoneChecker", floor.CFrame
	local top = floor.Size.Y / 2
	local function tile(parent: Instance, name: string, x0: number, x1: number, z0: number, z1: number, color: Color3)
		local part = Instance.new("Part")
		part.Name, part.Size = name, V(x1 - x0, 0.04, z1 - z0)
		part.CFrame = floor.CFrame * CFrame.new((x0 + x1) / 2, top + 0.02, (z0 + z1) / 2)
		part.Color, part.Material = color, Enum.Material.Plastic
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = true, false, false, false, false
		part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		local texture = Instance.new("Texture")
		texture.Name, texture.Texture, texture.Face = "KickZoneStuds", Palette.Studs, Enum.NormalId.Top
		texture.StudsPerTileU, texture.StudsPerTileV = TILE, TILE
		texture.OffsetStudsU, texture.OffsetStudsV = 0, 0
		texture.Transparency, texture.Parent = Palette.StudsTransparency, part
		part.Parent = parent
		return part
	end
	local x0, x1, z0, z1 = -columns * cell / 2, columns * cell / 2, -rows * cell / 2, rows * cell / 2
	for x = 0, columns - 1 do
		for z = 0, rows - 1 do
			local part = tile(
				model,
				"CheckerTile",
				x0 + x * cell,
				x0 + (x + 1) * cell,
				z0 + z * cell,
				z0 + (z + 1) * cell,
				if (x + z) % 2 == 0 then Palette.KickZoneChecker else Palette.KickZone
			)
			part:SetAttribute("GridX", x)
			part:SetAttribute("GridZ", z)
		end
	end
	local frame = Instance.new("Model")
	frame.Name, frame.Parent = "KickZoneFrame", model
	-- Front/back bars own the corners, without overlaps or mitre gaps.
	tile(frame, "EdgeCurb", x0 - band, x1 + band, z0 - band, z0, Palette.KickZoneEdge)
	tile(frame, "EdgeCurb", x0 - band, x1 + band, z1, z1 + band, Palette.KickZoneEdge)
	tile(frame, "EdgeCurb", x0 - band, x0, z0, z1, Palette.KickZoneEdge)
	tile(frame, "EdgeCurb", x1, x1 + band, z0, z1, Palette.KickZoneEdge)
	model:SetAttribute("Signature", key)
	model:SetAttribute("Columns", columns)
	model:SetAttribute("Rows", rows)
	model:SetAttribute("StudPitch", PITCH)
	if existing then
		existing:Destroy()
	end
	model.Parent = owner
	return columns * rows
end

return Style
