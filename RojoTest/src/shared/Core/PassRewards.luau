--!strict
local Data = require("./ProfileData")
local Rewards = {}

-- All entitlement mutations are synchronous. ProfileStore saves the bonus and
-- its one-time marker in the same profile; ownership restores them after a crash.
function Rewards.apply(data: any, key: string): boolean
	local perks = data.perks
	if key == "StarterPack" then
		local changed = not perks.StarterPack or not perks.DoubleSkill
		data.passGrants = data.passGrants or {}
		if not data.passGrants.StarterPack and not perks.StarterPack then
			Data.add(data, "wins", 10000)
		end
		data.passGrants.StarterPack = true
		perks.StarterPack, perks.DoubleSkill = true, true
		return changed
	elseif key == "AutoThrow" or key == "DoubleSkill" or key == "DoubleWins" then
		local changed = perks[key] ~= true
		perks[key] = true
		return changed
	end
	return false
end

function Rewards.owned(data: any, key: string, kind: string): boolean
	return kind == "GamePass" and data.perks[key] == true
end

return Rewards
