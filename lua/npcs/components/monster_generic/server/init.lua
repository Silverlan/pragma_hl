-- SPDX-FileCopyrightText: (c) 2021 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("../shared.lua")
include("behavior.lua")
include("controller.lua")

function ents.MonsterGeneric:InitializePhysics(component)
	component:SetMoveType(ents.PhysicsComponent.MOVETYPE_WALK) -- Our NPC is ground-based
end
