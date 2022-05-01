include("/entities/components/kinematic_mover/client/cl_init.lua")
include("../shared.lua")

function ents.FuncTrackTrain:ReceiveNetEvent(eventId,packet)
	if(eventId == self.m_netEvMoveTargetChanged) then
		self:SetCurrentTarget(packet:ReadEntity())
		
		local kinematicMover = self:GetEntity():GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
		if(kinematicMover ~= nil) then kinematicMover:SetSpeed(packet:ReadFloat()) end
	else return util.EVENT_REPLY_UNHANDLED end
	return util.EVENT_REPLY_HANDLED
end

function ents.FuncTrackTrain:ReceiveData(packet)
  self:FlagCallbackForRemoval(packet:ReadUniqueEntity(function(ent)
    if(self:IsValid() == false) then return end
    self:SetCurrentTarget(ent)
  end),ents.EntityComponent.CALLBACK_TYPE_COMPONENT)
end
