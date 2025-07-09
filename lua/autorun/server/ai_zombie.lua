-- SPDX-FileCopyrightText: (c) 2021 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local faction = ai.register_faction("zombie")
faction:AddClass("npc_zombie")
faction:SetDefaultDisposition(ai.DISPOSITION_HATE)
