include("../shared.lua")
include("behavior.lua")
include("controller.lua")

function ents.MonsterBarney:InitializeModel(component)
	component:SetModel("barney.wmd") -- The model our NPC uses
end

function ents.MonsterBarney:CanUse(ent) return true end

function ents.MonsterBarney:OnUse(ent)
	print("ON USE: ",ent)
end
