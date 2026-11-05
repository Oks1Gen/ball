-- Client-side motion and lighting for the Ocean Depths map.
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Presets = require(game.ReplicatedStorage.Shared.OceanAmbience)
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Wildlife = require(script.Parent.OceanWildlifeController)
local Atmosphere = require(script.Parent.OceanAtmosphereController)
local AmbientMath = require(game.ReplicatedStorage.Shared.Core.OceanAtmosphere)
local Controller: any = {}

function Controller:Init()
	self.wildlife = Wildlife
	self.wildlife:Init()
	self.atmosphere = Atmosphere
	self.atmosphere:Init()
	self.world = nil
	self.motions = {}
	self.pulses = {}
	self.elapsed = 0
	self.scanAt = 0
	self.nextUpdate = 0
	self.lighting = nil
end

local function anchorFor(world, node)
	local parent = node.Parent
	while parent and parent ~= world do
		local field = parent:FindFirstChild("Field")
		if field and field:IsA("BasePart") then
			return field
		end
		parent = parent.Parent
	end
	return Refs.kickZoneFloor(world) or world
end

local function frameOf(anchor: any): CFrame
	return if anchor:IsA("BasePart") then anchor.CFrame else anchor:GetPivot()
end

function Controller:Scan(world)
	self.wildlife:Scan(world)
	self.atmosphere:Scan(world)
	local existing = {}
	if self.world == world then
		for _, entry in self.motions do
			existing[entry.model] = entry
		end
	end
	self.world = world
	self.motions = {}
	self.pulses = {}
	for _, node in world:GetDescendants() do
		if node:IsA("Model") then
			local kind = node:GetAttribute("OceanMotion")
			if not kind and (node.Name == "FishSchool" or node.Name == "MantaRay") then
				kind = "School"
			end
			if kind then
				local anchor = anchorFor(world, node)
				local previous = existing[node]
				table.insert(
					self.motions,
					if previous and previous.anchor.Parent
						then previous
						else {
							model = node,
							kind = kind,
							anchor = anchor,
							origin = frameOf(anchor):ToObjectSpace(node:GetPivot()),
						}
				)
			end
		elseif node:IsA("BasePart") and node:GetAttribute("OceanPulse") then
			table.insert(self.pulses, {
				part = node,
				phase = node:GetAttribute("OceanPulse"),
				light = node:FindFirstChildWhichIsA("PointLight"),
			})
		end
	end
end

function Controller:RestoreLighting()
	if not self.lighting then
		return
	end
	for key, value in self.lighting.properties do
		Lighting[key] = value
	end
	for effect, enabled in self.lighting.effects do
		if effect.Parent then
			effect.Enabled = enabled
		end
	end
	for _, effect in self.lighting.atmospheres do
		effect.Parent = Lighting
	end
	self.lighting = nil
end

function Controller:ApplyLighting(index)
	if not self.lighting then
		local state = { properties = {}, effects = {}, atmospheres = {} }
		for _, key in
			{
				"Ambient",
				"OutdoorAmbient",
				"FogColor",
				"FogStart",
				"FogEnd",
				"ClockTime",
				"Brightness",
				"ExposureCompensation",
			}
		do
			state.properties[key] = Lighting[key]
		end
		for _, effect in Lighting:GetChildren() do
			if effect:IsA("PostEffect") and not effect:IsA("BlurEffect") then
				state.effects[effect] = effect.Enabled
				effect.Enabled = false
			elseif effect:IsA("Atmosphere") then
				table.insert(state.atmospheres, effect)
				effect.Parent = nil
			end
		end
		self.lighting = state
	end
	local p = Presets[index]
	local blend = 1 - math.exp(-0.1 / 0.85)
	Lighting.Ambient = Lighting.Ambient:Lerp(Color3.fromHex(p.ambient), blend)
	Lighting.OutdoorAmbient = Lighting.OutdoorAmbient:Lerp(Color3.fromHex(p.ambient), blend)
	Lighting.FogColor = Lighting.FogColor:Lerp(Color3.fromHex(p.fog), blend)
	Lighting.FogStart += (p.start - Lighting.FogStart) * blend
	Lighting.FogEnd += (p.finish - Lighting.FogEnd) * blend
	Lighting.ExposureCompensation += (p.exposure - Lighting.ExposureCompensation) * blend
	Lighting.Brightness = 2.05
	Lighting.ClockTime = 11.2
end

function Controller:Step(dt)
	self.wildlife:Step(dt)
	self.atmosphere:Step(dt)
	self.elapsed += dt
	if self.elapsed < self.nextUpdate then
		return
	end
	self.nextUpdate = self.elapsed + 0.1
	if self.elapsed >= self.scanAt then
		self.scanAt = self.elapsed + (if self.world then 3 else 0.6)
		local map = workspace:FindFirstChild("Map")
		local world = map and map:FindFirstChild("World2")
		if world and world:GetAttribute("OceanDepthsPreview") == true then
			self:Scan(world)
		else
			if self.world then
				self.atmosphere:Destroy()
				self.atmosphere:Init()
			end
			self.world = nil
			self.motions = {}
			self.pulses = {}
			self:RestoreLighting()
		end
	end
	local world = self.world
	if not world or not world.Parent then
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local first = Refs.field(world, 1)
	local fieldIndex = 1
	if not first then
		for index = 2, 8 do
			first = Refs.field(world, index)
			if first then
				fieldIndex = index
				break
			end
		end
	end
	if not first then
		self:RestoreLighting()
		return
	end
	local cameraPosition = camera.CFrame.Position
	local active = math.abs(cameraPosition.X - first.Position.X) < 250
	if active then
		local progress = first.Position.Z + (fieldIndex - 0.5) * first.Size.Z - cameraPosition.Z
		self:ApplyLighting(math.clamp(math.floor(progress / first.Size.Z) + 1, 1, 8))
	else
		self:RestoreLighting()
	end
	local pearlOpen = workspace:GetServerTimeNow() < (world:GetAttribute("OceanPearlOpenedUntil") or 0)
	for i, entry in self.motions do
		local m = entry.model
		if not m.Parent or not entry.anchor.Parent then
			continue
		end
		local origin = frameOf(entry.anchor) * entry.origin
		if (origin.Position - camera.CFrame.Position).Magnitude > 430 then
			continue
		end
		local phase = self.elapsed * 0.6 + i * 0.83
		local shift = CFrame.identity
		if entry.kind == "Kelp" then
			local flow = AmbientMath.current(self.elapsed)
			local ripple = math.sin(self.elapsed * 0.7 - origin.Position.Z * 0.018)
			shift = CFrame.Angles(ripple * 0.017, 0, ripple * 0.025 * (flow.X / 0.6))
		elseif entry.kind == "ShellValve" then
			local goal = if pearlOpen then -0.1 else -0.65
			entry.angle = (entry.angle or -0.65) + (goal - (entry.angle or -0.65)) * 0.38
			shift = CFrame.Angles(entry.angle, 0, 0)
			local pearl = m.Parent and m.Parent:FindFirstChild("HeartPearl")
			local light = pearl and pearl:FindFirstChildWhichIsA("PointLight")
			if light then
				light.Brightness += ((if pearlOpen then 8 else 2) - light.Brightness) * 0.35
			end
		elseif entry.kind == "School" then
			shift = CFrame.new(math.sin(phase * 0.3) * 10, math.sin(phase * 0.6) * 1.5, math.cos(phase * 0.3) * 5)
		else
			shift = CFrame.new(math.sin(phase) * 1.2, math.sin(phase * 0.7) * 0.9, 0)
				* CFrame.Angles(0, math.sin(phase * 0.6) * 0.04, 0)
		end
		m:PivotTo(origin * shift)
	end
	for _, entry in self.pulses do
		if not entry.part.Parent then
			continue
		end
		local a = (math.sin(self.elapsed * 2.4 - entry.phase) + 1) / 2
		entry.part.Transparency = 0.15 + 0.5 * a
		if entry.light then
			entry.light.Brightness = 0.15 + 0.55 * (1 - a)
		end
	end
end

function Controller:Start()
	self.connection = RunService.Heartbeat:Connect(function(dt)
		self:Step(dt)
	end)
end

return Controller
