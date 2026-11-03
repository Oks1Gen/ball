--!strict
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Style = {}
local ENTRIES = {
	{ model = "Egg_Common", slot = "Common", theme = "Meadow" },
	{ model = "Egg_Uncommon", slot = "Uncommon", theme = "Glacier" },
	{ model = "Egg_Rare", slot = "Rare", theme = "Magma" },
	{ model = "Egg_Rainbow", slot = "Rainbow", theme = "Void" },
	{ model = "VolcanicEgg", slot = "Volcanic", theme = "Celestial" },
}

function Style.apply(world: Instance): number
	local shop = Refs.eggs(world)
	if not shop or world.Name ~= "World1" then
		return 0
	end
	local storage = game:GetService("ServerStorage")
	local assets = storage:FindFirstChild("Assets")
	local eggs = assets and assets:FindFirstChild("Eggs")
	local templates = (eggs and eggs:FindFirstChild("Elemental")) or storage:FindFirstChild("ElementalEggTemplates")
	assert(templates, "Missing elemental egg templates")
	local stand = assert(shop:FindFirstChild("EggStand"))
	for _, entry in ENTRIES do
		assert(templates:FindFirstChild(entry.theme), "Missing elemental theme")
		assert(shop:FindFirstChild(entry.model), "Missing egg stand")
	end
	local backups = storage:FindFirstChild("WorldBackups")
	if not backups then
		backups = Instance.new("Folder")
		backups.Name = "WorldBackups"
		backups.Parent = storage
	end
	local backup = backups:FindFirstChild("BeforeElementalEggReplacement_20261103")
	if not backup then
		backup = Instance.new("Folder")
		backup.Name = "BeforeElementalEggReplacement_20261103"
		backup.Parent = backups
		local snapshot = shop:Clone()
		snapshot.Parent = backup
	end
	for _, entry in ENTRIES do
		local egg = shop:FindFirstChild(entry.model) :: Model
		local premium = entry.slot == "Volcanic"
		local visualName = if premium then "Visual" else "ImportedVisual"
		local existing = egg:FindFirstChild(visualName)
		local visual: Model
		if existing and existing:IsA("Model") and existing:GetAttribute("ElementalEggTheme") == entry.theme then
			visual = existing
		else
			if existing then
				local retired = existing :: Instance
				retired.Name = entry.model .. "_PreviousVisual"
				retired.Parent = backup
			end
			visual = (templates:FindFirstChild(entry.theme) :: Model):Clone()
			visual.Name = visualName
			visual:SetAttribute("ElementalEggTheme", entry.theme)
			visual.Parent = egg
		end
		local slot = assert(stand:FindFirstChild(entry.slot))
		local seat = slot:FindFirstChild("SeatCenter") :: BasePart
		local anchor = egg:FindFirstChild(if premium then "InteractionAnchor" else "EggShell") :: BasePart
		local _, size = visual:GetBoundingBox()
		if math.abs(size.Y - 10) > 0.0001 then
			visual:ScaleTo(visual:GetScale() * 10 / size.Y)
		end
		visual:PivotTo(
			CFrame.new(seat.Position + Vector3.new(0, 0.08, 0)) * anchor.CFrame.Rotation * CFrame.Angles(0, math.pi, 0)
		)
		local cf, bounds = visual:GetBoundingBox()
		visual:PivotTo(
			visual:GetPivot()
				+ Vector3.new(
					seat.Position.X - cf.X,
					seat.Position.Y + 0.08 - cf.Y + bounds.Y / 2,
					seat.Position.Z - cf.Z
				)
		)
		if premium then
			local fallback = egg:FindFirstChild("Fallback") :: BasePart?
			if fallback then
				fallback.Transparency = 1
				fallback.CastShadow = false
				fallback:SetAttribute("PartRole", "HiddenVisual")
				fallback:SetAttribute("Purpose", "Legacy premium egg placement support")
			end
		end
		egg:SetAttribute("ElementalEggTheme", entry.theme)
	end
	return #ENTRIES
end

return Style
