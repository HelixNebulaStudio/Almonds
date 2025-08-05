local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modPlayers = shared.require(game.ReplicatedStorage.Library.Players);

if RunService:IsServer() then

end
--==


shared.coreBind(modPlayers.Player, "_new", function(playerClass: PlayerClassAlmdes)
    local healthComp: HealthComp = playerClass.HealthComp;
    healthComp:SetCanBeHurtBy();
    
    local player: Player = playerClass:GetInstance();
    local properties: PropertiesVariable<{}> = playerClass.Properties;

    if RunService:IsServer() then
        local profile: ProfileAlmdes = shared.modProfile:Get(player) :: ProfileAlmdes;

        local statusComp: StatusComp = playerClass.StatusComp;

    elseif RunService:IsClient() then
    end
    
    playerClass.OnIsDeadChanged:Once(function(isDead)
        if not isDead then return end;
        Debugger:Warn(`Dead`);
    end)
end)


shared.coreBind(modPlayers.Player, "_character_added", function(playerClass: PlayerClassAlmdes, character: Model)
    if RunService:IsClient() then return end;

    local player = playerClass:GetInstance();
    
    --MARK: Meta Status
    local statusComp: StatusComp = playerClass.StatusComp;

    --Hunger
    local hungerStatusCompApplyParam: StatusCompApplyParam = {
        Values = {
            CurValue = 75;
            MaxValue = 100;
        };
    }
    statusComp:Apply("Hunger", hungerStatusCompApplyParam);

    --Thirst
    local thirstStatusCompApplyParam: StatusCompApplyParam = {
        Values = {
            CurValue = 85;
            MaxValue = 100;
        };
    }
    statusComp:Apply("Thirst", thirstStatusCompApplyParam);

    --Comfort
    local comfortStatusCompApplyParam: StatusCompApplyParam = {
        Values = {
            CurValue = 95;
            MaxValue = 100;
        };
    }
    statusComp:Apply("Comfort", comfortStatusCompApplyParam);
end);

shared.coreBind(modPlayers.Player, "_status_tick_update", function(playerClass: PlayerClassAlmdes, tickData: TickData)

end);

function modPlayers.onRequire()
	shared.modCommandsLibrary.bind{
		["playeralmdes"] = {
			Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
			Description = [[Player commands for Almonds.
            
            /playeralmdes sethunger [val]
            /playeralmdes setthirst [val]
            ]];

			RequiredArgs = 0;
			UsageInfo = "/playeralmdes action [args]";
			Function = function(player, args)
				local playerClass: PlayerClass = modPlayers.get(player);
				local actionId = args[1];

                if actionId == "sethunger" then
                    local hungerStatus = playerClass.StatusComp:GetOrDefault("Hunger");
					hungerStatus:Func("SetValue", tonumber(args[2]) or 100);

                elseif actionId == "setthirst" then
                    local thirstStatus = playerClass.StatusComp:GetOrDefault("Thirst");
					thirstStatus:Func("SetValue", tonumber(args[2]) or 100);
                end

				return true;
			end;
			ClientFunction = function(player, args)
				local playerClass: PlayerClass = modPlayers.get(player);
				local actionId = args[1];

				return;
			end;
		};
	};
end

return modPlayers;