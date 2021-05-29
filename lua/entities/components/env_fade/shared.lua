util.register_class("ents.EnvFade",BaseEntityComponent)

ents.EnvFade.SF_FADE_FROM = 1
ents.EnvFade.SF_MODULATE = 2
ents.EnvFade.SF_STAY_OUT = 8

function ents.EnvFade:__init()
	BaseEntityComponent.__init(self)
end
function ents.EnvFade:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent(ents.COMPONENT_IO)
	self:AddEntityComponent(ents.COMPONENT_COLOR)
	
	self:BindEvent(Entity.EVENT_HANDLE_KEY_VALUE,"HandleKeyValue")
	self:BindEvent(ents.IOComponent.EVENT_HANDLE_INPUT,"HandleInput")
	
	self.m_fadeAlpha = 0
	
	self.m_netEvFade = self:RegisterNetEvent("fade")
	
	if(CLIENT) then
		self:BindEvent(ents.LogicComponent.EVENT_ON_TICK,"OnTick")
		
		local p = gui.create("WIRect")
		p:SetAutoAlignToParent(true)
		p:SetZPos(10000)
		p:SetVisible(false)
		self.m_fadePanel = p
	end
end

function ents.EnvFade:HandleInput(input,activator,caller,data)
	debug.print("Input: ",input)
	if(input == "fade") then
		self:StartFade()
	else return util.EVENT_REPLY_UNHANDLED end
	return util.EVENT_REPLY_HANDLED
end

function ents.EnvFade:StartFade()
	debug.print("StartFade")
	local ent = self:GetEntity()
	local ioComponent = ent:GetComponent(ents.COMPONENT_IO)
	if(ioComponent ~= nil) then ioComponent:FireOutput("OnBeginFade",ent) end
	if(SERVER) then
		ent:BroadcastNetEvent(net.PROTOCOL_SLOW_RELIABLE,self.m_netEvFade)
		return
	end
	if(util.is_valid(self.m_fadePanel)) then self.m_fadePanel:SetVisible(true) end
	self.m_tFadeStart = time.real_time()
	self:UpdateFadeColor()
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end

function ents.EnvFade:OnEntitySpawn()
	local it
	if(self.m_target ~= nil) then
		it = ents.iterator(bit.bor(ents.ITERATOR_FILTER_DEFAULT,ents.ITERATOR_FILTER_BIT_PENDING),{ents.IteratorFilterEntity(self.m_target)})
		self.m_entTarget = it()
	end
	if(self.m_altTarget ~= nil) then
		it = ents.iterator(bit.bor(ents.ITERATOR_FILTER_DEFAULT,ents.ITERATOR_FILTER_BIT_PENDING),{ents.IteratorFilterEntity(self.m_altTarget)})
		self.m_entAltTarget = it()
	end
end

function ents.EnvFade:HandleKeyValue(key,val)
	if(key == "spawnflags") then
		self.m_spawnFlags = tonumber(val)
	elseif(key == "duration") then
		self.m_duration = tonumber(val)
	elseif(key == "holdtime") then
		self.m_holdTime = tonumber(val)
	elseif(key == "renderamt") then
		self.m_fadeAlpha = tonumber(val)
	elseif(key == "rendercolor") then
		local colComponent = self:GetEntity():GetComponent(ents.COMPONENT_COLOR)
		if(colComponent ~= nil) then
			local col = util.Color(val)
			col.a = colComponent:GetColor().a
			colComponent:SetColor(col)
		end
	else return util.EVENT_REPLY_UNHANDLED end
	return util.EVENT_REPLY_HANDLED
end
ents.COMPONENT_ENV_FADE = ents.register_component("env_fade",ents.EnvFade,ents.EntityComponent.FREGISTER_BIT_NETWORKED)
