local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modProfile = shared.require(game.ServerScriptService.ServerLibrary.Profile);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManagerAlmdes);

--==
local function OnPlayerAdded(player: Player)
	Debugger:Log("Initializing player (",player,")");

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local profile: ProfileAlmdes = modProfile.new(player);
	
	if #profile.Saves <= 0 then
        profile:NewCustomSave();
    end

	local gameSave: GameSaveAlmdes = profile:GetActiveSave();
	
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

	
	playerClass.Died:Connect(function(character, dieReason)
		Debugger:Warn("Died:Connect>> Fired", character, dieReason);

		playerClass.Properties.Ragdoll = 1;
		playerClass.Humanoid.PlatformStand = true;
		
		ModEngine.OnPlayerDied(player, dieReason);
	end)
end

shared.coreBind(modProfile, "_new", function(profile: ProfileAlmdes, player: Player)
    
end)

shared.coreBind(modProfile, "_key_load", function(profile: ProfileAlmdes, key: string, data: any, loadOverwrite: anydict?)
    if key == "" then
        profile[key]:Load(data);
        return true;
    end

    return false;
end)

function modProfile.onRequire()
    shared.modEngineCore:ConnectOnPlayerAdded(script, OnPlayerAdded);

    local remoteMainMenu = modRemotesManager:Get("MainMenuRemote");
    function remoteMainMenu.OnServerInvoke(player, action, paramPacket)
        if remoteMainMenu:Debounce(player) then return end;

        local classPlayer = shared.modPlayers.get(player);
        
        local replyPacket = {};
        
        if action == "deploy" then
            classPlayer:Spawn();
            replyPacket.Success = true;
            
        end
        return replyPacket;
    end

end

return modProfile;