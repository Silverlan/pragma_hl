-- SPDX-FileCopyrightText: (c) 2021 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("../shared.lua")

function ents.EnvFade:SendData(packet,rp)
  packet:WriteUInt32(self.m_spawnFlags)
  packet:WriteFloat(self.m_duration)
  packet:WriteFloat(self.m_holdTime)
  packet:WriteUInt8(self.m_fadeAlpha)
end
