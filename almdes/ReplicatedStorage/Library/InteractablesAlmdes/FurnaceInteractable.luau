local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local FuranceInteractable = {
        Name = "Furnace";
        Type = "Furnace";

        IndicatorPresist = false;
    };

    function FuranceInteractable.new(interactable: InteractableInstance, player: Player)
        local config: Configuration = interactable.Config;
        
        interactable.CanInteract = true;
        interactable.Label = `Use Furnace`;
    end

    function FuranceInteractable.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Action ~= info.ActionSource.Client then return end;

		local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
        modClientGuis.toggleWindow("FurnaceWindow", true);
    end
    
    super.registerPackage(FuranceInteractable);
end

return interactablePackage;
