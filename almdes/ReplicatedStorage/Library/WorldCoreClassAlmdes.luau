
local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");

local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modWorldCoreClass = shared.require(game.ReplicatedStorage.Library.WorldCoreClass);

if RunService:IsServer() then
    modWorldEvents = shared.require(game.ServerScriptService.ServerLibrary.WorldEvents);
    modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
    modCrates = shared.require(game.ReplicatedStorage.Library.Crates);

end
--==
function modWorldCoreClass.onRequire()
    local eventsLibraryModule = game.ReplicatedStorage.Library:WaitForChild("EventsLibrary");

    if RunService:IsServer() then
        modWorldCoreClass.WorldEventsData = {};
    
    elseif RunService:IsClient() then
        local function updateEvents()
            local worldEventDataRaw = eventsLibraryModule:GetAttribute("Public");
            local worldEventData;
            pcall(function() worldEventData = HttpService:JSONDecode(worldEventDataRaw); end);
            if worldEventData == nil then return end;

            modWorldCoreClass.WorldEventsData = worldEventData;
        end
        eventsLibraryModule:GetAttributeChangedSignal("Public"):Connect(function()
            updateEvents();
        end)
        updateEvents();

    end
end

return modWorldCoreClass;
