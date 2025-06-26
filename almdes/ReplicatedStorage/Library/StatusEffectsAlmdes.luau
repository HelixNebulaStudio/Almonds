local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
--==

function modStatusEffects.onRequire()
    if RunService:IsServer() then
    elseif RunService:IsClient() then
    end
end

function modStatusEffects.Dizzy(player: Player, duration: number, dizzyType)
	duration = duration or 1;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

    statusComp:Apply("Dizzy", {
		ExpiresOnDeath = true;
		Expires = workspace:GetServerTimeNow() + duration;
		Duration = duration;

        Values = {
            Amount = duration;
            DizzyType = dizzyType;
        }
    });
end

return modStatusEffects;