local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local MISSION_ID = 6;

local MissionLogic = {};
--==

function MissionLogic.onRequire()
	if RunService:IsServer() then
		modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		shared.modEventService:OnInvoked("Players_BindRevive", function(event: EventPacket, ...)
			local playerClass: PlayerClass, dmgData: DamageData = ...;
			if playerClass == nil then return end;

			if dmgData == nil or dmgData.RevivedBy == nil then return end;

			task.spawn(function()
				local reviverPlayerClass: PlayerClass = dmgData.RevivedBy :: PlayerClass;
				if reviverPlayerClass.ClassName ~= "PlayerClass" then return end;

				local reviverPlayer: Player = reviverPlayerClass:GetInstance();
				
				local mission = modMission:GetMission(reviverPlayer, MISSION_ID);
				if mission.Type ~= 1 then return end;
			
				modMission:Progress(reviverPlayer, MISSION_ID, function(mission)
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