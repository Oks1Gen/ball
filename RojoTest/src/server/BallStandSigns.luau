--!strict
-- Reference-style ball captions. Ownership is rendered per player on the client.
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local BallVisuals = require(game.ReplicatedStorage.Shared.BallVisuals)
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
	-- Identical cards and clearance on both tiers; no hidden per-row offset.
	gui.Size = UDim2.fromScale(4.8, 2.5)
	gui.StudsOffsetWorldSpace = Vector3.zero
	local status = label(
		gui,
		"Status",
		0,
		0.23,
		if item.cost == 0 then Color3.fromRGB(55, 255, 35) else Color3.fromRGB(255, 44, 44)
	)
	status.Text = if item.cost == 0 then "UNLOCKED" else "LOCKED"
	local power = label(gui, "Power", 0.29, 0.32, Color3.fromRGB(255, 239, 215))
	power.Text = tostring(item.power) .. "x Skill"
	local price = label(gui, "Price", 0.67, 0.30, Color3.fromRGB(255, 225, 20))
	price.Text = Config.format(item.cost) .. " Wins"
	gui:SetAttribute("BallId", item.id)
	gui:SetAttribute("BallName", item.name)
	gui:AddTag("BallStandSign")
end

-- Refresh linked captions without rebuilding models, pedestals or purchase points.
function Signs.apply(map: Instance): number
	local world = Refs.course(map)
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
		if anchor and anchor:IsDescendantOf(map) and gui and item then
			Signs.render(gui, item)
			active[anchor] = true
			count += 1
		end
	end
	local shop = Refs.balls(map)
	local displays = shop and shop:FindFirstChild("Displays")
	if displays then
		for _, display in displays:GetChildren() do
			local ball, top = display:FindFirstChild("Ball"), display:FindFirstChild("DisplayTop")
			local anchor = display:FindFirstChild("LabelAnchor")
			local localLabel = ball and ball:GetAttribute("DisplayLabelLocal")
			if
				ball
				and ball:IsA("Model")
				and top
				and top:IsA("BasePart")
				and anchor
				and anchor:IsA("BasePart")
				and typeof(localLabel) == "Vector3"
			then
				local base = BallVisuals.displayOrigin(ball)
				if not base then
					continue
				end
				-- Yaw leaves these vertical extents unchanged, including rings/spikes.
				local pivot = ball:GetPivot()
				local highest = -math.huge
				for _, part in ball:GetDescendants() do
					if part:IsA("BasePart") and part.Transparency < 1 then
						local cf = base * pivot:ToObjectSpace(part.CFrame)
						local h = part.Size / 2
						local extent = math.abs(cf.RightVector.Y) * h.X
							+ math.abs(cf.UpVector.Y) * h.Y
							+ math.abs(cf.LookVector.Y) * h.Z
						highest = math.max(highest, cf.Position.Y + extent)
					end
				end
				local gui = anchor:FindFirstChildOfClass("BillboardGui")
				if not gui or highest == -math.huge then
					continue
				end
				local position = Vector3.new(base.Position.X, highest + 3 + gui.Size.Y.Scale / 2, base.Position.Z)
				local aligned = top.CFrame:PointToObjectSpace(position)
				ball:SetAttribute("DisplayLabelLocal", aligned)
				ball:SetAttribute("DisplayLabelBase", position)
				ball:SetAttribute("DisplayLabelGap", 3)
				ball:SetAttribute("DisplayLabelHeight", gui.Size.Y.Scale)
				anchor.Position = position
			end
		end
	end
	for _, node in map:GetDescendants() do
		local parent = node.Parent
		if node:IsA("BillboardGui") and node:HasTag("BallStandSign") and parent and not active[parent] then
			node.Enabled = false
			node:RemoveTag("BallStandSign")
		end
	end
	return count
end

return Signs
