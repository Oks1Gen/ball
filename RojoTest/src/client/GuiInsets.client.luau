local Players = game:GetService("Players")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local function configure(instance)
    if instance:IsA("ScreenGui") then instance.IgnoreGuiInset = true end
end
playerGui.DescendantAdded:Connect(configure)
for _, instance in playerGui:GetDescendants() do configure(instance) end
