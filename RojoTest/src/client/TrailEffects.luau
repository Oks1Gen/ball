--!strict
-- Cosmetic trail families. Fire remains in BallEffects; these never use fire textures.
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Shapes = require(script.Parent.BallEffectShapes)
local Effects = {}
local active = 0
local C = Color3.fromRGB
local PALETTES = {
	White = { C(246, 253, 255), C(161, 222, 255) },
	Blue = { C(185, 253, 255), C(32, 158, 255) },
	Purple = { C(255, 165, 255), C(135, 45, 255) },
	Rainbow = { C(255, 83, 133), C(110, 249, 255) },
}
local rainbow = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C(255, 82, 119)),
	ColorSequenceKeypoint.new(0.2, C(255, 208, 61)),
	ColorSequenceKeypoint.new(0.4, C(99, 255, 128)),
	ColorSequenceKeypoint.new(0.6, C(67, 217, 255)),
	ColorSequenceKeypoint.new(0.8, C(145, 98, 255)),
	ColorSequenceKeypoint.new(1, C(255, 106, 230)),
})

local function particles(parent: Instance, id: string): ParticleEmitter
	local palette = PALETTES[id] or PALETTES.White
	local p = Instance.new("ParticleEmitter")
	p.Name = id .. (id == "Blue" and "IceCrystals" or id == "Purple" and "ArcaneMotes" or "Sparkles")
	p.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	p.Color = id == "Rainbow" and rainbow or ColorSequence.new(palette[1], palette[2])
	p.Rate = id == "White" and 10 or 20
	p.Lifetime = NumberRange.new(0.25, 0.65)
	p.Speed = NumberRange.new(1, 4)
	p.EmissionDirection = Enum.NormalId.Back
	p.SpreadAngle = Vector2.new(35, 35)
	p.Rotation = NumberRange.new(0, 360)
	p.RotSpeed = NumberRange.new(-90, 90)
	p.LightEmission = 0.85
	p.Size = NumberSequence.new(id == "Blue" and 0.5 or 0.35, 0)
	p.Transparency = NumberSequence.new(0.15, 1)
	p.Acceleration = Vector3.new(0, id == "Blue" and -5 or 2, 0)
	p.Enabled = false
	p.Parent = parent
	return p
end

function Effects.burst(parent: Instance, position: Vector3, normal: Vector3, id: string, strength: number)
	local palette = PALETTES[id]
	if not palette then
		return
	end
	parent:SetAttribute("TrailStyle", id)
	local a = Instance.new("Attachment")
	a.CFrame = CFrame.lookAt(position, position + normal)
	if parent:IsA("BasePart") then
		a.CFrame = parent.CFrame:ToObjectSpace(a.CFrame)
	end
	a.Parent = parent
	local p = particles(a, id)
	p.Rate = 0
	p.Speed = NumberRange.new(2 * strength, 10 * strength)
	p.SpreadAngle = Vector2.new(75, 75)
	p:Emit(math.round(8 + 8 * strength))
	Shapes.ring(parent, position, normal, palette[1], 2.8 * strength)
	if id == "Purple" then
		Shapes.ring(parent, position + normal * 0.35, normal, palette[2], 1.8 * strength)
	elseif id == "Blue" then
		local basis = CFrame.lookAt(position, position + normal)
		for i = 1, 6 do
			local angle = i * math.pi / 3
			local offset = basis.RightVector * math.cos(angle) + basis.UpVector * math.sin(angle)
			local shard = Shapes.part(parent, "IceShard", palette[i % 2 + 1])
			shard.Material = Enum.Material.Neon
			shard.Size = Vector3.new(0.13, 0.6, 0.13) * strength
			shard.CFrame = CFrame.new(position) * CFrame.Angles(i, angle, 0.4)
			TweenService:Create(shard, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = position + offset * 3 * strength + normal,
				Transparency = 1,
				Size = Vector3.one * 0.02,
			}):Play()
		end
	end
end

function Effects.flight(id: string)
	local palette = PALETTES[id]
	local root: Part? = nil
	local ribbons: { Trail } = {}
	local emitters: { ParticleEmitter } = {}
	local orbiters: { BasePart } = {}
	local visible = false
	local finished = false
	local function enable(value: boolean)
		if visible == value then
			return
		end
		visible = value
		for _, p in emitters do
			p.Enabled = value
			if not value then
				p:Clear()
			end
		end
		for _, t in ribbons do
			t.Enabled = value
			if not value then
				t:Clear()
			end
		end
		for _, part in orbiters do
			part.Transparency = value and 0.15 or 1
		end
	end
	local function build(position: Vector3)
		if root or not palette or active >= 6 then
			return
		end
		local host = Shapes.part(workspace, "Ball" .. id .. "Flight", palette[1])
		host:SetAttribute("TrailStyle", id)
		host.Transparency = 1
		host.Size = Vector3.one * 0.1
		host.Position = position
		root = host
		active += 1
		host.Destroying:Once(function()
			active -= 1
		end)
		local lanes = id == "Rainbow" and 3 or 2
		for i = 1, lanes do
			local a, b = Instance.new("Attachment"), Instance.new("Attachment")
			local offset = (i - (lanes + 1) / 2) * 0.65
			a.Position = Vector3.new(offset - 0.2, 0, 0.4)
			b.Position = Vector3.new(offset + 0.2, 0, 0.4)
			a.Parent, b.Parent = host, host
			local t = Instance.new("Trail")
			t.Name = id .. "Ribbon" .. i
			t.Attachment0, t.Attachment1 = a, b
			t.Color = id == "Rainbow" and rainbow or ColorSequence.new(palette[1], palette[2])
			t.FaceCamera = true
			t.LightEmission = 0.85
			t.Transparency = NumberSequence.new(0.2, 1)
			t.WidthScale = NumberSequence.new(1, 0)
			t.MinLength = 0.05
			t.Lifetime = 0.3
			t.Enabled = false
			t.Parent = host
			table.insert(ribbons, t)
		end
		local source = Instance.new("Attachment")
		source.Parent = host
		table.insert(emitters, particles(source, id))
		if id == "White" then
			local mist = particles(source, id)
			mist.Name = "WindWisps"
			mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
			mist.Rate = 8
			mist.Size = NumberSequence.new(0.5, 1.8)
			mist.Transparency = NumberSequence.new(0.8, 1)
			table.insert(emitters, mist)
		elseif id == "Blue" or id == "Purple" then
			for i = 1, 3 do
				local crystal = Shapes.part(host, id == "Blue" and "OrbitIce" or "ArcaneRune", palette[i % 2 + 1])
				crystal.Material = Enum.Material.Neon
				crystal.Size = id == "Blue" and Vector3.new(0.15, 0.55, 0.15) or Vector3.new(0.25, 0.25, 0.08)
				crystal.Transparency = 1
				table.insert(orbiters, crystal)
			end
		end
	end
	return {
		update = function(position: Vector3, velocity: Vector3, show: boolean, _intensity: number)
			if finished or not palette then
				return
			end
			local camera = workspace.CurrentCamera
			local showNow = show and (not camera or (camera.CFrame.Position - position).Magnitude < 200)
			if showNow then
				build(position)
			end
			local host = root
			if not host then
				return
			end
			-- Position before enabling avoids a ribbon across a hidden/teleported interval.
			local direction = velocity.Magnitude > 0.05 and velocity.Unit or -Vector3.zAxis
			local up = math.abs(direction.Y) > 0.95 and Vector3.zAxis or Vector3.yAxis
			host.CFrame = CFrame.lookAt(position, position + direction, up)
			enable(showNow)
			local now = os.clock()
			for i, part in orbiters do
				local angle = now * (id == "Purple" and 4 or 2) + i * math.pi * 2 / 3
				part.CFrame = host.CFrame
					* CFrame.new(math.cos(angle) * 1.35, math.sin(angle) * 1.35, 0.2)
					* CFrame.Angles(0, 0, angle + math.pi / 4)
			end
			for _, t in ribbons do
				t.Lifetime = math.clamp(12 / math.max(velocity.Magnitude, 1), 0.1, 0.5)
			end
		end,
		stop = function()
			if finished then
				return
			end
			finished = true
			for _, p in emitters do
				p.Enabled = false
			end
			for _, t in ribbons do
				t.Enabled = false
			end
			for _, part in orbiters do
				TweenService:Create(part, TweenInfo.new(0.2), { Transparency = 1 }):Play()
			end
			if root then
				Debris:AddItem(root, 0.8)
			end
		end,
		destroy = function()
			finished = true
			if root then
				root:Destroy()
				root = nil
			end
		end,
	}
end

return Effects
