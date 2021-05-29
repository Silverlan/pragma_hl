util.register_class("ents.FuncDoor",BaseEntityComponent)

--[[
	TODO: Implement outputs:
	output OnBlockedClosing(void) : "Fired when the door is blocked while closing."
	output OnBlockedOpening(void) : "Fired when the door is blocked while opening."
	output OnUnblockedClosing(void) : "Fired when the door is unblocked while closing."
	output OnUnblockedOpening(void) : "Fired when the door is unblocked while opening."
]]

ents.FuncDoor.SF_STARTS_OPEN = 1
ents.FuncDoor.SF_NON_SOLID_TO_PLAYER = 4
ents.FuncDoor.SF_PASSABLE = 8
ents.FuncDoor.SF_TOGGLE = 32
ents.FuncDoor.SF_USE_OPENS = 256
ents.FuncDoor.SF_NPCS_CANT = 512
ents.FuncDoor.SF_TOUCH_OPENS = 1024
ents.FuncDoor.SF_STARTS_LOCKED = 2048
ents.FuncDoor.SF_DOOR_SILENT = 4096

ents.FuncDoor.SPAWN_POSITION_CLOSED = 0
ents.FuncDoor.SPAWN_POSITION_OPEN = 1

ents.FuncDoor.LOCKED_SENTENCE_NONE = 0
ents.FuncDoor.LOCKED_SENTENCE_GEN_ACCESS_DENIED = 1
ents.FuncDoor.LOCKED_SENTENCE_SECURITY_LOCKED = 2
ents.FuncDoor.LOCKED_SENTENCE_BLAST_DOOR = 3
ents.FuncDoor.LOCKED_SENTENCE_FIRE_DOOR = 4
ents.FuncDoor.LOCKED_SENTENCE_CHEMICAL_DOOR = 5
ents.FuncDoor.LOCKED_SENTENCE_RADIATION_DOOR = 6
ents.FuncDoor.LOCKED_SENTENCE_GEN_CONTAINMENT = 7
ents.FuncDoor.LOCKED_SENTENCE_MAINTENANCE_DOOR = 8
ents.FuncDoor.LOCKED_SENTENCE_BROKEN_SHUT_DOOR = 9

ents.FuncDoor.UNLOCKED_SENTENCE_NONE = 0
ents.FuncDoor.UNLOCKED_SENTENCE_GEN_ACCESS_GRANTED = 1
ents.FuncDoor.UNLOCKED_SENTENCE_SECURITY_DISENGAGED = 2
ents.FuncDoor.UNLOCKED_SENTENCE_BLAST_DOOR = 3
ents.FuncDoor.UNLOCKED_SENTENCE_FIRE_DOOR = 4
ents.FuncDoor.UNLOCKED_SENTENCE_CHEMICAL_DOOR = 5
ents.FuncDoor.UNLOCKED_SENTENCE_RADIATION_DOOR = 6
ents.FuncDoor.UNLOCKED_SENTENCE_GEN_CONTAINMENT = 7
ents.FuncDoor.UNLOCKED_SENTENCE_MAINTENANCE_AREA = 8

local defaultMemberFlags = bit.band(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,bit.bnot(bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_BIT_KEY_VALUE,ents.BaseEntityComponent.MEMBER_FLAG_BIT_INPUT,ents.BaseEntityComponent.MEMBER_FLAG_BIT_OUTPUT)))
local defaultMemberFlagsNw = bit.bor(defaultMemberFlags,ents.BaseEntityComponent.MEMBER_FLAG_BIT_NETWORKED,ents.BaseEntityComponent.MEMBER_FLAG_TRANSMIT_ON_CHANGE)

ents.FuncDoor:RegisterMember("MoveDir",util.VAR_TYPE_EULER_ANGLES,EulerAngles(),defaultMemberFlagsNw,1)
ents.FuncDoor:RegisterMember("FilterName",util.VAR_TYPE_ENTITY,ents.get_null(),defaultMemberFlags,1)

ents.FuncDoor:RegisterMember("Open",util.VAR_TYPE_BOOL,false,bit.bor(defaultMemberFlags,ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER),1)
ents.FuncDoor:RegisterMember("StartSound",util.VAR_TYPE_STRING,"",defaultMemberFlags,1)
ents.FuncDoor:RegisterMember("StopSound",util.VAR_TYPE_STRING,"",defaultMemberFlags,1)
ents.FuncDoor:RegisterMember("StartCloseSound",util.VAR_TYPE_STRING,"",defaultMemberFlags,1)
ents.FuncDoor:RegisterMember("CloseSound",util.VAR_TYPE_STRING,"",defaultMemberFlags,1)
ents.FuncDoor:RegisterMember("DelayBeforeReset",util.VAR_TYPE_FLOAT,4.0,defaultMemberFlags,1)
ents.FuncDoor:RegisterMember("Lip",util.VAR_TYPE_FLOAT,0.0,defaultMemberFlagsNw,1)
ents.FuncDoor:RegisterMember("BlockingDamage",util.VAR_TYPE_INT32,0,defaultMemberFlags,1)
ents.FuncDoor:RegisterMember("ForceClosed",util.VAR_TYPE_BOOL,0,defaultMemberFlags,1)
ents.FuncDoor:RegisterMember("IgnoreDebris",util.VAR_TYPE_BOOL,0,defaultMemberFlags,1)
ents.FuncDoor:RegisterMember("LockedSound",util.VAR_TYPE_STRING,"",defaultMemberFlags,1)
ents.FuncDoor:RegisterMember("UnlockedSound",util.VAR_TYPE_STRING,"",defaultMemberFlags,1)
ents.FuncDoor:RegisterMember("SpawnPosition",util.VAR_TYPE_UINT8,ents.FuncDoor.SPAWN_POSITION_CLOSED,defaultMemberFlags,1)
ents.FuncDoor:RegisterMember("LockedSentence",util.VAR_TYPE_UINT8,ents.FuncDoor.LOCKED_SENTENCE_NONE,defaultMemberFlags,1)
ents.FuncDoor:RegisterMember("UnlockedSentence",util.VAR_TYPE_UINT8,ents.FuncDoor.UNLOCKED_SENTENCE_NONE,defaultMemberFlags,1)
ents.FuncDoor:RegisterMember("MinimumLightLevel",util.VAR_TYPE_STRING,"",defaultMemberFlags,1)

ents.FuncDoor:RegisterMember("SpawnFlags",util.VAR_TYPE_UINT32,0,defaultMemberFlags,1)

ents.FuncDoor:RegisterMember("Locked",util.VAR_TYPE_BOOL,false,bit.bor(defaultMemberFlags,ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER),1)

function ents.FuncDoor:__init()
	BaseEntityComponent.__init(self)
end
function ents.FuncDoor:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent(ents.COMPONENT_KINEMATIC_MOVER,"InitializeKinematicMover")
	self:AddEntityComponent(ents.COMPONENT_RENDER,"InitializeRender")
	
	self:BindEvent(Entity.EVENT_HANDLE_KEY_VALUE,"HandleKeyValue")
	self:BindEvent(ents.IOComponent.EVENT_HANDLE_INPUT,"HandleInput")
	self:BindEvent(ents.KinematicMover.EVENT_ON_TARGET_REACHED,"OnTargetReached")
end

function ents.FuncDoor:OnEntitySpawn()
	if(self:GetSpawnPosition() == ents.FuncDoor.SPAWN_POSITION_OPEN) then self:SetOpen(true) end
end

function ents.FuncDoor:OnTargetReached()
	local ent = self:GetEntity()
	local kinematicMoverComponent = ent:GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
	local ioComponent = ent:GetComponent(ents.COMPONENT_IO)
	if(kinematicMoverComponent == nil or ioComponent == nil) then return end
	local moveState = kinematicMoverComponent:GetMoveState()
	ioComponent:FireOutput((moveState == ents.KinematicMover.MOVE_STATE_FORWARD) and "OnFullyOpen" or "OnFullyClosed",ent)
end

function ents.FuncDoor:InitializeKinematicMover(component)
	component:SetMoveRelative(true)
	component:SetLoopMovingSound(false)
end

function ents.FuncDoor:InitializeRender(component)
	component:SetCastShadows(true)
end

function ents.FuncDoor:HandleKeyValue(key,val)
	if(key == "movedir") then self:SetMoveDir(angle.create_from_string(val))
	elseif(key == "filtername") then self:SetFilterName(val)
	elseif(key == "speed") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:SetStartSpeed(tonumber(val)) end
	elseif(key == "noise1") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:SetStartSound(val) end
	elseif(key == "noise2") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:SetStopSound(val) end
	elseif(key == "startclosesound") then self:SetStartCloseSound(val)
	elseif(key == "closesound") then self:SetCloseSound(val)
	elseif(key == "wait") then self:SetDelayBeforeReset(tonumber(val))
	elseif(key == "lip") then self:SetLip(tonumber(val))
	elseif(key == "dmg") then self:SetBlockingDamage(tonumber(val))
	elseif(key == "forceclosed") then self:SetForceClosed(toboolean(val))
	elseif(key == "ignoredebris") then self:SetIgnoreDebris(toboolean(val))
	elseif(key == "locked_sound") then self:SetLockedSound(val)
	elseif(key == "unlocked_sound") then self:SetUnlockedSound(val)
	elseif(key == "spawnpos") then self:SetSpawnPosition(toboolean(val))
	elseif(key == "spawnflags") then self:SetSpawnFlags(tonumber(val))
	elseif(key == "locked_sentence") then self:SetLockedSentence(tonumber(val))
	elseif(key == "unlocked_sentence") then self:SetUnlockedSentence(tonumber(val))
	elseif(key == "_minlight") then self:SetMinimumLightLevel(val)
	elseif(key == "loopmovesound") then
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:SetLoopMovingSound(toboolean(val)) end
	else return util.EVENT_REPLY_UNHANDLED end
	return util.EVENT_REPLY_HANDLED
end

function ents.FuncDoor:UpdateMoveDistance(bReverse)
	local ent = self:GetEntity()
	local physComponent = ent:GetComponent(ents.COMPONENT_PHYSICS)
	if(physComponent == nil) then return end
	local moveDir = self:GetMoveDir():GetForward()
	local min,max = physComponent:GetCollisionBounds()
	local bIntersect0,lineStart0,lineExit0 = intersect.line_with_aabb(Vector(),moveDir,min,max)
	local bIntersect1,lineStart1,lineExit1 = intersect.line_with_aabb(Vector(),-moveDir,min,max)
	local kinematicMover = ent:GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
	if(kinematicMover ~= nil) then
		local d = -self:GetLip()
		if(bIntersect0 == true) then d = d +lineExit0 end
		if(bIntersect1 == true) then d = d +lineExit1 end
		local target = moveDir *d
		if(bReverse == true) then target = -target end
		kinematicMover:SetMoveTarget(target +kinematicMover:GetMoveTarget())
	end
end

function ents.FuncDoor:IsClosed() return self:IsOpen() == false end

function ents.FuncDoor:EmitSound(sndName)
	local sndEmitterComponent = self:GetEntity():GetComponent(ents.COMPONENT_SOUND_EMITTER)
	if(sndEmitterComponent == nil) then return end
	sndEmitterComponent:EmitSound(sndName,sound.TYPE_EFFECT)
end

function ents.FuncDoor:Open()
	if(self:IsOpen()) then return end
	local ioComponent = self:GetEntity():GetComponent(ents.COMPONENT_IO)
	if(self:IsLocked()) then
		local lockedSound = self:GetLockedSound()
		if(#lockedSound > 0) then self:EmitSound(lockedSound) end
		
		local lockedSentence = self:GetLockedSentence()
		if(lockedSentence ~= ents.FuncDoor.LOCKED_SENTENCE_NONE) then end -- TODO
		
		if(ioComponent ~= nil) then ioComponent:FireOutput("OnLockedUse",self:GetEntity()) end
		return
	else
		local unlockedSound = self:GetUnlockedSound()
		if(#unlockedSound > 0) then self:EmitSound(unlockedSound) end
		
		local unlockedSentence = self:GetUnlockedSentence()
		if(unlockedSentence ~= ents.FuncDoor.UNLOCKED_SENTENCE_NONE) then end -- TODO
	end
	
	if(ioComponent ~= nil) then ioComponent:FireOutput("OnOpen",self:GetEntity()) end
	self:SetOpen(true)
	self:UpdateMoveDistance()
	local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
	if(kinematicMover ~= nil) then kinematicMover:StartForward() end
end

function ents.FuncDoor:Close()
	if(self:IsClosed()) then return end
	local ioComponent = self:GetEntity():GetComponent(ents.COMPONENT_IO)
	if(ioComponent ~= nil) then ioComponent:FireOutput("OnClose",self:GetEntity()) end
	self:SetOpen(false)
	self:UpdateMoveDistance(true)
	local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
	if(kinematicMover ~= nil) then kinematicMover:StartBackward() end
end

function ents.FuncDoor:Toggle()
	if(self:IsOpen()) then self:Close()
	else self:Open() end
end

function ents.FuncDoor:Lock()
	self:SetLocked(true)
end

function ents.FuncDoor:Unlock()
	self:SetLocked(false)
end

function ents.FuncDoor:HandleInput(input,activator,caller,data)
	if(input == "open") then
		self:Open()
	elseif(input == "close") then
		self:Close()
	elseif(input == "toggle") then
		self:Toggle()
	elseif(input == "lock") then
		self:Lock()
	elseif(input == "unlock") then
		self:Unlock()
	elseif(input == "setspeed") then
		self:SetSpeed(tonumber(data))
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:SetStartSpeed(tonumber(data)) end
	else return util.EVENT_REPLY_UNHANDLED end
	return util.EVENT_REPLY_HANDLED
end
ents.COMPONENT_FUNC_DOOR = ents.register_component("func_door",ents.FuncDoor,ents.EntityComponent.FREGISTER_BIT_NETWORKED)
