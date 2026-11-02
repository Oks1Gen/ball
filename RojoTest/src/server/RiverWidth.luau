--!strict
-- Grow the authored side rivers outwards; keep the bank overlap and shore foam.
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local RiverWidth = {}
local MULTIPLIER = 3

function RiverWidth.apply(world: any): any
	local river = assert(Refs.course(world).Environment:FindFirstChild("River"), "Missing side rivers")
	local growth: { [string]: number } = {}
	local changed = 0
	for _, p in river:GetDescendants() do
		if p:IsA("BasePart") and (p.Name == "RiverWaterWest" or p.Name == "RiverWaterEast") then
			local base = p:GetAttribute("RiverWidthBase")
			if typeof(base) ~= "number" then
				base = p.Size.X
				p:SetAttribute("RiverWidthBase", base)
			end
			growth[if p.Name == "RiverWaterWest" then "West" else "East"] = base * (MULTIPLIER - 1)
		end
	end
	assert(growth.West and growth.East, "Both river sides are required")
	for _, p in river:GetDescendants() do
		if p:IsA("BasePart") then
			local side = p.Name:match("^RiverWater(West)$")
				or p.Name:match("^RiverWater(East)$")
				or p.Name:match("^VFX_RiverSurface(West)$")
				or p.Name:match("^VFX_RiverSurface(East)$")
			if side then
				local base = p:GetAttribute("RiverWidthBase")
				if typeof(base) ~= "number" then
					base = p.Size.X
					p:SetAttribute("RiverWidthBase", base)
				end
				local width = base + growth[side]
				local delta = width - p.Size.X
				if math.abs(delta) > 0.0001 then
					p.CFrame *= CFrame.new((if side == "West" then -1 else 1) * delta / 2, 0, 0)
					p.Size = Vector3.new(width, p.Size.Y, p.Size.Z)
					changed += 1
				end
			end
		end
	end
	river:SetAttribute("WidthMultiplier", MULTIPLIER)
	return { changedParts = changed, multiplier = MULTIPLIER }
end

return RiverWidth
