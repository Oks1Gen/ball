--!strict
-- Compact, non-interactive signs above the existing goals. Never rebuild a field.
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Goal = require(game.ReplicatedStorage.Shared.TrainingGoal)
local UIAssets = require(game.StarterPlayer.StarterPlayerScripts.Client.UIAssets)
local Signs = {}
local HEIGHT = 4.6

local function top(part: BasePart): number
	local cf, size = part.CFrame, part.Size
	return part.Position.Y
		+ (
				math.abs(cf.RightVector.Y) * size.X
				+ math.abs(cf.UpVector.Y) * size.Y
				+ math.abs(cf.LookVector.Y) * size.Z
			)
			/ 2
end

local function text(parent: Instance, name: string): TextLabel
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("TextLabel") then
		return existing
	end
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = Color3.fromRGB(12, 13, 19)
	label.TextStrokeTransparency = 0
	label.Parent = parent
	return label
end

function Signs.apply(map: Instance, definitions: any?)
	local lanes = definitions or Config.Lanes
	local zone = map:FindFirstChild("TrainingZone")
	if not zone then
		return
	end
	local skipping = map:FindFirstChild("SkippingWorld")
	for index, definition in lanes do
		local lane = zone:FindFirstChild("TrainingLane" .. index)
		local strip = lane and lane:FindFirstChild("TrainingStrip")
		if not lane or not strip or not strip:IsA("BasePart") then
			continue
		end
		-- Preserve the old authored anchors and labels, but stop rendering the
		-- three-line captions over the middle of the playable strip.
		for _, item in lane:GetDescendants() do
			if item:IsA("BillboardGui") and item.Parent and item.Parent.Name == "UIAnchor" then
				item.Enabled = false
			end
		end
		if skipping then
			for _, anchor in skipping:GetChildren() do
				if anchor:IsA("BasePart") and anchor.Name == "LabelAnchor" then
					if math.abs(anchor.Position.Z - strip.Position.Z) < 0.1 then
						for _, gui in anchor:GetChildren() do
							if gui:IsA("BillboardGui") then
								local caption = gui:FindFirstChildOfClass("TextLabel")
								if caption and caption.Text:match("^RB " .. definition.rebirths .. "\n") then
									gui.Enabled = false
								end
							end
						end
					end
				end
			end
		end
		local net = Goal.net(lane)
		local endpoint = lane:FindFirstChild("UIAnchor")
		local center = if net
			then net.Position
			elseif endpoint and endpoint:IsA("BasePart") then endpoint.Position
			else strip.Position
		local goalTop = if net then top(net) else top(strip) + 5.4
		local visual = lane:FindFirstChild("ImportedField")
		if visual then
			for _, part in visual:GetChildren() do
				if part:IsA("BasePart") and part.Name:find("Goal", 1, true) then
					goalTop = math.max(goalTop, top(part))
				end
			end
		end
		local existing = lane:FindFirstChild("GoalSignAnchor")
		local anchor = if existing and existing:IsA("Part") then existing else Instance.new("Part")
		anchor.Name = "GoalSignAnchor"
		anchor.Anchored = true
		anchor.Transparency = 1
		anchor.CanCollide, anchor.CanTouch, anchor.CanQuery = false, false, false
		anchor.CastShadow = false
		anchor.Size = Vector3.one * 0.1
		anchor.Position = Vector3.new(center.X, goalTop + HEIGHT / 2 + 0.9, center.Z)
		anchor.Parent = lane
		local previousGui = anchor:FindFirstChild("TrainingLaneSign")
		local gui = if previousGui and previousGui:IsA("BillboardGui")
			then previousGui
			else Instance.new("BillboardGui")
		gui.Name = "TrainingLaneSign"
		gui.Adornee = anchor
		gui.Size = UDim2.fromScale(9, HEIGHT)
		gui.StudsOffset = Vector3.zero
		gui.AlwaysOnTop = false
		gui.LightInfluence = 0
		gui.MaxDistance = 180
		gui.Active = false
		gui.Enabled = true
		gui.Parent = anchor
		local oldRow = gui:FindFirstChild("Requirement")
		local row = if oldRow and oldRow:IsA("Frame") then oldRow else Instance.new("Frame")
		row.Name = "Requirement"
		row.Position = UDim2.fromScale(0.06, 0.02)
		row.Size = UDim2.fromScale(0.88, 0.4)
		row.BackgroundTransparency = 0.06
		row.BackgroundColor3 = Color3.fromRGB(30, 14, 9)
		row.BorderSizePixel = 0
		row.Parent = gui
		if not row:FindFirstChildOfClass("UICorner") then
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = row
		end
		if not row:FindFirstChildOfClass("UIStroke") then
			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(7, 4, 3)
			stroke.Thickness = 2
			stroke.Parent = row
		end
		if not row:FindFirstChildOfClass("UIGradient") then
			local gradient = Instance.new("UIGradient")
			gradient.Rotation = 90
			gradient.Color = ColorSequence.new(Color3.fromRGB(255, 245, 232), Color3.fromRGB(125, 108, 97))
			gradient.Parent = row
		end
		if not row:FindFirstChildOfClass("UIListLayout") then
			local layout = Instance.new("UIListLayout")
			layout.FillDirection = Enum.FillDirection.Horizontal
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			layout.VerticalAlignment = Enum.VerticalAlignment.Center
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Padding = UDim.new(0.025, 0)
			layout.Parent = row
		end
		local oldIcon = row:FindFirstChild("RebirthIcon")
		local icon = if oldIcon and oldIcon:IsA("ImageLabel") then oldIcon else Instance.new("ImageLabel")
		icon.Name = "RebirthIcon"
		icon.BackgroundTransparency = 1
		icon.Size = UDim2.fromScale(0.2, 0.94)
		icon.LayoutOrder = 1
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Image = UIAssets.Images.Rebirth
		icon.Parent = row
		local requirement = text(row, "Count")
		requirement.Size = UDim2.fromScale(0.2, 1)
		requirement.LayoutOrder = 2
		requirement.TextColor3 = Color3.fromRGB(255, 239, 215)
		requirement.Text = tostring(definition.rebirths)
		local status = text(gui, "Status")
		status.Position = UDim2.fromScale(0, 0.46)
		status.Size = UDim2.fromScale(1, 0.2)
		-- Each client replaces the starter-lane Edit preview with its own locks.
		status.Text = if definition.rebirths == 0 then "UNLOCKED" else "LOCKED"
		status.TextColor3 = if definition.rebirths == 0
			then Color3.fromRGB(55, 255, 35)
			else Color3.fromRGB(255, 44, 44)
		local multiplier = text(gui, "Multiplier")
		multiplier.Position = UDim2.fromScale(0, 0.7)
		multiplier.Size = UDim2.fromScale(1, 0.3)
		multiplier.TextColor3 = Color3.fromRGB(255, 239, 215)
		multiplier.Text = tostring(definition.multiplier) .. "x SKILL"
		gui:SetAttribute("RequiredRebirths", definition.rebirths)
		gui:AddTag("TrainingLaneSign")
		lane:SetAttribute("SkillGain", nil)
		lane:SetAttribute("TrainingMultiplier", definition.multiplier)
		lane:SetAttribute("RequiredRebirths", definition.rebirths)
	end
end

return Signs
