# Pets inventory — approved 01D

Implemented 2026-11-09 with React Luau and Ripple. Reference: `../immersive-concepts/2026-11-08/concept-01d-rounded-contained-footer.png`.

Four separate transparent icons were generated with the built-in ImageGen tool. `prompts.json` retains exact prompts and originals; `roblox-assets.json` maps PNG, Decal and Image IDs and records sharing with the Ball universe. Each original PNG is 1254x1254 with alpha; the existing Skill, Close and pet portraits are reused. No full-window screenshot is used as runtime UI artwork.

Implementation and ownership: `RojoTest/src/client/CollectorUI/PetsWindow.luau`, `PetControls.luau`, `PetDetailPlane.luau`, `InventoryPages.luau`. Main documentation: `docs/pets-inventory.md`.

Verification: `verification/results.json`. `2026-11-09-pc-normal-capture.png` has normal settings, but Roblox's capture path omits AlwaysOnTop SurfaceGuis. `2026-11-09-pc-plane-proof.png` is a diagnostic view with the card in the world render pass, blur off, Brightness 2 and local followers/character hidden; settings were restored afterward. It verifies geometry/content and is not an exact normal-runtime blur/color screenshot. The earlier `pc-layout.png` is superseded.
