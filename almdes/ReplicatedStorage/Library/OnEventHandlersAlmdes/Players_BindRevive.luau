local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);
--==

return function(event: EventPacket, ...)
    local playerClass: PlayerClass, dmgData: DamageData = ...;
    if playerClass == nil then return end;

    if dmgData == nil or dmgData.RevivedBy == nil then return end;

    task.spawn(function()
        local reviverPlayerClass: PlayerClass = dmgData.RevivedBy :: PlayerClass;
        if reviverPlayerClass.ClassName ~= "PlayerClass" then return end;

        local player: Player = reviverPlayerClass:GetInstance();
        
        local profile: ProfileAlmdes = shared.modProfile:Get(player) :: ProfileAlmdes;
        local gameSave: GameSaveAlmdes = profile:GetActiveSave() :: GameSaveAlmdes;

        local reviverRunSession: PlayRunSession = gameSave.Session;
        if reviverRunSession == nil then return end;

        reviverRunSession:AddStat("PlayersRevived", 1);
    end)
end;
