local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
    local StructureAttachment = {
		Name = "StructureAttachment";
        Type = "StructureAttachment";

        IndicatorPresist = false;
        InteractDuration = RunService:IsStudio() and 1 or 3;

    };

    function StructureAttachment.new(interactable: InteractableInstance)
        local scr: ModuleScript = interactable.Script;

        interactable.CanInteract = true;
        interactable.Label = `Attach structure`;

        interactable.Values.AttachmentType = scr:GetAttribute("AttachmentType") :: string;
        interactable.Values.AttachmentPoint = scr.Parent and scr.Parent:WaitForChild("AttachmentPoint") :: Attachment;
    end

    -- When interacting with interactable.
    function StructureAttachment.ActionEvent(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionTypes.ClientInteract then return end;
    end
    
    -- When interactable pops up on screen.
    function StructureAttachment.PromptEvent(interactable: InteractableInstance, info: InteractInfo)

    end

    super.register(StructureAttachment);
end

return interactablePackage;

