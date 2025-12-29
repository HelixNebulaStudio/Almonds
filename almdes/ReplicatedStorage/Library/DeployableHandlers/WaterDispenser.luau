local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modScheduler = shared.require(game.ReplicatedStorage.Library.Scheduler);

local deployablePackage = {
    Type = "WaterDispenser";

    ActiveList = {};
    DebrisList = {};

    Scheduler = nil;
};

local SCAN_RANGE = 32;

local overlapParams = OverlapParams.new();
overlapParams.FilterType = Enum.RaycastFilterType.Include;
--==
local function getInteractablesInRange(pivotCf: CFrame, filterType)
    overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("InteractablePart");
    
    local pivotPos = pivotCf.Position;
    local partsInRange = workspace:GetPartBoundsInRadius(pivotPos, SCAN_RANGE, overlapParams);
    
    local interactables = {};
    for a=1, #partsInRange do
        local heightDif = math.abs(pivotPos.Y - partsInRange[a].Position.Y);
        if heightDif >= 4 then continue end;

        local interactableOfPart: InteractableInstance = modInteractables.getByPart(partsInRange[a]);
        if interactableOfPart == nil or interactableOfPart.Type ~= filterType then continue end;

        table.insert(interactables, interactableOfPart);
    end

    return interactables;
end


function deployablePackage.onRequire()
    if RunService:IsClient() then return end;
    local scheduler: Scheduler = modScheduler.new("WaterDispenserScheduler", 1);
    deployablePackage.Scheduler = scheduler;
    
    local pipePrefabs = game.ServerStorage.Prefabs:WaitForChild("Misc"):WaitForChild("PipeAndSprinklers");

    local function onTick(tickData: TickData)
        for _, dispenserData in pairs(deployablePackage.ActiveList) do
            local dispenserInteractable: InteractableInstance = modInteractables.getOrNew(dispenserData.InteractableConfig);
            local planterConfigs = dispenserInteractable.Values.PlanterConfigs;

            for a=1, #planterConfigs do
                local planterConfig: Configuration = planterConfigs[a];
                local planterInteractable: InteractableInstance = modInteractables.getOrNew(planterConfig);

                if planterInteractable == nil then continue end;
                if planterInteractable.Type ~= "Planter" then continue end;
                if planterInteractable.Values.Water >= planterInteractable.Values.WaterCapacity then continue end;
                if planterInteractable.Values.LastWaterReceived + 1 >= workspace:GetServerTimeNow() then continue end;

                planterInteractable.Values.LastWaterReceived = workspace:GetServerTimeNow();
                planterInteractable.Values.Water = math.clamp(planterInteractable.Values.Water + 1, 0, planterInteractable.Values.WaterCapacity);
            
                local debrisModel: Model = deployablePackage.DebrisList[planterConfig];
                if debrisModel == nil then 
                    debrisModel = Instance.new("Model");
                    debrisModel.Name = "WaterDispenserDebris";
                    debrisModel.Parent = workspace.Debris;
                    deployablePackage.DebrisList[planterConfig] = debrisModel;

                    planterConfig.Destroying:Connect(function()
                        debrisModel:Destroy();
                        deployablePackage.DebrisList[planterConfig] = nil;
                    end)

                    local PathfindingService: PathfindingService = game:GetService("PathfindingService");
                    local path: Path = PathfindingService:CreatePath({
                        AgentRadius = 1;
                        AgentHeight = 4;
                        AgentCanJump = false;
                        WaypointSpacing = math.huge;
                    });

                    debrisModel:GetAttributeChangedSignal("Update"):Connect(function()
                        if debrisModel:GetAttribute("Update") ~= true then return end;
                        Debugger:StudioWarn(`Update dispenser piping`);
                        if RunService:IsStudio() then
                            debrisModel:SetAttribute("Update", false);
                        else
                            debrisModel:SetAttribute("Update", nil);
                        end
                        debrisModel:ClearAllChildren();

                        local dispenserRootAtt = dispenserInteractable.Part:FindFirstChild("Root");
                        local planterPrimaryPart = planterInteractable.Part;

                        path:ComputeAsync(
                            dispenserRootAtt.WorldPosition,
                            planterPrimaryPart.Position
                        );
                        if path.Status ~= Enum.PathStatus.Success then return end;

                        local waypoints = path:GetWaypoints();
                        local pipePivots = {};
                        for b=1, #waypoints do
                            local waypoint = waypoints[b];

                            if RunService:IsStudio() then
                                local dbPart = Debugger:PointPart(waypoint.Position);
                                dbPart.Name = b;
                                dbPart.Color = Color3.fromRGB(255, 0, 0);
                                if waypoint.Action == Enum.PathWaypointAction.Jump then
                                    dbPart.Color = Color3.fromRGB(0, 255, 0);
                                end
                                dbPart.Size = Vector3.one * 0.01;
                                dbPart.Parent = debrisModel;
                            end

                            local raycastParams = RaycastParams.new();
                            raycastParams.FilterType = Enum.RaycastFilterType.Include;
                            raycastParams.FilterDescendantsInstances = {workspace.Environment.Game.Foundations;};

                            local wpPosition = waypoint.Position;
                            local floorRayResult = workspace:Raycast(wpPosition, -Vector3.yAxis, raycastParams);
                            if floorRayResult then
                                table.insert(pipePivots, {
                                    Position = floorRayResult.Position + Vector3.new(0, -0.001 * a, 0);
                                    Normal = floorRayResult.Normal;
                                });
                            end
                        end
                        if #pipePivots <= 1 then return end;

                        for c=2, #pipePivots do
                            local pivotPivotA = pipePivots[c-1];
                            local pivotPivotB = pipePivots[c];

                            local displace = (pivotPivotB.Position - pivotPivotA.Position);
                            local dir = displace.Unit;
                            local dist = displace.Magnitude;

                            local pipeCapA = pipePrefabs.PipeCap:Clone();
                            pipeCapA.CFrame = CFrame.lookAlong(pivotPivotA.Position, dir) * CFrame.Angles(0, math.rad(90), 0);
                            pipeCapA.Parent = debrisModel;

                            local pipeBar = pipePrefabs.Pipe:Clone();
                            pipeBar.Size = Vector3.new(dist, 0.348, 0.348);
                            pipeBar.CFrame = CFrame.lookAlong(pivotPivotA.Position, dir) * CFrame.new(0, 0, -dist/2) * CFrame.Angles(0, math.rad(90), 0);
                            pipeBar.Parent = debrisModel;

                            if c == #pipePivots then 
                                local pipeCapB = pipePrefabs.PipeCap:Clone();
                                pipeCapB.CFrame = CFrame.lookAlong(pivotPivotB.Position, dir) * CFrame.Angles(0, math.rad(90), 0);
                                pipeCapB.Parent = debrisModel;
                            end;
                        end
                    end)

                    debrisModel:SetAttribute("Update", true);
                end;

                local planterModel = planterInteractable.Part.Parent;
                local primaryPart = planterModel.PrimaryPart;
                
                local sprinklersModel = planterInteractable.Values.SprinklerModel;
                if sprinklersModel == nil then
                    for _, sprinklerAtt in pairs(primaryPart:GetChildren()) do
                        if sprinklerAtt.Name ~= "SprinklerAtt" then continue end;

                        sprinklersModel = Instance.new("Model");
                        sprinklersModel.Name = "SprinklersModel";
                        sprinklersModel.Parent = planterInteractable.Part.Parent;
                        planterInteractable.Values.SprinklerModel = sprinklersModel;

                        local sprinklerModel = pipePrefabs.Sprinkler:Clone();
                        sprinklerModel:PivotTo(sprinklerAtt.WorldCFrame * CFrame.new(0, 0.5, 0));
                        sprinklerModel.Parent = sprinklersModel;
                    end

                else
                    for _, sprinklerModel in pairs(sprinklersModel:GetChildren()) do
                        local waterPart: BasePart = sprinklerModel:FindFirstChild("Water");
                        if waterPart then
                            if waterPart:GetAttribute("CFrame") == nil then
                                waterPart:SetAttribute("CFrame", CFrame.new(waterPart:GetPivot().Position));
                            end

                            local baseCf = waterPart:GetAttribute("CFrame");
                            task.spawn(function()
                                for a=1, 5 do
                                    waterPart:PivotTo(baseCf * CFrame.Angles(math.rad(90), 0, math.rad(math.random(0, 360))) );
                                    waterPart.Transparency = 0.75;
                                    task.wait(0.1);
                                    waterPart.Transparency = 1;
                                    task.wait(0.1);
                                end
                            end)
                        end
                    end

                end
            end
        end
    end
    scheduler.OnStepped:Connect(onTick);

    shared.modEventService:OnInvoked("Deployable_BindSpawn", function(eventPacket: EventPacket, ...)
        local params = ...;
        -- params = {                 
        --  ["AimPoint"]? = -22.7125893, 11.1732311, -398.046844,
        --  ["AimRayHit"]? = Floor,
        --  ["CharacterClass"]? =  ▶ {...},
        --  ["Configurations"]? =  ▶ {...},
        --  ["PlaceCFrame"]? = -22.7125931, 11.1732302, -398.046844, 0.715464413, -0, -0.698649168, 0, 1, -0, 0.698649168, 0, 0.715464413
        --  ["DeployableModel"]? = cabbageseeds$u4,
        --  ["HitDeployableModel"]? = planter$u3,
        --  ["NewDestructible"]? =  ▶ {...},
        --  ["NewInteractable"]? =  ▶ {...},
        -- }

        local model = params.DeployableModel;
        local interactable: InteractableInstance = params.NewInteractable;
        if model == nil or interactable == nil then return end;

        if interactable.Type == "WaterDispenser" then
            deployablePackage.UpdatePlanterConfigs(interactable);

        elseif interactable.Type == "Planter" then
            local pivotCf = model:GetPivot();
            local nearbyWaterDispensers = getInteractablesInRange(pivotCf, "WaterDispenser");

            for a=1, #nearbyWaterDispensers do
                local wdInteractable = nearbyWaterDispensers[a];
                deployablePackage.UpdatePlanterConfigs(wdInteractable);
            end

        end
    end)
end


function deployablePackage.UpdatePlanterConfigs(interactable: InteractableInstance)
    local planterConfigs = interactable.Values.PlanterConfigs;

    local pivotCf = interactable.Part.CFrame;
    local plantersInRange = getInteractablesInRange(pivotCf, "Planter");

    for a=1, #plantersInRange do
        local planterInteractable = plantersInRange[a];
        if table.find(planterConfigs, planterInteractable.Config) then continue end;
        table.insert(planterConfigs, planterInteractable.Config);
    end
end

function deployablePackage.BindDeployablePlacement(handler: ToolHandlerInstance, packet)

end

function deployablePackage.BindSetup(interactable: InteractableInstance)
    Debugger:StudioWarn(`BindSetup {interactable.Config:GetFullName()}`);
    table.insert(deployablePackage.ActiveList, {
        InteractableConfig = interactable.Config;
    });

    task.wait(1);
    deployablePackage.UpdatePlanterConfigs(interactable);
end


return deployablePackage;