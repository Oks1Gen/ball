--!strict
-- Final, narrow egg-shop placement; never reruns historical world builders.
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Style = {}
local VERSION = "arc-native-v1"
local V = Vector3.new
local SLOTS = {
	{ slot = "Common", model = "Egg_Common" },
	{ slot = "Uncommon", model = "Egg_Uncommon" },
	{ slot = "Volcanic", model = "VolcanicEgg" },
	{ slot = "Rare", model = "Egg_Rare" },
	{ slot = "Rainbow", model = "Egg_Rainbow" },
}

local SEAT_COLORS: { [string]: { Color3 } } = {
	Common = { Color3.fromRGB(72, 193, 16), Color3.fromRGB(121, 231, 43) },
	Uncommon = { Color3.fromRGB(16, 171, 225), Color3.fromRGB(101, 222, 250) },
	Volcanic = { Color3.fromRGB(226, 157, 17), Color3.fromRGB(255, 214, 65) },
	Rare = { Color3.fromRGB(102, 22, 37), Color3.fromRGB(142, 35, 42) },
}

function Style.colorSeats(stand: Instance): number
	local changed = 0
	for slotName, colors in SEAT_COLORS do
		local slot = stand:FindFirstChild(slotName)
		if slot then
			for _, part in slot:GetDescendants() do
				if part:IsA("BasePart") then
					local color = if part.Name:find("_SeatRim", 1, true)
						then colors[1]
						elseif part.Name:find("_SeatInset", 1, true) then colors[2]
						else nil
					if color and part.Color ~= color then
						part.Color = color
						changed += 1
					end
				end
			end
		end
	end
	return changed
end

local function extents(root: Instance, onlyPaving: boolean?): (Vector3, Vector3)
	local low, high = V(math.huge, math.huge, math.huge), V(-math.huge, -math.huge, -math.huge)
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 and (not onlyPaving or p.Name == "PavingSurface") then
			for _, x in { -0.5, 0.5 } do
				for _, y in { -0.5, 0.5 } do
					for _, z in { -0.5, 0.5 } do
						local q = p.CFrame:PointToWorldSpace(p.Size * V(x, y, z))
						low, high = low:Min(q), high:Max(q)
					end
				end
			end
		end
	end
	return low, high
end

local function hideSupport(p: Instance?)
	if not p or not p:IsA("BasePart") then
		return
	end
	p.Transparency, p.CastShadow = 1, false
	p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
	p:SetAttribute("PartRole", "HiddenVisual")
	p:SetAttribute("Purpose", "Legacy egg placement support; visible stand is EggShop.EggStand")
end

function Style.apply(world: Instance): number
	if world.Name ~= "World1" then
		return 0
	end
	local shop = Refs.eggs(world)
	local lobby = world:FindFirstChild("Lobby")
	local paths = lobby and lobby:FindFirstChild("Paths")
	local plaza = paths and paths:FindFirstChild("EggPlaza")
	local boards = Refs.rankings(world)
	if not shop or not plaza or not boards then
		return 0
	end
	local template = game.ServerStorage:FindFirstChild("EggStandTemplate")
	assert(template and template:IsA("Model"), "Missing persistent EggStandTemplate")
	for _, entry in SLOTS do
		local egg = shop:FindFirstChild(entry.model)
		assert(egg and egg:IsA("Model"), "Missing existing egg: " .. entry.model)
		assert(egg:FindFirstChild(if entry.slot == "Volcanic" then "Fallback" else "ImportedVisual"))
	end
	local low, high = extents(plaza, true)
	local boardLow = extents(boards)
	local centerX = (low.X + high.X) / 2
	local scale = math.min(120, high.X - low.X - 10) / 121
	assert(scale > 0.5 and scale < 1.5, "Unexpected egg plaza size")
	local baseY = high.Y + 0.025
	local centerZ = boardLow.Z - 2.5 - 9.25 * scale
	local existing = shop:FindFirstChild("EggStand")
	local stand: Model
	if existing then
		assert(existing:IsA("Model") and existing:GetAttribute("EggStandVersion") == VERSION, "Unknown EggStand")
		stand = existing
	else
		stand = template:Clone()
		stand.Name = "EggStand"
		stand:SetAttribute("EggStandVersion", VERSION)
		stand.WorldPivot = CFrame.identity
		stand:ScaleTo(scale)
		stand:PivotTo(CFrame.new(centerX, baseY, centerZ))
		for _, p in stand:GetDescendants() do
			if p:IsA("BasePart") then
				p.Anchored = true
				p.CanTouch = false
				if p.Name == "SeatCenter" then
					p.Transparency = 1
					p.CanCollide, p.CanQuery = false, false
					p:SetAttribute("PartRole", "InteractionAnchor")
					p:SetAttribute("Purpose", "Egg seat top and symmetry marker")
				end
			end
		end
		stand.Parent = shop
	end
	Style.colorSeats(stand)
	-- Position by the visible egg's bounds, not its possibly offset authored pivot.
	for _, entry in SLOTS do
		local egg = shop:FindFirstChild(entry.model) :: Model
		local slot = stand:FindFirstChild(entry.slot)
		local seat = slot and slot:FindFirstChild("SeatCenter") :: BasePart?
		assert(seat and seat:IsA("BasePart"), "Missing seat marker")
		local premium = entry.slot == "Volcanic"
		local visual = egg:FindFirstChild(if premium then "Fallback" else "ImportedVisual")
		local cf: CFrame
		local size: Vector3
		if visual and visual:IsA("Model") then
			cf, size = visual:GetBoundingBox()
		else
			assert(visual and visual:IsA("BasePart"))
			cf, size = visual.CFrame, visual.Size
		end
		local gap = 0.08
		local delta = V(seat.Position.X - cf.X, seat.Position.Y + gap - (cf.Y - size.Y / 2), seat.Position.Z - cf.Z)
		egg:PivotTo(egg:GetPivot() + delta)
		local anchor = egg:FindFirstChild(if premium then "InteractionAnchor" else "EggShell")
		assert(anchor and anchor:IsA("BasePart"))
		anchor.CFrame = CFrame.new(seat.Position.X, anchor.Position.Y, seat.Position.Z) * anchor.CFrame.Rotation
		anchor:SetAttribute("PartRole", "InteractionAnchor")
		local support = egg:FindFirstChild(if premium then "Pedestal" else "EggPedestal")
		assert(support and support:IsA("BasePart"))
		support.CFrame = CFrame.new(seat.Position.X, seat.Position.Y - support.Size.Y / 2, seat.Position.Z)
		hideSupport(support)
		local ring = egg:FindFirstChild("EggRing")
		if ring and ring:IsA("BasePart") then
			ring.CFrame = CFrame.new(seat.Position.X, seat.Position.Y + gap - 0.3 - ring.Size.Y / 2, seat.Position.Z)
			hideSupport(ring)
		end
		local caption = egg:FindFirstChild("EggSignAnchor", true)
		if caption and caption:IsA("BasePart") then
			caption.CFrame = CFrame.new(seat.Position.X, seat.Position.Y + gap + size.Y + 2.4, seat.Position.Z)
		end
		if premium then
			egg:SetAttribute("EggDisplayHeight", size.Y)
			egg:SetAttribute("EggDisplayGap", gap)
		end
		egg:SetAttribute("EggStandVersion", VERSION)
	end
	world:SetAttribute("EggStandVersion", VERSION)
	return #SLOTS
end

return Style
