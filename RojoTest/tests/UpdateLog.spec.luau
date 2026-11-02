--!strict
local Log = require("../src/client/Modules/UpdateLog")

local function release(date: string, version: string): Log.Release
	return {
		id = date .. "-v" .. version,
		date = date,
		version = version,
		title = "Test",
		published = true,
		changes = {},
	}
end

return {
	["update log groups versions numerically under a single date without editing history"] = function()
		local older = release("2026-11-01", "0.1.8")
		local input =
			{ older, release("2026-11-02", "0.1.9"), release("2026-11-02", "0.1.10"), release("2026-11-02", "0.2.0") }
		local days = Log.groupReleases(input)
		assert(#days == 2 and days[1].date == "2026-11-02")
		assert(#days[1].releases == 3)
		assert(days[1].releases[1].version == "0.2.0")
		assert(days[1].releases[2].version == "0.1.10")
		assert(days[1].releases[3].version == "0.1.9")
		assert(input[1] == older and days[2].releases[1] == older)
	end,
	["update log limits dates without dropping versions from the fourth day"] = function()
		local input = {
			release("2026-10-28", "0.1.0"),
			release("2026-10-29", "0.1.1"),
			release("2026-10-30", "0.1.2"),
			release("2026-10-30", "0.1.3"),
			release("2026-10-31", "0.1.4"),
			release("2026-11-01", "0.1.5"),
			release("2026-11-02", "0.1.6"),
		}
		local days = Log.groupReleases(input)
		assert(#days == 4 and days[4].date == "2026-10-30")
		assert(#days[4].releases == 2)
		assert(#Log.groupReleases(input, 0) == 0 and #Log.groupReleases({}) == 0)
		assert(#input == 7)
	end,
	["update log content has unique versions concise highlights and valid contributor credits"] = function()
		local ids, versions = {}, {}
		local unpublished = {}
		local categories = { New = true, Improved = true, Fixed = true }
		for _, item in Log.Releases do
			assert(not ids[item.id] and not versions[item.version], "Duplicate release/version")
			ids[item.id], versions[item.version] = true, true
			assert(string.match(item.date, "^%d%d%d%d%-%d%d%-%d%d$"))
			assert(string.match(item.version, "^%d+%.%d+%.%d+$"))
			assert(item.id == item.date .. "-v" .. item.version)
			assert(#item.title > 0 and #item.changes >= 1 and #item.changes <= 5)
			if not item.published then
				assert(not unpublished[item.date], "Amend the current draft for this date")
				unpublished[item.date] = true
			end
			local changes = {}
			for _, change in item.changes do
				assert(not changes[change.id] and categories[change.category])
				changes[change.id] = true
				assert(#change.summary > 0 and #change.summary <= 60)
				assert(change.details == nil or #change.details <= 380)
				assert(#change.credits > 0)
				local authors = {}
				for _, credit in change.credits do
					local author = Log.Authors[credit.author]
					assert(author and #author.name > 0 and #credit.role > 0)
					assert(not authors[credit.author], "Duplicate credit")
					authors[credit.author] = true
					assert(author.userId == nil or (author.userId > 0 and author.userId % 1 == 0))
				end
			end
		end
	end,
	["update log date labels do not depend on the client timezone"] = function()
		assert(Log.displayDate("2026-11-02") == "November 2, 2026")
		assert(Log.displayDate("2027-01-01") == "January 1, 2027")
	end,
}
