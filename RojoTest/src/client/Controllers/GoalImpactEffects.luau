--!strict
-- A torn white shock ring and sharp rays, built from native ribbons in the goal plane.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Goal = require(game.ReplicatedStorage.Shared.TrainingGoal)
local Effects = {}
local WHITE = Color3.new(1, 1, 1)
local MAX_BURSTS = 6

type Ribbon = { beam: Beam }
type Point = { attachment: Attachment, offset: Vector3, drift: Vector3 }
type Cache = { net: BasePart?, retryAt: number }

export type Context = {
	folder: Folder,
	enabled: () -> boolean,
}

function Effects.mount(context: Context)
	local folder = Instance.new("Folder")
	folder.Name = "GoalImpactEffects"
	folder.Parent = context.folder
	local cache: { [Instance]: Cache } = setmetatable({}, { __mode = "k" }) :: any
	local active: { Part } = {}
	local trackedLane: Instance? = nil
	local trackedStart: number? = nil
	local lastCycle = -1
	local alive = true

	local function burst(contact: Goal.Contact, seed: number?, boosted: boolean?)
		local camera = workspace.CurrentCamera
		if
			not alive
			or not context.enabled()
			or (camera and (camera.CFrame.Position - contact.position).Magnitude > 220)
		then
			return
		end
		for i = #active, 1, -1 do
			if not active[i].Parent then
				table.remove(active, i)
			end
		end
		while #active >= MAX_BURSTS do
			local oldest = table.remove(active, 1)
			if oldest then
				oldest:Destroy()
			end
		end
		local host = Instance.new("Part")
		host.Name = if boosted then "PurpleGoalShockwave" else "GoalShockwave"
		host.Anchored = true
		host.CanCollide, host.CanTouch, host.CanQuery = false, false, false
		host.CastShadow = false
		host.Transparency = 1
		host.Size = Vector3.one * 0.1
		host.CFrame = CFrame.lookAt(contact.position + contact.normal * 0.06, contact.position + contact.normal)
		local random = Random.new(((seed or math.random(1, 2147483646)) + 5701) % 2147483647)
		local radius = contact.radius * random:NextNumber(0.65, 1.3) * (if boosted then 1.18 else 1)
		local duration = if boosted then random:NextNumber(0.65, 0.78) else random:NextNumber(0.38, 0.62)
		local rotation = random:NextNumber(0, math.pi * 2)
		local stretch = Vector2.new(random:NextNumber(0.85, 1.25), random:NextNumber(0.85, 1.2))
		local incoming = host.CFrame:VectorToObjectSpace(contact.direction)
		local edge = host.CFrame:VectorToObjectSpace(contact.edge)
		local bias = Vector3.new(edge.X, edge.Y, 0) * 0.65 + Vector3.new(incoming.X, incoming.Y, 0) * 0.5
		if bias.Magnitude < 0.1 then
			bias = Vector3.new(math.cos(rotation), math.sin(rotation), 0) * 0.3
		end
		host:SetAttribute("ImpactScale", radius / contact.radius)
		host:SetAttribute("HitU", contact.hit.X)
		host:SetAttribute("HitV", contact.hit.Y)
		host:SetAttribute("SpreadX", bias.X)
		host:SetAttribute("SpreadY", bias.Y)
		local points: { Point } = {}
		local ribbons: { Ribbon } = {}
		local scatter = false
		local function point(angle: number, distance: number): Attachment
			angle += rotation
			local outward = Vector3.new(math.cos(angle) * stretch.X, math.sin(angle) * stretch.Y, 0)
			local offset = outward * distance * radius
			local drift = if scatter
				then (outward * 0.35 + bias) * radius * random:NextNumber(0.3, 0.8)
				else Vector3.zero
			local attachment = Instance.new("Attachment")
			attachment.Position = offset * 0.35
			attachment.Parent = host
			table.insert(points, { attachment = attachment, offset = offset, drift = drift })
			return attachment
		end
		local function ribbon(a: Attachment, b: Attachment, width: number, tapered: boolean?)
			local beam = Instance.new("Beam")
			beam.Name = if boosted then "PurpleShockRibbon" else "WhiteShockRibbon"
			beam.Attachment0, beam.Attachment1 = a, b
			beam.FaceCamera = true
			beam.Segments = 1
			beam.Width0 = width
			beam.Width1 = if tapered then 0 else width * 0.65
			beam.Color = if boosted
				then ColorSequence.new(Color3.fromRGB(215, 130, 255), Color3.fromRGB(145, 45, 245))
				else ColorSequence.new(WHITE)
			beam.Transparency = NumberSequence.new(0.08)
			beam.LightEmission, beam.LightInfluence = if boosted then 0.65 else 1, 0
			beam.Parent = host
			table.insert(ribbons, { beam = beam })
		end
		-- Two offset, interrupted rings preserve the rough hollow silhouette.
		for layer = 1, 2 do
			local ring: { Attachment } = {}
			for i = 0, 31 do
				local angle = i / 32 * math.pi * 2 + layer * 0.075
				local distance = (if layer == 1 then 1 else 0.88) + random:NextNumber(-0.065, 0.065)
				ring[i + 1] = point(angle, distance)
			end
			for i = 1, 32 do
				if (i + layer * 3) % 11 < 9 then
					ribbon(ring[i], ring[i % 32 + 1], if layer == 1 then 0.095 else 0.045)
				end
			end
		end
		scatter = true
		for i = 1, 8 do
			local angle = i / 8 * math.pi * 2 + random:NextNumber(-0.2, 0.2)
			local tip = point(angle + 0.035, random:NextNumber(1.2, 1.9))
			ribbon(point(angle - 0.09, 0.82), tip, 0.2, true)
			ribbon(tip, point(angle + 0.13, 0.99), 0.045)
			ribbon(point(angle + 0.2, 1.52), point(angle + 0.17, 1.78), 0.09, true)
		end
		local progress = Instance.new("NumberValue")
		progress.Parent = host
		local base = host.CFrame
		local changed = progress.Changed:Connect(function(t: number)
			if not alive or not context.enabled() then
				host:Destroy()
				return
			end
			local scale = 0.35 + 0.85 * (1 - (1 - t) ^ 3)
			local opacity = NumberSequence.new(0.08 + 0.92 * t ^ 1.3)
			for _, entry in points do
				entry.attachment.Position = entry.offset * scale + entry.drift * t
			end
			for _, entry in ribbons do
				entry.beam.Transparency = opacity
			end
			host.CFrame = base + contact.normal * t * 0.4 + base:VectorToWorldSpace(bias) * t * radius * 0.2
		end)
		host.Destroying:Once(function()
			changed:Disconnect()
		end)
		host.Parent = folder
		table.insert(active, host)
		TweenService:Create(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Value = 1 }):Play()
		Debris:AddItem(host, duration + 0.08)
	end

	return {
		training = function(
			lane: Instance,
			start: Vector3,
			finish: Vector3,
			elapsed: number,
			index: number,
			started: number,
			seed: number?,
			boosted: boolean?
		)
			if not alive then
				return
			end
			if lane ~= trackedLane or started ~= trackedStart then
				trackedLane, trackedStart, lastCycle = lane, started, -1
			end
			local entry = cache[lane]
			if not entry or (not entry.net and os.clock() >= entry.retryAt) or (entry.net and not entry.net.Parent) then
				local fresh: Cache = { net = Goal.net(lane), retryAt = os.clock() + 0.75 }
				entry = fresh
				cache[lane] = fresh
			end
			local net = entry.net
			if not net then
				return
			end
			local contact = Goal.contact(net, start, finish, index)
			if not contact then
				return
			end
			local cycle = math.floor(elapsed / Config.TrainingCycle)
			local phase = elapsed % Config.TrainingCycle
			if cycle > lastCycle and phase >= contact.phase then
				lastCycle = cycle
				-- Do not replay an old goal after a stalled frame, late snapshot or streaming.
				if phase - contact.phase < 0.2 then
					burst(contact, seed, boosted)
				end
			end
		end,
		clearTraining = function()
			trackedLane, trackedStart, lastCycle = nil, nil, -1
		end,
		destroy = function()
			alive = false
			folder:Destroy()
			table.clear(active)
			table.clear(cache)
		end,
	}
end

return Effects
