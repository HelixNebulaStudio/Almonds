local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);

function modBranchConfigurations.onRequire()
    modConfigurations.Set("SpectateEnabled", false);
    modConfigurations.Set("BaseWoundedDuration", 150);
    modConfigurations.Set("DisableInventory", false);
    modConfigurations.Set("CanQuickEquip", true);
    modConfigurations.Set("PvpMode", true);
    modConfigurations.Set("DisableItemDrops", false);
end

return modBranchConfigurations;