--!strict
local Config = require(script.Parent.UiMotionConfig)
local Spacing = {}

-- Обе соседние кнопки могут быть увеличены одновременно, пока курсор переходит
-- между ними. Зазор включает рост обеих половин, обводки, тень и запас пружины.
function Spacing.gap(span: number): number
	return math.max(
		Config.Spacing.MinimumGap,
		math.ceil(span * (Config.Button.MaximumScale - 1)) + Config.Spacing.HoverClearance
	)
end

-- Равные кнопки помещаются в прежнюю ширину строки вместе с безопасными зазорами.
-- height позволяет использовать тот же зазор для строк и колонок сетки.
function Spacing.row(available: number, count: number, height: number?): (number, number)
	local gap = Spacing.gap(math.max(available / count, height or 0))
	local width = math.floor((available - (count - 1) * gap) / count)
	return math.max(1, width), gap
end

return Spacing
