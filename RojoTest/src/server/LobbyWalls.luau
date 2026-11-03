--!strict
-- Final wall facade after WorldLayout; source geometry and physics stay intact.
local Walls = {}
function Walls.apply(world: Instance): any
	if world.Name ~= "World1" then
		return { tiles = 0, walls = 0 }
	end
	local coverage = require(script.Parent.LobbyWallCoverage).apply(world)
	world:SetAttribute("LobbyWallStyleVersion", 4)
	return coverage
end
return Walls
