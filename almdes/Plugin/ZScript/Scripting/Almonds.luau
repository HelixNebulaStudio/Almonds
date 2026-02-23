local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurationsAlmdes);
local ZScript = {};

function ZScript.Load(zScr, zEnv)
    local Almonds, AlmondsMeta = zScr.newLib();

    Almonds.GameVersion = modGlobalVars.GameVersion;
    Almonds.GameBuild = modGlobalVars.GameBuild;
    Almonds.BranchColor = modBranchConfigurations.BranchColor;

    zEnv.Almonds = Almonds;
end

return ZScript;