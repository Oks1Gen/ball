--!strict
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Flight = {}

function Flight.mount(player: Player): () -> ()
	local update: RBXScriptConnection? = nil
	local cleanup: (() -> ())? = nil
	local function stop()
		if update then
			update:Disconnect()
			update = nil
		end
		if cleanup then
			cleanup()
			cleanup = nil
		end
	end
	local function sync()
		stop()
		if player:GetAttribute("AdminFlight") ~= true then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = character and character:FindFirstChildOfClass("Humanoid")
		if not character or not root or not hum or hum.Health <= 0 then
			return
		end
		local previousStand, previousRotate = hum.PlatformStand, hum.AutoRotate
		local collisions: { [BasePart]: boolean } = {}
		local attachment = Instance.new("Attachment")
		attachment.Name = "DevFlightAttachment"
		attachment.Parent = root
		local velocity = Instance.new("LinearVelocity")
		velocity.Name = "DevFlightVelocity"
		velocity.Attachment0 = attachment
		velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		velocity.ForceLimitsEnabled = false
		velocity.VectorVelocity = Vector3.zero
		velocity.Parent = root
		local orientation = Instance.new("AlignOrientation")
		orientation.Name = "DevFlightOrientation"
		orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
		orientation.Attachment0 = attachment
		orientation.MaxTorque = math.huge
		orientation.Responsiveness = 20
		orientation.CFrame = root.CFrame.Rotation
		orientation.Parent = root
		cleanup = function()
			velocity:Destroy()
			orientation:Destroy()
			attachment:Destroy()
			for part, collidable in collisions do
				if part.Parent then
					local original = part:GetAttribute("DevFlightCanCollide")
					part.CanCollide = if typeof(original) == "boolean" then original else collidable
				end
			end
			if hum.Parent then
				hum.PlatformStand = previousStand
				hum.AutoRotate = previousRotate
				if hum.Health > 0 then
					hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end
			if root.Parent then
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
		end
		update = RunService.PreSimulation:Connect(function()
			if player.Character ~= character or not root.Parent or hum.Health <= 0 then
				stop()
				return
			end
			hum.PlatformStand = true
			hum.AutoRotate = false
			for _, part in character:GetDescendants() do
				if part:IsA("BasePart") then
					if collisions[part] == nil then
						collisions[part] = part.CanCollide
					end
					part.CanCollide = false
				end
			end
			local camera = workspace.CurrentCamera
			local direction = Vector3.zero
			local function held(key: Enum.KeyCode): number
				return if Input:IsKeyDown(key) then 1 else 0
			end
			if camera and not Input:GetFocusedTextBox() and not game:GetService("GuiService").MenuIsOpen then
				direction = camera.CFrame.LookVector * (held(Enum.KeyCode.W) - held(Enum.KeyCode.S))
					+ camera.CFrame.RightVector * (held(Enum.KeyCode.D) - held(Enum.KeyCode.A))
					+ Vector3.yAxis
						* (held(Enum.KeyCode.Space) - math.max(
							held(Enum.KeyCode.LeftControl),
							held(Enum.KeyCode.RightControl)
						))
				local flat = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
				if flat.Magnitude > 0.01 then
					orientation.CFrame = CFrame.lookAt(Vector3.zero, flat)
				end
			end
			local speed = if Input:IsKeyDown(Enum.KeyCode.LeftShift) or Input:IsKeyDown(Enum.KeyCode.RightShift)
				then 96
				else 48
			velocity.VectorVelocity = if direction.Magnitude > 0.001 then direction.Unit * speed else Vector3.zero
		end)
	end
	local attribute = player:GetAttributeChangedSignal("AdminFlight"):Connect(sync)
	local removing = player.CharacterRemoving:Connect(stop)
	local added = player.CharacterAdded:Connect(sync)
	sync()
	return function()
		attribute:Disconnect()
		removing:Disconnect()
		added:Disconnect()
		stop()
	end
end

return Flight
