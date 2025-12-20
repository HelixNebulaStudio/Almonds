local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modWaterDispenser = shared.require(game.ReplicatedStorage.Library.DeployableHandlers.WaterDispenser);

local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local WaterDispenser = {
		Name = "WaterDispenser";
        Type = "WaterDispenser";

        IndicatorPresist = false;
        InteractableRange = 10;
    };

    function WaterDispenser.new(interactable: InteractableInstance)
        local config = interactable.Config;

        interactable.CanInteract = false;
        interactable.Label = `Watering 0 nearby planters..`;

        interactable.Values.PlanterConfigs = {};

        if RunService:IsClient() then return end;
        modWaterDispenser.BindSetup(interactable);
    end

    function WaterDispenser.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;
    end
    
    function WaterDispenser.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        interactable.Label = `Watering {#interactable.Values.PlanterConfigs} nearby planters..`;
    end

    super.registerPackage(WaterDispenser);
end

return interactablePackage;

