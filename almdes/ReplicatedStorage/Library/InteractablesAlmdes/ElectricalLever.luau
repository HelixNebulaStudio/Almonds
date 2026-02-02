local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modElectricals = shared.require(game.ReplicatedStorage.Entity.Electricals);

local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local ElectricalLever = {
		Name = "ElectricalLever";
        Type = "Lever";
    };

    function ElectricalLever.BindEvent(interactable: InteractableInstance, info: InteractInfo, eventType: string)
        if eventType ~= "AfterInteract" then return end;

        local config = interactable.Config;
        for _, obj in ipairs(config:GetDescendants()) do
            if not obj:HasTag("Electrical") then continue end;

            local electrical: Electrical = modElectricals.getOrNew(obj);
            electrical:ToggleOn(interactable.Values.IsActive);
        end
    end

    super.registerPackage(ElectricalLever);
end

return interactablePackage;

