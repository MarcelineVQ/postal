Postal.control = {}

local event_listeners = {}
local update_listeners = {}

function Postal.control.on_event()
	for listener, _ in pairs(event_listeners) do
		if event == listener.event and not listener.deleted then
			listener.action()
		end
	end
end

function Postal.control.on_update()
	-- event_listeners = Postal.util.set_filter(event_listeners, function(l) return not l.deleted end)
	-- update_listeners = Postal.util.set_filter(update_listeners, function(l) return not l.deleted end)
	
	for listener, _ in pairs(update_listeners) do
		if not listener.deleted then
			listener.action()
		end
	end
end



function Postal.control.event_listener(event, action)
	local self = {}
	
	local listener = { event=event, action=action }
	
	function self.set_action(action)
		listener.action = action
	end
	
	function self.start()
		Postal.util.set_add(event_listeners, listener)
		if not Postal.util.any(event_listeners, function(l) return l.event == event end) then
			PostalControlFrame:RegisterEvent(event)
		end
		return self
	end
	
	function self.stop()
		listener.deleted = true
		if not Postal.util.any(event_listeners, function(l) return l.event == event end) then
			PostalControlFrame:UnregisterEvent(event)
		end
		-- Postal.util.set_remove(event_listeners, listener)
		return self
	end
	
	return self
end

function Postal.control.update_listener(action)
	local self = {}
	
	local listener = { action=action }

	function self.set_action(action)
		listener.action = action
	end
	
	function self.start()
		Postal.util.set_add(update_listeners, listener)
		return self
	end
	
	function self.stop()
		listener.deleted = true
		-- Postal.util.set_remove(update_listeners, listener)
		return self
	end
	
	return self
end

	

function Postal.control.on_next_update(callback)
	local listener = Postal.control.update_listener()
	
	listener.set_action(function()
		listener:stop()
		return callback()
	end)
	
	listener.start()
end

function Postal.control.on_next_event(event, callback)
	local listener = Postal.control.event_listener(event)
	
	listener.set_action(function()
		listener:stop()
		return callback()
	end)
	
	listener.start()
end

function Postal.control.as_soon_as(p, callback)
	local listener = Postal.control.update_listener()	
	
	listener.set_action(function()
		if p() then
			listener.stop()
			return callback()
		end
	end)
	
	listener.start()
end



function Postal.control.controller()
	local self = {}
	
	local state
	
	local listener = Postal.control.update_listener()
	listener.set_action(function()
		if state and state.p() then
			local k = state.k
			state = nil
			return k()
		end
	end)
	listener.start()
	
	function self.wait(p, k)
		state = {
			k = k,
			p = p,
		}
	end
	
	function self.reset()
		state = nil
	end
	
	function self.cleanup()
		listener.stop()
	end
	
	return self
end
