local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibraryAlmdes);
local modInteractables = shared.require(game.ReplicatedStorage.Library.InteractablesAlmdes);

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
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
    local player: Player = storage.Player;

    local storageItem = rPacket.StorageItem; -- Might be proxy;

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
        local rootCFrame = playerClass.RootPart.CFrame;
        
		modItemDrops.spawn{
			ItemId = storageItem.ItemId;
            StorageItem = storageItem;
			SpawnCFrame = rootCFrame + rootCFrame.LookVector;
			DespawnDuration = false;
		};

        shared.Notify(storage.Player, "Inventory is full, "..quantity.." "..itemLib.Name.." was dropped!", "Negative");
    end
    
    return rPacket;
end

function modStorage.RequestUnlock(params, rPacket)
    local storageId = params.StorageId;
    local storage = params.Storage;
    local player = params.Player;

    Debugger:StudioLog(`RequestUnlock(params, rPacket)`, params, rPacket)

    if storage.InteractConfig == nil then Debugger:Warn(`{storageId} is missing InteractConfig.`); return end;
    local interactable: InteractableInstance = modInteractables.getOrNew(storage.InteractConfig);

    local function setSucessful()
        rPacket.Success = true;

        if storage.BasePart then
            modAudio.Play("CrateOpen", storage.BasePart);
        end
    end

    local keyRequired = interactable.Values.KeyRequired;
    if keyRequired == nil then 
        setSucessful();
        return;
    end;

    local profile: ProfileAlmdes = shared.modProfile:Get(player);
    local gameSave: GameSaveAlmdes = profile:GetActiveSave() :: GameSaveAlmdes;
    local inventory = gameSave.Inventory;
    
    local total, itemList = inventory:ListQuantity(keyRequired, 1);
    if total <= 0 then return end;

    inventory:Remove(itemList[1].ID, 1);

    interactable.Values.KeyRequired = nil;
    interactable:SetPermissions("CanInteract", true);

    storage:SetPermissions("CanView", true);
    storage:SetPermissions("CanAdd", true);
    storage:SetPermissions("CanRemove", true);

    interactable:Sync();
    
    setSucessful();
end

shared.coreBind(modStorage, "_new", function(storage: Storage)
    storage:BindActionHandler("RequestUnlock", modStorage.RequestUnlock);
end)

return modStorage;