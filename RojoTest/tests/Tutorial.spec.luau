--!strict
local Tutorial = require("../src/shared/Core/Tutorial")
local Data = require("../src/shared/Core/ProfileData")
local catalog = { stones = { Pebble = true }, trails = { None = true }, pets = {} }
return {
	["replay keeps all objectives even with existing inventory"] = function()
		local d = Data.fresh()
		d.stones.Smooth = true
		d.stone = "Smooth"
		d.pets = { { uid = "old" } }
		d.equipped = { "old" }
		d.tutorialStage = 5
		Tutorial.restart(d)
		assert(d.tutorialStage == 0 and d.tutorialSkill == 0 and d.stones.Smooth)
		Tutorial.train(d, 30)
		Tutorial.shot(d, true)
		assert(d.tutorialStage == 2)
		Tutorial.equipped(d)
		Tutorial.hatched(d)
		assert(d.tutorialStage == 2)
		Tutorial.ball(d, "Smooth")
		assert(d.tutorialStage == 3)
		assert(#d.pets == 1 and d.equipped[1] == "old")
		Tutorial.hatched(d)
		assert(d.tutorialStage == 4)
		Tutorial.equipped(d)
		assert(d.tutorialStage == 5)
	end,

	["tutorial trains only from actual training gains"] = function()
		local d = Data.fresh()
		d.skill = 50000
		assert(d.tutorialStage == 0)
		Tutorial.train(d, 12)
		assert(d.tutorialSkill == 12 and d.tutorialStage == 0)
		Tutorial.train(d, 25)
		assert(d.tutorialSkill == 30 and d.tutorialStage == 1)
	end,
	["tutorial requires manual completed shot before purchases"] = function()
		local d = Data.fresh()
		Tutorial.shot(d, true)
		assert(d.tutorialStage == 0)
		Tutorial.train(d, 30)
		Tutorial.shot(d, false)
		assert(d.tutorialStage == 1)
		Tutorial.shot(d, true)
		assert(d.tutorialStage == 2)
		d.wins = 99999
		assert(d.tutorialStage == 2)
		d.stones.Smooth = true
		d.stone = "Smooth"
		Tutorial.ball(d, "Smooth")
		assert(d.tutorialStage == 3)
		d.pets = { { uid = "one" } }
		Tutorial.hatched(d)
		assert(d.tutorialStage == 4)
		d.equipped = { "one" }
		Tutorial.equipped(d)
		assert(d.tutorialStage == Tutorial.Complete)
	end,
	["tutorial resumes from saved progress and bounds corrupt fields"] = function()
		local d = Data.fresh()
		Tutorial.train(d, 17)
		local loaded = Data.normalize(d, catalog)
		assert(loaded.tutorialStage == 0 and loaded.tutorialSkill == 17)
		loaded.tutorialStage = 3
		assert(Data.normalize(loaded, catalog).tutorialStage == 3)
		local bad = Data.normalize({ tutorialStage = math.huge, tutorialSkill = -100 }, catalog)
		assert(bad.tutorialStage == 0 and bad.tutorialSkill == 0)
		local legacy = Data.normalize({ skill = 1000, best = 100 }, catalog)
		assert(legacy.tutorialStage == 0 and legacy.tutorialSkill == 0)
	end,
}
