local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modSeed = shared.require(game.ReplicatedStorage.Library.DeployableHandlers.Seed);

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
    local Seed = super.newPackage{
		Name = "Seed";
        Type = "Button";

        IndicatorPresist = false;
        InteractableRange = 10;
    };

    function Seed.new(interactable: InteractableInstance)
        local config = interactable.Config;

        interactable.CanInteract = false;
        interactable.Label = ``;
        interactable.Values.Growth = 0;

        if RunService:IsClient() then return end;
        modSeed.BindSetup(interactable);
    end

    -- When interacting with interactable.
    function Seed.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        Seed.TypePackage.BindInteract(interactable, info);
        if info.Action == "Client" then return end;

        if interactable.Values.Growth < 100 then return end;

        if info.NpcClass then
            local npcClass: NpcClass = info.NpcClass;
            return;
        end
        
        local player: Player? = info.Player;
        if player == nil then 
            return; 
        end;

        local profile: ProfileAlmdes = shared.modProfile:Get(player) :: ProfileAlmdes;
        local inventory = profile.ActiveInventory;
        modSeed.HarvestCrop(interactable, inventory);
    end
    
    -- When interactable pops up on screen.
    function Seed.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        local variant = interactable.Variant;
        local seedLib = modSeed.SeedsLibrary[variant];

        local itemLib = modItemsLibrary:Find(seedLib.ItemId);

        local growthPercent = math.clamp(interactable.Values.Growth, 0, 100);
        if growthPercent >= 100 then
            interactable.CanInteract = true;
            interactable.Label = `Harvest {itemLib.Name}`;
        else
            interactable.CanInteract = false;
            interactable.Label = `{itemLib.Name} Growth: {growthPercent}%`;
        end
    end

    super.registerPackage(Seed);
end

return interactablePackage;

