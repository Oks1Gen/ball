--!strict
-- Все настройки движения UI собраны здесь. Масштаб 1 = обычный размер.
return {
	Button = {
		HoverScale = 1.08, -- +8% из центра, без изменения цвета.
		PressScale = 0.96, -- Размер при удержании мыши / пальца / кнопки A.
		HoverTime = 0.11, -- Секунды наведения и ухода курсора.
		PressTime = 0.06, -- Быстрый отклик в момент нажатия.
		ReleaseFrequency = 10, -- Больше = быстрее возврат после нажатия.
		ReleaseDamping = 0.85, -- Ближе к 1 = меньше колебаний.
	},
	Window = {
		ClosedScale = 0.70, -- Окно на 30% меньше перед открытием / после закрытия.
		OvershootScale = 1.06, -- Пик выпрыгивания перед возвратом к размеру 1.
		OpenTime = 0.30, -- Более плавный рост от текущего размера до пика.
		SettleFrequency = 6.5, -- Неторопливый пружинный возврат от пика к 1.
		SettleDamping = 0.85, -- Мягкий возврат без длинного раскачивания.
		CloseAnticipationTime = 0.07, -- Небольшое расширение перед закрытием.
		CloseTime = 0.18, -- Сжатие от пика до ClosedScale.
		FadeInTime = 0.14, -- Проявление согласовано с более медленным ростом окна.
		FadeOutTime = 0.14, -- Исчезновение во время сжатия.
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
		PhoneSkillOfferY = 320, -- Между правыми предложениями учитываются выступающие иконки.
		PhoneWinsOfferY = 400,
		LevelBarY = 520, -- Запас над нижними предложениями, включая выступающие иконки.
		BottomOffersY = 604, -- Цены и hover нижнего ряда остаются выше подсказки.
		SlideTime = 0.45, -- Более медленный выезд и возврат, с мягким началом и остановкой.
		OffscreenPadding = 80, -- Дополнительный запас за экраном, в экранных px.
		-- Состав блоков: дочерние иконки и тени движутся со своей кнопкой.
		Groups = {
			Left = { "RebirthIcon", "RebirthCount", "WinsIcon", "WinsCount", "FriendBoost" },
			Right = { "StarterPack", "DoubleSkill", "DoubleWins", "Best" },
			Top = { "AutoThrow", "Daily", "Settings", "Distance", "HitDistance", "StopTraining" },
			Bottom = {
				"Throw",
				"SkillIcon",
				"Skill",
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
		Size = 22, -- Сила размытия мира за любым открытым окном.
		Time = 0.35, -- Размытие сопровождает более медленное движение HUD.
	},
}
