local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local modCrateLibrary = shared.require(game.ReplicatedStorage.Library.CrateLibrary);

--== Script;
function modCrateLibrary.onRequire()

	modCrateLibrary.New{
		Id = "deathpack";
		Name = "Death Pack";
		Prefab = {
            script:WaitForChild("Deathpack");
        };
		StoragePresetId = "deathpack";
	};

	modCrateLibrary.New{
		Id = "npcinventory";
		Name = "Inventory";
		Prefab = {};
		StoragePresetId = "npcinventory";
	};

	modCrateLibrary.New{
		Id = "envlootcrate";
		Name = "Crate";
		Prefab = {
			script:WaitForChild("EnvLootCrate1");
			script:WaitForChild("EnvLootCrate2");
			script:WaitForChild("EnvLootCrate3");
        };
		StoragePresetId = "envlootcrate";
	};

	modCrateLibrary.New{
		Id = "smallbanditcamp";
		Name = "Loot";
		Prefab = {
			script:WaitForChild("CratePalletT1");
        };
		StoragePresetId = "rewardcrate";
	};

	modCrateLibrary.New{
		Id = "carparkraid";
		Name = "Loot";
		Prefab = {
			script:WaitForChild("CratePalletT3");
        };
		StoragePresetId = "rewardcrate";
	};

	modCrateLibrary.New{
		Id = "athenahotelraid";
		Name = "Loot";
		Prefab = {
			script:WaitForChild("CratePalletT3");
        };
		StoragePresetId = "rewardcrate";
	};

end

return modCrateLibrary;