--!strict
-- A single acknowledged pop scatters existing Skill icons, then gathers them to HUD.
local Run = game:GetService("RunService")
local Assets = require(script.Parent.Parent.UIAssets)
local CameraCue = require(script.Parent.PerfectKickFeedback)
local Feedback = {}
local PURPLE = Color3.fromRGB(188, 92, 255)

function Feedback.create(context: any)
	local groups: { any } = {}
	local alive = true
	local camera = CameraCue.mount({
		effects = context.effects,
		shake = function()
			return false
		end,
	})
	local function clear()
		for _, group in groups do
			group.host:Destroy()
		end
		table.clear(groups)
		camera.stop()
	end
	local function play(at: Vector2, multiplier: number)
		if not alive then
			return
		end
		clear()
		local host = Instance.new("Frame")
		host.Name = "LightningCollect"
		host.Size = UDim2.fromScale(1, 1)
		host.BackgroundTransparency = 1
		host.ZIndex = 70
		host.Parent = context.parent
		local ring = Instance.new("Frame")
		ring.Name = "PopRing"
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.fromOffset(at.X, at.Y)
		ring.BackgroundTransparency = 1
		ring.ZIndex = 71
		ring.Parent = host
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = ring
		local stroke = Instance.new("UIStroke")
		stroke.Color = PURPLE
		stroke.Thickness = 3
		stroke.Parent = ring
		local text = Instance.new("TextLabel")
		text.Name = "BoostConfirmed"
		text.AnchorPoint = Vector2.new(0.5, 0.5)
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromOffset(190, 36)
		text.Position = UDim2.fromOffset(at.X, at.Y)
		text.Font = Enum.Font.GothamBlack
		text.TextSize = 23
		text.TextColor3 = Color3.fromRGB(245, 218, 255)
		text.TextStrokeColor3 = Color3.fromRGB(45, 16, 66)
		text.TextStrokeTransparency = 0
		text.Text = "×" .. tostring(multiplier) .. " SKILL!"
		text.ZIndex = 75
		text.Parent = host
		local icons = {}
		local count = if context.effects() then (if multiplier >= 4 then 10 else 8) else 0
		for _ = 1, count do
			local icon = Instance.new("ImageLabel")
			icon.Name = "SkillLightning"
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.BackgroundTransparency = 1
			icon.Image = Assets.Images.Skill
			icon.Size = UDim2.fromOffset(50, 50)
			icon.ZIndex = 74
			icon.Parent = host
			Assets.bind(icon)
			table.insert(icons, icon)
		end
		local dots = {}
		for i = 1, (if context.effects() then 8 else 0) do
			local dot = Instance.new("Frame")
			dot.Name = "PurpleSpark"
			dot.AnchorPoint = Vector2.new(0.5, 0.5)
			dot.Size = UDim2.fromOffset(6 + i % 3, 6 + i % 3)
			dot.BorderSizePixel = 0
			dot.BackgroundColor3 = if i % 2 == 0 then PURPLE else Color3.fromRGB(235, 192, 255)
			dot.ZIndex = 72
			dot.Parent = host
			local round = Instance.new("UICorner")
			round.CornerRadius = UDim.new(1, 0)
			round.Parent = dot
			table.insert(dots, dot)
		end
		table.insert(groups, {
			host = host,
			ring = ring,
			stroke = stroke,
			text = text,
			icons = icons,
			dots = dots,
			at = at,
			started = os.clock(),
			sound = false,
		})
		camera.confirm()
		context.playSound("rbxasset://sounds/volume_slider.ogg", 0.25, 1.3)
	end
	local connection = Run.RenderStepped:Connect(function()
		if context.blocked() then
			clear()
			return
		end
		for i = #groups, 1, -1 do
			local g = groups[i]
			local age = os.clock() - g.started
			if age > 1.2 then
				g.host:Destroy()
				table.remove(groups, i)
				continue
			end
			local reduced = not context.effects()
			local radius = 48 + age * 90
			g.ring.Visible = not reduced and age < 0.42
			g.ring.Size = UDim2.fromOffset(radius * 2, radius * 2)
			g.stroke.Transparency = math.clamp(age / 0.42, 0, 1)
			g.text.Position = UDim2.fromOffset(g.at.X, g.at.Y - 18 - math.round(age * 22))
			g.text.TextTransparency = math.clamp((age - 0.4) / 0.5, 0, 1)
			g.text.TextStrokeTransparency = g.text.TextTransparency
			local label = context.skillLabel
			local target = label.AbsolutePosition
				+ Vector2.new(label.AbsoluteSize.X * 0.25, label.AbsoluteSize.Y * 0.5)
				- context.parent.AbsolutePosition
			for j, icon in g.icons do
				local angle = j / #g.icons * math.pi * 2
				local spread = Vector2.new(math.cos(angle) * 64, math.sin(angle) * 52)
				local elapsed = age - (j - 1) * 0.025
				local pos = g.at
				if elapsed < 0.18 then
					pos = g.at + spread * math.clamp(elapsed / 0.18, 0, 1)
				else
					local t = math.clamp((elapsed - 0.18) / 0.65, 0, 1)
					local eased = t * t * (3 - 2 * t)
					local begin = g.at + spread
					local control = (begin + target) / 2 + Vector2.new(math.sin(angle) * 80, -60)
					pos = begin * (1 - eased) ^ 2 + control * (2 * (1 - eased) * eased) + target * eased ^ 2
					icon.ImageTransparency = if t >= 1 then 1 else 0
				end
				icon.Position = UDim2.fromOffset(math.round(pos.X), math.round(pos.Y))
				icon.Rotation = math.sin(angle + age * 5) * 18
				icon.Visible = not reduced and elapsed >= 0
			end
			for j, dot in g.dots do
				local angle = j / #g.dots * math.pi * 2
				dot.Position = UDim2.fromOffset(
					g.at.X + math.cos(angle) * (25 + age * 115),
					g.at.Y + math.sin(angle) * (25 + age * 115) + age * age * 65
				)
				dot.BackgroundTransparency = math.clamp(age / 0.5, 0, 1)
				dot.Visible = not reduced
			end
			if age > 0.92 and not g.sound then
				g.sound = true
				if not reduced then
					context.playSound("rbxasset://sounds/volume_slider.ogg", 0.1, 1.8)
				end
			end
		end
	end)
	return {
		play = play,
		clear = clear,
		destroy = function()
			alive = false
			clear()
			connection:Disconnect()
			camera.destroy()
		end,
	}
end
return Feedback
