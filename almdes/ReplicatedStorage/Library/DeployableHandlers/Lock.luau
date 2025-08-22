local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local deployablePackage = {
    Type = "Lock";

    KeyCounter = 0;
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

    deployablePackage.KeyCounter = deployablePackage.KeyCounter +1;

    local keylockId = deployablePackage.KeyCounter;

    local ownerClass = packet.CharacterClass;
    local interactable: InteractableInstance = modInteractables.getOrNew(newModel:WaitForChild("Interactable"));
    if ownerClass then
        interactable.Values.KeylockId = keylockId;
        interactable:SetUserPermissions(ownerClass.Name, "CanInteract", true);
    end

    local destructible: DestructibleInstance = modDestructibles.getOrNew(newModel:WaitForChild("Destructible"));
    
    local parentDestructibleConfig: Configuration? = parentModel:FindFirstChild("Destructible");
    if parentDestructibleConfig and parentDestructibleConfig:HasTag("Destructible") then
        local parentDestructible: DestructibleInstance = modDestructibles.getOrNew(parentDestructibleConfig);
        parentDestructible.OnDestroy:Connect(function()
            destructible.HealthComp:SetIsDead(true);
        end)
    end

    local parentInteractableConfig: Configuration? = parentModel:FindFirstChild("Interactable");
    if parentInteractableConfig and parentInteractableConfig:HasTag("Interactable") then
        local parentInteractable: InteractableInstance = modInteractables.getOrNew(parentInteractableConfig);
        
        parentInteractable.Values.KeylockId = keylockId;
        parentInteractable:Sync();

        destructible.OnDestroy:Connect(function()
            parentInteractable.Values.KeylockId = nil;
            parentInteractable:Sync();
        end)
    end

end

return deployablePackage;