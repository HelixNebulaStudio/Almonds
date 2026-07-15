local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

if RunService:IsServer() then
    modServerCoordinator = shared.require(game.ServerScriptService.ServerLibrary.ServerCoordinator);

end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassAlmdes).new();
--==

function WorldCore.onRequire()
    if RunService:IsServer() then
        local spawnLocations = workspace.SpawnLocations:GetChildren();
        for a=1, #spawnLocations do
            local part = spawnLocations[a];
            part.Name = a;
        end

        shared.modPlayers.OnPlayerSpawn:Connect(function(playerClass: PlayerClass)
            local player: Player = playerClass:GetInstance();
            local profile: ProfileAlmdes = shared.modProfile:Get(player) :: ProfileAlmdes;

            local partyIndex = player:GetAttribute("PartyIndex") or 1;
            local setSpawnCFrame = nil;
            
            local spawnPart = spawnLocations[partyIndex] or workspace:FindFirstChildWhichIsA("SpawnLocation");

            local worldSpaceSize = spawnPart.CFrame:vectorToWorldSpace(spawnPart.Size);
            worldSpaceSize = Vector3.new(math.abs(worldSpaceSize.X), math.abs(worldSpaceSize.Y), math.abs(worldSpaceSize.Z));

            local newSpawnCFrame = spawnPart.CFrame * CFrame.new(
                math.random(-worldSpaceSize.X*10/20, worldSpaceSize.X*10/20), 
                2.35, 
                math.random(-worldSpaceSize.Z*10/20, worldSpaceSize.Z*10/20)
            );
            setSpawnCFrame = newSpawnCFrame;

            profile.SpawnCFrame = setSpawnCFrame;
            playerClass.SpawnCFrame = setSpawnCFrame;

            task.delay(0, function()
                playerClass:SetCFrame(setSpawnCFrame)
            end)
        end)

        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            local profile: ProfileAlmdes = shared.modProfile:WaitForProfile(player) :: ProfileAlmdes;
            if profile == nil then return end;

            Debugger:Warn(`{player.Name} has joined the world!`);
            
            local serverInfo = modServerCoordinator:GetCurrentServerInfo();
            if serverInfo == nil then
                Debugger:Warn(`Missing server info`);
                return;
            end
            local gameLobby = serverInfo;

            local modWorldEvents = shared.require(game.ServerScriptService.ServerLibrary.WorldEvents);
            modWorldEvents.GlobalProperties.Tutorial = gameLobby.Values.IsTutorial == true;

            local expectedUserIds = gameLobby.UserIds;

            local adminByPass = player.UserId == 16170943;
            if not adminByPass and table.find(expectedUserIds, player.UserId) == nil then
                player:Kick(`You are not allowed to be on this server.`);
                return
            end;

            local parties = gameLobby.Parties;
            local playerPlayer = nil;

            for a=1, #parties do
                local party = parties[a];
                if table.find(party.UserIds, player.UserId) == nil then continue end;
                party.Index = a;
                playerPlayer = party;
                break;
            end

            local partyIndex = playerPlayer.Index;
            player:SetAttribute("PartyIndex", partyIndex);

            local curTime = os.time();
            local playerClass: PlayerClass = shared.modPlayers.get(player);

            if WorldCore.GameStartTime == nil then
                WorldCore.GameStartTime = curTime + 10;
            end;

            if curTime > WorldCore.GameStartTime then
                local lateStartTime = WorldCore.GameStartTime+3;
                for a=1, 3, 0.5 do
                    profile:GuiAction("onconnecttimedown", lateStartTime);
                    task.wait(0.5);
                end
            end
            while os.time() < WorldCore.GameStartTime do
                profile:GuiAction("onconnecttimedown", WorldCore.GameStartTime);
                task.wait(0.5);
            end

            Debugger:Warn(`Spawn player`);
            playerClass:Spawn();

        end, 999);
    end

    shared.modEventService:OnInvoked("Interactables_BindButtonInteract", function(eventPacket: EventPacket, ...)
        local interactable: InteractableInstance = ...;
        local variantId = interactable.Variant;

        Debugger:StudioLog("Interactables_BindButtonInteract eventPacket", eventPacket, "interactable", interactable);
    end)
end


return WorldCore;