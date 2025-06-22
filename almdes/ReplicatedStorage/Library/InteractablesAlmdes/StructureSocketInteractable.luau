local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
    local StructureSocket = {
		Name = "StructureSocket";
        Type = "StructureSocket";

        IndicatorPresist = false;
        InteractDuration = RunService:IsStudio() and 1 or 3;

    };

    function StructureSocket.new(interactable: InteractableInstance)
        local config: Configuration = interactable.Config;

        interactable.CanInteract = true;
        interactable.Label = `Attach structure`;

        interactable.Values.AttachmentType = config:GetAttribute("AttachmentType");
        interactable.Values.AttachmentPoint = config.Parent and config.Parent:WaitForChild("AttachmentPoint");
    end

    -- When interacting with interactable.
    function StructureSocket.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;
    end
    
    -- When interactable pops up on screen.
    function StructureSocket.BindPrompt(interactable: InteractableInstance, info: InteractInfo)

    end

    super.registerPackage(StructureSocket);
end

return interactablePackage;

