--!strict
-- Clicked egg reveal. The pets arrive already rolled by the server: five clicks
-- crack the egg and reveal its rarity tier by tier, the egg shakes and bursts,
-- and black silhouettes of the egg's pets stop on the granted one.
local React = require(game.ReplicatedStorage.Packages.React)
local Run = game:GetService("RunService")
local UserInput = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Sequence = require(game.ReplicatedStorage.Shared.Core.HatchSequence)
local LevelSound = require(game.ReplicatedStorage.Shared.LevelUpSound)
local U = require(script.Parent.Components)
local T = require(script.Parent.Theme)
local HatchEffects = require(script.Parent.HatchEffects)
local Egg = require(script.Parent.HatchEgg)
local Roulette = require(script.Parent.HatchRoulette)
local Scenery = require(script.Parent.HatchScenery)
local Presentation = require(script.Parent.Parent.Modules.UiPresentation)
local e = React.createElement

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
	Width: number,
	Height: number,
	Hatched: { Pet },
	EggId: string?,
	Data: { world: number, wins: number? }?,
	Inventory: { pets: { any } }?,
	-- Open again sends the same hatch; the reply replaces this stage.
	Request: ((string, any?, any?) -> ())?,
	Busy: boolean?,
	Variant: number?,
	-- Offline capture: a fixed clock with synthetic clicks.
	PreviewTime: number?,
	Reduced: boolean?,
	Close: () -> (),
}
type EggEntry = {
	pet: Pet,
	pool: { any },
	final: number,
	eggId: string,
	tier: number,
	track: Egg.Track,
}
type Session = { start: number, clicks: { number }, eggs: { EggEntry }, played: { [string]: boolean } }

-- Effects=false and the capture show the end state of the synthetic clicks.
local SETTLED = 1000
local INK = Color3.fromRGB(12, 13, 19)

-- Built-in sounds the game already uses; the SkippingSounds group applies the
-- Sound setting.
local SOUNDS = {
	Jump = { id = "rbxasset://sounds/action_jump.mp3", volume = 0.14, speed = 1.3 },
	Land = { id = "rbxasset://sounds/action_jump_land.mp3", volume = 0.3, speed = 1 },
	Upgrade = { id = "rbxasset://sounds/volume_slider.ogg", volume = 0.4, speed = 1 },
	Burst = { id = "rbxasset://sounds/impact_explosion_03.mp3", volume = 0.2, speed = 1.3 },
	Tick = { id = "rbxasset://sounds/volume_slider.ogg", volume = 0.1, speed = 2.2 },
	Reveal = { id = LevelSound.id, volume = LevelSound.volume, speed = LevelSound.speed },
	-- A deep boom when the light turns Legendary or Mythic.
	Epic = { id = "rbxasset://sounds/impact_explosion_03.mp3", volume = 0.3, speed = 0.62 },
}
-- Vibration on gamepads and phones that support it; one effect per kind.
local HAPTICS = {
	Land = Enum.HapticEffectType.GameplayCollision,
	Upgrade = Enum.HapticEffectType.UINotification,
	Burst = Enum.HapticEffectType.GameplayExplosion,
}
local haptics: { [string]: any } = {}
local function buzz(name: string)
	pcall(function()
		local effect = haptics[name]
		if effect == nil or effect.Parent == nil then
			effect = Instance.new("HapticEffect")
			effect.Type = HAPTICS[name]
			effect.Parent = workspace
			haptics[name] = effect
		end
		effect:Play()
	end)
end
local function play(name: string, speed: number?)
	local info = SOUNDS[name]
	local sound = Instance.new("Sound")
	sound.SoundId = info.id
	sound.Volume = info.volume
	sound.PlaybackSpeed = info.speed * (speed or 1)
	local group = SoundService:FindFirstChild("SkippingSounds")
	if group and group:IsA("SoundGroup") then
		sound.SoundGroup = group
	end
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 3)
end

local function finishedAt(session: Session): number?
	local latest = 0
	for _, entry in session.eggs do
		local fill = Egg.fill(entry.track)
		if fill == nil then
			return nil
		end
		latest = math.max(latest, fill + Sequence.Fill + 0.35)
	end
	return latest
end

-- Sounds of everything that happened by `t`, each moment once.
local function cues(session: Session, t: number)
	local played = session.played
	local function cue(key: string, moment: number?, name: string, speed: number?, haptic: string?)
		if moment and t >= moment and not played[key] then
			played[key] = true
			-- A moment that passed long ago (a stalled frame) stays silent.
			if t - moment < 0.25 then
				play(name, speed)
				if haptic then
					buzz(haptic)
				end
			end
		end
	end
	for k, click in session.clicks do
		cue("Jump" .. k, click, "Jump", 0.95 + k * 0.05)
		cue("Land" .. k, click + Sequence.Jump, "Land", 1, "Land")
	end
	for i, entry in session.eggs do
		local track = entry.track
		for k = 1, #session.clicks do
			if (track.plan[k] or 1) > (track.plan[k - 1] or 1) then
				cue(
					"Up" .. i .. "_" .. k,
					session.clicks[k] + track.delay + Sequence.Jump,
					"Upgrade",
					0.8 + track.plan[k] * 0.15,
					"Upgrade"
				)
			end
		end
		local finale = Sequence.finale(session.clicks, track.delay)
		local last = track.plan[Sequence.Clicks + 1]
		if finale and last > track.plan[Sequence.Clicks] then
			cue("Late" .. i, finale + Sequence.FinaleUpgrade, "Upgrade", 0.8 + last * 0.15, "Upgrade")
		end
		-- One boom for the whole stage, at the first egg that turns epic.
		cue("Epic", Sequence.reached(track.plan, session.clicks, track.delay, Sequence.EpicTier), "Epic", 1, "Burst")
		-- The eggs of a triple burst and tick together: the first egg plays the
		-- burst, the last one (its frames contain the others') the ticks.
		if i == 1 then
			cue("Burst", Egg.burst(track), "Burst", 1, "Burst")
		end
		local start = Egg.rouletteStart(track)
		if start and i == #session.eggs then
			for n, frame in track.frames do
				cue("Tick" .. i .. "_" .. n, start + frame.at, "Tick", 1 + (i - 1) * 0.06)
			end
		end
		cue(
			"Reveal" .. i,
			Egg.fill(track),
			if i == 1 then "Reveal" else "Upgrade",
			if i == 1 then 1 else 1.5,
			if i == 1 then "Upgrade" else nil
		)
	end
end

-- The same hatch once more: the egg of the pets, their count and the price,
-- or nil when the player cannot pay, has no room or the pets came from no egg.
local function againOf(p: Props, eggs: { EggEntry }): { egg: string, count: number, cost: number }?
	local count = #eggs
	if count ~= 1 and count ~= 3 then
		return nil
	end
	local eggId = Roulette.eggOf(eggs[1].pet)
	for _, entry in eggs do
		if Roulette.eggOf(entry.pet) ~= eggId then
			return nil
		end
	end
	local egg = eggId and Config.find(Config.Eggs, eggId)
	local data = p.Data
	if not egg or not data or data.wins == nil then
		return nil
	end
	local cost = egg.cost * (if data.world == 2 then 10 else 1) * count
	local pets = if p.Inventory then #p.Inventory.pets else 0
	if data.wins < cost or pets + count > 60 then
		return nil
	end
	return { egg = egg.id, count = count, cost = cost }
end

local function TapHint(p: { At: ((number) -> any) -> any, Session: Session, Width: number, Height: number })
	local at, session = p.At, p.Session
	local function idle(t: number): number
		local last = session.clicks[#session.clicks]
		return t - (if last then last + Sequence.Jump else 0)
	end
	local function alpha(t: number): number
		if #session.clicks >= Sequence.Clicks then
			return 1
		end
		return 1 - Egg.smooth((t - 0.3) / 0.3)
	end
	local pips = {}
	local gap, pip = 10, 14
	local rowWidth = Sequence.Clicks * pip + (Sequence.Clicks - 1) * gap
	for k = 1, Sequence.Clicks do
		pips["Pip" .. k] = e("Frame", {
			Name = "HatchClickPip",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(
				math.floor((p.Width - rowWidth) / 2) + (k - 1) * (pip + gap) + pip / 2,
				p.Height - 16
			),
			Size = at(function(t)
				local click = session.clicks[k]
				local s = pip * (if click and t >= click then Egg.pop((t - click) / 0.2) else 0.8)
				return UDim2.fromOffset(s, s)
			end),
			BackgroundColor3 = at(function(t)
				local click = session.clicks[k]
				return if click and t >= click then T.Gold else Color3.fromRGB(122, 130, 138)
			end),
			BackgroundTransparency = at(alpha),
			BorderSizePixel = 0,
			ZIndex = 27,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
			Edge = e("UIStroke", { Color = INK, Thickness = 2, Transparency = at(alpha) }),
		})
	end
	pips.Text = e("TextLabel", {
		Name = "HatchTapHint",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(p.Width / 2, p.Height - 46),
		Size = UDim2.fromOffset(p.Width - 20, 30),
		Text = Presentation.hatchHint(),
		Font = Enum.Font.GothamBlack,
		TextSize = 22,
		TextColor3 = Color3.new(1, 1, 1),
		TextTransparency = at(alpha),
		ZIndex = 27,
	}, {
		Stroke = e("UIStroke", { Color = INK, Thickness = 2, Transparency = at(alpha) }),
		-- The hint pulses harder while the player waits.
		Scale = e("UIScale", {
			Scale = at(function(t)
				local strength = if idle(t) > 2.5 then 0.08 else 0.03
				return 1 + math.sin(t * 6) * strength
			end),
		}),
	})
	return e(
		"Frame",
		{ Name = "HatchTapProgress", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 4 },
		pips
	)
end

return function(p: Props)
	local fixed = p.PreviewTime ~= nil or p.Reduced == true
	local session: Session = React.useMemo(function()
		local random = if fixed then Random.new(7) else Random.new()
		local function roll(): number
			return random:NextNumber()
		end
		local clicks = if fixed then table.clone(Sequence.PreviewClicks) else {}
		local eggs: { EggEntry } = {}
		for i, pet in p.Hatched do
			local pool, final, eggId = Roulette.pool(pet, p.EggId or "Common")
			if p.Reduced then
				-- Effects off shows only the granted pet: no extra viewports.
				pool, final = { pool[final] }, 1
			end
			local tier = Sequence.tierOf(pet.rarity)
			local frames, stop = Sequence.roulette(#pool, final, Sequence.Spin + (i - 1) * Sequence.Stagger, roll)
			eggs[i] = {
				pet = pet,
				pool = pool,
				final = final,
				eggId = eggId,
				tier = tier,
				track = {
					clicks = clicks,
					plan = Sequence.plan(tier, roll),
					delay = (i - 1) * Sequence.EggDelay,
					frames = frames,
					stop = stop,
				},
			}
		end
		return { start = os.clock(), clicks = clicks, eggs = eggs, played = {} }
	end, { p.Hatched, p.PreviewTime ~= nil, p.Reduced == true } :: { any })
	local function now(): number
		if p.PreviewTime ~= nil then
			return p.PreviewTime
		end
		return if p.Reduced then SETTLED else os.clock() - session.start
	end
	local time, setTime = React.useBinding(0)
	React.useEffect(function()
		if fixed then
			return
		end
		setTime(now())
		local connection
		connection = Run.RenderStepped:Connect(function()
			local t = os.clock() - session.start
			setTime(t)
			cues(session, t)
			local finished = finishedAt(session)
			-- The light keeps turning a little after the reveal, then the clock rests.
			if finished and t > finished + 1.5 then
				connection:Disconnect()
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, { session } :: { any })
	local function tap()
		if fixed then
			return
		end
		local startAt = Sequence.accept(session.clicks, now())
		if startAt then
			table.insert(session.clicks, startAt)
		end
	end
	React.useEffect(function()
		if fixed then
			return
		end
		local connection = UserInput.InputBegan:Connect(function(input, processed)
			local key = input.KeyCode
			-- E typed into the chat is not a click; the gamepad has no text box.
			local keyboard = key == Enum.KeyCode.E and not processed
			if keyboard or key == Enum.KeyCode.ButtonA or key == Enum.KeyCode.ButtonX then
				tap()
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, { session } :: { any })
	local function at(fn: (number) -> any): any
		if fixed then
			return fn(now())
		end
		return time:map(fn)
	end

	local w, h = p.Width, p.Height
	local count = math.max(1, #session.eggs)
	-- The eggs of a triple stand side by side on their own pedestals, close
	-- enough to share the plaza on a wide screen.
	local spacing = math.min((w - 16) / count, h * 0.52)
	local eggSize =
		math.round(math.min(spacing * (if count == 1 then 0.9 else 0.72), h * (if count == 1 then 0.6 else 0.42)))
	local groundY = math.round(h * (if count == 1 then 0.72 else 0.7))
	local spots: { Scenery.Spot } = {}
	for i = 1, count do
		spots[i] = { x = math.round(w / 2 + (i - (count + 1) / 2) * spacing), y = groundY, size = eggSize }
	end
	local world = p.Data and p.Data.world or 1
	-- The garden follows the light of every egg; effects off keeps it still.
	local lights: { Scenery.Light }? = nil
	if not p.Reduced then
		local list: { Scenery.Light } = {}
		for i, entry in session.eggs do
			local track = entry.track
			list[i] = {
				color = function(t: number): Color3
					return Egg.lightColor(track, t)
				end,
				tier = function(t: number): number
					return (Sequence.tierAt(track.plan, track.clicks, t, track.delay))
				end,
				flare = function(t: number): number
					return Egg.flare(track, t, 1)
				end,
				epic = function(t: number): number
					local moment = Sequence.reached(track.plan, track.clicks, track.delay, Sequence.EpicTier)
					return if moment then Egg.smooth((t - moment) / 0.6) else 0
				end,
			}
		end
		lights = list
	end
	local children: { [string]: any } = {
		Scenery = e(Scenery.View, { At = at, Now = now, Width = w, Height = h, Spots = spots, Lights = lights }),
	}
	for i, entry in session.eggs do
		local foot = Vector2.new(spots[i].x, groundY)
		local eggCenter = foot - Vector2.new(0, math.round(eggSize * Egg.Foot))
		local egg = Config.find(Config.Eggs, entry.eggId) or Config.Eggs[1]
		if not p.Reduced then
			children["Egg" .. i] = e(Egg.View, {
				At = at,
				Now = now,
				Track = entry.track,
				Center = eggCenter,
				Size = eggSize,
				EggId = egg.id,
				World = world,
				ShellColor = egg.color,
			})
			children["Effects" .. i] = e(HatchEffects, {
				At = at,
				Center = eggCenter,
				Size = eggSize * (if count == 1 then 1.1 else 0.95),
				Age = function(t: number): number
					local burst = Egg.burst(entry.track)
					return if burst then t - burst else -math.huge
				end,
				ShellColor = egg.color,
				Color = Egg.TierColors[entry.tier],
			})
		end
		children["Pet" .. i] = e(Roulette.View, {
			At = at,
			Track = entry.track,
			Pool = entry.pool,
			Final = entry.final,
			Pet = entry.pet,
			Tier = entry.tier,
			Foot = foot,
			Size = eggSize,
			Width = spacing - 8,
			Single = count == 1,
		})
		if i == 1 and not fixed then
			-- The egg itself is a button too, so the tutorial can point at it.
			children.EggTap = e("TextButton", {
				Name = "HatchTap",
				Text = "",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(eggCenter.X, eggCenter.Y),
				Size = UDim2.fromOffset(eggSize * 0.7, eggSize * 0.8),
				Visible = at(function()
					return #session.clicks < Sequence.Clicks
				end),
				ZIndex = 31,
				[React.Event.Activated] = tap,
			})
		end
	end
	if not p.Reduced then
		children.Hint = e(TapHint, { At = at, Session = session, Width = w, Height = h })
	end
	-- Landings, upgrades and the burst knock the whole scene; the buttons
	-- below stay still.
	local amplitude = h * 0.014
	children = {
		Shake = e("Frame", {
			Name = "HatchShake",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Position = if p.Reduced
				then UDim2.new()
				else at(function(t)
					local strength = 0
					for _, entry in session.eggs do
						local track = entry.track
						strength = math.max(strength, Sequence.shake(track.plan, track.clicks, t, track.delay))
					end
					local a = amplitude * strength
					return UDim2.fromOffset(math.sin(t * 83) * a, math.cos(t * 67) * a * 0.7)
				end),
		}, children),
	}
	if not fixed then
		children.TapArea = e("TextButton", {
			Name = "HatchTapArea",
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = at(function()
				return #session.clicks < Sequence.Clicks
			end),
			ZIndex = 30,
			[React.Event.Activated] = tap,
		})
	end
	-- Open again: the same egg and count, shown only when the player can pay
	-- for it and has room for the pets.
	local again = againOf(p, session.eggs)
	local request = p.Request
	local againWidth = 300
	local rowLeft = math.floor((w - (if again and request then 240 + 16 + againWidth else 240)) / 2)
	local function finished(t: number): boolean
		local moment = finishedAt(session)
		return moment ~= nil and t >= moment
	end
	if again and request then
		children.Again = e("Frame", {
			Name = "HatchOpenAgain",
			Size = UDim2.fromOffset(againWidth, 46),
			Position = UDim2.fromOffset(rowLeft + 240 + 16, h - 78),
			BackgroundTransparency = 1,
			Visible = at(finished),
			ZIndex = 20,
		}, {
			Button = e(U.Button, {
				Name = "OpenAgain",
				Text = "Open again / " .. Config.format(again.cost) .. " Wins",
				Size = UDim2.fromOffset(againWidth, 46),
				Position = UDim2.fromOffset(0, 0),
				Color = T.Colors.Eggs,
				OnActivated = function()
					request("Hatch", again.egg, again.count)
				end,
				Disabled = p.Busy == true,
			}),
		})
	end
	children.Continue = e("Frame", {
		Name = "HatchContinue",
		Size = UDim2.fromOffset(240, 46),
		Position = UDim2.fromOffset(rowLeft, h - 78),
		BackgroundTransparency = 1,
		Visible = at(finished),
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
