# Balance implementation — 2026-11-08

User overrides the CEO proposal: additive ball bonuses affect training only; bubbles retain x5–15 and paid charge values, interval 14 seconds; rebirth costs, bonuses and lane progression unchanged. Single agent; no publication or sales changes.

All economic tuning lives in Shared/Core/Balance. Candidate base training rate 10 Skill/s, additive base + equipped ball + pet bonuses. Ball bonuses 1/2/3/5/9/15/25/40/65/100. Raw timing stages retain familiar clocks; combined timing becomes .85–1.35 inside shot power. Pet pools use 55/30/14/1%; Rainbow reserves .05% for Eclipse Cat. Lifetime zone challenges and pet recycling provide an earned upgrade path. Existing paid rights and pet identities remain; recognized normal v1 pet boosts migrate to current tiers, custom and paid boosts are preserved.

Moment inventory (reuse existing game feedback):

| Moment | Sound | Motion / visual | Camera |
| --- | --- | --- | --- |
| Ball buy/equip | Existing purchase/notification | Shared button spring, +X labels | unchanged |
| Accurate kick | Existing staged kick sound | Existing perfect aura, flight and bounce | existing optional perfect camera |
| Bubble collection | Existing bubble pop | Existing collect/payout motion | unchanged |
| Hatch / Secret reveal | Existing rarity reveal sound | Existing reveal rays, imported recolored cat and follower | existing reveal |
| Recycle confirmation / upgrade | Success or error toast sound | Existing button spring, toast spring and updated shards/boost | unchanged |
| Challenge ready / claimed | Success toast sound | Existing toast spring; claim state updates | unchanged |

Validation evidence and limitations are recorded in docs/verification.md and design/ACCEPTANCE.md at completion. No new standard rules or generated art.
