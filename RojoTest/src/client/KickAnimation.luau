--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Motion = require(game.ReplicatedStorage.Shared.Core.KickMotion)
local Perfect = require(game.ReplicatedStorage.Shared.Core.PerfectKick)
local Kick = {}
local shots = {}
local active = {}
local rigs: { [Model]: any } = {}

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

local function angles(x: number, y: number?, z: number?): CFrame
	return CFrame.Angles(math.rad(x), math.rad(y or 0), math.rad(z or 0))
end

local function rigFor(character: Model, humanoid: Humanoid): any
	local rig: any = { bindings = {}, r15 = humanoid.RigType == Enum.HumanoidRigType.R15 }
	for _, joint in character:GetDescendants() do
		if joint:IsA("Motor6D") then
			rig.bindings[joint.Name] = { c0 = joint.C0, c1 = joint.C1 }
		elseif joint:IsA("AnimationConstraint") and joint.Attachment0 and joint.Attachment1 then
			rig.bindings[joint.Name] = { c0 = joint.Attachment0.CFrame, c1 = joint.Attachment1.CFrame }
		end
	end
	if rig.r15 then
		local b = rig.bindings
		local root, hip, knee, ankle = b.Root or b.RootJoint, b.LeftHip, b.LeftKnee, b.LeftAnkle
		if root and hip and knee and ankle then
			rig.root = root
			local pelvis = root.c0 * root.c1:Inverse()
			local upper = pelvis * hip.c0 * hip.c1:Inverse()
			local lower = upper * knee.c0 * knee.c1:Inverse()
			rig.plantedAnkle = lower * ankle.c0
			rig.upperBone = (hip.c1:Inverse() * knee.c0).Position
			rig.lowerBone = (knee.c1:Inverse() * ankle.c0).Position
			rig.scale = (rig.upperBone.Magnitude + rig.lowerBone.Magnitude) / 2
		end
	end
	return rig
end

local function between(from: Vector3, to: Vector3): CFrame
	local a, b = from.Unit, to.Unit
	local axis, dot = a:Cross(b), math.clamp(a:Dot(b), -1, 1)
	if axis.Magnitude < 0.00001 then
		return if dot > 0 then CFrame.identity else CFrame.fromAxisAngle(Vector3.xAxis, math.pi)
	end
	return CFrame.fromAxisAngle(axis.Unit, math.acos(dot))
end

-- Two-bone IK keeps the support foot planted while the pelvis shifts and turns.
-- Everything is root-local: the physics root and the player's movement stay untouched.
local function plant(rig: any, rootPose: CFrame, poses: { [string]: CFrame })
	if not rig.plantedAnkle then
		return
	end
	local hip, knee, ankle = rig.bindings.LeftHip, rig.bindings.LeftKnee, rig.bindings.LeftAnkle
	local pelvis = rig.root.c0 * rootPose * rig.root.c1:Inverse()
	local hipFrame = pelvis * hip.c0
	local target = rig.plantedAnkle.Position
	local delta = hipFrame:PointToObjectSpace(target)
	local u, l = rig.upperBone.Magnitude, rig.lowerBone.Magnitude
	local distance = math.clamp(delta.Magnitude, math.abs(u - l) + 0.0001, u + l - 0.0001)
	local direction = delta.Unit
	local forward = Vector3.new(0, 0, -1)
	local bend = forward - direction * forward:Dot(direction)
	if bend.Magnitude < 0.0001 then
		bend = Vector3.xAxis
	end
	local along = (u * u - l * l + distance * distance) / (2 * distance)
	local height = math.sqrt(math.max(0, u * u - along * along))
	poses.LeftHip = between(rig.upperBone, direction * along + bend.Unit * height)
	local upper = hipFrame * poses.LeftHip * hip.c1:Inverse()
	local kneeFrame = upper * knee.c0
	poses.LeftKnee = between(rig.lowerBone, kneeFrame:PointToObjectSpace(target))
	local lower = kneeFrame * poses.LeftKnee * knee.c1:Inverse()
	poses.LeftAnkle = (lower * ankle.c0).Rotation:Inverse() * rig.plantedAnkle.Rotation
end

local function pose(rig: any, p: { [string]: number }): { [string]: CFrame }
	local poses: { [string]: CFrame } = {}
	if rig.r15 then
		local scale = rig.scale or 1
		local rootPose = CFrame.new(p.x * scale, p.y * scale, p.z * scale) * angles(0, p.yaw, p.roll)
		if rig.plantedAnkle then
			-- Lean the entire chain about the planted ankle, keeping the support leg long.
			local pivot = rig.root.c0:PointToObjectSpace(rig.plantedAnkle.Position)
			rootPose = CFrame.new(pivot) * angles(0, 0, p.lean) * CFrame.new(-pivot) * rootPose
		end
		poses.Root, poses.RootJoint = rootPose, rootPose
		poses.RightHip = angles(p.hip, -p.yaw * 0.25, 4 * p.weight)
		poses.RightKnee, poses.RightAnkle = angles(p.knee), angles(p.ankle)
		poses.Waist = angles(p.chest, p.twist, p.side)
		poses.Neck = angles(p.head, -p.yaw * 0.35 - p.twist * 0.6, -(p.lean + p.side + p.roll) * 0.45)
		poses.LeftShoulder = angles(p.leftArm, -5 * p.weight, -p.leftSpread)
		poses.RightShoulder = angles(p.rightArm, 6 * p.weight, p.rightSpread)
		poses.LeftElbow, poses.RightElbow = angles(p.leftElbow), angles(p.rightElbow)
		poses.LeftWrist, poses.RightWrist = CFrame.identity, CFrame.identity
		plant(rig, rootPose, poses)
	else
		-- R6 has no knee joints; preserve its support leg and adapt to its joint axes.
		local rotations: { [string]: CFrame } = {
			["Right Hip"] = angles(p.hip * 0.8),
			["Left Hip"] = CFrame.identity,
			["RootJoint"] = angles(p.chest * 0.35, p.yaw * 0.4, (p.lean + p.side) * 0.45),
			["Left Shoulder"] = angles(p.leftArm, 0, -p.leftSpread),
			["Right Shoulder"] = angles(p.rightArm, 0, p.rightSpread),
			["Neck"] = angles(p.head, -p.yaw * 0.4),
		}
		for name, rotation in rotations do
			local bind = rig.bindings[name]
			if bind then
				local basis = bind.c0.Rotation
				poses[name] = basis:Inverse() * rotation * basis
			end
		end
	end
	return poses
end

function Kick.play(userId, started, perfectCount: number?)
	shots[userId] = { started = started, perfect = perfectCount or 0 }
end

local function reset(character)
	local joints = active[character]
	if joints then
		restore(joints)
		active[character] = nil
		rigs[character] = nil
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
			local shot = shots[player.UserId]
			phase = Perfect.phase(now - shot.started, shot.perfect)
			if phase >= Motion.Duration then
				shots[player.UserId] = nil
				phase = nil
			end
		end
		if not phase or phase < 0 or phase >= Motion.Duration then
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
			rigs[character] = rigFor(character, hum)
		end
		local p = Motion.sample(phase, Config.KickContact)
		local poses = pose(rigs[character], p)
		for joint, entry in active[character] do
			if not joint.Parent then
				continue
			end
			local offset = poses[joint.Name]
			if offset then
				entry.base = joint.Transform
				entry.applied = entry.base:Lerp(offset, p.weight)
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

Players.PlayerRemoving:Connect(function(player)
	shots[player.UserId] = nil
end)
return Kick
