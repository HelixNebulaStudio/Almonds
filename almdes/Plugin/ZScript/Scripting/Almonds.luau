local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local ZScript = {};

function ZScript.Load(zScr, zEnv)
    local Almonds, AlmondsMeta = zScr.newLib();

    Almonds.GameVersion = modGlobalVars.GameVersion;
    Almonds.GameBuild = modGlobalVars.GameBuild;
    Almonds.BranchColor = modBranchConfigs.BranchColor;

    zEnv.Almonds = Almonds;
end

return ZScript;