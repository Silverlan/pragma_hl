include("../shared.lua")

function ents.PathTrack:SendData(packet,rp)
  packet:WriteUniqueEntity(self.m_entTarget)
  packet:WriteUniqueEntity(self.m_entAltTarget)
  packet:WriteFloat(self.m_speed)
  packet:WriteFloat(self.m_radius)
  packet:WriteBool(self.m_altPathEnabled)
end
