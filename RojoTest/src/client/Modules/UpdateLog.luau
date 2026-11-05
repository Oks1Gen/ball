--!strict
-- Single source of player-facing releases, versions and credits.
-- Maintenance contract: docs/update-log.md and AGENTS.md.
export type Category = "New" | "Improved" | "Fixed"
export type Author = { name: string, userId: number? }
export type Credit = { author: string, role: string }
export type Change = {
	id: string,
	category: Category,
	summary: string,
	details: string?,
	credits: { Credit },
}
export type Release = {
	id: string,
	date: string, -- ISO date in Europe/Moscow, independent of the player's timezone.
	version: string, -- Numbers only; the UI supplies the v prefix.
	title: string,
	published: boolean, -- Freeze only after an explicitly authorized game publication.
	changes: { Change },
}
export type Day = { date: string, releases: { Release } }

local UpdateLog = {}
UpdateLog.MaxVisibleDays = 4
UpdateLog.Categories = { "New", "Improved", "Fixed" } :: { Category }
UpdateLog.Authors = {
	dakemo = { name = "Dakemo555", userId = 11789507527 },
} :: { [string]: Author }

UpdateLog.Releases = {
	{
		id = "2026-11-06-v0.5.0",
		date = "2026-11-06",
		version = "0.5.0",
		title = "Shop & permanent upgrades",
		published = false,
		changes = {
			{
				id = "permanent-game-passes",
				category = "New",
				summary = "Permanent passes & a one-time Starter Pack",
				details = "Dakemo555 connected Auto Kick, 2x Skill, 2x Wins and Starter Pack to permanent ownership. Starter Pack grants 10K Wins once and permanent double Skill; its Skill bonus does not stack with the separate pass.",
				credits = { { author = "dakemo", role = "Shop & gameplay" } },
			},
			{
				id = "repeatable-shop-purchases",
				category = "Improved",
				summary = "Repeatable Skill packs, boosts & guaranteed pets",
				details = "Dakemo555 connected Skill packs, Skip Rebirth, three single-kick training boosts and guaranteed Glitched Dragons. Paid pets wait safely when storage is full, and retrying a purchase cannot grant the same reward twice.",
				credits = { { author = "dakemo", role = "Shop & gameplay" } },
			},
			{
				id = "shop-prices-ownership",
				category = "Improved",
				summary = "Roblox prices, clear ownership & egg availability",
				details = "Dakemo555 connected Roblox prices across the shop and purchase buttons, with clear Owned and Off Sale states. Where random paid rewards are restricted, Wins eggs show and grant one guaranteed pet instead.",
				credits = { { author = "dakemo", role = "Shop UI & gameplay" } },
			},
		},
	},
	{
		id = "2026-11-05-v0.4.0",
		date = "2026-11-05",
		version = "0.4.0",
		title = "Ocean Depths opens",
		published = false,
		changes = {
			{
				id = "world1-hd-studs",
				category = "Improved",
				summary = "HD studs across both worlds",
				details = "Dakemo555 directed the material update for Football City and Ocean Depths. Square studs are clearer on terrace edges, reef shelves and the smaller galleon.",
				credits = { { author = "dakemo", role = "Map art direction" } },
			},
			{
				id = "dev-map-navigation",
				category = "Improved",
				summary = "Developer world travel & noclip flight",
				details = "Dakemo555 added world travel and noclip flight to the developer panel. Developers can visit the Ocean Depths preview in Studio, fly around its scenery and return to Football City without changing their saved world progress.",
				credits = { { author = "dakemo", role = "Developer tools" } },
			},
			{
				id = "ocean-course-scenery",
				category = "New",
				summary = "Ocean Depths: seven new landscapes",
				details = "Dakemo555 built seven Ocean Depths landscapes with landmarks on both banks: amber kelp, wrecked ships, mosaic ruins, jellyfish, basalt vents, a deep-blue amphitheatre and a mint pearl grotto.",
				credits = { { author = "dakemo", role = "Map & art" } },
			},
			{
				id = "ocean-life-atmosphere",
				category = "New",
				summary = "Animated sea life across Ocean Depths",
				details = "Dakemo555 added close fish schools, moving caustic light, drifting plankton and bubble streams throughout Ocean Depths. Mantas pass above the course, jellyfish glow in waves and the squid appears in the distance. Spatial audio, distant reefs and a local underwater backdrop replace the old background. Fish remain twice as large and fast.",
				credits = { { author = "dakemo", role = "Models, effects & animation" } },
			},
			{
				id = "ocean-world-travel",
				category = "New",
				summary = "Ocean Depths is fully playable",
				details = "Dakemo555 selected Kelp, Leviathan, Treasure, Abyss and Jelly eggs with nautilus shell cradles, labels, levitation, outlines and themed effects. Unlock Ocean Depths for 100,000 Wins and earn triple training and kick rewards. Eight named locations lead to Pearl Grotto, where reaching the finish lights the pearl.",
				credits = { { author = "dakemo", role = "UI, gameplay & fix direction" } },
			},
		},
	},
	{
		id = "2026-11-04-v0.3.0",
		date = "2026-11-04",
		version = "0.3.0",
		title = "Voxel Football City & leaderboards",
		published = false,
		changes = {
			{
				id = "voxel-locations",
				category = "Improved",
				summary = "Studded voxel makeover for every location",
				details = "Dakemo555 rebuilt all eight course locations in a studded voxel style, with stands full of fans, a park pond, a brick shopping street, dock cranes, factory chimneys, rooftop towers and academy halls. Taller dividers display each location's name and leave a clear view down the pitch.",
				credits = { { author = "dakemo", role = "Map & art" } },
			},
			{
				id = "leaderboards",
				category = "New",
				summary = "New leaderboards with a Donate ranking",
				details = "Dakemo555 rebuilt the four lobby leaderboards with bold colour frames, category icons, player avatars and gold, silver and bronze top places. The new Donate board ranks the Robux players have spent in the game.",
				credits = { { author = "dakemo", role = "Map, UI & code" } },
			},
			{
				id = "egg-preview-world-size",
				category = "Improved",
				summary = "Egg previews centered above each egg",
				details = "Dakemo555 centered previews above the eggs, sized them in world studs and restyled them with the game's studded panels.",
				credits = { { author = "dakemo", role = "Egg preview layout & styling" } },
			},
			{
				id = "loading-skip",
				category = "Fixed",
				summary = "Click anywhere to skip asset loading",
				details = "Dakemo555 fixed the skip control and added a confirmation while your character and ground finish loading.",
				credits = { { author = "dakemo", role = "Loading screen fix" } },
			},
			{
				id = "club-lobby",
				category = "Improved",
				summary = "Football club lobby & Ocean Depths preview",
				details = "Dakemo555 dressed Football City's lobby with a Champions Cup, FREE chest and matching shops, and built an Ocean Depths art preview with a sandy Coral Reef, shell trophy, reef portal, four colourful fish species and manta rays.",
				credits = { { author = "dakemo", role = "Map & art" } },
			},
		},
	},
	{
		id = "2026-11-03-v0.2.1",
		date = "2026-11-03",
		version = "0.2.1",
		title = "Map readability & scenery",
		published = false,
		changes = {
			{
				id = "stand-readability",
				category = "Improved",
				summary = "Instant ball buying, reveals & compact alerts",
				details = "Dakemo555 made E at the ball stand buy or equip on the spot and added 3D reveals for new balls and rebirths. Messages and upgrade alerts are compact, stack under Auto Kick and each alert appears once; Welcome Back shows only after an hour away. Ball prices and training requirements sit neatly above their stands.",
				credits = {
					{ author = "dakemo", role = "Code, map & UI" },
				},
			},
			{
				id = "lobby-scenery",
				category = "Fixed",
				summary = "Matching egg displays & city landmarks",
				details = "Dakemo555 built a lower curved stand in path grey with a dark studded rim, displaying Meadow, Glacier, Magma, Void and Celestial eggs on matching raised studded seats, gave each Football City location a distinct sideline landmark and varied the cloud borders. Prices, rewards and purchases stay the same.",
				credits = { { author = "dakemo", role = "Map & art" } },
			},
			{
				id = "lobby-paths",
				category = "Improved",
				summary = "Smoother paths & moving arrows",
				details = "Dakemo555 joined whole checker squares and larger studs cleanly across the lobby, gave the orange Kick Zone complete tiles and one even border without protruding edges, and added bold chevrons that flow toward it and fade gently at each end.",
				credits = { { author = "dakemo", role = "Map & animation" } },
			},
			{
				id = "lobby-walls",
				category = "Improved",
				summary = "A more compact, cleaner map",
				details = "Dakemo555 made the whole map about a quarter smaller in proportion, so stations and locations are closer together; textures shrank with it and distances and rewards stay the same. Dakemo555 also removed loose lobby props, centred the approaches on the ball stand and added a recessed upper terrace to the studded walls.",
				credits = { { author = "dakemo", role = "Map" } },
			},
			{
				id = "spawn-loading",
				category = "Fixed",
				summary = "Safer joins with solid ground underfoot",
				details = "Dakemo555 improved joining and respawning: the loading screen counts the assets as they load and stays until your character stands on the loaded floor, so you never fall through the map.",
				credits = { { author = "dakemo", role = "Code & gameplay" } },
			},
		},
	},
	{
		id = "2026-11-02-v0.2.0",
		date = "2026-11-02",
		version = "0.2.0",
		title = "Football City & gameplay",
		published = false,
		changes = {
			{
				id = "update-log",
				category = "New",
				summary = "Upgrade alerts & rebirth reminders",
				details = "Compact top-screen alerts match the game's translucent windows, with clearer spacing for new balls, trails, training fields and ready rebirths. Open the matching menu or follow arrows to training; turn alerts off in Settings. Rebirth has a centred icon, progress percentage and ready pulse. Updates include daily cards and contributor credits.",
				credits = { { author = "dakemo", role = "UI & code" } },
			},
			{
				id = "lobby",
				category = "Improved",
				summary = "Redesigned lobby",
				details = "A central plaza links training, balls and eggs, with leaderboards by the rear waterfall and an open entrance to the course. Cleaner paths, warmer walls and matching stands complete a 20% smaller map; shot distances and rewards stay the same.",
				credits = { { author = "dakemo", role = "Map" } },
			},
			{
				id = "kicking",
				category = "Improved",
				summary = "Better kicking controls",
				details = "Kick from your position anywhere inside the orange zone, with the ball launching from your foot. A larger distance counter follows the ball throughout its flight.",
				credits = { { author = "dakemo", role = "Gameplay & UI" } },
			},
			{
				id = "world",
				category = "Improved",
				summary = "A longer Football City",
				details = "Explore eight football locations, now twice as long, from a local field to City Stadium. Buildings and props keep their proportions; pitches, paths and cloud borders follow the longer course. Club-colour accents mark the academy and stadium. Longer shots earn more Wins. Your lobby, training and saved progress are preserved.",
				credits = { { author = "dakemo", role = "Map & gameplay" } },
			},
			{
				id = "spawn",
				category = "Fixed",
				summary = "Safer spawning",
				details = "Your character no longer falls under the map when joining or skipping the loading screen.",
				credits = { { author = "dakemo", role = "Gameplay" } },
			},
		},
	},
} :: { Release }

local function versionParts(version: string): (number, number, number)
	local major, minor, patch = string.match(version, "^(%d+)%.(%d+)%.(%d+)$")
	return tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
end

-- Limit dates, never their releases. Sorting a copy preserves authored history.
function UpdateLog.groupReleases(releases: { Release }, limit: number?): { Day }
	local sorted = table.clone(releases)
	table.sort(sorted, function(a, b)
		if a.date ~= b.date then
			return a.date > b.date
		end
		local aMajor, aMinor, aPatch = versionParts(a.version)
		local bMajor, bMinor, bPatch = versionParts(b.version)
		if aMajor ~= bMajor then
			return aMajor > bMajor
		elseif aMinor ~= bMinor then
			return aMinor > bMinor
		end
		return aPatch > bPatch
	end)
	local days: { Day } = {}
	local maximum = math.max(0, math.floor(limit or UpdateLog.MaxVisibleDays))
	for _, release in sorted do
		local day = days[#days]
		if not day or day.date ~= release.date then
			if #days >= maximum then
				break
			end
			local newDay: Day = { date = release.date, releases = {} }
			table.insert(days, newDay)
			day = newDay
		end
		table.insert(day.releases, release)
	end
	return days
end

function UpdateLog.displayDate(date: string): string
	local year, month, day = string.match(date, "^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
	local months = {
		"January",
		"February",
		"March",
		"April",
		"May",
		"June",
		"July",
		"August",
		"September",
		"October",
		"November",
		"December",
	}
	return string.format("%s %d, %s", months[tonumber(month) or 0] or "", tonumber(day) or 0, year or "")
end

return UpdateLog
