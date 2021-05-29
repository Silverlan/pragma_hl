include("/entities/components/kinematic_mover/server/init.lua")
include("../shared.lua")

function ents.FuncTrackTrain:SendData(packet,rp)
  local entTgt = self:GetCurrentTarget()
  packet:WriteUniqueEntity(entTgt)
end

function ents.FuncTrackTrain:OnEntitySpawn()
	local ent = self:GetEntity()
  local firstStopTarget = self:GetFirstStopTarget()
  if(#firstStopTarget > 0) then
    self:SetFirstStopTarget("")
    local it = ents.iterator(bit.bor(ents.ITERATOR_FILTER_DEFAULT,ents.ITERATOR_FILTER_BIT_PENDING),{ents.IteratorFilterEntity(firstStopTarget)})
    local entTgt = it()
    if(entTgt ~= nil) then
      local pathTrackComponent = entTgt:GetComponent(ents.COMPONENT_PATH_TRACK)
      self:SetCurrentTarget(entTgt)
      ent:SetPos(self:GetMovePos(entTgt:GetPos()))
      if(pathTrackComponent ~= nil) then
        pathTrackComponent:OnPass(ent)
        ent:SetAngles(self:GetTargetAngles(pathTrackComponent:GetNextTarget()))
      end
      
      local kinematicMover = ent:GetComponent(ents.COMPONENT_KINEMATIC_MOVER)
      local p = net.Packet()
      p:WriteEntity(entTgt)
      p:WriteFloat((kinematicMover ~= nil) and kinematicMover:GetSpeed() or 0.0)
      self:GetEntity():BroadcastNetEvent(net.PROTOCOL_SLOW_RELIABLE,self.m_netEvMoveTargetChanged,p)
      --self:TeleportToTarget()
    end
  end
end
