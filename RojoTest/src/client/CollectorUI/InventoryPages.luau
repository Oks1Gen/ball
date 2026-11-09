--!strict
local React = require(game.ReplicatedStorage.Packages.React)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local BallCardArt = require(script.Parent.Parent.Modules.BallCardArt)
local Spacing = require(game.ReplicatedStorage.Shared.UiSpacing)
local U = require(script.Parent.Components)
local T = require(script.Parent.Theme)
local Art = require(script.Parent.Art)
local PetCardArt = require(script.Parent.Parent.Modules.PetCardArt)
local Variants = require(game.ReplicatedStorage.Shared.Core.PetVariants)
local Controls = require(script.Parent.PetControls)
local PetDetailPlane = require(script.Parent.PetDetailPlane)
local e = React.createElement
local C = Color3.fromRGB
local Pages = {}
local CYAN = C(125, 223, 255)
local GREEN = C(79, 255, 34)

local function label(text: string, x: number, y: number, w: number, h: number, size: number, color: Color3?): any
	return e(U.Label, {
		Text = text,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		TextSize = size,
		Color = color,
		Scaled = true,
		MinTextSize = 12,
	})
end
local function button(
	name: string,
	text: string,
	x: number,
	y: number,
	w: number,
	h: number,
	action: any,
	color: Color3,
	disabled: boolean?
): any
	return e(U.Button, {
		Name = name,
		Text = text,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		TextSize = math.min(22, math.max(14, math.floor(w * 0.2))),
		OnActivated = action,
		Color = color,
		Disabled = disabled,
		Studs = false,
		NoShadow = true,
	})
end
local function frame(name: string, children: any, w: number, h: number): any
	return e("Frame", { Name = name, Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, ZIndex = 20 }, children)
end
local function recess(name: string, x: number, y: number, w: number, h: number, children: any): any
	return e(U.Slot, {
		Name = name,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		Color = T.Recess,
		Radius = 16,
		Outline = 3,
		NoShadow = true,
		Children = children,
	})
end
local function power(value: number, w: number, y: number, size: number, additive: boolean?): any
	return frame("Power", {
		Icon = e(
			U.Icon,
			{ Kind = "Skill", Position = UDim2.fromOffset(4, y), Size = UDim2.fromOffset(size + 6, size + 6) }
		),
		Value = label(
			(if additive then "+" else "×") .. Config.formatBoost(value),
			size + 6,
			y,
			w - size - 10,
			size + 6,
			size,
			GREEN
		),
	}, w, y + size + 6)
end
local function checkMark(w: number): any
	return e(
		U.Icon,
		{ Kind = "Check", Position = UDim2.fromOffset(w - 32, -2), Size = UDim2.fromOffset(34, 34), ZIndex = 36 }
	)
end
local function BallView(p: any): any
	local ref: any = React.useRef(nil)
	React.useEffect(function()
		if ref.current then
			Art.bind(ref.current)
		end
	end, { p.Id })
	return e("ImageLabel", {
		ref = ref,
		Name = "BallPortrait",
		Image = BallCardArt.image(p.Id),
		ScaleType = Enum.ScaleType.Fit,
		Position = p.Position,
		Size = p.Size,
		BackgroundTransparency = 1,
		Active = false,
		ZIndex = 15,
	})
end

function Pages.Balls(p: any): any
	local w, h = p.Width, p.Height
	local selected = Config.find(Config.Stones, p.BallId or p.Data.stone) or Config.Stones[1]
	local detailW = p.Phone and 132 or 180
	local gridX = detailW + 16
	local gridW = w - gridX
	local header = p.Phone and 26 or 34
	local panelH = h - header
	local cols = p.Phone and (gridW >= 300 and 3 or 2) or 4
	local cardW, gap = Spacing.row(gridW - 32, cols, 96)
	local cardH = cardW
	local cards: any = {}
	local owned = 0
	for i, item in Config.Stones do
		local has = p.Data.stones[item.id] == true
		if has then
			owned += 1
		end
		cards[item.id] = e(U.Tile, {
			Name = "BallCard" .. item.id,
			Position = UDim2.fromOffset(
				16 + (i - 1) % cols * (cardW + gap),
				16 + math.floor((i - 1) / cols) * (cardH + gap)
			),
			Size = UDim2.fromOffset(cardW, cardH),
			Color = has and C(124, 133, 138) or C(70, 76, 85),
			BorderColor = C(182, 190, 195),
			SelectionColor = CYAN,
			Selected = selected.id == item.id,
			Quiet = true,
			Studs = false,
			OnActivated = function()
				p.SelectBall(item.id)
			end,
			Children = {
				Preview = e(
					BallView,
					{ Id = item.id, Position = UDim2.fromOffset(5, 2), Size = UDim2.fromOffset(cardW - 10, cardH - 24) }
				),
				Power = power(item.trainingBonus, cardW, cardH - 29, p.Phone and 17 or 22, true),
				Check = p.Data.stone == item.id and checkMark(cardW) or nil,
				Lock = not has and e(
					U.Icon,
					{ Kind = "Lock", Position = UDim2.fromOffset(cardW - 26, 2), Size = UDim2.fromOffset(24, 24) }
				) or nil,
			},
		})
	end
	local equipped = p.Data.stone == selected.id
	local has = p.Data.stones[selected.id] == true
	local afford = p.Data.wins >= selected.cost
	local tutorialContinue = p.Data.tutorialStage == 2 and selected.id ~= "Pebble" and equipped
	local detail: any = {
		Name = label(selected.name, 6, 6, detailW - 12, p.Phone and 30 or 46, p.Phone and 19 or 26),
		Portrait = e(BallView, {
			Id = selected.id,
			Position = UDim2.fromOffset(8, p.Phone and 35 or 58),
			Size = UDim2.fromOffset(detailW - 16, math.max(32, panelH - (p.Phone and 135 or 175))),
		}),
		Power = power(selected.trainingBonus, detailW, panelH - 98, p.Phone and 21 or 29, true),
		Owned = label(
			has and (equipped and "Equipped" or "Owned") or Config.format(selected.cost) .. " Wins",
			4,
			panelH - 64,
			detailW - 8,
			22,
			16,
			has and CYAN or T.Gold
		),
		Equip = button(
			"EquipBall",
			tutorialContinue and "Continue" or equipped and "Equipped" or has and "Equip" or "Buy",
			8,
			panelH - 40,
			detailW - 16,
			38,
			function()
				p.Request("Stone", selected.id)
			end,
			T.Colors.Green,
			p.Busy or (equipped and not tutorialContinue) or (not has and not afford)
		),
	}
	-- All actions retain a 44 px touch target.
	if p.Phone then
		detail.Equip = button(
			"EquipBall",
			tutorialContinue and "Continue" or equipped and "Equipped" or has and "Equip" or "Buy",
			4,
			panelH - 44,
			detailW - 8,
			44,
			function()
				p.Request("Stone", selected.id)
			end,
			T.Colors.Green,
			p.Busy or (equipped and not tutorialContinue) or (not has and not afford)
		)
	end
	return frame("BallsInventory", {
		Count = label(
			tostring(owned) .. " / " .. #Config.Stones .. " Balls",
			gridX,
			0,
			gridW,
			header - 4,
			p.Phone and 18 or 24
		),
		Details = e(U.Surface, {
			Name = "BallDetails",
			Position = UDim2.fromOffset(0, header),
			Size = UDim2.fromOffset(detailW, panelH),
			Color = C(48, 100, 119),
			BorderColor = CYAN,
			Outline = 3,
			Quiet = true,
			NoShadow = true,
			Children = detail,
		}),
		Grid = recess("BallGridPanel", gridX, header, gridW, panelH, {
			Scroll = e(U.Scroll, {
				Name = "BallGrid",
				Size = UDim2.fromScale(1, 1),
				Height = 32 + math.ceil(#Config.Stones / cols) * (cardH + gap) - gap,
				BarColor = CYAN,
				Children = cards,
			}),
		}),
	}, w, h)
end

local function PetCardImage(p: any): any
	local image = if p.Pet and ((p.Pet.form and p.Pet.form ~= "Normal") or p.Pet.mutation)
		then nil
		else PetCardArt.outlinedImage(p.Id)
	local ref: any = React.useRef(nil)
	React.useEffect(function()
		if ref.current then
			Art.bind(ref.current)
		end
	end, { p.Id, image })
	local modelProps = table.clone(p)
	if p.Pet then
		modelProps.Def = table.clone(p.Def)
		modelProps.Def.name = Variants.name(p.Pet)
	end
	modelProps.Position = UDim2.fromOffset(0, p.PortraitOnly and 0 or 14)
	modelProps.Size = p.PortraitOnly and UDim2.fromScale(1, 1) or UDim2.new(1, 0, 1, p.MultilineName and -50 or -30)
	return e("Frame", {
		Name = "PetIllustration",
		BackgroundTransparency = 1,
		Position = p.Position,
		Size = p.Size,
		ZIndex = 15,
	}, {
		Image = image and e("ImageLabel", {
			ref = ref,
			Name = "PetCardArt",
			Image = image,
			BackgroundTransparency = 1,
			Position = modelProps.Position,
			Size = modelProps.Size,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 15,
			Active = false,
		}) or e(U.PetView, modelProps),
		Rarity = not p.PortraitOnly and e(U.Label, {
			Text = p.Def.rarity,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 14),
			TextSize = p.MultilineName and 16 or 14,
			Scaled = true,
			MinTextSize = 9,
			Color = T.Rarity[p.Def.rarity],
			ZIndex = 16,
		}),
		Name = not p.PortraitOnly and e(U.Label, {
			Text = if p.Pet then Variants.name(p.Pet) else p.Def.name,
			Position = UDim2.new(0, 0, 1, p.MultilineName and -36 or -16),
			Size = UDim2.new(1, 0, 0, p.MultilineName and 36 or 16),
			TextSize = p.MultilineName and 18 or 14,
			Wrap = p.MultilineName,
			Scaled = true,
			MinTextSize = p.MultilineName and 12 or 8,
			ZIndex = 16,
		}),
	})
end

function Pages.Pets(p: any): any
	local confirm, setConfirm = React.useState(false)
	local firstRow, setFirstRow = React.useState(0)
	local byName, setByName = React.useState(false)
	local pets: any = table.clone(p.Inventory.pets)
	local equipped = p.Inventory.equipped
	table.sort(pets, function(a: any, b: any): boolean
		local ae, be = table.find(equipped, a.uid) ~= nil, table.find(equipped, b.uid) ~= nil
		if ae ~= be then
			return ae
		end
		if byName and a.name ~= b.name then
			return a.name < b.name
		end
		if a.boost ~= b.boost then
			return a.boost > b.boost
		end
		return a.uid < b.uid
	end)
	local pet: any = pets[1]
	for _, item in pets do
		if item.uid == p.SelectedPet then
			pet = item
			break
		end
	end
	local w, h = p.Width, p.Height
	local header = p.ImmersivePets and 12 or p.Phone and 26 or 34
	if not pet then
		return frame("PetsInventory", {
			Empty = recess("EmptyPetInventory", 0, header, w, h - header, {
				Icon = e(U.Icon, {
					Kind = "Pets",
					Position = UDim2.fromOffset(20, 20),
					Size = UDim2.fromOffset(p.Phone and 100 or 160, p.Phone and 100 or 160),
				}),
				Title = label(
					"Your first pet awaits!",
					p.Phone and 124 or 200,
					24,
					w - (p.Phone and 144 or 220),
					44,
					p.Phone and 22 or 32
				),
				Hint = label(
					"Hatch an egg for a Skill boost",
					p.Phone and 124 or 200,
					74,
					w - (p.Phone and 144 or 220),
					38,
					p.Phone and 17 or 22,
					T.Muted
				),
				Find = button(
					"FindEggs",
					"Find Eggs",
					p.Phone and 124 or 200,
					p.Phone and 124 or 156,
					math.min(240, w - (p.Phone and 144 or 220)),
					44,
					function()
						p.Open("Eggs")
					end,
					T.Colors.Green
				),
			}),
			Count = label("0 / 60 Pets", 4, 0, w - 8, header - 4, 20),
		}, w, h)
	end
	local detailW = p.ImmersivePets and 300 or p.Phone and 132 or 184
	local gridX = p.ImmersivePets and 0 or detailW + 16
	local gridW = p.ImmersivePets and w or w - detailW - 16
	local gridH = h - header - (p.ImmersivePets and 100 or 70)
	local detailH = p.ImmersivePets and h + 88 or h - header
	local cols = p.Phone and (gridW >= 300 and 3 or 2) or 4
	local cardW, gap = Spacing.row(gridW - 32, cols, 92)
	local paddingY = p.Phone and 8 or 16
	local cardH = if p.Phone
		then math.min(cardW + 28, math.max(72, gridH - paddingY * 2))
		else cardW + (p.ImmersivePets and 68 or 28)
	local artworkSize = math.min(cardW - 6, cardH - 30)
	local visibleRows = math.ceil(gridH / (cardH + gap))
	local cards: any = {}
	for i, item in pets do
		local isEquipped = table.find(equipped, item.uid) ~= nil
		local row = math.floor((i - 1) / cols)
		local color = T.Rarity[item.rarity] or T.Slot
		local def = Config.pet(item.id)
		cards[item.uid] = e(U.Tile, {
			Name = "Pet_" .. item.uid,
			Position = UDim2.fromOffset(16 + (i - 1) % cols * (cardW + gap), paddingY + row * (cardH + gap)),
			Size = UDim2.fromOffset(cardW, cardH),
			Color = color:Lerp(T.Outline, p.ImmersivePets and 0.08 or 0.2),
			BorderColor = color:Lerp(Color3.new(1, 1, 1), 0.5),
			SelectionColor = CYAN,
			Selected = item.uid == pet.uid,
			Quiet = true,
			Studs = false,
			OnActivated = function()
				if p.Feedback then
					p.Feedback()
				end
				p.SelectPet(item.uid)
				setConfirm(false)
			end,
			Children = {
				Preview = def and row >= firstRow - 1 and row <= firstRow + visibleRows and e(PetCardImage, {
					Id = item.id,
					Pet = item,
					Def = def,
					Key = item.uid,
					FitToView = true,
					ReducedMotion = true,
					MultilineName = p.ImmersivePets,
					Position = UDim2.fromOffset((cardW - artworkSize) / 2, 3),
					Size = UDim2.fromOffset(artworkSize, p.ImmersivePets and cardH - 30 or artworkSize),
				}) or nil,
				Power = power(item.boost, cardW, cardH - 29, p.ImmersivePets and 25 or p.Phone and 17 or 22),
				Check = isEquipped and checkMark(cardW) or nil,
			},
		})
	end
	local isEquipped = table.find(equipped, pet.uid) ~= nil
	local full = not isEquipped and #equipped >= 3
	-- Both imported models and raster portraits carry their own name/rarity.
	local illustrated = true
	local previewY = if illustrated then 4 else p.Phone and 28 or 48
	local details: any = {

		Name = not illustrated and label(pet.name, 6, 4, detailW - 12, p.Phone and 24 or 40, p.Phone and 18 or 26)
			or nil,
		Preview = e(PetCardImage, {
			Id = pet.id,
			Pet = pet,
			Def = Config.pet(pet.id),
			Key = pet.uid,
			Position = UDim2.fromOffset(5, previewY),
			Size = UDim2.fromOffset(
				detailW - 10,
				math.max(
					28,
					detailH - previewY - (if illustrated then (p.Phone and 80 or 100) else (p.Phone and 100 or 128))
				)
			),
			FitToView = true,
			ReducedMotion = p.Reduced,
			Animated = true,
		}),
		Rarity = not illustrated and label(
			pet.rarity,
			4,
			detailH - (p.Phone and 98 or 124),
			detailW - 8,
			p.Phone and 22 or 26,
			p.Phone and 17 or 22,
			T.Rarity[pet.rarity]
		) or nil,
		Power = power(pet.boost, detailW, detailH - (p.Phone and 75 or 92), p.Phone and 21 or 29),
		Equip = button(
			"EquipSelected",
			isEquipped and "Unequip" or full and "Team Full" or "Equip",
			8,
			detailH - 46,
			detailW - 16,
			44,
			function()
				p.Request("Pet", pet.uid)
			end,
			isEquipped and T.Colors.Red or T.Colors.Green,
			p.Busy or full
		),
	}
	local footerW, footerGap = Spacing.row(gridW - 16, 4, 44)
	local result: any = {
		Count = label(tostring(#pets) .. " / 60", 0, 0, detailW, header - 4, p.Phone and 18 or 25),
		Equipped = label(
			"Team " .. #equipped .. "/3 • " .. (p.Data.petMaterial or 0) .. " Shards",
			gridX,
			0,
			gridW,
			header - 4,
			p.Phone and 18 or 27
		),
		Details = e(U.Surface, {
			Name = "PetDetails",
			Position = UDim2.fromOffset(0, header),
			Size = UDim2.fromOffset(detailW, detailH),
			Color = C(48, 100, 119),
			BorderColor = CYAN,
			Outline = 3,
			Quiet = true,
			NoShadow = true,
			Children = details,
		}),
		Grid = recess("PetGridPanel", gridX, header, gridW, gridH, {
			Scroll = e(U.Scroll, {
				Name = "PetGrid",
				Size = UDim2.fromScale(1, 1),
				Height = paddingY * 2 + math.ceil(#pets / cols) * (cardH + gap) - gap,
				BarColor = CYAN,
				OnCanvasPosition = function(y: number)
					setFirstRow(math.floor(y / (cardH + gap)))
				end,
				Children = cards,
			}),
		}),
		Delete = button(
			"RecycleSelected",
			"Recycle",
			gridX + 8,
			h - 44,
			footerW,
			44,
			function()
				setConfirm(true)
			end,
			T.Colors.Red,
			p.Busy or isEquipped or not Config.Balance.Crafting.Yield[pet.rarity] or pet.id == "AdminDragon"
		),
		Best = button("EquipBest", "Best", gridX + 8 + footerW + footerGap, h - 44, footerW, 44, function()
			p.Request("EquipBest")
		end, T.Colors.Green, p.Busy),
		CraftHint = label(Variants.name(pet), gridX, h - 68, gridW, 20, 14, T.Gold),
		Upgrade = button(
			"OpenPetWorkshop",
			"Craft",
			gridX + 8 + 3 * (footerW + footerGap),
			h - 44,
			footerW,
			44,
			function()
				p.Request("PetCraft")
			end,
			T.Colors.Blue,
			p.Busy
		),
		Sort = button(
			"SortPets",
			byName and "Name" or "Power",
			gridX + 8 + 2 * (footerW + footerGap),
			h - 44,
			footerW,
			44,
			function()
				setByName(not byName)
			end,
			T.Gold
		),
	}
	if p.ImmersivePets then
		local rarityColor = T.Rarity[pet.rarity] or T.Slot
		local common = pet.rarity == "Common"
		local detailBorder = if common then T.Outline else rarityColor:Lerp(Color3.new(1, 1, 1), 0.4)
		local available = w - 24
		local bestW, utilityW, countW =
			math.floor(available * 0.32), math.floor(available * 0.32), math.floor(available * 0.26)
		local groupGap = (available - bestW - utilityW - countW) / 2
		local footerY = h - 78
		local utilityX = 12 + bestW + groupGap
		local countX = utilityX + utilityW + groupGap
		local actionW, actionGap = Spacing.row(utilityW - 20, 3, 50)
		result.Count = nil
		result.Equipped = nil
		result.Delete = nil
		result.Sort = nil
		result.Upgrade = nil
		result.CraftHint = nil
		result.Best = e(Controls.Button, {
			Name = "EquipBest",
			Text = "Equip Best",
			Position = UDim2.fromOffset(12, footerY),
			Size = UDim2.fromOffset(bestW, 70),
			TextSize = 38,
			Color = C(155, 255, 0),
			TopColor = C(245, 255, 0),
			BottomColor = C(113, 255, 0),
			Disabled = p.Busy,
			OnActivated = function()
				p.Request("EquipBest")
			end,
		})
		result.Utility = e(Controls.Plate, {
			Name = "PetUtilityBar",
			Position = UDim2.fromOffset(utilityX, footerY),
			Size = UDim2.fromOffset(utilityW, 70),
			Children = {
				Recycle = e(Controls.Action, {
					Name = "RecycleSelected",
					Text = "Recycle",
					Icon = "Recycle",
					Position = UDim2.fromOffset(10, 7),
					Size = UDim2.fromOffset(actionW, 50),
					Disabled = p.Busy
						or isEquipped
						or not Config.Balance.Crafting.Yield[pet.rarity]
						or pet.id == "AdminDragon",
					OnActivated = function()
						setConfirm(true)
					end,
				}),
				Sort = e(Controls.Action, {
					Name = "SortPets",
					Text = byName and "Name" or "Power",
					Icon = "Skill",
					Position = UDim2.fromOffset(10 + actionW + actionGap, 7),
					Size = UDim2.fromOffset(actionW, 50),
					OnActivated = function()
						setByName(not byName)
					end,
				}),
				Craft = e(Controls.Action, {
					Name = "OpenPetWorkshop",
					Text = "Craft",
					Icon = "PetCraft",
					Position = UDim2.fromOffset(10 + 2 * (actionW + actionGap), 7),
					Size = UDim2.fromOffset(actionW, 50),
					Disabled = p.Busy,
					OnActivated = function()
						p.Request("PetCraft")
					end,
				}),
			},
		})
		result.Capacity = e(Controls.Plate, {
			Name = "PetCapacity",
			Position = UDim2.fromOffset(countX, footerY + 11),
			Size = UDim2.fromOffset(countW, 48),
			Children = {
				Paw = e(
					U.Icon,
					{ Kind = "PetTeam", Position = UDim2.fromScale(0.02, 0.12), Size = UDim2.fromScale(0.21, 0.76) }
				),
				Team = e(U.Label, {
					Name = "TeamCount",
					Text = #equipped .. "/3",
					Position = UDim2.fromScale(0.23, 0),
					Size = UDim2.fromScale(0.23, 1),
					TextSize = 20,
					Scaled = true,
				}),
				Box = e(
					U.Icon,
					{ Kind = "PetStorage", Position = UDim2.fromScale(0.49, 0.12), Size = UDim2.fromScale(0.21, 0.76) }
				),
				Count = e(U.Label, {
					Name = "StorageCount",
					Text = #pets .. "/60",
					Position = UDim2.fromScale(0.70, 0),
					Size = UDim2.fromScale(0.28, 1),
					TextSize = 19,
					Scaled = true,
				}),
			},
		})
		result.Details = e(PetDetailPlane, {
			Color = rarityColor,
			BorderColor = detailBorder,
			GlowColor = if common then T.Outline:Lerp(T.Text, 0.12) else rarityColor,
			X = w + 45,
			Y = -70,
			Width = detailW,
			Height = detailH,
			AnchorWidth = 250,
			AnchorHeight = 506,
			Visible = p.Visible,
			Interactive = not confirm,
			Reduced = p.Reduced,
			Children = {
				Name = e(U.Label, {
					Name = "SelectedPetName",
					Text = Variants.name(pet),
					Position = UDim2.fromOffset(14, 14),
					Size = UDim2.fromOffset(detailW - 28, 44),
					TextSize = 38,
					MaxTextSize = 76,
					Scaled = true,
					MinTextSize = 16,
					Wrap = true,
				}),
				Rarity = e(U.Surface, {
					Name = "RarityPill",
					Position = UDim2.fromOffset(72, 65),
					Size = UDim2.fromOffset(detailW - 144, 32),
					Quiet = true,
					Color = rarityColor:Lerp(T.Outline, 0.65),
					BorderColor = detailBorder,
					Outline = 2,
					Radius = 16,
					NoShadow = true,
					Children = {
						Text = e(U.Label, {
							Text = pet.rarity,
							TextSize = 21,
							Color = if common then T.Text else detailBorder,
						}),
					},
				}),
				Preview = e(PetCardImage, {
					Id = pet.id,
					Pet = pet,
					Def = Config.pet(pet.id),
					Key = pet.uid,
					PortraitOnly = true,
					FitToView = true,
					ReducedMotion = true,
					Position = UDim2.fromOffset(10, 102),
					Size = UDim2.fromOffset(detailW - 20, detailH - 238),
				}),
				Power = e("Frame", {
					Name = "SelectedPower",
					Position = UDim2.fromOffset(38, detailH - 160),
					Size = UDim2.fromOffset(detailW - 76, 60),
					BackgroundTransparency = 1,
				}, {
					Icon = e(U.Icon, { Kind = "Skill", Size = UDim2.fromOffset(52, 60) }),
					Value = e(U.Label, {
						Text = "×" .. Config.formatBoost(pet.boost),
						Position = UDim2.fromOffset(59, 0),
						Size = UDim2.new(1, -59, 1, 0),
						TextSize = 52,
						MaxTextSize = 104,
						Scaled = true,
						Color = GREEN,
					}),
				}),
				Equip = e(Controls.Button, {
					Name = "EquipSelected",
					Text = isEquipped and "Unequip" or full and "Team Full" or "Equip",
					Position = UDim2.fromOffset(22, detailH - 91),
					Size = UDim2.fromOffset(detailW - 44, 58),
					Color = isEquipped and C(255, 34, 89) or T.Colors.Green,
					TextSize = 42,
					Disabled = p.Busy or full,
					OnActivated = function()
						p.Request("Pet", pet.uid)
					end,
				}),
			},
		})
	end
	if confirm then
		result.Confirm = e("TextButton", {
			Name = "DeleteConfirmation",
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 0.15,
			BackgroundColor3 = T.Outline,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 70,
		}, {
			Box = e(U.Surface, {
				Size = UDim2.fromOffset(math.min(w - 16, 400), 180),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Color = T.Body,
				ZIndex = 75,
				Children = {
					Title = e(U.Label, {
						Text = "Recycle "
							.. pet.name
							.. " for "
							.. (Config.Balance.Crafting.Yield[pet.rarity] or 0)
							.. " Shards permanently?",
						Position = UDim2.fromOffset(12, 8),
						Size = UDim2.new(1, -24, 0, 82),
						TextSize = 23,
						Wrap = true,
						ZIndex = 90,
					}),
					Keep = e(U.Button, {
						Name = "KeepPet",
						Text = "Keep",
						Position = UDim2.new(0, 16, 1, -62),
						Size = UDim2.new(0.5, -32, 0, 44),
						ZIndex = 90,
						OnActivated = function()
							setConfirm(false)
						end,
					}),
					Delete = e(U.Button, {
						Name = "ConfirmDeletePet",
						Text = "Recycle",
						Position = UDim2.new(0.5, 16, 1, -62),
						Size = UDim2.new(0.5, -32, 0, 44),
						Color = T.Colors.Red,
						ZIndex = 90,
						OnActivated = function()
							p.Request("RecyclePet", pet.uid)
							setConfirm(false)
						end,
					}),
				},
			}),
		})
	end
	return frame("PetsInventory", result, w, h)
end
return Pages
