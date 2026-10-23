--!strict
local Debris = game:GetService("Debris")
local Shapes = require(script.Parent.Parent.BallEffectShapes)
local Flame = {}
local GOLD = Color3.fromRGB(255, 186, 54)
local FIRE = Color3.fromRGB(255, 86, 24)

export type Handle = {
	update: (number, boolean) -> (number, number),
	kick: () -> (),
	hide: () -> (),
	destroy: () -> (),
}

function Flame.mount(model: Model): Handle
	local body = assert(model:FindFirstChildWhichIsA("BasePart", true), "Flame Cat has no body")
	local _, size = model:GetBoundingBox()
	local particles: { ParticleEmitter } = {}
	local roots: { Attachment } = {}
	local parts: { BasePart } = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			table.insert(parts, part)
			part.LocalTransparencyModifier = 1
		end
	end
	for i = 1, 2 do
		local root = Instance.new("Attachment")
		root.Name = "FlameCatAura" .. i
		local world = model:GetPivot() * CFrame.new((i == 1 and -1 or 1) * size.X * 0.3, -size.Y * 0.18, 0)
		root.CFrame = body.CFrame:ToObjectSpace(world)
		root.Parent = body
		roots[i] = root
		local embers = Instance.new("ParticleEmitter")
		embers.Name = "PetEmbers"
		embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		embers.Color = ColorSequence.new(GOLD, FIRE)
		embers.Rate = 4
		embers.Enabled = false
		embers.Speed = NumberRange.new(0.4, 1)
		embers.Acceleration = Vector3.new(0, 1.2, 0)
		embers.SpreadAngle = Vector2.new(30, 30)
		embers.Lifetime = NumberRange.new(0.4, 0.75)
		embers.Size = NumberSequence.new(0.16, 0)
		embers.LightEmission = 0.85
		embers.Transparency = NumberSequence.new(0.15, 1)
		embers.Parent = root
		table.insert(particles, embers)
		local fire = Instance.new("ParticleEmitter")
		fire.Name = "PetSmallFlames"
		fire.Texture = "rbxasset://textures/particles/fire_main.dds"
		fire.Color = ColorSequence.new(GOLD, FIRE)
		fire.Rate = 3
		fire.Enabled = false
		fire.Speed = NumberRange.new(0.2, 0.5)
		fire.Lifetime = NumberRange.new(0.2, 0.35)
		fire.Size = NumberSequence.new(0.55, 0)
		fire.LightEmission = 0.65
		fire.Transparency = NumberSequence.new(0.5, 1)
		fire.Parent = root
		table.insert(particles, fire)
	end
	local light = Instance.new("PointLight")
	light.Name = "FlameCatGlow"
	light.Color = FIRE
	light.Range = 4
	light.Brightness = 0.15
	light.Shadows = false
	light.Enabled = false
	light.Parent = roots[1]
	local born: number? = nil
	local kickedAt = -math.huge
	local show = false
	local destroyed = false
	local pulses: { Part } = {}
	local function clearPulses()
		for _, pulse in pulses do
			pulse:Destroy()
		end
		table.clear(pulses)
	end
	local function burst()
		for i = #pulses, 1, -1 do
			if not pulses[i].Parent then
				table.remove(pulses, i)
			end
		end
		for _, emitter in particles do
			emitter:Emit(emitter.Name == "PetEmbers" and 9 or 3)
		end
		local center = model:GetPivot().Position - Vector3.yAxis * size.Y * 0.25
		local host = Shapes.part(model, "PetFlamePulse", GOLD)
		table.insert(pulses, host)
		host.Transparency = 1
		host.Size = Vector3.one * 0.1
		host.Position = center
		Shapes.ring(host, center, Vector3.yAxis, GOLD, math.max(1.3, size.X * 0.8))
		Debris:AddItem(host, 0.65)
	end
	return {
		update = function(now: number, enabled: boolean): (number, number)
			if destroyed then
				return 0, 0
			end
			local first = born == nil
			born = born or now
			local age = math.max(0, now - (born :: number))
			local reveal = enabled and math.clamp(age / 0.35, 0, 1) or 1
			reveal = reveal * reveal * (3 - 2 * reveal)
			for _, part in parts do
				part.LocalTransparencyModifier = 1 - reveal
			end
			local camera = workspace.CurrentCamera
			local visible = enabled
				and (not camera or (camera.CFrame.Position - model:GetPivot().Position).Magnitude < 120)
			if show ~= visible then
				show = visible
				for _, emitter in particles do
					emitter.Enabled = visible
					if not visible then
						emitter:Clear()
					end
				end
				light.Enabled = visible
				if not visible then
					clearPulses()
				end
			end
			if first and show then
				burst()
			end
			local phase = math.clamp((now - kickedAt) / 0.65, 0, 1)
			local jump = enabled and math.sin(phase * math.pi) or 0
			light.Brightness = 0.15 + jump * 0.65 + math.sin(now * 4) * 0.025
			return -0.65 * (1 - reveal) + jump * 0.7, -jump * 0.18
		end,
		kick = function()
			if not destroyed and show and os.clock() - kickedAt > 0.4 then
				kickedAt = os.clock()
				burst()
			end
		end,
		hide = function()
			show = false
			clearPulses()
			for _, emitter in particles do
				emitter.Enabled = false
				emitter:Clear()
			end
			light.Enabled = false
			for _, part in parts do
				part.LocalTransparencyModifier = 1
			end
		end,
		destroy = function()
			destroyed = true
			clearPulses()
			for _, root in roots do
				root:Destroy()
			end
			for _, part in parts do
				if part.Parent then
					part.LocalTransparencyModifier = 0
				end
			end
		end,
	}
end

return Flame
