if SERVER then
	include("/ai/tasks/task_move_to_position.lua")
end
util.register_class("ents.ScriptedSequence", BaseEntityComponent)

ents.ScriptedSequence.MOVE_TO_POSITION_NO = 0
ents.ScriptedSequence.MOVE_TO_POSITION_WALK = 1
ents.ScriptedSequence.MOVE_TO_POSITION_RUN = 2
ents.ScriptedSequence.MOVE_TO_POSITION_CUSTOM_MOVEMENT = 3
ents.ScriptedSequence.MOVE_TO_POSITION_INSTANTANEOUS = 4
ents.ScriptedSequence.MOVE_TO_POSITION_TURN_TO_FACE = 5

ents.ScriptedSequence.SF_REPEATABLE = 4
ents.ScriptedSequence.SF_LEAVE_CORPSE = 8
ents.ScriptedSequence.SF_START_ON_SPAWN = 16
ents.ScriptedSequence.SF_NO_INTERRUPTIONS = 32
ents.ScriptedSequence.SF_OVERRIDE_AI = 64
ents.ScriptedSequence.SF_DONT_TELEPORT_NPC_ON_END = 128
ents.ScriptedSequence.SF_LOOP_IN_POST_IDLE = 256
ents.ScriptedSequence.SF_PRIORITY_SCRIPT = 512
ents.ScriptedSequence.SF_ALLOW_ACTOR_DEATH = 4096

ents.ScriptedSequence.SF_ON_PLAYER_DEATH_DO_NOTHING = 0
ents.ScriptedSequence.SF_ON_PLAYER_DEATH_CANCEL_SCRIPT_AND_RETURN_TO_AI = 1

function ents.ScriptedSequence:__init()
	BaseEntityComponent.__init(self)
end
function ents.ScriptedSequence:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent(ents.COMPONENT_IO)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)

	self:BindEvent(Entity.EVENT_HANDLE_KEY_VALUE, "HandleKeyValue")
	self:BindEvent(ents.IOComponent.EVENT_HANDLE_INPUT, "HandleInput")

	self.m_spawnFlags = 0
	self.m_onPlayerDeath = ents.ScriptedSequence.SF_ON_PLAYER_DEATH_DO_NOTHING
	self.m_targetNpcName = ""
	self.m_preActionIdleAnim = ""
	self.m_entryAnim = ""
	self.m_actionAnim = ""
	self.m_postActionIdleAnim = ""
	self.m_customMoveAnim = ""
	self.m_bLoopActionAnim = false
	self.m_bSynchPostIdles = false
	self.m_searchRadius = 0.0
	self.m_repeatRateMs = 0
	self.m_moveToType = ents.ScriptedSequence.MOVE_TO_POSITION_NO
	self.m_nextScript = ""
	self.m_bIgnoreGravity = false
	self.m_bDisableNPCCollisions = false

	self.m_entityData = {}
end

function ents.ScriptedSequence:OnRemove()
	for ent, data in pairs(self.m_entityData) do
		if util.is_valid(data.callback) then
			data.callback:Remove()
		end
	end
end

function ents.ScriptedSequence:BeginSequenceForTarget(entTgt, moveToPosition)
	if self.m_entityData[entTgt] ~= nil then
		if util.is_valid(self.m_entityData[entTgt].callback) then
			self.m_entityData[entTgt].callback:Remove()
		end
		self.m_entityData[entTgt] = nil
	end

	local aiComponent = entTgt:GetComponent(ents.COMPONENT_AI)
	if aiComponent == nil then
		return
	end
	local ent = self:GetEntity()
	local pos = ent:GetPos()
	local ang = ent:GetAngles()

	self.m_entityData[entTgt] = {}
	self.m_entityData[entTgt].callback = aiComponent:AddEventCallback(
		ents.AIComponent.EVENT_ON_SCHEDULE_COMPLETE,
		function(schedule, result)
			if self.m_entityData[entTgt] ~= nil and util.is_valid(self.m_entityData[entTgt].callback) then
				self.m_entityData[entTgt].callback:Remove()
			end
			self.m_entityData[entTgt] = nil
			if #self.m_nextScript > 0 then
				local nextScript = self.m_nextScript
				-- Note: BeginSequence mustn't be called from the EVENT_ON_SCHEDULE_COMPLETE event, since it can
				-- trigger another EVENT_ON_SCHEDULE_COMPLETE event itself, which can cause severe problems.
				-- Instead we'll delay the call slightly.
				time.create_simple_timer(0.0, function()
					for ent in
						ents.iterator({
							ents.IteratorFilterComponent(ents.COMPONENT_SCRIPTED_SEQUENCE),
							ents.IteratorFilterEntity(nextScript),
						})
					do
						local scriptedSeqComponent = ent:GetComponent(ents.COMPONENT_SCRIPTED_SEQUENCE)
						scriptedSeqComponent:BeginSequence()
					end
				end, time.TIMER_TYPE_CURTIME)
			end
		end
	)

	local sched = ai.create_schedule()
	local root = sched:GetRootTask()

	if self.m_moveToType == ents.ScriptedSequence.MOVE_TO_POSITION_INSTANTANEOUS then
		entTgt:SetPos(pos)
		entTgt:SetAngles(ang)
	elseif self.m_moveToType ~= ents.ScriptedSequence.MOVE_TO_POSITION_NO then
		local taskMoveToPos = root:CreateTask(ai.TASK_MOVE_TO_POSITION)
		taskMoveToPos:SetDebugName("Move To Position")
		taskMoveToPos:SetParameterVector(ai.TaskMoveToPosition.PARAM_MOVE_TARGET, pos)
		taskMoveToPos:SetParameterFloat(ai.TaskMoveToPosition.PARAM_MOVE_DISTANCE, 10.0)
		taskMoveToPos:SetParameterBool(ai.TaskMoveToPosition.PARAM_MOVE_ON_PATH, true)

		if self.m_moveToType == ents.ScriptedSequence.MOVE_TO_POSITION_WALK then
			taskMoveToPos:SetParameterInt(ai.TaskMoveToPosition.PARAM_MOVE_ACTIVITY, game.Model.Animation.ACT_WALK)
		elseif self.m_moveToType == ents.ScriptedSequence.MOVE_TO_POSITION_RUN then
			taskMoveToPos:SetParameterInt(ai.TaskMoveToPosition.PARAM_MOVE_ACTIVITY, game.Model.Animation.ACT_RUN)
		elseif
			self.m_moveToType == ents.ScriptedSequence.MOVE_TO_POSITION_CUSTOM_MOVEMENT
			and #self.m_customMoveAnim > 0
		then
			-- TODO: Custom movement animation not yet supported (only activities!)
			-- taskMoveToPos:SetParameterString(ai.TaskMoveToPosition.PARAM_MOVE_ACTIVITY,	self.m_customMoveAnim)
		end
		--if(self.m_moveToType == ents.ScriptedSequence.MOVE_TO_POSITION_TURN_TO_FACE) then
		local taskTurn = root:CreateTask(ai.TASK_TURN_TO_TARGET)
		taskTurn:SetDebugName("Turn To Face")
		taskTurn:SetParameterEntity(0, ent)
		taskTurn:SetParameterFloat(1, 0.05)
		--end
	end

	if moveToPosition == true then
		if #self.m_preActionIdleAnim > 0 then
			local taskDecoRepeat = root:CreateTask(ai.TASK_DECORATOR)
			taskDecoRepeat:SetParameterInt(0, ai.BehaviorTask.DECORATOR_TYPE_REPEAT)
			taskDecoRepeat:SetParameterInt(1, -1) -- Repeat forever

			local taskPlayAnim = taskDecoRepeat:CreateTask(ai.TASK_PLAY_ANIMATION)
			taskPlayAnim:SetDebugName("Play Scripted Pre-Action Idle Animation")
			taskPlayAnim:SetParameterString(0, self.m_preActionIdleAnim)
		end
		aiComponent:StartSchedule(sched)
		return
	end
	if #self.m_entryAnim > 0 then
		local taskPlayAnim = root:CreateTask(ai.TASK_PLAY_ANIMATION)
		taskPlayAnim:SetDebugName("Play Scripted Entry Animation")
		taskPlayAnim:SetParameterString(0, self.m_entryAnim)
	end
	if #self.m_actionAnim > 0 then
		local parent = root
		if self.m_bLoopActionAnim == true then
			local taskDecoRepeat = root:CreateTask(ai.TASK_DECORATOR)
			taskDecoRepeat:SetParameterInt(0, ai.BehaviorTask.DECORATOR_TYPE_REPEAT)
			taskDecoRepeat:SetParameterInt(1, -1) -- Repeat forever
			parent = taskDecoRepeat
		end
		local taskPlayAnim = parent:CreateTask(ai.TASK_PLAY_ANIMATION)
		taskPlayAnim:SetDebugName("Play Scripted Action Animation")
		taskPlayAnim:SetParameterString(0, self.m_actionAnim)
	end
	if #self.m_postActionIdleAnim > 0 then
		local taskDecoRepeat = root:CreateTask(ai.TASK_DECORATOR)
		taskDecoRepeat:SetParameterInt(0, ai.BehaviorTask.DECORATOR_TYPE_REPEAT)
		taskDecoRepeat:SetParameterInt(1, -1) -- Repeat forever

		local taskPlayAnim = taskDecoRepeat:CreateTask(ai.TASK_PLAY_ANIMATION)
		taskPlayAnim:SetDebugName("Play Scripted Post-Action Idle Animation")
		taskPlayAnim:SetParameterString(0, self.m_postActionIdleAnim)
	end
	aiComponent:StartSchedule(sched)
end

function ents.ScriptedSequence:BeginSequence()
	local ent = self:GetEntity()
	local ioComponent = ent:GetComponent(ents.COMPONENT_IO)
	if ioComponent ~= nil then
		ioComponent:FireOutput("OnBeginSequence", ent)
	end

	local targets = self:FindTargets()
	for _, entTgt in ipairs(targets) do
		self:BeginSequenceForTarget(entTgt, false)
	end
end

function ents.ScriptedSequence:MoveToPosition()
	local targets = self:FindTargets()
	for _, entTgt in ipairs(targets) do
		self:BeginSequenceForTarget(entTgt, true)
	end
end

function ents.ScriptedSequence:CancelSequence()
	local ent = self:GetEntity()
	local ioComponent = ent:GetComponent(ents.COMPONENT_IO)
	if ioComponent ~= nil then
		ioComponent:FireOutput("OnCancelSequence", ent)
	end
	for ent, data in pairs(self.m_entityData) do
		if ent:IsValid() then
			local aiComponent = ent:GetComponent(ents.COMPONENT_AI)
			if aiComponent ~= nil then
				aiComponent:CancelSchedule() -- TODO: Keep playing action animation if it has already started?
			end
		end
	end
	self.m_entityData = {}
end

function ents.ScriptedSequence:HandleInput(input, activator, caller, data)
	if input == "beginsequence" then
		self:BeginSequence()
	elseif input == "movetoposition" then
		self:MoveToPosition()
	elseif input == "cancelsequence" then
		self:CancelSequence()
	else
		return util.EVENT_REPLY_UNHANDLED
	end
	return util.EVENT_REPLY_HANDLED
end

function ents.ScriptedSequence:FindTargets()
	local r = {}
	local ent = self:GetEntity()
	local filters = {
		ents.IteratorFilterEntity(self.m_targetNpcName),
		ents.IteratorFilterComponent(ents.COMPONENT_AI),
	}
	if self.m_searchRadius ~= 0.0 then
		table.insert(filters, ents.IteratorFilterSphere(ent:GetPos(), self.m_searchRadius))
	end
	for entTgt in ents.iterator(filters) do
		table.insert(r, entTgt)
		break -- Always only use one target?
	end
	return r
end

function ents.ScriptedSequence:OnEntitySpawn()
	if bit.band(self.m_spawnFlags, ents.ScriptedSequence.SF_START_ON_SPAWN) ~= 0 then
		self:MoveToPosition()
	end
end

function ents.ScriptedSequence:HandleKeyValue(key, val)
	if key == "m_iszentity" then
		self.m_targetNpcName = val
	elseif key == "m_iszidle" then
		self.m_preActionIdleAnim = val
	elseif key == "m_iszentry" then
		self.m_entryAnim = val
	elseif key == "m_iszplay" then
		self.m_actionAnim = val
	elseif key == "m_iszpostidle" then
		self.m_postActionIdleAnim = val
	elseif key == "m_iszcustommove" then
		self.m_customMoveAnim = val
	elseif key == "m_bloopactionsequence" then
		self.m_bLoopActionAnim = toboolean(val)
	elseif key == "m_bsynchpostidles" then
		self.m_bSynchPostIdles = toboolean(val)
	elseif key == "m_flradius" then
		self.m_searchRadius = tonumber(val)
	elseif key == "m_flrepeat" then
		self.m_repeatRateMs = tonumber(val)
	elseif key == "m_fmoveto" then
		self.m_moveToType = tonumber(val)
	elseif key == "m_isznextscript" then
		self.m_nextScript = val
	elseif key == "m_bignoregravity" then
		self.m_bIgnoreGravity = toboolean(val)
	elseif key == "m_bdisablenpccollisions" then
		self.m_bDisableNPCCollisions = toboolean(val)
	elseif key == "spawnflags" then
		self.m_spawnFlags = tonumber(val)
	elseif key == "onplayerdeath" then
		self.m_onPlayerDeath = tonumber(val)
	else
		return util.EVENT_REPLY_UNHANDLED
	end
	return util.EVENT_REPLY_HANDLED
end
ents.register_component("scripted_sequence", ents.ScriptedSequence, "ai", ents.EntityComponent.FREGISTER_BIT_NETWORKED)
