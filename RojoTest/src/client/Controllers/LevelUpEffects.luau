--!strict
-- One local celebration per confirmed increase, including multi-level rewards.
local RunService = game:GetService("RunService")
local LevelSound = require(game.ReplicatedStorage.Shared.LevelUpSound)

local LevelUp = {}
local COLORS = {
	Color3.fromRGB(255, 225, 66),
	Color3.fromRGB(255, 90, 137),
	Color3.fromRGB(78, 214, 255),
	Color3.fromRGB(154, 115, 255),
	Color3.fromRGB(114, 244, 136),
	Color3.fromRGB(255, 158, 65),
}
local FOV_DURATION = 0.75
local FOV_RISE = 0.14
local FOV_AMOUNT = 10
local COOLDOWN = 0.65
local MAX_PIECES = 384
local nextMount = 0

type Piece = {
	part: Part,
	origin: Vector3,
	velocity: Vector3,
	rotation: CFrame,
	spin: Vector3,
	age: number,
	lifetime: number,
}

export type Context = {
	player: Player,
	effectsFolder: Folder,
	snapshot: () -> any?,
	playSound: (string, number?, number?) -> (),
	blocked: () -> boolean,
}

function LevelUp.mount(context: Context)
	local folder = Instance.new("Folder")
	folder.Name = "LevelUpConfetti"
	folder.Parent = context.effectsFolder
	local pieces: { Piece } = {}
	local random = Random.new()
	local previousLevel: number? = nil
	local previousRebirths: number? = nil
	local previousTest: boolean? = nil
	local lastCelebration = -math.huge
	local pulseAge = FOV_DURATION
	local pulseStart = 0
	local alive = true
	local appliedCamera: Camera? = nil
	local appliedBase = 70
	local appliedFov = 70
	nextMount += 1
	local binding = "LevelUpCameraReset_" .. context.player.UserId .. "_" .. nextMount

	-- Remove only our FOV contribution before either camera controller runs.
	-- An external FOV change must never be restored to a stale value.
	local function clearPulse()
		local camera = appliedCamera
		if camera and camera.Parent and math.abs(camera.FieldOfView - appliedFov) < 0.0001 then
			camera.FieldOfView = appliedBase
		end
		appliedCamera = nil
	end
	RunService:BindToRenderStep(binding, Enum.RenderPriority.Camera.Value - 1, clearPulse)

	local function pulseStrength(): number
		if pulseAge >= FOV_DURATION then
			return 0
		end
		if pulseAge < FOV_RISE then
			local progress = pulseAge / FOV_RISE
			local eased = progress * progress * (3 - 2 * progress)
			return pulseStart + (1 - pulseStart) * eased
		end
		local progress = 1 - (pulseAge - FOV_RISE) / (FOV_DURATION - FOV_RISE)
		return progress * progress * (3 - 2 * progress)
	end

	local function reset()
		clearPulse()
		pulseAge = FOV_DURATION
		pulseStart = 0
		for _, piece in pieces do
			piece.part:Destroy()
		end
		table.clear(pieces)
	end
	local respawnConnection = context.player.CharacterRemoving:Connect(reset)

	local function burst(root: BasePart, gained: number)
		local count = 108 + math.min(gained - 1, 3) * 12
		while #pieces + count > MAX_PIECES do
			local oldest = table.remove(pieces, 1)
			if oldest then
				oldest.part:Destroy()
			end
		end
		for index = 1, count do
			local angle = index / count * math.pi * 2 + random:NextNumber(-0.15, 0.15)
			local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
			local origin = root.Position + direction * 0.8 + Vector3.new(0, random:NextNumber(0, 1.5), 0)
			local rotation = CFrame.Angles(
				random:NextNumber(0, math.pi),
				random:NextNumber(0, math.pi),
				random:NextNumber(0, math.pi)
			)
			local part = Instance.new("Part")
			part.Name = "Confetti"
			part.Size = Vector3.new(random:NextNumber(0.15, 0.24), random:NextNumber(0.28, 0.46), 0.025)
			part.Anchored = true
			part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
			part.CastShadow = false
			part.Material = Enum.Material.SmoothPlastic
			part.Color = COLORS[(index - 1) % #COLORS + 1]
			part.CFrame = CFrame.new(origin) * rotation
			part.Parent = folder
			table.insert(pieces, {
				part = part,
				origin = origin,
				velocity = direction * random:NextNumber(6, 11) + Vector3.new(0, random:NextNumber(11, 17), 0),
				rotation = rotation,
				spin = Vector3.new(random:NextNumber(-9, 9), random:NextNumber(-7, 7), random:NextNumber(-10, 10)),
				age = 0,
				lifetime = random:NextNumber(1.7, 2.2),
			})
		end
	end

	local function celebrate(gained: number, force: boolean?)
		local info = context.snapshot()
		if not alive or not info then
			return
		end
		local character = context.player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
			return
		end
		-- Every confirmed increase retriggers the zoom, even during the VFX cooldown.
		-- Start from the current strength so rapid levels never snap the FOV back.
		if info.data.settings.effects ~= false and not context.blocked() then
			pulseStart = pulseStrength()
			pulseAge = 0
		end
		local now = os.clock()
		if not force and now - lastCelebration < COOLDOWN then
			return
		end
		lastCelebration = now
		context.playSound(LevelSound.id, LevelSound.volume, LevelSound.speed)
		if info.data.settings.effects ~= false then
			burst(root, gained)
		end
	end

	return {
		observe = function(info: any)
			local level, rebirths, test = info.level, info.data.rebirths, info.adminTest == true
			local oldLevel = previousLevel
			local sameProgress = previousRebirths == rebirths and previousTest == test
			previousLevel, previousRebirths, previousTest = level, rebirths, test
			if oldLevel ~= nil and sameProgress and level > oldLevel then
				celebrate(level - oldLevel)
			end
		end,
		rebirth = function()
			-- Only called for the server's successful Rebirth effect.
			celebrate(1, true)
		end,
		-- Compose the pulse after the normal camera update without taking it over.
		frame = function(dt: number)
			if not alive then
				return
			end
			clearPulse()
			local snapshot = context.snapshot()
			local settings = snapshot and snapshot.data.settings
			if settings and settings.effects == false then
				reset()
				return
			end
			for index = #pieces, 1, -1 do
				local piece = pieces[index]
				piece.age += dt
				local age = piece.age
				if age >= piece.lifetime then
					piece.part:Destroy()
					table.remove(pieces, index)
				else
					local travel = (1 - math.exp(-age * 1.4)) / 1.4
					local position = piece.origin
						+ Vector3.new(
							piece.velocity.X * travel,
							piece.velocity.Y * age - 9 * age * age,
							piece.velocity.Z * travel
						)
						+ Vector3.new(math.sin(age * 8 + index) * 0.16 * age, 0, 0)
					piece.part.CFrame = CFrame.new(position)
						* piece.rotation
						* CFrame.Angles(piece.spin.X * age, piece.spin.Y * age, piece.spin.Z * age)
					piece.part.Transparency = math.clamp((age / piece.lifetime - 0.65) / 0.35, 0, 1)
				end
			end
			if not settings or context.blocked() then
				pulseAge = FOV_DURATION
				return
			end
			pulseAge = math.min(FOV_DURATION, pulseAge + dt)
			local camera = workspace.CurrentCamera
			if pulseAge < FOV_DURATION and camera then
				appliedCamera, appliedBase = camera, camera.FieldOfView
				appliedFov = math.max(1, appliedBase - FOV_AMOUNT * pulseStrength())
				camera.FieldOfView = appliedFov
			end
		end,
		destroy = function()
			alive = false
			RunService:UnbindFromRenderStep(binding)
			respawnConnection:Disconnect()
			reset()
			folder:Destroy()
		end,
	}
end

return LevelUp
