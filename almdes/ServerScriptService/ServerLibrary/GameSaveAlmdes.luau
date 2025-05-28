local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modGameSave = shared.require(game.ServerScriptService.ServerLibrary.GameSave);

local modUsableItems = shared.require(game.ReplicatedStorage.Library.UsableItems);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);

local modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
local modItemFactory = shared.require(game.ServerScriptService.ServerLibrary.ItemFactory);
local modPortableStorages = shared.require(game.ServerScriptService.ServerLibrary.PortableStorages);

--==
shared.coreBind(modGameSave, "_new", function(gameSave: GameSaveAlmdes, profile: ProfileAlmdes)
	local player = profile.Player;
	Debugger:Warn("OnNewSave", player);

	local saveMeta = getmetatable(gameSave :: any);
	saveMeta.ItemFactory = modItemFactory.new();
	-- saveMeta.ItemFactory:GetMeta()["Player"] = player;
	-- saveMeta.ItemFactory:GetMeta()["Storage"] = gameSave.Inventory;
	
	gameSave.Inventory.MaxSize = 12;
	gameSave.Inventory.Size = gameSave.Inventory.MaxSize;
	gameSave.Inventory.PremiumStorage = 12;
	
	gameSave.Clothing.OnChanged:Connect(function()
		local portableStorages = {};
		local equippedStorageIds = {};
		
		for storageItemId, storageItem in pairs(gameSave.Clothing.Container) do
			local itemId = storageItem.ItemId;

			local usableItemLib = modUsableItems:Find(itemId);
			if usableItemLib and usableItemLib.PortableStorage then
				local storageConfig = usableItemLib.PortableStorage;
				
				local new = {
					StorageId=storageItemId;
					ItemId=itemId;
					StorageItemId=storageItemId;
					StorageSize=storageConfig.Size;
				};
				table.insert(portableStorages, new);
				equippedStorageIds[new.StorageId] = new;

				local storage = modPortableStorages.OpenStorage(storageItemId, itemId, storageConfig);
				storage:SetOwner(player);
			end
		end
		
		table.sort(portableStorages, function(a, b) return a.StorageSize > b.StorageSize; end)
		
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
			local storage = modStorage.Get(linkStorageInfo.StorageId);
			if storage then
				storage:Loop(function(storageItem)
					gameSave.Inventory:InsertRequest(storageItem);
				end)
				storage:Destroy();
			end
		end
		
	end)

	gameSave.WorkbenchSeed = modSyncTime.TimeOfEndOfDay();
	
	Debugger:Warn("profile.DayRollOver", profile.DayRollOver, "data.WorkbenchSeed", gameSave.WorkbenchSeed);
	gameSave.RecipesUnlocked = {};
end)

function modGameSave.onRequire()

end

return modGameSave;