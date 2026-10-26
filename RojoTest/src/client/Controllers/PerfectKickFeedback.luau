--!strict
-- Short additive camera cue; removed before the stock camera or a flight takes over.
local Run = game:GetService("RunService")
local Perfect = require(game.ReplicatedStorage.Shared.Core.PerfectKick)
local nextId = 0
local Feedback = {}

function Feedback.mount(context: any)
	nextId += 1
	local name = "PerfectSelection_" .. nextId
	local started = -math.huge
	local camera: Camera? = nil
	local baseFov, appliedFov = 70, 70
	local baseFrame, appliedFrame = CFrame.identity, CFrame.identity
	local function clear()
		if camera and camera.Parent then
			if math.abs(camera.FieldOfView - appliedFov) < 0.0001 then
				camera.FieldOfView = baseFov
			end
			if camera.CFrame:FuzzyEq(appliedFrame, 0.00001) then
				camera.CFrame = baseFrame
			end
		end
		camera = nil
	end
	local function stop()
		started = -math.huge
		clear()
	end
	Run:BindToRenderStep(name .. "Clear", Enum.RenderPriority.Camera.Value - 1, clear)
	Run:BindToRenderStep(name, Enum.RenderPriority.Camera.Value + 2, function()
		local age = os.clock() - started
		if age >= 0.52 or not context.effects() then
			return
		end
		local current = workspace.CurrentCamera
		if not current or current.CameraType == Enum.CameraType.Scriptable then
			return
		end
		camera = current
		baseFov, baseFrame = current.FieldOfView, current.CFrame
		appliedFov = math.clamp(baseFov + Perfect.selectionFov(age), 40, 100)
		local shake = if context.shake() then math.sin(age * 52) * math.exp(-age * 12) * 0.07 else 0
		appliedFrame = baseFrame * CFrame.new(shake, shake * 0.5, 0) * CFrame.Angles(0, 0, shake * 0.025)
		current.FieldOfView, current.CFrame = appliedFov, appliedFrame
	end)
	return {
		confirm = function()
			if context.effects() then
				started = os.clock()
			end
		end,
		stop = stop,
		destroy = function()
			stop()
			Run:UnbindFromRenderStep(name)
			Run:UnbindFromRenderStep(name .. "Clear")
		end,
	}
end

return Feedback
