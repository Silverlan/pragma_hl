function ents.MonsterGeneric:InitializeSchedules() -- This is not a hook, we'll have to call this functions ourselves later
	self.Schedules = {}

	self:InitializeController()
end

function ents.MonsterGeneric:SelectSchedule()
end
