--!strict
-- Client-only isolated UI fixture. No gameplay remotes or profile writes.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
local player = game.Players.LocalPlayer
local client = player.PlayerScripts.Client
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Data = require(game.ReplicatedStorage.Shared.Core.ProfileData)
local Craft = require(game.ReplicatedStorage.Shared.Core.PetCrafting)
local Challenges = require(game.ReplicatedStorage.Shared.Core.Challenges)
local Pages = require(client.CollectorUI.InventoryPages)
local Screens = require(client.CollectorUI.Screens)
local previous = _G.BalanceQA
if previous then
	previous.destroy()
end
local gui = Instance.new("ScreenGui")
gui.Name = "BalanceQA"
gui.DisplayOrder = 1000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = player.PlayerGui
local frame = Instance.new("Frame")
frame.Name = "Panel"
frame.Size = UDim2.fromOffset(700, 452)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(34, 61, 84)
frame.Parent = gui
local root: any = nil
local data = Data.fresh()
data.wins, data.skill, data.petMaterial, data.tutorialStage = 50000, 20000, 30, 5
data.stones.Smooth = true
data.stone = "Smooth"
data.pets = {
	{ uid = "fixture-a", id = "Cactus", name = "Cactus", rarity = "Common", boost = 1.15 },
	{ uid = "fixture-s", id = "EclipseCat", name = "Eclipse Cat", rarity = "Secret", boost = 10 },
}
data.equipped = { "fixture-s" }
data.challengeProgress["1:first-kick"] = 1
local snap = { data = data, inventory = { pets = data.pets, equipped = data.equipped }, elapsed = 90, gifts = {} }
local mode = "Balls"
local selected = "fixture-a"
local events: { any } = {}
local render: (string?) -> ()
local function request(command: string, id: string?)
	local ok, message = false, ""
	if command == "RecyclePet" then
		ok, message = Craft.salvage(data, assert(id))
	elseif command == "PetCraft" then
		ok, message = true, "Open Pet Workshop from the game"
	elseif command == "ClaimChallenge" then
		ok, message = Challenges.claim(data, assert(id))
	end
	table.insert(events, { command = command, success = ok, message = message })
	if ok then
		local sound = Instance.new("Sound")
		sound.Name = "BalanceQASuccess"
		sound.SoundId = "rbxasset://sounds/volume_slider.ogg"
		sound.Parent = gui
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 2)
	end
	render()
end
render = function(nextMode: string?)
	mode = nextMode or mode
	if root then
		root:unmount()
		root = nil
	end
	frame:ClearAllChildren()
	local props: any = {
		Width = 676,
		Height = 420,
		Data = data,
		Inventory = snap.inventory,
		Phone = false,
		Reduced = false,
		Busy = false,
		Request = request,
		SelectedPet = selected,
		BallId = "Smooth",
		EggId = "Rainbow",
		UnifiedInventory = true,
		SelectBall = function() end,
		SelectPet = function(uid: string)
			selected = uid
			render()
		end,
		Open = function() end,
		PaidRandomRestricted = false,
		PurchasePolicyReady = true,
	}
	if mode == "Challenges" then
		local refresh = require(client.Controllers.ProgressionRewards).mount(frame, {
			snapshot = function()
				return snap
			end,
			send = request,
		})
		refresh()
	elseif mode == "Log" then
		local list = Instance.new("ScrollingFrame")
		list.Name = "UpdateLogList"
		list.Size = UDim2.fromScale(1, 1)
		list.BackgroundTransparency = 1
		list.AutomaticCanvasSize = Enum.AutomaticSize.Y
		list.CanvasSize = UDim2.new()
		list.Parent = frame
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 12)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = list
		require(client.Controllers.UpdateLogView).mount(list, 676, false)
	else
		local component = if mode == "Balls" then Pages.Balls elseif mode == "Pets" then Pages.Pets else Screens.Eggs
		root = ReactRoblox.createRoot(frame)
		root:render(React.createElement(component, props))
	end
end
_G.BalanceQA = {
	render = render,
	data = data,
	events = events,
	destroy = function()
		if root then
			root:unmount()
		end
		gui:Destroy()
		_G.BalanceQA = nil
	end,
}
render("Balls")
return { fixture = gui:GetFullName(), profileWrites = 0 }
