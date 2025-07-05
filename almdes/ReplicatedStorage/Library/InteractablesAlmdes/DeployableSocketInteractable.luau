local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
    local DeployableSocket = {
		Name = "DeployableSocket";
        Type = "DeployableSocket";

        IndicatorPresist = false;
        InteractDuration = RunService:IsStudio() and 1 or 3;
    };

    function DeployableSocket.new(interactable: InteractableInstance)
        local config: Configuration = interactable.Config;

        interactable.Values.AttachmentPoint = config.Parent and config.Parent:WaitForChild("AttachmentPoint");

        if RunService:IsServer() then
            local objectValue = Instance.new("ObjectValue");
            objectValue.Name = `ActiveDeployable`;
            objectValue.Parent = config;

            local orignalParent = interactable.Part.Parent;
            objectValue:GetPropertyChangedSignal("Value"):Connect(function()
                if objectValue.Value then
                    interactable.Part.Parent = script;
                else
                    interactable.Part.Parent = orignalParent;
                end
            end)

            interactable.Values.ActiveDeployable = objectValue;

        elseif RunService:IsClient() then
            interactable.Values.ActiveDeployable = config:WaitForChild("ActiveDeployable");
            
        end
    end

    -- When interacting with interactable.
    function DeployableSocket.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;

    end
    
    -- When interactable pops up on screen.
    function DeployableSocket.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        local activeDeployable: Model? = interactable.Values.ActiveDeployable.Value;
        
        if activeDeployable then
            
            
        else
            interactable.CanInteract = false;
            interactable.Label = `Attach {interactable.Variant}`;
        end
    end

    super.registerPackage(DeployableSocket);
end

return interactablePackage;

