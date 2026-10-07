local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local localPlayer = game.Players.LocalPlayer;

local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

local interactablePackage = {};
--==
function interactablePackage.init(super) -- Server/Client
    local PickupableAlmdes = super.newPackage{
		Name = "PickupableAlmdes";
        Type = "Pickupable";

        InsertRequestRuleset = {};
    };
    
    function PickupableAlmdes.new(interactable: InteractableInstance)
        PickupableAlmdes.TypePackage.new(interactable);
        
        local config: Configuration = interactable.Config;
		local itemId = config:GetAttribute("ItemId") :: string;

        config:SetAttribute("TouchPickup", false);
    end

    super.registerPackage(PickupableAlmdes);
end

return interactablePackage;

