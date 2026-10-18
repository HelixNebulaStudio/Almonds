local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local Revive = {
        Name = "Revive"; 
        Type = "Revive";

        Label = "Heal to revive";
	    IndicatorPresist = true;
        InteractableRange = 8;
    };

    function Revive.new(interactable: InteractableInstance, npcName: string)
    end

    function Revive.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        local config: Configuration = interactable.Config;
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;
    end
    
    function Revive.BindPrompt(interactable: InteractableInstance, info: InteractInfo)

    end

    super.registerPackage(Revive);
end

return interactablePackage;
