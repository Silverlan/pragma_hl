include("/ai/tasks/task_chase.lua")
include("tasks/task_attack.lua")

local Component = ents.MonsterZombieComponent
function Component:InitializeChaseSchedule()
	local schedChase = ai.create_schedule()
	local root = schedChase:GetRootTask() -- All schedules have a task at the very top. This task doesn't do anything by itself, but can be used to add child-tasks

	local taskChaseAndAttack = root:CreateTask(ai.TASK_DECORATOR,ai.BehaviorTask.TYPE_SELECTOR,ai.BehaviorTask.SELECTOR_TYPE_SEQUENTIAL) -- Empty task. This task will execute all of its children in sequential order, but only if all of them succeed.
	
	local taskAttack = taskChaseAndAttack:CreateTask(ai.TASK_DECORATOR,ai.BehaviorTask.TYPE_SEQUENCE,ai.BehaviorTask.SELECTOR_TYPE_SEQUENTIAL) -- Our main attack task. It will check whether an attack is actually possible, and perform the attack if it is. Otherwise the whole task will fail.
	taskAttack:CreateTask(ai.TaskZombieCanAttack)

	local taskAttackSound = taskAttack:CreateTask(ai.TASK_PLAY_SOUND)
	taskAttackSound:SetParameterString(0,"npc_zombie.attack")

	local taskAttackAnim = taskAttack:CreateTask(ai.TASK_PLAY_ACTIVITY) -- Pre-defined engine-task for playing animations.
	taskAttackAnim:SetParameterInt(0,Animation.ACT_MELEE_ATTACK1) -- Parameter 0 is the activity we want to play.
	taskAttackAnim:SetParameterBool(1,true) -- If parameter 1 is set to true, the NPC will continuously look at his primary target while the animation is playing.

	-- If 'taskAttack' failed, attempt chase.
	taskChaseAndAttack:CreateTask(ai.TASK_CHASE):SetParameterInt(ai.TaskChase.PARAM_MOVE_ACTIVITY,Animation.ACT_WALK)

	return schedChase
end

function Component:InitializeWanderSchedule()
	local wanderDistance = 200.0
	local wanderActivity = Animation.ACT_WALK

	local schedWander = ai.create_schedule()

	local root = schedWander:GetRootTask()
	local taskMove = root:CreateTask(ai.TASK_MOVE_RANDOM)
	taskMove:SetParameterFloat(0,wanderDistance)
	taskMove:SetParameterInt(1,wanderActivity)

	local taskWait = root:CreateTask(ai.TASK_WAIT)
	taskWait:SetParameterFloat(0,0.5)
	taskWait:SetParameterFloat(1,6.0)
	return schedWander
end

function Component:InitializeSchedules() -- This is not a hook, we'll have to call this functions ourselves later
	self.Schedules = {}

	self.Schedules.Chase = self:InitializeChaseSchedule() -- We can use this schedule to execute our task-chain
	self.Schedules.Wander = self:InitializeWanderSchedule()

	self:InitializeController()
end

function Component:SelectSchedule()
	local ent = self:GetEntity()
	local aiComponent = ent:GetComponent(ents.COMPONENT_AI)
	if(aiComponent == nil) then return end
	local npcState = aiComponent:GetNPCState()
	if(npcState ~= ai.NPC_STATE_COMBAT) then
		local t = time.cur_time()
		if(t >= self.m_tNextIdle) then
			if(math.random(1,2) == 2) then
				local sndEmitterComponent = ent:GetComponent(ents.COMPONENT_SOUND_EMITTER)
				if(sndEmitterComponent ~= nil) then
					sndEmitterComponent:EmitSound("npc_zombie.idle",sound.TYPE_NPC)
				end -- Emit idle sound from time to time
			end
			self.m_tNextIdle = t +math.randomf(3.0,6.0)
		end
		if(npcState == ai.NPC_STATE_ALERT) then
			aiComponent:StartSchedule(self.Schedules.Wander)
		end
		return
	end
	local t = aiComponent:GetPrimaryTarget()
	if(t == nil) then aiComponent:StopMoving() return end
	aiComponent:StartSchedule(self.Schedules.Chase)
end

function Component:OnPrimaryTargetChanged(targetMemory)
	local aiComponent = self:GetEntity():GetComponent(ents.COMPONENT_AI)
	if(aiComponent == nil) then return end
	if(targetMemory == nil) then -- We don't have any viable targets anymore
		aiComponent:SetNPCState(ai.NPC_STATE_IDLE)
	end
end

function Component:OnNPCStateChanged(oldState,newState)
	if(newState == ai.NPC_STATE_IDLE) then self.m_tNextIdle = time.cur_time() +math.randomf(3.0,6.0)
	elseif(newState == ai.NPC_STATE_COMBAT) then
		local ent = self:GetEntity()
		local aiComponent = ent:GetComponent(ents.COMPONENT_AI)
		if(aiComponent ~= nil) then
			aiComponent:CancelSchedule() -- Cancel whatever we were doing before so we can start chasing immediately
		end
		local sndEmitterComponent = ent:GetComponent(ents.COMPONENT_SOUND_EMITTER)
		if(sndEmitterComponent ~= nil) then
			sndEmitterComponent:EmitSound("npc_zombie.alert",sound.TYPE_NPC)
		end
	end
end

function Component:OnTargetAcquired(ent,dist,bFirst)
	local aiComponent = self:GetEntity():GetComponent(ents.COMPONENT_AI)
	if(bFirst == false or aiComponent == nil) then return end
	aiComponent:SetNPCState(ai.NPC_STATE_COMBAT)
end
