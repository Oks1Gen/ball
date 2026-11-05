# Dev Panel: world preview and flight

Open **DEV** (or **F2**) and select **Карта**. The panel is available only to the
server's existing developer allowlist.

- **Мир 1 · Football City** returns to the World1 kick apron.
- **Мир 2 · Ocean Depths** visits the current World2 art preview in Studio.
  A published server without that preview returns an explanatory error.
- **Полёт / Noclip** toggles free flight. WASD follows the camera, Space ascends,
  Ctrl descends, Shift doubles flight speed. Reopen F2 to disable it.

Successful world travel or enabling flight closes the window; the gold indicator
shows when flight is active. Travel preserves an active flight mode. Respawning
clears preview and flight state. Text entry and the Roblox menu pause flight input.

The server validates commands and authorization. `AdminFlight` owns collision state;
`AdminFlightController` owns local movement constraints and restores normal movement
when the mode ends. Training, automatic kicking and manual kick timing stop during
flight. These tools do not change the saved world or write progression to ProfileStore.

`Admin` uses the existing RemoteFunction: `Flight(boolean)` and
`Teleport("World1" | "World2")`. Existing World1 location/training travel remains available.
The Studio preview does not implement normal player unlocks or World2 progression.
