
local RunService = game:GetService("RunService");

local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modWorldCoreClass = shared.require(game.ReplicatedStorage.Library.WorldCoreClass);

if RunService:IsServer() then
    modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
    modCrates = shared.require(game.ReplicatedStorage.Library.Crates);

end
--==
function modWorldCoreClass.onRequire()

end

return modWorldCoreClass;
