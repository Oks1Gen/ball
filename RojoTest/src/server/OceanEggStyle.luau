--!strict
local Catalog = require(game.ReplicatedStorage.Shared.OceanEggCatalog)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local Cradle = require(script.Parent.OceanEggCradle)
local Style = {}
function Style.apply(world: any): number
	assert(world.Name == "World2", "Ocean eggs belong to World2")
	local storage = game:GetService("ServerStorage")
	local templates = storage:FindFirstChild("Assets")
	templates = templates and templates:FindFirstChild("Eggs")
	templates = templates and templates:FindFirstChild("Ocean")
	assert(templates and templates:GetAttribute("Status") == "Ready", "Ocean egg templates are not ready")
	local shop = world.Lobby.EggShop
	local stand = shop.EggStand
	local backups = storage:FindFirstChild("WorldBackups")
	if not backups then
		backups = Instance.new("Folder")
		backups.Name = "WorldBackups"
		backups.Parent = storage
	end
	if not backups:FindFirstChild("BeforeOceanEggs_20261105") then
		local copy = shop:Clone()
		copy.Name = "BeforeOceanEggs_20261105"
		copy.Parent = backups
	end
	local scale = Scale.relative(world)
	for _, entry in Catalog.entries do
		local station = shop[entry.station]
		local seat = stand[entry.seat].SeatCenter
		local anchor = station:FindFirstChild("EggShell") or station:FindFirstChild("InteractionAnchor")
		station:PivotTo(
			station:GetPivot()
				+ Vector3.new(seat.Position.X - anchor.Position.X, 0, seat.Position.Z - anchor.Position.Z)
		)
		local eggBottom = Cradle.apply(station, seat, scale)
		local name = if entry.id == "AdminEgg" then "Visual" else "ImportedVisual"
		local visual = station:FindFirstChild(name)
		if not visual or visual:GetAttribute("OceanEggTheme") ~= entry.theme then
			if visual then
				visual:Destroy()
			end
			visual = templates[entry.theme]:Clone()
			visual.Name = name
			visual.Parent = station
			visual:SetAttribute("OceanEggTheme", entry.theme)
			visual:SetAttribute("ElementalEggTheme", entry.theme)
		end
		local _, size = visual:GetBoundingBox()
		visual:ScaleTo(visual:GetScale() * 10 * scale / size.Y)
		visual:PivotTo(CFrame.new(seat.Position))
		local cf, bounds = visual:GetBoundingBox()
		visual:PivotTo(
			visual:GetPivot()
				+ Vector3.new(seat.Position.X - cf.X, eggBottom - cf.Y + bounds.Y / 2, seat.Position.Z - cf.Z)
		)
		visual:SetAttribute("DisplayEffectScale", scale)
		visual:AddTag("FloatingDisplayEgg")
		station:SetAttribute("OceanEggTheme", entry.theme)
		station:SetAttribute("DisplayName", entry.theme .. " Egg")
		local fallback = station:FindFirstChild("Fallback")
		if fallback then
			fallback.Transparency = 1
			fallback.CastShadow = false
		end
		local caption = station:FindFirstChild("EggSignAnchor", true)
		if not caption then
			caption = Instance.new("Part")
			caption.Name = "EggSignAnchor"
			caption.Size = Vector3.one * 0.1
			caption.Anchored = true
			caption.Transparency = 1
			caption.CanCollide = false
			caption.CanTouch = false
			caption.CanQuery = false
			caption.CastShadow = false
			caption.Parent = station
		end
		caption:SetAttribute("PartRole", "CaptionAnchor")
		caption:SetAttribute("Purpose", "Ocean egg name and rarity")
		caption.Position = Vector3.new(seat.Position.X, eggBottom + 13 * scale, seat.Position.Z)
		local gui = caption:FindFirstChild("EggSign") or Instance.new("BillboardGui")
		gui.Name = "EggSign"
		gui.Adornee = caption
		gui.Size = UDim2.fromScale(16 * scale, 4.2 * scale)
		gui.LightInfluence = 0
		gui.MaxDistance = 180
		gui.AlwaysOnTop = false
		gui.Parent = caption
		gui:SetAttribute("EggId", entry.id)
		for _, label in gui:GetChildren() do
			label:Destroy()
		end
		for i, value in { entry.theme .. " Egg", entry.rarity } do
			local label = Instance.new("TextLabel")
			label.Name = if i == 1 then "Title" else "Rarity"
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromScale(1, 0.5)
			label.Position = UDim2.fromScale(0, (i - 1) * 0.5)
			label.TextScaled = true
			label.Font = Enum.Font.GothamBlack
			label.Text = value
			label.TextColor3 = entry.color
			label.Parent = gui
			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(7, 8, 11)
			stroke.Thickness = 2.5
			stroke.Parent = label
		end
		for _, desc in station:GetDescendants() do
			if desc:IsA("BillboardGui") and desc ~= gui then
				desc.Enabled = false
			end
		end
	end
	return #Catalog.entries
end
return Style
