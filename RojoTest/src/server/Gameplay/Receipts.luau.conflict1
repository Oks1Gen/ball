--!strict
-- MarketplaceService.ProcessReceipt runs on the server. The product is granted
-- and the receipt id is recorded without a yield in between, so a repeated
-- receipt can never pay twice.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local Data = require(game.ReplicatedStorage.Shared.Core.ProfileData)
local PaidRewards = require(game.ReplicatedStorage.Shared.Core.PaidRewards)
local PetNews = require(game.ReplicatedStorage.Shared.Core.PetNews)

local Receipts = {}

export type Context = {
	states: { [Player]: any },
	Config: any,
	save: (Player, boolean, string?) -> boolean,
	publish: (Player, string?) -> (),
	effect: RemoteEvent,
	equipBest: (any) -> (),
	rebirth: (Player, boolean?) -> boolean,
}

function Receipts.claimPending(context: Context, player: Player): boolean
	local s = context.states[player]
	if not s or not s.data.perks.AdminEggPending or #s.data.pets >= 60 then
		return false
	end
	local pet = PaidRewards.claim(s.data, context.Config.AdminPet, HttpService:GenerateGUID(false))
	if not pet then
		return false
	end
	context.equipBest(s)
	context.effect:FireClient(player, "Hatch", PetNews.mark(s.data.pets, { pet }))
	context.publish(player, "Your reserved Admin Egg has arrived!")
	context.save(player, false)
	return true
end

-- Also callable with an isolated context in Studio verification; never installs
-- a test callback into the real MarketplaceService.
function Receipts.process(context: Context, player: Player?, receipt: any): Enum.ProductPurchaseDecision
	local s = player and context.states[player]
	if not player or not s then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if s.data.receipts[receipt.PurchaseId] then
		return context.save(player, false, receipt.PurchaseId) and Enum.ProductPurchaseDecision.PurchaseGranted
			or Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local name, product
	for key, p in context.Config.Products do
		if p.kind == "DeveloperProduct" and p.id > 0 and p.id == receipt.ProductId then
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
	if product.trainingBoost then
		local key = tostring(product.trainingBoost)
		s.data.trainingBoosts[key] = (s.data.trainingBoosts[key] or 0) + 1
	elseif product.skill then
		Data.add(s.data, "skill", product.skill)
	elseif name == "SkipRebirth" then
		s.paidRebirthWaiting = true
		while context.states[player] == s and player.Parent == Players and os.clock() < (s.busyUntil or 0) do
			task.wait()
		end
		s.paidRebirthWaiting = nil
		if context.states[player] ~= s or player.Parent ~= Players then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if not context.rebirth(player, true) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	elseif name == "AdminEgg" then
		PaidRewards.reserve(s.data)
		granted = PaidRewards.claim(s.data, context.Config.AdminPet, HttpService:GenerateGUID(false))
		if granted then
			context.equipBest(s)
		else
			notice = "Admin Egg reserved. Delete a pet to receive it."
		end
		if notice then
			context.publish(player, notice)
		end
	else
		warn("[Ball purchases] No reward handler for product " .. tostring(name))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- Counted together with the receipt mark, so a repeated receipt never adds twice.
	local spent = receipt.CurrencySpent
	if receipt.CurrencyType == Enum.CurrencyType.Robux and Data.finite(spent) and spent > 0 then
		Data.add(s.data, "donated", spent)
	end
	s.data.receipts[receipt.PurchaseId] = true
	if not context.save(player, false, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if granted then
		context.effect:FireClient(player, "Hatch", PetNews.mark(s.data.pets, { granted }))
	end
	-- A later notice replaces the one on the client, so the generic text is
	-- only sent when the purchase had no notice of its own.
	if not notice then
		context.publish(player, "Purchase received!")
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Archive adapter also permits isolated failure/retry verification without
-- invoking MarketplaceService or writing a real player's profile.
function Receipts.fulfill(context: Context, player: Player, receipt: any, archive: any): Enum.ProductPurchaseDecision
	local state = context.states[player]
	local granted = Enum.ProductPurchaseDecision.PurchaseGranted
	local deferred = Enum.ProductPurchaseDecision.NotProcessedYet
	if not state then
		return deferred
	end
	local id = receipt.PurchaseId
	local archived = archive.read(id)
	if archived == true or (type(archived) == "table" and archived.granted == true) then
		if type(archived) == "table" and archived.playerId ~= receipt.PlayerId then
			warn("[Ball purchases] Receipt archive ownership mismatch")
			return deferred
		end
		state.data.receipts[id] = nil
		return granted
	end
	if context.states[player] ~= state or player.Parent ~= Players then
		return deferred
	end
	if Receipts.process(context, player, receipt) ~= granted then
		return deferred
	end
	-- The reward and receipt are durable before the independent audit record.
	archive.write(id, {
		granted = true,
		playerId = receipt.PlayerId,
		productId = receipt.ProductId,
		robux = if receipt.CurrencyType == Enum.CurrencyType.Robux then receipt.CurrencySpent else 0,
		grantedAt = os.time(),
	})
	state.data.receipts[id] = nil
	return granted
end

function Receipts.install(context: Context)
	local archive =
		DataStoreService:GetDataStore(if RunService:IsStudio() then "BallReceipts_Studio_v1" else "BallReceipts_v1")
	local readOptions = Instance.new("DataStoreGetOptions")
	readOptions.UseCache = false
	local storage = {
		read = function(id: string)
			return archive:GetAsync(id, readOptions)
		end,
		write = function(id: string, record: any)
			archive:SetAsync(id, record)
		end,
	}
	local processing: { [Player]: boolean } = {}
	local deferred = Enum.ProductPurchaseDecision.NotProcessedYet
	for key, item in context.Config.Products do
		if item.kind == "DeveloperProduct" then
			assert(
				item.id > 0 and (item.skill or item.trainingBoost or key == "SkipRebirth" or key == "AdminEgg"),
				"Product reward missing: " .. key
			)
		end
	end
	MarketplaceService.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		if not player then
			return deferred
		end
		while processing[player] and player.Parent == Players do
			task.wait()
		end
		local state = context.states[player]
		if not state or player.Parent ~= Players then
			return deferred
		end
		processing[player] = true
		state.receiptProcessing = true
		local ok, decision = pcall(function()
			return Receipts.fulfill(context, player, receipt, storage)
		end)
		processing[player] = nil
		state.receiptProcessing = nil
		if not ok then
			warn("[Ball purchases] Receipt processing or archival failed")
			return deferred
		end
		return decision
	end
end

return Receipts
