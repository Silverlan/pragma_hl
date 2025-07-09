-- SPDX-FileCopyrightText: (c) 2021 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local faction = ai.register_faction("scientist")
faction:AddClass("monster_scientist")
faction:SetDefaultDisposition(ai.DISPOSITION_HATE)
