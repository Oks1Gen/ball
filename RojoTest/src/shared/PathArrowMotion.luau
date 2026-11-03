--!strict
-- Constant-speed surface navigation. Full glyphs fade at the ends, never snap visibly.
local Motion = {}
function Motion.update(root: Model, time: number)
	local origin = root:FindFirstChild("Origin")
	if not origin or not origin:IsA("BasePart") then
		return
	end
	local length = root:GetAttribute("PathLength") :: number
	local count = root:GetAttribute("ArrowCount") :: number
	if not length or not count then
		return
	end
	local period = count * 8
	local visibleLength = length - 5
	for _, arrow in root:GetChildren() do
		local slot = arrow:GetAttribute("ArrowSlot")
		if arrow:IsA("Model") and typeof(slot) == "number" then
			local travel = (time * 2.56 + slot * 8) % period
			local opacity = math.clamp(math.min(travel, visibleLength - travel) / 1.5, 0, 1)
			arrow:PivotTo(origin.CFrame * CFrame.new(0, 0, -2.5 - travel))
			for _, part in arrow:GetChildren() do
				if part:IsA("BasePart") then
					part.Transparency = 1 - opacity
					part.LocalTransparencyModifier = 0
				end
			end
		end
	end
end
return Motion
