local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManagerAlmdes);

local modProfile = shared.require(game.ServerScriptService.ServerLibrary.Profile);
local modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
local modMatchMakingService = shared.require(game.ServerScriptService.ServerLibrary.MatchMakingService);

--==
local function OnPlayerAdded(player: Player)
	Debugger:Log("Initializing player (",player,")");

	local profile: ProfileAlmdes = modProfile.new(player);
	local gameSave: GameSaveAlmdes = profile:GetActiveSave() :: GameSaveAlmdes;
	
	--== Auto-save cycle;
	task.spawn(function()
		repeat
			if profile and (os.time() - profile.LastOnline) > 300 then
				profile.LastOnline = os.time();
				--profile:Save(); -- Auto save
			end
		until modProfile:Find(player.Name) == nil or not task.wait(60);
	end)

	profile:InitMessaging();
	profile:Sync();
	
	local spawnLocations = CollectionService:GetTagged("SpawnLocations");
	player.ReplicationFocus = spawnLocations[math.random(1, #spawnLocations)];

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	playerClass.OnIsDeadChanged:Connect(function(isDead, dieReason)
		if not isDead then return end;
		Debugger:Warn("Player died: ", dieReason);
		
	end)

    player.CharacterRemoving:Connect(function()
        Debugger:Warn(`Player ({player.Name}) returned to menu.`);
	    --player.ReplicationFocus = spawnLocations[math.random(1, #spawnLocations)];
    end)
end

shared.coreBind(modProfile, "_new", function(profile: ProfileAlmdes, player: Player)
    
end)

shared.coreBind(modProfile, "_key_load", function(profile: ProfileAlmdes, key: string, data: any, loadOverwrite: anydict?)
    -- if key == "" then
    --     profile[key]:Load(data);
    --     return true;
    -- end
    return false;
end)

shared.coreBind(modProfile, "_save", function(profile: ProfileAlmdes, overrideData: any?, force: boolean?)
    local gameSave: GameSaveAlmdes = profile:GetActiveSave() :: GameSaveAlmdes;
    
end)

function modProfile.onRequire()
    shared.modEngineCore:ConnectOnPlayerAdded(script, OnPlayerAdded);

    local remoteMainMenu = modRemotesManager:Get("MainMenuRemote");
    function remoteMainMenu.OnServerInvoke(player: Player, action, paramPacket)
        if remoteMainMenu:Debounce(player) then return end;

        local playerClass: PlayerClass = shared.modPlayers.get(player);
        
        local replyPacket = {};
        
        if action == "playtutorial" then

			local reserveAccessCode = modServerManager:CreatePrivateServer("Genesis");
            local teleportData = modServerManager:CreateTeleportData();
            teleportData.Tutorial = true;
            Debugger:Warn("hqAccessCode", reserveAccessCode);
            modServerManager:TeleportToPrivateServer("Genesis", reserveAccessCode, {player}, teleportData);

            replyPacket.Success = true;
            
        elseif action == "quickplay" then

            local userId = player.UserId;
            local partyObj = {
                Region = modMatchMakingService:GetServerRegion(player);
                QueueType = "Default";
                Players = {userId};
                Values = {
                    LocalSearchTimeLimit=30
                };
            };
            local sucess, partyId = modMatchMakingService:QueueParty(partyObj);
            
            if sucess then
                player:SetAttribute("IsInQueue", partyId);
                replyPacket.Success = true;
                replyPacket.NewState = modMatchMakingService:GetPlayerState(userId);

            else
                player:SetAttribute("IsInQueue", nil);
                replyPacket.Failmsg = "Failed to queue";

            end

        elseif action == "rescuerequest" then
            if playerClass.Properties.LastRescueRequest and tick() - playerClass.Properties.LastRescueRequest < 30 then
                return replyPacket;
            end

            local playersInRange = {};
            for _, oPlayer in pairs(game.Players:GetPlayers()) do
                if oPlayer == player then continue end;
                if oPlayer:DistanceFromCharacter(playerClass.RootPart.Position) > 256 then continue end;
                table.insert(playersInRange, oPlayer);
            end

            local helpMsg = `A player near you needs help!`;
			shared.Notify(playersInRange, `<b><font size="18" color="#d4bb6c">{helpMsg}</font></b>`, "Message", `rescuealert`);
			shared.Notify(player, `Rescue alert radioed to nearby players.`, "Inform");
            replyPacket.Success = true;

        elseif action == "endrun" then
            -- run failed;
            local playRunSession = playerClass.Properties.PlayRunSession;

            playRunSession:EndRun("Failed", "Died");
            replyPacket.RunSummary = playRunSession:GetSummary();

            replyPacket.Success = true;
        
        elseif action == "returnmenu" then
            playerClass:Despawn();
            replyPacket.Success = true;

        end
        return replyPacket;
    end

    modMatchMakingService.OnPlayerStateUpdate:Connect(function(userId, newState)
        local player = game.Players:GetPlayerByUserId(userId);
        if player == nil then return end;

        local profile = shared.modProfile:Get(player);
        profile:GuiAction("queueupdate", newState);
    end)
end

return modProfile;