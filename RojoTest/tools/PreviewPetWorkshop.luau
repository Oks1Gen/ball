--!strict
-- Studio client fixture: real UI and pure rules; no remotes and no saved profile changes.
assert(game:GetService("RunService"):IsStudio())
local player = game.Players.LocalPlayer
local client = player.PlayerScripts.Client
local Panels = require(client.Controllers.HudPanels)
local View = require(client.Controllers.PetWorkshop)
local Data = require(game.ReplicatedStorage.Shared.Core.ProfileData)
local Craft = require(game.ReplicatedStorage.Shared.Core.PetCrafting)
View.dismiss()
if _G.WorkshopQA then
	_G.WorkshopQA.destroy()
end
local hidden = {}
for _, node in player.PlayerGui:GetDescendants() do
	if node:IsA("CanvasGroup") and node.Name:match("^Window_") and node.Visible then
		hidden[node] = true
		node.Visible = false
	end
end
local gui = Instance.new("ScreenGui")
gui.Name = "WorkshopQA"
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 1000
gui.Parent = player.PlayerGui
local canvas = Instance.new("Frame")
canvas.Name = "Canvas"
canvas.BackgroundTransparency = 1
canvas.Size = UDim2.fromOffset(1280, 720)
canvas.AnchorPoint = Vector2.new(0.5, 0.5)
canvas.Position = UDim2.fromScale(0.5, 0.5)
canvas.Parent = gui
local scale = Instance.new("UIScale")
scale.Scale = math.min(workspace.CurrentCamera.ViewportSize.X / 1280, workspace.CurrentCamera.ViewportSize.Y / 720)
scale.Parent = canvas
local data = Data.fresh()
data.petMaterial = 100
for i = 1, 10 do
	table.insert(data.pets, {
		uid = "qa" .. i,
		id = "Cactus",
		name = "Cactus",
		rarity = "Common",
		boost = 1.27,
		baseBoost = 1.27,
		eggId = "Uncommon",
		sourceWorld = 1,
	})
end
table.insert(data.pets, {
	uid = "cosmic",
	id = "CrystalCat",
	name = "Crystal Cat",
	rarity = "Legendary",
	boost = 44.2,
	baseBoost = 6.4,
	form = "Diamond",
	mutation = "Cosmic",
	eggId = "Rainbow",
	sourceWorld = 1,
})
local snapshot = {
	data = {},
	inventory = { pets = data.pets, equipped = data.equipped },
	elapsed = 0,
	gifts = {},
	purchasePolicyReady = true,
	paidRandomRestricted = false,
}
local function liveSnapshot(): any
	local progress = table.clone(data)
	progress.pets = nil
	progress.equipped = nil
	snapshot.data = progress
	snapshot.inventory = { pets = data.pets, equipped = data.equipped }
	return snapshot
end
local handle: any = nil
local events = {}
local unit = 0.5
local function send(command: string, value: any, extra: any)
	local ok, message, result
	if command == "Pet" then
		local slot = table.find(data.equipped, value)
		if slot then
			table.remove(data.equipped, slot)
		elseif #data.equipped < 3 then
			table.insert(data.equipped, value)
		end
		data.equipped = table.clone(data.equipped)
		handle.refresh()
		return
	elseif command == "FusePets" then
		ok, message, result = Craft.fuse(data, extra, value, unit)
	elseif command == "MutatePet" then
		ok, message, result = Craft.mutate(data, value, extra, unit)
	else
		return
	end
	table.insert(events, { command = command, ok = ok, message = message, result = result })
	if ok then
		View.present(result)
	end
	handle.refresh()
end
handle = Panels.mount({
	canvas = canvas,
	send = send,
	snapshot = liveSnapshot,
	closePanel = function()
		if handle then
			handle.close()
		end
	end,
	showPanel = function() end,
})
handle.open("PetCraft")
_G.WorkshopQA = {
	data = data,
	events = events,
	roll = function(value: number)
		unit = value
	end,
	refresh = function()
		handle.refresh()
	end,
	destroy = function()
		handle.destroy()
		for node in hidden do
			if node.Parent then
				node.Visible = true
			end
		end
		gui:Destroy()
		_G.WorkshopQA = nil
	end,
}
return { name = player.Name, petCount = #data.pets }
