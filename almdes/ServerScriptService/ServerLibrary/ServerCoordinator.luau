local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local MemoryStoreService = game:GetService("MemoryStoreService");

local serverCoordinatorMem;

local ServerCoordinator = {};
ServerCoordinator.CurServerInfo = nil;

--==
function ServerCoordinator.onRequire()
    serverCoordinatorMem = MemoryStoreService:GetHashMap(`GlobalServers`);
end

function ServerCoordinator:SetCurrentServerInfo(serverInfo)
    ServerCoordinator.CurServerInfo = serverInfo;
end

function ServerCoordinator:NewServer(privateServerId, serverInfo)
    Debugger:Warn(`NewServer {privateServerId}`);

    local maxAttempts = 5;
    local s, e;
    for a=1, maxAttempts do
        s, e = pcall(function()
            serverCoordinatorMem:SetAsync(privateServerId, serverInfo, shared.Const.Hour);
        end);

        if s then break end;
        Debugger:Warn(`ServerCoordinator: failed to register server (attempt {a}/{maxAttempts})`, privateServerId, e);
        task.wait((a-1.5)^2);
    end

    if not s then
        Debugger:Warn("ServerCoordinator: gave up registering server", privateServerId, e);
    end
end

function ServerCoordinator:GetCurrentServerInfo(timeOut)
    if ServerCoordinator.CurServerInfo then
        return ServerCoordinator.CurServerInfo;
    end

    local serverId = game.PrivateServerId;
    if serverId == "" then return end;
    Debugger:Warn(`GetCurrentServerInfo {serverId}`);

    local serverInfo;
    for a=0, timeOut or 30 do
        local s, e = pcall(function()
            serverInfo = serverCoordinatorMem:GetAsync(serverId);
        end);
        if s then break; end

        task.wait(1);
    end
    if serverInfo == nil then return end;
    
    ServerCoordinator.CurServerInfo = serverInfo;

    return serverInfo;
end

function ServerCoordinator:RemoveServer(accessCode)
    local s, e = pcall(function()
        serverCoordinatorMem:RemoveAsync(accessCode);
    end);

    if not s then
        Debugger:Warn("ServerCoordinator: failed to remove server", accessCode, e);
    end
end

return ServerCoordinator;
