include("../shared.lua")
include("behavior.lua")
include("controller.lua")

function ents.MonsterGeneric:InitializePhysics(component)
	component:SetMoveType(ents.PhysicsComponent.MOVETYPE_WALK) -- Our NPC is ground-based
end
