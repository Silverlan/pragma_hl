util.register_class("ents.MonsterGeneric", BaseEntityComponent)

function ents.MonsterGeneric:__init()
	BaseEntityComponent.__init(self)
end

function ents.MonsterGeneric:Initialize()
	local ent = self:GetEntity()

	self:AddEntityComponent(ents.COMPONENT_CHARACTER)
	self:AddEntityComponent(ents.COMPONENT_AI, "InitializeAI")
	self:AddEntityComponent(ents.COMPONENT_HEALTH)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_PHYSICS, "InitializePhysics")
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_DAMAGEABLE)
	self:AddEntityComponent(ents.COMPONENT_SOUND_EMITTER)
	self:AddEntityComponent(ents.COMPONENT_ANIMATED, "InitializeAnimated")

	if SERVER == true then
		self:BindEvent(ents.AIComponent.EVENT_SELECT_SCHEDULE, "SelectSchedule")
		self:BindEvent(ents.AIComponent.EVENT_SELECT_CONTROLLER_SCHEDULE, "SelectControllerSchedule")
	end
	self:BindEvent(Entity.EVENT_HANDLE_KEY_VALUE, "HandleKeyValue")

	if SERVER == true then
		self:InitializeSchedules()
	end
end

function ents.MonsterGeneric:HandleKeyValue(key, val)
	if key == "model" then
		local mdlComponent = self:GetEntity():GetComponent(ents.COMPONENT_MODEL)
		if mdlComponent ~= nil then
			mdlComponent:SetModel(val)
		end
	elseif key == "body" then
	else
		return util.EVENT_REPLY_UNHANDLED
	end
	return util.EVENT_REPLY_HANDLED
end

function ents.MonsterGeneric:InitializeAI(component)
	if SERVER then
		component:SetNPCState(ai.NPC_STATE_IDLE)
	end
end

function ents.MonsterGeneric:OnEntitySpawn()
	local physComponent = self:GetEntity():GetComponent(ents.COMPONENT_PHYSICS)
	if physComponent ~= nil then
		physComponent:SetCollisionBounds(Vector(-16, 0, -16), Vector(16, 72, 16)) -- Our collision bounds in units (Width, length = 16 and height = 72)
	end
	if CLIENT or physComponent == nil then
		return
	end
	physComponent:InitializePhysics(phys.TYPE_CAPSULECONTROLLER)
end
ents.register_component("monster_generic", ents.MonsterGeneric, "hl", ents.EntityComponent.FREGISTER_BIT_NETWORKED)
