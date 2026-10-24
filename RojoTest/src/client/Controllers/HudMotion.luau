--!strict
local Motion = require(game.ReplicatedStorage.Shared.UiMotion)
local Config = require(game.ReplicatedStorage.Shared.UiMotionConfig)
local HudMotion = {}

-- Полноразмерные прозрачные блоки сохраняют исходные координаты элементов.
-- Добавлять элемент в блок можно в UiMotionConfig.Hud.Groups.
function HudMotion.mount(hud: Frame, canvas: Frame, boardScale: UIScale)
	local groups: { [string]: Frame } = {}
	local animations = {}
	for direction, names in Config.Hud.Groups :: { [string]: { string } } do
		local group = Instance.new("Frame")
		group.Name = direction
		group:SetAttribute("HudDirection", direction)
		group.BackgroundTransparency = 1
		group.Size = UDim2.fromScale(1, 1)
		group.Parent = hud
		groups[direction] = group
		for _, name in names do
			for _, suffix in { "", "Shadow" } do
				local node = hud:FindFirstChild(name .. suffix) or canvas:FindFirstChild(name .. suffix)
				if node then
					node.Parent = group
				end
			end
		end
		animations[direction] = Motion.slide(group, direction, function()
			return 1 / math.max(0.01, boardScale.Scale)
		end)
	end
	return {
		groups = groups,
		layout = function(phone: boolean)
			-- На телефоне счётчики стоят справа сверху и уходят вправо.
			local destination = if phone then groups.Right else groups.Left
			for _, name in { "RebirthIcon", "RebirthCount", "WinsIcon", "WinsCount", "FriendBoost" } do
				for _, group in groups do
					local node = group:FindFirstChild(name)
					if node then
						node.Parent = destination
					end
				end
			end
		end,
		setHidden = function(value: boolean, instant: boolean?)
			for _, animation in animations do
				animation.setHidden(value, instant)
			end
		end,
		refresh = function()
			for _, animation in animations do
				animation.refresh()
			end
		end,
		destroy = function()
			for _, animation in animations do
				animation.destroy()
			end
		end,
	}
end

return HudMotion
