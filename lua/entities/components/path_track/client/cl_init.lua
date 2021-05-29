include("../shared.lua")

function ents.PathTrack:ReceiveData(packet)
  self:FlagCallbackForRemoval(packet:ReadUniqueEntity(function(ent)
    if(self:IsValid() == false) then return end
    self.m_entTarget = ent
  end),ents.EntityComponent.CALLBACK_TYPE_COMPONENT)
   self:FlagCallbackForRemoval(packet:ReadUniqueEntity(function(ent)
    if(self:IsValid() == false) then return end
    self.m_entAltTarget = ent
  end),ents.EntityComponent.CALLBACK_TYPE_COMPONENT)
  self.m_speed = packet:ReadFloat()
  self.m_radius = packet:ReadFloat()
  self.m_altPathEnabled = packet:ReadBool()
end
