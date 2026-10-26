--!strict
-- Reference-style ball captions. Ownership is rendered per player on the client.
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Signs = {}

local function label(gui: BillboardGui, name: string, y: number, height: number, color: Color3): TextLabel
	local old = gui:FindFirstChild(name)
	local text = if old and old:IsA("TextLabel") then old else Instance.new("TextLabel")
	text.Name = name
	text.Position = UDim2.fromScale(0, y)
	text.Size = UDim2.fromScale(1, height)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBlack
	text.TextScaled = true
	text.TextStrokeTransparency = 1
	text.TextColor3 = color
	text.Visible = true
	text.Parent = gui
	if not text:FindFirstChildOfClass("UIStroke") then
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(7, 8, 11)
		stroke.Thickness = 2
		stroke.Parent = text
	end
	return text
end

function Signs.render(gui: BillboardGui, item: any)
	for _, node in gui:GetChildren() do
		if node:IsA("TextLabel") and node.Name ~= "Status" and node.Name ~= "Power" and node.Name ~= "Price" then
			node.Visible = false
		end
	end
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.Active = false
	gui.Enabled = true
	local status = label(
		gui,
		"Status",
		0,
		0.25,
		if item.cost == 0 then Color3.fromRGB(55, 255, 35) else Color3.fromRGB(255, 44, 44)
	)
	status.Text = if item.cost == 0 then "UNLOCKED" else "LOCKED"
	local power = label(gui, "Power", 0.27, 0.38, Color3.fromRGB(255, 239, 215))
	power.Text = tostring(item.power) .. "x Skill"
	local price = label(gui, "Price", 0.69, 0.31, Color3.fromRGB(255, 225, 20))
	price.Text = Config.format(item.cost) .. " Wins"
	gui:SetAttribute("BallId", item.id)
	gui:SetAttribute("BallName", item.name)
	gui:AddTag("BallStandSign")
end

-- Refresh only existing linked captions in Edit; do not reposition models,
-- anchors, prompts or the authored stand by rerunning the placement routine.
function Signs.apply(map: Instance): number
	local world = map:FindFirstChild("SkippingWorld")
	if not world then
		return 0
	end
	local count = 0
	local active: { [Instance]: boolean } = {}
	for _, model in game:GetService("CollectionService"):GetTagged("BallStandPreview") do
		if not model:IsDescendantOf(workspace) then
			continue
		end
		local link = model:FindFirstChild("DisplayLabel")
		local anchor = if link and link:IsA("ObjectValue") then link.Value else nil
		local gui = anchor and anchor:FindFirstChildOfClass("BillboardGui")
		local item = Config.find(Config.Stones, model:GetAttribute("BallId"))
		if anchor and anchor:IsDescendantOf(world) and gui and item then
			Signs.render(gui, item)
			active[anchor] = true
			count += 1
		end
	end
	for _, node in world:GetDescendants() do
		local parent = node.Parent
		if node:IsA("BillboardGui") and node:HasTag("BallStandSign") and parent and not active[parent] then
			node.Enabled = false
			node:RemoveTag("BallStandSign")
		end
	end
	return count
end

return Signs
