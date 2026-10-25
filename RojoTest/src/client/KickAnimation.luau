--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Kick = {}
local shots = {}
local active = {}

-- Strip our last overlay before Animator evaluates the next walk/run pose.
-- Restore only a transform we still own, so other animation writers are respected.
local function restore(joints)
	for joint, entry in joints do
		if joint.Parent and entry.applied and joint.Transform:FuzzyEq(entry.applied, 0.00001) then
			joint.Transform = entry.base
		end
		entry.applied = nil
	end
end

RunService.PreAnimation:Connect(function()
	for _, joints in active do
		restore(joints)
	end
end)

local function envelope(phase)
	local windupEnd = Config.KickContact - 0.14
	if phase < windupEnd then
		return -0.8 * math.sin(phase / windupEnd * math.pi / 2), 0.7 * phase / windupEnd
	elseif phase < Config.KickContact then
		local alpha = (phase - windupEnd) / 0.14
		return -0.8 + 2.05 * math.sin(alpha * math.pi / 2), 0.7 * (1 - alpha)
	elseif phase < 0.85 then
		return 1.25 * (1 - (phase - Config.KickContact) / (0.85 - Config.KickContact)) ^ 2, 0
	end
	return 0, 0
end

function Kick.play(userId, started)
	shots[userId] = started
end

local function reset(character)
	local joints = active[character]
	if joints then
		restore(joints)
		active[character] = nil
	end
end

-- Support classic Motor6D and upgraded AnimationConstraint rigs after Animator evaluation.
RunService.PreSimulation:Connect(function()
	local now = workspace:GetServerTimeNow()
	local seen = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local hum = character and character:FindFirstChildOfClass("Humanoid")
		if not character or not hum or hum.Health <= 0 then
			continue
		end
		local phase
		local started = character:GetAttribute("TrainingStarted")
		if character:GetAttribute("TrainingLane") and started then
			phase = (now - started) % Config.TrainingCycle
		elseif shots[player.UserId] then
			phase = now - shots[player.UserId]
			if phase >= 0.9 then
				shots[player.UserId] = nil
				phase = nil
			end
		end
		if not phase then
			reset(character)
			continue
		end
		seen[character] = true
		if not active[character] then
			local joints = {}
			for _, joint in character:GetDescendants() do
				if joint:IsA("Motor6D") or joint:IsA("AnimationConstraint") then
					joints[joint] = { base = joint.Transform, applied = nil }
				end
			end
			active[character] = joints
		end
		local angle, knee = envelope(phase)
		local weight = math.clamp(math.abs(angle) / 1.25 + knee / 0.7, 0, 1)
		for joint, entry in active[character] do
			if not joint.Parent then
				continue
			end
			local name = joint.Name
			local offset: CFrame? = nil
			if name == "RightHip" then
				offset = CFrame.Angles(angle, 0, -0.06 * weight)
			elseif name == "Right Hip" then
				offset = CFrame.Angles(0, 0, angle)
			elseif name == "RightKnee" then
				offset = CFrame.Angles(-knee, 0, 0)
			elseif name == "Waist" or name == "RootJoint" then
				offset = CFrame.Angles(-angle * 0.12, -angle * 0.08, 0)
			elseif name == "LeftShoulder" then
				offset = CFrame.Angles(-angle * 0.4, 0, -0.2 * weight)
			elseif name == "RightShoulder" then
				offset = CFrame.Angles(angle * 0.35, 0, 0.2 * weight)
			elseif name == "Left Shoulder" then
				offset = CFrame.Angles(0, 0, angle * 0.3)
			elseif name == "Right Shoulder" then
				offset = CFrame.Angles(0, 0, -angle * 0.3)
			end
			if offset then
				entry.base = joint.Transform
				entry.applied = entry.base * offset
				joint.Transform = entry.applied
			end
		end
	end
	for character in active do
		if not seen[character] then
			reset(character)
		end
	end
end)
return Kick
