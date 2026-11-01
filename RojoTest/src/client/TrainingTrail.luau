--!strict
-- The equipped trail behind the practice ball on a training lane. One flight
-- effect lives for the whole session: it hides while the ball waits between
-- the shots of a cycle and is rebuilt only when the equipped trail changes.
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local BallEffects = require(script.Parent.BallEffects)
local TrainingTrail = {}

export type Handle = {
	-- trail id from the profile, ball position, ball shown, effects allowed
	update: (string?, Vector3, boolean, boolean) -> (),
	clear: () -> (),
}

function TrainingTrail.new(): Handle
	local effect: BallEffects.FlightHandle? = nil
	local id = "None"
	local last: Vector3? = nil
	local lastAt = 0
	local function clear()
		if effect then
			-- Stop lets the ribbons and particles already in the air fade out.
			effect.stop()
			effect = nil
		end
		last = nil
	end
	return {
		update = function(trail: string?, position: Vector3, visible: boolean, enabled: boolean)
			local def = trail and Config.find(Config.Trails, trail)
			local wanted = if def then def.id else "None"
			if wanted ~= id then
				clear()
				id = wanted
			end
			if not enabled or id == "None" then
				clear()
				return
			end
			local current = effect or BallEffects.flight(id)
			effect = current
			local now = os.clock()
			-- The first frame of a shot has no previous point: the ball has just
			-- reappeared at the start of the lane, so no velocity is invented.
			local velocity = if last and visible
				then (position - last) / math.max(now - lastAt, 1 / 240)
				else Vector3.zero
			last = if visible then position else nil
			lastAt = now
			current.update(position, velocity, visible, 0.5, 0)
		end,
		clear = clear,
	}
end

return TrainingTrail
