--!strict
local React = require(game.ReplicatedStorage.Packages.React)
local Run = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local U = require(script.Parent.Components)
local T = require(script.Parent.Theme)
local Framing = require(script.Parent.PetViewCamera)
local HatchEffects = require(script.Parent.HatchEffects)
local e = React.createElement

type Pet = { uid: string, id: string, name: string, rarity: string, boost: number }
type Props = {
	Width: number,
	Height: number,
	Hatched: { Pet },
	EggId: string?,
	Data: { world: number }?,
	Variant: number?,
	PreviewTime: number?,
	Reduced: boolean?,
	Close: () -> (),
}

local function clamp(t: number): number
	return math.clamp(t, 0, 1)
end
local function smooth(t: number): number
	local x = clamp(t)
	return x * x * (3 - 2 * x)
end
local function pop(t: number): number
	local x = clamp(t) - 1
	return 1 + 2.7 * x * x * x + 1.7 * x * x
end

local function EggView(p: { World: number, Id: string, Color: Color3 })
	local ref = React.useRef(nil :: ViewportFrame?)
	React.useEffect(function()
		local viewport = assert(ref.current, "Egg viewport must be mounted")
		local map = (
			workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild(p.World == 2 and "World2" or "World1")
		)
		local scenery = map and map:FindFirstChild("SkippingWorld")
		local stand = scenery and scenery:FindFirstChild("Egg_" .. p.Id)
		local source = stand and stand:FindFirstChild("ImportedVisual")
		local model
		if source and source:IsA("Model") then
			model = source:Clone()
		else
			model = Instance.new("Model")
			local shell = Instance.new("Part")
			shell.Shape = Enum.PartType.Ball
			shell.Size = Vector3.new(2.2, 3, 2.2)
			shell.Color = p.Color
			shell.Material = Enum.Material.SmoothPlastic
			shell.Parent = model
		end
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
			end
		end
		local cf, size = model:GetBoundingBox()
		model.WorldPivot = cf
		model:PivotTo(CFrame.identity)
		local world = Instance.new("WorldModel")
		world.Parent = viewport
		model.Parent = world
		local camera = Instance.new("Camera")
		camera.FieldOfView = 34
		camera.Parent = viewport
		viewport.CurrentCamera = camera
		local function fit()
			Framing.fit(camera, size, viewport.AbsoluteSize)
		end
		fit()
		local connection = viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
		return function()
			connection:Disconnect()
			world:Destroy()
			camera:Destroy()
		end
	end, { p.Id, tostring(p.World) })
	return e("ViewportFrame", {
		ref = ref,
		Name = "HatchingEgg",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(215, 215, 235),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1, -1),
		ZIndex = 16,
		Active = false,
	})
end

return function(p: Props)
	local revealAt = 1.3
	local time, setTime = React.useBinding(0)
	React.useEffect(function()
		if p.PreviewTime ~= nil then
			return
		end
		if p.Reduced then
			setTime(revealAt + 1.5)
			return
		end
		local start = os.clock()
		setTime(0)
		local connection
		connection = Run.RenderStepped:Connect(function()
			local t = os.clock() - start
			setTime(t)
			if t > revealAt + 1.3 then
				connection:Disconnect()
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, { p.PreviewTime ~= nil, p.Reduced == true, p.EggId or "", p.Hatched } :: { any })
	local function at(fn: (number) -> any): any
		if p.PreviewTime ~= nil then
			return fn(p.PreviewTime)
		end
		return time:map(fn)
	end
	local w, h = p.Width, p.Height
	local count = math.max(1, #p.Hatched)
	local column = (w - 16) / count
	local egg = Config.find(Config.Eggs, p.EggId or "Common") or Config.Eggs[1]
	local children = {}
	for i, pet in p.Hatched do
		local offset = (i - 1) * 0.09
		local center = column * (i - 0.5) + 8
		local artSize = math.min(column - 20, count == 1 and 245 or 180, h - 90)
		local eggSize = math.min(column - 20, count == 1 and 340 or 215, h - 55)
		local color = T.Rarity[pet.rarity] or egg.color
		local function progress(t: number): number
			return clamp((t - revealAt - offset) / 0.55)
		end
		if not p.Reduced then
			children["Effects" .. i] = e(HatchEffects, {
				At = at,
				Center = Vector2.new(center, math.round(h * 0.43)),
				Size = eggSize * (count == 1 and 1 or 0.82),
				RevealAt = revealAt + offset,
				ShellColor = egg.color,
				Color = color,
			})
		end
		local eggChildren = {
			Art = e(EggView, { Id = egg.id, World = p.Data and p.Data.world or 1, Color = egg.color }),
		}
		if not p.Reduced then
			local points = {
				Vector2.new(0.49, 0.25),
				Vector2.new(0.43, 0.37),
				Vector2.new(0.54, 0.46),
				Vector2.new(0.46, 0.57),
				Vector2.new(0.55, 0.68),
				Vector2.new(0.49, 0.77),
			}
			for k = 1, 7 do
				local a = k <= 5 and points[k] or (k == 6 and points[3] or points[4])
				local b = k <= 5 and points[k + 1] or (k == 6 and Vector2.new(0.63, 0.39) or Vector2.new(0.34, 0.62))
				local delta = b - a
				for layer = 1, 2 do
					eggChildren["Crack" .. k .. "Layer" .. layer] = e("Frame", {
						Name = layer == 1 and "CrackGlow" or "CrackCore",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale((a.X + b.X) / 2, (a.Y + b.Y) / 2),
						Size = UDim2.fromOffset(delta.Magnitude * eggSize, layer == 1 and 7 or 2),
						Rotation = math.deg(math.atan2(delta.Y, delta.X)),
						BackgroundColor3 = layer == 1 and T.Gold or Color3.fromRGB(255, 251, 216),
						BackgroundTransparency = at(function(t)
							local charge = smooth((t - offset - 0.34 - k * 0.09) / 0.16)
							return 1 - charge * (layer == 1 and 0.4 or 0.95)
						end),
						BorderSizePixel = 0,
						ZIndex = layer == 1 and 19 or 20,
					})
				end
			end
		end
		children["Egg" .. i] = e("CanvasGroup", {
			Name = "HatchEggStage",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			GroupTransparency = at(function(t)
				return smooth((t - revealAt - offset + 0.14) / 0.22)
			end),
			Position = at(function(t)
				local localTime = math.max(0, t - offset)
				local bounce = -math.abs(math.sin(localTime * 9)) * (4 + clamp(localTime / revealAt) * 9)
				return UDim2.fromOffset(center, math.round(h * 0.43 + bounce))
			end),
			Size = at(function(t)
				local localTime = math.max(0, t - offset)
				local charge = smooth((localTime - 0.7) / 0.6)
				local scale = 0.88 + 0.12 * pop(localTime / 0.35) + charge * 0.06 + math.sin(localTime * 12) * 0.012
				return UDim2.fromOffset(eggSize * scale, eggSize * scale)
			end),
			Rotation = at(function(t)
				local localTime = math.max(0, t - offset)
				local charge = clamp(localTime / revealAt)
				return math.sin(localTime * (9 + charge * 16)) * (2 + charge * charge * 13)
			end),
			ZIndex = 15,
		}, eggChildren)
		local resultChildren = {
			Name = e(U.Label, {
				Text = pet.name,
				Position = UDim2.fromOffset(0, 0),
				Size = UDim2.fromOffset(column - 8, 38),
				TextSize = count == 1 and 28 or 20,
				Wrap = true,
			}),
			Rarity = e(U.Label, {
				Text = pet.rarity,
				Position = UDim2.fromOffset(0, 40),
				Size = UDim2.fromOffset(column - 8, 26),
				TextSize = 20,
				Color = color,
			}),
			Pet = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset((column - 8) / 2, (h - 70) * 0.52 + 23),
				Size = at(function(t)
					local s = pop(progress(t))
					return UDim2.fromOffset(math.max(1, artSize * s), math.max(1, (h - 160) * s))
				end),
			}, {
				View = e(U.PetView, {
					Def = Config.pet(pet.id),
					Key = pet.uid,
					Size = UDim2.fromScale(1, 1),
					FitToView = true,
					ReducedMotion = true,
				}),
			}),
			Boost = e(U.Label, {
				Text = "×" .. pet.boost .. " Skill",
				Position = UDim2.fromOffset(0, h - 118),
				Size = UDim2.fromOffset(column - 8, 34),
				TextSize = count == 1 and 25 or 20,
				Color = T.Gold,
			}),
		}
		children["Pet" .. i] = e("CanvasGroup", {
			Name = "HatchPetResult",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(column - 8, h - 70),
			Position = at(function(t)
				return UDim2.fromOffset(
					math.round(center - (column - 8) / 2),
					math.round(4 + (1 - smooth(progress(t))) * 20)
				)
			end),
			GroupTransparency = at(function(t)
				return 1 - smooth(progress(t) * 2)
			end),
			ZIndex = 16,
		}, resultChildren)
	end
	children.Continue = e("Frame", {
		Name = "HatchContinue",
		Size = UDim2.fromOffset(240, 46),
		Position = UDim2.fromOffset(math.floor((w - 240) / 2), h - 54),
		BackgroundTransparency = 1,
		Visible = at(function(t)
			return t >= revealAt + (count - 1) * 0.09 + 1.1
		end),
		ZIndex = 20,
	}, {
		Button = e(U.Button, {
			Name = "Continue",
			Text = "Continue",
			Size = UDim2.fromOffset(240, 46),
			Position = UDim2.fromOffset(0, 0),
			Color = T.Colors.Pets,
			OnActivated = p.Close,
			Disabled = false,
		}),
	})
	return e(
		"Frame",
		{ Name = "HatchPresentation", Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1 },
		children
	)
end
