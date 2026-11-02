--!strict
-- How fast a shot looks, and the client-only time warp that lets a fast ball
-- linger at each bounce. Pure: the server never uses the warped values.
local Pace = {}

-- Average ball speed (studs/s) where speed effects start and where they peak. Scaled with World1
-- (0.8 on 2026-11-02), so a shot of the same length in metres gets the same effects.
Pace.Slow = 56
Pace.Fast = 160
-- Ball speed at a contact relative to an unwarped shot, at full pace.
Pace.ContactSpeed = 0.2

-- 0 for a slow shot, 1 for the fastest ones.
function Pace.factor(studsPerSecond: number): number
	return math.clamp((studsPerSecond - Pace.Slow) / (Pace.Fast - Pace.Slow), 0, 1)
end

-- Warps the shot progress inside every bounce: slow right after a contact so
-- the impact stays in the frame, faster in the air to make the time up. Every
-- contact (alpha = k / bounces) and the finish keep their exact time.
function Pace.hang(alpha: number, strength: number, bounces: number): number
	if alpha <= 0 or alpha >= 1 or strength <= 0 then
		return math.clamp(alpha, 0, 1)
	end
	local segment = alpha * bounces
	local bounce = math.floor(segment)
	local phase = segment - bounce
	-- Cubic Hermite from slope `start` at the contact to slope 1 at the next
	-- one; the slope start + (1 - start)(4p - 3p²) never goes below `start`.
	local start = 1 - (1 - Pace.ContactSpeed) * math.clamp(strength, 0, 1)
	local warped = phase * start + phase * phase * (2 - 2 * start) + phase * phase * phase * (start - 1)
	return (bounce + warped) / bounces
end

return Pace
