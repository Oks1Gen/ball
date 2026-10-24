# Football UI assets

Superseded by `../../Assets/UI/` on 2026-10-24. The runtime now uses individually
generated images, without atlas crops. These older sheets remain as history.

Generated from scratch with the built-in ImageGen tool for this game's UI.
No pre-existing artwork from `assets/` was used. The existing stud tile is the
only reused UI image. Game ball/pet models remain live inventory previews.

- `main.png`: original transparent 4 × 4 atlas.
- `extra.png`: original transparent 4 × 4 atlas with football trails and utilities.
- `*-upload.png`: 1024 × 1024 upload copies; each cell is 256 × 256.
- `prompts.json`: exact generation prompts.
- Asset IDs and cell mappings: `src/client/UIAssets.luau`.

The Playtime Rewards and Daily Reward windows use the existing six timed gifts and daily claim. This UI
does not advertise a seven-day streak, offline earnings or purchasable aura
slots, because those systems do not exist in the game.

