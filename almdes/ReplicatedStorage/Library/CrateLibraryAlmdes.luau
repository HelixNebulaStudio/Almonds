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
		Id = "envlootcrate";
		Name = "Crate";
		Prefab = {
			script:WaitForChild("EnvLootCrate1");
			script:WaitForChild("EnvLootCrate2");
			script:WaitForChild("EnvLootCrate3");
        };
		StoragePresetId = "envlootcrate";
	};
	
end

return modCrateLibrary;