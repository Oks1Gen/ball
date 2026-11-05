-- Client-only cosmetic movement for the Ocean Depths preview.
local HttpService = game:GetService("HttpService")
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Swim = require(game.ReplicatedStorage.Shared.Core.OceanSwimming)
local Ambient = require(game.ReplicatedStorage.Shared.Core.OceanAtmosphere)
type Pose = { bone: Bone, axis: Vector3, slide: Vector3, amplitude: number, frequency: number, phase: number }
type Member = {
	model: Model,
	index: number,
	seed: number,
	offset: Vector3,
	velocity: Vector3,
	bones: { Pose },
	radius: number,
	cf: CFrame,
	scale: number,
	glow: Part?,
}
type Group = {
	model: Model,
	anchor: BasePart,
	origin: CFrame,
	rx: number,
	rz: number,
	speed: number,
	seed: number,
	memberLimit: number,
	memberScale: number,
	motionRate: number,
	clock: number,
	members: { Member },
	budget: number,
}
local Controller: any = {}

local function facing(position: Vector3, direction: Vector3, bank: number): CFrame
	local right = if direction.Magnitude > 0.001 then direction.Unit else Vector3.xAxis
	local up = Vector3.yAxis - right * right.Y
	if up.Magnitude < 0.01 then
		up = Vector3.zAxis
	end
	up = up.Unit
	return CFrame.fromMatrix(position, right, up, right:Cross(up)) * CFrame.Angles(bank, 0, 0)
end

function Controller:Init(context: any)
	self.swim = if context and context.swim then context.swim else Swim
	self.groups = {}
	self.world = nil
	self.stats = { active = 0, boneWrites = 0, blockedSteps = 0, steps = 0 }
	self.elapsed = 0
end

function Controller:Scan(world: Model)
	local old = {}
	if self.world == world then
		for _, g in self.groups do
			old[g.model] = g
		end
	end
	self.world = world
	self.groups = {}
	for _, model in world:GetDescendants() do
		if not model:IsA("Model") or not model:GetAttribute("WildlifeRoute") then
			continue
		end
		if old[model] then
			table.insert(self.groups, old[model])
			continue
		end
		local index = model:GetAttribute("AnchorIndex") :: number
		local anchor = if index == 0 then Refs.kickZoneFloor(world) else Refs.field(world, index)
		if not anchor then
			continue
		end
		local g: Group = {
			model = model,
			anchor = anchor,
			origin = model:GetAttribute("RouteOrigin") :: CFrame,
			rx = model:GetAttribute("RouteX") :: number,
			rz = model:GetAttribute("RouteZ") :: number,
			speed = model:GetAttribute("RouteSpeed") :: number,
			seed = model:GetAttribute("RouteSeed") :: number,
			memberLimit = (model:GetAttribute("MemberLimit") :: number?) or 8.8,
			memberScale = (model:GetAttribute("MemberMotionScale") :: number?) or 1,
			motionRate = (model:GetAttribute("MotionRate") :: number?) or 1,
			clock = 0,
			members = {},
			budget = 0,
		}
		for _, m in model:GetChildren() do
			if not m:IsA("Model") or not m:GetAttribute("MemberIndex") then
				continue
			end
			local bones: { Pose } = {}
			for _, recipe in HttpService:JSONDecode(m:GetAttribute("MotionRecipe") :: string) do
				local b = m:FindFirstChild(recipe.name, true)
				if b and b:IsA("Bone") then
					table.insert(bones, {
						bone = b,
						axis = Vector3.new(unpack(recipe.axis)),
						slide = Vector3.new(unpack(recipe.slide)),
						amplitude = recipe.amplitude,
						frequency = recipe.frequency,
						phase = recipe.phase,
					})
				end
			end
			table.insert(g.members, {
				model = m,
				index = m:GetAttribute("MemberIndex") :: number,
				seed = m:GetAttribute("PoseSeed") :: number,
				offset = m:GetAttribute("MemberOffset") :: Vector3,
				velocity = Vector3.zero,
				bones = bones,
				radius = (m:GetAttribute("NavigationRadius") :: number) * m:GetScale(),
				cf = m:GetPivot(),
				scale = m:GetScale(),
			})
		end
		table.sort(g.members, function(a, b)
			return a.index < b.index
		end)
		table.insert(self.groups, g)
	end
end

function Controller:Simulate(g: Group, dt: number)
	g.clock += dt
	local center: Vector3, tangent: Vector3 = self.swim.route(g.clock, g.rx, g.rz, g.speed, g.seed)
	local proposed: { Vector3 }, velocities: { Vector3 } = {}, {}
	for i, a in g.members do
		if #g.members == 1 then
			proposed[i] = Vector3.zero
			velocities[i] = Vector3.zero
			continue
		end
		local target: Vector3 = self.swim.member(g.clock * g.motionRate, a.index, g.seed) * g.memberScale
		local acceleration = (target - a.offset) * g.motionRate ^ 2 - a.velocity * (1.5 * g.motionRate)
		for j, b in g.members do
			if i == j then
				continue
			end
			local delta = a.offset - b.offset
			local distance = delta.Magnitude
			local separation = a.radius + b.radius + 3 * g.memberScale
			if distance > 0.001 and distance < separation then
				acceleration += delta.Unit * (separation - distance) * 5 * g.motionRate ^ 2
			end
			if distance < 16 * g.memberScale then
				acceleration += (b.velocity - a.velocity) * 0.03 * g.motionRate
			end
		end
		local velocity = a.velocity + acceleration * dt
		local maxSpeed = 4.5 * g.memberScale * g.motionRate
		if velocity.Magnitude > maxSpeed then
			velocity = velocity.Unit * maxSpeed
		end
		local position = a.offset + velocity * dt
		if position.Magnitude > g.memberLimit then
			position = position.Unit * g.memberLimit
			velocity = Vector3.zero
		end
		proposed[i] = position
		velocities[i] = velocity
	end
	local safe = true
	for i, a in g.members do
		for j = i + 1, #g.members do
			local b = g.members[j]
			if
				not self.swim.pairClear(
					a.offset,
					proposed[i],
					b.offset,
					proposed[j],
					a.radius + b.radius + 0.25 * g.memberScale
				)
			then
				safe = false
				break
			end
		end
		if not safe then
			break
		end
	end
	local origin = g.anchor.CFrame * g.origin
	for i, a in g.members do
		if safe then
			a.offset = proposed[i]
			a.velocity = velocities[i]
		else
			a.velocity = Vector3.zero
		end
		local position = origin:PointToWorldSpace(center + a.offset)
		local direction = origin:VectorToWorldSpace(tangent * g.speed + a.velocity)
		local kind = a.model:GetAttribute("WildlifeKind")
		if kind == "Jelly" or kind == "Hover" or kind == "Squid" then
			a.cf = origin.Rotation
					* CFrame.Angles(
						0,
						math.sin(g.clock * 0.18 + a.seed) * 0.12,
						math.sin(g.clock * 0.27 + a.seed) * 0.035
					)
				+ position
		else
			local target =
				facing(position, direction, math.sin(g.clock * g.speed / math.max(g.rx, g.rz, 1) + g.seed) * 0.13)
			if kind == "Manta" then
				target *= CFrame.Angles(0, -math.pi / 2, 0)
			end
			-- Assign the certified position exactly; interpolate orientation only.
			a.cf = a.cf.Rotation:Lerp(target.Rotation, 1 - math.exp(-dt * 5)) + position
		end
	end
	if not safe then
		self.stats.blockedSteps += 1
	end
	self.stats.steps += 1
end

function Controller:Step(dt: number)
	self.elapsed += dt
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local active, writes = 0, 0
	local player = game:GetService("Players").LocalPlayer
	local hud = player and player.PlayerGui:FindFirstChild("SkippingHUD")
	local effectsEnabled = not hud or hud:GetAttribute("ReducedMotion") ~= true
	for _, g in self.groups do
		if not g.model.Parent or not g.anchor.Parent then
			continue
		end
		local center = (g.anchor.CFrame * g.origin).Position
		local distance = (center - camera.CFrame.Position).Magnitude
		if distance > 460 then
			for _, a in g.members do
				if a.glow then
					local e = a.glow:FindFirstChildWhichIsA("ParticleEmitter")
					if e then
						e.Enabled = false
						e:Clear()
					end
				end
			end
			continue
		end
		local near = distance < 260
		g.budget += math.min(dt, 0.12)
		if not near and g.budget < 1 / 20 then
			continue
		end
		local remaining = math.min(g.budget, 0.12)
		g.budget = 0
		while remaining > 0 do
			local step = math.min(remaining, 1 / (30 * g.motionRate))
			self:Simulate(g, step)
			remaining -= step
		end
		for _, a in g.members do
			if not a.model.Parent then
				continue
			end
			a.model:PivotTo(a.cf)
			local kind = a.model:GetAttribute("WildlifeKind")
			local encounter = g.model:GetAttribute("Encounter")
			if kind == "Squid" then
				encounter = "Squid"
			end
			if encounter then
				local alpha = Ambient.envelope(
					g.clock,
					if encounter == "Manta" then 78 else 94,
					if encounter == "Manta" then 30 else 34,
					17
				)
				if not effectsEnabled then
					alpha = if encounter == "Manta" then 0 else 1
				end
				for _, p in a.model:GetChildren() do
					if p:IsA("BasePart") then
						p.LocalTransparencyModifier = 1 - alpha
					end
				end
			end
			if kind == "Jelly" then
				local light = a.model:FindFirstChildWhichIsA("PointLight", true)
				local wave = if effectsEnabled then Ambient.jellyWave(self.elapsed, -g.origin.Position.Z) else 0
				if light then
					light.Brightness = 0.2 + wave * 1.25
					light.Range = 10 + wave * 5
				end
				if not a.glow then
					local pack = game.ReplicatedStorage:FindFirstChild("OceanAmbientTemplates")
					local template = pack and pack:FindFirstChild("JellySpark")
					if template and template:IsA("Part") then
						local glow = template:Clone()
						glow.Name = "BellBioluminescence"
						glow.CFrame = a.cf * CFrame.new(0, 2, 0)
						glow.Parent = a.model
						a.glow = glow
					end
				end
				if a.glow then
					local e = a.glow:FindFirstChildWhichIsA("ParticleEmitter")
					if e then
						e.Rate = wave * 5
						e.Enabled = effectsEnabled and wave > 0.15
						if not effectsEnabled then
							e:Clear()
						end
					end
				end
			end
			active += 1
			for _, b in a.bones do
				local wave =
					self.swim.phase(g.clock * g.motionRate * (0.92 + a.index % 4 * 0.04), b.frequency, b.phase + a.seed)
				b.bone.Transform = CFrame.new(b.slide * wave * a.scale)
					* CFrame.fromAxisAngle(b.axis, b.amplitude * wave)
				writes += 1
			end
		end
	end
	self.stats.active, self.stats.boneWrites = active, writes
end

return Controller
