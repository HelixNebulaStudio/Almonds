local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local WorkbenchInteractable = {
        Name = "Workbench";
        Type = "Button";

        IndicatorPresist = false;
    };

    function WorkbenchInteractable.new(interactable: InteractableInstance, player: Player)
        local config: Configuration = interactable.Config;
        config:SetAttribute("_Proximity", true);

        interactable.CanInteract = true;
        interactable.Label = `Use Workbench`;
    end

    function WorkbenchInteractable.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        local config: Configuration = interactable.Config;
        if config.Parent == nil then return end;

        if RunService:IsClient() then
            modClientGuis.toggleWindow("Inventory", true);
        end

        interactable.TypePackage.BindInteract(interactable, info);

        local player: Player? = info.Player;
        if info.Action == "Client" or player == nil then return end;

        local playerClass: PlayerClass = shared.modPlayers.get(player);
        local statusComp: StatusComp = playerClass.StatusComp;

        local workbenchStatus: StatusClassInstance = statusComp:GetOrDefault("Workbench");
        if workbenchStatus == nil then
            workbenchStatus = statusComp:Apply("Workbench", {
                Values = {
                    ActiveInteractable = nil;
                };
            });
        end
        
        workbenchStatus.Values.ActiveInteractable = interactable;
        workbenchStatus:Sync();
    end
    
    super.registerPackage(WorkbenchInteractable);
end

return interactablePackage;
