local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);
--==

return function(event: EventPacket, ...)
    local playerClass: PlayerClass, dmgData: DamageData = ...;
    if playerClass == nil then return end;

	local deathPosition = playerClass.Properties.DeathPosition;
	
    if dmgData == nil or dmgData.DamageBy == nil then return end;

    task.spawn(function()
        local killerPlayerClass: PlayerClass = dmgData.DamageBy :: PlayerClass;
        if killerPlayerClass.ClassName ~= "PlayerClass" then return end;

        local player: Player = killerPlayerClass:GetInstance();
        
        local profile: ProfileAlmdes = shared.modProfile:Get(player) :: ProfileAlmdes;
        local gameSave: GameSaveAlmdes = profile:GetActiveSave() :: GameSaveAlmdes;

        local killerRunSession: PlayRunSession = gameSave.Session;
        if killerRunSession == nil then return end;

        killerRunSession:AddStat("PlayerKills", 1);
    end)
end;
