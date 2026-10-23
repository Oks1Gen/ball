--!strict
-- Client-only decorations; never change the shot or create colliding debris.
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Shapes = require(script.Parent.BallEffectShapes)
local FlamePath = require(script.Parent.FlamePath)
local TrailEffects = require(script.Parent.TrailEffects)
local BallImpactEffects = require(script.Parent.BallImpactEffects)
local Effects = {}
local active = 0
local MAX_BURSTS = 24
local activeFlights = 0
local MAX_FLIGHTS = 6
local FIRE = Color3.fromRGB(255, 91, 20)
local GOLD = Color3.fromRGB(255, 197, 65)
local CREAM = Color3.fromRGB(255, 245, 183)
local TAIL_SEGMENTS = 6

local function anchor(position: Vector3): Part?
	local camera = workspace.CurrentCamera
	if active >= MAX_BURSTS or (camera and (camera.CFrame.Position - position).Magnitude > 320) then
		return nil
	end
	local part = Instance.new("Part")
	part.Name = "BallEffectBurst"
	part.Anchored = true
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	part.Transparency = 1
	part.Size = Vector3.one * 0.1
	part.Position = position
	part.Parent = workspace
	active += 1
	part.Destroying:Once(function()
		active -= 1
	end)
	Debris:AddItem(part, 1.3)
	return part
end

local function emitter(parent: Instance, texture: string, color: Color3): ParticleEmitter
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = texture
	particles.Color = ColorSequence.new(color)
	particles.Enabled = false
	particles.Rate = 0
	particles.Lifetime = NumberRange.new(0.2, 0.5)
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.Rotation = NumberRange.new(0, 360)
	particles.SpreadAngle = Vector2.new(45, 45)
	particles.Parent = parent
	return particles
end

function Effects.kick(position: Vector3, direction: Vector3, color: Color3, intensity: number, trailId: string)
	local part = anchor(position)
	if not part then
		return
	end
	part:SetAttribute("TrailStyle", trailId)
	if trailId ~= "Red" then
		if trailId == "None" then
			Shapes.ring(part, position, direction, color, 2.5 + intensity)
		else
			TrailEffects.burst(part, position, direction, trailId, 0.8 + intensity * 0.4)
		end
		return
	end
	local attachment = Instance.new("Attachment")
	attachment.CFrame = CFrame.lookAt(Vector3.zero, direction)
	attachment.Parent = part
	local sparks = emitter(attachment, "rbxasset://textures/particles/sparkles_main.dds", GOLD)
	sparks.EmissionDirection = Enum.NormalId.Front
	sparks.Speed = NumberRange.new(12, 23 + intensity * 9)
	sparks.Drag = 5
	sparks.Acceleration = Vector3.new(0, -12, 0)
	sparks.LightEmission = 0.85
	sparks.Orientation = Enum.ParticleOrientation.VelocityParallel
	sparks.Rotation = NumberRange.new(0)
	sparks.Squash = NumberSequence.new(-0.55)
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparks:Emit(math.round(12 + intensity * 8))
	Shapes.ring(part, position, direction, GOLD, 4 + intensity * 2)
	Shapes.ring(part, position - direction * 0.45, direction, FIRE, 2.8 + intensity)
	local flame = emitter(attachment, "rbxasset://textures/particles/fire_main.dds", FIRE)
	flame.Name = "KickFlame"
	flame.Color = ColorSequence.new(CREAM, FIRE)
	flame.EmissionDirection = Enum.NormalId.Front
	flame.Speed = NumberRange.new(8, 16)
	flame.LightEmission = 0.8
	flame.Size = NumberSequence.new(2.4, 0)
	flame:Emit(8)
	local flash = Instance.new("Part")
	flash.Name = "KickFlash"
	flash.Shape = Enum.PartType.Ball
	flash.Anchored = true
	flash.CanCollide, flash.CanTouch, flash.CanQuery = false, false, false
	flash.Material = Enum.Material.Neon
	flash.Color = color:Lerp(CREAM, 0.9)
	flash.Transparency = 0.3
	flash.Size = Vector3.one * 1.5
	flash.Position = position
	flash.Parent = part
	TweenService:Create(flash, TweenInfo.new(0.18), { Size = Vector3.one * 4, Transparency = 1 }):Play()
end

function Effects.bounce(position: Vector3, waterY: number, contact: number, intensity: number, trailId: string)
	-- Probe scenery, excluding characters and the decorative balls/effects.
	local params = RaycastParams.new()
	params.RespectCanCollide = true
	local excluded: { Instance } = {}
	for _, player in game:GetService("Players"):GetPlayers() do
		if player.Character then
			table.insert(excluded, player.Character)
		end
	end
	params.FilterDescendantsInstances = excluded
	local hit = workspace:Raycast(position + Vector3.yAxis * 1.5, -Vector3.yAxis * 7, params)
	local water = hit == nil or hit.Material == Enum.Material.Water
	local surface = hit and hit.Position or Vector3.new(position.X, waterY, position.Z)
	local normal = hit and hit.Normal or Vector3.yAxis
	local part = anchor(surface + normal * 0.12)
	if not part then
		return
	end
	local strength = math.clamp((1 - (contact - 1) / 8) * (0.75 + intensity * 0.4), 0.25, 1.2)
	part:SetAttribute("TrailStyle", trailId)
	BallImpactEffects.bounce(part, surface, normal, trailId, strength)
	local attachment = Instance.new("Attachment")
	attachment.CFrame = CFrame.lookAt(Vector3.zero, normal) * CFrame.Angles(-math.pi / 2, 0, 0)
	attachment.Parent = part
	local color = Color3.fromRGB(225, 246, 255)
	if not water then
		color = Color3.fromRGB(199, 183, 153)
		if hit and hit.Instance:IsA("BasePart") then
			color = hit.Instance.Color:Lerp(Color3.fromRGB(224, 211, 188), 0.65)
		end
	end
	part:SetAttribute("Surface", water and "Water" or "Dust")
	Shapes.ring(part, surface + normal * 0.15, normal, color, 2.5 * strength)
	if not water then
		Shapes.puffs(part, surface + normal * 0.3, normal, color, strength)
	end
	local cloud = emitter(attachment, "rbxasset://textures/particles/smoke_main.dds", color)
	cloud.EmissionDirection = Enum.NormalId.Top
	cloud.SpreadAngle = Vector2.new(75, 75)
	cloud.Speed = NumberRange.new(3 * strength, 9 * strength)
	cloud.Drag = 6
	cloud.Acceleration = normal * 1.5
	cloud.Lifetime = NumberRange.new(0.45, 0.85)
	cloud.Color = ColorSequence.new(color, color:Lerp(Color3.fromRGB(235, 228, 215), 0.3))
	cloud.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.08, 0.35),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	cloud.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.65 * strength),
		NumberSequenceKeypoint.new(0.4, 2.5 * strength),
		NumberSequenceKeypoint.new(1, 3.6 * strength),
	})
	cloud:Emit(math.round(8 + strength * 7))
	if water then
		local drops = emitter(attachment, "rbxasset://textures/particles/sparkles_main.dds", color)
		drops.Speed = NumberRange.new(5 * strength, 13 * strength)
		drops.Acceleration = Vector3.new(0, -30, 0)
		drops.Size = NumberSequence.new(0.2 * strength, 0)
		drops:Emit(math.round(7 + strength * 5))
	end
end

export type FlightHandle = {
	update: (Vector3, Vector3, boolean, number) -> (),
	stop: () -> (),
	destroy: () -> (),
}

function Effects.flight(trailId: string): FlightHandle
	if trailId ~= "Red" then
		return TrailEffects.flight(trailId)
	end
	local rig: Part? = nil
	local flames: { ParticleEmitter } = {}
	local beams: { Beam } = {}
	local trails: { Trail } = {}
	local attachments: { Attachment } = {}
	local tailRoots: { Attachment } = {}
	local light: PointLight? = nil
	local aura: Part? = nil
	local stopped = false
	local destroyed = false
	local wasVisible = false
	local previousTime = os.clock()
	local smoothedDirection: Vector3? = nil
	local smoothedLength = 7
	local path = FlamePath.new()
	local function build(position: Vector3)
		if rig or activeFlights >= MAX_FLIGHTS then
			return
		end
		local root = Shapes.part(workspace, "BallFireFlight", FIRE)
		root:SetAttribute("TrailStyle", "Red")
		root.Transparency = 1
		root.Size = Vector3.one * 0.1
		root.Position = position
		rig = root
		activeFlights += 1
		root.Destroying:Once(function()
			activeFlights -= 1
		end)
		-- Each attachment is placed on the world-space trail during update.
		for i = 1, TAIL_SEGMENTS + 1 do
			local a = Instance.new("Attachment")
			a.Name = "FireTail" .. i
			a.Position = i == 1 and Vector3.new(0, 0, 0.3) or Vector3.new(0, 0, 6)
			a.Parent = root
			attachments[i] = a
		end
		for i = 1, TAIL_SEGMENTS do
			local beam = Instance.new("Beam")
			beam.Name = ({ "OuterFlame", "HotCore", "CometGlow" })[i] or "FlameSegment" .. i
			beam.Attachment0, beam.Attachment1 = attachments[i], attachments[i + 1]
			beam.FaceCamera = true
			beam.Texture = "rbxasset://textures/particles/fire_main.dds"
			beam.TextureMode = Enum.TextureMode.Wrap
			beam.TextureLength = 4
			beam.TextureSpeed = i == 1 and 1.4 or -1.1
			beam.Segments = 20
			beam.Width0 = 2.8 * (1 - (i - 1) / TAIL_SEGMENTS) ^ 0.75
			beam.Width1 = 2.8 * (1 - i / TAIL_SEGMENTS) ^ 0.75
			beam.Color = i == 1 and ColorSequence.new(GOLD, FIRE) or ColorSequence.new(FIRE, Color3.fromRGB(175, 32, 6))
			beam.LightEmission = 0.9
			beam.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.18 + (i - 1) * 0.1),
				NumberSequenceKeypoint.new(1, i == TAIL_SEGMENTS and 1 or 0.18 + i * 0.1),
			})
			beam.Enabled = false
			beam.Parent = root
			beams[i] = beam
		end
		local headSource = Instance.new("Attachment")
		headSource.Name = "HeadFlameRoot"
		headSource.Position = Vector3.new(0, 0, 0.3)
		headSource.Parent = root
		local fire = emitter(headSource, "rbxasset://textures/particles/fire_main.dds", FIRE)
		fire.Name = "FlameTongues"
		fire.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, GOLD),
			ColorSequenceKeypoint.new(0.35, FIRE),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(185, 43, 10)),
		})
		fire.EmissionDirection = Enum.NormalId.Back
		fire.Rate = 32
		fire.Speed = NumberRange.new(4, 9)
		fire.SpreadAngle = Vector2.new(14, 14)
		fire.Lifetime = NumberRange.new(0.15, 0.3)
		fire.LightEmission = 0.65
		fire.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.65),
			NumberSequenceKeypoint.new(0.3, 2.3),
			NumberSequenceKeypoint.new(1, 0),
		})
		local embers = emitter(headSource, "rbxasset://textures/particles/sparkles_main.dds", GOLD)
		embers.Name = "FlyingEmbers"
		embers.Rate = 20
		embers.EmissionDirection = Enum.NormalId.Back
		embers.Speed = NumberRange.new(5, 13)
		embers.SpreadAngle = Vector2.new(28, 28)
		embers.Lifetime = NumberRange.new(0.25, 0.55)
		embers.Acceleration = Vector3.new(0, 3, 0)
		embers.LightEmission = 1
		embers.Orientation = Enum.ParticleOrientation.VelocityParallel
		embers.Rotation = NumberRange.new(0)
		embers.Squash = NumberSequence.new(-0.5)
		embers.Size = NumberSequence.new(0.25, 0)
		local tongues: { ParticleEmitter } = {}
		for i = 1, 3 do
			local tailRoot = Instance.new("Attachment")
			tailRoot.Name = "TailFlameRoot" .. i
			tailRoot.Position = Vector3.new(0, 0, i * 2)
			tailRoot.Parent = root
			tailRoots[i] = tailRoot
			local tail = emitter(tailRoot, "rbxasset://textures/particles/fire_main.dds", FIRE)
			tail.Name = "TailFlameTongues" .. i
			tail.Rate = 22 - i * 4
			tail.LockedToPart = false
			tail.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, i == 1 and GOLD or FIRE),
				ColorSequenceKeypoint.new(0.6, FIRE),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(164, 28, 6)),
			})
			tail.EmissionDirection = Enum.NormalId.Back
			tail.Speed = NumberRange.new(1, 3)
			tail.Lifetime = NumberRange.new(0.25, 0.4)
			tail.LightEmission = 1
			tail.Brightness = 2
			tail.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.05),
				NumberSequenceKeypoint.new(0.6, 0.25),
				NumberSequenceKeypoint.new(1, 1),
			})
			tail.SpreadAngle = Vector2.new(11, 11)
			local size = 3.1 - i * 0.55
			tail.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, size * 0.55),
				NumberSequenceKeypoint.new(0.3, size),
				NumberSequenceKeypoint.new(1, 0),
			})
			tongues[i] = tail
		end
		local smoke = emitter(headSource, "rbxasset://textures/particles/smoke_main.dds", Color3.fromRGB(123, 91, 77))
		smoke.Name = "WarmSmoke"
		smoke.Rate = 7
		smoke.EmissionDirection = Enum.NormalId.Back
		smoke.Speed = NumberRange.new(2, 4)
		smoke.Lifetime = NumberRange.new(0.25, 0.4)
		smoke.Size = NumberSequence.new(0.7, 2)
		smoke.Transparency = NumberSequence.new(0.8, 1)
		flames = { fire, embers, smoke }
		for _, tongue in tongues do
			table.insert(flames, tongue)
		end
		local left = Instance.new("Attachment")
		left.Position = Vector3.new(-0.55, 0, 0.5)
		left.Parent = root
		local right = Instance.new("Attachment")
		right.Position = Vector3.new(0.55, 0, 0.5)
		right.Parent = root
		local trail = Instance.new("Trail")
		trail.Name = "EmberRibbon"
		trail.Texture = "rbxasset://textures/particles/fire_main.dds"
		trail.Attachment0, trail.Attachment1 = left, right
		trail.FaceCamera = true
		trail.LightEmission = 0.85
		trail.Color = ColorSequence.new(GOLD, FIRE)
		trail.WidthScale = NumberSequence.new(1, 0)
		trail.Transparency = NumberSequence.new(0.45, 1)
		trail.Lifetime = 0.18
		trail.Enabled = false
		trail.Parent = root
		trails = { trail }
		local glow = Instance.new("PointLight")
		glow.Name = "FireAura"
		glow.Color = FIRE
		glow.Range = 7
		glow.Brightness = 0.45
		glow.Shadows = false
		glow.Enabled = false
		glow.Parent = root
		light = glow
		local shell = Shapes.part(root, "FireAuraShell", GOLD)
		shell.Shape = Enum.PartType.Ball
		shell.Material = Enum.Material.Neon
		shell.Size = Vector3.one * 2.35
		shell.Transparency = 0.97
		aura = shell
	end
	local function enabled(value: boolean)
		if value == wasVisible then
			return
		end
		wasVisible = value
		for _, x in flames do
			x.Enabled = value
			if not value then
				x:Clear()
			end
		end
		for _, x in beams do
			x.Enabled = value
		end
		for _, x in trails do
			x.Enabled = value
			if not value then
				x:Clear()
			end
		end
		if light then
			light.Enabled = value
		end
		if aura then
			aura.Transparency = value and 0.97 or 1
		end
	end
	return {
		update = function(position: Vector3, velocity: Vector3, show: boolean, intensity: number)
			if destroyed or stopped then
				return
			end
			local camera = workspace.CurrentCamera
			local visible = show and (not camera or (camera.CFrame.Position - position).Magnitude < 200)
			if visible then
				build(position)
			end
			local root = rig
			if not root then
				return
			end
			enabled(visible)
			if not visible then
				path.clear()
				return
			end
			local speed = velocity.Magnitude
			local direction = speed > 0.05 and velocity.Unit or -Vector3.zAxis
			local now = os.clock()
			local blend = 1 - math.exp(-math.min(now - previousTime, 0.1) * 24)
			previousTime = now
			local previous = smoothedDirection
			if previous and previous:Dot(direction) > -0.8 then
				direction = previous:Lerp(direction, blend).Unit
			end
			smoothedDirection = direction
			root.CFrame = CFrame.lookAt(position, position + direction)
			if aura then
				aura.CFrame = root.CFrame
				aura.Size = Vector3.one * (2.32 + math.sin(now * 8) * 0.035)
			end
			local length = math.clamp(7 + speed * 0.065 + intensity * 3, 7, 16)
			smoothedLength += (length - smoothedLength) * blend
			length = smoothedLength
			path.push(position)
			for i, attachment in attachments do
				local point, tangent = path.sample(position, length * (i - 1) / TAIL_SEGMENTS, -direction)
				local up = math.abs(tangent.Y) > 0.95 and Vector3.zAxis or Vector3.yAxis
				local frame = CFrame.fromMatrix(point, tangent, up:Cross(tangent).Unit)
				attachment.CFrame = root.CFrame:ToObjectSpace(frame)
			end
			for i, beam in beams do
				local span = (attachments[i + 1].WorldPosition - attachments[i].WorldPosition).Magnitude
				beam.CurveSize0 = span / 3
				beam.CurveSize1 = span / 3
				beam.Enabled = span > 0.05
			end
			for i, tailRoot in tailRoots do
				local point, tangent = path.sample(position, length * i * 0.23, -direction)
				local up = math.abs(tangent.Y) > 0.95 and Vector3.zAxis or Vector3.yAxis
				tailRoot.CFrame = root.CFrame:ToObjectSpace(CFrame.lookAt(point, point - tangent, up))
			end
			if light then
				light.Brightness = 0.45 + math.sin(now * 8) * 0.05
			end
			trails[1].Lifetime = math.clamp(10 / math.max(speed, 1), 0.08, 0.4)
		end,
		stop = function()
			if stopped or destroyed then
				return
			end
			stopped = true
			-- Stop emission, but let existing embers and ribbons finish naturally.
			for _, particles in flames do
				particles.Enabled = false
			end
			for _, trail in trails do
				trail.Enabled = false
			end
			for _, beam in beams do
				TweenService:Create(beam, TweenInfo.new(0.18), { Width0 = 0, Width1 = 0 }):Play()
			end
			if light then
				TweenService:Create(light, TweenInfo.new(0.2), { Brightness = 0 }):Play()
			end
			if aura then
				TweenService:Create(aura, TweenInfo.new(0.18), { Transparency = 1 }):Play()
			end
			if rig then
				Debris:AddItem(rig, 0.6)
			end
		end,
		destroy = function()
			destroyed = true
			if rig then
				rig:Destroy()
				rig = nil
			end
		end,
	}
end

return Effects
