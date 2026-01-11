local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modGameSave = shared.require(game.ServerScriptService.ServerLibrary.GameSave);

local modUsableItems = shared.require(game.ReplicatedStorage.Library.UsableItems);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modStoragePresetsLibrary = shared.require(game.ReplicatedStorage.Library.StoragePresetsLibraryAlmdes);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibraryAlmdes);

local modLoadoutSaves = shared.require(game.ServerScriptService.ServerLibrary.LoadoutSaves);
local modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
local modItemProcessor = shared.require(game.ServerScriptService.ServerLibrary.ItemProcessor);

--==
function modGameSave.onRequire()

end

shared.coreBind(modGameSave, "_new", function(gameSave: GameSaveAlmdes, profile: ProfileAlmdes)
	local player: Player = profile.Player;
	Debugger:Warn("OnNewSave", player);

	local saveMeta = getmetatable(gameSave :: any);

	--ItemProcessor
	local itemProcessor = modItemProcessor.new();
	itemProcessor:Setup(player, gameSave.Inventory);
	profile.Garbage:Tag(itemProcessor);
	saveMeta.ItemProcessor = itemProcessor;
	
	
	gameSave.Inventory.MaxSize = 12;
	gameSave.Inventory.Size = gameSave.Inventory.MaxSize;
	gameSave.Inventory.PremiumStorage = 12;
	
	local function onStorageChanged(storage: Storage?)
		if storage == nil then return end;
		Debugger:Log("Storage changed", storage.Id);
		storage:Sync(player);
	end

	gameSave.Clothing.OnChanged:Connect(function()
		local portableStorages = {};
		local equippedStorageIds = {};
		
		for siid, storageItem: StorageItem in pairs(gameSave.Clothing.Container) do
			local itemId = storageItem.ItemId;

			local storagePresetLib = modStoragePresetsLibrary:Find(itemId);
			if storagePresetLib == nil then continue end;
			
			local storageConfig = storagePresetLib.Configuration;
			
			local new = {
				StorageId = siid;
				ItemId = itemId;
				StorageItemId = siid;
				StorageSize = storageConfig.Size;
			};
			table.insert(portableStorages, new);
			equippedStorageIds[new.StorageId] = new;

			local storage: Storage = modStorage.openStorage(siid, {
				Player = player;
				
				StorageName = storageConfig.Name;
				StoragePresetLib = storagePresetLib;
			});
			storage.OnChanged:Connect(onStorageChanged); -- doesn't reconnect if func already exists
		end
		
		table.sort(portableStorages, function(a, b)
			return a.StorageSize > b.StorageSize;
		end)
		
		local unequippedStorages = {};
		for a=1, #gameSave.Inventory.LinkedStorages do
			local oldInfo = gameSave.Inventory.LinkedStorages[a];
			if equippedStorageIds[oldInfo.StorageId] == nil then
				unequippedStorages[oldInfo.StorageId] = oldInfo;
			end
		end
		
		table.clear(gameSave.Inventory.LinkedStorages);
		for a=1, #portableStorages do
			local linkStorageInfo = portableStorages[a];
			table.insert(gameSave.Inventory.LinkedStorages, linkStorageInfo);
		end
		
		
		for storageId, linkStorageInfo in pairs(unequippedStorages) do
			local storage: Storage = modStorage.Get(linkStorageInfo.StorageId);
			if storage and storage.Locked ~= true then
				storage:Loop(function(storageItem)
					gameSave.Inventory:InsertRequest(storageItem);
				end)
				storage:Destroy();
			end
		end
		
	end)

	gameSave.AppearanceData.UpdateReady = true;
	gameSave.WorkbenchSeed = modSyncTime.TimeOfEndOfDay();
	gameSave.LoadoutSaves = modLoadoutSaves.new(player, gameSave);

	local storages = gameSave.Storages;

	local keychainStorage: Storage = modStorage.new("keychain", "keychain", player);
	storages.keychain = keychainStorage;
	keychainStorage:ConnectCheck(function(packet)
		local dragStorageItem = packet.DragStorageItem;
		local targetStorageItem = packet.TargetStorageItem;
		
		if packet.DragStorage == storages.keychain then 
			packet.Allowed = true;
			return packet;
		end;
		if targetStorageItem and dragStorageItem.ItemId == targetStorageItem.ItemId then 
			packet.Allowed = true;
			return packet;
		end; -- true if swapping with item of same id
		
		if dragStorageItem then
			local isKeyItem = modItemsLibrary:HasTag(dragStorageItem.ItemId, "Key");
			if isKeyItem then
				packet.Allowed = true;
				return packet;
			end

			packet.FailMsg = `{dragStorageItem.Library.Name} is not a key.`;
		end
		
		packet.Allowed = false;
		return packet;
	end);
	keychainStorage.OnChanged:Connect(function()
		local itemCount = keychainStorage:Loop();

		local lastSize = keychainStorage.Size;
		keychainStorage.Size = math.max(5, 5+ math.ceil(itemCount/5)*5);
		keychainStorage.MaxSize = keychainStorage.Size;
		
		if lastSize ~= keychainStorage.Size then
			keychainStorage:Sync(player);
		end
	end)
end)

shared.coreBind(modGameSave, "_loaded", function(gameSave: GameSaveAlmdes)
	local profile: ProfileAlmdes = gameSave.Profile;
	local player: Player = profile.Player;
	Debugger:Warn("OnLoadedSave", player);

	for storageId, storage: Storage in pairs(gameSave.Storages) do
		storage:Wipe();
		Debugger:Warn(`Wiped storage: {storageId}`);
	end
end)

return modGameSave;