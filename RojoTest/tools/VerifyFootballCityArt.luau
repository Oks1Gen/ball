--!strict
-- Checks actual generated objects; joints inside one complete prop are intentional.
local Audit = {}
local V = Vector3.new

local function extent(p: BasePart): Vector3
	local cf, h = p.CFrame, p.Size / 2
	return V(
		math.abs(cf.RightVector.X) * h.X + math.abs(cf.UpVector.X) * h.Y + math.abs(cf.LookVector.X) * h.Z,
		math.abs(cf.RightVector.Y) * h.X + math.abs(cf.UpVector.Y) * h.Y + math.abs(cf.LookVector.Y) * h.Z,
		math.abs(cf.RightVector.Z) * h.X + math.abs(cf.UpVector.Z) * h.Y + math.abs(cf.LookVector.Z) * h.Z
	)
end

local function intersects(a: BasePart, b: BasePart): boolean
	local aa = { a.CFrame.RightVector, a.CFrame.UpVector, a.CFrame.LookVector }
	local ba = { b.CFrame.RightVector, b.CFrame.UpVector, b.CFrame.LookVector }
	local ah, bh = { a.Size.X / 2, a.Size.Y / 2, a.Size.Z / 2 }, { b.Size.X / 2, b.Size.Y / 2, b.Size.Z / 2 }
	local axes = { aa[1], aa[2], aa[3], ba[1], ba[2], ba[3] }
	for _, u in aa do
		for _, v in ba do
			local cross = u:Cross(v)
			if cross.Magnitude > 0.0001 then
				table.insert(axes, cross.Unit)
			end
		end
	end
	local delta = b.Position - a.Position
	for _, axis in axes do
		local radius = 0
		for i = 1, 3 do
			radius += math.abs(aa[i]:Dot(axis)) * ah[i] + math.abs(ba[i]:Dot(axis)) * bh[i]
		end
		if radius - math.abs(delta:Dot(axis)) <= 0.045 then
			return false
		end
	end
	return true
end

function Audit.run(): any
	local overlaps, samples, textureFaces, checkerCells, props, grounded = 0, {}, 0, 0, 0, 0
	local checkerByZone = {}
	local themes = require(game.ReplicatedStorage.Shared.FootballCity)
	for _, zone in workspace.Map.World1.FootballCourse.Zones:GetChildren() do
		local city = zone.Environment.Cityscape
		local definition = themes[zone:GetAttribute("ZoneIndex")]
		checkerByZone[zone.Name] = 0
		local parts = {}
		for _, object in city:GetChildren() do
			if object:IsA("Model") and not object:GetAttribute("CitySurface") then
				props += 1
				for _, p in object:GetDescendants() do
					if p:IsA("BasePart") and p.Transparency < 1 then
						table.insert(parts, { part = p, owner = object, e = extent(p) })
					end
				end
				if object.Name == "TeamBench" or object.Name == "Floodlight" or object.Name == "Scoreboard" then
					local bottom, x = math.huge, 0
					for _, p in object:GetDescendants() do
						if p:IsA("BasePart") then
							local low = p.Position.Y - extent(p).Y
							if low < bottom then
								bottom, x = low, p.Position.X
							end
						end
					end
					local k = workspace.Map.World1:GetAttribute("WorldScale") or 1
					local localX = math.abs(x - zone.Field.Position.X) / k
					local expected = zone.Field.Position.Y
						+ zone.Field.Size.Y / 2
						+ (if localX < 78 then 3.74 else 8.74) * k
					assert(math.abs(bottom - expected) < 0.015, "Floating furniture: " .. object:GetFullName())
					grounded += 1
				end
			end
		end
		for _, p in city:GetDescendants() do
			if p:IsA("Texture") and p.Name == "CityStuds" then
				assert(
					p.Texture == "rbxassetid://88156646156237" and math.abs(p.Transparency - 0.45) < 0.00001,
					"Wrong studs"
				)
				textureFaces += 1
			elseif p:IsA("BasePart") and p.Name == "CheckerTile" then
				local pattern = definition.pavingPattern
				assert(pattern, "Checker outside a themed club forecourt")
				local scale = workspace.Map.World1:GetAttribute("WorldScale") or 1
				assert(
					math.abs(p.Position.Z - zone.Field.Position.Z) + p.Size.Z / 2 <= pattern.length * scale / 2 + 0.001,
					"Pattern extends along the path"
				)
				assert(
					p.Color == pattern.light or p.Color == pattern.west or p.Color == pattern.east,
					"Wrong club colours"
				)
				checkerByZone[zone.Name] += 1
				checkerCells += 1
			end
		end
		for i, a in parts do
			for j = i + 1, #parts do
				local b = parts[j]
				if a.owner ~= b.owner then
					local d, r = b.part.Position - a.part.Position, a.e + b.e
					if
						math.abs(d.X) < r.X - 0.045
						and math.abs(d.Y) < r.Y - 0.045
						and math.abs(d.Z) < r.Z - 0.045
						and intersects(a.part, b.part)
					then
						overlaps += 1
						if #samples < 24 then
							table.insert(samples, { a = a.part:GetFullName(), b = b.part:GetFullName() })
						end
					end
				end
			end
			if i % 250 == 0 then
				task.wait()
			end
		end
		task.wait()
	end
	return {
		interObjectOverlaps = overlaps,
		samples = samples,
		studsFaces = textureFaces,
		checkerCells = checkerCells,
		checkerByZone = checkerByZone,
		completeProps = props,
		groundedFurniture = grounded,
	}
end

return Audit
