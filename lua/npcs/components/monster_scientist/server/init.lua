include("../shared.lua")
include("behavior.lua")
include("controller.lua")

function ents.MonsterScientist:InitializeModel(component)
	component:SetModel("scientist.wmd") -- The model our NPC uses
end

function ents.MonsterScientist:CanUse(ent) return true end

function ents.MonsterScientist:OnUse(ent)
	print("ON USE: ",ent)
end
