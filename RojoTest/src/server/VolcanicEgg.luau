--!strict
local Construction = require(script.Parent.ConstructionTypes)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local Egg = {}
-- The authored World1 egg turns once; the client mesh uses this same anchor.
function Egg.turnLeft(map: any)
	if map.Name ~= "World1" then
		return false
	end
	local world = map.SkippingWorld
	local anchor = assert(world:FindFirstChild("HackedAdminEgg")) :: BasePart
	if anchor:GetAttribute("VolcanicEggLeft45Version") == 1 then
		return false
	end
	anchor.CFrame *= CFrame.Angles(0, math.rad(45), 0)
	for _, name in { "VolcanicEggFallback", "VolcanicEggVisual" } do
		local visual = world:FindFirstChild(name)
		if visual and visual:IsA("BasePart") then
			visual.CFrame = CFrame.new(visual.Position) * anchor.CFrame.Rotation
		end
	end
	anchor:SetAttribute("VolcanicEggLeft45Version", 1)
	return true
end

function Egg.apply(map: Construction.World)
	Egg.turnLeft(map :: any)
	local world = map.SkippingWorld
	local anchor = assert(world:FindFirstChild("HackedAdminEgg")) :: BasePart
	local old = world:FindFirstChild("VolcanicEggVisual")
	if old then
		old:Destroy()
	end
	local fallback = world:FindFirstChild("VolcanicEggFallback") :: MeshPart?
	if not fallback then
		local created = game:GetService("AssetService")
			:CreateMeshPartAsync(Content.fromUri("rbxassetid://137723316390315"))
		created.Name = "VolcanicEggFallback"
		created.Color = Color3.fromRGB(100, 20, 14)
		created.Material = Enum.Material.SmoothPlastic
		created.Anchored = true
		created.CanCollide, created.CanTouch, created.CanQuery = false, false, false
		created.Parent = world
		fallback = created
	end
	local visual = assert(fallback)
	local stand = assert(world:FindFirstChild("HackedEggStand")) :: BasePart
	-- Authored studs, shrunk with the world.
	local k = Scale.factor(map)
	local height = 12.5 * k
	local centerY = stand.Position.Y + stand.Size.Y / 2 + 0.3 * k + height / 2
	visual.Size = Vector3.new(4.978106, 7, 4.978202) * (height / 7)
	visual.CFrame = anchor.CFrame + Vector3.new(0, centerY - anchor.Position.Y, 0)
	anchor.Transparency = 1
	anchor.CastShadow = false
	(assert(anchor:FindFirstChildOfClass("ProximityPrompt")) :: ProximityPrompt).ObjectText =
		"Volcanic Inferno Egg • 175 Robux"
	for _, node in world:GetChildren() do
		if not node:IsA("BasePart") then
			continue
		end
		if node.Name == "HackedPixel" then
			node.Transparency = 1
			node.CastShadow = false
		end
		if node.Name == "LabelAnchor" then
			local text = node:FindFirstChildWhichIsA("TextLabel", true)
			if
				text
				and (text.Text:find("Hacked Admin Egg", 1, true) or text.Text:find("Volcanic Inferno Egg", 1, true))
			then
				text.Text = "Volcanic Inferno Egg\n175 ROBUX"
				text.TextColor3 = Color3.fromRGB(255, 160, 48)
				node.CFrame += Vector3.new(0, centerY + height / 2 + 5.5 * k - node.Position.Y, 0)
			end
		end
	end
end
return Egg
