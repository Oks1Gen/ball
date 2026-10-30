--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.GameConfig)
local Motion = require(Shared.ShotMotion)
local BallVisuals = require(Shared.BallVisuals)
local ShotFeedback = require(Shared.ShotFeedback)
local Zones = require(Shared.Core.ZoneProgression)
local BallEffects = require(script.Parent.BallEffects)
local Perfect = require(Shared.Core.PerfectKick)
local PerfectAura = require(script.Parent.PerfectKickAura)
local Flight = {}

-- Camera handover --------------------------------------------------------
-- Every scripted takeover has to give the camera back to the character. The
-- saved subject can be nil (the character was not there yet) and a camera
-- without a subject keeps the last scripted position for ever, so the
-- subject is always the character's Humanoid and the saved CFrame is only
-- restored when there is no character at all.
local HANDOFF_TIMEOUT = 2
local HANDOFF_POLL = 0.1
local handoverToken = 0

local function humanoidOf(player: Player?): Humanoid?
	if not player then
		return nil
	end
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		return nil
	end
	return humanoid :: Humanoid
end

-- Startup can capture Fixed before the player camera initializes. Neither
-- Fixed nor Scriptable can resume normal character following.
local function followType(saved: any): Enum.CameraType
	local cameraType = saved and saved.cameraType or Enum.CameraType.Custom
	if cameraType == Enum.CameraType.Scriptable or cameraType == Enum.CameraType.Fixed then
		return Enum.CameraType.Custom
	end
	return cameraType
end

-- A script takes the camera over: a pending handover must not attach a
-- subject behind the script's back.
function Flight.claimCamera()
	handoverToken += 1
end

-- Gives the camera back to the character. The subject is the character's
-- Humanoid; when the character is not there yet the subject is attached as
-- soon as it appears (bounded wait). The saved CFrame is only restored when
-- there is no character at all.
function Flight.releaseCamera(player: Player?, saved: any?, fov: number?)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	handoverToken += 1
	local token = handoverToken
	camera.CameraType = followType(saved)
	if fov then
		camera.FieldOfView = fov
	end
	local humanoid = humanoidOf(player)
	if humanoid then
		camera.CameraSubject = humanoid
		return
	end
	-- The character is gone: wait for the respawn and attach the subject as
	-- soon as it shows up.
	task.spawn(function()
		local deadline = os.clock() + HANDOFF_TIMEOUT
		while os.clock() < deadline do
			task.wait(HANDOFF_POLL)
			if token ~= handoverToken then
				return
			end
			local ready = humanoidOf(player)
			if ready then
				camera.CameraSubject = ready
				return
			end
		end
		if token ~= handoverToken then
			return
		end
		-- The character never came back: the camera keeps the frame it was
		-- released with instead of pointing at nothing.
		if saved then
			camera.CFrame = saved.cframe
		end
	end)
end

-- The camera returns to where the character is now: the stale frame the
-- throw started from would fight the camera controller.
local function returnFrame(player: Player?, fallback: CFrame): CFrame
	if not player then
		return fallback
	end
	local character = player.Character
	if not character then
		return fallback
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return fallback
	end
	return (root :: BasePart).CFrame * CFrame.new(0, 2, -8)
end

function Flight.start(info, context)
	local feedback = info.feedback or ShotFeedback.profile(0, 1, info.world)
	local timingQuality = feedback.timingQuality or 0
	local perfect = info.perfectCount or 0
	local cameraQuality = math.max(timingQuality, if perfect > 0 then 0.85 else 0)
	local windup = info.windup or Config.KickWindup
	local ball = BallVisuals.create(info.stone, Config.BallDiameter)
	ball.Name = "ThrownBall_" .. info.userId
	ball.Parent = workspace
	local trailDef = Config.find(Config.Trails, info.trail)
	local trailId = trailDef and trailDef.id or "None"
	local color = trailDef and trailDef.color or Color3.fromRGB(240, 255, 255)
	local camera = workspace.CurrentCamera
	local player = context.player or Players.LocalPlayer
	local saved = {
		cameraType = camera.CameraType,
		cframe = camera.CFrame,
		fov = camera.FieldOfView,
	}
	if context.me then
		Flight.claimCamera()
		camera.CameraType = Enum.CameraType.Scriptable
	end
	local started = info.startedAt or workspace:GetServerTimeNow()
	local startPosition = info.startPosition
		or Vector3.new(-116, 1.8, -0.3) + (info.world == 2 and Config.WorldOffset or Vector3.zero)
	ball:PivotTo(CFrame.new(startPosition))
	local direction = info.direction or -Vector3.zAxis
	local right = direction:Cross(Vector3.yAxis).Unit
	local waterY = info.waterY or 0.82
	local lastContact = 0
	local kicked = false
	local lastZone = 1
	local zoneCrossings: { any } = info.zoneCrossings or {}
	local zonePulseAt = -math.huge
	local baseFov = saved.fov
	local trailEffect = BallEffects.flight(trailId)
	local perfectAura = PerfectAura.new(perfect, direction)
	local previousPosition: Vector3? = nil
	local connection
	local returnTween
	saved.cancel = function()
		if connection then
			connection:Disconnect()
		end
		if returnTween then
			returnTween:Cancel()
		end
		ball:Destroy()
		trailEffect.destroy()
		perfectAura.destroy()
		if context.me then
			Flight.releaseCamera(player, saved, saved.fov)
		end
	end
	connection = RunService.RenderStepped:Connect(function(dt)
		if context.me and not context.active() then
			connection:Disconnect()
			ball:Destroy()
			trailEffect.destroy()
			perfectAura.destroy()
			return
		end
		local elapsed = workspace:GetServerTimeNow() - started
		local alpha = math.clamp((elapsed - windup) / info.duration, 0, 1)
		local position = Motion.position(startPosition, info.distance, alpha, direction)
		if context.me and elapsed >= windup then
			for _, crossing in zoneCrossings do
				if crossing.zone > lastZone and alpha >= crossing.alpha then
					lastZone = crossing.zone
					local age = elapsed - windup - crossing.alpha * info.duration
					if age < 0.25 then
						zonePulseAt = elapsed - age
						if context.zone then
							context.zone(crossing)
						end
					end
				end
			end
		end
		local velocity = previousPosition and (position - previousPosition) / math.max(dt, 1 / 240) or direction
		previousPosition = position
		ball:PivotTo(CFrame.new(position) * CFrame.Angles(alpha * 25, alpha * 12, 0))
		perfectAura.update(position, elapsed, windup, context.effects())
		trailEffect.update(
			position,
			velocity,
			elapsed >= windup and alpha < 1 and context.effects(),
			feedback.intensity
		)
		if elapsed >= windup and not kicked then
			kicked = true
			if context.effects() and elapsed - windup < 0.3 then
				BallEffects.kick(position, direction, color, feedback.intensity, trailId)
			end
			if context.me and context.kick then
				context.kick(feedback)
			end
		end
		local contacts = math.min(Motion.BounceCount, math.floor(alpha * Motion.BounceCount + 1e-6))
		for contact = lastContact + 1, contacts do
			local landing = Motion.position(startPosition, info.distance, contact / Motion.BounceCount, direction)
			-- Do not replay old impacts when joining a shot late or after a long frame.
			-- Alpha is clamped at one, so it cannot measure the age of a finished shot.
			if elapsed - Motion.contactTime(contact, info.duration, windup) < 0.25 then
				context.ripple(Vector3.new(landing.X, waterY, landing.Z), color, feedback.rippleScale)
				if context.effects() then
					BallEffects.bounce(landing, waterY, contact, feedback.intensity, trailId)
				end
				if context.bounce then
					context.bounce(landing, trailId, contact, feedback.intensity)
				end
			end
		end
		lastContact = contacts
		if context.me then
			context.distance(
				elapsed < windup and (if perfect > 0 then "PERFECT!" else "KICK!")
					or Config.format(info.distance * alpha)
						.. " m  •  ×"
						.. string.format("%.1f", Zones.multiplier(lastZone))
			)
			local blend = 1 - math.exp(-dt * (9 + 5 * feedback.intensity))
			local height = position.Y - startPosition.Y
			local cameraPosition = position
				+ right * 7
				- direction * (14 + 6 * feedback.intensity)
				+ Vector3.new(0, 5.5 - height * 0.35, 0)
			local sinceKick = elapsed - windup
			local shake = context.shake()
					and context.effects()
					and sinceKick >= 0
					and math.sin(sinceKick * (45 - 25 * cameraQuality)) * feedback.shakeAmplitude * math.exp(
						-sinceKick * (5 - 2.8 * cameraQuality)
					)
				or 0
			local kickDecay = if sinceKick >= 0 then math.exp(-sinceKick * 2.6) else 0
			local roll = if context.shake() and context.effects()
				then math.sin(math.max(0, sinceKick) * 18) * kickDecay * cameraQuality * 0.045
				else 0
			local target = CFrame.lookAt(
				cameraPosition + right * shake * 0.5 + Vector3.new(0, shake, 0),
				position + Vector3.new(0, 0.4, 0)
			) * CFrame.Angles(0, 0, roll)
			if perfect > 0 and elapsed < windup then
				-- Keep the full slow backswing visible before snapping into ball follow.
				target = saved.cframe
					* CFrame.new(0, 0, if context.effects() then -Perfect.charge(elapsed, windup) * 0.75 else 0)
			end
			camera.CFrame = camera.CFrame:Lerp(target, blend)
			local targetFov = if not context.effects()
				then saved.fov
				elseif elapsed < windup then (if perfect > 0
					then saved.fov - (7 + perfect * 2) * Perfect.charge(elapsed, windup)
					else 68 - timingQuality * 6)
				else feedback.fieldOfView
			local pulse = context.effects() and Zones.pulse(elapsed - zonePulseAt) or 0
			local timingPulse = if context.effects() and sinceKick >= 0
				then timingQuality * 22 * (1 - math.exp(-sinceKick * 14)) * kickDecay
				else 0
			baseFov += (targetFov - baseFov) * blend
			local perfectPulse = if context.effects() then Perfect.impactFov(sinceKick, perfect) else 0
			camera.FieldOfView = if context.effects()
				then math.clamp(baseFov + pulse + timingPulse + perfectPulse, 35, 105)
				else saved.fov
		end
		if alpha >= 1 then
			connection:Disconnect()
			trailEffect.stop()
			perfectAura.destroy()
			Debris:AddItem(ball, 0.6)
			if context.me then
				-- The camera flies back to the character, not to the stale
				-- frame the throw started from.
				local tween = TweenService:Create(
					camera,
					TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{ CFrame = returnFrame(player, saved.cframe), FieldOfView = saved.fov }
				)
				returnTween = tween
				tween:Play()
				task.delay(0.55, function()
					if context.active() then
						Flight.releaseCamera(player, saved)
						context.finish()
					end
				end)
			end
		end
	end)
	return saved
end
return Flight
