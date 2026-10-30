--!strict
-- Timeline of the clicked egg reveal. The pet is rolled by the server before
-- the stage opens: the upgrades only reveal its rarity step by step, they never
-- roll again, so the last light always matches the pet that was granted.
local Sequence = {}

Sequence.Clicks = 5
-- Light order of the reveal: white, green, purple, yellow, red.
Sequence.Tiers = { "Common", "Uncommon", "Rare", "Legendary", "Mythic" }
-- One click: wind up, jump with a spin, land. Seconds from the click.
Sequence.Windup = 0.07
Sequence.Jump = 0.42
-- A click pressed in the air is kept and starts right after the landing.
Sequence.Queue = 0.02
-- Jumps of a triple hatch are slightly out of step.
Sequence.EggDelay = 0.05
-- After the fifth landing the egg shakes, grows and glows white.
Sequence.FinaleDelay = 0.25
Sequence.Charge = 1.35
-- A late upgrade lands in the middle of the shaking.
Sequence.FinaleUpgrade = 0.75
-- At its biggest the egg holds still for a moment, then bursts.
Sequence.Freeze = 0.12
-- From this tier on the garden darkens and light falls onto the pedestal.
Sequence.EpicTier = 4
-- Screen knocks: every landing, harder with an upgrade, hardest at the burst.
Sequence.Shake = { Land = 0.25, Upgrade = 0.45, PerTier = 0.1, Burst = 1, Decay = 0.32, BurstDecay = 0.55 }
-- Silhouettes start after the burst and slow down for Spin seconds.
Sequence.RouletteDelay = 0.15
Sequence.Spin = 1.3
Sequence.FirstFrame = 0.07
Sequence.FrameGrowth = 1.2
-- Triple hatch: every next roulette spins this much longer.
Sequence.Stagger = 0.3
-- The last silhouette stays black, then fills with colour.
Sequence.Hold = 0.35
Sequence.Fill = 0.3
-- Chance that the last upgrade waits for the shaking.
Sequence.LateChance = 0.3
-- Synthetic clicks of the offline capture and of the verification script.
Sequence.PreviewClicks = { 0.5, 1.1, 1.7, 2.3, 2.9 }

export type Frame = { at: number, index: number }

function Sequence.tierOf(rarity: string?): number
	if rarity == "Epic" then
		return 3
	end
	return table.find(Sequence.Tiers, rarity or "") or 1
end

-- The tier after every click landing (1..Clicks) and after the shaking
-- (Clicks + 1). Each slot raises the tier by at most one step, the light
-- never goes down and the last slot is always the final tier.
function Sequence.plan(finalTier: number, roll: () -> number): { number }
	local slots = Sequence.Clicks + 1
	local steps = math.clamp(math.floor(finalTier) - 1, 0, slots - 1)
	local chosen: { [number]: boolean } = {}
	local remaining = steps
	if remaining > 0 and roll() < Sequence.LateChance then
		chosen[slots] = true
		remaining -= 1
	end
	local free = {}
	for slot = 1, Sequence.Clicks do
		table.insert(free, slot)
	end
	-- A partial shuffle picks distinct click slots.
	for i = 1, math.min(remaining, #free) do
		local j = i + math.min(#free - i, math.floor(roll() * (#free - i + 1)))
		free[i], free[j] = free[j], free[i]
		chosen[free[i]] = true
	end
	local tiers = {}
	local tier = 1
	for slot = 1, slots do
		if chosen[slot] then
			tier += 1
		end
		tiers[slot] = tier
	end
	return tiers
end

-- When a click pressed at `now` starts its jump, or nil when it is ignored:
-- all clicks are used or one click already waits for the landing.
function Sequence.accept(clicks: { number }, now: number): number?
	local count = #clicks
	if count >= Sequence.Clicks then
		return nil
	end
	local last = clicks[count]
	if last == nil then
		return now
	end
	if last > now then
		return nil
	end
	local landing = last + Sequence.Jump
	return if now >= landing then now else landing + Sequence.Queue
end

-- Landings an egg made by `t`, and the time of the latest one.
function Sequence.landed(clicks: { number }, t: number, delay: number): (number, number?)
	local count, latest = 0, nil
	for k = 1, math.min(#clicks, Sequence.Clicks) do
		local at = clicks[k] + delay + Sequence.Jump
		if at <= t then
			count, latest = k, at
		end
	end
	return count, latest
end

-- The start of the shaking, once all clicks were made.
function Sequence.finale(clicks: { number }, delay: number): number?
	local last = clicks[Sequence.Clicks]
	if last == nil then
		return nil
	end
	return last + delay + Sequence.Jump + Sequence.FinaleDelay
end

-- The burst: after the shaking and the still moment.
function Sequence.burst(clicks: { number }, delay: number): number?
	local finale = Sequence.finale(clicks, delay)
	return finale and finale + Sequence.Charge + Sequence.Freeze
end

-- The moment the light first shows `tier` or a stronger one, or nil.
function Sequence.reached(plan: { number }, clicks: { number }, delay: number, tier: number): number?
	for k = 1, math.min(#clicks, Sequence.Clicks) do
		if (plan[k] or 1) >= tier then
			return clicks[k] + delay + Sequence.Jump
		end
	end
	local finale = Sequence.finale(clicks, delay)
	if finale and (plan[Sequence.Clicks + 1] or 1) >= tier then
		return finale + Sequence.FinaleUpgrade
	end
	return nil
end

-- Strength of the screen shake at `t`, 0..1: the strongest knock still fading.
function Sequence.shake(plan: { number }, clicks: { number }, t: number, delay: number): number
	local shake = Sequence.Shake
	local strength = 0
	local function knock(at: number?, power: number, decay: number)
		if at and t >= at and t - at < decay then
			local q = 1 - (t - at) / decay
			strength = math.max(strength, power * q * q)
		end
	end
	local previous = 1
	for k = 1, math.min(#clicks, Sequence.Clicks) do
		local tier = plan[k] or previous
		local power = if tier > previous then shake.Upgrade + tier * shake.PerTier else shake.Land
		knock(clicks[k] + delay + Sequence.Jump, power, shake.Decay)
		previous = math.max(previous, tier)
	end
	local finale = Sequence.finale(clicks, delay)
	local last = plan[Sequence.Clicks + 1] or previous
	if finale and last > previous then
		knock(finale + Sequence.FinaleUpgrade, shake.Upgrade + last * shake.PerTier, shake.Decay)
	end
	knock(Sequence.burst(clicks, delay), shake.Burst, shake.BurstDecay)
	return math.min(1, strength)
end

-- The tier shown at `t`, the time of the latest upgrade and the tier before it.
function Sequence.tierAt(plan: { number }, clicks: { number }, t: number, delay: number): (number, number?, number)
	local tier, changed, previous = 1, nil, 1
	local function event(at: number, value: number)
		if at <= t and value > tier then
			previous, tier, changed = tier, value, at
		end
	end
	for k = 1, math.min(#clicks, Sequence.Clicks) do
		event(clicks[k] + delay + Sequence.Jump, plan[k] or 1)
	end
	local finale = Sequence.finale(clicks, delay)
	if finale then
		event(finale + Sequence.FinaleUpgrade, plan[Sequence.Clicks + 1] or tier)
	end
	return tier, changed, previous
end

-- Silhouette frames from the start of the roulette. They slow down and the
-- last one is the granted pet; neighbouring frames never repeat a pet.
-- Returns the frames and the start of the last frame.
function Sequence.roulette(size: number, final: number, spin: number, roll: () -> number): ({ Frame }, number)
	local frames: { Frame } = {}
	local at, duration = 0, Sequence.FirstFrame
	local previous = 0
	local function pick(avoid: number): number
		if size <= 1 then
			return 1
		end
		local options = {}
		for index = 1, size do
			if index ~= previous and index ~= avoid then
				table.insert(options, index)
			end
		end
		if #options == 0 then
			-- Two pets: repeating a pet is better than showing the result early.
			return if avoid == 1 then 2 else 1
		end
		return options[math.min(#options, math.floor(roll() * #options) + 1)]
	end
	while at < spin do
		local nextAt = at + duration
		-- The frame before the last one never shows the granted pet.
		local index = pick(if nextAt >= spin then final else 0)
		table.insert(frames, { at = at, index = index })
		previous = index
		at = nextAt
		duration *= Sequence.FrameGrowth
	end
	table.insert(frames, { at = at, index = final })
	return frames, at
end

-- The frame shown at `elapsed` seconds of the roulette, or nil before it.
function Sequence.frameAt(frames: { Frame }, elapsed: number): (Frame?, number)
	local current, number = nil, 0
	for i, frame in frames do
		if frame.at <= elapsed then
			current, number = frame, i
		else
			break
		end
	end
	return current, number
end

return Sequence
