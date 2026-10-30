--!strict
-- Black silhouettes of the egg's pets replace each other, slow down and stop on
-- the granted pet, which then fills with colour. The labels follow the fill.
local React = require(game.ReplicatedStorage.Packages.React)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Sequence = require(game.ReplicatedStorage.Shared.Core.HatchSequence)
local U = require(script.Parent.Components)
local T = require(script.Parent.Theme)
local Egg = require(script.Parent.HatchEgg)
local e = React.createElement

local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)
local INK = Color3.fromRGB(12, 13, 19)
local NEW = Color3.fromRGB(64, 210, 96)
local GLOW = "rbxasset://textures/particles/smoke_main.dds"

-- `fresh` and `owned` come from the server (PetNews); a pet without them shows
-- no badge.
type Pet = {
	uid: string,
	id: string,
	name: string,
	rarity: string,
	boost: number,
	fresh: boolean?,
	owned: number?,
}
type Props = {
	At: ((number) -> any) -> any,
	Track: Egg.Track,
	Pool: { any },
	Final: number,
	Pet: Pet,
	Tier: number,
	-- The pedestal top under the egg, the egg size and the room for the labels.
	Foot: Vector2,
	Size: number,
	Width: number,
	Single: boolean,
}

local Roulette = {}

-- Seconds since the reveal filled the pet with colour, or nil before it.
function Roulette.revealed(track: Egg.Track, t: number): number?
	local fill = Egg.fill(track)
	return if fill and t >= fill then t - fill else nil
end

function Roulette.View(p: Props)
	local at, track = p.At, p.Track
	local width = p.Width
	-- The pet stands on the pedestal where the egg stood.
	local artSize = p.Size * 0.8
	local artHeight = p.Size * 0.84
	local centerX = p.Foot.X
	-- The pet view keeps a margin around the model, so its box reaches below
	-- the pedestal top.
	local centerY = p.Foot.Y - artHeight * 0.37
	-- Name, rarity and boost stack above the pet.
	local nameHeight = if p.Single then 40 else 30
	local lineHeight = if p.Single then 30 else 24
	local blockHeight = nameHeight + lineHeight * 2
	local blockTop = p.Foot.Y - artHeight * 0.9 - blockHeight - 6
	local color = Egg.TierColors[p.Tier]
	local function current(t: number): (Sequence.Frame?, number)
		local start = Egg.rouletteStart(track)
		if start == nil or t < start then
			return nil, 0
		end
		return Sequence.frameAt(track.frames, t - start)
	end
	local function switchAge(t: number): number
		local frame = current(t)
		local start = Egg.rouletteStart(track)
		return if frame and start then t - start - frame.at else math.huge
	end
	local children: { [string]: any } = {
		Shadow = e("ImageLabel", {
			Name = "PetShadow",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(centerX, p.Foot.Y),
			Size = UDim2.fromOffset(p.Size * 0.7, p.Size * 0.17),
			Image = GLOW,
			ImageColor3 = BLACK,
			ImageTransparency = at(function(t)
				return if current(t) or Roulette.revealed(track, t) then 0.35 else 1
			end),
			ZIndex = 17,
		}),
	}
	for index, def in p.Pool do
		local final = index == p.Final
		children["Silhouette" .. index] = e(U.PetView, {
			Def = def,
			Key = if final then p.Pet.uid else "silhouette-" .. def.id,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(centerX, centerY),
			Size = at(function(t)
				local reveal = Roulette.revealed(track, t)
				local s = if reveal then Egg.pop(reveal / 0.35) else 1 + 0.08 * (1 - Egg.clamp(switchAge(t) / 0.1))
				return UDim2.fromOffset(math.max(1, artSize * s), math.max(1, artHeight * s))
			end),
			Visible = at(function(t)
				local frame = current(t)
				return frame ~= nil and frame.index == index
			end),
			ImageColor3 = if final
				then at(function(t)
					local reveal = Roulette.revealed(track, t)
					return if reveal then BLACK:Lerp(WHITE, Egg.smooth(reveal / Sequence.Fill)) else BLACK
				end)
				else BLACK,
			FitToView = true,
			ReducedMotion = true,
			ZIndex = 18,
		})
	end
	children.RevealFlash = e("ImageLabel", {
		Name = "PetRevealFlash",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(centerX, centerY),
		Image = GLOW,
		ImageColor3 = WHITE,
		Size = at(function(t)
			local reveal = Roulette.revealed(track, t) or 0
			local s = artSize * (0.7 + Egg.clamp(reveal / 0.3) * 0.8)
			return UDim2.fromOffset(s, s)
		end),
		ImageTransparency = at(function(t)
			local reveal = Roulette.revealed(track, t)
			return if reveal then Egg.clamp(0.15 + reveal / 0.35) else 1
		end),
		ZIndex = 19,
	})
	children.Result = e("CanvasGroup", {
		Name = "HatchPetResult",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(width, blockHeight),
		Position = at(function(t)
			local reveal = Roulette.revealed(track, t)
			local q = if reveal then Egg.smooth((reveal - 0.12) / 0.3) else 0
			return UDim2.fromOffset(math.round(centerX - width / 2), math.round(blockTop + (1 - q) * 14))
		end),
		GroupTransparency = at(function(t)
			local reveal = Roulette.revealed(track, t)
			return if reveal then 1 - Egg.smooth((reveal - 0.12) / 0.3) else 1
		end),
		ZIndex = 20,
	}, {
		Name = e(U.Label, {
			Text = p.Pet.name,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromOffset(width, nameHeight),
			TextSize = if p.Single then 36 else 26,
			Wrap = true,
			ZIndex = 21,
		}),
		Rarity = e(U.Label, {
			Text = p.Pet.rarity,
			Position = UDim2.fromOffset(0, nameHeight),
			Size = UDim2.fromOffset(width, lineHeight),
			TextSize = if p.Single then 26 else 20,
			Color = color,
			ZIndex = 21,
		}),
		Boost = e(U.Label, {
			Text = "×" .. p.Pet.boost .. " Skill",
			Position = UDim2.fromOffset(0, nameHeight + lineHeight),
			Size = UDim2.fromOffset(width, lineHeight),
			TextSize = if p.Single then 26 else 20,
			Color = T.Gold,
			ZIndex = 21,
		}),
	})
	-- NEW! on a kind the player did not hold, the count of the kind otherwise.
	local badge = Roulette.badge(p.Pet)
	if badge then
		local fresh = p.Pet.fresh == true
		local badgeW = if fresh then (if p.Single then 104 else 82) else (if p.Single then 148 else 118)
		local badgeH = if p.Single then 38 else 30
		children.Badge = e("Frame", {
			Name = "HatchPetBadge",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(
				math.round(math.min(centerX + artSize * 0.38, centerX + width / 2 - badgeW / 2)),
				math.round(centerY - artHeight * 0.36)
			),
			Size = UDim2.fromOffset(badgeW, badgeH),
			Rotation = if fresh then -10 else 0,
			BackgroundColor3 = if fresh then NEW else INK,
			BackgroundTransparency = at(function(t)
				return if Roulette.revealed(track, t) then (if fresh then 0 else 0.15) else 1
			end),
			BorderSizePixel = 0,
			ZIndex = 22,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
			Edge = e("UIStroke", {
				Color = if fresh then INK else WHITE,
				Thickness = if fresh then 3 else 2,
				Transparency = at(function(t)
					return if Roulette.revealed(track, t) then (if fresh then 0 else 0.5) else 1
				end),
			}),
			Text = e("TextLabel", {
				Name = "HatchPetBadgeText",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Text = badge,
				Font = Enum.Font.GothamBlack,
				TextSize = if p.Single then 22 else 17,
				TextColor3 = WHITE,
				TextTransparency = at(function(t)
					return if Roulette.revealed(track, t) then 0 else 1
				end),
				ZIndex = 23,
			}, {
				Stroke = e("UIStroke", {
					Color = INK,
					Thickness = 2,
					Transparency = at(function(t)
						return if Roulette.revealed(track, t) then 0 else 1
					end),
				}),
			}),
			-- Pops in right after the pet fills with colour.
			Scale = e("UIScale", {
				Scale = at(function(t)
					local reveal = Roulette.revealed(track, t)
					return if reveal then math.max(0.05, Egg.pop((reveal - 0.3) / 0.3)) else 0.05
				end),
			}),
		})
	end
	-- Above every egg layer: the light of a neighbour never covers a pet.
	return e("Frame", {
		Name = "HatchPetReveal",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
	}, children)
end

-- The badge text of a hatched pet, or nil without the server's marks.
function Roulette.badge(pet: Pet): string?
	if pet.fresh == true then
		return "NEW!"
	elseif pet.owned and pet.owned > 1 then
		return "You have " .. pet.owned
	end
	return nil
end

-- The egg that holds the pet, or nil for a pet no egg gives (a paid reward).
function Roulette.eggOf(pet: Pet): string?
	for _, egg in Config.Eggs do
		if Config.find(Config.eggPets(egg.id), pet.id) then
			return egg.id
		end
	end
	return nil
end

-- The pets the egg can give, with the granted pet among them.
function Roulette.pool(pet: Pet, fallbackEgg: string): ({ any }, number, string)
	local eggId = fallbackEgg
	for _, egg in Config.Eggs do
		if Config.find(Config.eggPets(egg.id), pet.id) then
			eggId = egg.id
			break
		end
	end
	local pool = table.clone(Config.eggPets(eggId))
	local final = 0
	for index, def in pool do
		if def.id == pet.id then
			final = index
		end
	end
	if final == 0 then
		table.insert(pool, Config.pet(pet.id) or { id = pet.id, name = pet.name, rarity = pet.rarity })
		final = #pool
	end
	return pool, final, eggId
end

return Roulette
