--!strict
-- Native violet/gold charge, embers and shock rings; bounded to the launch moment.
local Debris = game:GetService("Debris")
local Shapes = require(script.Parent.BallEffectShapes)
local Perfect = require(game.ReplicatedStorage.Shared.Core.PerfectKick)
local Aura = {}
local GOLD = Color3.fromRGB(255, 220, 86)
local VIOLET = Color3.fromRGB(179, 79, 255)
local active = 0

function Aura.new(count: number, direction: Vector3)
	local host: Part? = nil
	local flame: ParticleEmitter? = nil
	local sparks: ParticleEmitter? = nil
	local light: PointLight? = nil
	local orbits: { { node: Attachment, pose: CFrame, layer: number } } = {}
	local arcs: { Beam } = {}
	local motes: { Part } = {}
	local launched = false
	local ended = false
	local function destroy()
		if host then
			host:Destroy()
			host = nil
		end
		table.clear(orbits)
		table.clear(arcs)
		table.clear(motes)
	end
	local function build(position: Vector3)
		if active >= 8 then
			return
		end
		local root = Shapes.part(workspace, "PerfectKickAura", VIOLET)
		root.Transparency = 1
		root.Size = Vector3.one * 0.1
		root.Position = position
		root:SetAttribute("PerfectCount", count)
		host = root
		active += 1
		root.Destroying:Once(function()
			active -= 1
		end)
		local attachment = Instance.new("Attachment")
		attachment.Position = Vector3.new(0, 0, 0.85)
		attachment.Parent = root
		local fire = Instance.new("ParticleEmitter")
		fire.Name = "PerfectFlames"
		fire.Texture = "rbxasset://textures/particles/fire_main.dds"
		fire.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 249, 211)),
			ColorSequenceKeypoint.new(0.25, GOLD),
			ColorSequenceKeypoint.new(0.65, VIOLET),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(102, 29, 224)),
		})
		fire.LightEmission = 0.85
		fire.LightInfluence = 0
		fire.Rate = 24 + count * 8
		fire.Enabled = true
		fire.Lifetime = NumberRange.new(0.18, 0.36)
		fire.Speed = NumberRange.new(1, 4)
		fire.SpreadAngle = Vector2.new(35, 35)
		fire.EmissionDirection = Enum.NormalId.Back
		fire.Drag = 3
		fire.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(0.3, 2.5 + count * 0.35),
			NumberSequenceKeypoint.new(1, 0),
		})
		fire.Transparency = NumberSequence.new(0.1, 1)
		fire.Parent = attachment
		flame = fire
		local embers = fire:Clone()
		embers.Name = "PerfectEmbers"
		embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		embers.Color = ColorSequence.new(GOLD, VIOLET)
		embers.Rate = 14
		embers.Speed = NumberRange.new(5, 11)
		embers.Lifetime = NumberRange.new(0.2, 0.45)
		embers.SpreadAngle = Vector2.new(80, 80)
		embers.Size = NumberSequence.new(0.24, 0)
		embers.Parent = attachment
		sparks = embers
		local lamp = Instance.new("PointLight")
		lamp.Color = GOLD
		lamp.Range = 10
		lamp.Brightness = 1
		lamp.Shadows = false
		lamp.Parent = root
		light = lamp
		-- Texture-free orbit ribbons keep the charged silhouette clear around the ball.
		for layer = 1, 2 do
			local previous: Attachment? = nil
			for index = 0, 8 do
				local angle = index / 8 * 2 * math.pi
				local radial = Vector3.new(math.cos(angle), math.sin(angle), 0)
				local tangent = Vector3.new(-math.sin(angle), math.cos(angle), 0)
				local node = Instance.new("Attachment")
				node.Parent = root
				table.insert(orbits, {
					node = node,
					pose = CFrame.fromMatrix(radial * (1.55 + layer * 0.18), tangent, Vector3.zAxis, radial),
					layer = layer,
				})
				if previous then
					local beam = Instance.new("Beam")
					beam.Attachment0, beam.Attachment1 = previous, node
					beam.FaceCamera = true
					beam.Segments = 8
					beam.CurveSize0, beam.CurveSize1 = 0.46, 0.46
					beam.Width0, beam.Width1 = 0.10, 0.055
					beam.Color = ColorSequence.new(if layer == 1 then GOLD else VIOLET)
					beam.LightEmission = 0.85
					beam.LightInfluence = 0
					beam.Transparency = NumberSequence.new(0.12)
					beam.Parent = root
					table.insert(arcs, beam)
				end
				previous = node
			end
		end
		for index = 1, 6 do
			local mote = Shapes.part(root, "PerfectCinder", if index % 2 == 0 then GOLD else VIOLET)
			mote.Material = Enum.Material.Neon
			mote.Size = Vector3.new(0.10, 0.30, 0.10)
			table.insert(motes, mote)
		end
		Debris:AddItem(root, 4)
	end
	return {
		update = function(position: Vector3, elapsed: number, windup: number, enabled: boolean)
			if ended or count <= 0 then
				return
			end
			if not enabled then
				destroy()
				return
			end
			local age = elapsed - windup
			if age > 1.15 then
				ended = true
				destroy()
				return
			end
			local camera = workspace.CurrentCamera
			if not camera or (camera.CFrame.Position - position).Magnitude > 180 then
				destroy()
				return
			end
			if not host then
				build(position)
			end
			if not host or not flame or not sparks or not light then
				return
			end
			host.CFrame = CFrame.lookAt(position, position + direction)
			local charge = Perfect.charge(elapsed, windup)
			local fade = if age < 0 then 0 else math.clamp(age / 0.8, 0, 1)
			for _, orbit in orbits do
				local rotation = CFrame.Angles(if orbit.layer == 2 then 1.1 else 0, elapsed * 1.8, elapsed * 2)
				orbit.node.CFrame = rotation * orbit.pose
			end
			for _, arc in arcs do
				arc.Transparency = NumberSequence.new(0.12 + 0.88 * fade)
			end
			for index, mote in motes do
				local angle = index / 6 * 2 * math.pi + elapsed * 3
				local radius = 1.9 + (if age >= 0 then age * 4 else 0)
				mote.CFrame = host.CFrame
					* CFrame.new(math.cos(angle) * radius, math.sin(angle) * radius, math.sin(angle * 2) * 0.5)
					* CFrame.Angles(0, 0, angle)
				mote.Transparency = fade
			end
			light.Brightness = if age < 0 then 0.5 + charge * 2 else math.max(0, 3.5 - age * 3)
			flame.Rate = if age < 0 then 12 + charge * 24 else 44 * math.max(0, 1 - age)
			if age >= 0 and not launched then
				launched = true
				if age < 0.2 then
					flame:Emit(14 + count * 6)
					sparks:Emit(24 + count * 10)
					local burst = Shapes.part(workspace, "PerfectKickShockwave", GOLD)
					burst.Transparency = 1
					burst.Size = Vector3.one * 0.1
					burst.Position = position
					Shapes.ring(burst, position, direction, GOLD, 4 + count)
					Shapes.ring(burst, position, Vector3.yAxis, VIOLET, 3 + count)
					Debris:AddItem(burst, 0.65)
				end
			end
		end,
		destroy = destroy,
	}
end

return Aura
