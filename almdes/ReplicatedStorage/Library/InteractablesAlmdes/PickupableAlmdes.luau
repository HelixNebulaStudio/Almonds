local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local localPlayer = game.Players.LocalPlayer;

local interactablePackage = {};
--==
function interactablePackage.init(super) -- Server/Client
    local PickupableAlmdes = super.newPackage{
		Name = "PickupableAlmdes";
        Type = "Pickupable";

        InsertRequestRuleset = {};
    };
    
    super.registerPackage(PickupableAlmdes);
end

return interactablePackage;

