util.register_class("ents.FuncTrackAutoChange",BaseEntityComponent)

ents.FuncTrackAutoChange.SF_AUTO_ACTIVATE_TRAIN = 1
ents.FuncTrackAutoChange.SF_RELINK_TRACK = 2
ents.FuncTrackAutoChange.SF_START_AT_BOTTOM = 8
ents.FuncTrackAutoChange.SF_ROTATE_ONLY = 16
ents.FuncTrackAutoChange.SF_X_AXIS = 64
ents.FuncTrackAutoChange.SF_Y_AXIS = 128

ents.FuncTrackAutoChange.TOGGLE_STATE_AT_TOP = 0
ents.FuncTrackAutoChange.TOGGLE_STATE_AT_BOTTOM = 1
ents.FuncTrackAutoChange.TOGGLE_STATE_GOING_UP = 2
ents.FuncTrackAutoChange.TOGGLE_STATE_GOING_DOWN = 3

ents.FuncTrackAutoChange.TRAIN_SAFE = 0
ents.FuncTrackAutoChange.TRAIN_BLOCKING = 1
ents.FuncTrackAutoChange.TRAIN_FOLLOWING = 2

local defaultMemberFlags = bit.band(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,bit.bnot(bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_BIT_KEY_VALUE,ents.BaseEntityComponent.MEMBER_FLAG_BIT_INPUT,ents.BaseEntityComponent.MEMBER_FLAG_BIT_OUTPUT)))
local defaultMemberFlagsNw = bit.bor(defaultMemberFlags,ents.BaseEntityComponent.MEMBER_FLAG_BIT_NETWORKED,ents.BaseEntityComponent.MEMBER_FLAG_TRANSMIT_ON_CHANGE)

ents.FuncTrackAutoChange:RegisterMember("TravelAltitude",util.VAR_TYPE_FLOAT,0.0,defaultMemberFlagsNw,1)
ents.FuncTrackAutoChange:RegisterMember("SpinAmount",util.VAR_TYPE_FLOAT,0.0,defaultMemberFlagsNw,1)
ents.FuncTrackAutoChange:RegisterMember("TrainToSwitch",util.VAR_TYPE_ENTITY,ents.get_null(),defaultMemberFlagsNw,1)
ents.FuncTrackAutoChange:RegisterMember("TopTrack",util.VAR_TYPE_ENTITY,ents.get_null(),defaultMemberFlagsNw,1)
ents.FuncTrackAutoChange:RegisterMember("BottomTrack",util.VAR_TYPE_ENTITY,ents.get_null(),defaultMemberFlagsNw,1)

ents.FuncTrackAutoChange:RegisterMember("SpawnFlags",util.VAR_TYPE_UINT32,0,defaultMemberFlags,1)

function ents.FuncTrackAutoChange:__init()
	BaseEntityComponent.__init(self)
end
function ents.FuncTrackAutoChange:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent(ents.COMPONENT_KINEMATIC_MOVER,"InitializeKinematicMover")
	self:AddEntityComponent(ents.COMPONENT_RENDER,"InitializeRender")
	
	self:BindEvent(Entity.EVENT_HANDLE_KEY_VALUE,"HandleKeyValue")
	self:BindEvent(ents.IOComponent.EVENT_HANDLE_INPUT,"HandleInput")
	self:BindEvent(ents.KinematicMover.EVENT_ON_TARGET_REACHED,"OnTargetReached")
end

function ents.FuncTrackAutoChange:OnTargetReached()
	TODO:
	Problem: func_trackautochange has no origin in source engine
	-> origin is 0 0 0
	-> rotation is around map origin
	solution:
	- Either introduce origin and move faces of entity by the negative origin -> Probably better solution, faces can alyways only belong to one entity (because of numfaces range)
	Calculated origin has to correspond with hammer entity origin
	- or work with map origin in which case entity has to be MOVED for proper rotation!
	Also: Make sure to apply velocity to parented kinematic entities
	local spinAmount = self:GetSpinAmount()
	local trComponent = self:GetEntity():GetComponent(ents.COMPONENT_TRANSFORM)
	if(trComponent ~= nil) then
		trComponent:SetYaw(trComponent:GetYaw() +spinAmount)
	end
	
	local entTrain = self:GetTrainToSwitch()
	if(util.is_valid(entTrain)) then entTrain:RemoveComponent(ents.COMPONENT_ATTACHABLE) end
end

function ents.FuncTrackAutoChange:OnEntitySpawn()
	if(self.m_trainName ~= nil) then
		self:SetTrainToSwitch(ents.iterator(bit.bor(ents.ITERATOR_FILTER_DEFAULT,ents.ITERATOR_FILTER_BIT_PENDING),{ents.IteratorFilterEntity(self.m_trainName)})())
	end
	if(self.m_topTrackName ~= nil) then
		self:SetTopTrack(ents.iterator(bit.bor(ents.ITERATOR_FILTER_DEFAULT,ents.ITERATOR_FILTER_BIT_PENDING),{ents.IteratorFilterEntity(self.m_topTrackName)})())
	end
	if(self.m_bottomTrackName ~= nil) then
		self:SetBottomTrack(ents.iterator(bit.bor(ents.ITERATOR_FILTER_DEFAULT,ents.ITERATOR_FILTER_BIT_PENDING),{ents.IteratorFilterEntity(self.m_bottomTrackName)})())
	end
end

function ents.FuncTrackAutoChange:InitializeKinematicMover(component)
	component:SetMoveRelative(true)
	component:SetLoopMovingSound(false)
end

function ents.FuncTrackAutoChange:InitializeRender(component)
	component:SetCastShadows(true)
end

function ents.FuncTrackAutoChange:HandleKeyValue(key,val)
	if(key == "height") then self:SetTravelAltitude(tonumber(val))
	elseif(key == "spawnflags") then self:SetSpawnFlags(tonumber(val))
	elseif(key == "rotation") then self:SetSpinAmount(tonumber(val))
	elseif(key == "train") then self.m_trainName = val
	elseif(key == "toptrack") then self.m_topTrackName = val
	elseif(key == "bottomtrack") then self.m_bottomTrackName = val
	elseif(key == "speed") then
		local componentKinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(componentKinematicMover ~= nil) then componentKinematicMover:SetSpeed(tonumber(val)) end
	else return util.EVENT_REPLY_UNHANDLED end
	return util.EVENT_REPLY_HANDLED
end

function ents.FuncTrackAutoChange:Trigger()
	local entBottomTrack = self:GetBottomTrack()
	local entTopTrack = self:GetTopTrack()
	local ent = self:GetEntity()
	local componentKinematicMover = ent:GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
	if(componentKinematicMover == nil or util.is_valid(entBottomTrack) == false or util.is_valid(entTopTrack) == false) then return end
	local entTrain = self:GetTrainToSwitch()
	if(util.is_valid(entTrain)) then
		local attachableComponent = entTrain:AddComponent(ents.COMPONENT_ATTACHABLE)
		if(attachableComponent ~= nil) then
			attachableComponent:AttachToEntity(ent)
		end
	end
	componentKinematicMover:SetMoveTarget(entBottomTrack:GetPos() -entTopTrack:GetPos())
	componentKinematicMover:StartForward()
end

function ents.FuncTrackAutoChange:HandleInput(input,activator,caller,data)
	if(input == "trigger") then self:Trigger()
	else return util.EVENT_REPLY_UNHANDLED end
	return util.EVENT_REPLY_HANDLED
end
ents.COMPONENT_FUNC_TRACKAUTOCHANGE = ents.register_component("func_trackautochange",ents.FuncTrackAutoChange,ents.EntityComponent.FREGISTER_BIT_NETWORKED)
