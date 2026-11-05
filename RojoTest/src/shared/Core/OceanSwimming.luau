--!strict
-- Deterministic swimming math; every position is constrained to a certified route tube.
local Swim = {}
local tau = math.pi * 2

function Swim.route(t: number, rx: number, rz: number, speed: number, seed: number): (Vector3, Vector3)
	local phase = t * speed / math.max(rx, rz, 1) + seed
	local p = Vector3.new(math.cos(phase) * rx, math.sin(phase * 2) * 1.4, math.sin(phase) * rz)
	local tangent = Vector3.new(-math.sin(phase) * rx, math.cos(phase * 2) * 2.8, math.cos(phase) * rz)
	return p, tangent.Unit
end

function Swim.memberCoordinates(t: number, index: number, seed: number): (number, number, number)
	-- Different angular speeds continuously exchange front/back positions; no fixed slots.
	local angle = index * 2.399963 + t * (0.16 + index % 3 * 0.018) + seed
	local radius = 3 + index % 3 * 1.8 + math.sin(t * 0.23 + index) * 0.4
	return math.cos(angle) * radius, math.sin(t * 0.31 + index * 1.7) * 2.2, math.sin(angle) * radius
end

function Swim.member(t: number, index: number, seed: number): Vector3
	return Vector3.new(Swim.memberCoordinates(t, index, seed))
end

function Swim.segmentDistance(a: Vector3, b: Vector3): number
	local d = b - a
	local length2 = d:Dot(d)
	local t = if length2 < 1e-12 then 0 else math.clamp(-a:Dot(d) / length2, 0, 1)
	return (a + d * t).Magnitude
end

function Swim.clearBox(a: Vector3, b: Vector3, half: Vector3, radius: number): boolean
	-- Segment versus inflated AABB: conservative at corners, includes initial overlap.
	local d = b - a
	local lo, hi = 0, 1
	for _, axis in { "X", "Y", "Z" } do
		local origin, delta, limit = (a :: any)[axis], (d :: any)[axis], (half :: any)[axis] + radius
		if math.abs(delta) < 1e-9 then
			if math.abs(origin) <= limit then
				continue
			end
			return true
		end
		local first, last = (-limit - origin) / delta, (limit - origin) / delta
		if first > last then
			first, last = last, first
		end
		lo, hi = math.max(lo, first), math.min(hi, last)
		if lo > hi then
			return true
		end
	end
	return false
end

function Swim.pairClear(a: Vector3, b: Vector3, c: Vector3, d: Vector3, radius: number): boolean
	return Swim.segmentDistance(a - c, b - d) >= radius
end

function Swim.phase(t: number, frequency: number, phase: number): number
	return math.sin(t * tau * frequency + phase)
end

return Swim
