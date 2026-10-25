--!strict
-- The whole playable strip is a training area, independent of the old start pad.
local Area = {}
Area.RepositionDistance = 1.25

function Area.contains(strip: BasePart, position: Vector3): boolean
	local point = strip.CFrame:PointToObjectSpace(position)
	return math.abs(point.X) <= math.max(0, strip.Size.X / 2 - 0.25)
		and math.abs(point.Z) <= math.max(0, strip.Size.Z / 2 - 0.25)
		and point.Y >= strip.Size.Y / 2 - 0.3
		and point.Y < strip.Size.Y / 2 + 8
end

function Area.repositioned(previous: Vector3, current: Vector3): boolean
	local delta = current - previous
	return Vector2.new(delta.X, delta.Z).Magnitude >= Area.RepositionDistance
end

return Area
