--!strict
-- Generated from Assets/UI/bouncy-motion.theme.json by tools/sync-motion-theme.mjs.
return {
	hover = {
		scale = 1.08,
		rotate = 0,
		time = 0.2,
		style = "Quad" :: "Quad",
		easing = "quadOut" :: "quadOut",
	},
	press = {
		scale = 0.96,
		time = 0.11,
		easing = "quadOut" :: "quadOut",
	},
	release = {
		overshootMultiplier = 1.05,
		time = 0.18,
		easing = "quartOut" :: "quartOut",
		maximumScale = 1.14,
		spring = {
			frequency = 4,
			dampingRatio = 0.85,
		},
	},
	open = {
		style = "pop" :: "pop",
		from = 0.05,
		time = 0.26,
		easing = "quartOut" :: "quartOut",
		fadeTime = 0.04,
		fadeEasing = "linear" :: "linear",
		fadeBeforeScale = true,
		overshoot = 1.06,
		spring = {
			frequency = 6.5,
			dampingRatio = 0.85,
		},
	},
	close = {
		anticipationScale = 1.06,
		anticipationTime = 0.07,
		anticipationEasing = "quadOut" :: "quadOut",
		to = 0.05,
		time = 0.26,
		easing = "quartIn" :: "quartIn",
		fadeTime = 0.04,
		fadeEasing = "linear" :: "linear",
		fadeAfterScale = true,
	},
	hud = {
		time = 0.45,
		hideEasing = "quartIn" :: "quartIn",
		showEasing = "quartOut" :: "quartOut",
		overshootPixels = 12,
		anticipationTime = 0.1,
		anticipationEasing = "quadOut" :: "quadOut",
		offscreenPaddingPixels = 80,
		spring = {
			frequency = 4,
			dampingRatio = 0.85,
		},
	},
	blur = {
		size = 22,
		time = 0.35,
		easing = "quadOut" :: "quadOut",
	},
	disabled = {
		mode = "instant" :: "instant",
		cancelRunning = true,
		buttonScale = 1,
		keepStaticBlur = true,
	},
}
