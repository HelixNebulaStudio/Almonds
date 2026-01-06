local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local localPlayer = game.Players.LocalPlayer;

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modPlayers = shared.require(game.ReplicatedStorage.Library.Players);
local modPlayRunSession = shared.require(game.ReplicatedStorage.Library:WaitForChild("PlayRunSession"));
local modRaycastUtil = shared.require(game.ReplicatedStorage.Library.Util.RaycastUtil);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

--==
function modPlayers.onRequire()
    if RunService:IsClient() then
        modClientLighting = shared.require(game.ReplicatedStorage.PlayerScripts.ClientLighting);
    end

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

shared.coreBind(modPlayers.Player, "_new", function(playerClass: PlayerClassAlmdes)
    local healthComp: HealthComp = playerClass.HealthComp;
    healthComp:SetCanBeHurtBy();
    
    local player: Player = playerClass:GetInstance();
    local properties: PropertiesVariable<{}> = playerClass.Properties;

    if RunService:IsServer() then
        local profile: ProfileAlmdes = shared.modProfile:Get(player) :: ProfileAlmdes;

        local statusComp: StatusComp = playerClass.StatusComp;

        if modBranchConfigs.CurrentBranch.Name == "Dev" then
            player:SetAttribute("DbTinkerCmds", true);
        end

    elseif RunService:IsClient() then
    end
    
    playerClass.OnIsDeadChanged:Once(function(isDead)
        if not isDead then return end;
        Debugger:Warn(`Dead`);

        if RunService:IsClient() then
            if playerClass.Properties.PlayRunStatus == "Success" then
                modClientLighting:SetAtmosphere("Exfil");

            else
                modClientLighting:SetAtmosphere("Death");

                local deathScreenElement: InterfaceElement = modClientGuis.getElement("DeathScreenElement");
                if deathScreenElement then
                    deathScreenElement.Visible = true;
                    modClientGuis.ActiveInterface:HideAll();
                end
            end

        elseif RunService:IsServer() then
            --
        end
    end)
end)


shared.coreBind(modPlayers.Player, "_character_added", function(playerClass: PlayerClassAlmdes, character: Model)
    local wieldComp = playerClass.WieldComp;
    wieldComp.TargetableTags.Bandit = true;

    if RunService:IsClient() then return end;

    local properties: PropertiesVariable<{}> = playerClass.Properties;
    local player = playerClass:GetInstance();
    
    local humanoid: Humanoid = playerClass.Humanoid;
    humanoid.HealthDisplayDistance = 0;

    if properties.PlayRunSession then
        properties.PlayRunSession:Destroy();
    end
    properties.PlayRunSession = modPlayRunSession.new(playerClass);

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

    local profile: ProfileAlmdes = shared.modProfile:Get(player) :: ProfileAlmdes;
    local gameSave: GameSaveAlmdes = profile:GetActiveSave() :: GameSaveAlmdes;

	for storageId, storage: Storage in pairs(gameSave.Storages) do
		storage:Wipe();
		Debugger:Warn(`Wiped storage: {storageId}`);
	end
    gameSave.LoadoutSaves:LoadActiveLoadout();

end);

shared.coreBind(modPlayers.Player, "_status_tick_update", function(playerClass: PlayerClassAlmdes, tickData: TickData)
    local player: Player = playerClass:GetInstance();
    if RunService:IsClient() then
        -- not engine implemented
    end

    if RunService:IsServer() and tickData.ms1000 then
        local statusComp: StatusComp = playerClass.StatusComp;
        local campfirePackage = statusComp.getPackage("Campfire");

        local activeCampfireModels = CollectionService:GetTagged("Campfire");

        local closestCampfire = nil;
        local closestDistance = math.huge;

        for _, campfireModel in pairs(activeCampfireModels) do
            if campfireModel.Parent == nil then continue end;
            if campfireModel.PrimaryPart == nil then continue end;
            
            local fireAtt = campfireModel.PrimaryPart:FindFirstChild("_naturalLight");
            if fireAtt == nil then continue end;

            local campfirePosition = fireAtt.WorldPosition;
            local distance = player:DistanceFromCharacter(campfirePosition);
            if distance < closestDistance then
                local hitParts, partsChecked = modRaycastUtil.GetHittable(
                    campfirePosition,
                    campfirePackage.BuffDistance,
                    playerClass.Character,
                    1
                );
                if #hitParts <= 0 then continue end;

                closestDistance = distance;
                closestCampfire = campfireModel;
            end
        end

        local campfireStatus = statusComp:GetOrDefault("Campfire");

        if closestCampfire and closestDistance <= campfirePackage.BuffDistance then
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

return modPlayers;