--!strict
-- Builds the legacy HUD once. The layout module moves the same instances
-- between the landscape board and the portrait column, so nothing here knows
-- about the window size.
local Kit = require(script.Parent.HudKit)
local Layout = require(script.Parent.Parent.Modules.HudLayout)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)

local Builder = {}
local C = Color3.fromRGB
local yellow = C(255, 225, 66)
local function caption(button: TextButton): TextLabel
	return assert(Kit.captionOf(button))
end

export type Context = {
	canvas: Frame,
	send: (string, any?, any?) -> (),
	openPanel: (string) -> (),
	snapshot: () -> any?,
}

export type Refs = {
	hud: Frame,
	auto: TextButton,
	throwButton: TextButton,
	stopButton: TextButton,
	levelFill: Frame,
	levelText: TextLabel,
	maxText: TextLabel,
	skillText: TextLabel,
	multiText: TextLabel,
	levelUpText: TextLabel,
	rebirthText: TextLabel,
	winsText: TextLabel,
	friendText: TextLabel,
	distanceText: TextLabel,
	powerText: TextLabel,
	bestText: TextLabel,
	tutorial: TextLabel,
	rebirthPercent: TextLabel,
}

function Builder.build(context: Context): Refs
	local canvas = context.canvas
	local send = context.send
	local spec = Layout.landscape()
	local function at(name: string): Layout.Entry
		local item = spec.elements[name]
		assert(item, "Missing layout entry: " .. name)
		return item
	end

	local hudItem = at("HUD")
	local hud = Kit.frame(canvas, "HUD", hudItem.x, hudItem.y, hudItem.w, hudItem.h)
	hud.BackgroundTransparency = 1

	local autoItem = at("AutoThrow")
	local auto = Kit.button(
		hud,
		"AutoThrow",
		"AUTO KICK",
		autoItem.x,
		autoItem.y,
		autoItem.w,
		autoItem.h,
		C(204, 37, 62),
		19,
		function()
			local snapshot = context.snapshot()
			if snapshot and snapshot.data.perks.AutoThrow then
				send("Auto")
			else
				context.openPanel("Shop")
			end
		end
	)
	caption(auto).Position = UDim2.fromOffset(3, 7)
	caption(auto).Size = UDim2.fromOffset(autoItem.w - 6, 25)
	Kit.icon(auto, "Wins", (autoItem.w - 43) / 2, -15, 43, 31)
	Kit.text(auto, "Price", "ONLY", 56, 32, 43, 17, 14, yellow)
	Kit.icon(auto, "Robux", 103, 32, 17, 17)
	Kit.text(auto, "Amount", "25", 124, 32, 27, 17, 14, yellow)

	local settingsItem = at("Settings")
	local settings = Kit.button(
		canvas,
		"Settings",
		"",
		settingsItem.x,
		settingsItem.y,
		settingsItem.w,
		settingsItem.h,
		C(37, 47, 58),
		16,
		function()
			context.openPanel("Settings")
		end
	)
	Kit.icon(settings, "Settings", 3, 3, 30, 30)
	local dailyItem = at("Daily")
	local daily = Kit.button(
		hud,
		"Daily",
		"",
		dailyItem.x,
		dailyItem.y,
		dailyItem.w,
		dailyItem.h,
		C(30, 32, 39),
		18,
		function()
			context.openPanel("Daily")
		end
	)
	Kit.hide(daily, "Studs")
	Kit.hide(hud, "DailyShadow")
	Kit.corner(daily, 999)
	Kit.icon(daily, "Daily", 5, 5, dailyItem.w - 10, dailyItem.h - 10)

	local starterItem = at("StarterPack")
	local starter = Kit.button(
		hud,
		"StarterPack",
		"",
		starterItem.x,
		starterItem.y,
		starterItem.w,
		starterItem.h,
		C(250, 201, 60),
		18,
		function()
			send("Product", "StarterPack")
		end
	)
	Kit.visualOf(starter).BackgroundTransparency = 1
	Kit.hide(starter, "Studs")
	Kit.hide(starter, "UIStroke")
	Kit.hide(hud, "StarterPackShadow")
	Kit.icon(starter, "Pets", 24, 5, 63, 59, C(173, 107, 248))
	Kit.icon(starter, "Skill", 1, -1, 37, 56)
	Kit.icon(starter, "Rebirth", 77, -2, 38, 39)
	Kit.text(starter, "Caption2", "STARTER PACK", 3, 69, 113, 16, 12)

	local skillItem = at("DoubleSkill")
	local skillOffer = Kit.button(
		hud,
		"DoubleSkill",
		"+2× SKILL",
		skillItem.x,
		skillItem.y,
		skillItem.w,
		skillItem.h,
		C(164, 233, 35),
		23,
		function()
			send("Product", "DoubleSkill")
		end
	)
	caption(skillOffer).Position = UDim2.fromOffset(3, 12)
	caption(skillOffer).Size = UDim2.fromOffset(119, 25)
	Kit.icon(skillOffer, "Skill", 50, -13, 39, 37)
	Kit.text(skillOffer, "Price", "ONLY", 17, 42, 43, 15, 14, yellow)
	Kit.icon(skillOffer, "Robux", 64, 40, 17, 17)
	Kit.text(skillOffer, "Amount", "5", 85, 42, 20, 15, 14, yellow)

	local winsItem = at("DoubleWins")
	local winsOffer = Kit.button(
		hud,
		"DoubleWins",
		"2× WINS",
		winsItem.x,
		winsItem.y,
		winsItem.w,
		winsItem.h,
		C(255, 196, 56),
		23,
		function()
			send("Product", "DoubleWins")
		end
	)
	caption(winsOffer).Position = UDim2.fromOffset(3, 9)
	caption(winsOffer).Size = UDim2.fromOffset(119, 27)
	Kit.icon(winsOffer, "Wins", 46, -7, 39, 37)
	Kit.text(winsOffer, "Price", "ONLY", 13, 42, 43, 15, 14, yellow)
	Kit.icon(winsOffer, "Robux", 60, 40, 17, 17)
	Kit.text(winsOffer, "Amount", "59", 81, 42, 30, 15, 14, yellow)

	local throwItem = at("Throw")
	local throwButton = Kit.button(
		hud,
		"Throw",
		"KICK",
		throwItem.x,
		throwItem.y,
		throwItem.w,
		throwItem.h,
		C(112, 237, 10),
		29,
		function()
			send("Throw")
		end
	)

	local stopItem = at("StopTraining")
	local stopButton = Kit.button(
		hud,
		"StopTraining",
		"STOP TRAINING",
		stopItem.x,
		stopItem.y,
		stopItem.w,
		stopItem.h,
		C(251, 65, 77),
		25,
		function()
			send("StopTraining")
		end
	)
	stopButton.Visible = false

	local skillTextItem = at("Skill")
	local skillText = Kit.text(
		hud,
		"Skill",
		"0 SKILL",
		skillTextItem.x,
		skillTextItem.y,
		skillTextItem.w,
		skillTextItem.h,
		skillTextItem.text,
		yellow
	)
	skillText.TextXAlignment = Enum.TextXAlignment.Left
	local skillIconItem = at("SkillIcon")
	Kit.icon(hud, "Skill", skillIconItem.x, skillIconItem.y, skillIconItem.w, skillIconItem.h)

	local multiItem = at("Multiplier")
	local multiText = Kit.text(
		hud,
		"Multiplier",
		"×1 Multiplier",
		multiItem.x,
		multiItem.y,
		multiItem.w,
		multiItem.h,
		multiItem.text,
		yellow
	)
	multiText.TextXAlignment = Enum.TextXAlignment.Left
	local levelUpItem = at("LevelUp")
	local levelUpText =
		Kit.text(hud, "LevelUp", "", levelUpItem.x, levelUpItem.y, levelUpItem.w, levelUpItem.h, levelUpItem.text)
	levelUpText.Visible = false

	local levelItem = at("LevelBar")
	local levelBase = Kit.frame(hud, "LevelBar", levelItem.x, levelItem.y, levelItem.w, levelItem.h, C(226, 230, 235))
	Kit.corner(levelBase, 9)
	Kit.stroke(levelBase, 3)
	Kit.pattern(levelBase, C(190, 196, 204))
	local levelFill = Kit.frame(levelBase, "Progress", 0, 0, 0, levelItem.h, Color3.new(1, 1, 1))
	levelFill.Size = UDim2.fromScale(0, 1)
	Kit.corner(levelFill, 8)
	local fillGradient = Instance.new("UIGradient")
	fillGradient.Rotation = 90
	fillGradient.Color = ColorSequence.new(C(0, 214, 255), C(0, 112, 255))
	fillGradient.Parent = levelFill
	Kit.pattern(levelFill, C(64, 179, 223))
	local levelTextItem = at("LevelBar/Level")
	local levelText = Kit.text(
		levelBase,
		"Level",
		"Level 1",
		levelTextItem.x,
		levelTextItem.y,
		levelTextItem.w,
		levelTextItem.h,
		levelTextItem.text
	)
	levelText.TextXAlignment = Enum.TextXAlignment.Left
	levelText.ZIndex = 3
	local maxItem = at("LevelBar/Maximum")
	local maxText = Kit.text(levelBase, "Maximum", "0 / 2", maxItem.x, maxItem.y, maxItem.w, maxItem.h, maxItem.text)
	maxText.TextXAlignment = Enum.TextXAlignment.Right
	maxText.ZIndex = 3

	for _, offer in
		{
			{ "+10M", "Skill10M", C(255, 205, 57) },
			{ "+100M", "Skill100M", C(250, 98, 100) },
			{ "+1B", "Skill1B", C(174, 111, 239) },
		}
	do
		local item = at(offer[2])
		local b = Kit.button(hud, offer[2], offer[1], item.x, item.y, item.w, item.h, offer[3], 30, function()
			send("Product", offer[2])
		end)
		Kit.icon(b, "Skill", 72, -7, 40, 67)
		caption(b).ZIndex = 3
		Kit.icon(b, "Robux", item.w - 54, 44, 22, 22)
		Kit.text(b, "Price", tostring(Config.Products[offer[2]].price), item.w - 30, 44, 30, 23, 18, C(142, 255, 51))
	end

	local rebirthIconItem = at("RebirthIcon")
	Kit.icon(hud, "Rebirth", rebirthIconItem.x, rebirthIconItem.y, rebirthIconItem.w, rebirthIconItem.h)
	local rebirthItem = at("RebirthCount")
	local rebirthText = Kit.text(
		hud,
		"RebirthCount",
		"0",
		rebirthItem.x,
		rebirthItem.y,
		rebirthItem.w,
		rebirthItem.h,
		rebirthItem.text,
		C(139, 233, 255)
	)
	rebirthText.TextXAlignment = Enum.TextXAlignment.Left

	local winsIconItem = at("WinsIcon")
	Kit.icon(hud, "Wins", winsIconItem.x, winsIconItem.y, winsIconItem.w, winsIconItem.h)
	local winsCountItem = at("WinsCount")
	local winsText = Kit.text(
		hud,
		"WinsCount",
		"0",
		winsCountItem.x,
		winsCountItem.y,
		winsCountItem.w,
		winsCountItem.h,
		winsCountItem.text,
		yellow
	)
	winsText.TextXAlignment = Enum.TextXAlignment.Left

	local friendItem = at("FriendBoost")
	local friendText = Kit.text(
		hud,
		"FriendBoost",
		"Friend Boost +0%",
		friendItem.x,
		friendItem.y,
		friendItem.w,
		friendItem.h,
		friendItem.text
	)
	friendText.TextXAlignment = Enum.TextXAlignment.Left

	local distanceItem = at("Distance")
	local distanceText = Kit.text(
		hud,
		"Distance",
		"",
		distanceItem.x,
		distanceItem.y,
		distanceItem.w,
		distanceItem.h,
		distanceItem.text,
		yellow
	)
	local powerItem = at("HitDistance")
	local powerText = Kit.text(
		hud,
		"HitDistance",
		"HIT: 60 m",
		powerItem.x,
		powerItem.y,
		powerItem.w,
		powerItem.h,
		powerItem.text,
		C(225, 255, 255)
	)
	local bestItem = at("Best")
	local bestText = Kit.text(hud, "Best", "", bestItem.x, bestItem.y, bestItem.w, bestItem.h, bestItem.text)
	bestText.TextXAlignment = Enum.TextXAlignment.Right
	local hintItem = at("Hint")
	local tutorial = Kit.text(
		hud,
		"Hint",
		"Walk onto a training pad to gain Skill",
		hintItem.x,
		hintItem.y,
		hintItem.w,
		hintItem.h,
		hintItem.text
	)
	tutorial.TextTransparency = 0.15

	local percentItem = at("RebirthProgress")
	local rebirthPercent = Kit.text(
		hud,
		"RebirthProgress",
		"0%",
		percentItem.x,
		percentItem.y,
		percentItem.w,
		percentItem.h,
		percentItem.text
	)
	rebirthPercent.Visible = false

	return {
		hud = hud,
		auto = auto,
		throwButton = throwButton,
		stopButton = stopButton,
		levelFill = levelFill,
		levelText = levelText,
		maxText = maxText,
		skillText = skillText,
		multiText = multiText,
		levelUpText = levelUpText,
		rebirthText = rebirthText,
		winsText = winsText,
		friendText = friendText,
		distanceText = distanceText,
		powerText = powerText,
		bestText = bestText,
		tutorial = tutorial,
		rebirthPercent = rebirthPercent,
	}
end

return Builder
