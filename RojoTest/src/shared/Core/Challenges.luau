--!strict
local Balance = require("./Balance")
local Data = require("./ProfileData")
local Challenges = {}

function Challenges.key(world: number, id: string): string
	return tostring(world) .. ":" .. id
end

function Challenges.shot(data: any, world: number, zone: number, timing: number, manual: boolean): string?
	if not manual then
		return
	end
	local ready: string? = nil
	for _, goal in Balance.Challenges do
		local key = Challenges.key(world, goal.id)
		if zone >= goal.zone and timing >= goal.timing and not data.challengeClaims[key] then
			local before = data.challengeProgress[key] or 0
			data.challengeProgress[key] = math.min(goal.hits, before + 1)
			if before < goal.hits and data.challengeProgress[key] == goal.hits then
				ready = goal.title
			end
		end
	end
	return ready
end

function Challenges.claim(data: any, id: string): (boolean, string)
	for _, goal in Balance.Challenges do
		local key = Challenges.key(data.world, goal.id)
		if id ~= goal.id then
			continue
		end
		if data.challengeClaims[key] then
			return false, "Reward already claimed"
		end
		if (data.challengeProgress[key] or 0) < goal.hits then
			return false, "Complete the challenge first"
		end
		data.challengeClaims[key] = true
		Data.add(data, "wins", goal.wins)
		Data.add(data, "petMaterial", goal.material)
		return true, "+" .. goal.wins .. " Wins and " .. goal.material .. " Pet Shards"
	end
	return false, "Unknown challenge"
end

return Challenges
