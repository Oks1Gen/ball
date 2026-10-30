--!strict
-- Retain upstream HUD avoidance while bubbles enter from above the screen.
local Players = game:GetService("Players")
local Rules = require(game.ReplicatedStorage.Shared.Core.TrainingBoost)
local Placement = {}

function Placement.choose(layer: Frame, preferred: Vector2, diameter: number, seed: number, offer: number): Vector2?
	local size = layer.AbsoluteSize
	local radius = diameter * 0.57 + 8
	local excluded = {}
	local function visible(node: Instance): boolean
		local parent: Instance? = node
		while parent and parent ~= Players.LocalPlayer.PlayerGui do
			if parent:IsA("GuiObject") and not parent.Visible then
				return false
			end
			if parent:IsA("ScreenGui") and not parent.Enabled then
				return false
			end
			parent = parent.Parent
		end
		return parent == Players.LocalPlayer.PlayerGui
	end
	for _, screen in Players.LocalPlayer.PlayerGui:GetChildren() do
		if screen.Name == "SkippingHUD" or screen.Name == "CollectorUI" or screen.Name == "BallTopbar" then
			for _, node in screen:GetDescendants() do
				if
					node:IsA("GuiObject")
					and visible(node)
					and (
						node:IsA("GuiButton")
						or node.Name == "LevelBar"
						or node.Name == "Skill"
						or node.Name == "WinsCount"
						or node.Name == "LevelUpText"
					)
				then
					local at = node.AbsolutePosition - layer.AbsolutePosition
					table.insert(excluded, { x = at.X, y = at.Y, w = node.AbsoluteSize.X, h = node.AbsoluteSize.Y })
				end
			end
		end
	end
	local minX, maxX = radius + 8, size.X - radius - 8
	local minY, maxY = radius + 76, size.Y - radius - 24
	if minX > maxX or minY > maxY then
		return nil
	end
	local function fits(at: Vector2): boolean
		if at.X < minX or at.X > maxX or at.Y < minY or at.Y > maxY then
			return false
		end
		for _, rect in excluded do
			local dx = math.max(rect.x - at.X, 0, at.X - rect.x - rect.w)
			local dy = math.max(rect.y - at.Y, 0, at.Y - rect.y - rect.h)
			if dx * dx + dy * dy < radius ^ 2 then
				return false
			end
		end
		return true
	end
	if fits(preferred) then
		return preferred
	end
	for attempt = 1, 180 do
		local at = Vector2.new(
			minX + Rules.sample(seed, offer, attempt * 2) * (maxX - minX),
			minY + Rules.sample(seed, offer, attempt * 2 + 1) * (maxY - minY)
		)
		if fits(at) then
			return at
		end
	end
	return nil
end

return Placement
