local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local interactablePackage = {};

local modSeed = shared.require(game.ReplicatedStorage.Library.DeployableHandlers.Seed);
--==

function interactablePackage.init(super) -- Server/Client
    local Seed = {
		Name = "Seed";
        Type = "Seed";

        IndicatorPresist = false;
        InteractableRange = 10;
    };

    function Seed.new(interactable: InteractableInstance, npcName: string)
        local config = interactable.Config;

        interactable.CanInteract = false;
        interactable.Label = ``;
        interactable.Values.Growth = 0;
    end

    -- When interacting with interactable.
    function Seed.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;

        Debugger:Warn("Harvesting crop.");
    end
    
    -- When interactable pops up on screen.
    function Seed.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        local variant = interactable.Variant;
        local seedLib = modSeed.SeedsLibrary[variant];

        local growthPercent = math.clamp(interactable.Values.Growth, 0, 100);
        if growthPercent >= 100 then
            interactable.CanInteract = true;
            interactable.Label = `Harvest {seedLib.Name}`;
        else
            interactable.CanInteract = false;
            interactable.Label = `{seedLib.Name} Growth: {growthPercent}%`;
        end
    end

    super.registerPackage(Seed);
end

return interactablePackage;

