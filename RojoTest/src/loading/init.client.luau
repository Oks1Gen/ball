--!strict
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local LoadingConfig = require(script.Config)
local player = Players.LocalPlayer
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
table.insert(connections, cover.Activated:Connect(cleanup))

local ok, failure = xpcall(function()
	local View = require(script.View)
	local Preloader = require(script.AssetPreloader)
	local Config = require(script.Config)
	local function cancelled(): boolean
		return finished
	end
	local packages = Preloader.waitFor(game:GetService("ReplicatedStorage"), "Packages", cancelled)
	if not packages then
		return
	end
	view = View.mount(screen, cleanup)
	if finished then
		view.destroy()
		return
	end
	cover.BackgroundTransparency = 1
	while not game:IsLoaded() and not finished do
		RunService.Heartbeat:Wait()
	end
	if finished then
		return
	end
	local entries = Preloader.collect(player, Config.Icon, cancelled)
	if finished then
		Preloader.destroy(entries)
		return
	end
	local result = Preloader.load(entries, cancelled, function(loaded: number, total: number, failed: number)
		if not finished then
			view.update(loaded, total, failed)
		end
	end)
	if finished then
		return
	end
	if result.failed > 0 or result.pending > 0 then
		warn(string.format("[Loading] %d loaded, %d failed, %d pending", result.loaded, result.failed, result.pending))
	end
	-- Only the completed screen fades; progress never advances on a timer.
	view.finish()
	task.wait(Config.FadeTime)
end, debug.traceback)
cleanup()
if not ok then
	warn("Loading screen ended safely: " .. tostring(failure))
end
