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
