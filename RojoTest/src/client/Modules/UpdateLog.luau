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
		id = "2026-11-04-v0.2.2",
		date = "2026-11-04",
		version = "0.2.2",
		title = "Leaderboards, eggs & loading",
		published = false,
		changes = {
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
				id = "stand-rims",
				category = "Improved",
				summary = "Matching ball and egg stands",
				details = "Dakemo555 gave the ball stand the egg stand's look: path-grey tiers with whole studs, a dark studded rim around each tread and dark frames under the ball pads. The egg seats turn with the stand beneath them and sit centred on it, and the steps up to the eggs got the same dark rim.",
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
