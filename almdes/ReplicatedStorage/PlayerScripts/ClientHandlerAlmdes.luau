local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local localPlayer = game.Players.LocalPlayer;

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManagerAlmdes);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local ClientHandler = {};
--==

function ClientHandler.onRequire()
	local dataModule = localPlayer:WaitForChild("DataModule");
	local modData = shared.require(dataModule :: ModuleScript);

    modData.TravelRequests = {};

    modClientGuis.bindGuiRemote("queueupdate", function(newState)
        modData.QueueState = newState;
        modClientGuis.fireEvent("queueupdate");
    end)
end

return ClientHandler;