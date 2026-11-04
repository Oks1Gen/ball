--!strict
-- Final wall geometry and facade after WorldLayout.
local Walls = {}
function Walls.apply(world: Instance): any
	if world.Name ~= "World1" then
		return { tiles = 0, walls = 0 }
	end
	local removed = require(script.Parent.LobbyWallDecor).apply(world)
	local geometry = require(script.Parent.LobbyWallGeometry).apply(world)
	local coverage = require(script.Parent.LobbyWallCoverage).apply(world)
	coverage.removedDecor = removed
	coverage.geometry = geometry
	world:SetAttribute("LobbyWallStyleVersion", 6)
	return coverage
end
return Walls
