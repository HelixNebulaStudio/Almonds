local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modPlanter = shared.require(game.ReplicatedStorage.Library.DeployableHandlers.Planter);

local interactablePackage = {};
--==
function interactablePackage.init(super) -- Server/Client
    local Planter = {
		Name = "Planter";
        Type = "Planter";

        IndicatorPresist = false;
    };

    function Planter.new(interactable: InteractableInstance)
        local config = interactable.Config;
        
        interactable.CanInteract = false;
        interactable.Label = `Water: 0/100`;

        local variant = interactable.Variant;
        local planterLib = modPlanter.PlanterLibrary[variant];

        interactable.Values.LastWaterReceived = workspace:GetServerTimeNow();
        interactable.Values.Water = 0;
        interactable.Values.WaterCapacity = planterLib.WaterCapacity;
        interactable.Values.Crops = {};

        if RunService:IsClient() then return end;
        modPlanter.BindSetup(interactable);
    end

    -- When interactable pops up on screen.
    function Planter.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        interactable.Label = `Water: {interactable.Values.Water}/{interactable.Values.WaterCapacity}`;
    end

    super.registerPackage(Planter);
end

return interactablePackage;

