--!strict
local Config = require(script.Parent.GameConfig)
local Timing = require(script.Parent.Core.KickTiming)
local Feedback = {}

function Feedback.profile(skill, power, world, timingMultiplier: number?)
	local target = Config.WorldShotProgression[world == 2 and 2 or 1].requiredPower
	local ratio = math.clamp(Config.effectiveShotPower(skill, power) / target, 0, 1)
	local intensity = ratio ^ 0.22
	local quality = Timing.quality(timingMultiplier or 1)
	return {
		intensity = math.clamp(intensity + quality * 0.45, 0, 1),
		timingQuality = quality,
		fieldOfView = 68 + 14 * intensity,
		trailLifetime = 0.18 + 0.42 * intensity,
		rippleScale = 0.65 + 1.3 * intensity + quality * 0.6,
		kickVolume = 0.18 + 0.27 * intensity + quality * 0.12,
		kickPlayback = 1 + 0.35 * intensity + quality * 0.25,
		shakeAmplitude = 0.015 + 0.045 * intensity + quality * 0.48,
	}
end

return Feedback
