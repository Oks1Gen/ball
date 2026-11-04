--!strict
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LoadingConfig = require(script.Config)
local player = Players.LocalPlayer
local SpawnReadiness = require(script.SpawnReadiness)
task.spawn(SpawnReadiness.start)
player:SetAttribute("MapIntroActive", true)

local playerGui = player:WaitForChild("PlayerGui")
local screen = Instance.new("ScreenGui")
screen.Name = "MapIntro"
screen.IgnoreGuiInset = true
screen.ScreenInsets = Enum.ScreenInsets.None
screen.ResetOnSpawn = false
screen.DisplayOrder = 10000
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Immediate cover and skip, even before packages replicate.
local cover = Instance.new("TextButton")
cover.Name = "SkipAnywhere"
cover.Size = UDim2.fromScale(1, 1)
cover.BackgroundColor3 = LoadingConfig.Colors.Bottom
cover.BorderSizePixel = 0
cover.Text = ""
cover.AutoButtonColor = false
cover.Modal = true
cover.ZIndex = 10
cover.Parent = screen
screen.Parent = playerGui
ReplicatedFirst:RemoveDefaultLoadingScreen()

local hidden: { [ScreenGui]: boolean } = {}
local connections: { RBXScriptConnection } = {}
local coreStates: { [Enum.CoreGuiType]: boolean } = {}
local finished = false
local view: any = nil
local function hideGui(gui: Instance)
	if not gui:IsA("ScreenGui") or gui == screen or hidden[gui] ~= nil then
		return
	end
	hidden[gui] = gui.Enabled
	gui.Enabled = false
	table.insert(
		connections,
		gui:GetPropertyChangedSignal("Enabled"):Connect(function()
			if gui.Enabled then
				hidden[gui] = true
				gui.Enabled = false
			end
		end)
	)
end
for _, gui in playerGui:GetChildren() do
	hideGui(gui)
end
table.insert(connections, playerGui.ChildAdded:Connect(hideGui))
for _, kind in
	{ Enum.CoreGuiType.Backpack, Enum.CoreGuiType.PlayerList, Enum.CoreGuiType.Chat, Enum.CoreGuiType.Health }
do
	pcall(function()
		coreStates[kind] = StarterGui:GetCoreGuiEnabled(kind)
		StarterGui:SetCoreGuiEnabled(kind, false)
	end)
end
ContextActionService:BindActionAtPriority(
	"MapIntroMovement",
	function()
		return Enum.ContextActionResult.Sink
	end,
	false,
	3000,
	Enum.PlayerActions.CharacterForward,
	Enum.PlayerActions.CharacterBackward,
	Enum.PlayerActions.CharacterLeft,
	Enum.PlayerActions.CharacterRight,
	Enum.PlayerActions.CharacterJump
)

local skipRequested = false
local function cleanup()
	if finished then
		return
	end
	finished = true
	ContextActionService:UnbindAction("MapIntroMovement")
	for _, connection in connections do
		connection:Disconnect()
	end
	if view then
		view.destroy()
	end
	screen:Destroy()
	for gui, enabled in hidden do
		if gui.Parent then
			gui.Enabled = enabled
		end
	end
	for kind, enabled in coreStates do
		pcall(function()
			StarterGui:SetCoreGuiEnabled(kind, enabled)
		end)
	end
	-- Welcome Back / Daily continue to use this lifecycle signal.
	player:SetAttribute("MapIntroActive", false)
end
local function closeWhenReady()
	while not finished and not SpawnReadiness.isReady() do
		RunService.Heartbeat:Wait()
	end
	cleanup()
end

table.insert(
	connections,
	UserInputService.InputBegan:Connect(function(input)
		local kind = input.UserInputType
		if skipRequested or (kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch) then
			return
		end
		skipRequested = true
		if view and not SpawnReadiness.isReady() then
			view.waiting(true)
		end
		task.spawn(closeWhenReady)
	end)
)

local completion = table.pack(xpcall(function()
	local View = require(script.View)
	local Preloader = require(script.AssetPreloader)
	local Config = require(script.Config)
	local function cancelled(): boolean
		return finished or skipRequested
	end
	local packages = Preloader.waitFor(game:GetService("ReplicatedStorage"), "Packages", cancelled)
	if not packages then
		return
	end
	view = View.mount(screen)
	if finished then
		view.destroy()
		return
	end
	cover.BackgroundTransparency = 1
	if skipRequested then
		view.waiting(true)
	end
	while not game:IsLoaded() and not cancelled() do
		RunService.Heartbeat:Wait()
	end
	if cancelled() then
		return
	end
	local entries = Preloader.collect(player, Config.Icon, cancelled)
	if cancelled() then
		Preloader.destroy(entries)
		return
	end
	local result = Preloader.load(entries, cancelled, function(loaded: number, total: number, failed: number)
		if not cancelled() then
			view.update(loaded, total, failed)
		end
	end)
	if cancelled() then
		return
	end
	if result.failed > 0 or result.pending > 0 then
		warn(string.format("[Loading] %d loaded, %d failed, %d pending", result.loaded, result.failed, result.pending))
	end
	-- The screen also waits for the avatar to stand on its real floor.
	if not SpawnReadiness.isReady() then
		view.waiting()
		while not SpawnReadiness.isReady() and not cancelled() do
			RunService.Heartbeat:Wait()
		end
	end
	if cancelled() then
		return
	end
	-- Only the completed screen fades; progress never advances on a timer.
	view.finish()
	task.wait(Config.FadeTime)
end, debug.traceback))
local ok, failure = completion[1], completion[2]
if not skipRequested then
	closeWhenReady()
end
if not ok then
	warn("Loading screen ended safely: " .. tostring(failure))
end
