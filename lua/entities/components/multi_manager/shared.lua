util.register_class("ents.MultiManager", BaseEntityComponent)

function ents.MultiManager:__init()
	BaseEntityComponent.__init(self)
end
function ents.MultiManager:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent(ents.COMPONENT_IO)

	self:BindEvent(ents.IOComponent.EVENT_HANDLE_INPUT, "HandleInput")
end

function ents.MultiManager:HandleInput(input, activator, caller, data)
	if input == "trigger" then
		local ent = self:GetEntity()
		local ioComponent = ent:GetComponent(ents.COMPONENT_IO)
		if ioComponent ~= nil then
			ioComponent:FireOutput("OnTrigger", ent)
		end
	else
		return util.EVENT_REPLY_UNHANDLED
	end
	return util.EVENT_REPLY_HANDLED
end
ents.register_component("multi_manager", ents.MultiManager, "logic", ents.EntityComponent.FREGISTER_NONE)
