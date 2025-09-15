local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local deployablePackage = {
    Type = "Lock";

    KeyCounter = 110;
};
--==

function deployablePackage.BindDeployablePlacement(handler: ToolHandlerInstance, packet)
    local hitDeployableModel = packet.HitDeployableModel;
    if hitDeployableModel == nil then return end;

    local lockPlacement = hitDeployableModel:FindFirstChild("LockPlacement", true);
    if lockPlacement == nil then return end;

    packet.LockPlacement = lockPlacement;
    packet.PlaceCFrame = lockPlacement.WorldCFrame;

    local deployableInteractConfig: Configuration? = hitDeployableModel:FindFirstChild("Interactable");
    if deployableInteractConfig then
        local deployableInteractable: InteractableInstance = modInteractables.getOrNew(deployableInteractConfig);

        if deployableInteractable.Values.Barricaded then
            packet.IsPlaceable = false;
            packet.InvalidReason = `Can't attach because of barricade`;

        elseif deployableInteractable.Values.KeylockId then
            packet.IsPlaceable = false;
            packet.InvalidReason = `This is already locked`;

        end
    end
end

function deployablePackage.BindSpawnDeployable(handler: ToolHandlerInstance?, packet)
    local newModel: Model = packet.DeployableModel;

    local primaryPart = newModel:WaitForChild("PrimaryPart");
    local hitDeployableModel = packet.HitDeployableModel;

    local lockAttachPoint: Attachment = packet.LockPlacement;
    local attachPart = lockAttachPoint.Parent;

    local weld = Instance.new("Weld");
    weld.Name = "LockWeld";
    weld.Part0 = primaryPart;
    weld.Part1 = attachPart;
    weld.C0 = primaryPart.CFrame:ToObjectSpace(attachPart.CFrame);
    weld.Parent = newModel;
    
    deployablePackage.KeyCounter = deployablePackage.KeyCounter +1;

    local keylockId = deployablePackage.KeyCounter;

    local interactable: InteractableInstance = packet.NewInteractable;
    local ownerClass = packet.CharacterClass;
    if ownerClass then
        interactable.Values.KeylockId = keylockId;
        interactable:SetUserPermissions(ownerClass.Name, "CanInteract", true);
    end

    local destructible: DestructibleInstance = packet.NewDestructible;
    
    local parentDestructibleConfig: Configuration? = hitDeployableModel:FindFirstChild("Destructible");
    if parentDestructibleConfig and parentDestructibleConfig:HasTag("Destructible") then
        local parentDestructible: DestructibleInstance = modDestructibles.getOrNew(parentDestructibleConfig);
        parentDestructible.OnDestroy:Connect(function()
            destructible.HealthComp:SetIsDead(true);
        end)
    end

    local parentInteractableConfig: Configuration? = hitDeployableModel:FindFirstChild("Interactable");
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