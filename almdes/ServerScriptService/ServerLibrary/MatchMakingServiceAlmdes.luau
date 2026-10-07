local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");
local ConfigService = game:GetService("ConfigService");

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurationsAlmdes);

local modCrossServerSignals = shared.require(game.ServerScriptService.ServerLibrary.CrossServerSignals);
local modMatchMakingService = shared.require(game.ServerScriptService.ServerLibrary.MatchMakingService);
local modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
local modServerCoordinator = shared.require(game.ServerScriptService.ServerLibrary.ServerCoordinator);


local SERVER_TYPES = {
	Default = {
		CanJoinInProgress = true;
	};
};
--==

function modMatchMakingService.onRequire()
	local crossServerSignal = modCrossServerSignals.new("MatchMaking");

	local function joinServer(gameLobbyUserIds, reserveAccessCode)
		local teleportData = modServerManager:CreateTeleportData();

		local localPlayers = {};
		for _, player in ipairs(game.Players:GetPlayers()) do
			if table.find(gameLobbyUserIds, player.UserId) == nil then continue end;
			table.insert(localPlayers, player);
		end

		modServerManager:TeleportToPrivateServer("Genesis", reserveAccessCode, localPlayers, teleportData);
	end

	crossServerSignal:Connect(function(action, ...)
		Debugger:Warn(`MatchMaking CS event:`, action, ...);

		if action == "joinserver" then
			local gameLobbyUserIds, serverCode = ...;
			joinServer(gameLobbyUserIds, serverCode);
		end
	end)

	local function GetExtractionInfilGracePeriod()
		local graceSeconds = 300;
		local s, e = pcall(function()
			local config = ConfigService:GetConfigAsync();
			local value = config:GetValue("ExtractionInfilGracePeriod");
			if type(value) == "number" then
				graceSeconds = value;
			end
		end);
		if not s then
			Debugger:Warn("Failed to read ExtractionInfilGracePeriod config", e);
		end
		return graceSeconds;
	end

	modMatchMakingService:BindLobbyFormed(function(gameLobby)
		Debugger:Warn(`Preparing server`);

		local reserveAccessCode, privateServerId = modServerManager:CreatePrivateServer("Genesis");

		gameLobby.AccessCode = reserveAccessCode;
		gameLobby.Values = gameLobby.Values or {};

		local queueType = gameLobby.QueueType;
		local config = SERVER_TYPES[queueType];
		if config and config.CanJoinInProgress then
			gameLobby.Values.GraceUntil = os.time() + GetExtractionInfilGracePeriod();
			gameLobby.Values.StartTime = os.time();
			gameLobby.Values.CanJoinInProgress = true;

		else
			gameLobby.Values.CanJoinInProgress = false;
		end
		gameLobby.Values.JoinedCount = 0;

		modServerCoordinator:NewServer(privateServerId, gameLobby);

		crossServerSignal:Fire("joinserver", gameLobby.UserIds, reserveAccessCode);
	end)

	shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
		local worldInfo = modBranchConfigurations.WorldInfo;
		local worldType = worldInfo.WorldType;
		if worldType ~= 1 then Debugger:Warn(`Not game world`); return; end;

		local serverInfo = modServerCoordinator:GetCurrentServerInfo(30);
		if serverInfo == nil and RunService:IsStudio() then
			serverInfo = {
				LobbyId = `studio-{HttpService:GenerateGUID(false)}`;
				UserIds = {16170943; -1; -2; -3};
				Parties = {
					{
						PartyId = "test-party1";
						Queue = "LOCAL";
						UserIds = {16170943};
						Values = {
							LocalSearchTimeLimit = 30;
						};
						JoinTimestamp = os.time()-math.random(60, 120);
						Region = "US";
						QueueType = "Default";
					};
					{
						PartyId = "test-party2";
						Queue = "LOCAL";
						UserIds = {-1; -2; -3};
						Values = {
							LocalSearchTimeLimit = 30;
						};
						JoinTimestamp = os.time()-math.random(60, 120);
						Region = "US";
						QueueType = "Default";
					};
				};
				Slots = 4;
				Values = {};
			};

		elseif serverInfo == nil then
			Debugger:Warn(`Server missing info.`)
			return;
		end
		modServerCoordinator:SetCurrentServerInfo(serverInfo);
	end);

    shared.modCommandsLibrary.bind{
		["mmalmdes"]={
			Permission = shared.modCommandsLibrary.PermissionLevel.Admin;
			Description = [[Matchmaking Admin / test harness.
			/mmalmdes <u>t</u>est<u>j</u>oin<u>s</u>erver  -- test join server
			]];

			RequiredArgs = 0;
			UsageInfo = "/mm action [args]";
			Function = function(speaker: Player, args)
				local player = speaker;
				local actionId = args[1];

				if actionId == "testjoinserver" or actionId == "tjs" then
					local reserveAccessCode = modServerManager:CreatePrivateServer("Genesis");
					crossServerSignal:Fire("joinserver", {player.UserId}, reserveAccessCode);

				else
					Debugger:Log("MatchMaking: unknown action", tostring(actionId));
				end

				return true;
			end
		};
    };

end

function modMatchMakingService:SetCanJoinInProgress(gameLobby, value)
	gameLobby.Values.CanJoinInProgress = value;
	if value == false then
		modServerCoordinator:RemoveServer();
	end
end

return modMatchMakingService;
