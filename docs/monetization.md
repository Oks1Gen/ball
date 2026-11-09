# Robux purchases

Universe **10770268214**, place **106456161057435**. Created 5 November 2026,
connected and verified locally on 6 November (Europe/Moscow).

**All 12 offers are OFF SALE pending publication of the new handlers.**
The code is synced through Rojo. The old published build has no configured IDs.
Publish the verified authored place before enabling sales. AGENTS.md requires a
separate explicit publishing instruction. Do not publish the standalone Rojo
build over the authored map.

## Catalog

Runtime source: RojoTest/src/shared/CommerceCatalog.luau.
Cloud records and existing icon sources: Assets/Commerce/catalog.json.
Prices below are base prices. The client reads current Roblox prices, including
personal discounts, from GetProductInfoAsync. Managed and regional pricing were
left disabled. Off-sale items can omit PriceInRobux; this is a valid Off Sale
state, not a failed request or a reason to display a guessed price.

| Key | Type | ID | Base Robux | Reward |
| --- | --- | --- | ---: | --- |
| AutoThrow | Game Pass | 2070553162 | 25 | Permanent Auto Kick; also earnable for 2,500 Wins |
| DoubleSkill | Game Pass | 2070002509 | 5 | Permanent 2x earned Skill |
| DoubleWins | Game Pass | 2067146709 | 59 | Permanent 2x kick Wins |
| StarterPack | Game Pass | 2071564747 | 99 | 10,000 Wins once and permanent DoubleSkill |
| Skill10M | Developer Product | 3728591695 | 25 | 10,000,000 Skill |
| Skill100M | Developer Product | 3728591727 | 95 | 100,000,000 Skill |
| Skill1B | Developer Product | 3728591755 | 185 | 1,000,000,000 Skill |
| SkipRebirth | Developer Product | 3728591793 | 49 | One rebirth without the Skill requirement |
| AdminEgg | Developer Product | 3728591825 | 175 | One guaranteed x25 Glitched Dragon |
| TrainingBoost67 | Developer Product | 3728591855 | 5 | One complete training kick at x67 |
| TrainingBoost69 | Developer Product | 3728591889 | 5 | One complete training kick at x69 |
| TrainingBoost144 | Developer Product | 3728591926 | 9 | One complete training kick at x144 |

The eight repeatable IDs are the current API productId values, confirmed through
GetDeveloperProductsAsync and GetProductInfoAsync. Do not substitute the legacy
DeveloperProductId/TargetId fields.

## Checkout and fulfillment

- Action Product(key) is an intent. Gameplay/Commerce validates the key, rate
  limits requests and checks pass ownership. Effect PurchasePrompt(key) tells
  that player's client to open the correct native checkout.
- Client Modules/MarketplaceCatalog retrieves prices and opens
  PromptGamePassPurchase or PromptProductPurchase. Prompt-finished events only
  release its local checkout lock; they never fulfill Developer Products.
- Gameplay/Commerce restores passes through UserOwnsGamePassAsync after profile
  load and grants from the server's successful pass-purchase event. Failed
  ownership checks retry and are never cached as false.
- Core/PassRewards writes Starter Pack's Wins and passGrants.StarterPack
  synchronously into the same ProfileStore progress table. Its permanent
  DoubleSkill uses the same boolean perk as the separate pass and never stacks.
  Flat Skill purchases and gifts are not multiplied.
- The single ProcessReceipt callback serializes processing per player. Missing
  players, unknown IDs, failed saves and archive errors defer the receipt.
  Developer Products alone are routed to receipt rewards.
- The grant and PurchaseId persist together in ProfileStore before the
  independent archive is written. Its durable marker survives archive failure,
  so retries cannot duplicate the reward. Old boolean archive entries remain
  supported. New records store player/product IDs, actual receipt Robux and time.
- The Shop's Admin Egg remains a repeatable offer for a guaranteed Glitched Dragon. Each purchase grants one pet, or one saved reservation
  when storage is full. Charges survive rejoining and are spent only by a real
  complete training kick. Paid rebirth waits for an existing kick to finish.
- Donate totals use actual Developer Product CurrencySpent. Pass ownership does
  not expose historical paid prices, so restoring a pass does not invent spending
  from its base or personalized list price.

## Wins eggs and player policy

Starter Pack makes Wins purchasable with Robux. The server queries
PolicyService.GetPolicyInfoForPlayerAsync with retries. Egg purchases wait until
the result is known. Restricted players see only the first configured pet at
100%, and the server grants it deterministically for the existing Wins price.
Other players see the complete normal pool and numeric odds. Guaranteed regional
reveals show only the delivered pet. Football City's fifth stand sells Solar
Crown Egg for Wins through the same policy gate. Glitched Dragon is a separate
guaranteed offer in the Shop and at Ocean Depths' Jelly Egg stand.
The separately authorized Studio admin hatch is a development path.

## Reset Progress

The confirmed Dev-panel reset clears progress, donated, all perks, paid training
charges and pending paid pets. Settings, receipt markers and the one-time
Starter Pack fulfillment record remain. This prevents a delayed receipt or
restored ownership from granting previously delivered currency again.

Reset is blocked during receipt fulfillment. Old ownership requests are
invalidated by purchaseGeneration. Roblox account ownership cannot be revoked by
resetting game data: owned passes restore on next join or a later ownership check.
Starter Pack's permanent perk restores, but its 10,000 Wins do not repeat.

## Verification and deployment

- Cloud readback: 4 passes, 8 products, correct prices, icons and OFF SALE state.
- Engine readback: all eight product IDs belong to the target universe.
- PC Play: pass ownership and player policy loaded; existing passes restored.
  Shop opened, scrolled through all offers, displayed Owned/Off Sale and closed.
- Project gate: 132 Lune tests, formatting, Selene, Rojo build, require routes,
  ProfileStore integrity and Luau types pass.
- 71 isolated server checks cover all products, repeated receipts, failed
  profile saves, archive read/write failures, full pet storage and paid rebirth
  interruption. Nine further isolated checks cover reset, rollback, receipt
  locking and stale ownership requests. No real profile writes or paid tests.
- Native successful/cancelled checkout and real paid receipts remain untested
  while offers are off sale. After separately authorized publication, enable
  sales, rejoin, check live prices and test cancellation. A real paid test needs
  an explicit purchase/budget instruction. Public access is a separate setting.

References: [passes](https://create.roblox.com/docs/production/monetization/passes),
[developer products](https://create.roblox.com/docs/production/monetization/developer-products),
[MarketplaceService](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService).
