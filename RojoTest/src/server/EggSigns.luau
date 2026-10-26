--!strict
-- Two-line reference-style captions above the existing eggs. Prices are gameplay data.
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local UIAssets = require(game.StarterPlayer.StarterPlayerScripts.Client.UIAssets)
local Signs = {}
local HEIGHT = 4.2
local C = Color3.fromRGB
local TITLE_COLORS = { Common = C(220, 233, 229), Uncommon = C(46, 255, 35), Rare = C(0, 210, 255) }

local function text(parent: Instance, name: string): TextLabel
	local old = parent:FindFirstChild(name)
	local label = if old and old:IsA("TextLabel") then old else Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.TextStrokeTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = parent
	if not label:FindFirstChildOfClass("UIStroke") then
		local stroke = Instance.new("UIStroke")
		stroke.Color = C(7, 8, 11)
		stroke.Thickness = 2.5
		stroke.Parent = label
	end
	return label
end

local function caption(
	parent: Instance,
	center: Vector3,
	topY: number,
	title: string,
	price: string,
	currency: string,
	id: string
)
	local old = parent:FindFirstChild("EggSignAnchor")
	local anchor = if old and old:IsA("Part") then old else Instance.new("Part")
	anchor.Name = "EggSignAnchor"
	anchor.Anchored = true
	anchor.Transparency = 1
	anchor.CanCollide, anchor.CanTouch, anchor.CanQuery = false, false, false
	anchor.CastShadow = false
	anchor.Size = Vector3.one * 0.1
	anchor.Position = Vector3.new(center.X, topY + HEIGHT / 2 + 1, center.Z)
	anchor.Parent = parent
	local oldGui = anchor:FindFirstChild("EggSign")
	local gui = if oldGui and oldGui:IsA("BillboardGui") then oldGui else Instance.new("BillboardGui")
	gui.Name = "EggSign"
	gui.Adornee = anchor
	gui.Size = UDim2.fromScale(if id == "AdminEgg" then 20 else 16, HEIGHT)
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.MaxDistance = 180
	gui.Active = false
	gui.Enabled = true
	gui.Parent = anchor
	local heading = text(gui, "Title")
	heading.Size = UDim2.fromScale(1, 0.5)
	heading.Text = title
	heading.TextColor3 = TITLE_COLORS[id] or Color3.new(1, 1, 1)
	if id == "Rainbow" or id == "AdminEgg" then
		local existing = heading:FindFirstChildOfClass("UIGradient")
		local gradient = existing or Instance.new("UIGradient")
		gradient.Color = if id == "Rainbow"
			then ColorSequence.new({
				ColorSequenceKeypoint.new(0, C(220, 38, 255)),
				ColorSequenceKeypoint.new(0.2, C(65, 116, 255)),
				ColorSequenceKeypoint.new(0.4, C(0, 240, 227)),
				ColorSequenceKeypoint.new(0.6, C(95, 255, 25)),
				ColorSequenceKeypoint.new(0.8, C(255, 224, 12)),
				ColorSequenceKeypoint.new(1, C(255, 71, 22)),
			})
			else ColorSequence.new(C(255, 219, 60), C(255, 84, 31))
		gradient.Parent = heading
	end
	local oldRow = gui:FindFirstChild("PriceRow")
	local row = if oldRow and oldRow:IsA("Frame") then oldRow else Instance.new("Frame")
	row.Name = "PriceRow"
	row.BackgroundTransparency = 1
	row.Position = UDim2.fromScale(0, 0.56)
	row.Size = UDim2.fromScale(1, 0.44)
	row.Parent = gui
	if not row:FindFirstChildOfClass("UIListLayout") then
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0.02, 0)
		layout.Parent = row
	end
	local oldIcon = row:FindFirstChild("Currency")
	local icon = if oldIcon and oldIcon:IsA("ImageLabel") then oldIcon else Instance.new("ImageLabel")
	icon.Name = "Currency"
	icon.Size = UDim2.fromScale(0.12, 0.9)
	icon.BackgroundTransparency = 1
	icon.LayoutOrder = 1
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Image = if currency == "Wins" then UIAssets.Images.Wins else UIAssets.Images.Robux
	icon.Parent = row
	local amount = text(row, "Amount")
	amount.Size = UDim2.fromScale(if currency == "Wins" then 0.5 else 0.25, 1)
	amount.LayoutOrder = 2
	amount.Text = price
	amount.TextColor3 = if currency == "Wins" then C(255, 225, 20) else C(101, 255, 33)
	gui:SetAttribute("EggId", id)
	gui:SetAttribute("Currency", currency)
end

function Signs.apply(map: Instance, settings: any?)
	local config = settings or Config
	local world = map:FindFirstChild("SkippingWorld")
	if not world then
		return
	end
	local worldFactor = if map.Name == "World2" then 10 else 1
	for _, egg in config.Eggs do
		local stand = world:FindFirstChild("Egg_" .. egg.id)
		local shell = stand and stand:FindFirstChild("EggShell")
		if not stand or not shell or not shell:IsA("BasePart") then
			continue
		end
		local center, size = shell.CFrame, shell.Size
		local visual = stand:FindFirstChild("ImportedVisual")
		if visual and visual:IsA("Model") then
			center, size = visual:GetBoundingBox()
		end
		local legacy = stand:FindFirstChild("LabelAnchor")
		if legacy then
			for _, gui in legacy:GetChildren() do
				if gui:IsA("BillboardGui") then
					gui.Enabled = false
				end
			end
		end
		local title = if egg.id == "Rainbow" then egg.name else string.upper((egg.name:gsub(" Egg$", "")))
		caption(
			stand,
			shell.Position,
			center.Position.Y + size.Y / 2,
			title,
			config.format(egg.cost * worldFactor) .. " Wins",
			"Wins",
			egg.id
		)
	end
	local admin = world:FindFirstChild("HackedAdminEgg")
	local visual = world:FindFirstChild("VolcanicEggFallback")
	if admin and admin:IsA("BasePart") and visual and visual:IsA("BasePart") then
		for _, anchor in world:GetChildren() do
			if anchor.Name == "LabelAnchor" then
				local gui = anchor:FindFirstChildOfClass("BillboardGui")
				local label = gui and gui:FindFirstChildOfClass("TextLabel")
				if
					gui
					and label
					and (
						label.Text:find("Volcanic Inferno Egg", 1, true)
						or label.Text:find("Hacked Admin Egg", 1, true)
						or (
							label.Text:find("BEST IN GAME", 1, true)
							and anchor:IsA("BasePart")
							and (Vector3.new(anchor.Position.X, 0, anchor.Position.Z) - Vector3.new(
									admin.Position.X,
									0,
									admin.Position.Z
								)).Magnitude
								< 0.5
						)
					)
				then
					gui.Enabled = false
				end
			end
		end
		local holder: Instance = world:FindFirstChild("AdminEggCaption") or Instance.new("Folder")
		holder.Name = "AdminEggCaption"
		holder.Parent = world
		caption(
			holder,
			admin.Position,
			visual.Position.Y + visual.Size.Y / 2,
			"Volcanic Inferno Egg",
			config.format(config.Products.AdminEgg.price),
			"Robux",
			"AdminEgg"
		)
	end
end

return Signs
