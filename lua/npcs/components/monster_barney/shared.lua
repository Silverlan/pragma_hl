util.register_class("ents.MonsterBarney",BaseEntityComponent)

local cvHealth = console.register_variable("sk_barney_health","100",bit.bor(console.FLAG_BIT_ARCHIVE,console.FLAG_BIT_REPLICATED),"Specifies barney's default health.")

function ents.MonsterBarney:__init()
	BaseEntityComponent.__init(self)
end

function ents.MonsterBarney:Initialize()
	local ent = self:GetEntity()
	
	self:AddEntityComponent(ents.COMPONENT_AI,"InitializeAI")
	self:AddEntityComponent(ents.COMPONENT_CHARACTER,"InitializeCharacter")
	self:AddEntityComponent(ents.COMPONENT_HEALTH,"InitializeHealth")
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_PHYSICS,"InitializePhysics")
	self:AddEntityComponent(ents.COMPONENT_MODEL,"InitializeModel")
	self:AddEntityComponent(ents.COMPONENT_DAMAGEABLE)
	self:AddEntityComponent(ents.COMPONENT_SOUND_EMITTER)
	self:AddEntityComponent(ents.COMPONENT_ANIMATED,"InitializeAnimated")
	self:AddEntityComponent(ents.COMPONENT_USABLE)
	
	if(SERVER == true) then
		self:BindEvent(ents.AIComponent.EVENT_SELECT_SCHEDULE,"SelectSchedule")
    self:BindEvent(ents.AIComponent.EVENT_SELECT_CONTROLLER_SCHEDULE,"SelectControllerSchedule")
		self:BindEvent(ents.UsableComponent.EVENT_CAN_USE,"CanUse")
		self:BindEvent(ents.UsableComponent.EVENT_ON_USE,"OnUse")
	end
	self:BindEvent(Entity.EVENT_HANDLE_KEY_VALUE,"HandleKeyValue")
	self:BindEvent(ents.AnimatedComponent.EVENT_HANDLE_ANIMATION_EVENT,"HandleAnimationEvent")
	self:BindEvent(ents.CharacterComponent.EVENT_PLAY_FOOTSTEP_SOUND,"PlayFootStepSound")
	
	if(SERVER == true) then
		self:InitializeSchedules()
	end
	-- Sentences: Blend controller
end

function ents.MonsterBarney:InitializeCharacter(component)
	if(SERVER) then component:SetFaction("barney") end
	component:SetTurnSpeed(360.0)
end

function ents.MonsterBarney:HandleKeyValue(key,val)
	return util.EVENT_REPLY_UNHANDLED
end

function ents.MonsterBarney:InitializeAI(component)
	if(SERVER) then
		component:SetHearingStrength(0.6) -- Use 0.0 to disable the NPCs ability to hear, 1.0 means perfect hearing
		component:SetNPCState(ai.NPC_STATE_IDLE)
	end
	--component:SetMoveSpeed("walk",50.0) -- We don't use animation movement, so we have to specify a constant movement speed here
end

function ents.MonsterBarney:InitializeHealth(component)
	component:SetHealth(cvHealth:GetInt()) -- Grab the current value for the console command we've created earlier
end

function ents.MonsterBarney:OnEntitySpawn()
	local physComponent = self:GetEntity():GetComponent(ents.COMPONENT_PHYSICS)
	if(physComponent ~= nil) then
		physComponent:SetCollisionBounds(Vector(-16,0,-16),Vector(16,72,16)) -- Our collision bounds in units (Width, length = 16 and height = 72)
	end
	if(CLIENT or physComponent == nil) then return end
	physComponent:InitializePhysics(phys.TYPE_CAPSULECONTROLLER) -- Initialize our physics as a capsule. You can use phys.TYPE_BOXCONTROLLER to use a box-shape instead (Note: box-shapes are buggy at the time of this writing (2017-01-01) and should be avoided
end

function ents.MonsterBarney:InitializePhysics(component)
	if(CLIENT == true) then return end -- The following aren't needed clientside
	component:SetMoveType(ents.PhysicsComponent.MOVETYPE_WALK) -- Our NPC is ground-based
end
ents.COMPONENT_MONSTER_BARNEY = ents.register_component("monster_barney",ents.MonsterBarney,ents.EntityComponent.FREGISTER_BIT_NETWORKED)
