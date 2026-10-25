--!strict
-- Follow the moving foot during the windup; freeze one trajectory at ball contact.
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Goal = require(game.ReplicatedStorage.Shared.TrainingGoal)
local Shot = {}

export type State = {
	lane: Instance,
	started: number,
	seed: number,
	cycle: number,
	launched: boolean,
	shot: Goal.Shot?,
	retryAt: number,
}

function Shot.update(
	current: State?,
	lane: Instance,
	rootPosition: Vector3,
	seed: number,
	elapsed: number,
	started: number
): State
	local cycle = math.floor(elapsed / Config.TrainingCycle)
	local phase = elapsed % Config.TrainingCycle
	local state: State
	if
		current
		and current.lane == lane
		and current.started == started
		and current.seed == seed
		and current.cycle == cycle
	then
		state = current
	else
		state =
			{ lane = lane, started = started, seed = seed, cycle = cycle, launched = false, shot = nil, retryAt = 0 }
	end
	if phase < Config.KickContact or not state.launched or (not state.shot and os.clock() >= state.retryAt) then
		state.shot = Goal.shot(lane, rootPosition, seed, cycle)
		state.launched = phase >= Config.KickContact
		state.retryAt = os.clock() + 0.75
	end
	return state
end

return Shot
