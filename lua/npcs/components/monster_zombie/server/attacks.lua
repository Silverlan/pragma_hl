
local MAX_MELEE_DAMAGE_RANGE = 80.0
local MELEE_DAMAGE_CONE_ANGLE = 22.0
local MELEE_DAMAGE_PUSH_FORCE = 500.0

local cvMeleeDamage = console.register_variable("sk_zombie_melee_damage","24",console.FLAG_ARCHIVE,"Specifies the zombie's default melee damage.")

local Component = ents.MonsterZombieComponent
function Component:DealMeleeDamage(viewPunch)
	local entSelf = self:GetEntity()
	local trComponent = entSelf:GetTransformComponent()
	if(trComponent == nil) then return end
	local pos = entSelf:GetCenter()
	local dir = trComponent:GetForward()

	local scale = trComponent:GetAbsMaxAxisScale()
	local dist = MAX_MELEE_DAMAGE_RANGE *scale
	local dmgVal = cvMeleeDamage:GetInt()
	local dmgValue = dmgVal *scale

	local dmg = game.DamageInfo()
	dmg:AddDamageType(game.DAMAGETYPE_BASH)
	dmg:SetDamage(dmgVal)
	dmg:SetAttacker(entSelf)
	dmg:SetInflictor(entSelf)
	dmg:SetSource(pos)
	dmg:SetForce(dir *MELEE_DAMAGE_PUSH_FORCE)
	local bHasHit = false
  
  local splashDmgInfo = util.SplashDamageInfo()
  splashDmgInfo.damageInfo = dmg
  splashDmgInfo.origin = pos
  splashDmgInfo.radius = dist
  splashDmgInfo:SetCone(dir,MELEE_DAMAGE_CONE_ANGLE)
  splashDmgInfo:SetCallback(function(ent,dmgInfo)
		local aiComponent = entSelf:GetComponent(ents.COMPONENT_AI)
		if(aiComponent ~= nil) then
			local disp = aiComponent:GetDisposition(ent)
			if((ent:IsNPC() or ent:IsPlayer()) and (disp == ai.DISPOSITION_LIKE or disp == ai.DISPOSITION_NEUTRAL)) then return false end -- Don't apply damage to allied targets
		end
		if(ent:IsPlayer() == true) then
			ent:GetPlayerComponent():ApplyViewRotationOffset(viewPunch)
		end
		bHasHit = true
		return true
	end)
  util.splash_damage(splashDmgInfo)
	local sndEmitterComponent = entSelf:GetComponent(ents.COMPONENT_SOUND_EMITTER)
	if(sndEmitterComponent ~= nil) then
		if(bHasHit == true) then sndEmitterComponent:EmitSound("npc_zombie.attack_hit",sound.TYPE_EFFECT)
		else sndEmitterComponent:EmitSound("npc_zombie.attack_miss",sound.TYPE_EFFECT) end
	end
end
