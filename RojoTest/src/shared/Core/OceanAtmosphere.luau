--!strict
local Atmosphere = {}

function Atmosphere.envelope(t: number, period: number, duration: number, offset: number): number
	local phase = (t + offset) % period
	if phase >= duration then
		return 0
	end
	local fade = math.min(3, duration / 3)
	local a = math.clamp(math.min(phase, duration - phase) / fade, 0, 1)
	return a * a * (3 - 2 * a)
end

function Atmosphere.current(t: number): Vector3
	return Vector3.new(0.48 + math.sin(t * 0.055) * 0.12, 0.025, -0.26 + math.cos(t * 0.041) * 0.08)
end

function Atmosphere.zoneWeights(progress: number): { number }
	local coordinate = math.clamp(progress, 1, 8)
	local first = math.floor(coordinate)
	local weights = table.create(8, 0)
	weights[first] = 1 - (coordinate - first)
	if first < 8 then
		weights[first + 1] = coordinate - first
	end
	return weights
end

function Atmosphere.jellyWave(t: number, along: number): number
	return Atmosphere.envelope(t - along / 52, 34, 6, 30)
end

return Atmosphere
