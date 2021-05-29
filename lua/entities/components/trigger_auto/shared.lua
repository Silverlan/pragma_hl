util.register_class("ents.TriggerAuto",BaseEntityComponent)

ents.TriggerAuto.TRIGGER_STATE_OFF = 0
ents.TriggerAuto.TRIGGER_STATE_ON = 1
ents.TriggerAuto.TRIGGER_STATE_TOGGLE = 2

ents.TriggerAuto.SF_REMOVE_ON_FIRE = 1

function ents.TriggerAuto:__init()
	BaseEntityComponent.__init(self)
end
function ents.TriggerAuto:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent(ents.COMPONENT_IO)
	
	self:BindEvent(Entity.EVENT_HANDLE_KEY_VALUE,"HandleKeyValue")
end

function ents.TriggerAuto:OnRemove()
	if(util.is_valid(self.m_cbOnMapLoaded)) then self.m_cbOnMapLoaded:Remove() end
end

function ents.TriggerAuto:Trigger()
	if(util.is_valid(self.m_cbOnMapLoaded)) then self.m_cbOnMapLoaded:Remove() end
	local ent = self:GetEntity()
	local ioComponent = ent:GetComponent(ents.COMPONENT_IO)
	if(ioComponent ~= nil) then ioComponent:FireOutput("OnTrigger",ent,ents.IOComponent.IO_FLAG_BIT_FORCE_DELAYED_FIRE) end
	if(self.m_spawnFlags ~= nil and bit.band(self.m_spawnFlags,ents.TriggerAuto.SF_REMOVE_ON_FIRE) ~= 0) then self:GetEntity():RemoveSafely() end
end

function ents.TriggerAuto:OnEntitySpawn()
	if(game.is_map_loaded()) then
		self:Trigger()
		return
	end
	self.m_cbOnMapLoaded = game.add_callback("OnMapLoaded",function()
		self:Trigger()
	end)
end

function ents.TriggerAuto:HandleKeyValue(key,val)
	if(key == "triggerstate") then
		self.m_triggerState = tonumber(val) -- TODO
	elseif(key == "globalstate") then
		-- TODO
	elseif(key == "spawnflags") then
		self.m_spawnFlags = tonumber(val)
	else return util.EVENT_REPLY_UNHANDLED end
	return util.EVENT_REPLY_HANDLED
end
ents.COMPONENT_TRIGGER_AUTO = ents.register_component("trigger_auto",ents.TriggerAuto,ents.EntityComponent.FREGISTER_NONE)
