include("../shared.lua")

function ents.KinematicMover:ReceiveNetEvent(eventId,packet)
	if(eventId == self.m_netEvMoveTypeChanged) then
		local moveState = packet:ReadUInt8()
		if(moveState == ents.KinematicMover.MOVE_STATE_IDLE) then self:Stop()
		elseif(moveState == ents.KinematicMover.MOVE_STATE_FORWARD) then self:StartForward()
		elseif(moveState == ents.KinematicMover.MOVE_STATE_BACKWARD) then self:StartBackward() end
	else return util.EVENT_REPLY_UNHANDLED end
	return util.EVENT_REPLY_HANDLED
end
