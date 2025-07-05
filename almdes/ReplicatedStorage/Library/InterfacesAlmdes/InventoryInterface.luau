local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.localPlayer;

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modKeyBindsHandler = shared.require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modFormatNumber = shared.require(game.ReplicatedStorage.Library.FormatNumber);
local modUsableItems = shared.require(game.ReplicatedStorage.Library.UsableItems);
local modConfigurations = shared.require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modTableManager = shared.require(game.ReplicatedStorage.Library.TableManager);

local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);
local modStorageInterface = shared.require(game.ReplicatedStorage.Library.UI.StorageInterface);

local modRecipeLibrary = shared.require(game.ReplicatedStorage.Library.RecipeLibrary);
local modDeconstructLibrary = shared.require(game.ReplicatedStorage.Library.DeconstructLibrary);

local STORAGE_BUTTON_TWEENINFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut);

local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));
	local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);

    local remoteUseStorageItem = modRemotesManager:Get("UseStorageItem");
    local remoteItemFactory = modRemotesManager:Get("ItemFactory");

    local templateItemSlot = script:WaitForChild("ItemSlot");


    local defaultStorageInterface: StorageInterface, clothingStorageInterface: StorageInterface;
	local portableStorageInterfaces: {[string]: StorageInterface} = {};

    local charWindow = interface:GetWindow("CharacterWindow");
    local mPanel = charWindow.Binds.MPanel;


    --MARK: Inventory
    local invFrame = script:WaitForChild("InventoryFrame"):Clone();
    invFrame.Parent = mPanel;
    
	local invList = invFrame:WaitForChild("InvList");
	local clothingList = invFrame:WaitForChild("ClothingList");

    local invWindow: InterfaceWindow = interface:NewWindow("Inventory", invFrame);
	invWindow.UseTween = false;

    local invFrameUILayout = invFrame:WaitForChild("UIListLayout");
    invFrameUILayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        invFrame.Size = UDim2.new(1, 0, 0, invFrameUILayout.AbsoluteContentSize.Y);
    end)

    local invListUIGridLayout = invList:WaitForChild("UIGridLayout");
    invListUIGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        invList.Size = UDim2.new(1, 0, 0, invListUIGridLayout.AbsoluteContentSize.Y+10);
    end)

    --MARK: Hotbar
	local newHotbarFrame = script:WaitForChild("Hotbar"):Clone();
	newHotbarFrame.Parent = interface.ScreenGui;
    
	local hotbarWindow: InterfaceWindow = interface:NewWindow("Hotbar", newHotbarFrame);
	hotbarWindow.IgnoreHideAll = true;
	hotbarWindow.ReleaseMouse = false;
	hotbarWindow:Open();

    
    --MARK: OnToggle
    invWindow.OnToggle:Connect(function(visible)
        if visible then
			newHotbarFrame.Parent = invFrame;
			defaultStorageInterface.OnItemButton1Click = defaultStorageInterface.BeginDragItem;
            
            interface.Properties.CharacterInterfaceVisible = true;
            invFrame.Visible = true;
            
            modStorageInterface.QueueRefreshStorage({"Inventory", "Clothing"});

        else
			newHotbarFrame.Parent = interface.ScreenGui;
			
            interface.Properties.CharacterInterfaceVisible = false;
            invFrame.Visible = false;

			defaultStorageInterface:ToggleDescriptionFrame(false);
			defaultStorageInterface:StopDragItem();
			defaultStorageInterface.OnItemButton1Click = defaultStorageInterface.UseItem;

            interface:ToggleWindow("ExternalStorage", false);
            modStorageInterface.CloseOptionMenus();
        end
    end)
	modKeyBindsHandler:SetDefaultKey("KeyWindowInventory", Enum.KeyCode.Tab);
	local quickButton = interface:NewQuickButton("Inventory", "Inventory", "rbxassetid://2169843985");
	quickButton.LayoutOrder = 2;
	interface:ConnectQuickButton(quickButton, "KeyWindowInventory");


    --MARK: StorageInterfaces
	for a=1, 6 do
		local newSlot = templateItemSlot:Clone();
		newSlot.LayoutOrder = 6+a;
		newSlot:SetAttribute("Index", newSlot.LayoutOrder);
		newSlot.Name = newSlot.LayoutOrder;
		newSlot.Parent = invList;
	end

	local defaultSlots = {};
	for _,value in pairs(newHotbarFrame:GetChildren()) do 
        if value:IsA("GuiObject") and value.LayoutOrder > 0 then 
            table.insert(defaultSlots, value) 
        end 
    end;
	for _,value in pairs(invList:GetChildren()) do 
        if value:IsA("GuiObject") and value.LayoutOrder > 0 then 
            table.insert(defaultSlots, value) 
        end 
    end;
    
	
	local clothingSlots = {};
	for _,value in pairs(clothingList:GetChildren()) do
        if value:IsA("GuiObject") and value.LayoutOrder > 0 then 
            table.insert(clothingSlots, value);
        end
    end
	
	defaultStorageInterface = modStorageInterface.new("Inventory", charWindow.Frame, defaultSlots);
	defaultStorageInterface.Name = "Inventory";
	defaultStorageInterface.DeleteEnabled = false;

	clothingStorageInterface = modStorageInterface.new("Clothing", charWindow.Frame, clothingSlots);
	clothingStorageInterface.Name = "Clothing";
	clothingStorageInterface.DeleteEnabled = false;

	interface.Properties.ActiveHotbarKeys = 5;
	interface.Properties.HotEquip = function(index)
		if playerClass.HealthComp.IsDead then return end;
		if modData.GetStorage("Inventory") == nil then Debugger:Warn(`No inventory storage.`); return end;
		
		local slot = defaultStorageInterface.Slots[index];
		if slot and slot.ItemSlot then
			defaultStorageInterface:UseItem(slot.ItemSlot);
			
		end
	end

    function clothingStorageInterface:DecorateSlot(index, slotData)
		local slotFrame = slotData.Frame;
		local itemSlot = slotData.ItemSlot;
		
		if itemSlot and itemSlot.Library.SlotColor then
			slotFrame.ImageColor3 = itemSlot.Library.SlotColor;
		end
	end
	
	clothingStorageInterface:ConnectDepositLimit(function(slotInterface, itemSlot, itemSlotB)
		if itemSlot.Library.Type == modItemsLibrary.Types.Clothing then return end;

        if not slotInterface.WarnLabel.Visible then
            slotInterface.WarnLabel.Text = "Clothing Only!"
            slotInterface.WarnLabel.Visible = true;
            delay(1, function()
                slotInterface.WarnLabel.Visible = false;
            end)
        end

        if itemSlot then
            TweenService:Create(itemSlot.Button, STORAGE_BUTTON_TWEENINFO, {
                Position = UDim2.new();
            }):Play();
        end
        if itemSlotB then
            TweenService:Create(itemSlot.Button, STORAGE_BUTTON_TWEENINFO, {
                Position = UDim2.new();
            }):Play();
        end
        return false;
	end);

    local equipContextOption = {
		Text=function(itemSlot)
			return itemSlot.Item.Values.IsEquipped == nil and "Equip" or "Unequip";
		end;
		Check=function(itemSlot)
			return itemSlot.Library.Equippable;
		end;
		Click=function(itemSlot)
			if itemSlot.Item.Values.IsEquipped == nil then
				modData.HandleTool("equip", {Siid=itemSlot.ID; ItemId=itemSlot.ItemId});
                invWindow:Close();

			else
				modData.HandleTool("unequip", {Siid=itemSlot.ID; ItemId=itemSlot.ItemId});

			end
		end;
		Order=1;
	};
	defaultStorageInterface:AddContextOption(equipContextOption);

    modStorageInterface.ContextOptionDropItem = {
		Text="Drop";
		Click=function(itemSlot)
			local interface = itemSlot.Interface;
			
			modStorageInterface.CloseOptionMenus();
			
			local returnPacket = remoteItemFactory:InvokeServer("dropitemrequest", {
				StorageItemId = itemSlot.ID;
				StorageId = interface.StorageId;
			});

			if returnPacket.Success then
				Debugger:Log("Drop slot ", itemSlot, returnPacket);
			end
		end;
		Order=2;
	}
	defaultStorageInterface:AddContextOption(modStorageInterface.ContextOptionDropItem);
	clothingStorageInterface:AddContextOption(modStorageInterface.ContextOptionDropItem);
	
	local deconstructContextOption = {
		Text="Deconstruct";
		Check=function(slotItem)
			return slotItem.Library.Deconstructible == true;
		end;
		Click=function(slotItem)
			modStorageInterface.CloseOptionMenus();
			local returnPacket = remoteItemFactory:InvokeServer("deconstructrequest", {
				StorageItemId = slotItem.ID;
			});

			if returnPacket.Success then
				Debugger:Log("Deconstructing ", slotItem, returnPacket);
                --MARK: TODO: ItemFactory
				--Interface.UpdateItemFactoryData(returnPacket);
			end
		end;
		Order=3;
	};
	defaultStorageInterface:AddContextOption(deconstructContextOption);
	
	modStorageInterface.ContextOptionUnloadAmmo = {
		Text="Unload Ammo";
		Check=function(slotItem)
			local modWeaponModule = modData:GetItemClass(slotItem.ID);
			local configurations = modWeaponModule and modWeaponModule.Configurations;
			
			if configurations == nil or configurations.AmmoType == nil then
				return false;
			end
			
			local itemValues = slotItem.Item.Values;
			if itemValues == nil or itemValues.A == 0 then
				return false;
			end
			
			return true;
		end;
		Click=function(slotItem)
			modStorageInterface.CloseOptionMenus();
			
			local returnPacket = remoteItemFactory:InvokeServer("unloadammorequest", {
				StorageItemId = slotItem.ID;
				StorageId = slotItem.Interface.StorageId;
			});

			if returnPacket.Success then
				Debugger:Log("Drop slot ", slotItem, returnPacket);
			end
		end;
		Order=2;
	}
	defaultStorageInterface:AddContextOption(modStorageInterface.ContextOptionUnloadAmmo);

    local useDebounce = false;
	local usableContextOption = {
		Text=function(itemSlot)
			return itemSlot.Library.Usable or "Use";
		end;
		Check=function(itemSlot)
			return itemSlot.Library.Type == "Usable" or itemSlot.Library.Usable ~= nil;
		end;
		Click=function(itemSlot)
			if useDebounce then return end;
			useDebounce = true;

			local usableItemLib = modUsableItems:Find(itemSlot.Item.ItemId);
			if usableItemLib then
				usableItemLib:Use(itemSlot.Item);

			else
				local used = remoteUseStorageItem:InvokeServer(itemSlot.Interface.StorageId, itemSlot.ID);

			end

			useDebounce = false;
		end;
		Order=5;
	};
	defaultStorageInterface:AddContextOption(usableContextOption);
	
	local refreshDebounceIndex = 0;
	local function RefreshPortableStorages()
		refreshDebounceIndex = refreshDebounceIndex+1;
		local cIndex = refreshDebounceIndex;
		
		task.wait(0.1);
		if cIndex ~= refreshDebounceIndex then return end;
		
		--Debugger:Log("RefreshPortableStorages", refreshDebounceIndex);
		
		local linkedStorages = modData.Storages.Inventory.LinkedStorages;
		--Debugger:Log("linkedStorages", linkedStorages);
		local slotLayoutOrder = 12;
		
		for _, invListSlot in pairs(invList:GetChildren()) do
			if invListSlot:IsA("ImageLabel") and invListSlot.LayoutOrder > slotLayoutOrder then
				invListSlot.Parent = nil;
				game.Debris:AddItem(invListSlot, 0);
			end
		end
		
		for order=1, #linkedStorages do
			local linkedStorage = linkedStorages[order];

			local itemLib = modItemsLibrary:Find(linkedStorage.ItemId);
			
			local slotFrames = {};
			for a=1, linkedStorage.StorageSize do
				local newSlot = templateItemSlot:Clone();
				newSlot:SetAttribute("Index", a);
				newSlot.LayoutOrder = slotLayoutOrder+a;
				newSlot.Name = newSlot.LayoutOrder;
				newSlot.ImageColor3 = itemLib.SlotColor;
				newSlot.Parent = invList;
				
				table.insert(slotFrames, newSlot);
			end
			slotLayoutOrder = slotLayoutOrder + linkedStorage.StorageSize;
			
			local storageId = linkedStorage.StorageId;
			if portableStorageInterfaces[storageId] == nil then
				portableStorageInterfaces[storageId] = modStorageInterface.new(storageId, charWindow.Frame, slotFrames);
				portableStorageInterfaces[storageId].DeleteEnabled = false;

				portableStorageInterfaces[storageId]:AddContextOption(deconstructContextOption);
				portableStorageInterfaces[storageId]:AddContextOption(usableContextOption);
				portableStorageInterfaces[storageId]:AddContextOption(modStorageInterface.ContextOptionDropItem);
				
			else
				portableStorageInterfaces[storageId]:UpdateSlotFrames(slotFrames);
				
			end
			
			portableStorageInterfaces[storageId]:Update();
		end
	end

	task.spawn(function()
		modData.RequestStorage{
			Action = "GetStorage";
			StorageId = "Inventory";
		};
		modData.RequestStorage{
			Action = "GetStorage";
			StorageId = "Clothing";
		};
	end)
end

return interfacePackage;

