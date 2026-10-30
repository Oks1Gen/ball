--!strict
local React = require(game.ReplicatedStorage.Packages.React)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local BallCardArt = require(script.Parent.Parent.Modules.BallCardArt)
local Spacing = require(game.ReplicatedStorage.Shared.UiSpacing)
local U = require(script.Parent.Components)
local T = require(script.Parent.Theme)
local Art = require(script.Parent.Art)
local PetCardArt = require(script.Parent.Parent.Modules.PetCardArt)
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
local function power(value: number, w: number, y: number, size: number): any
	return frame("Power", {
		Icon = e(
			U.Icon,
			{ Kind = "Skill", Position = UDim2.fromOffset(4, y), Size = UDim2.fromOffset(size + 6, size + 6) }
		),
		Value = label("×" .. tostring(value), size + 6, y, w - size - 10, size + 6, size, GREEN),
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
				Power = power(item.power, cardW, cardH - 29, p.Phone and 17 or 22),
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
		Power = power(selected.power, detailW, panelH - 98, p.Phone and 21 or 29),
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
	local image = PetCardArt.image(p.Id)
	local ref: any = React.useRef(nil)
	React.useEffect(function()
		if ref.current then
			Art.bind(ref.current)
		end
	end, { p.Id })
	if not image then
		return e(U.PetView, p)
	end
	return e("Frame", {
		Name = "PetIllustration",
		BackgroundTransparency = 1,
		Position = p.Position,
		Size = p.Size,
		ZIndex = 15,
	}, {
		Image = e("ImageLabel", {
			ref = ref,
			Name = "PetCardArt",
			Image = image,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 14),
			Size = UDim2.new(1, 0, 1, -30),
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 15,
			Active = false,
		}),
		Rarity = e(U.Label, {
			Text = p.Def.rarity,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 14),
			TextSize = 14,
			Scaled = true,
			MinTextSize = 9,
			Color = T.Rarity[p.Def.rarity],
			ZIndex = 16,
		}),
		Name = e(U.Label, {
			Text = p.Def.name,
			Position = UDim2.new(0, 0, 1, -16),
			Size = UDim2.new(1, 0, 0, 16),
			TextSize = 14,
			Scaled = true,
			MinTextSize = 8,
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
	local header = p.Phone and 26 or 34
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
	local detailW = p.Phone and 132 or 184
	local gridX, gridW = detailW + 16, w - detailW - 16
	local gridH = h - header - 70
	local detailH = h - header
	local cols = p.Phone and (gridW >= 300 and 3 or 2) or 4
	local cardW, gap = Spacing.row(gridW - 32, cols, 92)
	local paddingY = p.Phone and 8 or 16
	local cardH = if p.Phone then math.min(cardW + 28, math.max(72, gridH - paddingY * 2)) else cardW + 28
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
			Color = color:Lerp(T.Outline, 0.2),
			BorderColor = color:Lerp(Color3.new(1, 1, 1), 0.5),
			SelectionColor = CYAN,
			Selected = item.uid == pet.uid,
			Quiet = true,
			Studs = false,
			OnActivated = function()
				p.SelectPet(item.uid)
				setConfirm(false)
			end,
			Children = {
				Preview = def and row >= firstRow - 1 and row <= firstRow + visibleRows and e(PetCardImage, {
					Id = item.id,
					Def = def,
					Key = item.uid,
					FitToView = true,
					ReducedMotion = true,
					Position = UDim2.fromOffset((cardW - artworkSize) / 2, 3),
					Size = UDim2.fromOffset(artworkSize, artworkSize),
				}) or nil,
				Power = power(item.boost, cardW, cardH - 29, p.Phone and 17 or 22),
				Check = isEquipped and checkMark(cardW) or nil,
			},
		})
	end
	local isEquipped = table.find(equipped, pet.uid) ~= nil
	local full = not isEquipped and #equipped >= 3
	local illustrated = PetCardArt.image(pet.id) ~= nil
	local previewY = if illustrated then 4 else p.Phone and 28 or 48
	local details: any = {

		Name = not illustrated and label(pet.name, 6, 4, detailW - 12, p.Phone and 24 or 40, p.Phone and 18 or 26)
			or nil,
		Preview = e(PetCardImage, {
			Id = pet.id,
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
	local footerW, footerGap = Spacing.row(gridW - 16, 3, 44)
	local result: any = {
		Count = label(tostring(#pets) .. " / 60", 0, 0, detailW, header - 4, p.Phone and 18 or 25),
		Equipped = label("Equipped: " .. #equipped .. " / 3", gridX, 0, gridW, header - 4, p.Phone and 18 or 27),
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
		Delete = button("DeleteSelected", "Delete", gridX + 8, h - 44, footerW, 44, function()
			setConfirm(true)
		end, T.Colors.Red, p.Busy),
		Best = button(
			"EquipBest",
			p.Phone and "Best" or "Equip Best",
			gridX + 8 + footerW + footerGap,
			h - 44,
			footerW,
			44,
			function()
				p.Request("EquipBest")
			end,
			T.Colors.Green,
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
						Text = "Delete " .. pet.name .. " permanently?",
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
						Text = "Delete",
						Position = UDim2.new(0.5, 16, 1, -62),
						Size = UDim2.new(0.5, -32, 0, 44),
						Color = T.Colors.Red,
						ZIndex = 90,
						OnActivated = function()
							p.Request("DeletePet", pet.uid)
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
