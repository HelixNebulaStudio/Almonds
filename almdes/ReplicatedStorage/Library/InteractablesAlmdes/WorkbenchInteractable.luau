local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local WorkbenchInteractable = {
        Name = "Workbench";
        Type = "Workbench";

        IndicatorPresist = false;
    };

    function WorkbenchInteractable.new(interactable: InteractableInstance, player: Player)
        local config: Configuration = interactable.Config;
        
        interactable.CanInteract = true;
        interactable.Label = `Use Workbench`;
    end

    function WorkbenchInteractable.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Action ~= info.ActionSource.Client then return end;

		local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
        modClientGuis.toggleWindow("WorkbenchWindow", true);
    end
    
    super.registerPackage(WorkbenchInteractable);
end

return interactablePackage;
