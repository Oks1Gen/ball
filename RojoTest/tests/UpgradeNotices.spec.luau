--!strict
local Notices = require("../src/shared/Core/UpgradeNotices")
local Data = require("../src/shared/Core/ProfileData")
local Net = require("../src/shared/Net")
local config = {
	Lanes = { { rebirths = 0, multiplier = 1 }, { rebirths = 2, multiplier = 2 }, { rebirths = 4, multiplier = 4 } },
	Stones = {
		{ id = "Pebble", name = "Starter", power = 1, cost = 0 },
		{ id = "Smooth", name = "Smooth", power = 2, cost = 250 },
		{ id = "Sun", name = "Sun", power = 10, cost = 2500 },
	},
	Trails = {
		{ id = "None", name = "None", boost = 1, cost = 0 },
		{ id = "Fire", name = "Fire", boost = 2, cost = 500 },
	},
}
local function snapshot(): any
	local data = Data.fresh()
	data.tutorialStage = 5
	return { data = data, rebirthReady = false }
end
local function candidate(info: any, kind: string): any
	for _, notice in Notices.available(info, config) do
		if notice.kind == kind then
			return notice
		end
	end
	return nil
end
return {
	["upgrade alerts require confirmed affordability and a completed tutorial"] = function()
		local info = snapshot()
		assert(#Notices.available(info, config) == 0)
		info.data.wins = 250
		assert(candidate(info, "Ball").itemId == "Smooth" and not candidate(info, "Trail"))
		info.data.wins = 2500
		assert(candidate(info, "Ball").itemId == "Sun" and candidate(info, "Trail").itemId == "Fire")
		info.data.tutorialStage = 4
		assert(#Notices.available(info, config) == 0)
		info.data.tutorialStage = 5
		info.data.settings.upgradeNotices = false
		assert(#Notices.available(info, config) == 0)
	end,
	["owned upgrades and lost affordability cannot remain advertised"] = function()
		local info = snapshot()
		info.data.wins = 2500
		local state = Notices.new()
		state:update(info, config)
		assert(state:step(0, false).itemId == "Sun")
		info.data.stones.Sun = true
		state:update(info, config)
		assert(state.current == nil and candidate(info, "Ball") == nil)
		assert(state:step(1, false).kind == "Trail")
		info.data.wins = 0
		state:update(info, config)
		assert(state.current == nil and state:step(1, false) == nil)
	end,
	["lane unlocks and rebirth readiness have distinct actions"] = function()
		local info = snapshot()
		info.data.rebirths = 2
		assert(candidate(info, "Training").lane == 2 and candidate(info, "Rebirth") == nil)
		info.rebirthReady = true
		assert(candidate(info, "Rebirth").action == "VIEW REBIRTH" and candidate(info, "Rebirth").lane == nil)
		info.data.rebirths = 4
		assert(candidate(info, "Training").lane == 3)
		info.training = 3
		assert(candidate(info, "Training") == nil)
	end,
	["alert queue pauses in menus and dismisses without weaker or repeated spam"] = function()
		local info = snapshot()
		info.data.wins = 2500
		local state = Notices.new()
		state:update(info, config)
		assert(state:step(20, true) == nil and state.current == nil)
		assert(state:step(0, false).itemId == "Sun")
		state:step(20, true)
		assert(state.remaining == Notices.Duration)
		state:step(Notices.Duration + 1, false)
		assert(state.current == nil)
		assert(state:step(1, false).kind == "Trail")
		state:dismiss()
		info.data.wins = 250
		state:update(info, config)
		assert(state:step(20, false) == nil)
		info.data.wins = 2500
		state:update(info, config)
		assert(state:step(20, false) == nil)
		info.rebirthReady = true
		state:update(info, config)
		assert(state:step(0, false).kind == "Rebirth")
	end,
	["an alert shown in an earlier session never returns, a stronger one still does"] = function()
		local info = snapshot()
		info.data.wins = 2500
		info.rebirthReady = true
		local reported = {}
		local first = Notices.new()
		first.onAnnounce = function(kind: string, rank: number)
			reported[kind] = rank
		end
		first:update(info, config)
		assert(first:step(0, false).kind == "Rebirth" and reported.Rebirth == 1)
		info.data.notices.Rebirth = reported.Rebirth
		info.data.notices.Ball = 10
		info.data.notices.Trail = 2
		local rejoined = Notices.new()
		rejoined:update(info, config)
		assert(rejoined:step(20, false) == nil)
		info.data.rebirths = 1
		rejoined:update(info, config)
		assert(rejoined:step(20, false).kind == "Rebirth")
		local catalog = { stones = { Pebble = true }, trails = { None = true }, pets = {} }
		info.data.notices.Ball = 0 / 0
		local loaded = Data.normalize(info.data, catalog)
		assert(loaded.notices.Rebirth == 1 and loaded.notices.Ball == 0 and loaded.notices.Trail == 2)
		assert(Net.validAction("NoticeSeen", "Ball", 1.15))
		assert(not Net.validAction("NoticeSeen", "Pets", 1))
		assert(not Net.validAction("NoticeSeen", "Ball", -1))
	end,
	["disabling alerts clears a live notice and the boolean survives normalization"] = function()
		local info = snapshot()
		assert(info.data.settings.upgradeNotices == true)
		info.rebirthReady = true
		local state = Notices.new()
		state:update(info, config)
		assert(state:step(0, false) ~= nil)
		info.data.settings.upgradeNotices = false
		state:update(info, config)
		assert(state.current == nil and state:step(100, false) == nil)
		local catalog = { stones = { Pebble = true }, trails = { None = true }, pets = {} }
		assert(Data.normalize(info.data, catalog).settings.upgradeNotices == false)
		info.data.settings.upgradeNotices = nil
		assert(Data.normalize(info.data, catalog).settings.upgradeNotices == true)
		info.data.settings.upgradeNotices = "false"
		assert(Data.normalize(info.data, catalog).settings.upgradeNotices == true)
		assert(Net.validAction("Setting", "upgradeNotices", false))
		assert(Net.validAction("Setting", "upgradeNotices", true))
		assert(not Net.validAction("Setting", "upgradeNotices", "false"))
	end,
}
