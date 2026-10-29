--!strict
-- Server-owned onboarding. No client command can claim a completed objective.
local Tutorial = {}
Tutorial.TrainingGoal = 30
Tutorial.Complete = 5

function Tutorial.train(data: any, gain: number)
	if data.tutorialStage == 0 then
		data.tutorialSkill = math.min(Tutorial.TrainingGoal, data.tutorialSkill + math.max(0, gain))
		if data.tutorialSkill >= Tutorial.TrainingGoal then
			data.tutorialStage = 1
		end
	end
end

function Tutorial.shot(data: any, manual: boolean)
	if data.tutorialStage == 1 and manual then
		data.tutorialStage = 2
	end
end

function Tutorial.restart(data: any)
	data.tutorialStage, data.tutorialSkill = 0, 0
end

function Tutorial.ball(data: any, id: string)
	if data.tutorialStage == 2 and id ~= "Pebble" and data.stones[id] and data.stone == id then
		data.tutorialStage = 3
	end
end

function Tutorial.hatched(data: any)
	if data.tutorialStage == 3 then
		data.tutorialStage = 4
	end
end

function Tutorial.equipped(data: any)
	if data.tutorialStage == 4 and #data.equipped > 0 then
		data.tutorialStage = Tutorial.Complete
	end
end

return Tutorial
