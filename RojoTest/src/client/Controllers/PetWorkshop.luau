--!strict
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Ripple = require(game.ReplicatedStorage.Packages.Ripple)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local B = Config.Balance
local V = require(game.ReplicatedStorage.Shared.Core.PetVariants)
local State = require(game.ReplicatedStorage.Shared.Core.PetWorkshopState)
local U = require(script.Parent.Parent.CollectorUI.Components)
local T = require(script.Parent.Parent.CollectorUI.Theme)
local e = React.createElement
local View = {}
local event = Instance.new("BindableEvent")
local rejected = Instance.new("BindableEvent")
local receipt: any = nil
local palette = {
	Normal = T.Slot,
	Golden = T.Gold,
	Diamond = T.Colors.Blue,
	Rainbow = T.Colors.Purple,
	Fail = T.Colors.Red,
	Wind = T.Colors.Blue,
	Frost = Color3.fromRGB(134, 240, 255),
	Flame = Color3.fromRGB(255, 133, 47),
	Storm = T.Colors.Purple,
	Cosmic = T.Gold,
}
local function text(value: string, x: number, y: number, w: number, h: number, size: number, color: Color3?): any
	return e(U.Label, {
		Text = value,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		TextSize = size,
		Color = color,
		Wrap = true,
		Scaled = true,
		MinTextSize = 12,
	})
end
local function button(
	name: string,
	title: string,
	x: number,
	y: number,
	w: number,
	action: any,
	color: Color3,
	disabled: boolean?
): any
	return e(U.Button, {
		Name = name,
		Text = title,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, 44),
		TextSize = 19,
		Color = color,
		Disabled = disabled,
		OnActivated = action,
		Studs = false,
		NoShadow = true,
	})
end
local function portrait(pet: any, x: number, y: number, w: number, h: number, animated: boolean?): any
	local definition = pet and Config.pet(pet.id)
	return definition
			and e(U.PetPortrait, {
				Def = definition,
				Pet = pet,
				Key = pet.uid .. ":" .. tostring(pet.craftRevision or 0),
				Position = UDim2.fromOffset(x, y),
				Size = UDim2.fromOffset(w, h),
				Animated = animated ~= false,
				FitToView = true,
			})
		or text("?", x, y, w, h, 80)
end
function View.dismiss()
	receipt = nil
end
function View.reject()
	rejected:Fire()
end
function View.present(result: any)
	receipt = { result = result, at = os.clock() }
	event:Fire()
end
function View.mount(parent: Frame, context: any): () -> ()
	local host = Instance.new("Frame")
	host.Name = "PetWorkshop"
	host.Position = UDim2.fromOffset(18, 48)
	host.Size = UDim2.new(1, -36, 1, -64)
	host.BackgroundTransparency = 1
	host.Parent = parent
	local root = ReactRoblox.createRoot(host)
	local alive = true
	local function App(p: any): any
		local mode, setMode = React.useState("Fusion")
		local selected, setSelected = React.useState({} :: { string })
		local query, setQuery = React.useState("")
		local firstRow, setFirstRow = React.useState(0)
		local confirm, setConfirm = React.useState(false)
		local pending, setPending = React.useState(false)
		local shown, setShown = React.useState(nil :: any)
		local spinning, setSpinning = React.useState(false)
		local offset, updateOffset = React.useBinding(0)
		local data = p.Snapshot.data
		local inventory = State.inventory(p.Snapshot)
		local pets, equipped = inventory.pets, inventory.equipped
		local primary: any = nil
		local lookup: any = {}
		for _, pet in pets do
			lookup[pet.uid] = pet
		end
		primary = lookup[selected[1]]
		local ids = {}
		for _, uid in selected do
			if lookup[uid] then
				table.insert(ids, uid)
			end
		end
		local reason = primary and State.reason(primary, equipped, mode)
		local restricted = not p.Snapshot.purchasePolicyReady or p.Snapshot.paidRandomRestricted
		React.useEffect(function(): (() -> ())?
			local function receive()
				if receipt then
					setShown(receipt)
					setPending(false)
					setConfirm(false)
					setSelected({})
				end
			end
			local connection = event.Event:Connect(receive)
			local rejection = rejected.Event:Connect(function()
				setPending(false)
				setConfirm(false)
			end)
			receive()
			return function()
				connection:Disconnect()
				rejection:Disconnect()
			end
		end, {})
		React.useEffect(function(): (() -> ())?
			if not shown then
				return nil
			end
			local reduced = data.settings.effects == false
			setSpinning(true)
			local motion = Ripple.createMotion(0, { start = true })
			local disconnect = motion:onChange(updateOffset)
			motion:tween(-23 * 88, { duration = if reduced then 0.1 else 3.2, easing = "quartOut" })
			local active = true
			task.delay(if reduced then 0.15 else 3.3, function()
				if active then
					setSpinning(false)
					context.feedback(shown.result.outcome ~= "Fail", shown.result.outcome)
				end
			end)
			return function()
				active = false
				disconnect()
				motion:destroy()
			end
		end, { shown })
		React.useEffect(function()
			setPending(false)
			setConfirm(false)
		end, { equipped })
		React.useEffect(function(): (() -> ())?
			if not pending then
				return nil
			end
			local active = true
			task.delay(7, function()
				if active then
					setPending(false)
				end
			end)
			return function()
				active = false
			end
		end, { pending })
		local children: any = {}
		if shown then
			local result = shown.result
			local possible: any = {}
			if result.kind == "Fusion" then
				possible = V.odds(V.form(result.source), result.count)
			else
				local total = 0
				for _, m in B.Mutations do
					total += m.weight
				end
				for _, m in B.Mutations do
					table.insert(possible, { id = m.id, chance = m.weight / total })
				end
			end
			local reel: any = {}
			for i = 1, 26 do
				local id = if i == 24 then result.outcome else V.roll(possible, Random.new(i):NextNumber())
				reel[tostring(i)] = e(U.Surface, {
					Name = "Reel" .. i,
					Position = UDim2.fromOffset(8, (i - 1) * 88),
					Size = UDim2.fromOffset(444, 80),
					Color = palette[id],
					Quiet = true,
					Children = { Title = text(string.upper(id), 8, 8, 428, 60, 38) },
				})
			end
			children.Left = e(U.Surface, {
				Name = "ResultPet",
				Size = UDim2.fromOffset(354, 418),
				Color = T.Recess,
				Quiet = true,
				Children = {
					Rays = if not spinning and result.pet
						then e(U.Icon, {
							Kind = "Sunburst",
							Position = UDim2.fromOffset(18, 6),
							Size = UDim2.fromOffset(318, 260),
							ZIndex = 10,
						})
						else nil,
					Pet = portrait(if spinning then nil else result.pet, 20, 18, 314, 242),
					Title = text(
						if spinning then "Crafting..." else result.outcome,
						12,
						264,
						330,
						40,
						30,
						palette[result.outcome]
					),
					Name = text(
						if spinning
							then "Revealing your pet..."
							elseif result.pet then V.name(result.pet)
							else "Selected pets consumed",
						12,
						308,
						330,
						34,
						19
					),
					Boost = text(
						if not spinning and result.pet then "×" .. Config.formatBoost(result.pet.boost) else "",
						12,
						350,
						330,
						42,
						30,
						T.Colors.Green
					),
				},
			})
			children.Reel = e("Frame", {
				Name = "Roulette",
				Position = UDim2.fromOffset(376, 12),
				Size = UDim2.fromOffset(460, 316),
				BackgroundColor3 = T.Recess,
				ClipsDescendants = true,
			}, {
				Strip = e("Frame", {
					Name = "Strip",
					Position = offset:map(function(y: number)
						return UDim2.fromOffset(0, y + 114)
					end),
					Size = UDim2.fromOffset(460, 26 * 88),
					BackgroundTransparency = 1,
				}, reel),
			})
			children.Pointer = e(U.Surface, {
				Name = "SelectionFrame",
				NoShadow = true,
				Position = UDim2.fromOffset(374, 124),
				Size = UDim2.fromOffset(464, 84),
				Color = Color3.new(1, 1, 1),
				Transparency = 1,
				BorderColor = Color3.new(1, 1, 1),
				Outline = 4,
				Quiet = true,
				Children = { Left = text(">", 0, 15, 30, 50, 40), Right = text("<", 434, 15, 30, 50, 40) },
			})
			children.Continue = button("ContinueCraft", "Continue", 440, 364, 332, function()
				View.dismiss()
				setShown(nil)
			end, T.Colors.Green, spinning)
			return e("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, children)
		end
		children.Fusion = button("FusionTab", "Forms", 0, 0, 144, function()
			setMode("Fusion")
			setSelected({})
			setConfirm(false)
		end, if mode == "Fusion" then T.Gold else T.Slot)
		children.Mutations = button("MutationTab", "Mutations", 156, 0, 164, function()
			setMode("Mutation")
			setSelected({})
			setConfirm(false)
		end, if mode == "Mutation" then T.Colors.Purple else T.Slot)
		children.InventoryCount = text(#pets .. " pets · " .. #equipped .. " equipped", 0, 426, 504, 28, 16, T.Muted)
		children.Shards = text(tostring(data.petMaterial or 0) .. " Shards", 552, 0, 286, 40, 24, T.Gold)
		children.Search = e("TextBox", {
			Name = "SearchPets",
			Text = query,
			PlaceholderText = "Search pets...",
			Font = Enum.Font.GothamBold,
			TextSize = 17,
			TextColor3 = T.Text,
			BackgroundColor3 = T.Recess,
			Position = UDim2.fromOffset(0, 56),
			Size = UDim2.fromOffset(300, 38),
			ClearTextOnFocus = false,
			[React.Change.Text] = function(box: any)
				setQuery(box.Text)
			end,
		}, { Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }) })
		children.Auto = button("AutoFill", "Auto-fill 5", 312, 52, 192, function()
			if not primary or reason then
				return
			end
			local fill = { primary.uid }
			for _, pet in pets do
				if #fill >= B.FusionCount then
					break
				end
				if
					pet.uid ~= primary.uid
					and not pet.mutation
					and V.same(primary, pet)
					and not table.find(equipped, pet.uid)
				then
					table.insert(fill, pet.uid)
				end
			end
			setSelected(fill)
			setConfirm(false)
		end, T.Colors.Green, mode ~= "Fusion" or not primary or reason ~= nil)
		local cards: any = {}
		local count = 0
		for _, pet in pets do
			if not string.find(string.lower(V.name(pet)), string.lower(query), 1, true) then
				continue
			end
			count += 1
			local index = count
			cards[pet.uid] = e(U.Tile, {
				Name = "Select_" .. pet.uid,
				Position = UDim2.fromOffset(6 + (index - 1) % 4 * 124, 6 + math.floor((index - 1) / 4) * 136),
				Size = UDim2.fromOffset(112, 124),
				Color = palette[V.form(pet)],
				Quiet = true,
				Studs = false,
				Selected = table.find(ids, pet.uid) ~= nil,
				SelectionColor = T.Colors.Green,
				OnActivated = function()
					setConfirm(false)
					if mode == "Mutation" then
						setSelected({ pet.uid })
						return
					end
					local nextIds = table.clone(ids)
					local slot = table.find(nextIds, pet.uid)
					if slot then
						table.remove(nextIds, slot)
					elseif not primary or not V.same(primary, pet) or reason or State.reason(pet, equipped, mode) then
						nextIds = { pet.uid }
					elseif #nextIds < B.FusionCount then
						table.insert(nextIds, pet.uid)
					end
					setSelected(nextIds)
				end,
				Children = {
					Pet = if math.floor((index - 1) / 4) >= firstRow - 1
							and math.floor((index - 1) / 4) <= firstRow + 3
						then portrait(pet, 6, 2, 100, 80, false)
						else nil,
					Name = text(pet.name, 2, 78, 108, 22, 13),
					Variant = text(
						State.reason(pet, equipped, mode)
							or ((if V.form(pet) == "Normal" then "" else V.form(pet) .. " ") .. (pet.mutation or "")),
						2,
						100,
						108,
						20,
						12
					),
				},
			})
		end
		if count == 0 then
			cards.Empty = text(State.empty(#pets), 16, 50, 460, 120, 22)
		end
		children.Grid = e(U.Scroll, {
			Name = "CraftPetGrid",
			OnCanvasPosition = function(y: number)
				setFirstRow(math.floor(y / 136))
			end,
			Position = UDim2.fromOffset(0, 108),
			Size = UDim2.fromOffset(504, 310),
			Height = math.ceil(count / 4) * 136 + 12,
			Children = cards,
		})
		local odds: any = {}
		local oddsText = ""
		if mode == "Fusion" then
			odds = V.odds(if primary then V.form(primary) else "Normal", #ids)
		else
			local total = 0
			for _, m in B.Mutations do
				total += m.weight
			end
			for _, m in B.Mutations do
				table.insert(odds, { id = m.id, chance = m.weight / total })
			end
		end
		for _, o in odds do
			if o.chance > 0 then
				oddsText ..= o.id .. " " .. Config.formatBoost(o.chance * 100) .. "%" .. (if mode == "Mutation"
					then " · ×" .. Config.formatBoost(V.mutation(o.id).multiplier)
					else "") .. "\n"
			end
		end
		local right: any = {
			Pet = portrait(primary, 86, 0, 156, 115),
			Name = text(if primary then V.name(primary) else "Select a pet", 8, 110, 310, 32, 20),
			Slots = text(
				if mode == "Fusion"
					then tostring(#ids)
						.. " / "
						.. B.FusionCount
						.. " selected  ·  "
						.. (#ids / B.FusionCount * 100)
						.. "% success"
					else "Current: " .. (if primary then primary.mutation or "None" else "None"),
				8,
				148,
				310,
				28,
				18,
				T.Gold
			),
			Odds = text(
				if primary or mode == "Mutation" then oddsText else "Choose matching pets to see all odds",
				8,
				218,
				310,
				76,
				15
			),
			Risk = text(
				if reason == "Equipped"
					then "This pet is equipped. Unequip it here before crafting."
					elseif reason == "Max form" then "Rainbow is the highest form. You can still spin a mutation."
					elseif reason == "Paid pet" then "Paid pets are protected and cannot be crafted or mutated."
					elseif restricted then "Random crafting unavailable for this account"
					elseif
						mode == "Fusion"
					then "Selected pets are consumed, even on failure. Primary mutation survives success."
					else "Every spin replaces the old mutation, even if worse. Form stays unchanged.",
				8,
				298,
				310,
				54,
				15,
				T.Gold
			),
			Action = button(
				"CraftAction",
				if pending
					then "Waiting..."
					elseif reason == "Equipped" then "Unequip to craft"
					elseif reason then reason
					elseif confirm then "Confirm"
					elseif mode == "Fusion" then "Craft!"
					else "Spin · " .. B.MutationCost .. " Shards",
				12,
				362,
				300,
				function()
					if not primary then
						return
					end
					if reason == "Equipped" then
						setPending(true)
						context.send("Pet", primary.uid)
						return
					end
					if reason then
						return
					end
					if not confirm then
						setConfirm(true)
						return
					end
					setPending(true)
					if mode == "Fusion" then
						context.send("FusePets", primary.craftRevision or 0, ids)
					else
						context.send("MutatePet", primary.uid, primary.craftRevision or 0)
					end
				end,
				if confirm then T.Colors.Red else T.Colors.Green,
				not primary
					or pending
					or (reason ~= nil and reason ~= "Equipped")
					or (restricted and reason ~= "Equipped")
					or (mode == "Mutation" and (data.petMaterial or 0) < B.MutationCost)
			),
		}
		if mode == "Fusion" then
			for slot = 1, B.FusionCount do
				right["Slot" .. slot] = button(
					"MaterialSlot" .. slot,
					if ids[slot] then tostring(slot) else "+",
					14 + (slot - 1) * 61,
					176,
					52,
					function()
						local nextIds = table.clone(ids)
						table.remove(nextIds, slot)
						setSelected(nextIds)
						setConfirm(false)
					end,
					if ids[slot] then T.Gold else T.Slot,
					ids[slot] == nil
				)
			end
		end
		children.Detail = e(U.Surface, {
			Name = "CraftDetails",
			Position = UDim2.fromOffset(522, 52),
			Size = UDim2.fromOffset(326, 418),
			Color = T.Recess,
			Quiet = true,
			Children = right,
		})
		return e("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, children)
	end
	host.Destroying:Once(function()
		alive = false
		root:unmount()
	end)
	return function()
		local snapshot = context.snapshot()
		if alive and snapshot then
			root:render(e(App, { Snapshot = snapshot }))
		end
	end
end
return View
