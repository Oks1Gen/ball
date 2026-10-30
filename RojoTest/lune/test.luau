--!strict
local suites = {
	require("../tests/Tutorial.spec"),
	require("../tests/PerfectKick.spec"),
	require("../tests/TrainingBoost.spec"),
	require("../tests/ReturnRewards.spec"),
	require("../tests/KickTiming.spec"),
	require("../tests/KickMotion.spec"),
	require("../tests/ZoneProgression.spec"),
	require("../tests/ProfileStorage.spec"),
	require("../tests/PaidRewards.spec"),
	require("../tests/ProfileData.spec"),
	require("../tests/ProfileData.bounds.spec"),
	require("../tests/Economy.spec"),
	require("../tests/Net.spec"),
	require("../tests/FlamePath.spec"),
	require("../tests/HatchSequence.spec"),
	require("../tests/PetNews.spec"),
}
local count, failed = 0, 0
for _, suite in suites do
	for name, test in suite do
		count += 1
		local ok, err = pcall(test)
		if ok then
			print("PASS " .. name)
		else
			failed += 1
			warn("FAIL " .. name .. ": " .. tostring(err))
		end
	end
end
assert(count > 0 and failed == 0, string.format("%d/%d tests failed", failed, count))
print(string.format("%d tests passed", count))
