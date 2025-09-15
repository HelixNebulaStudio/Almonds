local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

local SEEDS_LIBRARY = {
    ["cabbageseeds"] = {
        Name = "Cabbage";
        GrowthPerMin = 60;
        WaterCostPerMin = 30;
    };
};

local deployablePackage = {
    Type = "Seed";

    SeedsLibrary = SEEDS_LIBRARY;
};
--==

function deployablePackage.onRequire()
    
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

    local weld = Instance.new("Weld");
    weld.Name = `WeldToPlanter`;
    weld.Part0 = primaryPart;
    weld.Part1 = aimRayHit;
    weld.C0 = primaryPart.CFrame:ToObjectSpace(aimRayHit.CFrame);
    weld.Parent = deployableModel;

    local planterInteractable: InteractableInstance = modInteractables.getOrNew(planterInteractConfig);
    local planterDestructible: DestructibleInstance = modDestructibles.getOrNew(planterInteractConfig.Parent:FindFirstChild("Destructible"));

    local seedInteractable: InteractableInstance = packet.NewInteractable;
    local seedDestructible: DestructibleInstance = packet.NewDestructible;
    table.insert(planterInteractable.Values.Crops, {
        InteractableConfig = seedInteractable.Config;
        DestructibleConfig = seedDestructible.Config;
    });
end

return deployablePackage;