local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modScheduler = shared.require(game.ReplicatedStorage.Library.Scheduler);
local modFuelsLibrary = shared.require(game.ReplicatedStorage.Library.FuelsLibrary);
local modCookLibrary = shared.require(game.ReplicatedStorage.Library.CookLibrary);

local FURNACE_INDEX = {
	FUEL_INPUT = 1;
	FUEL_OUTPUT = 2;
	PRODUCT_INPUT = 3;
	PRODUCT_OUTPUT = 4;
	MIX_INPUT = 5;
	MIX_OUTPUT = 6;
}

local interactablePackage = {
    Counter = 0;
};

local furnaceScheduler: Scheduler

function interactablePackage.onRequire()
    if RunService:IsServer() then
        furnaceScheduler = modScheduler.new("FurnaceScheduler", 1);
    end
end

function interactablePackage.init(super) -- Server/Client
    local FuranceInteractable = {
        Name = "Furnace";
        Type = "Storage";

        WindowName = "FurnaceWindow";
        IndicatorPresist = false;
    };

    function FuranceInteractable.initFurnace(interactable: InteractableInstance)
        if RunService:IsClient() then return end;

        local storageId = interactable.Values.StorageId;
        local storage: Storage = shared.modStorage.openStorage(storageId, {
            StoragePresetId = "furnace";
            StorageName = "Furnace";
        });

        --MARK: ConnectCheck
        storage:ConnectCheck(function(packet)
			local dragStorageItem = packet.DragStorageItem;
			local targetIndex: number = packet.TargetIndex;

            if targetIndex == FURNACE_INDEX.FUEL_OUTPUT 
            or targetIndex == FURNACE_INDEX.PRODUCT_OUTPUT 
            or targetIndex == FURNACE_INDEX.MIX_OUTPUT then
                packet.Allowed = false;
                packet.FailMsg = `{dragStorageItem.Library.Name} cannot be in slot {targetIndex}.`;
            end
            
            return packet;
        end)

        --MARK: OnChanged
        storage.OnChanged:Connect(function()
            local currTime = workspace:GetServerTimeNow();
            local indexDict: {[number]: StorageItem} = storage:GetIndexDictionary();
            
            local fuelStorageItem: StorageItem? = indexDict[FURNACE_INDEX.FUEL_INPUT];
            local activeFuel = storage.Values.ActiveFuel or {};
            
            local fuelLib = fuelStorageItem and modFuelsLibrary:Find(fuelStorageItem.ItemId);
            if fuelLib and fuelStorageItem then
                activeFuel.ID = fuelStorageItem.ID;
                
                if activeFuel.FuelId == nil or activeFuel.FuelId ~= fuelStorageItem.ItemId then
                    activeFuel.FuelId = fuelLib.Id;
                    
                elseif fuelStorageItem.Quantity >= fuelLib.InputQuantity then
                    
                    if activeFuel.Tick == nil then
                        if activeFuel.Active and activeFuel.Active > currTime then
                            local timeLeft = (activeFuel.Active - currTime)/2;
                            activeFuel.Tick = currTime-timeLeft;
                        else
                            activeFuel.Tick = currTime;
                        end
                    end
                    
                    if (currTime-activeFuel.Tick >= fuelLib.BurnTime) then
                        activeFuel.Tick = currTime;

                        if fuelStorageItem.Quantity >= fuelLib.InputQuantity then
                            local rPacket = storage:InsertRequest({
                                ItemId = fuelLib.OutputItemId;
                                Quantity = fuelLib.OutputQuantity;
                            } :: StorageItem, {ForceIndex = FURNACE_INDEX.FUEL_OUTPUT});

                            Debugger:Warn("rPacket", rPacket);

                            storage:Remove(fuelStorageItem.ID, fuelLib.InputQuantity);
                            
                            activeFuel.ActiveDuration = fuelLib.BurnTime *2;
                            activeFuel.Active = currTime + activeFuel.ActiveDuration;
                        end
                    end
                end

            else
                activeFuel.Tick = nil;
                activeFuel.ID = nil;
                
            end
            
            
            local isActive = activeFuel.Active and activeFuel.Active > currTime;

            local productStorageItem = indexDict[FURNACE_INDEX.PRODUCT_INPUT];
            local mixStorageItem = indexDict[FURNACE_INDEX.MIX_INPUT];
            local activeCook = storage.Values.ActiveCook or {};
            local activeMix = storage.Values.ActiveMix or {};

            local cookLib = productStorageItem and modCookLibrary:Find(productStorageItem.ItemId);
            if cookLib then
                local canCook = true;
                
                local _enoughProductIn = productStorageItem.Quantity >= cookLib.InputQuantity;
                
                if cookLib.MixInItemId and mixStorageItem 
                    and mixStorageItem.ItemId == cookLib.MixInItemId 
                    and mixStorageItem.Quantity >= cookLib.MixInQuantity
                    and productStorageItem.Quantity >= cookLib.InputQuantity then
                    
                    if activeMix.ID == nil or activeMix.ID ~= mixStorageItem.ID then
                        if activeCook.Tick ~= nil then
                            activeCook.Tick = currTime;
                        end
                        activeMix.ID = mixStorageItem.ID;
                        
                    end
                    activeCook.Mix = 2;
                    
                else
                    if cookLib.MixInItemId then
                        canCook = false;
                        activeCook.Tick = nil;
                        activeCook.Mix = (mixStorageItem and mixStorageItem.ItemId == cookLib.MixInItemId and 1) or 0;
                        
                    else
                        activeCook.Mix = 0;
                    end
                    
                    activeMix.ID = nil;
                    
                end
                
                if activeCook.CookId == nil or activeCook.CookId ~= productStorageItem.ItemId then
                    activeCook.CookId = cookLib.Id;
                    activeCook.Tick = nil;
                    
                elseif isActive and canCook and productStorageItem.Quantity >= cookLib.InputQuantity then
                    if activeCook.Tick == nil then
                        activeCook.Tick = currTime;
                    end
                    if currTime-activeCook.Tick >= cookLib.CookTime then
                        activeCook.Tick = currTime;

                        -- Product out;
                        local _rPacket = storage:InsertRequest({
                            ItemId = cookLib.OutputItemId;
                            Quantity = cookLib.OutputQuantity;
                        } :: StorageItem, {ForceIndex = FURNACE_INDEX.PRODUCT_OUTPUT});

                        storage:Remove(productStorageItem.ID, cookLib.InputQuantity);


                        local _rPacket = storage:InsertRequest({
                            ItemId = cookLib.MixOutItemId;
                            Quantity = cookLib.MixOutQuantity;
                        } :: StorageItem, {ForceIndex = FURNACE_INDEX.MIX_OUTPUT});

                        if cookLib.ConsumeMix == true then
                            storage:Remove(mixStorageItem.ID, cookLib.MixInQuantity);
                        end

                    end

                end

            else
                activeCook.CookId = nil;
                activeCook.Tick = nil;
                activeCook.Mix = 0;

                activeMix.ID = nil;
            end

            storage.Values.ActiveFuel = activeFuel;
            storage.Values.ActiveCook = activeCook;
            storage.Values.ActiveMix = activeMix;
            
            storage:SyncValues();
        end)
        
        storage.Garbage:Tag(furnaceScheduler.OnStepped:Connect(function()
            storage.OnChanged:Fire(storage);
        end))
    end

    --MARK: new
    local STORAGE_NAME = "Furnace";
    local STORAGE_PRESET_ID = "furnace";
    function FuranceInteractable.new(interactable: InteractableInstance, player: Player)
        local config: Configuration = interactable.Config;
        
        if RunService:IsServer() then
            interactablePackage.Counter = interactablePackage.Counter + 1;
            local storageId = `{STORAGE_PRESET_ID}${interactablePackage.Counter}`

            config:SetAttribute("StorageId", storageId);
            config:SetAttribute("StoragePresetId", STORAGE_PRESET_ID);
            config:SetAttribute("StorageName", STORAGE_NAME);

            interactable.Values.StorageId = storageId;
            interactable.Values.StoragePresetId = STORAGE_PRESET_ID;
            interactable.Values.StorageName = STORAGE_NAME;

            FuranceInteractable.initFurnace(interactable);
            interactable:SetPermissions("CanInteract", true);
        end

        interactable.CanInteract = true;
        interactable.Label = `Use Furnace`;
    end

    --MARK: BindInteract
    function FuranceInteractable.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        interactable.TypePackage.BindInteract(interactable, info);  -- Calls StorageInteractable.BindInteract
        if info.Action == "Client" then return end;
    end
    
    super.registerPackage(FuranceInteractable);
end

return interactablePackage;
