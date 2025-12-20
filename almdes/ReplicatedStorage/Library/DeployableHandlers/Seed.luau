--[[
    Deployable handler for Seeds.
    - Handles setting up seed interactable on plantable surfaces.
    - Handles deployable tool placement checks.
    - Handles harvast logic.
]]

local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

local SEEDS_LIBRARY = {
    ["cabbageseeds"] = {
        ItemId = "cabbage";
        GrowthPerMin = 60;
        WaterCostPerMin = 45;
    };
};

local deployablePackage = {
    Type = "Seed";

    SeedsLibrary = SEEDS_LIBRARY;
};
--==

function deployablePackage.onRequire()
    worldRayParams = RaycastParams.new();
    worldRayParams.FilterType = Enum.RaycastFilterType.Include;
    worldRayParams.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain;};
end

function deployablePackage.BindDeployablePlacement(handler: ToolHandlerInstance, packet)
    local aimRayHit = packet.AimRayHit;
    if aimRayHit == nil then return end;

    if aimRayHit:GetAttribute("PlantableSurface") ~= true then
        packet.IsPlaceable = false;
        packet.InvalidReason = "Must be planted on planter or soil";
        return;
    end

    local aimPoint: Vector3? = packet.AimPoint;
    if aimRayHit == nil or aimRayHit.Parent == nil then
        Debugger:Warn("Missing AimRayHit or AimRayHit.Parent.");
        return;
    end;

	local isValidRayPoint = modVector.IsInBoundingBox(
		aimRayHit.CFrame, 
		aimRayHit.Size + Vector3.new(0.5, 0.5, 0.5),
		aimPoint
	);
    if not isValidRayPoint then
        packet.IsPlaceable = false;
        packet.InvalidReason = "Aim point is out of bounds";
        return;
    end

    packet.PlaceableLabel = "Plant";
end

function deployablePackage.BindSpawnDeployable(handler: ToolHandlerInstance?, packet)
    Debugger:StudioLog("BindSpawnDeployable", handler, packet);

    local deployableModel = packet.DeployableModel;
    local primaryPart = deployableModel.PrimaryPart;

    local aimRayHit: BasePart? = packet.AimRayHit;
    if aimRayHit and aimRayHit:IsA("Terrain") then
        Debugger:Warn("Plant on terrain not implemented");
        return;
    end

    local aimPoint: Vector3? = packet.AimPoint;
    if aimRayHit == nil or aimRayHit.Parent == nil then
        Debugger:Warn("Missing AimRayHit or AimRayHit.Parent.");
        return;
    end;

	local isValidRayPoint = modVector.IsInBoundingBox(
		aimRayHit.CFrame, 
		aimRayHit.Size + Vector3.new(0.5, 0.5, 0.5),
		aimPoint
	);
    if not isValidRayPoint then
        Debugger:Warn("Invalid AimPoint.");
        return;
    end

    local planterInteractConfig = aimRayHit.Parent:FindFirstChild("Interactable");
    if planterInteractConfig == nil 
    or not planterInteractConfig:IsA("Configuration")
    or planterInteractConfig:GetAttribute("_Name") ~= "Planter" then
        Debugger:Warn("Missing planter interactable.");
        return;
    end
end

function deployablePackage.BindSetup(interactable: InteractableInstance)
    local model = interactable.Config.Parent;
    local pivotCf = model:GetPivot();

    local destructConfig = model:WaitForChild("Destructible");
    local destructible: DestructibleInstance = modDestructibles.getOrNew(destructConfig);

    local hitRayResult = workspace:Raycast(pivotCf.Position, -Vector3.yAxis*4, worldRayParams);
    local planterInteractConfig = hitRayResult and hitRayResult.Instance.Parent:FindFirstChild("Interactable");
    if hitRayResult == nil
    or planterInteractConfig == nil
    or planterInteractConfig:GetAttribute("_Name") ~= "Planter" then
        Debugger:Warn("Invalid planter interactable.");
        destructible.HealthComp:SetIsDead(true);
        return;
    end

    local primaryPart = model.PrimaryPart;
    local rayHitPart = hitRayResult.Instance;
    local weld = Instance.new("Weld");
    weld.Name = `WeldToPlanter`;
    weld.Part0 = primaryPart;
    weld.Part1 = rayHitPart;
    weld.C0 = primaryPart.CFrame:ToObjectSpace(rayHitPart.CFrame);
    weld.Parent = model;
    
    local planterInteractable: InteractableInstance = modInteractables.getOrNew(planterInteractConfig);
    local cropData = {
        InteractableConfig = interactable.Config;
        DestructibleConfig = destructible.Config;
    }

    local cropsList = planterInteractable.Values.Crops;
    table.insert(cropsList, cropData);

    destructible.OnDestroy:Connect(function()
        for a=#cropsList, 1, -1 do
            if cropsList[a].InteractableConfig == interactable.Config then
                table.remove(cropsList, a);
            end
        end
    end)

    model:ScaleTo(0.2);
end

function deployablePackage.HarvestCrop(interactable: InteractableInstance, storage: Storage)
    Debugger:Warn("Harvesting crop.");
    local model = interactable.Config.Parent;

    local destructibleConfig = model:FindFirstChild("Destructible");
    local destructible: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);
    destructible.HealthComp:SetIsDead(true);

    local seedItemId = interactable.Variant;
    local cropLib = SEEDS_LIBRARY[seedItemId];
    if cropLib == nil then
        Debugger:Warn("Invalid crop library.", seedItemId);
        return;
    end

    if storage == nil then return end;
    local storageItem = {ItemId=cropLib.ItemId; Quantity=1;} :: StorageItem;
    local rPacket = storage:InsertRequest(storageItem);
    if rPacket.Success then
        shared.Notify(storage.Player, `You harvested {cropLib.Name}.`, "Positive");
    end
end

return deployablePackage;