--!strict
-- Player-facing changes, newest first. Maintenance rules: AGENTS.md.
export type Release = {
	id: string,
	date: string,
	title: string,
	changes: { string },
}

local releases: { Release } = {
	{
		id = "2026-10-30-lightning-bubbles",
		date = "October 30, 2026",
		title = "Catch lightning boosts",
		changes = {
			"Catch floating training bubbles for a 1.6x to 4x bonus on one kick.",
			"Bubbles drift up or down, then pause so you can tap them.",
			"Pop a bubble to send lightning flying into your Skill counter.",
			"Doubled bubble and flying lightning sizes for easier tapping.",
		},
	},
	{
		id = "2026-10-30-pet-card-art",
		date = "October 30, 2026",
		title = "New pet inventory artwork",
		changes = {
			"Added illustrated inventory cards for all 16 current egg pets.",
			"Each pet now has its own sharp transparent icon at a consistent scale.",
			"Kept English names and rarity labels and removed preview rays.",
			"Live boosts and equipped markers stay visible on every card.",
		},
	},
	{
		id = "2026-10-29-tutorial-replay",
		date = "October 29, 2026",
		title = "Tutorial replay fix",
		changes = {
			"Replaying the tutorial now continues through balls and pets after your kick.",
			"Already owned items no longer skip tutorial steps; reuse your ball without paying again.",
			"Confirm Equip Best to finish the pet step.",
		},
	},
	{
		id = "2026-10-29-tutorial",
		date = "October 29, 2026",
		title = "Follow the arrows",
		changes = {
			"Added step-by-step guidance from training to your first kick, better ball and pet.",
			"Follow moving arrows and tap hints while playing; progress resumes when you return.",
			"Replay the tutorial from Settings.",
		},
	},
	{
		id = "2026-10-29-hud-polish",
		date = "October 29, 2026",
		title = "HUD polish",
		changes = {
			"Made the side menu and skill offers more compact.",
			"Moved the desktop side menu higher to keep it clear of the counters.",
			"Enlarged menu icons and artwork on Auto Kick and boost offers.",
			"Refreshed the Starter Pack artwork with a larger pet and rays.",
		},
	},
	{
		id = "2026-10-29-skill-gain",
		date = "October 29, 2026",
		title = "Bigger skill rewards",
		changes = {
			"Skill gains now pop up larger with a bouncy rise.",
			"Moved the energy icon closer to the amount.",
			"Fixed skill text, outlines and icons fading at different times.",
		},
	},
	{
		id = "2026-10-29",
		date = "October 29, 2026",
		title = "What's new",
		changes = {
			"Added Update Log to read the latest game changes.",
			"Moved developer tools to DEV in the top bar.",
		},
	},
}

return releases
