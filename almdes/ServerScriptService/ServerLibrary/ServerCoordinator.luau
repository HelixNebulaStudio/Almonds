local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local MemoryStoreService = game:GetService("MemoryStoreService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurationsAlmdes);
local modCrossServerSignals = shared.require(game.ServerScriptService.ServerLibrary.CrossServerSignals);
local modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);

local serverCoordinatorMem: MemoryStoreHashMap;

local ServerCoordinator = {};
ServerCoordinator.CurServerInfo = nil;
ServerCoordinator.RecentServers = nil;
ServerCoordinator._lastJoinLookup = {};  -- [serverId] = last MemoryStore lookup time

local RECENT_SERVERS_CAP = 20;
local RECENT_SERVERS_MAX_AGE = 1200;
local JOIN_LOOKUP_RETRY = 10;

--==
function ServerCoordinator.onRequire()
    serverCoordinatorMem = MemoryStoreService:GetHashMap(`GlobalServers`);

    local worldInfo = modBranchConfigurations.WorldInfo;
    local isLobbyServer = worldInfo and worldInfo.WorldType == 1;  -- WORLD_TYPES.Game
    if not isLobbyServer then
        game:BindToClose(function()
            if RunService:IsStudio() then return end;

            ServerCoordinator:RemoveServer();
            task.wait(1);
        end);
        
        return;
    end;

    ServerCoordinator.RecentServers = {};


    local registrySignal = modCrossServerSignals.new("ServerRegistry");
    registrySignal:Connect(function(action, info)
        if action == "newserver" then
            table.insert(ServerCoordinator.RecentServers, info);
            if #ServerCoordinator.RecentServers > RECENT_SERVERS_CAP then
                table.remove(ServerCoordinator.RecentServers, 1);  -- FIFO cap
            end

        elseif action == "serverremoved" then
            for i, s in ipairs(ServerCoordinator.RecentServers) do
                if s.Id == info.Id then
                    table.remove(ServerCoordinator.RecentServers, i);
                    break;
                end
            end

        elseif action == "serverupdate" then
            for _, s in ipairs(ServerCoordinator.RecentServers) do
                if s.Id == info.Id or s.AccessCode == info.AccessCode then
                    if info.PlayerCount ~= nil then s.PlayerCount = info.PlayerCount; end
                    if info.CanJoinInProgress ~= nil then s.CanJoinInProgress = info.CanJoinInProgress; end
                    break;
                end
            end
        end
    end);
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
        return;
    end

    -- Broadcast a trimmed payload so peer lobby servers can cache it for late-join.
    if ServerCoordinator.RecentServers ~= nil then
        local trimmed = self:Shrink(serverInfo, privateServerId);
        local ok, err = pcall(function()
            modCrossServerSignals.new("ServerRegistry"):Fire("newserver", trimmed);
        end);
        if not ok then
            Debugger:Warn("ServerCoordinator: failed to broadcast newserver", err);
        end
    end
end

function ServerCoordinator:Shrink(serverInfo, privateServerId)
    local values = serverInfo.Values or {};
    return {
        Id = privateServerId;
        AccessCode = serverInfo.AccessCode;
        PlayerCount = #(serverInfo.UserIds or {});
        CanJoinInProgress = values.CanJoinInProgress;
        PartyCount = #(serverInfo.Parties or {});
        Region = serverInfo.Region;
        StartTime = values.StartTime;
        GraceUntil = values.GraceUntil;
        Slots = serverInfo.Slots;
    };
end

function ServerCoordinator:FindJoinableServer(region, excludeIds, partySize)
    if ServerCoordinator.RecentServers == nil then return nil end;  -- not a lobby server

    partySize = partySize or 1;
    local now = os.time();
    local candidates = {};

    for i = #ServerCoordinator.RecentServers, 1, -1 do
        local s = ServerCoordinator.RecentServers[i];
        if now - (s.StartTime or 0) > RECENT_SERVERS_MAX_AGE then
            table.remove(ServerCoordinator.RecentServers, i);  -- 20-min lazy drop

        elseif s.CanJoinInProgress
            and now < (s.GraceUntil or 0)
            and (s.PlayerCount or 0) + partySize <= (s.Slots or 0)
            and s.Region == region
            and not table.find(excludeIds or {}, s.Id) then
            table.insert(candidates, s);

        end
    end

    if #candidates == 0 then return nil end;

    local best = candidates[1];

    -- Only retry this server's MemoryStore lookup at most once per JOIN_LOOKUP_RETRY seconds (per best.Id).
    if now - (ServerCoordinator._lastJoinLookup[best.Id] or 0) >= JOIN_LOOKUP_RETRY then
        ServerCoordinator._lastJoinLookup[best.Id] = now;
        local ok, full = pcall(function()
            return serverCoordinatorMem:GetAsync(best.Id);
        end);
        if ok and full then
            best.PlayerCount = #(full.UserIds or {});
            best.CanJoinInProgress = full.Values and full.Values.CanJoinInProgress;
            if not best.CanJoinInProgress
                or (best.PlayerCount + partySize) > (best.Slots or 0) then
                return nil;  -- re-validate failed; fall through to normal queue
            end
        end
    end

    return best.AccessCode;
end

function ServerCoordinator:SyncServerUpdate()
	local serverInfo = ServerCoordinator.CurServerInfo;
	if serverInfo == nil then return end;
	local accessCode = serverInfo.AccessCode;
	if accessCode == nil then return end;

	local s, e = pcall(function()
		serverCoordinatorMem:UpdateAsync(game.PrivateServerId, function(old)
			old = old or serverInfo;
			old.UserIds = serverInfo.UserIds;
			old.Values = serverInfo.Values;
			return old;
		end, RECENT_SERVERS_MAX_AGE+60);
	end);
    if not s then Debugger:Warn("Failed to update server coordinator GlobalServers.", e); end

    if ServerCoordinator.RecentServers == nil then return end;
    
    local s, e = pcall(function()
        modCrossServerSignals.new("ServerRegistry"):Fire("serverupdate", {
            Id = game.PrivateServerId;
            AccessCode = accessCode;
            PlayerCount = #(serverInfo.UserIds or {});
            CanJoinInProgress = serverInfo.Values and serverInfo.Values.CanJoinInProgress;
        });
    end);
    if not s then
        Debugger:Warn("ServerCoordinator: failed to broadcast serverupdate", e);
    end
    
end

function ServerCoordinator:JoinServer(accessCode, userIds)
    local ok, err = pcall(function()
        modCrossServerSignals.new("MatchMaking"):Fire("joinserver", userIds, accessCode);
    end);
    if not ok then
        Debugger:Warn("ServerCoordinator: failed to request join", err);
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

function ServerCoordinator:RemoveServer()
    local privateServerId = game.PrivateServerId;
    local s, e = pcall(function()
        serverCoordinatorMem:RemoveAsync(privateServerId);
    end);

    if not s then
        Debugger:Warn("ServerCoordinator: failed to remove server", privateServerId, e);
        return;
    end

    if ServerCoordinator.RecentServers ~= nil then
        local ok, err = pcall(function()
            modCrossServerSignals.new("ServerRegistry"):Fire("serverremoved", {
                Id = privateServerId;
            });
        end);
        if not ok then
            Debugger:Warn("ServerCoordinator: failed to broadcast serverremoved", err);
        end
    end
end

return ServerCoordinator;
