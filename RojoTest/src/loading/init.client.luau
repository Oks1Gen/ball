local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
player:SetAttribute("MapIntroActive", true)

local playerGui = player:WaitForChild("PlayerGui")
local screen = Instance.new("ScreenGui")
screen.Name = "MapIntro"
screen.IgnoreGuiInset = true
screen.ResetOnSpawn = false
screen.DisplayOrder = 10000
screen.Parent = playerGui

local hidden, connections, coreStates = {}, {}, {}
local function hideGui(gui)
    if not gui:IsA("ScreenGui") or gui == screen or hidden[gui] ~= nil then return end
    hidden[gui] = gui.Enabled
    gui.Enabled = false
    table.insert(connections, gui:GetPropertyChangedSignal("Enabled"):Connect(function()
        if gui.Enabled then hidden[gui] = true gui.Enabled = false end
    end))
end
for _, gui in playerGui:GetChildren() do hideGui(gui) end
table.insert(connections, playerGui.ChildAdded:Connect(hideGui))
for _, kind in {Enum.CoreGuiType.Backpack, Enum.CoreGuiType.PlayerList, Enum.CoreGuiType.Chat, Enum.CoreGuiType.Health} do
    pcall(function() coreStates[kind] = StarterGui:GetCoreGuiEnabled(kind) StarterGui:SetCoreGuiEnabled(kind, false) end)
end
ContextActionService:BindActionAtPriority("MapIntroMovement", function() return Enum.ContextActionResult.Sink end,
    false, 3000, Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward,
    Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump)

local cameraState, root, cancelled, finished, streamingRemote
local function cleanup()
    if finished then return end
    finished = true
    RunService:UnbindFromRenderStep("MapIntroCamera")
    ContextActionService:UnbindAction("MapIntroMovement")
    for _, connection in connections do connection:Disconnect() end
    for gui, enabled in hidden do if gui.Parent then gui.Enabled = enabled end end
    for kind, enabled in coreStates do pcall(function() StarterGui:SetCoreGuiEnabled(kind, enabled) end) end
    local camera = workspace.CurrentCamera
    if camera and cameraState then
        camera.CameraType = cameraState.Type
        camera.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid") or cameraState.Subject
        camera.FieldOfView = cameraState.FOV
        camera.CFrame = cameraState.CFrame
    end
    player:SetAttribute("MapIntroActive", false)
    if streamingRemote then streamingRemote:FireServer("Finish") end
    if root then root:unmount() end
    screen:Destroy()
end

local ok, failure = xpcall(function()
    local packages = ReplicatedStorage:WaitForChild("Packages", 30)
    assert(packages, "UI packages unavailable")
    local React = require(packages:WaitForChild("React"))
    local ReactRoblox = require(packages:WaitForChild("ReactRoblox"))
    local Ripple = require(packages:WaitForChild("Ripple"))
    local e = React.createElement
    local fade, setFade = React.createBinding(1)
    local progress, setProgress = React.createBinding(0)
    local caption, setCaption = React.createBinding("Preparing your adventure…")
    local phase, setPhase = React.createBinding("LOADING")
    local spring = Ripple.createSpring(1, {frequency = 7, dampingRatio = 1, start = true})
    local disconnect = spring:onChange(setFade)
    table.insert(connections, {Disconnect = function() disconnect() spring:destroy() end})
    local function label(text, position, size, textSize, color)
        return e("TextLabel", {BackgroundTransparency = 1, Text = text, Position = position, Size = size,
            Font = Enum.Font.FredokaOne, TextSize = textSize, TextColor3 = color or Color3.new(1, 1, 1),
            TextWrapped = true}, {Stroke = e("UIStroke", {Color = Color3.fromRGB(12, 20, 39), Thickness = 2})})
    end
    root = ReactRoblox.createRoot(screen)
    root:render(e("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, {
        Blocker = e("TextButton", {Size = UDim2.fromScale(1, 1), Text = "", BackgroundTransparency = 1, Modal = true, AutoButtonColor = false}),
        Fade = e("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(12, 20, 39), BackgroundTransparency = fade:map(function(v) return 1 - math.clamp(v, 0, 1) end), BorderSizePixel = 0}),
        Top = e("Frame", {Size = UDim2.new(1, 0, 0.075, 0), BackgroundColor3 = Color3.fromRGB(12, 20, 39), BorderSizePixel = 0}),
        Bottom = e("Frame", {Position = UDim2.fromScale(0, 0.82), Size = UDim2.fromScale(1, 0.18), BackgroundColor3 = Color3.fromRGB(12, 20, 39), BorderSizePixel = 0}, {
            Heading = label(phase, UDim2.fromScale(0.15, 0.05), UDim2.fromScale(0.7, 0.25), 18, Color3.fromRGB(255, 221, 83)),
            Caption = label(caption, UDim2.fromScale(0.1, 0.30), UDim2.fromScale(0.8, 0.3), 23),
            Track = e("Frame", {Position = UDim2.fromScale(0.2, 0.76), Size = UDim2.fromScale(0.6, 0.035), BackgroundColor3 = Color3.fromRGB(39, 62, 87), BorderSizePixel = 0}, {
                Fill = e("Frame", {Size = progress:map(function(v) return UDim2.fromScale(v, 1) end), BackgroundColor3 = Color3.fromRGB(255, 221, 83), BorderSizePixel = 0}),
            }),
        }),
        Skip = e("TextButton", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0.09, 0), Size = UDim2.fromOffset(136, 44),
            Text = "Skip  ›", Font = Enum.Font.FredokaOne, TextSize = 21, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Color3.fromRGB(24, 43, 65),
            [React.Event.Activated] = function() cancelled = true end}, {
                Corner = e("UICorner", {CornerRadius = UDim.new(0, 12)}),
                Stroke = e("UIStroke", {Color = Color3.fromRGB(12, 20, 39), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}),
            }),
    }))
    RunService.Heartbeat:Wait()
    game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()
    streamingRemote = ReplicatedStorage:WaitForChild("MapIntroStreaming", 20)
    assert(streamingRemote, "Streaming service unavailable")
    streamingRemote:FireServer("Prepare")
    local map = workspace:WaitForChild("ProgressionMap", 30)
    assert(map, "Map unavailable")
    local shots = {{Name = "Lobby", A = Vector3.new(95, 110, 185), B = Vector3.new(80, 100, 225), TA = Vector3.new(30, 28, 240), TB = Vector3.new(15, 28, 245), Duration = 1.43}}
    for i, name in {"Palm Beach", "Desert Dunes", "Candy Beach", "Violet Valley", "Ember River", "Moonlight", "Frozen Falls", "Rainbow Paradise"} do
        local z = -10.399963 - (i - 1) * 270
        table.insert(shots, {Name = name, A = Vector3.new(135, 105, z + 45), B = Vector3.new(115, 95, z + 5),
            TA = Vector3.new(30, 28, z - 15), TB = Vector3.new(20, 29, z - 45), Duration = 1.43})
    end
    table.insert(shots, {Name = "Final Portal", A = Vector3.new(95, 92, -1845), B = Vector3.new(48, 78, -1895),
        TA = Vector3.new(48, 73, -2029), TB = Vector3.new(48, 73, -2029), Duration = 2.13})
    -- Prefetch the remote biomes before flying there. Each request is bounded.
    local ready = 0
    for _, shot in shots do
        task.spawn(function()
            if workspace.StreamingEnabled then pcall(function() player:RequestStreamAroundAsync(shot.TB, 6) end) end
            ready += 1
        end)
    end
    local waitStarted = os.clock()
    local function routeReady()
        local world = map:FindFirstChild("SkippingWorld")
        return world and world:FindFirstChild("Water_8") and world:FindFirstChild("SakuraGatewayFrame", true)
    end
    while (ready < #shots or not routeReady() or os.clock() - waitStarted < 1) and os.clock() - waitStarted < 12 and not cancelled do
        setProgress(ready / #shots)
        RunService.Heartbeat:Wait()
    end
    if cancelled or not routeReady() then return end
    local camera = workspace.CurrentCamera
    cameraState = {Type = camera.CameraType, Subject = camera.CameraSubject, FOV = camera.FieldOfView, CFrame = camera.CFrame}
    -- Hide only world captions; restore their exact local state afterwards.
    for _, node in map:GetDescendants() do
        if node:IsA("BillboardGui") and node.Enabled then
            node.Enabled = false
            table.insert(connections, {Disconnect = function() if node.Parent then node.Enabled = true end end})
        end
    end
    local elapsed = 0
    setPhase("EXPLORE THE WORLD")
    RunService:BindToRenderStep("MapIntroCamera", Enum.RenderPriority.Camera.Value + 10, function(dt)
        elapsed = math.min(15, elapsed + dt)
        local localTime, index = elapsed, 1
        while index < #shots and localTime > shots[index].Duration do
            localTime -= shots[index].Duration
            index += 1
        end
        local shot = shots[index]
        local t = math.clamp(localTime / shot.Duration, 0, 1)
        local eased = t * t * (3 - 2 * t)
        camera.CameraType = Enum.CameraType.Scriptable
        camera.FieldOfView = 58
        camera.CFrame = CFrame.lookAt(shot.A:Lerp(shot.B, eased), shot.TA:Lerp(shot.TB, eased))
        camera.Focus = CFrame.new(shot.TA:Lerp(shot.TB, eased))
        setProgress(elapsed / 15)
        if caption:getValue() ~= shot.Name then setCaption(shot.Name) end
        -- Mask the edits instead of racing the camera over 2,000 studs.
        local opacity = math.max(1 - localTime / 0.14, 1 - (shot.Duration - localTime) / 0.14, 0)
        setFade(math.clamp(opacity, 0, 1))
    end)
    while elapsed < 15 and not cancelled do RunService.Heartbeat:Wait() end
    RunService:UnbindFromRenderStep("MapIntroCamera")
    spring:setPosition(1)
    setFade(1)
    -- Camera and controls are restored before revealing the character.
    camera.CameraType = cameraState.Type
    camera.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid") or cameraState.Subject
    camera.FieldOfView = cameraState.FOV
    camera.CFrame = cameraState.CFrame
    spring:setGoal(0)
    task.wait(0.35)
end, debug.traceback)
cleanup()
if not ok then warn("Map intro ended safely: " .. tostring(failure)) end
