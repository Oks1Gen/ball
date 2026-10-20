local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.GameConfig)
local Motion = require(Shared.ShotMotion)
local BallVisuals = require(Shared.BallVisuals)
local ShotFeedback = require(Shared.ShotFeedback)
local Flight = {}

function Flight.start(info, context)
	local feedback=info.feedback or ShotFeedback.profile(0,1,info.world)
	local ball = BallVisuals.create(info.stone, 2.2)
	ball.Name = "ThrownBall_"..info.userId ball.Parent = workspace
	local body = ball:FindFirstChildWhichIsA("BasePart", true)
	local trailDef = Config.find(Config.Trails, info.trail)
	local color = info.trail == "None" and Color3.fromRGB(240, 255, 255) or trailDef.color
	local a = Instance.new("Attachment") a.Position = Vector3.new(0, 0.6, 0) a.Parent = body
	local b = Instance.new("Attachment") b.Position = Vector3.new(0, -0.6, 0) b.Parent = body
	local trail = Instance.new("Trail") trail.Attachment0=a trail.Attachment1=b trail.Color=ColorSequence.new(color)
	trail.Lifetime=feedback.trailLifetime trail.Enabled=false trail.FaceCamera=true trail.LightEmission=0.7
	trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.25),NumberSequenceKeypoint.new(1,1)}) trail.Parent=body
	local camera = workspace.CurrentCamera
	local saved = {cameraType=camera.CameraType,subject=camera.CameraSubject,cframe=camera.CFrame,fov=camera.FieldOfView}
	if context.me then camera.CameraType=Enum.CameraType.Scriptable end
	local started = info.startedAt or workspace:GetServerTimeNow()
	local startPosition = info.startPosition or Vector3.new(-116,1.8,-0.3)+(info.world==2 and Config.WorldOffset or Vector3.zero)
	local direction = info.direction or -Vector3.zAxis
	local right = direction:Cross(Vector3.yAxis).Unit
	local waterY = info.waterY or 0.82
	local lastContact = 0
	local kicked = false
	local connection
	local returnTween
	saved.cancel=function()
		if connection then connection:Disconnect() end
		if returnTween then returnTween:Cancel() end
		ball:Destroy()
		if context.me then
			camera.CameraType=saved.cameraType camera.CameraSubject=saved.subject
			camera.CFrame=saved.cframe camera.FieldOfView=saved.fov
		end
	end
	connection = RunService.RenderStepped:Connect(function(dt)
		if context.me and not context.active() then connection:Disconnect() ball:Destroy() return end
		local elapsed = workspace:GetServerTimeNow()-started
		local alpha = math.clamp((elapsed-Config.KickWindup)/info.duration,0,1)
		local position = Motion.position(startPosition,info.distance,alpha,direction)
		ball:PivotTo(CFrame.new(position)*CFrame.Angles(alpha*25,alpha*12,0))
		trail.Enabled=elapsed>=Config.KickWindup and context.effects()
		if elapsed>=Config.KickWindup and not kicked then
			kicked=true
			if context.me and context.kick then context.kick(feedback) end
		end
		local contacts=math.min(Motion.BounceCount,math.floor(alpha*Motion.BounceCount+1e-6))
		for contact=lastContact+1,contacts do
			local landing=Motion.position(startPosition,info.distance,contact/Motion.BounceCount,direction)
			context.ripple(Vector3.new(landing.X,waterY,landing.Z),color,feedback.rippleScale)
		end
		lastContact=contacts
		if context.me then
			context.distance(elapsed<Config.KickWindup and "KICK!" or Config.format(info.distance*alpha).." m")
			local blend=1-math.exp(-dt*(9+5*feedback.intensity))
			local height=position.Y-startPosition.Y
			local cameraPosition=position+right*7-direction*(14+6*feedback.intensity)+Vector3.new(0,5.5-height*0.35,0)
			local sinceKick=elapsed-Config.KickWindup
			local shake=context.shake() and sinceKick>=0 and math.sin(sinceKick*45)*feedback.shakeAmplitude*math.exp(-sinceKick*5) or 0
			local target=CFrame.lookAt(cameraPosition+Vector3.new(0,shake,0),position+Vector3.new(0,0.4,0))
			camera.CFrame=camera.CFrame:Lerp(target,blend)
			local targetFov=elapsed<Config.KickWindup and 68 or feedback.fieldOfView
			camera.FieldOfView+=(targetFov-camera.FieldOfView)*blend
		end
		if alpha>=1 then
			connection:Disconnect() Debris:AddItem(ball,0.6)
			if context.me then
				local tween=TweenService:Create(camera,TweenInfo.new(0.55,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{CFrame=saved.cframe,FieldOfView=saved.fov})
				returnTween=tween
				tween:Play()
				task.delay(0.55,function()
					if context.active() then
						camera.CameraType=saved.cameraType camera.CameraSubject=saved.subject
						context.finish()
					end
				end)
			end
		end
	end)
	return saved
end
return Flight
