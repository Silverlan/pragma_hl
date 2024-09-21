util.register_class("ents.PathTrack", BaseEntityComponent)

function ents.PathTrack:__init()
	BaseEntityComponent.__init(self)
end
function ents.PathTrack:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent(ents.COMPONENT_IO)
	self:AddEntityComponent(ents.COMPONENT_TOGGLE)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)

	self:BindEvent(Entity.EVENT_HANDLE_KEY_VALUE, "HandleKeyValue")
	self:BindEvent(ents.IOComponent.EVENT_HANDLE_INPUT, "HandleInput")

	self.m_speed = 0.0
	self.m_radius = 0.0
	self.m_altPathEnabled = false
end

function ents.PathTrack:OnPass(ent)
	local ioComponent = self:GetEntity():GetComponent(ents.COMPONENT_IO)
	if ioComponent == nil or util.is_valid(ent) == false then
		return
	end
	ioComponent:FireOutput("OnPass", ent)
end

function ents.PathTrack:OnTeleport(ent)
	local ioComponent = self:GetEntity():GetComponent(ents.COMPONENT_IO)
	if ioComponent == nil or util.is_valid(ent) == false then
		return
	end
	ioComponent:FireOutput("OnTeleport", ent)
end

function ents.PathTrack:HandleInput(input, activator, caller, data)
	if input == "togglealternatepath" then
		self.m_altPathEnabled = not self.m_altPathEnabled
	elseif input == "enablealternatepath" then
		self.m_altPathEnabled = true
	elseif input == "disablealternatepath" then
		self.m_altPathEnabled = false
	elseif input == "togglepath" then
		local toggleComponent = self:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
		if toggleComponent ~= nil then
			toggleComponent:Toggle()
		end
	elseif input == "enablepath" then
		local toggleComponent = self:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
		if toggleComponent ~= nil then
			toggleComponent:SetTurnedOn(true)
		end
	elseif input == "disablepath" then
		local toggleComponent = self:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
		if toggleComponent ~= nil then
			toggleComponent:SetTurnedOn(false)
		end
	else
		return util.EVENT_REPLY_UNHANDLED
	end
	return util.EVENT_REPLY_HANDLED
end

function ents.PathTrack:GetNextTarget()
	if self.m_altPathEnabled then
		return self.m_entAltTarget
	end
	return self.m_entTarget
end

function ents.PathTrack:GetNewTrainSpeed()
	return self.m_speed
end

function ents.PathTrack:GetPathRadius()
	return self.m_radius
end

function ents.PathTrack:OnEntitySpawn()
	local it
	if self.m_target ~= nil then
		it = ents.iterator(
			bit.bor(ents.ITERATOR_FILTER_DEFAULT, ents.ITERATOR_FILTER_BIT_PENDING),
			{ ents.IteratorFilterEntity(self.m_target) }
		)
		self.m_entTarget = it()
	end
	if self.m_altTarget ~= nil then
		it = ents.iterator(
			bit.bor(ents.ITERATOR_FILTER_DEFAULT, ents.ITERATOR_FILTER_BIT_PENDING),
			{ ents.IteratorFilterEntity(self.m_altTarget) }
		)
		self.m_entAltTarget = it()
	end
end

function ents.PathTrack:HandleKeyValue(key, val)
	if key == "spawnflags" then
		self.m_spawnFlags = tonumber(val)
	elseif key == "target" then
		self.m_target = val
	elseif key == "altpath" then
		self.m_altTarget = val
	elseif key == "speed" then
		self.m_speed = tonumber(val)
	elseif key == "radius" then
		self.m_radius = tonumber(val)
	elseif key == "orientationtype" then
		self.m_orientationType = tonumber(val)
	else
		return util.EVENT_REPLY_UNHANDLED
	end
	return util.EVENT_REPLY_HANDLED
end
ents.register_component("path_track", ents.PathTrack, "hl", ents.EntityComponent.FREGISTER_BIT_NETWORKED)
