local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);

function modBranchConfigurations.onRequire()
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
    
end

return modBranchConfigurations;