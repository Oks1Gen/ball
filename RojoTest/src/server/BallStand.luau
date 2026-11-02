--!strict
local Construction = require(script.Parent.ConstructionTypes)
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.GameConfig)
local Visuals = require(Shared.BallVisuals)
local Scale = require(Shared.WorldScale)
local Tags = game:GetService("CollectionService")
local Signs = require(script.Parent.BallStandSigns)
local Stand = {}
local DISPLAY_FILL = 0.405
-- Rest height above the pad: the standPose bob (0.45) plus clear air at its lowest point.
local BOB = 0.45

function Stand.apply(map: Construction.World)
	require(script.Parent.BallStandStyle).apply(map)
	local stand = assert(map:FindFirstChild("EmptyItemStand")) :: Model
	local displayScale = ((stand:GetAttribute("BallDisplayScale") :: number?) or 1) * Scale.factor(map)
	local root = assert(map:FindFirstChild("SkippingWorld"))
	local imported = map.Name == "World1" and workspace:FindFirstChild("AllBalls_NoTextures")
	local container = imported or stand:FindFirstChild("DisplayBalls")
	if not container then
		container = Instance.new("Folder")
		container.Name = "DisplayBalls"
		container.Parent = stand
	end
	local anchors: { [number]: BasePart } = {}
	for _, anchor in root:GetChildren() do
		if
			anchor:IsA("BasePart")
			and anchor:FindFirstChildWhichIsA("BillboardGui")
			and (anchor.Name == "LabelAnchor" or anchor:GetAttribute("BallDisplayLabelSlot"))
		then
			for slot = 1, 10 do
				local top = stand:FindFirstChild("DisplayTop" .. slot) :: BasePart?
				if
					top
					and math.abs(anchor.Position.X - top.Position.X) < 0.1
					and math.abs(anchor.Position.Z - top.Position.Z) < 0.1
				then
					anchors[slot] = anchor
				end
			end
		end
	end
	for _, item in Config.Stones do
		local top = assert(stand:FindFirstChild("DisplayTop" .. item.displaySlot)) :: BasePart
		-- The ball body fills under half of its pad, like the items on the reference stands.
		local diameter = DISPLAY_FILL * math.min(top.Size.X, top.Size.Z)
		local model
		for _, candidate in container:GetChildren() do
			if
				candidate:GetAttribute("DisplaySlot") == item.displaySlot
				or candidate:GetAttribute("BallId") == item.id
			then
				model = candidate
				break
			end
		end
		-- Rebuild when the size or the template fit rule changed since the model was placed.
		local fit = Visuals.fitKey(item.id)
		if model and (model:GetAttribute("DisplayDiameter") ~= diameter or model:GetAttribute("DisplayFit") ~= fit) then
			model:Destroy()
			model = nil
		end
		if not model then
			model = Visuals.create(item.id, diameter)
			-- Face the purchase side of the pad, where players walk up.
			local front = top.CFrame.RightVector
			model:PivotTo(CFrame.lookAt(Vector3.zero, Vector3.new(front.X, 0, front.Z)))
			model:SetAttribute("DisplayDiameter", diameter)
			model:SetAttribute("DisplayFit", fit)
			model.Parent = container
		end
		-- Recompute placement when the stand moves, including the animation origin.
		do
			local cf, size = model:GetBoundingBox()
			model.WorldPivot = cf
			-- Float above the pad; even at the bottom of the bob the ball keeps visible air below it.
			local center = Vector3.new(
				top.Position.X,
				top.Position.Y + top.Size.Y / 2 + size.Y / 2 + BOB + 0.75 * displayScale,
				top.Position.Z
			)
			model:PivotTo(model:GetPivot() + (center - cf.Position))
			model:SetAttribute("DisplayBasePivot", model:GetPivot())
		end
		model:SetAttribute("BallId", item.id)
		model:SetAttribute("DisplaySlot", item.displaySlot)
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
			end
		end
		local cf, size = model:GetBoundingBox()
		local anchor = anchors[item.displaySlot]
		if not anchor then
			local created = Instance.new("Part")
			created.Name = "BallLabelAnchor" .. item.displaySlot
			created.Size = Vector3.new(0.1, 0.1, 0.1)
			created.Transparency = 1
			created.Anchored = true
			created.CanCollide = false
			created.CanTouch = false
			created.CanQuery = false
			created.Parent = root
			local gui = Instance.new("BillboardGui")
			gui.Name = "BallLabel"
			gui.MaxDistance = 450
			gui.LightInfluence = 0
			gui.Parent = created
			local title = Instance.new("TextLabel")
			title.Size = UDim2.fromScale(1, 1)
			title.BackgroundTransparency = 1
			title.Font = Enum.Font.GothamBlack
			title.TextScaled = true
			title.Parent = gui
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 2
			stroke.Color = Color3.fromRGB(20, 24, 40)
			stroke.Parent = title
			anchor = created
		end
		local labelAnchor = assert(anchor)
		local gui = assert(labelAnchor:FindFirstChildWhichIsA("BillboardGui"))
		anchors[item.displaySlot] = anchor
		gui.Size = UDim2.fromScale(12 * displayScale, 5.4 * displayScale)
		gui.Enabled = true
		Signs.render(gui, item)
		anchor.Position =
			Vector3.new(cf.Position.X, cf.Position.Y + size.Y / 2 + (1.6 + 2.7) * displayScale, cf.Position.Z)
		anchor:SetAttribute("BallDisplayLabelSlot", item.displaySlot)
		model:SetAttribute("DisplayLabelBase", anchor.Position)
		local link = model:FindFirstChild("DisplayLabel") or Instance.new("ObjectValue")
		link.Name = "DisplayLabel"
		link.Value = anchor
		link.Parent = model
		Tags:AddTag(model, "BallStandPreview")
		local promptAnchor = stand:FindFirstChild("BallPurchase" .. item.displaySlot) :: BasePart?
		if not promptAnchor then
			local created = Instance.new("Part")
			created.Name = "BallPurchase" .. item.displaySlot
			created.Size = Vector3.new(0.1, 0.1, 0.1)
			created.Transparency = 1
			created.Anchored = true
			created.CanCollide = false
			created.CanTouch = false
			created.CanQuery = false
			created.Parent = stand
			promptAnchor = created
		end
		local purchaseAnchor = assert(promptAnchor)
		-- Follow the display's facing when the authored stand is turned in Studio.
		purchaseAnchor.Position =
			top.CFrame:PointToWorldSpace(Vector3.new(top.Size.X / 2 + displayScale, 0.6 * displayScale, 0))
		local pp = purchaseAnchor:FindFirstChildWhichIsA("ProximityPrompt") or Instance.new("ProximityPrompt")
		pp.Name = "BallPurchasePrompt"
		pp.ObjectText = item.name
		pp.ActionText = "View ball"
		pp.MaxActivationDistance = 13
		pp.RequiresLineOfSight = false
		pp.HoldDuration = 0
		pp:SetAttribute("BallId", item.id)
		pp.Parent = purchaseAnchor
	end
	for _, part in root:GetChildren() do
		if part:IsA("BasePart") and part:GetAttribute("BallDisplayLabelSlot") then
			local slot = part:GetAttribute("BallDisplayLabelSlot") :: number?
			local gui = part:FindFirstChildWhichIsA("BillboardGui")
			if gui and slot and anchors[slot] ~= part then
				gui.Enabled = false
			end
		end
		if part:IsA("BasePart") and part.Name:match("^DisplayStone_") then
			part.Transparency = 1
			local prompt = part:FindFirstChildWhichIsA("ProximityPrompt")
			if prompt then
				prompt.Enabled = false
			end
		end
	end
	if container:IsA("Model") and not container.PrimaryPart then
		local bounds = container:GetBoundingBox()
		container.WorldPivot = bounds
	end
	return container
end

return Stand
