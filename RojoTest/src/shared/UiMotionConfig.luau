--!strict
-- Все настройки движения UI собраны здесь. Масштаб 1 = обычный размер.
local Theme = require(script.Parent.UiMotionTheme)
return {
	Button = {
		HoverScale = Theme.hover.scale, -- +8% из центра, без изменения цвета.
		PressScale = Theme.press.scale, -- Размер при удержании мыши / пальца / кнопки A.
		HoverTime = Theme.hover.time, -- Более плавное наведение и уход курсора.
		PressTime = Theme.press.time, -- Плавное сжатие при нажатии.
		ReleaseOvershoot = Theme.release.overshootMultiplier, -- После отпускания на 5% выше целевого размера.
		ReleaseTime = Theme.release.time, -- Более долгий рост до пика overshoot.
		MaximumScale = Theme.release.maximumScale, -- Запас раскладки, включая hover × overshoot.
		ReleaseFrequency = Theme.release.spring.frequency, -- Более медленный пружинный возврат с пика.
		ReleaseDamping = Theme.release.spring.dampingRatio, -- Ближе к 1 = меньше колебаний.
	},
	Window = {
		ClosedScale = Theme.open.from, -- Открытие начинается с 5%, как обратное закрытие.
		CloseScale = Theme.close.to, -- При закрытии сжимаем до 5% обычного размера.
		OvershootScale = Theme.open.overshoot, -- Пик выпрыгивания перед возвратом к размеру 1.
		OpenTime = Theme.open.time, -- Обратное сжатию раскрытие: быстро в начале, мягко в конце.
		SettleFrequency = Theme.open.spring.frequency, -- Неторопливый пружинный возврат от пика к 1.
		SettleDamping = Theme.open.spring.dampingRatio, -- Мягкий возврат без длинного раскачивания.
		CloseAnticipationTime = Theme.close.anticipationTime, -- Небольшое расширение перед закрытием.
		CloseTime = Theme.close.time, -- Сжатие от пика до CloseScale.
		FadeInTime = Theme.open.fadeTime, -- Сначала проявляем маленькое окно, затем раскрываем.
		FadeOutTime = Theme.close.fadeTime, -- Короткое исчезновение строго после достижения 5%.
		ChromeMargin = 70, -- Запас под выступающие заголовки, иконки и крестик.
	},
	Navigation = {
		PhoneAdminY = 48, -- Admin ниже верхних кнопок: hover не задевает Settings/Auto Kick.
		MinimumGap = 14, -- Минимальный зазор между кнопками левого меню, экранные px.
		HoverClearance = 10, -- Свободное место сверх роста двух соседних кнопок и их обводок.
	},
	Spacing = {
		MinimumGap = 16, -- Минимум между соседними кнопками в дизайн-пространстве UI.
		HoverClearance = 16, -- Запас сверх роста: рамки до 4 px, тень и возвратная пружина.
		ScrollInset = 16, -- Поля сетки, чтобы увеличенная карточка не обрезалась скроллом.
	},
	Hud = {
		PhoneStarterOfferY = 122, -- Между календарём и зоной прыжка, включая выступающий арт.
		PhoneSkillOfferY = 243,
		PhoneWinsOfferY = 364,
		LevelBarY = 520, -- Запас над нижними предложениями, включая выступающие иконки.
		BottomOffersY = 604, -- Цены и hover нижнего ряда остаются выше подсказки.
		SlideTime = Theme.hud.time, -- Более медленный выезд и возврат, с мягким началом и остановкой.
		SlideOvershoot = Theme.hud.overshootPixels, -- Замах/перелёт на 12 экранных px, независимо от экрана.
		SlideAnticipationTime = Theme.hud.anticipationTime, -- Небольшой замах внутрь перед уходом.
		SlideSettleFrequency = Theme.hud.spring.frequency, -- Плавное возвращение с перелёта на своё место.
		SlideSettleDamping = Theme.hud.spring.dampingRatio,
		OffscreenPadding = Theme.hud.offscreenPaddingPixels, -- Дополнительный запас за экраном, в экранных px.
		-- Состав блоков: дочерние иконки и тени движутся со своей кнопкой.
		Groups = {
			Left = { "RebirthIcon", "RebirthCount", "WinsIcon", "WinsCount", "FriendBoost" },
			Right = { "StarterPack", "DoubleSkill", "DoubleWins", "Best" },
			Top = { "AutoThrow", "Distance", "HitDistance", "StopTraining" },
			Bottom = {
				"Throw",
				"SkillIcon",
				"Skill",
				"LevelUp",
				"Multiplier",
				"LevelBar",
				"Skill10M",
				"Skill100M",
				"Skill1B",
				"Hint",
				"RebirthProgress",
			},
		},
	},
	Blur = {
		Size = Theme.blur.size, -- Сила размытия мира за любым открытым окном.
		Time = Theme.blur.time, -- Размытие сопровождает более медленное движение HUD.
	},
}
