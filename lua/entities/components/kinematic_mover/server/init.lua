include("../shared.lua")

function ents.KinematicMover:UpdatePhysics()
  local ent = self:GetEntity()
  if(ent:IsSpawned() == false or ent:GetModel() == nil) then return end
  local physComponent = ent:GetPhysicsComponent()
  if(physComponent ~= nil) then physComponent:InitializePhysics(phys.TYPE_DYNAMIC) end
end

function ents.KinematicMover:OnEntitySpawn()
  self:UpdatePhysics()
	local ent = self:GetEntity()
  local moveSoundName = self:GetMoveSoundName()
  if(#moveSoundName > 0) then
    local sndEmitterComponent = ent:GetComponent(ents.COMPONENT_SOUND_EMITTER)
    if(sndEmitterComponent ~= nil) then
      self.m_moveSound = sndEmitterComponent:CreateSound(moveSoundName,sound.TYPE_EFFECT)
      if(self.m_moveSound ~= nil) then
        self.m_moveSound:SetLooping(self:GetLoopMovingSound())
        self.m_moveSound:SetRelative(false)
        self.m_moveSound:SetGain(self:GetSoundVolume())
      end
    end
  end
	
	local startSpeed = self:GetStartSpeed()
	if(startSpeed > 0.0) then
		self:SetSpeed(startSpeed)
		self:StartForward()
	end
end
