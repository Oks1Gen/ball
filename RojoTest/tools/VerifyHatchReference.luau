-- Studio MCP Client: isolated React tree, no purchases, profile or network actions.
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Stage = require(game.Players.LocalPlayer.PlayerScripts.Client.CollectorUI.HatchStage)
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
local function render(time, count, reduced, egg, world)
	local pets = {}
	for i = 1, count do
		local def = Config.Pets[i]
		table.insert(
			pets,
			{ uid = "preview-" .. i, id = def.id, name = def.name, rarity = def.rarity, boost = def.boost }
		)
	end
	root:render(React.createElement(Stage, {
		Width = 656,
		Height = 390,
		Hatched = pets,
		EggId = egg or "Common",
		Data = { world = world or 1 },
		PreviewTime = time,
		Reduced = reduced,
		Close = function() end,
	}))
	task.wait(0.08)
end
local ok, result = pcall(function()
	for world = 1, 2 do
		for _, egg in Config.Eggs do
			render(0.95, 1, false, egg.id, world)
			check(#named("HatchingEgg") == 1, "Egg viewport: " .. egg.id)
			check(named("HatchEggStage")[1].GroupTransparency == 0, "Egg remains visible during charge")
			check(named("HatchPetResult")[1].GroupTransparency == 1, "No result before burst")
			check(#named("CrackCore") == 7, "Connected crack and branches")
		end
	end
	for _, count in { 1, 3 } do
		render(1.48, count, false)
		check(#named("HatchStar") == count * 14, "Star budget")
		check(#named("HatchShellShard") == count * 10, "Shell budget")
		check(#named("HatchLightRay") == count * 16, "Ray budget")
		check(not named("HatchContinue")[1].Visible, "No continue during burst")
		check(named("HatchStar")[1].ImageTransparency < 0.1, "Stars visible at reveal")
		check(named("HatchPresentation")[1].BackgroundTransparency == 1, "No dark reveal panel")
		for _, item in named("HatchPetResult") do
			check(item.BackgroundTransparency == 1, "Transparent result")
		end
		render(2.65, count, false)
		check(named("HatchContinue")[1].Visible, "Continue after last egg")
		for _, item in named("HatchPetResult") do
			check(item.GroupTransparency == 0, "Result fully visible")
		end
		for _, item in named("HatchEggStage") do
			check(item.GroupTransparency == 1, "Shell hidden after reveal")
		end
		for _, item in named("HatchStar") do
			check(item.ImageTransparency == 1, "Stars finish fading")
		end
	end
	render(nil, 3, true)
	check(#named("HatchReferenceEffects") == 0, "Effects off skips decorative layers")
	check(named("HatchContinue")[1].Visible, "Effects off reveals result immediately")
	for _, item in named("HatchPetResult") do
		check(item.GroupTransparency == 0, "Effects off shows all pets")
	end
	render(nil, 1, false)
	task.wait(2.8)
	check(named("HatchContinue")[1].Visible, "Live clock reaches completion")
	return { assertions = assertions, worlds = 2, eggTypes = 4, counts = { 1, 3 }, profilesChanged = false }
end)
root:unmount()
gui:Destroy()
assert(ok, tostring(result))
return result
