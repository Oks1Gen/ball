--!strict
-- The Action remote carries player intents only. Every price, reward and
-- requirement is decided here on the server from the authoritative state.
local MarketplaceService = game:GetService("MarketplaceService")
local Net = require(game.ReplicatedStorage.Shared.Net)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local BallPurchases = require(game.ReplicatedStorage.Shared.BallPurchases)
local Data = require(game.ReplicatedStorage.Shared.Core.ProfileData)
local ReturnRewards = require(game.ReplicatedStorage.Shared.Core.ReturnRewards)
local TrainingBoost = require(script.Parent.TrainingBoost)

local Tutorial = require(game.ReplicatedStorage.Shared.Core.Tutorial)

local Commands = {}

export type Context = {
	action: RemoteEvent,
	states: { [Player]: any },
	publish: (Player, string?, boolean?) -> (),
	kickTiming: any,
	hatch: (Player, string, number?, boolean?) -> (),
	purchaseItem: (Player, any, string, string, string) -> (),
	rebirth: (Player, boolean?) -> boolean,
	equipBest: (any) -> (),
	stopTraining: (Player, boolean?) -> (),
	claimPending: (Player) -> (),
	rootFor: (Player) -> (any, any),
	effect: RemoteEvent,
}

function Commands.install(context: Context)
	context.action.OnServerEvent:Connect(function(player, command, value, extra)
		local s = context.states[player]
		if not s or not Net.validAction(command, value, extra) then
			return
		end
		local now = os.clock()
		s.tokens = math.min(12, s.tokens + (now - s.lastAction) * 8)
		s.lastAction = now
		if s.tokens < 1 then
			return
		end
		s.tokens -= 1
		if command ~= "Throw" and command ~= "KickRelease" and command ~= "Snapshot" and command ~= "Setting" then
			context.kickTiming.cancel(player)
		end
		if command == "Snapshot" then
			-- The client asks for the state it lost, so the inventory travels
			-- with it even when nothing changed.
			context.publish(player, nil, true)
		elseif command == "Throw" then
			context.kickTiming.begin(player)
		elseif command == "TutorialRestart" then
			Tutorial.restart(s.data)
			context.publish(player)
		elseif command == "KickRelease" then
			context.kickTiming.release(player, value, extra)
		elseif command == "TrainingBoost" then
			TrainingBoost.claim(context, player, value, extra)
		elseif command == "KickCancel" then
			context.kickTiming.cancel(player)
		elseif command == "Auto" then
			if s.data.perks.AutoThrow then
				s.auto = not s.auto
				context.publish(player)
			else
				context.publish(player, "Auto Throw unlocks from the shop")
			end
		elseif command == "StopTraining" then
			-- A retry must preserve blockedLane after the first request released the pose.
			if s.lane then
				context.stopTraining(player, true)
				s.stopUntil = now + 0.5
			end
			context.publish(player)
		elseif command == "Rebirth" then
			context.rebirth(player, false)
		elseif command == "Stone" and type(value) == "string" then
			if now < s.busyUntil then
				context.publish(player, "Wait for your throw to finish")
			else
				local success, message = BallPurchases.buyOrEquip(s.data, value)
				if success then
					Tutorial.ball(s.data, value)
				end
				context.publish(player, message)
			end
		elseif command == "Trail" and type(value) == "string" then
			context.purchaseItem(player, Config.Trails, "trails", "trail", value)
		elseif command == "Hatch" and type(value) == "string" then
			context.hatch(player, value, extra)
		elseif command == "EquipBest" then
			context.equipBest(s)
			Tutorial.equipped(s.data)
			context.publish(player)
		elseif command == "UnequipAll" then
			s.data.equipped = {}
			s.inventoryVersion += 1
			context.publish(player)
		elseif (command == "Pet" or command == "DeletePet") and type(value) == "string" then
			-- The pet is looked up first and removed afterwards: a list that
			-- is changed while it is read would skip a pet.
			local index: number? = nil
			for position, pet in s.data.pets do
				if pet.uid == value then
					index = position
					break
				end
			end
			if index then
				local slot = table.find(s.data.equipped, value)
				if command == "DeletePet" then
					if slot then
						table.remove(s.data.equipped, slot)
					end
					table.remove(s.data.pets, index)
				elseif slot then
					table.remove(s.data.equipped, slot)
				elseif #s.data.equipped < 3 then
					table.insert(s.data.equipped, value)
				else
					context.publish(player, "Equip up to 3 pets")
					return
				end
				s.inventoryVersion += 1
				if command == "Pet" and table.find(s.data.equipped, value) then
					Tutorial.equipped(s.data)
				end
				if command == "DeletePet" then
					context.claimPending(player)
				end
				context.publish(player)
			else
				context.publish(player, "That pet is not in your inventory")
			end
		elseif command == "Gift" and type(value) == "number" and value == math.floor(value) then
			local gift = Config.Gifts[value]
			if not gift then
				context.publish(player, "Unknown gift")
			elseif s.gifts[value] then
				context.publish(player, "Gift already claimed")
			elseif now - s.joined < gift.time then
				context.publish(player, "That gift is not available yet")
			else
				s.gifts[value] = true
				Data.add(s.data, "wins", gift.wins)
				Data.add(s.data, "skill", gift.skill)
				context.publish(player, "Gift claimed!")
			end
		elseif command == "OfflineClaim" then
			if not s.welcomeClaimed then
				s.welcomeClaimed = true
				local amount = ReturnRewards.claimOffline(s.data)
				context.publish(
					player,
					if amount > 0 then "Offline reward claimed! +" .. Config.format(amount) .. " Skill" else nil
				)
			else
				context.publish(player)
			end
		elseif command == "Daily" then
			local reward = ReturnRewards.claimDaily(s.data, os.time())
			if reward then
				context.publish(
					player,
					"Daily gift: +"
						.. Config.format(reward.wins)
						.. " Wins +"
						.. Config.format(reward.skill)
						.. " Skill"
				)
			else
				context.publish(player, "Daily gift already claimed")
			end
		elseif command == "Setting" and type(value) == "string" then
			if (value == "sound" or value == "music") and type(extra) == "number" and extra == extra then
				s.data.settings[value] = math.clamp(math.floor(extra), 0, 100)
			elseif (value == "shake" or value == "effects") and type(extra) == "boolean" then
				s.data.settings[value] = extra
			end
			context.publish(player)
		elseif command == "Product" and type(value) == "string" then
			local product = Config.Products[value]
			if not product then
				context.publish(player, "Unknown product")
				return
			end
			if s.data.perks[value] then
				context.publish(player, "Already owned")
				return
			end
			if product.id == 0 then
				context.publish(player, "This purchase is not available yet")
			else
				MarketplaceService:PromptProductPurchase(player, product.id)
			end
		elseif command == "UnlockAuto" then
			if s.data.perks.AutoThrow then
				s.auto = not s.auto
			elseif s.data.wins >= 2500 then
				s.data.wins -= 2500
				s.data.perks.AutoThrow = true
				s.auto = true
			else
				context.publish(player, "Need 2.5K Wins for Auto Throw")
				return
			end
			context.publish(player)
		end
	end)
end

return Commands
