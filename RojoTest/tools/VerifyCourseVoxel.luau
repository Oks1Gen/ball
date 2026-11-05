-- Read-only Studio audit of voxel-styled course zones (docs/course-voxel.md).
-- Every studded face is a whole-stud rectangle on the zone grid; all cladding and props
-- are cosmetic; the old bank faces and tops are covered; the authored field is unchanged.
local world = workspace.Map.World1
local themes = require(game.ReplicatedStorage.Shared.FootballCity)
local HDStuds = require(game.ServerScriptService.Server.HDStuds)
local Palette = { pitch = 2 * (world:GetAttribute("WorldScale") or 1), layer = 0.05 }
local p = Palette.pitch
local result = { zones = {}, studdedParts = 0, coveredSamples = 0 }

local function near(x: number, step: number): boolean
	return math.abs(x / step - math.round(x / step)) < 0.002
end

for index, theme in themes do
	local zone = world.FootballCourse.Zones[string.format("Zone%02d", index)]
	if not zone:GetAttribute("VoxelStyleVersion") then
		continue
	end
	local field = zone.Field
	local frame = field.CFrame * CFrame.new(0, field.Size.Y / 2, field.Size.Z / 2)
	local ground = assert(zone.Geometry:FindFirstChild("GroundCladding"), "Missing GroundCladding")
	for _, name in { "Pitch", "BankWest", "BankEast" } do
		assert(ground:FindFirstChild(name), "Missing " .. name)
	end
	assert(not zone.Geometry:FindFirstChild("PitchMarkings"), "Old markings still in the zone")
	assert(field.Color == theme.pitch and field.CanCollide and field.Transparency == 0, "Field changed")
	local parts, pitchArea = {}, 0
	local levels = {}
	for _, root in { ground, zone.Environment.Cityscape } do
		for _, part in root:GetDescendants() do
			if part:IsA("BasePart") then
				assert(
					part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery,
					"Cosmetic part changes physics: " .. part:GetFullName()
				)
				table.insert(parts, part)
				-- Narrow bands below the last whole stud row are intentionally smooth.
				if part.Name == "OuterUnderside" or part.Name == "EndUnderside" then
					continue
				end
				if part.Material ~= Enum.Material.Neon then
					local variant = HDStuds.variant(part.Material, 4 * p)
					assert(variant and part.MaterialVariant == variant.Name, "Missing HD Studs: " .. part:GetFullName())
					assert(not part:FindFirstChild("VoxelStuds"), "Duplicate old studs: " .. part:GetFullName())
				end
				assert(frame.XVector:Dot(part.CFrame.XVector) > 0.9999, "Rotated studded part")
				local c = frame:PointToObjectSpace(part.Position)
				local half = part.Size / 2
				local u0, u1 = c.X - half.X, c.X + half.X
				local h0, h1 = c.Y - half.Y - Palette.layer, c.Y + half.Y - Palette.layer
				local s0, s1 = -c.Z - half.Z, -c.Z + half.Z
				local edges = { u0, u1, h0, h1, s0, s1 }
				if root == ground then
					local name = part.Name
					if name == "Turf" or name == "Line" or name == "TerraceTop" or name == "LawnTop" then
						edges = { u0, u1, s0, s1 }
						levels[math.round((c.Y + half.Y) * 100)] = true
						if part.Parent.Name == "Pitch" then
							pitchArea += part.Size.X * part.Size.Z
						end
					elseif name == "PitchWall" or name == "StepWall" or name == "OuterWall" then
						edges = { s0, s1, h0, h1 }
					else
						edges = { u0, u1, h0, h1 }
					end
				end
				for _, edge in edges do
					assert(near(edge, p), "Studded face off the stud grid: " .. part:GetFullName())
				end
				result.studdedParts += 1
			end
		end
	end
	local edge = zone.Geometry.Banks.InnerEast
	local pitchWidth = 2 * (math.abs(frame:PointToObjectSpace(edge.Position).X) - edge.Size.X / 2)
	assert(math.abs(pitchArea - field.Size.Z * pitchWidth) < 0.5, "Pitch cells do not cover the pitch")
	-- Neon props still use face overlays and may omit the underside when grounded.
	local function onLevel(h: number): boolean
		local key = math.round(h * 100)
		return levels[key] or levels[key - 1] or levels[key + 1] or false
	end
	for _, part in zone.Environment.Cityscape:GetDescendants() do
		if part:IsA("BasePart") then
			local c = frame:PointToObjectSpace(part.Position)
			local s = -c.Z
			assert(s - part.Size.Z / 2 >= -0.01 and s + part.Size.Z / 2 <= field.Size.Z + 0.01, "Prop crosses zone")
			result.propParts = (result.propParts or 0) + 1
			if part.Material ~= Enum.Material.Neon then
				continue
			end
			local faces = {}
			for _, child in part:GetChildren() do
				if child:IsA("Texture") and child.Name == "VoxelStuds" then
					assert(
						child.Texture == HDStuds.LegacyImage
							and math.abs(child.StudsPerTileU - 4 * p) < 0.001
							and math.abs(child.StudsPerTileV - 4 * p) < 0.001
							and child.OffsetStudsU == 0
							and child.OffsetStudsV == 0,
						"Wrong Neon overlay: " .. part:GetFullName()
					)
					faces[child.Face] = true
				end
			end
			for _, face in
				{ Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
			do
				assert(faces[face], "Prop face without studs: " .. part:GetFullName() .. " " .. face.Name)
			end
			assert(
				faces[Enum.NormalId.Bottom] or onLevel(c.Y - part.Size.Y / 2),
				"Raised prop bottom without studs: " .. part:GetFullName()
			)
		end
	end
	-- Each prop stands on the pitch, terrace or lawn level: whole rows above the pitch layer.
	for _, model in zone.Environment.Cityscape:GetChildren() do
		local bottom = math.huge
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				bottom = math.min(bottom, frame:PointToObjectSpace(part.Position).Y - part.Size.Y / 2)
			end
		end
		assert(near(bottom - Palette.layer, p) and bottom > 0, "Floating prop: " .. model:GetFullName())
		result.groundedProps = (result.groundedProps or 0) + 1
	end
	-- Every old bank face/top the camera can see has cladding in front of it.
	local function covered(point: Vector3): boolean
		for _, part in parts do
			local q = part.CFrame:PointToObjectSpace(point)
			local s = part.Size / 2
			if math.abs(q.X) <= s.X + 0.001 and math.abs(q.Y) <= s.Y + 0.001 and math.abs(q.Z) <= s.Z + 0.001 then
				return true
			end
		end
		return false
	end
	-- The cladding snaps bank faces to the grid and lifts its slabs over the old skins,
	-- so samples sit just inside the cladding: behind it lies only old geometry.
	local function level(name: string): number
		local top = -math.huge
		for _, part in ground.BankWest:GetChildren() do
			if part.Name == name then
				top = math.max(top, frame:PointToObjectSpace(part.Position).Y + part.Size.Y / 2)
			end
		end
		assert(top > 0, "Missing " .. name)
		return top
	end
	local terraceLevel, lawnLevel = level("TerraceTop"), level("LawnTop")
	local banks = zone.Geometry.Banks
	local rng = Random.new(index)
	for _, body in banks:GetChildren() do
		local c = frame:PointToObjectSpace(body.Position)
		local side = math.sign(c.X)
		local inner = math.round((math.abs(c.X) - body.Size.X / 2) / p) * p
		local outer = math.round((math.abs(c.X) + body.Size.X / 2) / p) * p
		local top = c.Y + body.Size.Y / 2
		local isInner = body.Name:match("^Inner") ~= nil
		local roof = if isInner then terraceLevel else lawnLevel
		assert(roof > top + 0.05, "Cladding top below the old bank: " .. body.Name)
		for _ = 1, 40 do
			local s = rng:NextNumber(0.5, field.Size.Z - 0.5)
			local samples = {
				Vector3.new(side * rng:NextNumber(inner + 0.1, outer - 0.1), roof - 0.025, -s),
			}
			if isInner then
				table.insert(samples, Vector3.new(side * (inner - 0.025), rng:NextNumber(0.1, roof - 0.05), -s))
			else
				local face = rng:NextNumber(terraceLevel + 0.05, roof - 0.05)
				table.insert(samples, Vector3.new(side * (inner - 0.025), face, -s))
				table.insert(
					samples,
					Vector3.new(side * (outer + 0.025), rng:NextNumber(c.Y - body.Size.Y / 2 + 0.05, roof - 0.05), -s)
				)
			end
			for _, point in samples do
				assert(
					covered(frame:PointToWorldSpace(point)),
					"Uncovered bank face near s=" .. string.format("%.1f", s)
				)
				result.coveredSamples += 1
			end
		end
		task.wait()
	end
	table.insert(result.zones, { zone = zone.Name, parts = #parts })
end
assert(#result.zones > 0, "No voxel-styled zone")
return result
