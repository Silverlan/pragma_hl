local MAX_ATTACK_DISTANCE = 50.0

util.register_class("ai.TaskZombieCanAttack",ai.BaseBehaviorTask)
function ai.TaskZombieCanAttack:__init(taskType,selectorType)
	ai.BaseBehaviorTask.__init(self,taskType,selectorType)
end

function ai.TaskZombieCanAttack:Start(schedule,npc)
	local ent = npc:GetEntity()
	local trComponent = ent:GetTransformComponent()
	local t = npc:GetPrimaryTarget()
	if(t == nil or t:IsInView() == false or trComponent == nil) then return ai.BehaviorTask.RESULT_FAILED end -- We can't attack if we don't have a target, or the target isn't visible
	local posDst = t:GetLastKnownPosition() +t:GetLastKnownVelocity() *0.6 -- Predicted position of target in 0.5 seconds
	local physComponent = ent:GetPhysicsComponent()
	local dist = trComponent:GetDistance(posDst)
	if(physComponent ~= nil) then
		dist = math.min(dist,physComponent:GetAABBDistance(t:GetEntity()))
	end
	local maxDist = MAX_ATTACK_DISTANCE *trComponent:GetAbsMaxAxisScale()
	return (dist <= maxDist) and ai.BehaviorTask.RESULT_SUCCEEDED or ai.BehaviorTask.RESULT_FAILED -- Only attack if the target is within maximum attack range
end
