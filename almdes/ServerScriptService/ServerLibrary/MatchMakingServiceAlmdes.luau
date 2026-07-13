local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modCrossServerSignals = shared.require(game.ServerScriptService.ServerLibrary.CrossServerSignals);
local modMatchMakingService = shared.require(game.ServerScriptService.ServerLibrary.MatchMakingService);
local modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);

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

	modMatchMakingService:BindLobbyFormed(function(gameLobby)
		Debugger:Warn(`Preparing server`);
			
		local reserveAccessCode = modServerManager:CreatePrivateServer("Genesis");
		crossServerSignal:Fire("joinserver", gameLobby.UserIds, reserveAccessCode);
	end)


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

return modMatchMakingService;
