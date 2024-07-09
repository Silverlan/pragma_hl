util.register_class("ents.AmbientGeneric", BaseEntityComponent)

ents.AmbientGeneric.SF_PLAY_EVERYWHERE = 1
ents.AmbientGeneric.SF_START_SILENT = 16
ents.AmbientGeneric.SF_IS_NOT_LOOPED = 32

function ents.AmbientGeneric:__init()
	BaseEntityComponent.__init(self)
end

function ents.AmbientGeneric:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent(ents.COMPONENT_IO)
	self:AddEntityComponent(ents.COMPONENT_SOUND)

	self:BindEvent(Entity.EVENT_HANDLE_KEY_VALUE, "HandleKeyValue")
	self:BindEvent(ents.IOComponent.EVENT_HANDLE_INPUT, "HandleInput")
end

function ents.AmbientGeneric:HandleKeyValue(key, val)
	if key == "message" then
		local sndComponent = self:GetEntity():GetComponent(ents.COMPONENT_SOUND)
		if sndComponent ~= nil then
			sndComponent:SetSoundSource(val)
		end
	elseif key == "health" then
		local sndComponent = self:GetEntity():GetComponent(ents.COMPONENT_SOUND)
		if sndComponent ~= nil then
			sndComponent:SetGain(tonumber(val) / 10.0)
		end
	elseif key == "preset" then
		self.m_preset = val -- TODO
	elseif key == "volstart" then
		self.m_volStart = tonumber(val) -- TODO
	elseif key == "fadeinsecs" then
		self.m_fadeInSecs = tonumber(val) -- TODO
	elseif key == "fadeoutsecs" then
		self.m_fadeOutSecs = tonumber(val) -- TODO
	elseif key == "pitch" then
		local sndComponent = self:GetEntity():GetComponent(ents.COMPONENT_SOUND)
		if sndComponent ~= nil then
			sndComponent:SetPitch(tonumber(val) / 100.0)
		end
	elseif key == "pitchstart" then
		self.m_pitchStart = tonumber(val) -- TODO
	elseif key == "spinup" then
		self.m_spinUp = tonumber(val) -- TODO
	elseif key == "spindown" then
		self.m_spinDown = tonumber(val) -- TODO
	elseif key == "lfotype" then
		self.m_lfoType = tonumber(val) -- TODO
	elseif key == "lforate" then
		self.n_lfoRate = tonumber(val) -- TODO
	elseif key == "lfomodpitch" then
		self.m_lfoModPitch = tonumber(val) -- TODO
	elseif key == "lfomodvol" then
		self.m_lfoModVol = tonumber(val) -- TODO
	elseif key == "cspinup" then
		self.m_cSpinUp = tonumber(val) -- TODO
	elseif key == "radius" then
		local sndComponent = self:GetEntity():GetComponent(ents.COMPONENT_SOUND)
		if sndComponent ~= nil then
			sndComponent:SetMaxDistance(tonumber(val))
		end
	elseif key == "spawnflags" then
		val = tonumber(val)
		local sndComponent = self:GetEntity():GetComponent(ents.COMPONENT_SOUND)
		if sndComponent ~= nil then
			sndComponent:SetRelativeToListener(bit.band(val, ents.AmbientGeneric.SF_PLAY_EVERYWHERE) ~= 0)
			sndComponent:SetPlayOnSpawn(bit.band(val, ents.AmbientGeneric.SF_START_SILENT) == 0)
			sndComponent:SetLooping(bit.band(val, ents.AmbientGeneric.SF_IS_NOT_LOOPED) == 0)
		end
	elseif key == "sourceentityname" then
		self.m_sourceEntityName = val
	else
		return util.EVENT_REPLY_UNHANDLED
	end
	return util.EVENT_REPLY_HANDLED
end

function ents.AmbientGeneric:OnEntitySpawn()
	if self.m_sourceEntityName == nil then
		return
	end
	local ent = self:GetEntity()
	local attComponent = ent:AddComponent(ents.COMPONENT_ATTACHMENT)
	if attComponent ~= nil then
		local it = ents.iterator({ ents.IteratorFilterEntity(self.m_sourceEntityName) })
		local ent = it()
		if ent ~= nil then
			attComponent:AttachToEntity(ent)
		end
	end
end

function ents.AmbientGeneric:PlaySound()
	local sndComponent = self:GetEntity():GetComponent(ents.COMPONENT_SOUND)
	if sndComponent == nil then
		return
	end
	sndComponent:Play()
end

function ents.AmbientGeneric:StopSound()
	local sndComponent = self:GetEntity():GetComponent(ents.COMPONENT_SOUND)
	if sndComponent == nil then
		return
	end
	sndComponent:Stop()
end

function ents.AmbientGeneric:ToggleSound()
	local sndComponent = self:GetEntity():GetComponent(ents.COMPONENT_SOUND)
	if sndComponent == nil then
		return
	end
	if sndComponent:IsPlaying() then
		self:StopSound()
		return
	end
	self:PlaySound()
end

function ents.AmbientGeneric:HandleInput(input, activator, caller, data)
	if input == "pitch" then
		local sndComponent = self:GetEntity():GetComponent(ents.COMPONENT_SOUND)
		if sndComponent ~= nil then
			sndComponent:SetPitch(tonumber(data) / 100.0)
		end
	elseif input == "playsound" then
		self:PlaySound()
	elseif input == "stopsound" then
		self:StopSound()
	elseif input == "togglesound" then
		self:ToggleSound()
	elseif input == "volume" then
		local sndComponent = self:GetEntity():GetComponent(ents.COMPONENT_SOUND)
		if sndComponent ~= nil then
			sndComponent:SetGain(tonumber(data) / 10.0)
		end
	elseif input == "fadein" then
		-- TODO
	elseif input == "fadeout" then
		-- TODO
	else
		return util.EVENT_REPLY_UNHANDLED
	end
	return util.EVENT_REPLY_HANDLED
end
ents.COMPONENT_AMBIENT_GENERIC =
	ents.register_component("ambient_generic", ents.AmbientGeneric, ents.EntityComponent.FREGISTER_NONE)
