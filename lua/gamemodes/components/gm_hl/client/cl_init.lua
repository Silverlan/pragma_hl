-- SPDX-FileCopyrightText: (c) 2021 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("../shared.lua")
local Component = ents.GmHl

function Component:InitializeReflectionProbe()
	if(ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_REFLECTION_PROBE)})() == nil) then
		ents.create("env_reflection_probe"):Spawn()
	end
end
