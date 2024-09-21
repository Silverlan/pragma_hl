util.register_class("ents.TriggerOnce", BaseEntityComponent)

ents.TriggerOnce.SF_CLIENTS = 1
ents.TriggerOnce.SF_NPCS = 2
ents.TriggerOnce.SF_PUSHABLES = 4
ents.TriggerOnce.SF_PHYSICS_OBJECTS = 8
ents.TriggerOnce.SF_ONLY_PLAYER_ALLY_NPCS = 16
ents.TriggerOnce.SF_ONLY_CLIENTS_IN_VEHICLES = 32
ents.TriggerOnce.SF_EVERYTHING = 64
ents.TriggerOnce.SF_ONLY_CLIENTS_NOT_IN_VEHICLES = 512
ents.TriggerOnce.SF_PHYSICS_DEBRIS = 1024
ents.TriggerOnce.SF_ONLY_NPCS_IN_VEHICLES = 2048
ents.TriggerOnce.SF_DISALLOW_BOTS = 4096

function ents.TriggerOnce:__init()
	BaseEntityComponent.__init(self)
end

function ents.TriggerOnce:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_PHYSICS)
	self:AddEntityComponent(ents.COMPONENT_IO)
	self:AddEntityComponent(ents.COMPONENT_TOUCH)

	self:BindEvent(Entity.EVENT_HANDLE_KEY_VALUE, "HandleKeyValue")
	self:BindEvent(ents.TouchComponent.EVENT_ON_TRIGGER_INITIALIZED, "InitializeTrigger")
	self:BindEvent(ents.TouchComponent.EVENT_CAN_TRIGGER, "CanTrigger")

	self.m_spawnFlags = 0
	self.m_filterName = ""
end

function ents.TriggerOnce:InitializeTrigger()
	local physComponent = self:GetEntity():GetComponent(ents.COMPONENT_PHYSICS)
	if physComponent == nil then
		return
	end

	local masks = phys.COLLISIONMASK_NONE
	if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_EVERYTHING) ~= 0 then
		masks = bit.bor(masks, phys.COLLISIONMASK_DYNAMIC, phys.COLLISIONMASK_GENERIC)
	end
	if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_CLIENTS) ~= 0 then
		masks = bit.bor(masks, phys.COLLISIONMASK_PLAYER)
	end
	if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_NPCS) ~= 0 then
		masks = bit.bor(masks, phys.COLLISIONMASK_NPC)
	end
	if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_PUSHABLES) ~= 0 then
		-- TODO
	end
	if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_PHYSICS_OBJECTS) ~= 0 then
		masks = bit.bor(masks, phys.COLLISIONMASK_DYNAMIC, phys.COLLISIONMASK_STATIC) -- TODO
	end
	if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_ONLY_PLAYER_ALLY_NPCS) ~= 0 then
		-- TODO
	end
	if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_ONLY_CLIENTS_IN_VEHICLES) ~= 0 then
		-- TODO
	end
	if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_ONLY_CLIENTS_NOT_IN_VEHICLES) ~= 0 then
		-- TODO
	end
	if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_PHYSICS_DEBRIS) ~= 0 then
		-- TODO
	end
	if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_ONLY_NPCS_IN_VEHICLES) ~= 0 then
		-- TODO
	end
	if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_DISALLOW_BOTS) ~= 0 then
		-- TODO
	end
	physComponent:SetCollisionFilterMask(masks)
	physComponent:SetCollisionFilterGroup(phys.COLLISIONMASK_TRIGGER)
	physComponent:SetCollisionCallbacksEnabled(true)
end

function ents.TriggerOnce:HandleKeyValue(key, val)
	if key == "spawnflags" then
		self.m_spawnFlags = tonumber(val)
	elseif key == "filtername" then
		self.m_filterName = val
	else
		return util.EVENT_REPLY_UNHANDLED
	end
	return util.EVENT_REPLY_HANDLED
end

function ents.TriggerOnce:CanTrigger(ent, physObj)
	if self.m_bUseFilter then
		if util.is_valid(self.m_filter) == false then
			return util.EVENT_REPLY_HANDLED, false
		end
		if self.m_filter:ShouldPass(ent) == false then
			return util.EVENT_REPLY_HANDLED, false
		end
		return util.EVENT_REPLY_HANDLED, true
	end
	return util.EVENT_REPLY_UNHANDLED
end

function ents.TriggerOnce:OnEntitySpawn()
	local ent = self:GetEntity()
	local touchComponent = ent:GetComponent(ents.COMPONENT_TOUCH)
	if touchComponent ~= nil then
		local triggerFlags = ents.TouchComponent.TRIGGER_FLAG_NONE
		if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_EVERYTHING) ~= 0 then
			triggerFlags = bit.bor(triggerFlags, ents.TouchComponent.TRIGGER_FLAG_EVERYTHING)
		end
		if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_NPCS) ~= 0 then
			triggerFlags = bit.bor(triggerFlags, ents.TouchComponent.TRIGGER_FLAG_BIT_NPCS)
		end
		if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_CLIENTS) ~= 0 then
			triggerFlags = bit.bor(triggerFlags, ents.TouchComponent.TRIGGER_FLAG_BIT_PLAYERS)
		end
		if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_PUSHABLES) ~= 0 then
			-- TODO
		end
		if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_PHYSICS_OBJECTS) ~= 0 then
			triggerFlags = bit.bor(triggerFlags, ents.TouchComponent.TRIGGER_FLAG_BIT_PHYSICS)
		end
		if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_ONLY_PLAYER_ALLY_NPCS) ~= 0 then
			-- TODO
		end
		if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_ONLY_CLIENTS_IN_VEHICLES) ~= 0 then
			-- TODO
		end
		if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_ONLY_CLIENTS_NOT_IN_VEHICLES) ~= 0 then
			-- TODO
		end
		if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_PHYSICS_DEBRIS) ~= 0 then
			-- TODO
		end
		if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_ONLY_NPCS_IN_VEHICLES) ~= 0 then
			-- TODO
		end
		if bit.band(self.m_spawnFlags, ents.TriggerOnce.SF_DISALLOW_BOTS) ~= 0 then
			-- TODO
		end
		print("TRIGGER FLAGS: ", triggerFlags)
		touchComponent:SetTriggerFlags(triggerFlags)
	end
	if SERVER == true then
		local physComponent = ent:GetPhysicsComponent()
		if physComponent ~= nil then
			physComponent:InitializePhysics(phys.TYPE_STATIC)
		end
	end
	if #self.m_filterName > 0 then
		self.m_bUseFilter = true
		local itFilter = ents.iterator({
			ents.IteratorFilterEntity(self.m_filterName),
			ents.IteratorFilterComponent(ents.COMPONENT_FILTER_NAME),
		})
		local entFilter = itFilter()
		if entFilter ~= nil then
			self.m_filter = entFilter:GetComponent(ents.COMPONENT_FILTER_NAME)
		else
			itFilter = ents.iterator({
				ents.IteratorFilterEntity(self.m_filterName),
				ents.IteratorFilterComponent(ents.COMPONENT_FILTER_CLASS),
			})
			entFilter = itFilter()
			if entFilter ~= nil then
				self.m_filter = entFilter:GetComponent(ents.COMPONENT_FILTER_CLASS)
			end
		end
	end
end
ents.register_component("trigger_once", "hl", ents.TriggerOnce)
