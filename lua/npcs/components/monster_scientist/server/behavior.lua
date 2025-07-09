-- SPDX-FileCopyrightText: (c) 2021 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

function ents.MonsterScientist:InitializeSchedules() -- This is not a hook, we'll have to call this functions ourselves later
	self.Schedules = {}

	self:InitializeController()
end

function ents.MonsterScientist:SelectSchedule()
end
