local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modScheduler = shared.require(game.ReplicatedStorage.Library.Scheduler);

local deployablePackage = {
    Type = "WaterDispenser";

    ActiveList = {};
    Scheduler = nil;
};

local SCAN_RANGE = 16;

local overlapParams = OverlapParams.new();
overlapParams.FilterType = Enum.RaycastFilterType.Include;
--==
local function getInteractablesInRange(pivotCf: CFrame, filterType)
    overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("InteractablePart");
    
    local partsInRange = workspace:GetPartBoundsInRadius(pivotCf.Position, SCAN_RANGE, overlapParams);
    
    local interactables = {};
    for a=1, #partsInRange do
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
    
    local function onTick(tickData: TickData)
        for _, dispenserData in pairs(deployablePackage.ActiveList) do
            local interactable: InteractableInstance = modInteractables.getOrNew(dispenserData.InteractableConfig);
            local planterConfigs = interactable.Values.PlanterConfigs;
            for a=1, #planterConfigs do
                local planterConfig: Configuration = planterConfigs[a];
                local planterInteractable: InteractableInstance = modInteractables.getOrNew(planterConfig);
                if planterInteractable == nil then continue end;
                if planterInteractable.Type ~= "Planter" then continue end;
                if planterInteractable.Values.Water >= planterInteractable.Values.WaterCapacity then continue end;
                if planterInteractable.Values.LastWaterReceived + 1 >= workspace:GetServerTimeNow() then continue end;

                planterInteractable.Values.LastWaterReceived = workspace:GetServerTimeNow();
                planterInteractable.Values.Water = math.clamp(planterInteractable.Values.Water + 1, 0, planterInteractable.Values.WaterCapacity);
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
    table.insert(deployablePackage.ActiveList, {
        InteractableConfig = interactable.Config;
    });
end


return deployablePackage;