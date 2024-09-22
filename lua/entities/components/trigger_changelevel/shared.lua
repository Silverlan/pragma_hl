util.register_class("ents.TriggerChangelevel", BaseEntityComponent)

ents.TriggerChangelevel.SF_DISABLE_TOUCH = 2
ents.TriggerChangelevel.SF_TO_PREVIOUS_CHAPTER = 4

function ents.TriggerChangelevel:__init()
	BaseEntityComponent.__init(self)
end

function ents.TriggerChangelevel:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_PHYSICS)
	self:AddEntityComponent(ents.COMPONENT_IO)
	self:AddEntityComponent(ents.COMPONENT_TOUCH)

	self:BindEvent(Entity.EVENT_HANDLE_KEY_VALUE, "HandleKeyValue")
	self:BindEvent(ents.IOComponent.EVENT_HANDLE_INPUT, "HandleInput")
	self:BindEvent(ents.PhysicsComponent.EVENT_ON_PHYSICS_INITIALIZED, "OnPhysicsInitialized")
	self:BindEvent(ents.TouchComponent.EVENT_CAN_TRIGGER, "CanTrigger")
	self:BindEvent(ents.TouchComponent.EVENT_ON_TRIGGER, "ChangeLevel")

	self.m_spawnFlags = 0
	self.m_mapName = ""
	self.m_landmarkName = ""
end

function ents.TriggerChangelevel:OnPhysicsInitialized()
	local physComponent = self:GetEntity():GetComponent(ents.COMPONENT_PHYSICS)
	if physComponent == nil then
		return
	end
	physComponent:SetCollisionFilterMask(phys.COLLISIONMASK_PLAYER)
	physComponent:SetCollisionFilterGroup(phys.COLLISIONMASK_TRIGGER)
	physComponent:SetCollisionCallbacksEnabled(true)
end

function ents.TriggerChangelevel:HandleKeyValue(key, val)
	if key == "spawnflags" then
		self.m_spawnFlags = tonumber(val)
	elseif key == "map" then
		self.m_mapName = val
	elseif key == "landmark" then
		self.m_landmarkName = val
	else
		return util.EVENT_REPLY_UNHANDLED
	end
	return util.EVENT_REPLY_HANDLED
end

function ents.TriggerChangelevel:HandleInput(input, activator, caller, data)
	if input == "changelevel" then
		self:ChangeLevel()
	else
		return util.EVENT_REPLY_UNHANDLED
	end
	return util.EVENT_REPLY_HANDLED
end

function ents.TriggerChangelevel:ChangeLevel(activator)
	local ent = self:GetEntity()
	if util.is_valid(activator) == false then
		activator = ent
	end
	local ioComponent = ent:GetComponent(ents.COMPONENT_IO)
	if ioComponent ~= nil then
		ioComponent:FireOutput("OnChangeLevel", activator)
	end
	if #self.m_mapName > 0 then
		game.change_map(self.m_mapName, self.m_landmarkName)
	end
end

function ents.TriggerChangelevel:CanTrigger(ent, physObj)
	return util.EVENT_REPLY_HANDLED, ent:IsPlayer()
end

function ents.TriggerChangelevel:OnEntitySpawn()
	local ent = self:GetEntity()
	if bit.band(self.m_spawnFlags, ents.TriggerChangelevel.SF_DISABLE_TOUCH) ~= 0 then
		ent:RemoveComponent(ents.COMPONENT_TOUCH)
		ent:RemoveComponent(ents.COMPONENT_PHYSICS)
		ent:RemoveComponent(ents.COMPONENT_MODEL)
		return
	end
	local touchComponent = ent:GetComponent(ents.COMPONENT_TOUCH)
	if touchComponent ~= nil then
		touchComponent:SetTriggerFlags(ents.TouchComponent.TRIGGER_FLAG_BIT_PLAYERS)
	end
	if SERVER == true then
		local physComponent = ent:GetPhysicsComponent()
		if physComponent ~= nil then
			physComponent:InitializePhysics(phys.TYPE_STATIC)
		end
	end
end
ents.register_component("trigger_changelevel", ents.TriggerChangelevel, "physics/triggers")
