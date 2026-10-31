--!strict
-- Themed trail flights and kick bursts built from TrailThemes recipes. The Red
-- (Volcanic) flame flight stays in BallEffects; its kick is built there too.
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Shapes = require(script.Parent.BallEffectShapes)
local Kit = require(script.Parent.TrailKit)
local Themes = require(script.Parent.TrailThemes)
local Effects = {}
local active = 0
local MAX_FLIGHTS = 6
local RIBBON_DEPTH = 0.4
local SOURCE_OFFSET = Vector3.new(0, 0, 0.3)
-- Particles per stud stay as dense as at this speed, up to FILL_MAX times the
-- emitter's own rate; past it a fast ball would leave them 20 studs apart.
local FILL_SPEED = 40
local FILL_MAX = 5
-- Ribbons longer than this run past the camera and are seen end-on.
local RIBBON_REACH = 22
local STREAK = "rbxassetid://6660412891"
local WHITE = Color3.new(1, 1, 1)
local WAKE_TIME = 0.22
local WAKE_WIDTH = 1.3

function Effects.burst(parent: Instance, position: Vector3, normal: Vector3, id: string, strength: number)
	local theme = Themes[id]
	if not theme or not parent:IsA("BasePart") then
		return
	end
	parent:SetAttribute("TrailStyle", id)
	Shapes.ring(parent, position, normal, theme.color, 2.8 * strength)
	Kit.burst(parent, position, normal, theme.kick, strength)
end

export type Speed = {
	update: (position: Vector3, direction: Vector3, speed: number, pace: number) -> (),
	contact: (surface: Vector3, normal: Vector3, scale: number, pace: number) -> (),
	stop: () -> (),
}

-- What every trail (the Red flame included) adds on a fast shot: a comet tail
-- and streaks locked to the ball, the bounce burst the ball carries away and a
-- short glowing skid on the pitch. The host must look along the flight (+Z is
-- behind the ball); it owns and cleans up everything made here.
function Effects.speed(host: BasePart, id: string): Speed
	local theme = Themes[id]
	local color = theme and theme.color or WHITE
	local carry = theme and (theme.carry or theme.kick) or {}
	local head = Instance.new("Attachment")
	head.Name = "CometHead"
	head.Position = Vector3.new(0, 0, 0.2)
	head.Parent = host
	local tail = Instance.new("Attachment")
	tail.Name = "CometEnd"
	tail.Parent = host
	-- Solid and barely additive: a textured glowing streak vanishes on the bright pitch.
	local comet = Instance.new("Beam")
	comet.Name = "CometTail"
	comet.Attachment0, comet.Attachment1 = head, tail
	comet.FaceCamera = true
	comet.Segments = 1
	comet.Color = Kit.colors(color:Lerp(WHITE, 0.55), color)
	comet.LightEmission = 0.15
	comet.LightInfluence = 0
	comet.Transparency = Kit.seq(0, 0.15, 1, 1)
	comet.Width0, comet.Width1 = 1.7, 0.3
	comet.Enabled = false
	comet.Parent = host
	local streaks = Kit.emitter(head, {
		Name = "CometStreaks",
		Texture = STREAK,
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Rotation = Kit.range(90),
		LockedToPart = true,
		Color = Kit.colors(WHITE, color),
		LightEmission = 0.7,
		EmissionDirection = Enum.NormalId.Back,
		Speed = Kit.range(28, 42),
		SpreadAngle = Vector2.new(14, 14),
		Lifetime = Kit.range(0.12, 0.2),
		Size = Kit.seq(0, 0.4, 1, 0.1),
		Transparency = Kit.seq(0, 0.15, 1, 1),
		Enabled = true,
	})
	local wakeA, wakeB = Instance.new("Attachment"), Instance.new("Attachment")
	wakeA.Name, wakeB.Name = "WakeLeft", "WakeRight"
	wakeA.Parent, wakeB.Parent = host, host
	local wake = Instance.new("Trail")
	wake.Name = "PitchWake"
	wake.Attachment0, wake.Attachment1 = wakeA, wakeB
	wake.FaceCamera = false
	wake.Color = Kit.colors(color:Lerp(WHITE, 0.4), color)
	wake.LightEmission = 0.5
	wake.LightInfluence = 0
	wake.Transparency = Kit.seq(0, 0.2, 1, 1)
	wake.WidthScale = Kit.seq(0, 1, 1, 0.3)
	wake.Lifetime = 0.45
	wake.MinLength = 0.1
	wake.Enabled = false
	wake.Parent = host
	local wakeY, wakeUntil = 0, 0
	return {
		update = function(position: Vector3, direction: Vector3, speed: number, pace: number)
			local fast = pace > 0
			comet.Enabled = fast
			-- The comet stretches in the air and shrinks while the ball hangs at a bounce.
			tail.Position = Vector3.new(0, 0, math.clamp(speed * 0.035, 1.2, 10))
			streaks.Enabled = fast
			streaks.Rate = 30 * pace
			local flat = Vector3.new(direction.X, 0, direction.Z)
			local skidding = fast and os.clock() < wakeUntil and flat.Magnitude > 0.05
			if skidding then
				local ground = Vector3.new(position.X, wakeY, position.Z)
				local side = flat.Unit:Cross(Vector3.yAxis) * WAKE_WIDTH / 2
				wakeA.WorldPosition, wakeB.WorldPosition = ground - side, ground + side
			end
			wake.Enabled = skidding
		end,
		contact = function(surface: Vector3, normal: Vector3, scale: number, pace: number)
			if pace <= 0 then
				return
			end
			-- Starts at the ball, then rides with it: stays in the frame however fast.
			Kit.burst(host, host.Position, normal, carry, scale * (0.4 + 0.6 * pace), true)
			wakeY = surface.Y + 0.06
			wakeUntil = os.clock() + WAKE_TIME
			wake:Clear()
		end,
		stop = function()
			comet.Enabled = false
			streaks.Enabled = false
			wake.Enabled = false
		end,
	}
end

export type Filler = (from: Vector3, to: Vector3, dt: number) -> ()

-- Extra particles spread along the path covered this frame, so a fast ball
-- leaves as many particles per stud as a slow one. Locked emitters ride with
-- the ball and need none.
function Effects.filler(source: Attachment, emitters: { ParticleEmitter }): Filler
	local rest = source.Position
	local debts: { [ParticleEmitter]: number } = {}
	return function(from: Vector3, to: Vector3, dt: number)
		local extra = math.clamp((to - from).Magnitude / FILL_SPEED - dt, 0, dt * (FILL_MAX - 1))
		if extra <= 0 then
			return
		end
		for _, p in emitters do
			if not p.LockedToPart then
				local debt = (debts[p] or 0) + p.Rate * extra
				local count = math.floor(debt)
				debts[p] = debt - count
				for k = 1, count do
					source.WorldPosition = from:Lerp(to, (k - math.random()) / count)
					p:Emit(1)
				end
			end
		end
		source.Position = rest
	end
end

type RibbonState = { trail: Trail, a: Attachment, b: Attachment, spec: Themes.Ribbon }

function Effects.flight(id: string)
	local theme = Themes[id]
	local root: Part? = nil
	local ribbons: { RibbonState } = {}
	local emitters: { ParticleEmitter } = {}
	local orbiters: { BasePart } = {}
	local light: PointLight? = nil
	local speed: Speed? = nil
	local fill: Filler? = nil
	local fillFrom: Vector3? = nil
	local lastClock = os.clock()
	local visible = false
	local finished = false
	local nextPulse = 0
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
		for _, r in ribbons do
			r.trail.Enabled = value
			if not value then
				r.trail:Clear()
			end
		end
		for _, part in orbiters do
			part.Transparency = value and (theme.orbit :: Themes.Orbit).transparency or 1
		end
		if light then
			light.Enabled = value
		end
	end
	local function build(position: Vector3)
		if root or not theme or active >= MAX_FLIGHTS then
			return
		end
		local host = Shapes.part(workspace, "Ball" .. id .. "Flight", theme.color)
		host:SetAttribute("TrailStyle", id)
		host.Transparency = 1
		host.Size = Vector3.one * 0.1
		host.Position = position
		root = host
		active += 1
		host.Destroying:Once(function()
			active -= 1
		end)
		for i, spec in theme.ribbons do
			local a, b = Instance.new("Attachment"), Instance.new("Attachment")
			a.Position = Vector3.new(-spec.width / 2, 0, RIBBON_DEPTH)
			b.Position = Vector3.new(spec.width / 2, 0, RIBBON_DEPTH)
			a.Parent, b.Parent = host, host
			local t = Instance.new("Trail")
			t.Name = id .. "Ribbon" .. i
			t.Attachment0, t.Attachment1 = a, b
			t.Color = spec.color
			t.FaceCamera = true
			t.LightEmission = spec.lightEmission or 0.85
			t.LightInfluence = spec.lightInfluence or 0
			t.Transparency = spec.transparency or NumberSequence.new(0.2, 1)
			t.WidthScale = Kit.seq(0, 1, 1, 0)
			t.MinLength = 0.05
			t.Lifetime = 0.3
			if spec.texture then
				t.Texture = spec.texture
				t.TextureMode = Enum.TextureMode.Stretch
			end
			t.Enabled = false
			t.Parent = host
			table.insert(ribbons, { trail = t, a = a, b = b, spec = spec })
		end
		local trailSource = Instance.new("Attachment")
		trailSource.Name = "TrailSource"
		trailSource.Position = SOURCE_OFFSET
		trailSource.Parent = host
		for _, props in theme.emitters do
			table.insert(emitters, Kit.emitter(trailSource, props))
		end
		fill = Effects.filler(trailSource, emitters)
		speed = Effects.speed(host, id)
		local orbit = theme.orbit
		if orbit then
			for i = 1, orbit.count do
				local piece = Shapes.part(host, id .. "Orbiter", orbit.colors[(i - 1) % #orbit.colors + 1])
				piece.Material = orbit.material
				piece.Size = orbit.size
				piece.Transparency = 1
				table.insert(orbiters, piece)
			end
		end
		local glow = theme.glow
		if glow then
			local point = Instance.new("PointLight")
			point.Name = id .. "Glow"
			point.Color = glow.color
			point.Range = glow.range
			point.Brightness = glow.brightness
			point.Shadows = false
			point.Enabled = false
			point.Parent = host
			light = point
		end
	end
	return {
		update = function(position: Vector3, velocity: Vector3, show: boolean, intensity: number, pace: number?)
			if finished or not theme then
				return
			end
			local shotPace = pace or 0
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
			local dt = math.min(now - lastClock, 0.1)
			lastClock = now
			local from = fillFrom
			fillFrom = if showNow then position else nil
			local ballSpeed = math.max(velocity.Magnitude, 1)
			if speed then
				speed.update(position, direction, ballSpeed, if showNow then shotPace else 0)
			end
			if not showNow then
				return
			end
			if fill and from and shotPace > 0 then
				fill(from, position, dt)
			end
			local lifetime = math.min(math.clamp(12 / ballSpeed, 0.1, 0.5), RIBBON_REACH / ballSpeed)
				* (0.85 + intensity * 0.3)
			-- Wider ribbons read from the three-quarter camera of a fast shot.
			local widen = 1 + shotPace
			for _, r in ribbons do
				local spec = r.spec
				local center = Vector3.new(0, 0, RIBBON_DEPTH)
				if spec.radius then
					local angle = now * (spec.spin or 0) + (spec.phase or 0)
					center = Vector3.new(math.cos(angle) * spec.radius, math.sin(angle) * spec.radius, RIBBON_DEPTH)
				end
				if spec.jitter then
					center += Vector3.new((math.random() - 0.5) * 2, (math.random() - 0.5) * 2, 0) * spec.jitter
				end
				local half = Vector3.new(spec.width * widen / 2, 0, 0)
				r.a.Position = center - half
				r.b.Position = center + half
				r.trail.Lifetime = lifetime * (spec.life or 1)
			end
			local orbit = theme.orbit
			if orbit then
				for i, part in orbiters do
					local angle = now * orbit.speed + i * math.pi * 2 / #orbiters
					part.CFrame = host.CFrame
						* CFrame.new(math.cos(angle) * orbit.radius, math.sin(angle) * orbit.radius, 0.2)
						* CFrame.Angles(angle, angle * 0.5, angle + math.pi / 4)
				end
			end
			local glow = theme.glow
			if light and glow then
				light.Brightness = glow.brightness * (1 - glow.flicker * math.random())
			end
			local pulse = theme.pulse
			if pulse and now >= nextPulse then
				nextPulse = now + (theme.pulseEvery or 0.1)
				pulse(host, position, direction)
			end
		end,
		contact = function(surface: Vector3, normal: Vector3, scale: number, pace: number)
			if speed and visible and not finished then
				speed.contact(surface, normal, scale, pace)
			end
		end,
		stop = function()
			if finished then
				return
			end
			finished = true
			if speed then
				speed.stop()
			end
			for _, p in emitters do
				p.Enabled = false
			end
			for _, r in ribbons do
				r.trail.Enabled = false
			end
			for _, part in orbiters do
				TweenService:Create(part, TweenInfo.new(0.2), { Transparency = 1 }):Play()
			end
			if light then
				TweenService:Create(light, TweenInfo.new(0.2), { Brightness = 0 }):Play()
			end
			if root then
				Debris:AddItem(root, 1)
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
