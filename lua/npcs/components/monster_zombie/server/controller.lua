include("/ai/tasks/controller/task_controller_move.lua")
include("/ai/tasks/controller/task_controller_check_input.lua")

local Component = ents.MonsterZombieComponent
function Component:InitializeController()
	local schedController = ai.create_schedule()
	local root = schedController:GetRootTask()
	local taskComposite = root:CreateTask(ai.TASK_DECORATOR,ai.BehaviorTask.TYPE_SELECTOR)

	-- Melee Attack
	local taskAttackComposite = taskComposite:CreateTask(ai.TASK_DECORATOR)
	taskAttackComposite:CreateTask(ai.TASK_CONTROLLER_CHECK_INPUT):SetParameterInt(ai.TaskControllerCheckInput.PARAM_INPUT_ACTION,input.ACTION_ATTACK)
	taskAttackComposite:CreateTask(ai.TASK_PLAY_ACTIVITY):SetParameterInt(0,Animation.ACT_MELEE_ATTACK1)

	-- Movement
	taskComposite:CreateTask(ai.TASK_CONTROLLER_MOVE)

	self.Schedules.Controller = schedController
end

function Component:SelectControllerSchedule()
	local ent = self:GetEntity()
	local aiComponent = ent:GetComponent(ents.COMPONENT_AI)
	if(aiComponent == nil) then return end
	aiComponent:StartSchedule(self.Schedules.Controller)
end
