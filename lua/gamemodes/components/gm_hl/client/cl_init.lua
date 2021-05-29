include("../shared.lua")
local Component = ents.GmHl

function Component:InitializeReflectionProbe()
	if(ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_REFLECTION_PROBE)})() == nil) then
		ents.create("env_reflection_probe"):Spawn()
	end
end
