local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local localPlayer = game.Players.LocalPlayer;

local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);

local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

--==
local templateAmmoOverlay = script:WaitForChild("AmmoOverlay");

local _defaultUpdateItemButton = modItemInterface.DefaultUpdateItemButton;
function modItemInterface:DefaultUpdateItemButton(storageItem: StorageItem)
    _defaultUpdateItemButton(self, storageItem);
    --

	local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);

	local itemButton: ImageButton = self.ImageButton;
    local overlayFrame = itemButton:WaitForChild("Overlays");

	local itemId = self.ItemId;
	local itemLib = modItemsLibrary:Find(itemId);
    
    if storageItem == nil then return end;
    local siid = storageItem.ID;
    local itemValues = storageItem.Values;

	local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
	local wieldComp: WieldComp = playerClass.WieldComp;

    if modItemsLibrary:HasTag(itemId, "Gun") then
        local ammoOverlay = self.AmmoOverlay;
        if ammoOverlay == nil then
            ammoOverlay = templateAmmoOverlay:Clone();
            ammoOverlay.Parent = overlayFrame;
            self.AmmoOverlay = ammoOverlay;
        end

        local counterLabel = ammoOverlay:WaitForChild("CounterLabel");

        local equipmentClass: EquipmentClass? = wieldComp:GetEquipmentClass(siid);
        if equipmentClass then
            ammoOverlay.Visible = true;

            local configurations = equipmentClass.Configurations;
            local properties = equipmentClass.Properties;
            local activeAmmoId = storageItem.Values.AmmoId or configurations.AmmoType;

            local ammoItemLib = modItemsLibrary:Find(activeAmmoId);
            ammoOverlay.Image = ammoItemLib.Icon;

            local availableInvAmmo = 0;
            if storageItem.StorageId == "Inventory" then
                availableInvAmmo = modData.CountItemIdOnCharacter(activeAmmoId);
            end

            counterLabel.Text = (itemValues.A or 0) + (itemValues.MA or 0) + availableInvAmmo;

        else
            ammoOverlay.Visible = false;
        end

    end
end

return modItemInterface;