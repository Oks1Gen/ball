--!strict
--!nocheck
-- Dependency injection keeps package paths owned by the consuming project.
return function(React, Ripple)
	-- onRest(value) fires when the spring settles; reduced motion settles immediately.
	local function useSpringBinding(initial, options, reducedMotion, onRest)
		local binding, update = React.useBinding(initial)
		local rest = React.useRef(onRest)
		rest.current = onRest
		local motion = React.useRef(nil)
		local goal = React.useRef(initial)
		local frequency = options.Frequency
		local damping = options.DampingRatio
		React.useEffect(function()
			local spring = Ripple.createSpring(initial, {
				frequency = frequency,
				dampingRatio = damping,
				start = true,
			})
			motion.current = spring
			local disconnect = spring:onChange(update)
			local completed = spring:onComplete(function(value)
				if rest.current then
					rest.current(value)
				end
			end)
			spring:setGoal(goal.current)
			return function()
				disconnect()
				completed()
				spring:destroy()
				if motion.current == spring then
					motion.current = nil
				end
			end
		end, { frequency, damping })
		local function setGoal(value)
			goal.current = value
			if reducedMotion then
				update(value)
			end
			if motion.current then
				if reducedMotion then
					motion.current:setPosition(value)
				end
				motion.current:setGoal(value)
			end
			if reducedMotion and rest.current then
				task.defer(rest.current, value)
			end
		end
		React.useEffect(function()
			if reducedMotion then
				setGoal(goal.current)
			end
		end, { reducedMotion })
		return binding, setGoal
	end

	local function useWindowNavigation()
		local activeWindow, setActiveWindow = React.useState(nil)
		local function toggle(windowId)
			assert(type(windowId) == "string", "Window id must be a string")
			setActiveWindow(function(current)
				if current == windowId then
					return nil
				end
				return windowId
			end)
		end
		local function close(windowId)
			setActiveWindow(function(current)
				if current == windowId then
					return nil
				end
				return current
			end)
		end
		return activeWindow, toggle, close
	end
	return {
		useSpringBinding = useSpringBinding,
		useWindowNavigation = useWindowNavigation,
	}
end
