if(CLIENT == true) then locale.load("monster_scientist.txt")
else resource.add_lua_file("monster_scientist.lua") end

local function register_entity(gm)
	if(gm.RegisterEntity == nil) then return end
	gm:RegisterEntity(game.Sandbox.ENTITY_CATEGORY_NPC,"monster_scientist","scientist",{["body"] = "Random"})
end
local gm = game.get_game_mode()
if(gm ~= nil) then register_entity(gm) end
game.add_callback("OnGameModeInitialized",register_entity)
