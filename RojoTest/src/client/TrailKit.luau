--!strict
-- Builders for the themed trails: plain property tables in, client-only VFX out.
-- Textures are public Creator Store ids harvested into the VfxForgeUltra library.
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Kit = {}

export type Props = { [string]: any }
export type Layer = {
	props: Props,
	count: number,
	delay: number?,
	-- Distance along the surface normal, in studs before scaling.
	lift: number?,
	-- Speed is scaled with the effect unless the layer opts out.
	fixedSpeed: boolean?,
}

function Kit.seq(...: number): NumberSequence
	local values = { ... }
	local points = {}
	for i = 1, #values, 2 do
		table.insert(points, NumberSequenceKeypoint.new(values[i], values[i + 1]))
	end
	return NumberSequence.new(points)
end

function Kit.range(min: number, max: number?): NumberRange
	return NumberRange.new(min, max or min)
end

-- Evenly spaced colours: the first one at 0, the last one at 1.
function Kit.colors(...: Color3): ColorSequence
	local list = { ... }
	if #list == 1 then
		return ColorSequence.new(list[1])
	end
	local points = {}
	for i, color in list do
		table.insert(points, ColorSequenceKeypoint.new((i - 1) / (#list - 1), color))
	end
	return ColorSequence.new(points)
end

function Kit.scaled(sequence: NumberSequence, factor: number): NumberSequence
	local points = {}
	for _, point in sequence.Keypoints do
		table.insert(points, NumberSequenceKeypoint.new(point.Time, point.Value * factor, point.Envelope * factor))
	end
	return NumberSequence.new(points)
end

function Kit.apply(instance: Instance, props: Props)
	for key, value in props do
		(instance :: any)[key] = value
	end
end

local DEFAULTS: Props = {
	Enabled = false,
	Rate = 0,
	LightEmission = 1,
	LightInfluence = 0,
	Rotation = NumberRange.new(0, 360),
	LockedToPart = false,
}

function Kit.emitter(parent: Instance, props: Props): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	Kit.apply(emitter, DEFAULTS)
	Kit.apply(emitter, props)
	emitter.Parent = parent
	return emitter
end

-- A layer lying flat on the surface (crack, rune, ripple): faces the normal.
function Kit.flat(props: Props): Props
	local result: Props = {
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection = Enum.NormalId.Top,
		Speed = NumberRange.new(0.001),
		SpreadAngle = Vector2.zero,
	}
	for key, value in props do
		result[key] = value
	end
	return result
end

-- An attachment whose Top direction is `normal`, so EmissionDirection.Top
-- shoots away from the surface (or along the shot for a kick). Built from
-- explicit axes: a lookAt frame rotated onto a straight-up normal makes
-- VelocityPerpendicular particles stop rendering.
function Kit.frame(host: BasePart, position: Vector3, normal: Vector3): Attachment
	local reference = math.abs(normal.Y) > 0.99 and Vector3.zAxis or Vector3.yAxis
	local world = CFrame.fromMatrix(position, normal:Cross(reference).Unit, normal)
	local attachment = Instance.new("Attachment")
	attachment.CFrame = host.CFrame:ToObjectSpace(world)
	attachment.Parent = host
	return attachment
end

-- Emits every layer once. Sizes, speeds and lifts follow `scale`; counts only
-- shrink a little so weak bounces stay readable. `locked` keeps the particles
-- on a moving host (the burst a ball carries away from a bounce).
function Kit.burst(
	host: BasePart,
	position: Vector3,
	normal: Vector3,
	layers: { Layer },
	scale: number,
	locked: boolean?
)
	local base = Kit.frame(host, position, normal)
	for _, layer in layers do
		local parent = base
		if layer.lift then
			parent = Kit.frame(host, position + normal * layer.lift * scale, normal)
		end
		local emitter = Kit.emitter(parent, layer.props)
		if locked then
			emitter.LockedToPart = true
		end
		emitter.Size = Kit.scaled(emitter.Size, scale)
		if not layer.fixedSpeed then
			emitter.Speed = NumberRange.new(emitter.Speed.Min * scale, emitter.Speed.Max * scale)
		end
		local count = math.max(1, math.round(layer.count * math.clamp(0.55 + scale * 0.45, 0.5, 1.15)))
		if layer.delay and layer.delay > 0 then
			task.delay(layer.delay, function()
				if emitter.Parent then
					emitter:Emit(count)
				end
			end)
		else
			emitter:Emit(count)
		end
	end
end

-- A short light pulse; the host's lifetime bounds it.
function Kit.flash(host: BasePart, color: Color3, range: number, brightness: number, duration: number)
	local light = Instance.new("PointLight")
	light.Name = "ImpactFlash"
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = false
	light.Parent = host
	TweenService:Create(light, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Brightness = 0,
	}):Play()
end

-- A vertical light column (Divine) or bolt (Electric) made of one Beam.
function Kit.pillar(host: BasePart, position: Vector3, normal: Vector3, height: number, props: Props, duration: number)
	local bottom = Instance.new("Attachment")
	bottom.CFrame = host.CFrame:ToObjectSpace(CFrame.new(position))
	bottom.Parent = host
	local top = Instance.new("Attachment")
	top.CFrame = host.CFrame:ToObjectSpace(CFrame.new(position + normal * height))
	top.Parent = host
	local beam = Instance.new("Beam")
	beam.Name = "ImpactPillar"
	beam.FaceCamera = true
	beam.Segments = 1
	beam.LightInfluence = 0
	beam.Attachment0, beam.Attachment1 = bottom, top
	Kit.apply(beam, props)
	beam.Parent = host
	TweenService:Create(beam, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Width0 = 0,
		Width1 = 0,
	}):Play()
end

-- Small anchored debris pieces thrown out along the surface (rocks, ice).
function Kit.chunks(
	host: BasePart,
	center: Vector3,
	normal: Vector3,
	count: number,
	scale: number,
	make: (index: number) -> BasePart
)
	local up = math.abs(normal.Y) > 0.99 and Vector3.zAxis or Vector3.yAxis
	local basis = CFrame.lookAt(center, center + normal, up)
	for i = 1, count do
		local angle = i / count * math.pi * 2 + math.random() * 0.6
		local outward = basis.RightVector * math.cos(angle) + basis.UpVector * math.sin(angle)
		local piece = make(i)
		piece.CFrame = CFrame.new(center) * CFrame.Angles(i, i * 2, i * 3)
		piece.Parent = host
		local reach = (2.2 + math.random() * 1.6) * scale
		local peak = center + outward * reach * 0.55 + normal * (1.4 + math.random()) * scale
		TweenService:Create(piece, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = CFrame.new(peak) * CFrame.Angles(i * 2, i * 3, i),
		}):Play()
		task.delay(0.22, function()
			if not piece.Parent then
				return
			end
			TweenService:Create(piece, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				CFrame = CFrame.new(center + outward * reach + normal * 0.1) * CFrame.Angles(i * 3, i, i * 2),
				Transparency = 1,
			}):Play()
		end)
		Debris:AddItem(piece, 0.6)
	end
end

return Kit
