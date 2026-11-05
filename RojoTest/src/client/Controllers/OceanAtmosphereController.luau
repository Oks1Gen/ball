-- Local soundscape and ambient effects, scoped to Ocean Depths.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Math = require(game.ReplicatedStorage.Shared.Core.OceanAtmosphere)
local Bank = require(game.ReplicatedStorage.Shared.OceanSoundBank)
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Controller: any = {}

function Controller:Init()
	self.world = nil
	self.entries = {}
	self.waterSurfaces = {}
	self.audio = {}
	self.clock = 0
	self.blend = 0
	self.budget = 0
	self.fieldPosition = nil
	self.fieldLength = nil
	self.stats = { emitters = 0, particles = 0, caustics = 0, playing = 0 }
end

function Controller:Scan(world)
	if self.world ~= world then
		self:Destroy()
		self:Init()
		self.world = world
	end
	local old = {}
	for _, e in self.entries do
		old[e.part] = e
	end
	self.entries = {}
	local lobby = world:FindFirstChild("Lobby")
	local environment = lobby and lobby:FindFirstChild("Environment")
	local roots = { environment and environment:FindFirstChild("OceanAtmosphere") }
	for i = 1, 8 do
		local f = Refs.field(world, i)
		if f then
			local zoneEnvironment = f.Parent:FindFirstChild("Environment")
			table.insert(roots, zoneEnvironment and zoneEnvironment:FindFirstChild("OceanAtmosphere"))
		end
	end
	for _, root in roots do
		if root then
			for _, p in root:GetDescendants() do
				if p:IsA("BasePart") then
					local entry = old[p]
						or {
							part = p,
							kind = p:GetAttribute("AmbientKind"),
							textures = {},
							emitters = {},
							index = root:GetAttribute("ZoneIndex") or 1,
						}
					if not old[p] then
						for _, n in p:GetDescendants() do
							if n:IsA("Texture") then
								table.insert(entry.textures, n)
							end
							if n:IsA("ParticleEmitter") then
								table.insert(entry.emitters, n)
							end
						end
					end
					table.insert(self.entries, entry)
				end
			end
		end
	end
	local backdrop = environment and environment:FindFirstChild("OpenWater")
	if backdrop then
		for _, n in backdrop:GetDescendants() do
			if n:IsA("Texture") and n.Name == "SurfaceRipples" and not self.waterSurfaces[n] then
				self.waterSurfaces[n] = { u = n.OffsetStudsU, v = n.OffsetStudsV }
			end
		end
	end
end

local function newSound(parent, name, entry, bus, spatial)
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = entry.id
	s.Volume = 0
	s.Looped = entry.looped
	s.SoundGroup = bus
	if spatial then
		s.RollOffMinDistance = 24
		s.RollOffMaxDistance = 165
		s.RollOffMode = Enum.RollOffMode.InverseTapered
	end
	local eq = Instance.new("EqualizerSoundEffect")
	eq.HighGain = -9
	eq.MidGain = -2
	eq.LowGain = 0
	eq.Parent = s
	s.Parent = parent
	return s
end

function Controller:Audio(active, weights, dt)
	local bus = SoundService:FindFirstChild("SkippingSounds")
	if not bus then
		return
	end
	if not self.audioFolder then
		self.audioFolder = Instance.new("Folder")
		self.audioFolder.Name = "OceanSoundscape"
		self.audioFolder.Parent = SoundService
		for _, role in { "Water", "Deep" } do
			local sound = newSound(self.audioFolder, role, Bank[role], bus, false)
			table.insert(self.audio, { sound = sound, role = role, index = 0, volume = Bank[role].volume, nextAt = 0 })
		end
	end
	local known = {}
	local retained = {}
	for _, e in self.audio do
		if e.sound.Parent then
			known[e.sound.Parent] = true
			table.insert(retained, e)
		else
			e.sound:Destroy()
		end
	end
	self.audio = retained
	for _, e in self.entries do
		if e.part.Name == "LocalSoundOrigin" and not known[e.part] then
			local role = ({ "Current", "Bubbles", "Wreck", "Deep", "Current", "Vent", "Deep", "Current" })[e.index]
			local sound = newSound(e.part, "OceanLocalAudio", Bank[role], bus, true)
			local reverb = Instance.new("ReverbSoundEffect")
			reverb.DecayTime = if e.index >= 4 then 2.4 else 1.4
			reverb.WetLevel = -20
			reverb.Parent = sound
			table.insert(self.audio, {
				sound = sound,
				role = role,
				index = e.index,
				volume = Bank[role].volume,
				nextAt = self.clock + 3 + e.index,
			})
		end
	end
	local playing = 0
	for _, e in self.audio do
		if not e.sound.Parent then
			continue
		end
		local weight = if e.index == 0
			then (if e.role == "Deep" then (weights[5] + weights[6] + weights[7] + weights[8]) * 0.75 else 1)
			else weights[e.index]
		local target = e.volume * self.blend * weight
		e.sound.Volume += (target - e.sound.Volume) * (1 - math.exp(-dt * 2.2))
		if e.sound.Looped then
			if e.sound.Volume > 0.002 and not e.sound.IsPlaying then
				e.sound:Play()
			end
			if e.sound.Volume < 0.001 then
				e.sound:Stop()
			end
		elseif active and self.blend > 0.5 and weight > 0.2 and self.clock >= e.nextAt and bus.Volume > 0 then
			e.sound:Play()
			e.nextAt = self.clock + 14 + e.index % 4 * 4
		end
		if e.sound.IsPlaying then
			playing += 1
		end
	end
	local music = SoundService:FindFirstChild("PlayfulTropicalHouse")
	if music then
		if self.music ~= music then
			self.music = music
			self.musicVolume = music.Volume
			self.musicEQ = Instance.new("EqualizerSoundEffect")
			self.musicEQ.Name = "OceanMuffling"
			self.musicEQ.Parent = music
		end
		music.Volume = self.musicVolume * (1 - self.blend * 0.65)
		if self.blend < 0.001 then
			music.Volume = self.musicVolume
		end
		self.musicEQ.Enabled = self.blend > 0.001
		self.musicEQ.HighGain = -14 * self.blend
		self.musicEQ.MidGain = -5 * self.blend
	end
	self.stats.playing = playing
end

function Controller:Step(dt)
	self.clock += dt
	self.budget += dt
	if self.budget < 1 / 20 then
		return
	end
	dt = math.min(self.budget, 0.2)
	self.budget = 0
	local world = self.world
	if not world or not world.Parent then
		return
	end
	local player = Players.LocalPlayer
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local first = Refs.field(world, 1)
	local camera = workspace.CurrentCamera
	if first then
		self.fieldPosition = first.Position
		self.fieldLength = first.Size.Z
	elseif not self.fieldPosition then
		for i = 2, 8 do
			local field = Refs.field(world, i)
			if field then
				self.fieldPosition = field.Position + Vector3.zAxis * ((i - 1) * field.Size.Z)
				self.fieldLength = field.Size.Z
				break
			end
		end
	end
	-- Streaming may unload Field1 in deep zones and after leaving the ocean.
	local origin, length = self.fieldPosition, self.fieldLength
	if not origin or not length or not camera then
		return
	end
	local active = root
		and math.abs(root.Position.X - origin.X) < 310
		and root.Position.Z < origin.Z + 570
		and root.Position.Z > origin.Z - 2800
	self.blend += ((if active then 1 else 0) - self.blend) * (1 - math.exp(-dt * 1.5))
	local progress = if root then (origin.Z + length / 2 - root.Position.Z) / length + 0.5 else 1
	local weights = Math.zoneWeights(progress)
	local hud = player.PlayerGui:FindFirstChild("SkippingHUD")
	local effects = not hud or hud:GetAttribute("ReducedMotion") ~= true
	local flow = Math.current(self.clock)
	-- Camera-local far enclosure remains available when Streaming omits distant end walls.
	if not self.horizon then
		self.horizon = Instance.new("Model")
		self.horizon.Name = "UnderwaterHorizon"
		for _, axis in { Vector3.xAxis, Vector3.yAxis, Vector3.zAxis } do
			for _, side in { -1, 1 } do
				local p = Instance.new("Part")
				p.Name = "FogBoundary"
				p.Size = Vector3.one * 1400
				if axis.X ~= 0 then
					p.Size = Vector3.new(0.1, 1400, 1400)
				elseif axis.Y ~= 0 then
					p.Size = Vector3.new(1400, 0.1, 1400)
				else
					p.Size = Vector3.new(1400, 1400, 0.1)
				end
				p.CFrame = CFrame.new(axis * side * 700)
				p.Anchored = true
				p.CanCollide = false
				p.CanTouch = false
				p.CanQuery = false
				p.CastShadow = false
				p:SetAttribute("PartRole", "Far fog enclosure")
				p.Parent = self.horizon
			end
		end
		self.horizon:PivotTo(CFrame.new())
	end
	local course = Refs.course(world)
	self.horizon.Parent = if active and course then course:FindFirstChild("Environment") else nil
	if active then
		self.horizon:PivotTo(CFrame.new(camera.CFrame.Position))
	end
	for _, p in self.horizon:GetChildren() do
		p.Color = game.Lighting.FogColor
	end
	for t, original in self.waterSurfaces do
		if t.Parent then
			t.OffsetStudsU = if active then self.clock * 0.85 else original.u
			t.OffsetStudsV = if active then self.clock * -0.28 else original.v
		end
	end
	local emitters, particles, caustics = 0, 0, 0
	for _, e in self.entries do
		local part = e.part
		if not part.Parent then
			continue
		end
		local distance = (part.Position - camera.CFrame.Position).Magnitude
		local visible = active and effects and distance < 180
		if e.kind == "Caustic" then
			local link = part:FindFirstChild("Receiver")
			local receiver = link and link.Value
			if receiver and (not e.receiver or not e.textures[1] or not e.textures[1].Parent) then
				for _, t in e.textures do
					if e.receiver then
						t:Destroy()
					else
						t.Transparency = 1
					end
				end
				e.textures = {}
				e.receiver = receiver
				for _, t in part:GetChildren() do
					if t:IsA("Texture") then
						local light = t:Clone()
						light.Name = "OceanCausticLight"
						light.ZIndex = 4 + #e.textures
						light.Parent = receiver
						table.insert(e.textures, light)
					end
				end
			end
			local bright = if e.index <= 4 then 1 else if e.index == 8 then 0.55 else 0.2
			for i, t in e.textures do
				t.OffsetStudsU = self.clock * (if i == 1 then 0.35 else -0.22) + part.Position.X * 0.01
				t.OffsetStudsV = self.clock * (if i == 1 then -0.23 else 0.17) + part.Position.Z * 0.01
				t.Transparency = if visible
					then 1 - (0.10 + math.sin(self.clock * 0.7 + part.Position.Z * 0.03) * 0.025) * bright / (if i
							== 1
						then 1
						else 1.5)
					else 1
			end
			if visible then
				caustics += 1
			end
		end
		for _, emitter in e.emitters do
			emitter.Enabled = visible
			emitter.Acceleration = if e.kind == "Bubbles"
				then Vector3.new(flow.X * 0.12, 0.25, flow.Z * 0.12)
				else flow * 0.14
			if visible then
				emitters += 1
				particles += emitter.Rate * emitter.Lifetime.Max
			else
				emitter:Clear()
			end
		end
	end
	self.stats.emitters, self.stats.particles, self.stats.caustics = emitters, particles, caustics
	self:Audio(active, weights, dt)
end

function Controller:Destroy()
	for _, e in self.entries do
		if e.receiver then
			for _, t in e.textures do
				t:Destroy()
			end
		end
		for _, emitter in e.emitters do
			if emitter.Parent then
				emitter.Enabled = false
				emitter:Clear()
			end
		end
	end
	for _, e in self.audio do
		e.sound:Destroy()
	end
	if self.audioFolder then
		self.audioFolder:Destroy()
		self.audioFolder = nil
	end
	if self.music and self.music.Parent then
		self.music.Volume = self.musicVolume
	end
	if self.musicEQ then
		self.musicEQ:Destroy()
	end
	for t, original in self.waterSurfaces do
		if t.Parent then
			t.OffsetStudsU, t.OffsetStudsV = original.u, original.v
		end
	end
	if self.horizon then
		self.horizon:Destroy()
		self.horizon = nil
	end
	self.audio = {}
	self.music = nil
	self.musicEQ = nil
end

return Controller
