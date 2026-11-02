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
