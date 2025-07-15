local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);

local deployablePackage = {
    Type = "Lock";
};
--==

function deployablePackage.onRequire()

end

function deployablePackage.BindDeployablePlacement(handler: ToolHandlerInstance, packet)
    local deployableModel = packet.DeployableModel;
    if deployableModel == nil then return end;

    local lockPlacement = deployableModel:FindFirstChild("LockPlacement", true);
    if lockPlacement == nil then return end;

    packet.LockPlacement = lockPlacement;
    packet.PlaceCFrame = lockPlacement.WorldCFrame;
end

function deployablePackage.BindSpawnDeployable(handler: ToolHandlerInstance, packet)
    local newModel: Model = packet.DeployableModel;
    if newModel.PrimaryPart == nil then error(`{newModel.Name} is missing PrimaryPart.`); return end;

    local placementData = packet.PlacementData;
    local parentModel = placementData.DeployableModel;

    local lockAttachPoint: Attachment = placementData.LockPlacement;
    local attachPart = lockAttachPoint.Parent;

    local weld: WeldConstraint = Instance.new("WeldConstraint");
    weld.Parent = newModel;
    weld.Part0 = newModel.PrimaryPart;
    weld.Part1 = attachPart;

    local destructible: DestructibleInstance = modDestructibles.getOrNew(newModel:FindFirstChild("Destructible"));
    
    local parentDestructibleConfig: Configuration? = parentModel:FindFirstChild("Destructible");
    if parentDestructibleConfig and parentDestructibleConfig:HasTag("Destructible") then
        local parentDestructible: DestructibleInstance = modDestructibles.getOrNew(parentDestructibleConfig);
        parentDestructible.OnDestroy:Connect(function()
            destructible.HealthComp:SetIsDead(true);
        end)
    end
end

return deployablePackage;