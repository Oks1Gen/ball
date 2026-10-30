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
		id = "2026-10-31-ball-portraits",
		date = "October 31, 2026",
		title = "New ball portraits",
		changes = {
			"The Balls inventory now shows bright outlined portraits of each ball instead of 3D previews.",
			"Ball portraits keep a consistent size when browsing or selecting a ball, including Sun and its ring.",
		},
	},
	{
		id = "2026-10-31-new-balls",
		date = "October 31, 2026",
		title = "Brand new balls",
		changes = {
			"All ten balls have new low-poly models with bright colours, on the stands, in your hands and in flight.",
			"The balls are now Rubber, Classic, Beach, Basketball, Leather, Steel, Gold, Storm, Volcano and Sun. Power and prices stay the same.",
			"The ball stand has a clean new look: soft lavender steps, studded pads, and smaller, same-size balls that hover above their pads with captions floating above.",
			"The ball in your hand, on the training lane and in your kick is now the same smaller size, and it waits just ahead of your foot so the kick no longer passes through it.",
		},
	},
	{
		id = "2026-10-31-dev-persistence",
		date = "October 31, 2026",
		title = "Dev panel saves progress",
		changes = {
			"Dev panel grants and progress changes now save to your profile immediately without starting a test session.",
		},
	},
	{
		id = "2026-10-31-hatch-again",
		date = "October 31, 2026",
		title = "Hatch again!",
		changes = {
			"A NEW! badge marks a pet you did not have before.",
			"A duplicate shows how many of that pet you now own.",
			"Open again next to Continue opens the same egg right away when you have the Wins and room.",
		},
	},
	{
		id = "2026-10-31-egg-drama",
		date = "October 31, 2026",
		title = "Bigger egg moments",
		changes = {
			"Every landing knocks the screen, and upgrades and the burst hit harder.",
			"Each upgrade washes the sky and lamps in its colour, and the pedestal rim keeps it.",
			"The egg freezes for a beat at its biggest, then bursts.",
			"Legendary and Mythic eggs turn the garden to night with light pillars and a deep boom.",
		},
	},
	{
		id = "2026-10-30-egg-cracking",
		date = "October 30, 2026",
		title = "Crack your eggs open!",
		changes = {
			"Eggs now open full screen on a big pedestal in a sunset garden.",
			"Click or tap the egg five times: it jumps, spins and cracks a little more each time.",
			"Every landing can upgrade the light behind the egg from white to green, purple, gold and red.",
			"After the last click the egg shakes, grows, glows white and bursts open.",
			"Black pet silhouettes spin past and stop on your new pet, which lands on the pedestal in colour.",
			"Effects off still shows your new pets right away.",
		},
	},
	{
		id = "2026-10-30-training-bubbles",
		date = "October 30, 2026",
		title = "Pop a training boost!",
		changes = {
			"Catch colorful studded bubbles as they float down during training.",
			"Pop a 5.0x–15.0x boost for your next complete kick.",
			"Enjoy bouncy hover, a crunchy pop and colorful confetti.",
			"Boost bubbles stay in front of skill reward pop-ups.",
			"Lightning from popped boosts flies into your Skill counter.",
		},
	},
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
