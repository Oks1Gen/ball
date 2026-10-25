--!strict
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.GameConfig)
local Motion = require(Shared.ShotMotion)
local Zones = require(Shared.Core.ZoneProgression)
local ShotZones = {}

function ShotZones.crossings(arena: any, info: any): { any }
	local result = {}
	local travel = info.direction * (info.distance / Config.DistancePerStud)
	for index = 1, #Config.Biomes - 1 do
		local wall = arena.ZoneDividers["Boundary" .. index].Wall
		local start = wall.CFrame:PointToObjectSpace(info.startPosition)
		local delta = wall.CFrame:VectorToObjectSpace(travel)
		if delta.Z < -0.000001 and start.Z >= 0 then
			local alpha = -start.Z / delta.Z
			if alpha >= 0 and alpha <= 1 then
				local position = Motion.position(info.startPosition, info.distance, alpha, info.direction)
				local contact = wall.CFrame:PointToObjectSpace(position)
				if math.abs(contact.X) <= wall.Size.X / 2 and math.abs(contact.Y) <= wall.Size.Y / 2 then
					table.insert(result, {
						alpha = alpha,
						zone = index + 1,
						name = Config.Biomes[index + 1].name,
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
