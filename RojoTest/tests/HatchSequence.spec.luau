--!strict
local Sequence = require("../src/shared/Core/HatchSequence")

-- A small deterministic generator, so every run checks the same sequences.
local function generator(seed: number): () -> number
	local state = seed
	return function()
		state = state * 16807 % 2147483647
		return state / 2147483647
	end
end

return {
	["rarities map onto the light tiers"] = function()
		assert(Sequence.tierOf("Common") == 1)
		assert(Sequence.tierOf("Uncommon") == 2)
		assert(Sequence.tierOf("Rare") == 3)
		assert(Sequence.tierOf("Legendary") == 4)
		assert(Sequence.tierOf("Mythic") == 5)
		assert(Sequence.tierOf("Epic") == 3)
		assert(Sequence.tierOf("Unknown") == 1)
		assert(Sequence.tierOf(nil) == 1)
	end,
	["upgrade plan rises one step at a time and ends on the granted rarity"] = function()
		local slots = Sequence.Clicks + 1
		for seed = 1, 400 do
			local roll = generator(seed)
			for final = 1, #Sequence.Tiers do
				local plan = Sequence.plan(final, roll)
				assert(#plan == slots, "One tier per landing and one for the shaking")
				local previous = 1
				for slot = 1, slots do
					local step = plan[slot] - previous
					assert(step == 0 or step == 1, "A slot raises the light by at most one tier")
					previous = plan[slot]
				end
				assert(plan[slots] == final, "The last light is the granted rarity")
				assert(plan[1] <= 2, "The first landing starts from white")
			end
		end
	end,
	["upgrades spread over different clicks and sometimes wait for the shaking"] = function()
		local placements: { [string]: boolean } = {}
		local late = 0
		local roll = generator(7)
		for _ = 1, 600 do
			local plan = Sequence.plan(4, roll)
			placements[table.concat(plan, ",")] = true
			if plan[Sequence.Clicks] < plan[Sequence.Clicks + 1] then
				late += 1
			end
		end
		local count = 0
		for _ in placements do
			count += 1
		end
		assert(count >= 10, "A legendary egg upgrades on different clicks: " .. count)
		assert(late > 100 and late < 300, "Late upgrades are a surprise, not a rule: " .. late)
		local common = Sequence.plan(1, generator(3))
		for _, tier in common do
			assert(tier == 1, "A common pet never shows a coloured light")
		end
	end,
	["clicks wait for the landing and buffer one press"] = function()
		local clicks = {}
		local first = Sequence.accept(clicks, 1)
		assert(first == 1)
		table.insert(clicks, first :: number)
		local queued = Sequence.accept(clicks, 1.1)
		assert(queued == 1 + Sequence.Jump + Sequence.Queue, "A press in the air starts after the landing")
		table.insert(clicks, queued :: number)
		assert(Sequence.accept(clicks, 1.2) == nil, "Only one press waits")
		assert(Sequence.accept(clicks, 3) == 3, "A later press starts at once")
		for k = #clicks + 1, Sequence.Clicks do
			clicks[k] = 10 + k
		end
		assert(Sequence.accept(clicks, 100) == nil, "No sixth click")
	end,
	["tier follows the landings and the late upgrade"] = function()
		local plan = { 1, 2, 2, 3, 3, 4 }
		local clicks = { 0, 1, 2, 3, 4 }
		local land = Sequence.Jump
		assert(Sequence.tierAt(plan, clicks, land - 0.01, 0) == 1)
		local tier, changed, previous = Sequence.tierAt(plan, clicks, 1 + land, 0)
		assert(tier == 2 and changed == 1 + land and previous == 1, "Upgrade on the second landing")
		tier, changed = Sequence.tierAt(plan, clicks, 2.9, 0)
		assert(tier == 2 and changed == 1 + land, "No upgrade keeps the old moment")
		local finale = Sequence.finale(clicks, 0) :: number
		assert(finale == 4 + land + Sequence.FinaleDelay)
		assert(Sequence.tierAt(plan, clicks, finale, 0) == 3)
		tier, changed, previous = Sequence.tierAt(plan, clicks, finale + Sequence.FinaleUpgrade, 0)
		assert(tier == 4 and previous == 3 and changed == finale + Sequence.FinaleUpgrade, "Late upgrade")
		assert(Sequence.finale({ 0, 1 }, 0) == nil, "No shaking before the fifth click")
		local count, latest = Sequence.landed(clicks, 2 + land, 0.1)
		assert(count == 2 and latest == 1 + 0.1 + land, "A delayed egg lands later")
	end,
	["the egg holds still before the burst"] = function()
		local clicks = { 0, 1, 2, 3, 4 }
		local finale = Sequence.finale(clicks, 0.05) :: number
		assert(Sequence.burst(clicks, 0.05) == finale + Sequence.Charge + Sequence.Freeze)
		assert(Sequence.Freeze >= 0.08 and Sequence.Freeze <= 0.2, "A beat, not a pause")
		assert(Sequence.burst({ 0, 1 }, 0) == nil, "No burst before the fifth click")
	end,
	["the epic mood starts when the light first turns legendary"] = function()
		local clicks = { 0, 1, 2, 3, 4 }
		local land = Sequence.Jump
		assert(Sequence.reached({ 1, 2, 3, 4, 4, 4 }, clicks, 0, 4) == 3 + land, "On the fourth landing")
		local finale = Sequence.finale(clicks, 0) :: number
		assert(Sequence.reached({ 1, 2, 3, 3, 3, 4 }, clicks, 0, 4) == finale + Sequence.FinaleUpgrade, "Late")
		assert(Sequence.reached({ 1, 2, 3, 3, 3, 3 }, clicks, 0, 4) == nil, "A rare egg never turns epic")
		assert(Sequence.reached({ 1, 2, 3, 4, 4, 4 }, { 0, 1 }, 0, 4) == nil, "Not before the landing")
	end,
	["landings, upgrades and the burst knock the screen"] = function()
		local plan = { 1, 2, 2, 2, 2, 2 }
		local clicks = { 0, 1, 2, 3, 4 }
		local land = Sequence.Jump
		assert(Sequence.shake(plan, clicks, land - 0.01, 0) == 0, "Still in the air")
		local landing = Sequence.shake(plan, clicks, land, 0)
		local upgrade = Sequence.shake(plan, clicks, 1 + land, 0)
		assert(landing > 0 and upgrade > landing, "An upgrade knocks harder than a landing")
		assert(Sequence.shake(plan, clicks, 1 + land + Sequence.Shake.Decay, 0) == 0, "The knock fades")
		assert(Sequence.shake(plan, clicks, 1.2 + land, 0) < upgrade, "Fading")
		local burst = Sequence.burst(clicks, 0) :: number
		assert(Sequence.shake(plan, clicks, burst, 0) == 1, "The burst is the hardest")
		assert(Sequence.shake(plan, clicks, burst - Sequence.Freeze / 2, 0) == 0, "The still moment")
		local mythic = Sequence.shake({ 2, 3, 4, 5, 5, 5 }, clicks, 3 + land, 0)
		assert(mythic > upgrade and mythic <= 1, "A stronger tier knocks harder")
	end,
	["roulette slows down and stops on the granted pet"] = function()
		for seed = 1, 200 do
			local roll = generator(seed)
			for size = 1, 5 do
				local final = math.min(size, 1 + seed % size)
				local frames, stop = Sequence.roulette(size, final, Sequence.Spin, roll)
				local last = frames[#frames]
				assert(last.index == final and last.at == stop, "The last silhouette is the granted pet")
				assert(stop >= Sequence.Spin, "The roulette spins for its whole time")
				assert(#frames >= 6, "Several silhouettes are shown")
				for i = 2, #frames do
					local gap = frames[i].at - frames[i - 1].at
					assert(gap > 0, "Frames move forward")
					if i > 2 then
						assert(gap >= frames[i - 1].at - frames[i - 2].at - 1e-9, "Frames slow down")
					end
					if size > 2 then
						assert(frames[i].index ~= frames[i - 1].index, "Neighbouring frames differ")
					end
					assert(frames[i].index >= 1 and frames[i].index <= size)
				end
				if size > 1 then
					assert(frames[#frames - 1].index ~= final, "The result is not shown a frame early")
				end
			end
		end
		local frames, stop = Sequence.roulette(4, 2, Sequence.Spin + Sequence.Stagger, generator(1))
		assert(stop >= Sequence.Spin + Sequence.Stagger, "Later eggs of a triple stop later")
		assert(Sequence.frameAt(frames, -0.01) == nil)
		local current, number = Sequence.frameAt(frames, stop + 5)
		assert(current == frames[#frames] and number == #frames)
	end,
}
