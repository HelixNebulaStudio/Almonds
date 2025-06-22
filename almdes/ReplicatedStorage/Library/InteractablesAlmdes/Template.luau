local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local Template = {
		Name = "Template";
        Type = "Template";

        IndicatorPresist = false;
        InteractableRange = 10;
    };

    function Template.new(interactable: InteractableInstance, npcName: string)
        local config = interactable.Config;
		npcName = (config:GetAttribute("NpcName") :: string) or npcName;

        interactable.CanInteract = true;
        interactable.Label = `Talk to {npcName}`;

        interactable.Values.NpcName = npcName;
    end

    -- When interacting with interactable.
    function Template.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;

        local interface = info.ClientInterface;
        if interface == nil or interface:IsVisible("Dialogue") then return end;

        interface.Part = interactable.Part;
        interface:OpenWindow("Dialogue", interactable, info);
    end
    
    -- When interactable pops up on screen.
    function Template.BindPrompt(interactable: InteractableInstance, info: InteractInfo)

    end

    super.registerPackage(Template);
end

return interactablePackage;

