--!strict
-- Preserve the upstream lightning-to-Skill collection alongside the native bubble pop.
local Run = game:GetService("RunService")
local Assets = require(script.Parent.Parent.UIAssets)
local CameraCue = require(script.Parent.PerfectKickFeedback)
local Collect = {}

function Collect.mount(context: any)
	local group: any = nil
	local alive = true
	local camera = CameraCue.mount({
		effects = context.enabled,
		shake = function()
			return false
		end,
	})
	local function clear()
		if group then
			group.host:Destroy()
			group = nil
		end
		camera.stop()
	end
	local connection = Run.RenderStepped:Connect(function()
		if context.blocked() or not context.enabled() then
			clear()
			return
		end
		local g = group
		if not g then
			return
		end
		local age = os.clock() - g.started
		local label = context.skillLabel
		if age > 1.2 or not label or not label.Parent then
			clear()
			return
		end
		local target = label.AbsolutePosition
			+ Vector2.new(label.AbsoluteSize.X * 0.25, label.AbsoluteSize.Y * 0.5)
			- context.parent.AbsolutePosition
		for j, icon in g.icons do
			local angle = j / #g.icons * math.pi * 2
			local spread = Vector2.new(math.cos(angle) * 64, math.sin(angle) * 52)
			local elapsed = age - (j - 1) * 0.025
			local position = g.at
			if elapsed < 0.18 then
				position = g.at + spread * math.clamp(elapsed / 0.18, 0, 1)
			else
				local t = math.clamp((elapsed - 0.18) / 0.65, 0, 1)
				local eased = t * t * (3 - 2 * t)
				local begin = g.at + spread
				local control = (begin + target) / 2 + Vector2.new(math.sin(angle) * 80, -60)
				position = begin * (1 - eased) ^ 2 + control * (2 * (1 - eased) * eased) + target * eased ^ 2
				icon.ImageTransparency = if t >= 1 then 1 else 0
			end
			icon.Position = UDim2.fromOffset(math.round(position.X), math.round(position.Y))
			icon.Rotation = math.sin(angle + age * 5) * 18
			icon.Visible = elapsed >= 0
		end
		if age > 0.92 and not g.sound then
			g.sound = true
			if context.playSound then
				context.playSound("rbxasset://sounds/volume_slider.ogg", 0.1, 1.8)
			end
		end
	end)
	return {
		play = function(at: Vector2, multiplier: number)
			if not alive or not context.enabled() or not context.skillLabel then
				return
			end
			clear()
			local host = Instance.new("Frame")
			host.Name = "LightningCollect"
			host.Size = UDim2.fromScale(1, 1)
			host.BackgroundTransparency = 1
			host.Active, host.Interactable = false, false
			host.ZIndex = 20
			host.Parent = context.parent
			local icons = {}
			for _ = 1, (if multiplier >= 15 then 10 else 8) do
				local icon = Instance.new("ImageLabel")
				icon.Name = "SkillLightning"
				icon.AnchorPoint = Vector2.new(0.5, 0.5)
				icon.BackgroundTransparency = 1
				icon.Image = Assets.Images.Skill
				icon.Size = UDim2.fromOffset(50, 50)
				icon.ZIndex = 21
				icon.Parent = host
				Assets.bind(icon)
				table.insert(icons, icon)
			end
			group = { host = host, icons = icons, at = at, started = os.clock(), sound = false }
			camera.confirm()
		end,
		clear = clear,
		destroy = function()
			alive = false
			clear()
			connection:Disconnect()
			camera.destroy()
		end,
	}
end

return Collect
