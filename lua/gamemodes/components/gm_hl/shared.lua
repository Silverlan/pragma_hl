include_component("gm_generic")
util.register_class("ents.GmHl",BaseEntityComponent)
local Component = ents.GmHl
function Component:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self:AddEntityComponent("gm_generic")
	if(CLIENT) then self:BindEvent(ents.GamemodeComponent.EVENT_ON_GAME_READY,"InitializeReflectionProbe") end
end
ents.COMPONENT_GM_HL_CAMPAIGN = ents.register_component("gm_hl",Component)

