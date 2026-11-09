--!strict
-- Two-line captions above the existing eggs.
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local WorldRefs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Signs = {}
local HEIGHT = 4.2 -- authored studs; the sign scales with the world
local C = Color3.fromRGB
local CAPTIONS = {
	Common = { title = "Forest Egg", rarity = "Common", color = C(220, 233, 229) },
	Uncommon = { title = "Frost Egg", rarity = "Uncommon", color = C(46, 255, 35) },
	SolarCrown = { title = Config.SolarEgg.name, rarity = "Legendary", color = Config.SolarEgg.color },
	Rare = { title = "Magma Egg", rarity = "Rare", color = C(0, 210, 255) },
	Rainbow = { title = "Void Egg", rarity = "Epic", color = C(206, 113, 255) },
}

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

local function caption(parent: Instance, center: Vector3, topY: number, id: string, scale: number)
	local copy = CAPTIONS[id]
	if not copy then
		return
	end
	local height = HEIGHT * scale
	local old = parent:FindFirstChild("EggSignAnchor")
	local anchor = if old and old:IsA("Part") then old else Instance.new("Part")
	anchor.Name = "EggSignAnchor"
	anchor.Anchored = true
	anchor.Transparency = 1
	anchor.CanCollide, anchor.CanTouch, anchor.CanQuery = false, false, false
	anchor.CastShadow = false
	anchor.Size = Vector3.one * 0.1
	anchor.Position = Vector3.new(center.X, topY + height / 2 + scale, center.Z)
	anchor.Parent = parent
	local oldGui = anchor:FindFirstChild("EggSign")
	local gui = if oldGui and oldGui:IsA("BillboardGui") then oldGui else Instance.new("BillboardGui")
	gui.Name = "EggSign"
	gui.Adornee = anchor
	gui.Size = UDim2.fromScale((if id == "SolarCrown" then 20 else 16) * scale, height)
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.MaxDistance = 180
	gui.Active = false
	gui.Enabled = true
	gui.Parent = anchor
	local heading = text(gui, "Title")
	heading.Size = UDim2.fromScale(1, 0.5)
	heading.Text = copy.title
	heading.TextColor3 = copy.color
	local gradient = heading:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient:Destroy()
	end
	local oldRow = gui:FindFirstChild("PriceRow")
	if oldRow then
		oldRow:Destroy()
	end
	local rarity = text(gui, "Rarity")
	rarity.Position = UDim2.fromScale(0, 0.5)
	rarity.Size = UDim2.fromScale(1, 0.375)
	rarity.Text = copy.rarity
	rarity.TextColor3 = copy.color
	gui:SetAttribute("EggId", id)
	gui:SetAttribute("Currency", nil)
end

function Signs.apply(map: Instance, settings: any?)
	local config = settings or Config
	local world = map:FindFirstChild("SkippingWorld")
	if not world then
		return
	end
	local scale = Scale.factor(map)
	for _, egg in config.BaseEggs do
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
		caption(stand, shell.Position, center.Position.Y + size.Y / 2, egg.id, scale)
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
		caption(holder, admin.Position, visual.Position.Y + visual.Size.Y / 2, "SolarCrown", scale)
	end
end

function Signs.applySolar(world: Instance)
	local egg = Config.SolarEgg
	local stand, part, visual = WorldRefs.eggStation(world, egg.id)
	if not stand or not part then
		return
	end
	local center, size = part.CFrame, part.Size
	if visual then
		center, size = visual:GetBoundingBox()
	end
	local anchor = stand:FindFirstChild("EggSignAnchor", true)
	caption(anchor and anchor.Parent or stand, center.Position, center.Y + size.Y / 2, egg.id, Scale.factor(world))
	stand:SetAttribute("EggId", egg.id)
	local prompt = part:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		prompt.ActionText = "Hatch"
		prompt.ObjectText = egg.name
	end
end

return Signs
