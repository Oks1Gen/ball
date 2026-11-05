--!strict
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.GameConfig)
local Motion = require(Shared.ShotMotion)
local Zones = require(Shared.Core.ZoneProgression)
local Refs = require(Shared.WorldRefs)
local ShotZones = {}

function ShotZones.crossings(arena: any, info: any): { any }
	local result = {}
	local travel = info.direction * (info.distance / Config.DistancePerStud)
	local boundaries = Refs.boundaries(arena)
	for index = 1, #Config.Biomes - 1 do
		local boundary = boundaries and boundaries:FindFirstChild("Boundary" .. index)
		local wall = boundary and boundary:FindFirstChild("Wall")
		local zone = Refs.zone(arena, index + 1)
		local field = Refs.field(arena, index + 1)
		if not wall and not field then
			continue
		end
		-- Ocean fields start at their near edge without a physical boundary wall.
		local plane = if wall then wall.CFrame else field.CFrame * CFrame.new(0, 0, field.Size.Z / 2)
		local start = plane:PointToObjectSpace(info.startPosition)
		local delta = plane:VectorToObjectSpace(travel)
		if delta.Z < -0.000001 and start.Z >= 0 then
			local alpha = -start.Z / delta.Z
			if alpha >= 0 and alpha <= 1 then
				local position = Motion.position(info.startPosition, info.distance, alpha, info.direction)
				local contact = plane:PointToObjectSpace(position)
				local width = if wall then wall.Size.X else field.Size.X
				if math.abs(contact.X) <= width / 2 and (not wall or math.abs(contact.Y) <= wall.Size.Y / 2) then
					table.insert(result, {
						alpha = alpha,
						zone = index + 1,
						name = if wall then Config.Biomes[index + 1].name else zone:GetAttribute("BiomeName"),
						multiplier = Zones.multiplier(index + 1),
					})
				end
			end
		end
	end
	table.sort(result, function(a, b)
		return a.alpha < b.alpha
	end)
	return result
end
return ShotZones
