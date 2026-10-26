--!strict
-- Full-body poses: time, blend, pelvis XYZ, hip/knee/ankle, pelvis yaw/roll,
-- chest pitch/twist, shoulder pitch, elbows, head pitch, chest side lean,
-- whole-body lean about the support ankle, and separate left/right arm spreads.
-- Angles are degrees. The pelvis leads the swing; the lower leg follows later.
local Motion = { Contact = 0.42, Duration = 0.86 }
local channels = {
	"weight",
	"x",
	"y",
	"z",
	"hip",
	"knee",
	"ankle",
	"yaw",
	"roll",
	"chest",
	"twist",
	"leftArm",
	"rightArm",
	"leftElbow",
	"rightElbow",
	"head",
	"side",
	"lean",
	"leftSpread",
	"rightSpread",
}
local frames = {
	{ 0.00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
	{ 0.10, 0.85, -0.01, -0.025, 0.02, -16, -20, -8, -5, 0, -2, 4, -8, 12, 8, 10, 1, 1, 8, 35, 15 },
	{ 0.25, 1, -0.025, -0.020, 0.10, -52, -62, -16, -20, 1, -5, 18, -18, 22, 5, 9, 3, 2, 28, 96, 30 },
	{ 0.34, 1, -0.03, -0.025, 0.06, -32, -104, -20, -14, 1, -1, 8, -22, 15, 6, 8, 2, 3, 30, 100, 30 },
	{ 0.42, 1, -0.025, -0.025, -0.08, 14, -40, 28, 12, 1, 8, -16, 15, -25, 7, 10, -3, 3, 26, 94, 34 },
	{ 0.52, 1, -0.015, -0.035, -0.20, 68, -20, -14, 20, 1, 16, -20, 30, -38, 10, 14, -6, 2, 18, 74, 36 },
	{ 0.68, 0.9, -0.005, -0.035, -0.06, 32, -42, 8, 8, 0, 8, -8, 12, -16, 12, 12, -3, 1, 6, 32, 20 },
	{ 0.86, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
}

-- Monotone cubic interpolation keeps joint limits and continuous velocity between poses.
local function tangent(index: number, column: number): number
	if index == 1 or index == #frames then
		return 0
	end
	local a, b, c = frames[index - 1], frames[index], frames[index + 1]
	local h0, h1 = b[1] - a[1], c[1] - b[1]
	local d0, d1 = (b[column] - a[column]) / h0, (c[column] - b[column]) / h1
	if d0 * d1 <= 0 then
		return 0
	end
	local w0, w1 = 2 * h1 + h0, h1 + 2 * h0
	return (w0 + w1) / (w0 / d0 + w1 / d1)
end

function Motion.sample(phase: number, contact: number?): { [string]: number }
	local hit = contact or Motion.Contact
	local time = if phase <= hit then phase * Motion.Contact / hit else Motion.Contact + phase - hit
	local result: { [string]: number } = {}
	if time <= 0 or time >= Motion.Duration then
		for _, name in channels do
			result[name] = 0
		end
		return result
	end
	local index = 1
	while index < #frames - 1 and time > frames[index + 1][1] do
		index += 1
	end
	local a, b = frames[index], frames[index + 1]
	local span = b[1] - a[1]
	local t = (time - a[1]) / span
	local t2, t3 = t * t, t * t * t
	for channel, name in channels do
		local column = channel + 1
		result[name] = (2 * t3 - 3 * t2 + 1) * a[column]
			+ (t3 - 2 * t2 + t) * span * tangent(index, column)
			+ (-2 * t3 + 3 * t2) * b[column]
			+ (t3 - t2) * span * tangent(index + 1, column)
	end
	return result
end

return Motion
