--!strict
local React = require(game.ReplicatedStorage.Packages.React)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local U = require(script.Parent.Components)
local T = require(script.Parent.Theme)
local Spacing = require(game.ReplicatedStorage.Shared.UiSpacing)
local MotionConfig = require(game.ReplicatedStorage.Shared.UiMotionConfig)
local EggCardLayout = require(script.Parent.EggCardLayout)
local HatchStage = require(script.Parent.HatchStage)
local Presentation = require(script.Parent.Parent.Modules.UiPresentation)
local e = React.createElement
local S = {}
type InventoryPet = { uid: string, id: string, name: string, rarity: string, boost: number }
-- The delete confirmation covers the whole screen content and opens a dialog
-- on top of it. The overlay has to stay above the content it dims and the
-- dialog has to stay above the overlay, otherwise its buttons are dead.
local LAYER_CONFIRM = 70
local LAYER_CONFIRM_BOX = 75
local function label(text, x, y, w, h, size, color)
	return e(U.Label, {
		Text = text,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		TextSize = size,
		Color = color,
		Small = size < 20,
	})
end
local function button(name, text, x, y, w, h, callback, color, disabled, size)
	return e(U.Button, {
		Name = name,
		Text = text,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		OnActivated = callback,
		Color = color,
		Disabled = disabled,
		TextSize = size or 21,
	})
end
local function rarity(value)
	return T.Rarity[value] or T.Colors.Pets
end
local function childrenFrame(children, x, y, w, h)
	return e(
		"Frame",
		{ BackgroundTransparency = 1, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), ZIndex = 11 },
		children
	)
end
function S.Pets(p)
	local inventory = p.Inventory
	local equipped: { string } = inventory.equipped
	local pets: { InventoryPet } = table.clone(inventory.pets)
	table.sort(pets, function(a, b)
		local ae = table.find(equipped, a.uid) ~= nil
		local be = table.find(equipped, b.uid) ~= nil
		if ae ~= be then
			return ae
		end
		if a.boost ~= b.boost then
			return a.boost > b.boost
		end
		return a.uid < b.uid
	end)
	local selected, setSelected = React.useState(nil)
	local confirm, setConfirm = React.useState(nil)
	local firstRow, setFirstRow = React.useState(0)
	local pet: InventoryPet? = nil
	for _, item in pets do
		if item.uid == selected then
			pet = item
			break
		end
	end
	pet = pet or pets[1]
	local w: number, h: number = p.Width, p.Height
	if #pets == 0 then
		local art = p.Phone and 96 or 150
		local contentWidth = math.min(w - 32, 480)
		local x = (w - contentWidth) / 2
		return childrenFrame({
			Art = e(U.Icon, {
				Kind = "Pets",
				Position = UDim2.fromOffset(x, math.max(4, (h - art) / 2)),
				Size = UDim2.fromOffset(art, art),
			}),
			Title = label(
				"Your first pet awaits!",
				x + art + 16,
				math.max(4, h / 2 - 72),
				contentWidth - art - 16,
				32,
				p.Phone and 21 or 27
			),
			Hint = e(U.Label, {
				Text = "Hatch an egg to gain a Skill boost.",
				Position = UDim2.fromOffset(x + art + 16, math.max(40, h / 2 - 34)),
				Size = UDim2.fromOffset(contentWidth - art - 16, 48),
				TextSize = p.Phone and 17 or 21,
				Wrap = true,
			}),
			FindEggs = button(
				"FindEggs",
				"Find Eggs",
				x + art + 16,
				h / 2 + 26,
				contentWidth - art - 16,
				48,
				function()
					p.Open("Eggs")
				end,
				T.Colors.Eggs
			),
		}, 0, 0, w, h)
	end
	local compact = w < 730
	local previewWidth = compact and 0 or 220
	local gridW = w - previewWidth - (compact and 0 or 16)
	local inset = p.Phone and 8 or MotionConfig.Spacing.ScrollInset
	local cols = gridW < 380 and 2 or compact and 3 or 4
	local footer = 62
	local header = 32
	local gridH = h - footer - header
	local cardH = p.Phone and math.max(72, gridH - inset * 2) or (compact and math.clamp(gridH - 12, 132, 176) or 136)
	local cardW, gap = Spacing.row(gridW - inset * 2, cols, cardH)
	local visibleRows = math.ceil(gridH / (cardH + gap))
	local slots, cards = math.max(9, #pets), {}
	for i = 1, slots do
		local item = pets[i]
		local def = item and Config.pet(item.id)
		local isEquipped = item and table.find(equipped, item.uid) ~= nil
		local chosen = item and pet and item.uid == pet.uid
		local content = {}
		if item then
			-- Keep real pet portraits only for visible rows plus one row of
			-- overscan. Scrolling sixty pets must not allocate sixty viewports.
			local row = math.floor((i - 1) / cols)
			if row >= firstRow - 1 and row <= firstRow + visibleRows then
				content.Preview = def
						and e(U.PetView, {
							Def = def,
							Key = item.uid,
							FitToView = true,
							ReducedMotion = true,
							Size = UDim2.fromOffset(cardW - 16, cardH - (p.Phone and 58 or 45)),
							Position = UDim2.fromOffset(14, 9),
						})
					or label("?", 14, 9, cardW - 28, cardH - 74, 36, T.Muted)
			end
			content.Name = e(U.Label, {
				Text = item.name,
				Position = UDim2.fromOffset(5, cardH - 44),
				Size = UDim2.fromOffset(cardW - 10, 20),
				TextSize = p.Phone and 14 or 13,
				Small = true,
				Wrap = true,
			})
			content.Power = label("×" .. item.boost .. " Skill", 5, cardH - 26, cardW - 10, 22, 18, T.Gold)
			if isEquipped then
				content.Check = e(U.Surface, {
					Color = T.Colors.Green,
					Radius = 9,
					Size = UDim2.fromOffset(28, 28),
					Position = UDim2.new(1, -32, 0, 4),
					NoShadow = true,
					Studs = false,
					ZIndex = 18,
					Children = { Mark = e(U.Label, { Text = "✓", TextSize = 20, ZIndex = 30 }) },
				})
			end
		end
		cards[tostring(i)] = e(U.Tile, {
			Name = item and "Pet_" .. item.uid or "EmptySlot" .. i,
			Position = UDim2.fromOffset(
				inset + (i - 1) % cols * (cardW + gap),
				inset + math.floor((i - 1) / cols) * (cardH + gap)
			),
			Size = UDim2.fromOffset(cardW, cardH),
			Color = item and (isEquipped and Color3.fromRGB(42, 160, 49) or T.plate(rarity(item.rarity))) or T.Slot,
			Quiet = item == nil,
			Studs = false,
			Selected = chosen,
			Disabled = item == nil,
			Inert = item == nil,
			OnActivated = function()
				if item then
					setSelected(item.uid)
					setConfirm(nil)
				end
			end,
			Children = content,
		})
	end
	local bestWidth = compact and 126 or math.min(230, math.floor(w * 0.42))
	local result = {
		OwnedCount = label("Pets: " .. #pets .. " / 60", 6, 0, math.floor(w / 2) - 12, 26, 18, T.Muted),
		EquippedCount = label(
			"Equipped: " .. #equipped .. " / 3",
			math.floor(w / 2),
			0,
			math.floor(w / 2) - 6,
			26,
			18,
			T.Gold
		),
		Grid = e(U.Scroll, {
			Name = "PetGrid",
			Position = UDim2.fromOffset(compact and 0 or previewWidth + 16, header),
			Size = UDim2.fromOffset(gridW, gridH),
			Height = inset * 2 + math.ceil(slots / cols) * (cardH + gap) - gap,
			OnCanvasPosition = function(y: number)
				setFirstRow(math.floor(y / (cardH + gap)))
			end,
			Children = cards,
		}),
		EquipBest = button("EquipBest", "Equip Best", 4, h - 50, bestWidth, 44, function()
			p.Request("EquipBest")
		end, nil, p.Busy or #pets == 0),
	}
	if not compact then
		local x, pw = 0, previewWidth
		local detail = {}
		if pet then
			local def = Config.pet(pet.id)
			local isEquipped = table.find(equipped, pet.uid) ~= nil
			local full = not isEquipped and #equipped >= 3
			detail.Name = label(pet.name, 8, 8, pw - 16, 34, 24)
			detail.Rarity = label(pet.rarity, 8, 44, pw - 16, 26, 20, rarity(pet.rarity))
			detail.Preview = e(U.PetView, {
				Def = def,
				Key = pet.uid,
				Position = UDim2.fromOffset(12, 65),
				Size = UDim2.fromOffset(pw - 24, gridH - 228),
				Animated = true,
				ReducedMotion = p.Reduced,
				FitToView = true,
			})
			detail.Power = label("×" .. pet.boost .. " Skill", 8, gridH - 159, pw - 16, 30, 25, T.Gold)
			detail.Equip = button(
				"EquipSelected",
				p.Busy and "Please wait…" or (isEquipped and "Unequip" or full and "Team full (3 / 3)" or "Equip"),
				12,
				gridH - 118,
				pw - 24,
				46,
				function()
					p.Request("Pet", pet.uid)
				end,
				isEquipped and T.Colors.Blue or T.Colors.Green,
				p.Busy or full
			)
			detail.Delete = button("DeleteSelected", "Delete Pet", 12, gridH - 49, pw - 24, 44, function()
				setConfirm(pet.uid)
			end, T.Colors.Red, p.Busy, 18)
		else
			detail.Art =
				e(U.Icon, { Kind = "Pets", Position = UDim2.fromOffset(35, 25), Size = UDim2.fromOffset(pw - 70, 130) })
			detail.Hint = e(U.Label, {
				Text = "Hatch an egg to meet your first pet",
				Position = UDim2.fromOffset(12, 170),
				Size = UDim2.fromOffset(pw - 24, 50),
				TextSize = 20,
				Wrap = true,
			})
			detail.Eggs = button("FindEggs", "Find Eggs", 12, gridH - 65, pw - 24, 46, function()
				p.Open("Eggs")
			end, T.Colors.Eggs)
		end
		result.Details = e(U.Slot, {
			Name = "PetDetails",
			Position = UDim2.fromOffset(x, header),
			Size = UDim2.fromOffset(pw, gridH - 4),
			Color = T.Recess,
			Children = detail,
		})
	elseif pet then
		local footerWidth, footerGap = Spacing.row(w - inset * 2, 3, 44)
		result.EquipBest = button("EquipBest", "Equip Best", inset, h - 50, footerWidth, 44, function()
			p.Request("EquipBest")
		end, nil, p.Busy)
		local yes = table.find(equipped, pet.uid) ~= nil
		local full = not yes and #equipped >= 3
		result.EquipSelected = button(
			"EquipSelected",
			yes and "Unequip" or full and "Team Full" or "Equip",
			inset + footerWidth + footerGap,
			h - 50,
			footerWidth,
			44,
			function()
				p.Request("Pet", pet.uid)
			end,
			yes and T.Colors.Blue or T.Colors.Green,
			p.Busy or full,
			18
		)
		result.Delete = button(
			"DeleteSelected",
			"Delete",
			inset + 2 * (footerWidth + footerGap),
			h - 50,
			footerWidth,
			44,
			function()
				setConfirm(pet.uid)
			end,
			T.Colors.Red,
			p.Busy,
			18
		)
	end
	if confirm and pet and confirm == pet.uid then
		local confirmWidth = math.min(430, w - 12)
		local actionWidth, actionGap = Spacing.row(confirmWidth - 32, 2, 46)
		result.Confirm = e("TextButton", {
			Name = "DeleteConfirmation",
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = T.Outline,
			BackgroundTransparency = 0.15,
			ZIndex = LAYER_CONFIRM,
		}, {
			Box = e(U.Surface, {
				Size = UDim2.fromOffset(confirmWidth, 190),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Color = T.Body,
				ZIndex = LAYER_CONFIRM_BOX,
				Children = {
					Title = e(U.Label, {
						Text = "Delete " .. pet.name .. " permanently?",
						Position = UDim2.fromOffset(12, 12),
						Size = UDim2.new(1, -24, 0, 72),
						Wrap = true,
						TextSize = 23,
						ZIndex = 90,
					}),
					Keep = e(U.Button, {
						Name = "KeepPet",
						Text = "Keep",
						Position = UDim2.new(0, 16, 1, -64),
						Size = UDim2.fromOffset(actionWidth, 46),
						ZIndex = 90,
						OnActivated = function()
							setConfirm(nil)
						end,
					}),
					Delete = e(U.Button, {
						Name = "ConfirmDeletePet",
						Text = "Delete",
						Position = UDim2.new(0, 16 + actionWidth + actionGap, 1, -64),
						Size = UDim2.fromOffset(actionWidth, 46),
						Color = T.Colors.Red,
						ZIndex = 90,
						OnActivated = function()
							p.Request("DeletePet", pet.uid)
							setConfirm(nil)
						end,
					}),
				},
			}),
		})
	end
	return childrenFrame(result, 0, 0, w, h)
end
function S.Eggs(p)
	local w, h = p.Width, p.Height
	local compact = w < 730
	local egg = Config.find(Config.Eggs, p.EggId) or Config.Eggs[1]
	local pool = Config.eggPets(egg.id)
	local cost = egg.cost * (p.Data.world == 2 and 10 or 1)
	local tabs = {}
	local tabW, tabGap = Spacing.row(w - 32, 4, 44)
	for i, item in Config.Eggs do
		tabs[item.id] = button("EggTab" .. item.id, item.id, 16 + (i - 1) * (tabW + tabGap), 0, tabW, 44, function()
			p.SelectEgg(item.id)
		end, item.id == egg.id and T.Colors.Eggs or T.Colors.Slate, false, p.Phone and 13 or compact and 15 or 18)
	end
	local leftW = w >= 1000 and math.floor(w * 0.24) or 0
	local rightX = leftW == 0 and 0 or leftW + 20
	local rightW = w - rightX
	local poolY = p.Phone and (p.UnifiedInventory and 54 or 58) or 91
	local poolHeight = p.Phone and h - (p.UnifiedInventory and 120 or 112) or h - 184
	local poolInset = p.UnifiedInventory and (p.Phone and 6 or 16) or 0
	local layout = EggCardLayout.calculate(
		rightW - poolInset * 2,
		poolHeight - poolInset * 2,
		#pool,
		p.Phone and "CompactSplit" or p.EggCardVariant
	)
	local cols, itemW, itemH = layout.Columns, layout.CardWidth, layout.CardHeight
	local function cardLabel(text: string, rect: { number }, size: number, color: Color3?)
		return e(U.Label, {
			Text = text,
			Position = UDim2.fromOffset(rect[1], rect[2]),
			Size = UDim2.fromOffset(rect[3], rect[4]),
			TextSize = size,
			Color = color,
			Wrap = not p.Phone,
			Scaled = p.Phone,
			MinTextSize = 12,
		})
	end
	local cards = {}
	local total = 0
	for _, item in pool do
		total += item.weight
	end
	for i, item in pool do
		local boost = item.boost * egg.boost * (p.Data.world == 2 and 3 or 1)
		cards[item.id] = e(U.Surface, {
			Name = "EggPet" .. item.id,
			Color = T.plate(rarity(item.rarity)),
			Quiet = p.UnifiedInventory,
			NoShadow = p.UnifiedInventory,
			BorderColor = p.UnifiedInventory and rarity(item.rarity):Lerp(Color3.new(1, 1, 1), 0.5) or nil,
			Position = UDim2.fromOffset(
				(i - 1) % cols * (itemW + 12) + 4,
				math.floor((i - 1) / cols) * (itemH + 12) + 4
			),
			Size = UDim2.fromOffset(itemW, itemH),
			Children = {
				Pet = e(U.PetView, {
					Def = item,
					Key = item.id,
					Position = UDim2.fromOffset(layout.Pet[1], layout.Pet[2]),
					Size = UDim2.fromOffset(layout.Pet[3], layout.Pet[4]),
					FitToView = true,
				}),
				Chance = cardLabel(
					string.format("%g%%", item.weight / total * 100),
					layout.Chance,
					p.Phone and 16 or 19,
					T.Gold
				),
				Name = cardLabel(item.name, layout.Name, 16),
				Boost = cardLabel("×" .. boost, layout.Boost, p.Phone and 15 or 17, T.Gold),
			},
		})
	end
	local hatchWidth, hatchGap = Spacing.row(w - 32, 2, 46)
	local result = {
		Tabs = childrenFrame(tabs, 0, 0, w, 44),
		Name = not p.Phone and label(egg.name, 8, 52, w - 16, 30, 25, T.Gold) or nil,
		-- The pool stays a scroll in every window size: it clips the cards, so
		-- they can never cover the hatch buttons, and scrolls the rows that
		-- do not fit.
		Pool = e(U.Scroll, {
			Name = "EggOutcomes",
			Position = UDim2.fromOffset(rightX, poolY),
			Size = UDim2.fromOffset(rightW, poolHeight),
			Height = layout.CanvasHeight,
			Children = cards,
		}),
		Hatch = button(
			"Hatch",
			(Presentation.keyboard() and "E • " or "") .. "Hatch / " .. Config.format(cost) .. " Wins",
			16,
			h - (p.Phone and 48 or 82),
			hatchWidth,
			46,
			function()
				p.Request("Hatch", egg.id, 1)
			end,
			nil,
			p.Busy or #p.Inventory.pets >= 60,
			compact and 16 or 21
		),
		Triple = button(
			"Hatch3",
			(Presentation.keyboard() and "R • " or "") .. "Hatch 3 / " .. Config.format(cost * 3) .. " Wins",
			16 + hatchWidth + hatchGap,
			h - (p.Phone and 48 or 82),
			hatchWidth,
			46,
			function()
				p.Request("Hatch", egg.id, 3)
			end,
			T.Colors.Eggs,
			p.Busy or #p.Inventory.pets > 57,
			compact and 16 or 21
		),
		Hint = not p.Phone and label("Hatch teleports you to the selected egg", 5, h - 27, w - 10, 24, 17, T.Muted)
			or nil,
	}
	if p.UnifiedInventory then
		result.Pool = e(U.Slot, {
			Name = "EggGridPanel",
			Position = UDim2.fromOffset(rightX, poolY),
			Size = UDim2.fromOffset(rightW, poolHeight),
			Color = T.Recess,
			Radius = 16,
			Outline = 3,
			NoShadow = true,
			Children = {
				Scroll = e(U.Scroll, {
					Name = "EggOutcomes",
					Position = UDim2.fromOffset(poolInset, poolInset),
					Size = UDim2.fromOffset(rightW - poolInset * 2, poolHeight - poolInset * 2),
					Height = layout.CanvasHeight,
					BarColor = Color3.fromRGB(125, 223, 255),
					Children = cards,
				}),
			},
		})
	end
	if leftW > 0 then
		result.Egg = e(U.Slot, {
			Position = UDim2.fromOffset(0, 91),
			Size = UDim2.fromOffset(leftW, h - 190),
			Color = T.Recess,
			Children = {
				Art = e(U.FloatingIcon, {
					Kind = "Egg",
					Position = UDim2.fromOffset(16, 14),
					Size = UDim2.new(1, -32, 1, -40),
					Reduced = p.Reduced,
				}),
			},
		})
	end
	return childrenFrame(result, 0, 0, w, h)
end
function S.Trails(p)
	local w: number = p.Width
	local h: number = p.Height
	local cards = {}
	local rowH = p.Phone and 112 or 155
	for i = 2, #Config.Trails do
		local item = Config.Trails[i]
		local owned, equipped = p.Data.trails[item.id], p.Data.trail == item.id
		local ink = item.id == "White" and Color3.fromRGB(208, 213, 222) or item.color
		cards[item.id] = e(U.Surface, {
			Name = "TrailCard" .. item.id,
			Position = UDim2.fromOffset(6, 6 + (i - 2) * (rowH + 18)),
			Size = UDim2.fromOffset(w - 22, rowH),
			Color = ink,
			Radius = 2,
			Outline = 4,
			Children = {
				Art = e(U.Icon, {
					Kind = item.id .. "Trail",
					Position = UDim2.fromOffset(12, 4),
					Size = UDim2.fromOffset(p.Phone and 96 or 210, rowH - 8),
				}),
				Name = label(
					item.name,
					p.Phone and 116 or 234,
					9,
					w - (p.Phone and 150 or 268),
					p.Phone and 28 or 46,
					p.Phone and 23 or 39
				),
				Trophy = e(U.Icon, {
					Kind = "Wins",
					Position = UDim2.fromOffset(p.Phone and 116 or 234, p.Phone and 44 or 58),
					Size = UDim2.fromOffset(p.Phone and 24 or 37, p.Phone and 24 or 36),
				}),
				Boost = label(
					"×" .. item.boost .. " Wins Boost",
					p.Phone and 146 or 274,
					p.Phone and 38 or 58,
					w - (p.Phone and 180 or 308),
					p.Phone and 20 or 28,
					p.Phone and 17 or 27,
					T.Gold
				),
				Action = button(
					"TrailAction" .. item.id,
					p.Busy and "Please wait…"
						or equipped and "Equipped"
						or owned and "Equip"
						or Config.format(item.cost) .. " Wins",
					w - 290,
					p.Phone and 64 or 102,
					250,
					44,
					function()
						p.Request("Trail", item.id)
					end,
					T.Colors.Green,
					p.Busy or equipped,
					28
				),
			},
		})
	end
	return e(U.Scroll, {
		Name = "TrailCollection",
		Size = UDim2.fromOffset(w, h),
		Height = (#Config.Trails - 1) * (rowH + 18) + 12,
		Children = cards,
	})
end

function S.Shop(p)
	local w: number, h: number = p.Width, p.Height
	local children = {}
	local function purchase(key)
		return function()
			p.Request("Product", key)
		end
	end
	local function buyButton(key, x, y, width, height)
		local product = Config.Products[key]
		local owned = p.Data.perks[key] == true
		local disabled = p.Busy
		return e(U.Button, {
			Name = "Buy" .. key,
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(width, height),
			Color = T.Colors.Green,
			Disabled = disabled,
			OnActivated = purchase(key),
			Children = {
				Currency = not owned and e(U.Icon, {
					Kind = "Robux",
					Position = UDim2.fromOffset(8, 6),
					Size = UDim2.fromOffset(height - 12, height - 12),
					ZIndex = 32,
				}) or nil,
				Price = label(
					owned and "Owned" or tostring(product.price),
					owned and 5 or height,
					2,
					width - (owned and 10 or height + 4),
					height - 4,
					28
				),
			},
		})
	end
	if p.Phone then
		local offers = {
			{ "StarterPack", "Starter Pack", "10K Wins + 2× Skill", "Wins", T.Colors.Gold },
			{ "AdminEgg", "Admin Egg", Config.AdminPet.name .. " • ×25 Skill", "Egg", T.Colors.Green },
			{ "DoubleSkill", "2× Skill", "Double your Skill gain", "Skill", T.Colors.Green },
			{ "DoubleWins", "2× Wins", "Double your Wins", "Wins", T.Colors.Gold },
			{ "AutoThrow", "Auto Kick", "Automatic kicks", "Ball", T.Colors.Blue },
			{ "Skill10M", "+10M Skill", "Instant Skill", "Skill", T.Colors.Gold },
			{ "Skill100M", "+100M Skill", "Instant Skill", "Skill", T.Colors.Red },
			{ "Skill1B", "+1B Skill", "Instant Skill", "Skill", T.Colors.Purple },
			{ "SkipRebirth", "Skip Rebirth", "Skip the level requirement", "Rebirth", T.Colors.Purple },
		}
		for i, info in offers do
			children[info[1]] = e(U.Surface, {
				Name = "Offer" .. info[1],
				Position = UDim2.fromOffset(12, 12 + (i - 1) * 124),
				Size = UDim2.fromOffset(w - 30, 104),
				Color = info[5],
				Children = {
					Icon = e(
						U.Icon,
						{ Kind = info[4], Position = UDim2.fromOffset(8, 16), Size = UDim2.fromOffset(72, 72) }
					),
					Title = label(info[2], 92, 8, w - 260, 30, 23),
					Details = e(U.Label, {
						Text = info[3],
						Position = UDim2.fromOffset(92, 42),
						Size = UDim2.fromOffset(w - 260, 52),
						TextSize = 17,
						Wrap = true,
					}),
					Buy = buyButton(info[1], w - 154, 44, 108, 48),
				},
			})
		end
		local bottom = 12 + #offers * 124
		children.EarnedAuto = button(
			"EarnAutoThrow",
			p.Data.perks.AutoThrow and "Auto Kick owned" or "Unlock Auto Kick • 2.5K Wins",
			12,
			bottom,
			w - 30,
			48,
			function()
				p.Request("UnlockAuto")
			end,
			T.Colors.Green,
			p.Busy,
			20
		)
		return e(
			U.Scroll,
			{ Name = "ShopOffers", Size = UDim2.fromOffset(w, h), Height = bottom + 68, Children = children }
		)
	end
	children.PackHeading = label("~ Pack ~", 0, 0, w, 36, 30)
	children.Starter = e(U.Surface, {
		Name = "StarterPackCard",
		Color = Color3.new(1, 1, 1),
		Rainbow = true,
		Position = UDim2.fromOffset(6, 48),
		Size = UDim2.fromOffset(w - 18, 226),
		Radius = 2,
		Outline = 4,
		Children = {
			Title = label("Starter Pack", 222, 8, w - 254, 52, 43, Color3.fromRGB(255, 245, 166)),
			Trophy = e(
				U.Icon,
				{ Kind = "Wins", Position = UDim2.fromOffset(14, 52), Size = UDim2.fromOffset(130, 142) }
			),
			Bolt = e(
				U.Icon,
				{ Kind = "Skill", Position = UDim2.fromOffset(116, 72), Size = UDim2.fromOffset(92, 116) }
			),
			Contents = label("10K WINS + 2× SKILL", 216, 68, w - 244, 38, 25),
			Wins = e(U.Slot, {
				Position = UDim2.fromOffset(230, 111),
				Size = UDim2.fromOffset(104, 91),
				Color = T.Colors.Blue,
				Transparency = 0.65,
				NoShadow = true,
				Children = {
					Icon = e(
						U.Icon,
						{ Kind = "Wins", Position = UDim2.fromOffset(28, 4), Size = UDim2.fromOffset(48, 48) }
					),
					Amount = label("10K", 0, 52, 104, 30, 25),
				},
			}),
			Skill = e(U.Slot, {
				Position = UDim2.fromOffset(346, 111),
				Size = UDim2.fromOffset(104, 91),
				Color = T.Colors.Purple,
				Transparency = 0.65,
				NoShadow = true,
				Children = {
					Icon = e(
						U.Icon,
						{ Kind = "Skill", Position = UDim2.fromOffset(28, 4), Size = UDim2.fromOffset(48, 48) }
					),
					Amount = label("×2", 0, 52, 104, 30, 25),
				},
			}),
			Buy = buyButton("StarterPack", w - 187, 146, 151, 52),
		},
	})
	children.LimitedHeading = label("~ Limited Offer ~", 0, 296, w, 40, 30)
	children.AdminEgg = e(U.Surface, {
		Name = "AdminEggOffer",
		Position = UDim2.fromOffset(6, 350),
		Size = UDim2.fromOffset(w - 18, 202),
		Color = Color3.fromRGB(126, 243, 38),
		Radius = 2,
		Outline = 4,
		Children = {
			Title = label("Admin Egg", 18, 8, w - 66, 40, 34),
			Egg = e(U.Icon, { Kind = "Egg", Position = UDim2.fromOffset(24, 56), Size = UDim2.fromOffset(115, 130) }),
			Pet = e(U.PetView, {
				Def = Config.AdminPet,
				Key = "ShopAdmin",
				Position = UDim2.fromOffset(158, 52),
				Size = UDim2.fromOffset(143, 135),
				FitToView = true,
				ReducedMotion = true,
			}),
			Name = label(Config.AdminPet.name, 312, 56, w - 356, 32, 25),
			Boost = label("×" .. Config.AdminPet.boost .. " SKILL", 312, 92, w - 356, 29, 24, T.Gold),
			Buy = buyButton("AdminEgg", w - 219, 137, 183, 48),
		},
	})
	children.UpgradesHeading = label("~ Upgrades ~", 0, 574, w, 40, 30)
	local offers = {
		{ "DoubleSkill", "2× Skill", "Skill", T.Colors.Green },
		{ "DoubleWins", "2× Wins", "Wins", T.Colors.Gold },
		{ "AutoThrow", "Auto Kick", "Ball", T.Colors.Blue },
		{ "Skill10M", "+10M Skill", "Skill", T.Colors.Gold },
		{ "Skill100M", "+100M Skill", "Skill", T.Colors.Red },
		{ "Skill1B", "+1B Skill", "Skill", T.Colors.Purple },
		{ "SkipRebirth", "Skip Rebirth", "Rebirth", T.Colors.Purple },
	}
	local cw = math.floor((w - 34) / 3)
	for i, info in offers do
		children[info[1]] = e(U.Surface, {
			Name = "Offer" .. info[1],
			Position = UDim2.fromOffset(6 + (i - 1) % 3 * (cw + 8), 632 + math.floor((i - 1) / 3) * 211),
			Size = UDim2.fromOffset(cw, 195),
			Color = info[4],
			Radius = 2,
			Outline = 3,
			Children = {
				Title = label(info[2], 4, 6, cw - 8, 29, 22),
				Icon = e(
					U.Icon,
					{ Kind = info[3], Position = UDim2.fromOffset(32, 39), Size = UDim2.fromOffset(cw - 64, 93) }
				),
				Buy = buyButton(info[1], 10, 143, cw - 20, 42),
			},
		})
	end
	local bottom = 632 + math.ceil(#offers / 3) * 211
	children.EarnedAuto = button(
		"EarnAutoThrow",
		p.Data.perks.AutoThrow and "Auto Kick owned" or "Unlock Auto Kick • 2.5K Wins",
		6,
		bottom,
		w - 18,
		46,
		function()
			p.Request("UnlockAuto")
		end,
		T.Colors.Green,
		p.Busy,
		24
	)
	return e(
		U.Scroll,
		{ Name = "ShopOffers", Size = UDim2.fromOffset(w, h), Height = bottom + 96, Children = children }
	)
end

function S.Hatch(p)
	return e(HatchStage, p)
end
return S
