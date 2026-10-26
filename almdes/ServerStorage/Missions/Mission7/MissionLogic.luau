local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local MISSION_ID = 7;

local MissionLogic = {};
--==

function MissionLogic.onRequire()
	if RunService:IsServer() then
		modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...)
			local triggerPlayer: Player? = event.Player;
			if triggerPlayer == nil then return end;

			local id: string, interactable: InteractableInstance = ...;

			task.spawn(function()
				if typeof(id) ~= "string" then return end;
				if id:sub(1,9) ~= "SpotRadar" then return end;

				modMission:Progress(triggerPlayer, MISSION_ID, function(mission)
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