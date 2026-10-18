local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);

local MISSION_ID = 1;

local MissionLogic = {};
--==

function MissionLogic.onRequire()
	if RunService:IsServer() then
		modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		shared.modEventService:OnInvoked("Npcs_BindDeath", function(eventPacket: EventPacket, ...)
			local npcClass: NpcClass = ...;
			if npcClass == nil or npcClass.HumanoidType ~= "Bandit" then return end;
		
			task.spawn(function()
				local playerTags = modDamageTag:Get(npcClass.Character, "Player");
				for a=1, #playerTags do
					local playerTag = playerTags[a];
					local player: Player = playerTag.Player;
					if player == nil or not game.Players:IsAncestorOf(player) then continue end;

					if modMission:IsComplete(player, MISSION_ID) then continue end

					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint == 1 then
							mission.SaveData.Kills = mission.SaveData.Kills -1;
							if mission.SaveData.Kills <= 0 then
								mission.ProgressionPoint = 2;
								mission.SaveData.ExfilComplete = true;
							end
						end;
					end)

				end
			end)
		end)
	end
end

return MissionLogic;