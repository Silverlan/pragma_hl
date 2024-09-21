util.register_class("ents.LogicAuto", BaseEntityComponent)

ents.LogicAuto.GLOBAL_STATE_NONE = ""
ents.LogicAuto.GLOBAL_STATE_GORDON_PRECRIMINAL = "gordon_precriminal"
ents.LogicAuto.GLOBAL_STATE_ANTLION_ALLIED = "antlion_allied"
ents.LogicAuto.GLOBAL_STATE_PLAYER_STEALTH = "player_stealth"
ents.LogicAuto.GLOBAL_STATE_SUIT_NO_SPRINT = "suit_no_sprint"
ents.LogicAuto.GLOBAL_STATE_SUPER_PHYS_GUN = "super_phys_gun"
ents.LogicAuto.GLOBAL_STATE_FRIENDLY_ENCOUNTER = "friendly_encounter"
ents.LogicAuto.GLOBAL_STATE_CITIZENS_PASSIVE = "citizens_passive"
ents.LogicAuto.GLOBAL_STATE_GORDON_INVULNERABLE = "gordon_invulnerable"
ents.LogicAuto.GLOBAL_STATE_NO_SEAGULLS_ON_JEEP = "no_seagulls_on_jeep"
ents.LogicAuto.GLOBAL_STATE_IS_CONSOLE = "is_console"
ents.LogicAuto.GLOBAL_STATE_IS_PC = "is_pc"

ents.LogicAuto.SF_REMOVE_ON_FIRE = 1

function ents.LogicAuto:__init()
	BaseEntityComponent.__init(self)
end
function ents.LogicAuto:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent(ents.COMPONENT_IO)

	self:BindEvent(Entity.EVENT_HANDLE_KEY_VALUE, "HandleKeyValue")

	self.m_spawnFlags = 0
	self.m_globalState = ents.LogicAuto.GLOBAL_STATE_NONE
end

function ents.LogicAuto:OnRemove()
	if util.is_valid(self.m_cbOnMapSpawn) then
		self.m_cbOnMapSpawn:Remove()
	end
end

function ents.LogicAuto:OnEntitySpawn()
	if game.is_map_loaded() then
		self:Trigger()
		return
	end

	self.m_cbOnMapSpawn = game.add_callback("OnMapLoaded", function()
		if util.is_valid(self.m_cbOnMapSpawn) then
			self.m_cbOnMapSpawn:Remove()
		end
		local ent = self:GetEntity()
		local ioComponent = ent:GetComponent(ents.COMPONENT_IO)
		if ioComponent ~= nil then
			ioComponent:FireOutput("OnNewGame", ent, ents.IOComponent.IO_FLAG_BIT_FORCE_DELAYED_FIRE) -- TODO
			ioComponent:FireOutput("OnMapSpawn", ent, ents.IOComponent.IO_FLAG_BIT_FORCE_DELAYED_FIRE)
		end
		if self.m_spawnFlags ~= nil and bit.band(self.m_spawnFlags, ents.LogicAuto.SF_REMOVE_ON_FIRE) ~= 0 then
			self:GetEntity():RemoveSafely()
		end
	end)
	--[[
	TODO: OnNewGame, OnLoadGame, OnMapTransition, OnBackgroundMap, OnMultiNewMap, OnMultiNewRound
]]
end

function ents.LogicAuto:HandleKeyValue(key, val)
	if key == "spawnflags" then
		self.m_spawnFlags = tonumber(val)
	elseif key == "globalstate" then
		self.m_globalState = tonumber(val)
	else
		return util.EVENT_REPLY_UNHANDLED
	end
	return util.EVENT_REPLY_HANDLED
end
ents.register_component("logic_auto", ents.LogicAuto, "logic", ents.EntityComponent.FREGISTER_NONE)
