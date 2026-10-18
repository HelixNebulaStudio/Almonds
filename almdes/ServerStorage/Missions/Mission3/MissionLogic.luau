local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local MISSION_ID = 3;

local MissionLogic = {};
--==

function MissionLogic.onRequire()
	if RunService:IsServer() then
		modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		shared.modEventService:OnInvoked("Storage_OnOpen", function(eventPacket: EventPacket, ...)
			local storage: Storage, player: Player = ...;
			if storage == nil or player == nil then return end;

			local storageId = storage.Id;
			if storageId:find("carparkraid") == nil then return end;

			task.spawn(function()
				local mission = modMission:GetMission(player, MISSION_ID);
				if mission.Type ~= 1 then return end;
			
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 1 then
						mission.ProgressionPoint = 2;
						mission.SaveData.ExfilComplete = true;
					end;
				end)
			end)

		end)

	end
end

return MissionLogic;