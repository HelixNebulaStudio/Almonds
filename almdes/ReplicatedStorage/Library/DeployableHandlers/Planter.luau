local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modScheduler = shared.require(game.ReplicatedStorage.Library.Scheduler);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);
local modSeed = shared.require(game.ReplicatedStorage.Library.DeployableHandlers.Seed);

local PLANTER_LIBRARY = {
    ["planter"] = {
        WaterCapacity = 100;
    };
};

local deployablePackage = {
    Type = "Planter";
    PlanterLibrary = PLANTER_LIBRARY;

    ActiveList = {};

    Scheduler = nil;
};
--==

function deployablePackage.onRequire()
    if RunService:IsClient() then return end;
    local scheduler: Scheduler = modScheduler.new("PlanterScheduler", 10);
    deployablePackage.Scheduler = scheduler;

    local function onTick(tickData: TickData)
        for _, planterData in pairs(deployablePackage.ActiveList) do
            local planterInteractable: InteractableInstance = modInteractables.getOrNew(planterData.InteractableConfig);

            local cropsList = planterInteractable.Values.Crops;
            modTables.Shuffle(cropsList);

            for a=#cropsList, 1, -1 do
                if planterInteractable.Values.Water <= 0 then continue end;

                local cropData = cropsList[a];
                local cropInteractConfig = cropData.InteractableConfig;
                local cropInteractable: InteractableInstance = modInteractables.getOrNew(cropInteractConfig);
                if cropInteractable == nil or cropInteractable.Name ~= "Seed" then continue; end;
                if cropInteractable.Values.Growth >= 100 then continue end;

                local seedLib = modSeed.SeedsLibrary[cropInteractable.Variant];

                local waterCost = seedLib.WaterCostPerMin/scheduler.Rate;
                local waterCapacity = planterInteractable.Values.WaterCapacity;
                planterInteractable.Values.Water = math.clamp(planterInteractable.Values.Water - waterCost, 0, waterCapacity);
                
                local growth = seedLib.GrowthPerMin/scheduler.Rate;
                cropInteractable.Values.Growth = math.clamp(cropInteractable.Values.Growth + growth, 0, 100);

                local model = cropInteractConfig.Parent;
                if math.random(1, 4) ~= 1 then
                    model:ScaleTo(math.max(cropInteractable.Values.Growth/100, 0.2));
                end
            end
        end
    end
    scheduler.OnStepped:Connect(onTick);
end

function deployablePackage.BindSetup(interactable: InteractableInstance)
    Debugger:StudioWarn(`BindSetup {interactable.Config:GetFullName()}`);
    local configParent = interactable.Config.Parent;

    local destructibleConfig: Configuration = configParent:FindFirstChild("Destructible");
    local destructible: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);

    destructible.OnDestroy:Connect(function()
        for a=1, #interactable.Values.Crops do
            local cropData = interactable.Values.Crops[a];

            local cropDestructible: DestructibleInstance = modDestructibles.getOrNew(cropData.DestructibleConfig);
            cropDestructible.HealthComp:SetIsDead(true);
        end
        
        table.clear(interactable.Values.Crops);
        interactable:Sync();
    end)

    table.insert(deployablePackage.ActiveList, {
        InteractableConfig = interactable.Config;
        DestructibleConfig = destructible.Config;
    });
end

return deployablePackage;