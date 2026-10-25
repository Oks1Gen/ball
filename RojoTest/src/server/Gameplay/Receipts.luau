--!strict
-- MarketplaceService.ProcessReceipt runs on the server. The product is granted
-- and the receipt id is recorded without a yield in between, so a repeated
-- receipt can never pay twice.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local Data = require(game.ReplicatedStorage.Shared.Core.ProfileData)
local PaidRewards = require(game.ReplicatedStorage.Shared.Core.PaidRewards)

local Receipts = {}

export type Context = {
	states: { [Player]: any },
	Config: any,
	save: (Player, boolean, string?) -> boolean,
	publish: (Player, string?) -> (),
	effect: RemoteEvent,
	equipBest: (any) -> (),
}

function Receipts.claimPending(context: Context, player: Player): boolean
	local s = context.states[player]
	if not s or s.adminOriginal or not s.data.perks.AdminEggPending or #s.data.pets >= 60 then
		return false
	end
	local pet = PaidRewards.claim(s.data, context.Config.AdminPet, HttpService:GenerateGUID(false))
	if not pet then
		return false
	end
	context.equipBest(s)
	context.effect:FireClient(player, "Hatch", { pet })
	context.publish(player, "Your reserved Admin Egg has arrived!")
	context.save(player, false)
	return true
end

-- Also callable with an isolated context in Studio verification; never installs
-- a test callback into the real MarketplaceService.
function Receipts.process(context: Context, player: Player?, receipt: any): Enum.ProductPurchaseDecision
	local s = player and context.states[player]
	if not player or not s or s.adminOriginal then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if s.data.receipts[receipt.PurchaseId] then
		return context.save(player, false, receipt.PurchaseId) and Enum.ProductPurchaseDecision.PurchaseGranted
			or Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local name, product
	for key, p in context.Config.Products do
		if p.id > 0 and p.id == receipt.ProductId then
			name = key
			product = p
			break
		end
	end
	if not product then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- The granted pet and the notice of a skipped reward are kept here:
	-- the save below can wait for the receipt and the pet list may change.
	local granted: any = nil
	local notice: string? = nil
	if product.skill then
		Data.add(s.data, "skill", product.skill)
	elseif name == "SkipRebirth" then
		s.data.skill = 0
		Data.add(s.data, "rebirths", 1)
	elseif name == "StarterPack" then
		Data.add(s.data, "wins", 10000)
		s.data.perks.DoubleSkill = true
		s.data.perks.StarterPack = true
	elseif name == "AdminEgg" then
		-- The admin pet is a one-time reward: a repeated purchase must not
		-- hand out a second pet.
		if s.data.perks.AdminEgg then
			notice = "Already owned"
		else
			PaidRewards.reserve(s.data)
			granted = PaidRewards.claim(s.data, context.Config.AdminPet, HttpService:GenerateGUID(false))
			if granted then
				context.equipBest(s)
			else
				notice = "Admin Egg reserved. Delete a pet to receive it."
			end
		end
		if notice then
			context.publish(player, notice)
		end
	else
		s.data.perks[name] = true
	end
	s.data.receipts[receipt.PurchaseId] = true
	if not context.save(player, false, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if granted then
		context.effect:FireClient(player, "Hatch", { granted })
	end
	-- A later notice replaces the one on the client, so the generic text is
	-- only sent when the purchase had no notice of its own.
	if not notice then
		context.publish(player, "Purchase received!")
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Receipts.install(context: Context)
	MarketplaceService.ProcessReceipt = function(receipt)
		return Receipts.process(context, Players:GetPlayerByUserId(receipt.PlayerId), receipt)
	end
end

return Receipts
