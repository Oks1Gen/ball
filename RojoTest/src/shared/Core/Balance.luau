--!strict
-- Economy tuning only. All amounts are per second, Wins, or additive bonuses.
-- Rebirth requirements, bonuses and lane gates deliberately remain unchanged.
local Balance = {}
Balance.Version = 3
Balance.TrainingSkillPerSecond = 10
Balance.BubbleInterval = 14
Balance.FriendBonus = 0.1
Balance.SkillPassMultiplier = 2
Balance.WinsPerDistance = 8
Balance.Timing = {
	Minimum = 0.85,
	PowerBonus = 0.25,
	AccuracyBonus = 0.25,
	PowerMinimum = 0.5,
	PowerMaximum = 2,
	AccuracyMinimum = 0.5,
	AccuracyMaximum = 3,
}
Balance.FreeBubble = { Minimum = 5, Maximum = 15, Step = 0.1 }
Balance.Balls = {
	{ bonus = 1, cost = 0 },
	{ bonus = 2, cost = 80 },
	{ bonus = 3, cost = 750 },
	{ bonus = 5, cost = 4000 },
	{ bonus = 9, cost = 16000 },
	{ bonus = 15, cost = 75000 },
	{ bonus = 25, cost = 350000 },
	{ bonus = 40, cost = 2000000 },
	{ bonus = 65, cost = 8000000 },
	{ bonus = 100, cost = 25000000 },
}
Balance.PetBoosts = { 1.15, 1.3, 1.6, 2.2 }
Balance.PetWeights = { 5500, 3000, 1400, 100 }
-- Five-pet pools reserve part of the standard Rare weight for Epic.
Balance.EpicPetWeight = 400
Balance.SolarEpicBoost = 1.9
Balance.EggTiers = { Common = 1, Uncommon = 1.8, Rare = 3, Rainbow = 4.5, SolarCrown = 7 }
Balance.OceanPetBonus = 3
Balance.OceanEggCost = 10
-- x10 in Football City's Rainbow Egg before forms/mutations.
Balance.Secret = { Weight = 5, BaseBoost = 3 }
Balance.Crafting = {
	Yield = { Common = 1, Uncommon = 2, Rare = 4, Epic = 4, Legendary = 12 },
}
-- Form weights are conditional on success; odds() combines them with material count.
Balance.FusionCount = 5
Balance.CraftCooldown = 5
Balance.Forms = {
	Normal = { multiplier = 1 },
	Golden = { multiplier = 2 },
	Diamond = { multiplier = 4 },
	Rainbow = { multiplier = 8 },
}
Balance.FormOutcomes = {
	Normal = { { id = "Golden", weight = 9890 }, { id = "Diamond", weight = 100 }, { id = "Rainbow", weight = 10 } },
	Golden = { { id = "Diamond", weight = 9950 }, { id = "Rainbow", weight = 50 } },
	Diamond = { { id = "Rainbow", weight = 10000 } },
}
Balance.MutationCost = 10
Balance.Mutations = {
	{ id = "Wind", multiplier = 1.25, weight = 5500 },
	{ id = "Frost", multiplier = 1.35, weight = 2800 },
	{ id = "Flame", multiplier = 1.5, weight = 1200 },
	{ id = "Storm", multiplier = 1.75, weight = 450 },
	{ id = "Cosmic", multiplier = 2, weight = 50 },
}
Balance.Gifts = {
	{ time = 60, wins = 20, skill = 20 },
	{ time = 180, wins = 40, skill = 40 },
	{ time = 300, wins = 60, skill = 60 },
	{ time = 600, wins = 100, skill = 100 },
	{ time = 900, wins = 150, skill = 150 },
	{ time = 1800, wins = 250, skill = 250 },
}
-- Lifetime objectives, claimed once. Required zones use actual scene crossings.
Balance.Challenges = {
	{ id = "first-kick", title = "Make a manual kick", zone = 1, hits = 1, timing = 0, wins = 40, material = 1 },
	{ id = "zone-2", title = "Reach zone 2 twice", zone = 2, hits = 2, timing = 0, wins = 120, material = 2 },
	{
		id = "zone-3",
		title = "Two accurate kicks to zone 3",
		zone = 3,
		hits = 2,
		timing = 1.2,
		wins = 250,
		material = 3,
	},
	{ id = "zone-4", title = "Reach zone 4 three times", zone = 4, hits = 3, timing = 0, wins = 500, material = 4 },
	{
		id = "zone-5",
		title = "Two accurate kicks to zone 5",
		zone = 5,
		hits = 2,
		timing = 1.2,
		wins = 800,
		material = 5,
	},
	{ id = "zone-6", title = "Reach zone 6 three times", zone = 6, hits = 3, timing = 0, wins = 1200, material = 6 },
	{
		id = "zone-7",
		title = "Two accurate kicks to zone 7",
		zone = 7,
		hits = 2,
		timing = 1.2,
		wins = 1800,
		material = 8,
	},
	{
		id = "zone-8",
		title = "Three accurate kicks to zone 8",
		zone = 8,
		hits = 3,
		timing = 1.2,
		wins = 2500,
		material = 10,
	},
}

function Balance.petBoost(base: number, egg: string, world: number): number
	local bonus = (base - 1) * (Balance.EggTiers[egg] or 1) * (if world == 2 then Balance.OceanPetBonus else 1)
	return 1 + bonus
end

function Balance.trainingMultiplier(data: any, ballBonus: number, friends: number?, worldReward: number?): number
	local additive = 1 + ballBonus
	for _, uid in data.equipped do
		for _, pet in data.pets do
			if pet.uid == uid then
				additive += math.max(0, pet.boost - 1)
				break
			end
		end
	end
	return additive
		* (1 + data.rebirths)
		* (if data.perks.DoubleSkill then Balance.SkillPassMultiplier else 1)
		* (1 + (friends or 0) * Balance.FriendBonus)
		* (worldReward or 1)
end

return Balance
