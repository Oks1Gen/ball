-- Studio MCP Client: isolated React tree, no purchases, profile or network actions.
-- PreviewTime replays the synthetic clicks of HatchSequence.PreviewClicks.
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Sequence = require(game.ReplicatedStorage.Shared.Core.HatchSequence)
local Client = game.Players.LocalPlayer.PlayerScripts.Client.CollectorUI
local Stage = require(Client.HatchStage)
local Egg = require(Client.HatchEgg)
local gui = Instance.new("ScreenGui")
gui.Name = "HatchReferenceVerification"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = false
gui.Parent = game.Players.LocalPlayer.PlayerGui
local root = ReactRoblox.createRoot(gui)
local assertions = 0
local function check(value, message)
	assert(value, message)
	assertions += 1
end
local function named(name)
	local list = {}
	for _, item in gui:GetDescendants() do
		if item.Name == name then
			table.insert(list, item)
		end
	end
	return list
end
local function visibleCracks()
	local shown = 0
	for _, crack in named("CrackCore") do
		if crack.BackgroundTransparency < 0.5 then
			shown += 1
		end
	end
	return shown
end
-- `extra` adds the server marks (fresh, owned per pet) and the Open again inputs.
local function render(time, count, reduced, egg, world, defs, extra)
	extra = extra or {}
	local pets = {}
	for i = 1, count do
		local def = (defs or Config.Pets)[i]
		local mark = extra.marks and extra.marks[i] or {}
		table.insert(pets, {
			uid = "preview-" .. i,
			id = def.id,
			name = def.name,
			rarity = def.rarity,
			boost = def.boost,
			fresh = mark.fresh,
			owned = mark.owned,
		})
	end
	root:render(React.createElement(Stage, {
		-- The full screen stage of a 16:9 desktop in design units.
		Width = 1280,
		Height = 720,
		Hatched = pets,
		EggId = egg or "Common",
		Data = { world = world or 1, wins = extra.wins },
		Inventory = extra.inventory,
		Request = extra.request,
		Busy = extra.busy,
		PreviewTime = time,
		Reduced = reduced,
		Close = function() end,
	}))
	task.wait(0.08)
	return pets
end
local clicks = Sequence.PreviewClicks
local finale = clicks[Sequence.Clicks] + Sequence.Jump + Sequence.FinaleDelay
local burst = finale + Sequence.Charge + Sequence.Freeze
local Scenery = require(Client.HatchScenery)
local buildsBefore = Scenery.builds
local ok, result = pcall(function()
	for world = 1, 2 do
		for _, egg in Config.Eggs do
			render(0.2, 1, false, egg.id, world)
			check(#named("HatchingEgg") == 1, "Egg viewport: " .. egg.id)
			check(named("HatchEggStage")[1].GroupTransparency < 0.05, "Egg visible before the clicks")
			check(#named("CrackCore") == Egg.CrackCount, "Crack network")
			check(visibleCracks() == 0, "No cracks before the first landing")
			check(named("HatchTapHint")[1].Text ~= "", "Tap hint")
		end
	end
	for _, count in { 1, 3 } do
		render(0.2, count, false)
		local garden = named("HatchGarden")
		check(#garden == 1 and #garden[1]:GetChildren() > 200, "Garden built in the stage viewport")
		-- Every pedestal adds one gold rim.
		local rims = 0
		for _, part in garden[1]:GetDescendants() do
			if part:IsA("Part") and part.Material == Enum.Material.Neon and part.Shape == Enum.PartType.Cylinder then
				rims += 1
			end
		end
		check(rims == count, "One pedestal per egg")
		check(named("HatchSky")[1] ~= nil, "Sky behind the garden")
		check(named("HatchPetReveal")[1].ZIndex > named("HatchEggLayers")[1].ZIndex, "Pets above every egg light")
	end
	for _, count in { 1, 3 } do
		render(clicks[2] + Sequence.Jump + 0.1 + (count - 1) * Sequence.EggDelay, count, false)
		check(visibleCracks() == count * 4, "Two landings open two crack stages per egg")
		check(#named("HatchClickPip") == Sequence.Clicks, "Five click pips")
		check(not named("HatchContinue")[1].Visible, "No continue while clicking")
		-- Instances of a triple come in no particular order, so every egg is checked.
		render(finale + Sequence.Charge * 0.6, count, false)
		for _, glow in named("HatchChargeGlow") do
			check(glow.ImageTransparency < 0.7, "Egg glows white while shaking")
		end
		for _, stage in named("HatchEggStage") do
			check(stage.GroupTransparency < 0.05, "Egg visible while shaking")
		end
		-- The last egg of a triple bursts 2 × EggDelay later.
		render(burst + 0.08 + (count - 1) * Sequence.EggDelay, count, false)
		check(#named("HatchStar") == count * 14, "Star budget")
		check(#named("HatchShellShard") == count * 10, "Shell budget")
		check(#named("HatchLightRay") == count * 16, "Ray budget")
		for _, star in named("HatchStar") do
			check(star.ImageTransparency < 0.1, "Stars visible at the burst")
		end
		for _, stage in named("HatchEggStage") do
			check(stage.GroupTransparency > 0.95, "Shell gone after the burst")
		end
		check(not named("HatchContinue")[1].Visible, "No continue during the burst")
		local knock = named("HatchShake")[1].Position
		check(Vector2.new(knock.X.Offset, knock.Y.Offset).Magnitude > 0.3, "The burst knocks the scene")
		check(named("HatchSkyWash")[1].BackgroundTransparency < 0.8, "The burst washes the sky")
		check(named("HatchPresentation")[1].BackgroundTransparency == 1, "No dark reveal panel")
		render(burst + Sequence.RouletteDelay + 0.5, count, false)
		local silhouettes = 0
		for _, view in named("PetPreview") do
			if view.Visible then
				silhouettes += 1
				check(view.ImageColor3 == Color3.new(0, 0, 0), "Roulette shows black silhouettes")
			end
		end
		check(silhouettes == count, "One silhouette per egg")
		for _, item in named("HatchPetResult") do
			check(item.GroupTransparency == 1, "No labels during the roulette")
		end
		local pets = render(12, count, false)
		check(named("HatchContinue")[1].Visible, "Continue after the last egg")
		for _, item in named("HatchPetResult") do
			check(item.GroupTransparency == 0, "Result fully visible")
		end
		for _, view in named("PetPreview") do
			if view.Visible then
				check(view.ImageColor3 == Color3.new(1, 1, 1), "Granted pet filled with colour")
			end
		end
		local glows = named("HatchTierGlow")
		check(#glows == count, "One light per egg")
		local expected = {}
		for _, pet in pets do
			expected[Sequence.tierOf(pet.rarity)] = true
		end
		for _, glow in glows do
			local tier = table.find(Egg.TierColors, glow.ImageColor3)
			check(tier and expected[tier], "Light ends on the rarity of a granted pet")
			expected[tier] = nil
		end
		for _, item in named("HatchStar") do
			check(item.ImageTransparency == 1, "Stars finish fading")
		end
		local rest = named("HatchShake")[1].Position
		check(rest.X.Offset == 0 and rest.Y.Offset == 0, "The scene rests after the reveal")
	end
	-- The egg holds still at its biggest right before the burst.
	render(burst - Sequence.Freeze / 2, 1, false)
	local still = named("HatchEggStage")[1]
	check(still.Rotation == 0 and still.GroupTransparency < 0.05, "Still moment before the burst")
	-- Legendary and Mythic: night falls, light pillars stand on the pedestal and
	-- the rim takes the tier colour. A plainer pet keeps the evening.
	local epicDef, plainDef
	for _, def in Config.Pets do
		local tier = Sequence.tierOf(def.rarity)
		if tier >= Sequence.EpicTier then
			epicDef = epicDef or def
		elseif tier > 1 then
			plainDef = plainDef or def
		end
	end
	local function rim()
		for _, part in named("HatchGarden")[1]:GetDescendants() do
			if part.Name == "HatchPedestalRim" then
				return part
			end
		end
		return nil
	end
	local function close(a, b)
		return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 0.03
	end
	local gold = Color3.fromRGB(255, 190, 70)
	if epicDef then
		render(12, 1, false, nil, nil, { epicDef })
		local tier = Sequence.tierOf(epicDef.rarity)
		check(named("HatchEpicDim")[1].BackgroundTransparency < 0.6, "Night falls for " .. epicDef.rarity)
		check(#named("HatchHeavenBeam") == 5, "Five light pillars")
		for _, beam in named("HatchHeavenBeam") do
			check(beam.BackgroundTransparency < 0.95, "Pillars shine")
		end
		check(close(rim().Color, gold:Lerp(Egg.TierColors[tier], 0.85)), "Rim in the tier colour")
	end
	if plainDef then
		render(12, 1, false, nil, nil, { plainDef })
		check(named("HatchEpicDim")[1].BackgroundTransparency == 1, "No night for " .. plainDef.rarity)
		for _, beam in named("HatchHeavenBeam") do
			check(beam.BackgroundTransparency > 0.999, "No pillars for " .. plainDef.rarity)
		end
	end
	render(nil, 3, true)
	check(#named("HatchReferenceEffects") == 0, "Effects off skips decorative layers")
	check(#named("HatchEggLayers") == 0, "Effects off skips the clicks")
	check(#named("PetPreview") == 3, "Effects off loads only the granted pets")
	check(#named("HatchGarden") == 1, "Effects off keeps the still garden")
	check(#named("HatchEpicDim") + #named("HatchHeavenBeam") + #named("HatchSkyWash") == 0, "Effects off: no mood")
	check(close(rim().Color, gold), "Effects off: gold rim")
	check(named("HatchContinue")[1].Visible, "Effects off reveals result immediately")
	for _, item in named("HatchPetResult") do
		check(item.GroupTransparency == 0, "Effects off shows all pets")
	end
	-- Badges: NEW! for a new kind, the count for a duplicate, none without marks.
	local function badges()
		local texts = {}
		for _, label in named("HatchPetBadgeText") do
			table.insert(texts, label.Text)
		end
		table.sort(texts)
		return table.concat(texts, "|")
	end
	render(12, 3, false, nil, nil, nil, { marks = { { fresh = true, owned = 1 }, { owned = 2 }, {} } })
	check(badges() == "NEW!|You have 2", "NEW! and duplicate badges")
	for _, badge in named("HatchPetBadge") do
		check(badge.BackgroundTransparency < 0.5, "Badges shown after the reveal")
	end
	render(burst + Sequence.RouletteDelay + 0.5, 3, false, nil, nil, nil, { marks = { { fresh = true, owned = 1 } } })
	check(named("HatchPetBadge")[1].BackgroundTransparency == 1, "No badge during the roulette")
	render(12, 1, false)
	check(#named("HatchPetBadge") == 0, "No badge without the server marks")
	-- Open again: the same egg and amount, only with the wins and room for it.
	local common = Config.find(Config.Eggs, "Common")
	-- The click itself is checked live in Play: a script cannot fire Activated.
	local again = {
		wins = common.cost * 3,
		inventory = { pets = {} },
		request = function() end,
	}
	local sameEgg = {}
	for _, def in Config.eggPets("Common") do
		table.insert(sameEgg, def)
	end
	while #sameEgg < 3 do
		table.insert(sameEgg, sameEgg[1])
	end
	render(1, 3, false, nil, nil, sameEgg, again)
	check(not named("HatchOpenAgain")[1].Visible, "No Open again before the result")
	render(12, 3, false, nil, nil, sameEgg, again)
	local againFrame = named("HatchOpenAgain")[1]
	check(againFrame and againFrame.Visible, "Open again after the result")
	-- U.Button keeps its caption in a child label.
	local function caption()
		local texts = {}
		for _, item in named("HatchOpenAgain")[1]:GetDescendants() do
			if item:IsA("TextLabel") or item:IsA("TextButton") then
				table.insert(texts, item.Text)
			end
		end
		return table.concat(texts, " ")
	end
	check(string.find(caption(), Config.format(common.cost * 3), 1, true) ~= nil, "Open again shows the price")
	check(
		againFrame.Position.Y.Offset == named("HatchContinue")[1].Position.Y.Offset,
		"Open again stands beside Continue"
	)
	render(
		12,
		3,
		false,
		nil,
		nil,
		sameEgg,
		{ wins = common.cost * 3 - 1, inventory = again.inventory, request = again.request }
	)
	check(#named("HatchOpenAgain") == 0, "No Open again without the wins")
	local full = {}
	for i = 1, 58 do
		full[i] = { uid = "full-" .. i }
	end
	render(
		12,
		3,
		false,
		nil,
		nil,
		sameEgg,
		{ wins = common.cost * 3, inventory = { pets = full }, request = again.request }
	)
	check(#named("HatchOpenAgain") == 0, "No Open again without room")
	render(12, 3, false, nil, nil, sameEgg, { wins = common.cost * 3, inventory = again.inventory })
	check(#named("HatchOpenAgain") == 0, "No Open again without a request")
	render(
		12,
		1,
		false,
		nil,
		2,
		{ sameEgg[1] },
		{ wins = common.cost * 10, inventory = again.inventory, request = again.request }
	)
	check(string.find(caption(), Config.format(common.cost * 10), 1, true) ~= nil, "World 2 price")
	render(nil, 1, false)
	task.wait(1)
	check(named("HatchTapArea")[1].Visible, "Live stage waits for the clicks")
	check(not named("HatchContinue")[1].Visible, "No result without clicks")
	-- The garden is built once and moved between hatch screens.
	check(Scenery.builds - buildsBefore <= 1, "Garden built once for every screen")
	root:unmount()
	root = ReactRoblox.createRoot(gui)
	task.wait(0.05)
	local cached = Scenery.garden()
	check(cached.model.Parent == nil, "Closed screen keeps the garden aside")
	check(cached.model:FindFirstChild("HatchPedestals") == nil, "Closed screen drops its pedestals")
	render(12, 1, false)
	check(named("HatchGarden")[1] == cached.model, "Next screen reuses the same garden")
	check(Scenery.builds - buildsBefore <= 1, "Reopening does not rebuild the garden")
	return { assertions = assertions, worlds = 2, eggTypes = #Config.Eggs, counts = { 1, 3 }, profilesChanged = false }
end)
root:unmount()
gui:Destroy()
assert(ok, tostring(result))
return result
