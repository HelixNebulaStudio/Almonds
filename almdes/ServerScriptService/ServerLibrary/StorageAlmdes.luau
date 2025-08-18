local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibraryAlmdes);

local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);
local modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);


--==
function modStorage.onRequire()
    shared.modEventService:OnInvoked("Storage_OnOpen", function(packet: EventPacket, storage: Storage, player: Player)
        if player == nil then return end;

        local playerClass: PlayerClassAlmdes = shared.modPlayers.get(player);
        Debugger:Log("Storage_OnOpen", storage.Id, player, storage.Cache.EnvLootCrate);
        if storage.Cache.EnvLootCrate == nil then return end;

        local firstOpenCache = storage.Cache.FirstOpen;
        if firstOpenCache == nil then
            firstOpenCache = {};
            storage.Cache.FirstOpen = firstOpenCache;
        end

        local playerName = player.Name;
        if firstOpenCache[playerName] == nil then
            firstOpenCache[playerName] = true;

            local playerRunSession = playerClass.Properties.PlayRunSession;
            playerRunSession:AddStat("StorageOpened", 1);
        end

    end);
end

function modStorage.InsertRequestHandler(storage: Storage, rPacket)
    Debugger:Log("InsertRequestHandler rPacket", rPacket);
    local player: Player = storage.Player;

    local pickupTime = workspace:GetServerTimeNow();
    local storageItem = rPacket.StorageItem; -- May be proxy;

    local itemLib = modItemsLibrary:Find(storageItem.ItemId);
    local quantity = storageItem.Quantity;
    
    if rPacket.Success then
        if player == nil then
            return rPacket;
        end
        
    elseif rPacket.Failed == 1 then
        if player == nil then
            Debugger:Log("Storage failed insert request: ", storage.Id, storageItem);
            return rPacket;
        end
        
        local playerClass: PlayerClass = shared.modPlayers.get(player);
        local cache = playerClass.Cache;
        local rootCFrame = playerClass.RootPart.CFrame;
        
        local itemDrop = {
            Type="Custom";
            ItemId=storageItem.ItemId;
            StorageItem=storageItem;
        };
        
        
        local lastFailPickup = cache.LastPickupFailTick;
        if lastFailPickup == nil then
            cache.LastPickupFailTick = pickupTime;
            
        elseif pickupTime-lastFailPickup >= 60 then
            cache.LastPickupFailTick = nil;
            cache.PickUpFailCount = nil;
        end 
        
        local pickUpFailCount = (cache.PickUpFailCount or 0) +1;
        cache.PickUpFailCount = pickUpFailCount;
        
        
        local newPrefab = modItemDrops.Spawn(itemDrop, rootCFrame + rootCFrame.LookVector, nil, 300);
        newPrefab:AddTag("ItemDrop");

        local interactConfig = newPrefab:FindFirstChild("Interactable");
        if interactConfig then
           interactConfig:SetAttribute("DisableTouchInteract", pickupTime+cache.PickUpFailCount);
        end
        
        shared.Notify(storage.Player, "Inventory is full, "..quantity.." "..itemLib.Name.." was dropped!", "Negative");
    end
    
    return rPacket;
end

return modStorage;