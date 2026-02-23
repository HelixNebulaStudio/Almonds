local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
--==

local LIVE_GAME_ID = 1971060599;
local DEV_GAME_ID = 5119363835;

local WORLD_TYPES = {
    Game = 1;
    Tutorial = 2;
    Dev = 10;
};

local WORLDS = {
    Genesis = {
        PlaceIds = {
            [LIVE_GAME_ID] = 5623142930;
            [DEV_GAME_ID] = 14856784878;
        };
        
        WorldType = WORLD_TYPES.Tutorial;
    };
}

function modBranchConfigurations.onRequire()
	modBranchConfigurations.Live = {
		Name = "Live";
		Color = Color3.fromRGB(92, 16, 255);
	};
	
	modBranchConfigurations.Dev = {
		Name = "Dev";
		Color = Color3.fromRGB(255, 16, 195);
	};

    modBranchConfigurations.Worlds = WORLDS;
    --==

    local curWorldName = modBranchConfigurations.WorldName;
    local curWorldInfo = modBranchConfigurations.WorldInfo;

    modConfigurations.Set("DisableHealthbar", false);
    modConfigurations.Set("DisableInfoBubbles", false);
    modConfigurations.Set("SpectateEnabled", false);
    modConfigurations.Set("BaseWoundedDuration", 150);
    modConfigurations.Set("DisableInventory", false);
    modConfigurations.Set("CanQuickEquip", true);
    modConfigurations.Set("PvpMode", true);
    modConfigurations.Set("DisableItemDrops", false);
    modConfigurations.Set("ForceNotifyStyle", 1);
    modConfigurations.Set("DisableSettingsMenu", false);
    modConfigurations.Set("FogScale", 2);
    
end

return modBranchConfigurations;