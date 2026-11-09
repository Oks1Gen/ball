--!strict
-- Presentation of confirmed progression only. Never buys or awards anything.
local Economy = require("./Economy")
local Notices = {}
Notices.Duration = 9
Notices.Gap = 0.65

export type Notice = {
	id: string,
	kind: string,
	rank: number,
	title: string,
	detail: string,
	itemId: string?,
	lane: number?,
	action: string,
}

local function upgrade(data: any, catalog: { any }, owned: any, field: string): any
	local power = 1
	for _, item in catalog do
		if owned[item.id] == true then
			power = math.max(power, item[field])
		end
	end
	local best: any = nil
	for _, item in catalog do
		if
			not owned[item.id]
			and item[field] > power
			and data.wins >= item.cost
			and (not best or item[field] > best[field])
		then
			best = item
		end
	end
	return best
end

function Notices.available(info: any, config: any): { Notice }
	local result: { Notice } = {}
	local data = info and info.data
	if not data or (data.tutorialStage or 0) < 5 or data.settings.upgradeNotices == false then
		return result
	end
	local laneIndex = 1
	for index, lane in config.Lanes do
		if data.rebirths >= lane.rebirths then
			laneIndex = index
		end
	end
	if laneIndex > 1 and info.training ~= laneIndex then
		local lane = config.Lanes[laneIndex]
		table.insert(result, {
			id = "training:" .. laneIndex,
			kind = "Training",
			rank = laneIndex,
			title = "×" .. lane.multiplier .. " Training",
			detail = "A stronger training field is now unlocked.",
			lane = laneIndex,
			action = "SHOW PATH",
		})
	end
	if info.rebirthReady == true then
		table.insert(result, {
			id = "rebirth:" .. (data.rebirths + 1),
			kind = "Rebirth",
			rank = data.rebirths + 1,
			title = "Rebirth #" .. (data.rebirths + 1),
			detail = "Rebirth multiplier: ×" .. (data.rebirths + 2) .. " Skill",
			action = "VIEW REBIRTH",
		})
	end
	local ball = upgrade(data, config.Stones, data.stones, "trainingBonus")
	if ball then
		table.insert(result, {
			id = "ball:" .. ball.id,
			kind = "Ball",
			rank = ball.trainingBonus,
			title = ball.name,
			detail = "+" .. ball.trainingBonus .. " Training  ·  " .. Economy.format(ball.cost) .. " Wins",
			itemId = ball.id,
			action = "VIEW BALL",
		})
	end
	local trail = upgrade(data, config.Trails, data.trails, "boost")
	if trail then
		table.insert(result, {
			id = "trail:" .. trail.id,
			kind = "Trail",
			rank = trail.boost,
			title = trail.name,
			detail = "×" .. trail.boost .. " Wins  ·  " .. Economy.format(trail.cost) .. " Wins",
			itemId = trail.id,
			action = "VIEW TRAIL",
		})
	end
	return result
end

-- At most one live notice and four pending candidates. A category never
-- advertises a weaker item after the player spends currency elsewhere.
function Notices.new(): any
	local state: any = { current = nil, remaining = 0, cooldown = 0, candidates = {}, announced = {} }
	function state:update(info: any, config: any)
		-- Alerts shown in earlier sessions stay announced: each one appears once.
		local seen = info and info.data.notices
		if type(seen) == "table" then
			for kind, rank in seen do
				if type(rank) == "number" then
					self.announced[kind] = math.max(self.announced[kind] or 0, rank)
				end
			end
		end
		self.candidates = Notices.available(info, config)
		self.enabled = info ~= nil
			and info.data.settings.upgradeNotices ~= false
			and (info.data.tutorialStage or 0) >= 5
		local valid = false
		for _, candidate in self.candidates do
			if self.current and candidate.id == self.current.id then
				valid = true
			end
		end
		if self.current and not valid then
			self:dismiss()
		end
	end
	function state:dismiss()
		self.current = nil
		self.remaining = 0
		self.cooldown = Notices.Gap
	end
	function state:step(dt: number, blocked: boolean): Notice?
		if not self.enabled or blocked then
			return nil
		end
		self.cooldown = math.max(0, self.cooldown - dt)
		if self.current then
			self.remaining = math.max(0, self.remaining - dt)
			if self.remaining <= 0 then
				self:dismiss()
			end
		end
		if not self.current and self.cooldown <= 0 then
			for _, candidate in self.candidates do
				if candidate.rank > (self.announced[candidate.kind] or 0) then
					self.current = candidate
					self.remaining = Notices.Duration
					self.announced[candidate.kind] = candidate.rank
					if self.onAnnounce then
						self.onAnnounce(candidate.kind, candidate.rank)
					end
					break
				end
			end
		end
		return self.current
	end
	return state
end

return Notices
