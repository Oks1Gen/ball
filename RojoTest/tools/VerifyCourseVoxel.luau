-- Read-only Studio audit of voxel-styled course zones (docs/course-voxel.md).
-- Every studded face is a whole-stud rectangle on the zone grid; all cladding and props
-- are cosmetic; the old bank faces and tops are covered; the authored field is unchanged.
local world = workspace.Map.World1
local themes = require(game.ReplicatedStorage.Shared.FootballCity)
local Palette = { pitch = 2 * (world:GetAttribute("WorldScale") or 1), layer = 0.05 }
local p = Palette.pitch
local result = { zones = {}, studsFaces = 0, coveredSamples = 0 }

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
	for _, root in { ground, zone.Environment.Cityscape } do
		for _, part in root:GetDescendants() do
			if part:IsA("BasePart") then
				assert(
					part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery,
					"Cosmetic part changes physics: " .. part:GetFullName()
				)
				table.insert(parts, part)
				if part.Parent and part.Parent.Name == "Pitch" then
					pitchArea += part.Size.X * part.Size.Z
					if part.Name == "Line" then
						assert(not part:FindFirstChildWhichIsA("Texture"), "Painted line has studs")
					end
				end
			elseif part:IsA("Texture") and part.Name == "VoxelStuds" then
				local host = part.Parent :: BasePart
				assert(
					part.Texture == "rbxassetid://88156646156237"
						and math.abs(part.Transparency - 0.45) < 0.00001
						and math.abs(part.StudsPerTileU - 4 * p) < 0.001
						and math.abs(part.StudsPerTileV - 4 * p) < 0.001
						and part.OffsetStudsU == 0
						and part.OffsetStudsV == 0,
					"Wrong studs texture: " .. host:GetFullName()
				)
				assert(frame.XVector:Dot(host.CFrame.XVector) > 0.9999, "Rotated studded part")
				local c = frame:PointToObjectSpace(host.Position)
				local half = host.Size / 2
				local u0, u1 = c.X - half.X, c.X + half.X
				local h0, h1 = c.Y - half.Y - Palette.layer, c.Y + half.Y - Palette.layer
				local s0, s1 = -c.Z - half.Z, -c.Z + half.Z
				local edges = if part.Face == Enum.NormalId.Top
					then { u0, u1, s0, s1 }
					elseif part.Face == Enum.NormalId.Left or part.Face == Enum.NormalId.Right then {
						s0,
						s1,
						h0,
						h1,
					}
					else { u0, u1, h0, h1 }
				for _, edge in edges do
					assert(near(edge, p), "Studded face off the stud grid: " .. host:GetFullName())
				end
				result.studsFaces += 1
			end
		end
	end
	local edge = zone.Geometry.Banks.InnerEast
	local pitchWidth = 2 * (math.abs(frame:PointToObjectSpace(edge.Position).X) - edge.Size.X / 2)
	assert(math.abs(pitchArea - field.Size.Z * pitchWidth) < 0.5, "Pitch cells do not cover the pitch")
	for _, part in zone.Environment.Cityscape:GetDescendants() do
		if part:IsA("BasePart") then
			local s = -frame:PointToObjectSpace(part.Position).Z
			assert(s - part.Size.Z / 2 >= -0.01 and s + part.Size.Z / 2 <= field.Size.Z + 0.01, "Prop crosses zone")
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
	local banks = zone.Geometry.Banks
	local rng = Random.new(index)
	for _, body in banks:GetChildren() do
		local c = frame:PointToObjectSpace(body.Position)
		local side = math.sign(c.X)
		local inner = math.abs(c.X) - body.Size.X / 2
		local outer = math.abs(c.X) + body.Size.X / 2
		local top = c.Y + body.Size.Y / 2
		local isInner = body.Name:match("^Inner") ~= nil
		for _ = 1, 40 do
			local s = rng:NextNumber(0.5, field.Size.Z - 0.5)
			local samples = {
				Vector3.new(side * rng:NextNumber(inner + 0.1, outer - 0.1), top + 0.12, -s),
			}
			if isInner then
				table.insert(samples, Vector3.new(side * (inner - 0.025), rng:NextNumber(0.1, top), -s))
			else
				table.insert(samples, Vector3.new(side * (inner - 0.025), rng:NextNumber(top - 2.4, top), -s))
				table.insert(
					samples,
					Vector3.new(side * (outer + 0.025), rng:NextNumber(c.Y - body.Size.Y / 2 + 0.05, top), -s)
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
