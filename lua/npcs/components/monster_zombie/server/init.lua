include("../shared.lua")
include("attacks.lua")
include("behavior.lua")
include("controller.lua")

local Component = ents.MonsterZombieComponent
function Component:Flinch(hitGroup)
	local act = Animation.ACT_SMALL_FLINCH
	if(hitGroup == game.HITGROUP_LEFT_ARM) then act = Animation.ACT_FLINCH_LEFT_ARM
	elseif(hitGroup == game.HITGROUP_LEFT_LEG) then act = Animation.ACT_FLINCH_LEFT_LEG
	elseif(hitGroup == game.HITGROUP_RIGHT_ARM) then act = Animation.ACT_FLINCH_RIGHT_ARM
	elseif(hitGroup == game.HITGROUP_RIGHT_LEG) then act = Animation.ACT_FLINCH_RIGHT_LEG end
	self:PlayActivity(act)
end

function Component:InitializeModel(component)
	component:SetModel("zombie.wmd") -- The model our NPC uses
end

function Component:InitializeCharacter(component)
	component:SetFaction("zombie")
end

function Component:DropBody()
	local ent = self:GetEntity()
	local sndEmitterComponent = ent:GetComponent(ents.COMPONENT_SOUND_EMITTER)
	if(sndEmitterComponent ~= nil) then
		sndEmitterComponent:EmitSound("npc_zombie.bodydrop",sound.TYPE_EFFECT)
	end
	local charComponent = ent:GetCharacterComponent()
	if(charComponent ~= nil) then
		self:Ragdolize()
	end
end

function Component:OnTakenDamage(dmgInfo,oldHealth,newHealth)
	local t = time.cur_time()
	if(self.m_tLastFlinch == nil or time.cur_time() -self.m_tLastFlinch > 3.0) then
		self.m_tLastFlinch = t
		local bFlinch = (self:HasPrimaryTarget() == false or (math.random(0,2) == 2)) and true or false
		if(bFlinch == true) then
			self:Flinch(dmgInfo:GetHitGroup())
		end
	end
	if(self:GetNPCState() == ai.NPC_STATE_IDLE) then self:SetNPCState(ai.NPC_STATE_ALERT) end
end

function Component:OnAnimationStart(anim,activity)
	local ent = self:GetEntity()
	local charComponent = ent:GetCharacterComponent()
	local physComponent = ent:GetPhysicsComponent()
	if(
		charComponent == nil or
		self:IsAlive() == true or activity == Animation.ACT_DIE_GUTSHOT or activity == Animation.ACT_DIE_HEADSHOT or
		activity == Animation.ACT_DIESIMPLE or activity == Animation.ACT_DIEFORWARD or activity == Animation.ACT_DIEBACKWARD or
		(physComponent ~= nil and physComponent:GetPhysicsType() == phys.TYPE_DYNAMIC)
	) then return end
	charComponent:Ragdolize() -- Death animation was interrupted, force ragdoll mode
end

function Component:OnDeath(dmgInfo)
	local ent = self:GetEntity()
	local sndEmitterComponent = ent:GetComponent(ents.COMPONENT_SOUND_EMITTER)
	if(sndEmitterComponent ~= nil) then
		sndEmitterComponent:EmitSound("npc_zombie.pain",sound.TYPE_NPC)
	end
	local act
	if(dmgInfo ~= nil) then -- dmgInfo can be nil if the NPC wasn't killed by damage
		local hitGroup = dmgInfo:GetHitGroup()
		if(hitGroup == game.HITGROUP_HEAD) then act = Animation.ACT_DIE_HEADSHOT -- If we were hit in the head, play a unique death animation
		elseif(hitGroup == game.HITGROUP_CHEST or hitGroup == game.HITGROUP_STOMACH) then act = Animation.ACT_DIE_GUTSHOT end
	end
	if(act == nil) then act = table.random({Animation.ACT_DIESIMPLE,Animation.ACT_DIEFORWARD,Animation.ACT_DIEBACKWARD}) end
	self:PlayActivity(act) -- Play our death animation
	return true -- Overwrite default behavior (To prevent the immediate transformation into a ragdoll)
end
