include("../shared.lua")

function ents.EnvFade:ReceiveNetEvent(eventId,packet)
	if(eventId == self.m_netEvFade) then
		self:StartFade()
	else return util.EVENT_REPLY_UNHANDLED end
	return util.EVENT_REPLY_HANDLED
end

function ents.EnvFade:UpdateFadeColor()
  local bFadeFrom = bit.band(self.m_spawnFlags,ents.EnvFade.SF_FADE_FROM) ~= 0
  local bModulate = bit.band(self.m_spawnFlags,ents.EnvFade.SF_MODULATE) ~= 0
  local bStayOut = bit.band(self.m_spawnFlags,ents.EnvFade.SF_STAY_OUT) ~= 0
  
  local tDelta = time.real_time() -self.m_tFadeStart
  local colComponent = self:GetEntity():GetComponent(ents.COMPONENT_COLOR)
  if(colComponent == nil) then return end
  local bEndFade = false
  local col = colComponent:GetColor()
  local aSrc = 0
  local aDst = self.m_fadeAlpha
  if(bFadeFrom == true) then
    local tmp = aSrc
    aSrc = aDst
    aDst = tmp
  end
  if(tDelta < self.m_duration) then col.a = aSrc +(tDelta /self.m_duration) *(aDst -aSrc)
  elseif(tDelta < (self.m_duration +self.m_holdTime)) then col.a = aDst
  else
    if(bStayOut == true) then col.a = aDst
    else col.a = 0 end
    bEndFade = true
  end
  if(util.is_valid(self.m_fadePanel)) then self.m_fadePanel:SetColor(col) end -- TODO: Link color properties
  if(bEndFade == false) then return end
  if(bStayOut == false or col.a == 0) then self.m_fadePanel:SetVisible(false) end
  self:SetTickPolicy(ents.TICK_POLICY_NEVER)
end

function ents.EnvFade:OnTick(dt)
  self:UpdateFadeColor()
end

function ents.EnvFade:ReceiveData(packet)
  self.m_spawnFlags = packet:ReadUInt32()
  self.m_duration = packet:ReadFloat()
  self.m_holdTime = packet:ReadFloat()
  self.m_fadeAlpha = packet:ReadUInt8()
end
