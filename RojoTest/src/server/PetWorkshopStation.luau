--!strict
-- Installs only this new, self-contained object. Never rebuilds the authored map.
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Station = {}
function Station.install(world: Instance): Model?
	local lobby = world:FindFirstChild("Lobby")
	if not lobby then
		return nil
	end
	local geometry = lobby:FindFirstChild("Geometry")
	local existing = lobby:FindFirstChild("PetWorkshop") or (geometry and geometry:FindFirstChild("PetWorkshop"))
	local model: Model
	if existing and existing:IsA("Model") then
		model = existing
	else
		model = game.ReplicatedStorage.Shared.PetWorkshopTemplate:Clone() :: Model
		model.Name = "PetWorkshop"
		model.WorldPivot = CFrame.identity
		model:PivotTo(CFrame.new(45, 20.24, 215))
	end
	model:SetAttribute("LayoutKey", "PetWorkshop")
	for _, name in { "WorkshopPrompt", "WorkshopSign", "Interaction", "SignAnchor" } do
		local old = model:FindFirstChild(name, true)
		if old then
			old:Destroy()
		end
	end
	local cabinet = model:FindFirstChild("CenterSpine") :: BasePart
	local anchor = Instance.new("Attachment")
	anchor.Name = "Interaction"
	anchor.Position = Vector3.new(0, -1, 5)
	anchor.Parent = cabinet
	local sign = Instance.new("Attachment")
	sign.Name = "SignAnchor"
	sign.Position = Vector3.new(0, 7, 0)
	sign.Parent = cabinet
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "WorkshopPrompt"
	prompt.ActionText = "Open Workshop"
	prompt.ObjectText = "Forms & Mutations"
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
	local board = Instance.new("BillboardGui")
	board.Name = "WorkshopSign"
	board.Size = UDim2.fromOffset(280, 76)
	board.Adornee = sign
	board.MaxDistance = 80
	board.AlwaysOnTop = false
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "PET WORKSHOP\nForms & Mutations"
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 23
	label.TextColor3 = Color3.fromRGB(255, 221, 38)
	label.TextStrokeTransparency = 0
	label.Parent = board
	board.Parent = sign
	model.Parent = lobby
	return model
end
function Station.connect(context: any, world: Instance)
	local model = Refs.workshop(world)
	local prompt = model and model:FindFirstChild("WorkshopPrompt", true)
	if not prompt or not prompt:IsA("ProximityPrompt") then
		return
	end
	prompt.Triggered:Connect(function(player: Player)
		local state = context.states[player]
		local root, humanoid = context.rootFor(player)
		local anchor = prompt.Parent :: Attachment
		if
			state
			and root
			and humanoid
			and humanoid.Health > 0
			and context.arenaFor(player) == world
			and (root.Position - anchor.WorldPosition).Magnitude <= 15
			and os.clock() >= (state.workshopPromptAt or 0)
		then
			state.workshopPromptAt = os.clock() + 1
			context.effect:FireClient(player, "Open", "PetCraft")
		end
	end)
end
return Station
