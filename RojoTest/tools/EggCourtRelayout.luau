-- Edit migration: egg arc in the World1 egg court (2026-11-01). Run once in Edit, then save the place.
-- The five eggs stand on one symmetric arc around the court plaza: the Volcanic egg is the
-- centrepiece at the apex, the paid eggs go up in price away from the boulevard and turn a little
-- towards the plaza. Every moved BasePart keeps its previous CFrame in the BeforeEggArc attribute.
assert(not game:GetService("RunService"):IsRunning(), "Run in Edit")
local map = workspace.Map.World1
assert(not map:GetAttribute("EggArc"), "Egg arc already applied")
local sw = map.SkippingWorld
local V = Vector3.new
game:GetService("ChangeHistoryService"):SetWaypoint("Before egg arc")

-- Pivot X/Z and the turn towards the plaza (degrees; positive turns the face towards -X).
local targets = {
	Common = { 48.4, 266, 20 },
	Uncommon = { 43, 284, 10 },
	Rare = { 9, 284, -10 },
	Rainbow = { 3.6, 266, -20 },
}
local VOLCANIC = V(26, 0, 287)

local renders = {}
for _, render in map.SurfaceSeparation:GetChildren() do
	local link = render:FindFirstChild("OriginalPart")
	if link and link.Value then
		renders[link.Value] = renders[link.Value] or {}
		table.insert(renders[link.Value], render)
	end
end
local moved = 0
local function transform(item, delta)
	local parts = item:IsA("BasePart") and { item } or {}
	for _, d in item:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		elseif d:IsA("Model") then
			d.WorldPivot = delta * d.WorldPivot
		end
	end
	for _, p in parts do
		if p:GetAttribute("BeforeEggArc") == nil then
			p:SetAttribute("BeforeEggArc", p.CFrame)
		end
		for _, r in renders[p] or {} do
			if r:GetAttribute("BeforeEggArc") == nil then
				r:SetAttribute("BeforeEggArc", r.CFrame)
			end
			r.CFrame = delta * r.CFrame
		end
		p.CFrame = delta * p.CFrame
		moved += 1
	end
	if item:IsA("Model") then
		item.WorldPivot = delta * item.WorldPivot
	end
end

for id, t in targets do
	local egg = sw["Egg_" .. id]
	local pivot = egg:GetPivot()
	-- The eggs face -Z; the new pivot keeps the height and turns about the vertical axis only.
	local goal = CFrame.new(t[1], pivot.Y, t[2]) * CFrame.Angles(0, math.rad(t[3]), 0)
	local flat = CFrame.new(pivot.Position)
		* CFrame.lookAlong(V(), V(pivot.LookVector.X, 0, pivot.LookVector.Z)).Rotation
	transform(egg, goal * flat:Inverse())
end

-- The admin egg is a loose group of parts around its stand.
local admin = sw.HackedAdminEgg
local old = admin.Position
local offset = V(VOLCANIC.X - old.X, 0, VOLCANIC.Z - old.Z)
for _, item in sw:GetChildren() do
	local named = item.Name == "HackedAdminEgg"
		or item.Name == "HackedEggStand"
		or item.Name == "VolcanicEggVisual"
		or item.Name == "VolcanicEggFallback"
		or item.Name == "AdminEggCaption"
		or item.Name == "LabelAnchor"
	if named then
		local c
		if item:IsA("BasePart") then
			c = item.Position
		else
			for _, d in item:GetDescendants() do
				if d:IsA("BasePart") then
					c = d.Position
					break
				end
			end
		end
		if c and (V(c.X, 0, c.Z) - V(old.X, 0, old.Z)).Magnitude < 8 then
			transform(item, CFrame.new(offset))
		end
	end
end

map:SetAttribute("EggArc", "2026-11-01")
game:GetService("ChangeHistoryService"):SetWaypoint("Egg arc")
return "moved " .. moved .. " parts"
