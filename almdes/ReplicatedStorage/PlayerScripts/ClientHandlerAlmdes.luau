local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local localPlayer = game.Players.LocalPlayer;

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManagerAlmdes);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterfaceAlmdes);

local ClientHandler = {};
--==

function ClientHandler.onRequire()
	local dataModule = localPlayer:WaitForChild("DataModule");
	local modData = shared.require(dataModule :: ModuleScript);

    local remoteMainMenu = modRemotesManager:Get("MainMenuRemote");

    modData.TravelRequests = {};
    
    modClientGuis.bindGuiRemote("queueupdate", function(newState)
        modData.QueueState = newState;
        modClientGuis.fireEvent("queueupdate");
    end)

    modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
        local queueState = modData.QueueState;
        if queueState == nil then return end;

        if queueState.NextLobbyFormTime == nil or workspace:GetServerTimeNow() > queueState.NextLobbyFormTime then
            local lastNextFormTime = queueState.NextLobbyFormTime;
            local rPacket = remoteMainMenu:InvokeServer("queueupdate");
            Debugger:Warn(`Requesting for queue update=`, rPacket);

            if rPacket then
                if rPacket.NewState then
                    modData.QueueState = rPacket.NewState;
                    queueState = modData.QueueState;

                    if queueState.NextLobbyFormTime == lastNextFormTime then
                        queueState.NextLobbyFormTime += 15;
                    end

                else
                    modData.QueueState = nil;
                    modClientGuis.fireEvent("queueupdate");
                end
            end
        end

    end)
end

return ClientHandler;