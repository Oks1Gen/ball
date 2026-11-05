--!strict
-- Save data contains only JSON values. This module has no engine dependencies.
local Data = {}
-- Largest whole number represented exactly by a Luau number. Accrual and
-- loading share this cap, so a rejoin cannot change valid live counters.
Data.MaxProgress = 9007199254740991

function Data.bound(value: number): number
	return math.clamp(math.floor(value), 0, Data.MaxProgress)
end

function Data.add(data: any, key: string, amount: number)
	data[key] = Data.bound(data[key] + amount)
end

-- Every runtime path assumes at most 60 pets, so a stored profile with more
-- is trimmed on load instead of breaking the inventory limits later.
local MAX_PETS = 60

function Data.fresh(): any
	return {
		skill = 0,
		wins = 0,
		rebirths = 0,
		best = 0,
		-- Robux spent on this game's products; the ДОНАТ leaderboard ranks it.
		donated = 0,
		tutorialStage = 0,
		tutorialSkill = 0,
		stone = "Pebble",
		stones = { Pebble = true },
		trail = "None",
		trails = { None = true },
		pets = {},
		equipped = {},
		world = 1,
		oceanUnlocked = false,
		perks = {},
		passGrants = {}, -- Durable one-time grants, independent of resettable perks.
		receipts = {},
		trainingBoosts = { ["67"] = 0, ["69"] = 0, ["144"] = 0 },
		settings = { sound = 100, music = 100, shake = true, effects = true, upgradeNotices = true },
		-- The strongest upgrade alert already shown per kind; each alert appears once.
		notices = { Training = 0, Rebirth = 0, Ball = 0, Trail = 0 },
		daily = 0,
		dailyCount = 0,
		lastSeen = 0,
		offlineRate = 0,
		offlinePending = 0,
	}
end

function Data.resetProgress(input: any): any
	local fresh = Data.fresh()
	fresh.settings = table.clone(input.settings)
	-- Receipts and one-time bundle grants are accounting records, not benefits.
	fresh.receipts = input.receipts
	fresh.passGrants = table.clone(input.passGrants or {})
	if input.perks.StarterPack then
		fresh.passGrants.StarterPack = true
	end
	return fresh
end

function Data.finite(value: any): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function bounded(value: any, fallback: number, maximum: number): number
	return if Data.finite(value) then math.clamp(math.floor(value), 0, maximum) else fallback
end

local function flags(value: any): any
	local result = {}
	if type(value) == "table" then
		for key, enabled in value do
			if type(key) == "string" and #key <= 200 and enabled == true then
				result[key] = true
			end
		end
	end
	return result
end

function Data.normalize(input: any, catalog: any): any
	local data = Data.fresh()
	if type(input) ~= "table" then
		return data
	end
	for _, key in { "skill", "wins", "rebirths", "best", "donated", "daily", "lastSeen", "offlinePending" } do
		data[key] = bounded(input[key], 0, Data.MaxProgress)
	end
	data.dailyCount = bounded(input.dailyCount, if data.daily > 0 then 1 else 0, 7)
	data.tutorialStage = bounded(input.tutorialStage, 0, 5)
	data.tutorialSkill = bounded(input.tutorialSkill, 0, 30)
	data.offlineRate = if Data.finite(input.offlineRate) then math.clamp(input.offlineRate, 0, Data.MaxProgress) else 0
	data.stones = flags(input.stones)
	data.trails = flags(input.trails)
	data.stones.Pebble, data.trails.None = true, true
	if type(input.stone) == "string" and catalog.stones[input.stone] and data.stones[input.stone] then
		data.stone = input.stone
	end
	if type(input.trail) == "string" and catalog.trails[input.trail] and data.trails[input.trail] then
		data.trail = input.trail
	end
	data.perks, data.receipts = flags(input.perks), flags(input.receipts)
	data.passGrants = flags(input.passGrants)
	if data.perks.StarterPack then
		data.passGrants.StarterPack = true
	end
	if data.perks.AdminEggPending then
		data.adminEggPendingCount = math.max(1, bounded(input.adminEggPendingCount, 1, Data.MaxProgress))
	end
	if type(input.trainingBoosts) == "table" then
		for key in data.trainingBoosts do
			data.trainingBoosts[key] = bounded(input.trainingBoosts[key], 0, 1000000)
		end
	end
	-- New sessions start in Football City. Keep the paid access from older saves.
	data.oceanUnlocked = input.oceanUnlocked == true or input.unlockedWorld2 == true
	local seen = {}
	if type(input.pets) == "table" then
		for _, pet in ipairs(input.pets) do
			if #data.pets >= MAX_PETS then
				break
			end
			if
				type(pet) == "table"
				and type(pet.uid) == "string"
				and #pet.uid <= 100
				and not seen[pet.uid]
				and type(pet.id) == "string"
				and catalog.pets[pet.id]
			then
				local definition = catalog.pets[pet.id]
				seen[pet.uid] = true
				table.insert(data.pets, {
					uid = pet.uid,
					id = pet.id,
					name = definition.name,
					rarity = definition.rarity,
					boost = if Data.finite(pet.boost) then math.clamp(pet.boost, 1, 1e9) else 1,
				})
			end
		end
	end
	if type(input.equipped) == "table" then
		local equipped = {}
		for _, uid in ipairs(input.equipped) do
			if type(uid) == "string" and seen[uid] and not equipped[uid] and #data.equipped < 3 then
				equipped[uid] = true
				table.insert(data.equipped, uid)
			end
		end
	end
	if type(input.notices) == "table" then
		for key in data.notices do
			local rank = input.notices[key]
			data.notices[key] = if Data.finite(rank) then math.clamp(rank, 0, Data.MaxProgress) else 0
		end
	end
	if type(input.settings) == "table" then
		for _, key in { "sound", "music" } do
			data.settings[key] = bounded(input.settings[key], 100, 100)
		end
		for _, key in { "shake", "effects", "upgradeNotices" } do
			if type(input.settings[key]) == "boolean" then
				data.settings[key] = input.settings[key]
			end
		end
	end
	return data
end

-- The old store is read only. Never import a profile still leased by an old server.
function Data.legacy(record: any, now: number): (any, string?)
	if record == nil then
		return nil, nil
	end
	if type(record) ~= "table" or type(record.data) ~= "table" then
		return nil, "Malformed legacy profile"
	end
	if record.owner ~= nil and (not Data.finite(record.expires) or record.expires > now) then
		return nil, "Legacy profile still has an active session"
	end
	return record.data, nil
end

return Data
