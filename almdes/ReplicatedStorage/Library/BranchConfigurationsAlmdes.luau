local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
--==

local LIVE_GAME_ID = 1971060599;
local DEV_GAME_ID = 5119363835;

local WORLD_TYPES = {
    Game = 1;
    MainMenu = 2;
    Dev = 10;
};

local WORLDS = {
    MainMenu = {
        DisplayName = "Main Menu";
        PlaceIds = {
            [LIVE_GAME_ID] = 5623142930;
            [DEV_GAME_ID] = 14856784878;
        };
        
        WorldType = WORLD_TYPES.MainMenu;
        CanTravelTo = true;
        TimeCycleEnabled = true;
        MaxPlayers = 20;
    };
    Genesis = {
        PlaceIds = {
            [LIVE_GAME_ID] = -1;
            [DEV_GAME_ID] = 114398204736032;
        };
        
        WorldType = WORLD_TYPES.Game;
        TimeCycleEnabled = true;
    };
}

function modBranchConfigurations.onRequire()
	modBranchConfigurations.Live = {
		Name = "Live";
		Color = Color3.fromRGB(255, 16, 195);
	};
	
	modBranchConfigurations.Dev = {
		Name = "Dev";
		Color = Color3.fromRGB(92, 16, 255);
	};

    modBranchConfigurations.Worlds = WORLDS;
    --==

    local curWorldName = modBranchConfigurations.WorldName;
    local curWorldInfo = modBranchConfigurations.WorldInfo;

    modConfigurations.Set("DisableEmotes", false);
    modConfigurations.Set("DisableInventory", false);
    modConfigurations.Set("DisableMissions", false);
    modConfigurations.Set("DisableHealthbar", false);
    modConfigurations.Set("DisableInfoBubbles", false);
    modConfigurations.Set("SpectateEnabled", false);
    modConfigurations.Set("CanQuickEquip", true);
    modConfigurations.Set("PvpMode", true);
    modConfigurations.Set("DisableSettingsMenu", false);
    modConfigurations.Set("DisableItemDrops", false);

    if curWorldInfo.WorldType == WORLD_TYPES.MainMenu then
        modConfigurations.Set("SafehomeMode", true);
        modConfigurations.Set("BaseWoundedDuration", 0);
            
    elseif curWorldInfo.WorldType == WORLD_TYPES.Game then
        modConfigurations.Set("BaseWoundedDuration", 150);
        modConfigurations.Set("ForceNotifyStyle", 1);
        modConfigurations.Set("FogScale", 2);

    end
end

return modBranchConfigurations;