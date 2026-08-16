--!strict

local Config = require(game.ReplicatedStorage.Affogato.Config)

local DayService = { Day = 1, PeriodIndex = 1, TimeLeft = Config.DayPeriods[1].duration }
DayService.Changed = Instance.new("BindableEvent")

function DayService.GetPeriod()
	return Config.DayPeriods[DayService.PeriodIndex]
end

function DayService.Start()
	task.spawn(function()
		while true do
			task.wait(1)
			DayService.TimeLeft -= 1
			if DayService.TimeLeft <= 0 then
				DayService.PeriodIndex += 1
				if DayService.PeriodIndex > #Config.DayPeriods then
					DayService.PeriodIndex = 1
					DayService.Day += 1
				end
				DayService.TimeLeft = DayService.GetPeriod().duration
			end
			DayService.Changed:Fire()
		end
	end)
end

return DayService
