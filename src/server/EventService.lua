--!strict

local Meta = require(game.ReplicatedStorage.Affogato.Meta)

local EventService = { Current = nil :: any }
EventService.Changed = Instance.new("BindableEvent")

function EventService.GetModifier(name: string): number
	local current = EventService.Current
	if not current or current.endsAt <= os.time() then return 1 end
	return current.data[name] or 1
end

function EventService.StartEvent(eventId: string?)
	local ids = {}
	for id in Meta.Events do table.insert(ids, id) end
	eventId = eventId or ids[math.random(1, #ids)]
	local data = Meta.Events[eventId]
	if not data then return end
	EventService.Current = { id = eventId, name = data.name, description = data.description, endsAt = os.time() + data.duration, data = data }
	EventService.Changed:Fire(EventService.Current)
	task.delay(data.duration, function()
		if EventService.Current and EventService.Current.id == eventId then EventService.Current = nil EventService.Changed:Fire(nil) end
	end)
end

function EventService.Start()
	task.spawn(function()
		task.wait(45)
		while true do
			EventService.StartEvent()
			task.wait(math.random(210, 330))
		end
	end)
end

return EventService
