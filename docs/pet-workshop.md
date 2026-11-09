# Pet Workshop — 2026-11-08

Implements the user's two roulette systems. Runtime station: `World1/Lobby/PetWorkshop`, a single portable Model. Open at its prompt or Pets → Craft. The station does not rebuild other scenery. `LayoutKey=PetWorkshop` preserves the new object through the legacy layout compiler; installation also recovers its own object from Geometry rather than creating a duplicate.

## Balance settings

All current economic settings: `RojoTest/src/shared/Core/Balance.luau`. No rebirth, ball, bubble, lane or egg-price changes in this task.

| Setting | Initial value |
| --- | --- |
| FusionCount | 5 matching pets for guaranteed success |
| Forms | Normal ×1, Golden ×2, Diamond ×4, Rainbow ×8 |
| FormOutcomes.Normal | Conditional weights: Golden 9890, Diamond 100, Rainbow 10 |
| FormOutcomes.Golden | Conditional weights: Diamond 9950, Rainbow 50 |
| FormOutcomes.Diamond | Rainbow 10000 |
| MutationCost | 10 Shards per spin |
| Mutations | Wind ×1.25 / 5500; Frost ×1.35 / 2800; Flame ×1.5 / 1200; Storm ×1.75 / 450; Cosmic ×2 / 50 |
| CraftCooldown | 5 seconds, server enforced |
| Crafting.Yield | Recycling: Common 1, Uncommon 2, Rare 4, Legendary 12 |

Form and mutation coefficients multiply the **pet's added contribution**:

`boost = 1 + (baseBoost - 1) * form.multiplier * mutation.multiplier`.

For base ×2.2, Golden is ×3.4; Golden + Wind is ×4.0. Each equipped pet's `boost-1` then enters the existing additive training formula. A form never directly multiplies flight distance. These are starting tuning values, not validated session-time targets.

## Fusion transaction

Select 1–5 unique, unequipped pets with identical species, form and origin strength (egg, world and baseBoost). The first selected pet is primary. Each selected pet contributes 20% success. **Every selected pet is consumed**, including on failure. Success creates one pet, preserving the primary UID, origin and mutation, with a new form and advanced craftRevision. Paid AdminDragon is protected. Secret can be crafted/mutated but remains protected from recycling. Rainbow is terminal for fusion and can still receive mutations.

The real outcome chances are `count/5 * conditionalWeight/totalWeight`; failure is `1-count/5`. For four Normal pets: Fail 20%, Golden 79.12%, Diamond 0.8%, Rainbow 0.08%. Five pets guarantee success, not a particular successful form. UI shows these combined chances before confirmation. Auto-fill excludes equipped pets and mutated materials; a mutated pet can only be selected manually. Only the primary mutation survives. Removing slot 1 makes the next selected pet primary.

## Mutation transaction

One spin always consumes 10 Shards and replaces the old mutation, including a duplicate or weaker result. There is one mutation slot. Form, UID, origin and equipped status remain intact. Confirmation explicitly warns about replacement; all five numerical chances and coefficients are visible before spending. No keep-old choice or hidden pity.

Shards still come from recycling and existing challenges. The previous guaranteed +1/+2/+3 upgrade command is retired. Loading a v2 pet refunds its actual old 10/20/40 costs once, removes that old level and normalizes the pet to the new independent fields. Frozen migration constants describe old saves and must not be retuned as current balance. Rejoining does not refund again or compound form/mutation power. Custom boosts and paid pets stay valid.

## Server and presentation

Net validates bounded dense selections and expected revisions. Commands checks global rate limit, throw state, crafting cooldown and current PolicyService state. Unknown/restricted policy blocks both random operations without consumption: pets and salvage materials can originate indirectly from purchasable Wins. This conservatively follows [Roblox paid random item rules](https://create.roblox.com/docs/production/monetization/paid-random-items). No products, prices or sales were added.

Validation, RNG selection, consumption, result and revision update run synchronously. A repeated request with the old revision cannot charge again. The server commits first, publishes inventory, then sends PetCraftResult. Closing the cosmetic roulette cannot refund, reroll or duplicate a pet. PetCraftRejected unlocks the waiting UI on normal rejections; network loss has a timeout.

React UI uses the existing HudPanels shell, blur, GothamBlack, palette, shared buttons and Ripple vertical reel. The reel only includes possible outcomes; it never shows Fail for a guaranteed craft. Its final slot is the committed result. Existing Sunburst artwork and success sound accompany the reveal; Effects Off shortens the reel. No new particle system or icons.

Forms use existing meshes. Their vertex colours are recoloured for Golden/Diamond and vertical Rainbow bands, preserving dark mouths/pupils and neutral highlights. A client reference-counted cache shares editable meshes across visible portraits/followers and releases them when unused. A failed optional mesh allocation warns and leaves the ordinary tinted model; the result, name and stats remain functional. Mutation uses a coloured outline. No live mesh upload is required.

The machine was authored in Blender and transported through Rojo as 39 native primitives. `.blend`, `.glb`, `.fbx`, renders, builder and verification live in `Assets/PetWorkshop`. The native JSON template is in Shared. Smooth machine panels intentionally contrast with the existing studded lawn and paths.

## Verification

See `docs/verification.md` and `design/ACCEPTANCE.md`. Test fixture `tools/PreviewPetWorkshop.luau` uses real production UI/pure rules with isolated data, no gameplay remotes. `tools/VerifyPetWorkshop.luau` exercises isolated Commands state and policy/cooldown/replay/save boundaries. Neither writes a loaded profile.

Full novice-to-endgame pacing with forms/mutations and retention impact still need measured sessions. Mobile testing remains deferred by project rules. No publication or commit.

## Inventory integration correction — 2026-11-08

The live snapshot intentionally separates `data` (progress) from `inventory` (pets/equipped). The initial screen incorrectly read `data.pets` and `data.equipped`, while the first fixture put them there and masked the integration bug. The screen now uses `PetWorkshopState.inventory(snapshot)` and the fixture uses the real split shape. Progress-only updates retain cached inventory; new inventory replaces it.

All owned pets are shown, including equipped pets, paid protected pets and terminal Rainbow. Their restrictions are labelled rather than silently filtering them out. Forms offer Unequip to craft for an equipped primary, through the existing server Pet command; auto-fill continues to exclude equipped materials. Protected/max forms have disabled craft actions, and Rainbow can still roll mutations. Search-with-no-matches is distinguished from owning zero pets. A count shows pets and equipped slots.

GameplayController suppresses ProximityPromptService while any modal is open and restores the previous value on closing or teardown. This replaces the old hatch-only suppression and prevents the station prompt appearing on top of the workshop. No economic parameters or ownership data changed.
