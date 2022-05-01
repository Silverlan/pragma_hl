util.register_class("ents.KinematicMover",BaseEntityComponent)

ents.KinematicMover.MOVE_STATE_IDLE = 0
ents.KinematicMover.MOVE_STATE_FORWARD = 1
ents.KinematicMover.MOVE_STATE_BACKWARD = 2

ents.KinematicMover.ORIENTATION_TYPE_NEVER = 0
ents.KinematicMover.ORIENTATION_TYPE_NEAR_PATH_TRACKS = 1
ents.KinematicMover.ORIENTATION_TYPE_LINEAR_BLEND = 2
ents.KinematicMover.ORIENTATION_TYPE_EASE_IN_EASE_OUT = 3

ents.KinematicMover.VELOCITY_TYPE_INSTANTANEOUSLY = 0
ents.KinematicMover.VELOCITY_TYPE_LINEAR_BLEND = 1
ents.KinematicMover.VELOCITY_TYPE_EASE_IN_EASE_OUT = 2

local defaultMemberFlags = bit.band(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,bit.bnot(bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_BIT_KEY_VALUE,ents.BaseEntityComponent.MEMBER_FLAG_BIT_INPUT,ents.BaseEntityComponent.MEMBER_FLAG_BIT_OUTPUT)))
local defaultMemberFlagsNw = bit.bor(defaultMemberFlags,ents.BaseEntityComponent.MEMBER_FLAG_BIT_NETWORKED)

ents.KinematicMover:RegisterMember("MoveRelative",ents.MEMBER_TYPE_BOOLEAN,false,{},defaultMemberFlagsNw)
ents.KinematicMover:RegisterMember("MoveTarget",ents.MEMBER_TYPE_VECTOR3,Vector(),{},defaultMemberFlagsNw)
ents.KinematicMover:RegisterMember("MoveState",ents.MEMBER_TYPE_UINT8,ents.KinematicMover.MOVE_STATE_IDLE,{},defaultMemberFlagsNw)
ents.KinematicMover:RegisterMember("MaxSpeed",ents.MEMBER_TYPE_FLOAT,math.huge,{},defaultMemberFlagsNw)
ents.KinematicMover:RegisterMember("StartSpeed",ents.MEMBER_TYPE_FLOAT,0.0,{},defaultMemberFlagsNw)
ents.KinematicMover:RegisterMember("Speed",ents.MEMBER_TYPE_FLOAT,0.0,{},bit.bor(defaultMemberFlagsNw,ents.BaseEntityComponent.MEMBER_FLAG_BIT_PROPERTY))
ents.KinematicMover:RegisterMember("VelocityType",ents.MEMBER_TYPE_UINT8,ents.KinematicMover.VELOCITY_TYPE_INSTANTANEOUSLY,{},defaultMemberFlagsNw)
ents.KinematicMover:RegisterMember("OrientationType",ents.MEMBER_TYPE_UINT8,ents.KinematicMover.ORIENTATION_TYPE_NEVER,{},defaultMemberFlagsNw)
ents.KinematicMover:RegisterMember("ForwardSpeedModifier",ents.MEMBER_TYPE_FLOAT,1.0,{},defaultMemberFlagsNw)
ents.KinematicMover:RegisterMember("HeightOffset",ents.MEMBER_TYPE_FLOAT,0.0,{},defaultMemberFlagsNw)

ents.KinematicMover:RegisterMember("MoveSoundName",ents.MEMBER_TYPE_STRING,"",{},defaultMemberFlags)
ents.KinematicMover:RegisterMember("LoopMovingSound",ents.MEMBER_TYPE_BOOLEAN,true,{},defaultMemberFlags)
ents.KinematicMover:RegisterMember("StartSound",ents.MEMBER_TYPE_STRING,"",{},defaultMemberFlags)
ents.KinematicMover:RegisterMember("StopSound",ents.MEMBER_TYPE_STRING,"",{},defaultMemberFlags)
ents.KinematicMover:RegisterMember("SoundVolume",ents.MEMBER_TYPE_FLOAT,1.0,{},defaultMemberFlags)

function ents.KinematicMover:__init()
	BaseEntityComponent.__init(self)
end
function ents.KinematicMover:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_PHYSICS)
	self:AddEntityComponent(ents.COMPONENT_VELOCITY)
	self:AddEntityComponent(ents.COMPONENT_IO)
	self:AddEntityComponent(ents.COMPONENT_SOUND_EMITTER)
	-- self:AddEntityComponent(ents.COMPONENT_LOGIC)
	
	self:BindEvent(ents.PhysicsComponent.EVENT_ON_PRE_PHYSICS_SIMULATE,"OnPrePhysicsSimulate")
	self:BindEvent(ents.PhysicsComponent.EVENT_ON_PHYSICS_INITIALIZED,"OnPhysicsInitialized")
	if(SERVER) then
		self:BindEvent(ents.ModelComponent.EVENT_ON_MODEL_CHANGED,"UpdatePhysics")
	end
	
	self.m_netEvMoveTypeChanged = self:RegisterNetEvent("move_type")
	
	self:GetSpeedProperty():AddModifier(function(speed)
		local maxSpeed = self:GetMaxSpeed()
		return math.clamp(speed,-maxSpeed,maxSpeed)
	end)
end

function ents.KinematicMover:InitializeRender(component)
	component:SetCastShadows(true)
end

function ents.KinematicMover:OnPhysicsInitialized()
	local physComponent = self:GetEntity():GetComponent(ents.COMPONENT_PHYSICS)
	if(physComponent == nil) then return end
	physComponent:SetKinematic(true)

	local physObj = physComponent:GetPhysicsObject()
	if(physObj ~= nil) then
		for _,c in ipairs(physObj:GetCollisionObjects()) do
			c:SetAlwaysAwake(true)
		end
	end
end

function ents.KinematicMover:OnPrePhysicsSimulate()
	local dt = time.delta_time()
	if(dt == 0.0) then return end
	self:UpdateMove(dt)
end

function ents.KinematicMover:GetAbsoluteMoveTarget()
	local target = self:GetMoveTarget()
	if(self:GetMoveRelative()) then
		local ent = self:GetEntity()
		return ent:GetPos() +target
	end
	return target
end

function ents.KinematicMover:GetTargetAngles(entTgt)
	local ent = self:GetEntity()
	local trComponent = ent:GetComponent(ents.COMPONENT_TRANSFORM)
	if(trComponent == nil) then return EulerAngles() end
	local pos = ent:GetPos()
	pos.y = pos.y -self:GetHeightOffset()
	local posTgt = self:GetAbsoluteMoveTarget()
	
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
	-- rotDst = rotDst *EulerAngles(0,180,0):ToQuaternion()
	
	return rotDst:ToEulerAngles()
end

function ents.KinematicMover:UpdateMove(dt)
	if(self:IsMoving() == false) then return end
	local ent = self:GetEntity()
	local velComponent = ent:GetComponent(ents.COMPONENT_VELOCITY)
	if(velComponent == nil) then return end
	local pos = ent:GetPos()
	pos.y = pos.y -self:GetHeightOffset()
	local posTgt = self:GetAbsoluteMoveTarget()
	local mvDelta = posTgt -pos
	local l = mvDelta:Length()
	if(l == 0.0) then
		self:BroadcastEvent(ents.KinematicMover.EVENT_ON_TARGET_REACHED)
		self:Stop()
		return
	end
	mvDelta = mvDelta /l
	mvDelta = mvDelta *(math.min(self:GetSpeed() *dt,l) /dt)
	if(self:GetMoveRelative()) then self:SetMoveTarget(self:GetMoveTarget() -mvDelta *dt) end
	velComponent:SetVelocity(mvDelta)
	
	local trComponent = ent:GetComponent(ents.COMPONENT_TRANSFORM)
	if(self:GetOrientationType() ~= ents.KinematicMover.ORIENTATION_TYPE_NEVER and trComponent ~= nil) then
		local ang = trComponent:GetAngles()
		local angDst = self:GetTargetAngles()
		if(math.is_nan(angDst.p)) then
			angDst = self:GetTargetAngles()
		end
		
		local turnSpeed = 45.0 *dt
		local angDelta = EulerAngles(
			math.approach_angle(0.0,math.get_angle_difference(ang.p,angDst.p),turnSpeed),
			math.approach_angle(0.0,math.get_angle_difference(ang.y,angDst.y),turnSpeed),
			math.approach_angle(0.0,math.get_angle_difference(ang.r,angDst.r),turnSpeed)
		) /dt
		velComponent:SetAngularVelocity(Vector(math.rad(angDelta.p),math.rad(angDelta.y),math.rad(angDelta.r)))
	end
	self.m_prevPos = pos
end

function ents.KinematicMover:EmitSound(sndName)
	local sndEmitterComponent = self:GetEntity():GetComponent(ents.COMPONENT_SOUND_EMITTER)
	if(sndEmitterComponent == nil) then return end
	sndEmitterComponent:EmitSound(sndName,sound.TYPE_EFFECT)
end

function ents.KinematicMover:GetSpeed()
	local speed = self.m_speed:Get()
	if(self:GetMoveState() == ents.KinematicMover.MOVE_STATE_FORWARD) then
		speed = speed *self:GetForwardSpeedModifier()
		speed = math.min(speed,self:GetMaxSpeed())
	end
	return speed
end

function ents.KinematicMover:Start()
	local startSound = self:GetStartSound()
	if(#startSound > 0) then self:EmitSound(startSound) end
	if(self.m_moveSound ~= nil) then self.m_moveSound:Play() end
	local ioComponent = self:GetEntity():GetComponent(ents.COMPONENT_IO)
	if(ioComponent ~= nil) then ioComponent:FireOutput("OnStart",self:GetEntity()) end
	
	self:BroadcastEvent(ents.KinematicMover.EVENT_ON_STARTED)
	if(CLIENT) then return end
	local p = net.Packet()
	p:WriteUInt8(self:GetMoveState())
	self:GetEntity():BroadcastNetEvent(net.PROTOCOL_SLOW_RELIABLE,self.m_netEvMoveTypeChanged,p)
end

function ents.KinematicMover:StartForward()
	self:SetMoveState(ents.KinematicMover.MOVE_STATE_FORWARD)
	self.m_lastMoveDirection = self:GetMoveState()
	self:Start()
end

function ents.KinematicMover:StartBackward()
	self:SetMoveState(ents.KinematicMover.MOVE_STATE_BACKWARD)
	self.m_lastMoveDirection = self:GetMoveState()
	self:Start()
end

function ents.KinematicMover:Stop()
	local velComponent = self:GetEntity():GetComponent(ents.COMPONENT_VELOCITY)
	if(velComponent ~= nil) then
		velComponent:SetVelocity(Vector())
		velComponent:SetAngularVelocity(Vector())
	end
	self:SetMoveState(ents.KinematicMover.MOVE_STATE_IDLE)
	local stopSound = self:GetStopSound()
	if(#stopSound > 0) then self:EmitSound(stopSound) end
	if(self.m_moveSound ~= nil) then self.m_moveSound:Stop() end
	
	self:BroadcastEvent(ents.KinematicMover.EVENT_ON_STOPPED)
	if(CLIENT) then return end
	local p = net.Packet()
	p:WriteUInt8(self:GetMoveState())
	self:GetEntity():BroadcastNetEvent(net.PROTOCOL_SLOW_RELIABLE,self.m_netEvMoveTypeChanged,p)
end

function ents.KinematicMover:IsMoving() return self:GetMoveState() ~= ents.KinematicMover.MOVE_STATE_IDLE end

function ents.KinematicMover:Toggle()
	if(self:IsMoving()) then
		self:Stop()
		return
	end
	self:Resume()
end

function ents.KinematicMover:Reverse()
	if(self:GetMoveState() == ents.KinematicMover.MOVE_STATE_FORWARD) then self:SetMoveState(ents.KinematicMover.MOVE_STATE_BACKWARD)
	elseif(self:GetMoveState() == ents.KinematicMover.MOVE_STATE_BACKWARD) then self:SetMoveState(ents.KinematicMover.MOVE_STATE_FORWARD) end
end

function ents.KinematicMover:Resume()
	if(self.m_lastMoveDirection == nil or self:IsMoving()) then return end
	if(self.m_lastMoveDirection == ents.KinematicMover.MOVE_STATE_FORWARD) then
		self:StartForward()
		return
	end
	self:StartBackward()
end
ents.COMPONENT_KINEMATIC_MOVER = ents.register_component("kinematic_mover",ents.KinematicMover,ents.EntityComponent.FREGISTER_BIT_NETWORKED)

ents.KinematicMover.EVENT_ON_TARGET_REACHED = ents.register_component_event(ents.COMPONENT_KINEMATIC_MOVER,"on_target_reached")
ents.KinematicMover.EVENT_ON_STARTED = ents.register_component_event(ents.COMPONENT_KINEMATIC_MOVER,"on_started")
ents.KinematicMover.EVENT_ON_STOPPED = ents.register_component_event(ents.COMPONENT_KINEMATIC_MOVER,"on_stopped")
