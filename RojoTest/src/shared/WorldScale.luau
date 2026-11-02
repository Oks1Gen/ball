--!strict
-- World1 was shrunk by tools/WorldScale.luau (0.8 on 2026-11-02), which records the factor and
-- its origin on the world folder. Builders that draw with authored sizes multiply them by the
-- factor, so a startup rebuild matches the scaled scene. An unscaled world reads as 1.
local WorldScale = {}

-- `world` is any instance carrying the attributes; untyped builders pass their own map tables.
function WorldScale.factor(world: any): number
	local value = world and world:GetAttribute("WorldScale")
	return if typeof(value) == "number" then value else 1
end

-- Maps an authored (unscaled) world position into the scaled scene.
function WorldScale.point(world: any, position: Vector3): Vector3
	local origin = world and world:GetAttribute("WorldScaleOrigin")
	if typeof(origin) ~= "Vector3" then
		return position
	end
	return origin + (position - origin) * WorldScale.factor(world)
end

return WorldScale
