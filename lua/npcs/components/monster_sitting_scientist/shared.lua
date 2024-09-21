util.register_class("ents.MonsterSittingScientist", BaseEntityComponent)

function ents.MonsterSittingScientist:__init()
	BaseEntityComponent.__init(self)
end

function ents.MonsterSittingScientist:Initialize()
	local ent = self:GetEntity()

	self:AddEntityComponent(ents.COMPONENT_MONSTER_SCIENTIST)
	self:GetEntity():RemoveComponent(ents.COMPONENT_AI)
	self:GetEntity():RemoveComponent(ents.COMPONENT_PHYSICS)

	self:BindEvent(ents.PhysicsComponent.EVENT_ON_PHYSICS_INITIALIZED, "OnPhysicsInitialized")
end

function ents.MonsterSittingScientist:OnPhysicsInitialized()
	local physComponent = self:GetEntity():GetComponent(ents.COMPONENT_PHYSICS)
	if physComponent ~= nil then
		physComponent:SetCollisionFilterGroup(phys.COLLISIONMASK_NO_COLLISION) -- TODO: Only collision with players
	end
end

function ents.MonsterSittingScientist:OnEntitySpawn()
	local ent = self:GetEntity()
	local animComponent = ent:GetComponent(ents.COMPONENT_ANIMATED)
	if animComponent ~= nil then
		animComponent:PlayAnimation("sitting2")
	end

	local gravComponent = ent:GetComponent(ents.COMPONENT_GRAVITY)
	if gravComponent ~= nil then
		gravComponent:SetGravityScale(0.0) -- We have no collision with the world, so we have to make sure we're not just falling through the ground
	end
end
ents.register_component(
	"monster_sitting_scientist",
	ents.MonsterSittingScientist,
	"hl",
	ents.EntityComponent.FREGISTER_BIT_NETWORKED
)
