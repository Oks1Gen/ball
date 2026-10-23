--!strict
-- Shared geometry for the three requested egg-preview layouts.
local Layout = {}
function Layout.calculate(width: number, height: number, count: number, variant: string?): any
	local mode = variant or "Gallery"
	local cols = if mode == "Gallery"
		then math.min(count, math.max(1, math.floor((width + 12) / 150)))
		elseif mode == "LargeCards" then math.min(count, math.max(1, math.floor((width + 12) / 210)))
		else math.min(count, width >= 460 and 2 or 1)
	local rows = math.ceil(count / cols)
	local cardW = math.floor((width - 12 - (cols - 1) * 12) / cols)
	local minimum = mode == "Split" and 88 or 174
	local cardH = math.max(minimum, math.floor((height - 16 - (rows - 1) * 12) / rows))
	local r: any = {
		Columns = cols,
		Rows = rows,
		CardWidth = cardW,
		CardHeight = cardH,
		CanvasHeight = rows * cardH + (rows - 1) * 12 + 13,
	}
	if mode == "Split" then
		local artW = math.min(math.floor(cardW * 0.42), cardH + 12)
		local textX = artW + 12
		r.Pet = { 6, 6, artW, cardH - 12 }
		r.Chance = { textX, 5, cardW - textX - 8, 23 }
		r.Name = { textX, 29, cardW - textX - 8, cardH - 55 }
		r.Boost = { textX, cardH - 25, cardW - textX - 8, 21 }
	elseif mode == "Gallery" then
		r.Pet = { 6, 24, cardW - 12, cardH - 86 }
		r.Chance = { 8, 4, cardW - 16, 24 }
		r.Name = { 7, cardH - 60, cardW - 14, 32 }
		r.Boost = { 7, cardH - 26, cardW - 14, 22 }
	else
		r.Pet = { 8, 28, cardW - 16, cardH - 94 }
		r.Chance = { 8, 4, cardW - 16, 24 }
		r.Name = { 7, cardH - 62, cardW - 14, 36 }
		r.Boost = { 7, cardH - 26, cardW - 14, 22 }
	end
	return r
end
return Layout
