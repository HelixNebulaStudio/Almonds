local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

local deployablePackage = {
    Type = "Template";
};
--==

function deployablePackage.onRequire()
    
end

function deployablePackage.BindDeployablePlacement(handler: ToolHandlerInstance, packet)

end

function deployablePackage.BindSpawnDeployable(handler: ToolHandlerInstance?, packet)

end

return deployablePackage;