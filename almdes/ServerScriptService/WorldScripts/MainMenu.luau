local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassAlmdes).new();
--==

function WorldCore.onRequire()
    if RunService:IsServer() then

        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            local playerClass: PlayerClass = shared.modPlayers.get(player);

            local isSafehome = modConfigurations.SafehomeMode;
            if isSafehome then
                playerClass:Spawn();
            end

            local profile: ProfileAlmdes = shared.modProfile:WaitForProfile(player) :: ProfileAlmdes;
            if profile == nil then return end;

        end, 999);

    end
end


return WorldCore;