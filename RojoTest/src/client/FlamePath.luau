--!strict
-- Bounded world-space history. Distances follow the actual path, not velocity.
local Path = {}

function Path.new()
	local points: { Vector3 } = {}
	return {
		clear = function()
			table.clear(points)
		end,
		push = function(position: Vector3)
			local newest = points[1]
			if newest then
				local gap = (position - newest).Magnitude
				if gap > 64 then
					table.clear(points)
				elseif gap < 0.12 then
					return
				end
			end
			table.insert(points, 1, position)
			if #points > 128 then
				table.remove(points)
			end
			local distance = 0
			for i = 2, #points do
				distance += (points[i] - points[i - 1]).Magnitude
				if distance > 20 then
					for _ = #points, i + 1, -1 do
						table.remove(points)
					end
					break
				end
			end
		end,
		sample = function(head: Vector3, distance: number, fallback: Vector3): (Vector3, Vector3)
			local current = head
			local tangent = fallback
			for _, point in points do
				local delta = point - current
				local length = delta.Magnitude
				if length > 0.001 then
					tangent = delta / length
					if distance <= length then
						return current + tangent * distance, tangent
					end
					distance -= length
				end
				current = point
			end
			return current, tangent
		end,
	}
end

return Path
