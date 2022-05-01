util.register_class("ents.FuncTrackTrain",BaseEntityComponent)

--TODO: Loop moving sound? -> Tracktrain sound doesnt loop anymore
--TODO: Network func_door to remove clientside jitter

ents.FuncTrackTrain.SF_NO_PITCH = 1
ents.FuncTrackTrain.SF_NO_USER_CONTROL = 2
ents.FuncTrackTrain.SF_PASSABLE = 8
ents.FuncTrackTrain.SF_FIXED_ORIENTATION = 16
ents.FuncTrackTrain.SF_HL1_TRAIN = 128
ents.FuncTrackTrain.SF_USE_MAX_SPEED_FOR_PITCH_SHIFTING_MOVE_SOUND = 256
ents.FuncTrackTrain.SF_IS_UNBLOCKABLE_BY_PLAYER = 512

local defaultMemberFlags = bit.band(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,bit.bnot(bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_BIT_KEY_VALUE,ents.BaseEntityComponent.MEMBER_FLAG_BIT_INPUT,ents.BaseEntityComponent.MEMBER_FLAG_BIT_OUTPUT)))
local defaultMemberFlagsNw = bit.bor(defaultMemberFlags,ents.BaseEntityComponent.MEMBER_FLAG_BIT_NETWORKED)

ents.FuncTrackTrain:RegisterMember("ManualAccelerationSpeed",ents.MEMBER_TYPE_FLOAT,0.0,{},defaultMemberFlagsNw)
ents.FuncTrackTrain:RegisterMember("ManualDecelerationSpeed",ents.MEMBER_TYPE_FLOAT,0.0,{},defaultMemberFlagsNw)

ents.FuncTrackTrain:RegisterMember("MovePingSound",ents.MEMBER_TYPE_STRING,"",{},defaultMemberFlags)
ents.FuncTrackTrain:RegisterMember("MoveSoundMinPitch",ents.MEMBER_TYPE_FLOAT,0.0,{},defaultMemberFlags)
ents.FuncTrackTrain:RegisterMember("MoveSoundMaxPitch",ents.MEMBER_TYPE_FLOAT,0.0,{},defaultMemberFlags)
ents.FuncTrackTrain:RegisterMember("MoveSoundMinTime",ents.MEMBER_TYPE_FLOAT,0.0,{},defaultMemberFlags)
ents.FuncTrackTrain:RegisterMember("MoveSoundMaxTime",ents.MEMBER_TYPE_FLOAT,0.0,{},defaultMemberFlags)
ents.FuncTrackTrain:RegisterMember("FirstStopTarget",ents.MEMBER_TYPE_STRING,"",{},defaultMemberFlags)

ents.FuncTrackTrain:RegisterMember("WheelDistance",ents.MEMBER_TYPE_FLOAT,0.0,{},defaultMemberFlagsNw)
ents.FuncTrackTrain:RegisterMember("Bank",ents.MEMBER_TYPE_FLOAT,0.0,{},defaultMemberFlagsNw)

ents.FuncTrackTrain:RegisterMember("IOControlled",ents.MEMBER_TYPE_BOOLEAN,false,{},defaultMemberFlagsNw)
ents.FuncTrackTrain:RegisterMember("CrushDamage",ents.MEMBER_TYPE_INT32,0,{},defaultMemberFlags)
ents.FuncTrackTrain:RegisterMember("CurrentTarget",ents.MEMBER_TYPE_ENTITY,"",{},defaultMemberFlagsNw)
ents.FuncTrackTrain:RegisterMember("SpawnFlags",ents.MEMBER_TYPE_UINT32,0,{},defaultMemberFlags)

function ents.FuncTrackTrain:__init()
	BaseEntityComponent.__init(self)
end
function ents.FuncTrackTrain:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self:BindEvent(ents.PhysicsComponent.EVENT_ON_PRE_PHYSICS_SIMULATE,"OnPrePhysicsSimulate")
	
	self:AddEntityComponent(ents.COMPONENT_KINEMATIC_MOVER)
	self:AddEntityComponent(ents.COMPONENT_RENDER,"InitializeRender")
	
	self:BindEvent(Entity.EVENT_HANDLE_KEY_VALUE,"HandleKeyValue")
	self:BindEvent(ents.IOComponent.EVENT_HANDLE_INPUT,"HandleInput")
	
	self.m_netEvMoveTargetChanged = self:RegisterNetEvent("move_target")
end

function ents.FuncTrackTrain:GetHeightAboveTrack()
	local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
	if(kinematicMover == nil) then return 0.0 end
	return kinematicMover:GetHeightOffset()
end

function ents.FuncTrackTrain:SetHeightAboveTrack(height)
	local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
	if(kinematicMover == nil) then return end
	kinematicMover:SetHeightOffset(height)
end

function ents.FuncTrackTrain:OnPrePhysicsSimulate()
	local dt = time.delta_time()
	if(dt == 0.0) then return end
	local ent = self:GetEntity()
	local kinematicMover = ent:GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
	if(kinematicMover == nil) then return end
	local entTgt = self:UpdateNextMoveTarget()
	kinematicMover:SetMoveTarget(util.is_valid(entTgt) and entTgt:GetPos() or ent:GetPos())
end

function ents.FuncTrackTrain:InitializeRender(component)
	component:SetCastShadows(true)
end

function ents.FuncTrackTrain:HandleKeyValue(key,val)
	if(key == "manualspeedchanges") then
		self:SetIOControlled(toboolean(val))
	elseif(key == "manualaccelspeed") then
		self:SetManualAccelerationSpeed(tonumber(val))
	elseif(key == "manualdecelspeed") then
		self:SetManualDecelerationSpeed(tonumber(val))
	elseif(key == "spawnflags") then
		self:SetSpawnFlags(tonumber(val))
	elseif(key == "target") then
		self:SetFirstStopTarget(val)
	elseif(key == "startspeed") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:SetMaxSpeed(tonumber(val)) end
	elseif(key == "speed") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:SetStartSpeed(tonumber(val)) end
	elseif(key == "velocitytype") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:SetVelocityType(tonumber(val)) end
	elseif(key == "orientationtype") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:SetOrientationType(tonumber(val)) end
	elseif(key == "wheels") then
		self:SetWheelDistance(tonumber(val))
	elseif(key == "height") then
		self:SetHeightAboveTrack(tonumber(val))
	elseif(key == "bank") then
		self:SetBank(tonumber(val))
	elseif(key == "dmg") then
		self:SetCrushDamage(tonumber(val))
	elseif(key == "_minlight") then
		
	elseif(key == "movesound") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:SetMoveSoundName(val) end
	elseif(key == "movepingsound") then
		self:SetMovePingSound(val)
	elseif(key == "startsound") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:SetStartSound(val) end
	elseif(key == "stopsound") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:SetStopSound(val) end
	elseif(key == "volume") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:SetSoundVolume(tonumber(val) /10.0) end
	elseif(key == "movesoundminpitch") then
		self:SetMoveSoundMinPitch(tonumber(val) /100.0)
	elseif(key == "movesoundmaxpitch") then
		self:SetMoveSoundMaxPitch(tonumber(val) /100.0)
	elseif(key == "movesoundmintime") then
		self:SetMoveSoundMinTime(tonumber(val))
	elseif(key == "movesoundmaxtime") then
		self:SetMoveSoundMaxTime(tonumber(val))
	else return util.EVENT_REPLY_UNHANDLED end
	return util.EVENT_REPLY_HANDLED
end

function ents.FuncTrackTrain:UpdateNextMoveTarget()
	local entTgt = self:GetCurrentTarget()
	if(util.is_valid(entTgt) == false) then return end
	local ent = self:GetEntity()
	local pos = ent:GetPos()
	pos.y = pos.y -self:GetHeightAboveTrack()
	local posTgt = entTgt:GetPos()
	
	local pathTrackComponent = entTgt:GetComponent(ents.COMPONENT_PATH_TRACK)
	local prevPos = self.m_prevPos or pos
	local closestPointToTarget = geometry.closest_point_on_line_to_point(prevPos,pos,posTgt,true)
	
	local pathRadius = math.max((pathTrackComponent ~= nil) and pathTrackComponent:GetPathRadius() or 0.0,0.1)
	if(closestPointToTarget:Distance(posTgt) > pathRadius) then return entTgt end
	if(pathTrackComponent == nil) then
		self:Stop()
		return entTgt
	end
	pathTrackComponent:OnPass(ent)
	
	local nextTarget = pathTrackComponent:GetNextTarget()
	local moveSpeed = pathTrackComponent:GetNewTrainSpeed() or 0.0
	self:SetCurrentTarget(nextTarget)
	if(moveSpeed ~= 0.0) then
		local kinematicMoverComponent = ent:GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMoverComponent ~= nil) then kinematicMoverComponent:SetSpeed(moveSpeed) end
	end
	
	local ioComponent = ent:GetComponent(ents.COMPONENT_IO)
	if(ioComponent ~= nil) then ioComponent:FireOutput("OnNext",ent) end
	if(util.is_valid(self:GetCurrentTarget()) == false) then
		local kinematicMover = ent:GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:Stop() end
	end
	if(SERVER) then
		local kinematicMover = ent:GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		local p = net.Packet()
		p:WriteEntity(nextTarget)
		p:WriteFloat((kinematicMover ~= nil) and kinematicMover:GetSpeed() or 0.0)
		print("Y: ",net.PROTOCOL_SLOW_RELIABLE,self.m_netEvMoveTargetChanged)
		self:GetEntity():BroadcastNetEvent(net.PROTOCOL_SLOW_RELIABLE,self.m_netEvMoveTargetChanged,p)
	end
	return self:GetCurrentTarget()
end

function ents.FuncTrackTrain:GetTargetAngles(entTgt)
	local ent = self:GetEntity()
	entTgt = entTgt or self:GetCurrentTarget()
	local trComponent = ent:GetComponent(ents.COMPONENT_TRANSFORM)
	if(util.is_valid(entTgt) == false or trComponent == nil) then return EulerAngles() end
	local pos = ent:GetPos()
	pos.y = pos.y -self:GetHeightAboveTrack()
	local posTgt = entTgt:GetPos()
	
	local forward = posTgt -pos
	forward:Normalize()
	
	local rotSrc = trComponent:GetRotation()
	rotSrc:Normalize()
	local up = vector.UP
	local right = forward:Cross(up)
	local l = right:Length()
	if(l == 0.0) then
		up = vector.FORWARD
		right = forward:Cross(up)
		l = right:Length()
	end
	right = right /l
	local rotDst = Quaternion(forward,right,up)
	rotDst:Normalize()
	rotDst = rotDst *EulerAngles(0,-90,0):ToQuaternion()
	
	return rotDst:ToEulerAngles()
end

function ents.FuncTrackTrain:EmitSound(sound)
	local sndEmitterComponent = self:GetEntity():GetComponent(ents.COMPONENT_SOUND_EMITTER)
	if(sndEmitterComponent == nil) then return end
	sndEmitterComponent:EmitSound(sound,sound.TYPE_EFFECT)
end

function ents.FuncTrackTrain:GetMovePos(pos)
	pos = pos:Copy()
	pos.y = pos.y +self:GetHeightAboveTrack()
	return pos
end

function ents.FuncTrackTrain:TeleportToTarget()
	local entTgt = self:GetCurrentTarget()
	if(util.is_valid(entTgt) == false) then return end
	local ent = self:GetEntity()
	ent:SetPos(self:GetMovePos(entTgt:GetPos()))
	local pathTrackComponent = entTgt:GetComponent(ents.COMPONENT_PATH_TRACK)
	if(pathTrackComponent ~= nil) then pathTrackComponent:OnTeleport(ent) end
end

function ents.FuncTrackTrain:HandleInput(input,activator,caller,data)
	if(input == "setspeeddiraccel") then
		self.m_speedDirAccel = tonumber(data)
	elseif(input == "teleporttopathtrack") then
		self:TeleportToTarget()
	elseif(input == "setspeedforwardmodifier") then
		self:SetForwardSpeedModifier(tonumber(data))
	elseif(input == "setspeed") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:SetSpeed(tonumber(data) *kinematicMover:GetMaxSpeed()) end
	elseif(input == "setspeeddir") then
		data = tonumber(data)
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then
			kinematicMover:SetSpeed(data *kinematicMover:GetMaxSpeed())
			if(data < 0.0) then
				kinematicMover:Reverse()
			end
		end
	elseif(input == "setspeedreal") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:SetSpeed(tonumber(data)) end
	elseif(input == "stop") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:Stop() end
	elseif(input == "startforward") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:StartForward() end
	elseif(input == "startbackward") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:StartBackward() end
	elseif(input == "resume") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:Resume() end
	elseif(input == "reverse") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:Reverse() end
	elseif(input == "toggle") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:Toggle() end
	else return util.EVENT_REPLY_UNHANDLED end
	return util.EVENT_REPLY_HANDLED
end
ents.COMPONENT_FUNC_TRACKTRAIN = ents.register_component("func_tracktrain",ents.FuncTrackTrain,ents.EntityComponent.FREGISTER_BIT_NETWORKED)
