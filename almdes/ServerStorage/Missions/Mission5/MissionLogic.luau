local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local MISSION_ID = 5;

local MissionLogic = {};
--==

function MissionLogic.onRequire()
	if RunService:IsServer() then
		modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		shared.modEventService:OnInvoked("Players_BindDeath", function(eventPacket: EventPacket, ...)
			local victimPlayerClass: PlayerClass, damageData: DamageData = ...;
			if damageData == nil then return end;

			task.spawn(function()
				local damageBy: EntityClass? = damageData.DamageBy;
				if damageBy == nil or damageBy.ClassName ~= "PlayerClass" then return end;

				local killerPlayerClass: PlayerClass = (damageBy :: PlayerClass);
				local killerPlayer: Player = killerPlayerClass:GetInstance();

				local mission = modMission:GetMission(killerPlayer, MISSION_ID);
				if mission.Type ~= 1 then return end;
			
				modMission:Progress(killerPlayer, MISSION_ID, function(mission)
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