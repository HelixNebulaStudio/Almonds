local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local localPlayer = game.Players.LocalPlayer;

local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modPlayers = shared.require(game.ReplicatedStorage.Library.Players);
local modPlayRunSession = shared.require(game.ReplicatedStorage.Library.PlayRunSession);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

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

        if RunService:IsClient() then
            local deathScreenElement: InterfaceElement = modClientGuis.getElement("DeathScreenElement");
            if deathScreenElement then
                deathScreenElement.Visible = true;
                modClientGuis.ActiveInterface:HideAll();
            end
            
        end
    end)
end)


shared.coreBind(modPlayers.Player, "_character_added", function(playerClass: PlayerClassAlmdes, character: Model)
    if RunService:IsClient() then return end;

    local properties: PropertiesVariable<{}> = playerClass.Properties;
    local player = playerClass:GetInstance();
    
    if properties.PlayRunSession then
        properties.PlayRunSession:Destroy();
    end
    properties.PlayRunSession = modPlayRunSession.new();


    --MARK: Meta Status
    local statusComp: StatusComp = playerClass.StatusComp;

    --Hunger
    local hungerStatusCompApplyParam: StatusCompApplyParam = {
        Values = {
            CurValue = 100;
            MaxValue = 100;
        };
    }
    statusComp:Apply("Hunger", hungerStatusCompApplyParam);

    --Thirst
    local thirstStatusCompApplyParam: StatusCompApplyParam = {
        Values = {
            CurValue = 100;
            MaxValue = 100;
        };
    }
    statusComp:Apply("Thirst", thirstStatusCompApplyParam);

    --Comfort
    local comfortStatusCompApplyParam: StatusCompApplyParam = {
        Values = {
            CurValue = 100;
            MaxValue = 100;
        };
    }
    statusComp:Apply("Comfort", comfortStatusCompApplyParam);
end);

shared.coreBind(modPlayers.Player, "_status_tick_update", function(playerClass: PlayerClassAlmdes, tickData: TickData)
    local player: Player = playerClass:GetInstance();
    if RunService:IsClient() then
        -- not engine implemented
    end

    if RunService:IsServer() and tickData.ms1000 then
        local activeCampfireModels = CollectionService:GetTagged("Campfire");

        local closestCampfire = nil;
        local closestDistance = math.huge;

        for _, campfireModel in pairs(activeCampfireModels) do
            if campfireModel.Parent == nil then continue end;
            if campfireModel.PrimaryPart == nil then continue end;
            
            local campfirePosition = campfireModel:GetPivot().Position;
            local distance = player:DistanceFromCharacter(campfirePosition);

            if distance < closestDistance then
                closestDistance = distance;
                closestCampfire = campfireModel;
            end
        end

        local statusComp: StatusComp = playerClass.StatusComp;
        local campfireStatus = statusComp:GetOrDefault("Campfire");

        local maxCampfireRange = 24;
        if closestCampfire and closestDistance <= maxCampfireRange then
            local campfireConfig = closestCampfire:FindFirstChild("Interactable");
            local isCampfireActive = campfireConfig and campfireConfig:GetAttribute("IsCampfireActive");

            if isCampfireActive then
                statusComp:Apply("Campfire", {
                    Values = {
                        CampfireModel = closestCampfire;
                    };
                    Expires = workspace:GetServerTimeNow() + 2;
                    Duration = 2;
                });
            end
        else
            if campfireStatus then
                campfireStatus.IsExpired = true;
            end
        end
    end
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