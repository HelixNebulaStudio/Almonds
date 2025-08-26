local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modStoragePresetsLibrary = shared.require(game.ReplicatedStorage.Library.StoragePresetsLibraryAlmdes);

local modStorages = shared.require(game.ServerScriptService.ServerLibrary.StorageAlmdes);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManagerAlmdes);

local LoadoutSaves = {};
LoadoutSaves.__index = LoadoutSaves;
--==
function LoadoutSaves.onRequire()
    local remoteLoadoutSaves = modRemotesManager:Get("LoadoutSaves");

    function remoteLoadoutSaves.OnServerInvoke(player: Player, action: string, pPacket)
        Debugger:Warn("LoadoutSaves", action, pPacket);
        local profile: ProfileAlmdes = shared.modProfile:Get(player);
        local gameSave: GameSaveAlmdes = profile:GetActiveSave() :: GameSaveAlmdes;
        local loadoutSaves: LoadoutSaves = gameSave.LoadoutSaves;

        if action == "fetch" then
            local rPacket = {
                Success = true;
                Data = loadoutSaves:Shrink();
            };

            return rPacket;
        end

        return {};
    end

	shared.modCommandsLibrary.bind{
		["loadouts"] = {
			Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
			Description = [[Loadout commands for Almonds.
            
            /loadouts print
            /loadouts reset
            ]];

			RequiredArgs = 0;
			UsageInfo = "/loadouts action [args]";
			Function = function(player, args)
                local profile: ProfileAlmdes = shared.modProfile:Get(player);
                local gameSave: GameSaveAlmdes = profile:GetActiveSave() :: GameSaveAlmdes;
                local loadoutSaves: LoadoutSaves = gameSave.LoadoutSaves;

				local playerClass: PlayerClass = shared.modPlayers.get(player);
				local actionId = args[1];

                if actionId == "print" then
                    Debugger:Log("LoadoutSaves", gameSave.LoadoutSaves);

                elseif actionId == "reset" then
                    table.clear(loadoutSaves.Loadouts);
                    loadoutSaves.ActiveLoadout = 1;

                end
				return true;
			end;
		};
	};
end

function LoadoutSaves.new(player: Player, gameSave: GameSaveAlmdes)
    local meta = {
        Player = player;
        GameSave = gameSave;
    };
    meta.__index = meta;

	local self = {
        ActiveLoadout = 1;
        MaxLoadouts = 3;
        Loadouts = {};
    };

    setmetatable(meta, LoadoutSaves);
    setmetatable(self, meta);
    return self;
end

function LoadoutSaves:Load(data: any)
    if getmetatable(data) == getmetatable(self) then    -- No raw data to load.
        return self;
    end

    local player: Player = self.Player;

    for key, value in pairs(data) do
        if key == "Loadouts" then
            for loadoutIndex, loadout in pairs(value) do
                local coldStorages = loadout.ColdStorages;

                for sId, rawStorage in pairs(coldStorages) do
                    local newStorage: Storage = modStorages.new(sId, rawStorage.PresetId, player);
				    newStorage:Load(rawStorage);

                    coldStorages[sId] = newStorage;
                end
            end
            
            self[key] = value;

        else
            self[key] = value;
        end
    end

    return self;
end

function LoadoutSaves:Shrink()
    local r = {
        ActiveLoadout = self.ActiveLoadout;
        MaxLoadouts = self.MaxLoadouts;
        Loadouts = {};
    };

    for loadoutIndex, loadout in pairs(self.Loadouts) do
        local rawLoadout = {
            ColdStorages = {};
        };
        for sId, storage: Storage in pairs(loadout.ColdStorages) do
            rawLoadout.ColdStorages[sId] = storage:Shrink();
        end

        r.Loadouts[loadoutIndex] = rawLoadout;
    end

    return r;
end

function LoadoutSaves:LoadActiveLoadout()
    local gameSave: GameSaveAlmdes = self.GameSave;
    local activeLoadout = self.ActiveLoadout;

    local loadout = self.Loadouts[activeLoadout];
    if loadout == nil then return end;

    local coldStorages = loadout.ColdStorages;
    if coldStorages.Inventory then
        coldStorages.Inventory:TransferContainer(gameSave.Inventory);
    end

    local clothingStorages = {};
    if coldStorages.Clothing then
        for siid, storageItem: StorageItem in pairs(coldStorages.Clothing.Container) do
            local portableStorage: Storage = coldStorages[siid];
            if portableStorage == nil then continue end;
            clothingStorages[storageItem] = portableStorage;
        end
        coldStorages.Clothing:TransferContainer(gameSave.Clothing);
    end

    for siid, storageItem: StorageItem in pairs(gameSave.Clothing.Container) do
        local portableStorage: Storage = clothingStorages[storageItem];
        if portableStorage == nil then continue end;

        local newStorage = shared.modStorage.get(siid);
        if newStorage == nil then continue end;

        portableStorage:TransferContainer(newStorage);
    end

    gameSave.Inventory:Sync(self.Player);
end

function LoadoutSaves:SaveActiveLoadout()
    local gameSave: GameSaveAlmdes = self.GameSave;
    local activeLoadout = self.ActiveLoadout;

    local loadout = {
        ColdStorages = {};
    };
    local coldStorages = loadout.ColdStorages; -- Inactive storages

    local clothingStorages = {};
    for siid, storageItem: StorageItem in pairs(gameSave.Clothing.Container) do
        local storage: Storage = modStorages.get(siid);
        if storage == nil then continue end;
        clothingStorages[storageItem] = storage;
    end

    for storageId, storage: Storage in pairs(gameSave.Storages) do
        Debugger:Warn("Saving storage", storageId);

        local newStorage: Storage = modStorages.new(storageId, storage.PresetId, self.Player);
        coldStorages[storageId] = newStorage;

        storage:TransferContainer(newStorage);
        
        if storageId == "Clothing" then
            for siid, storageItem: StorageItem in pairs(newStorage.Container) do
                local portableStorage: Storage = clothingStorages[storageItem];
                if portableStorage == nil then
                    Debugger:Warn(`Missing portable storage {siid}`);
                    continue;
                end
                
                local newPortableStorage: Storage = modStorages.new(siid, portableStorage.PresetId, self.Player);
                coldStorages[siid] = newPortableStorage;

                portableStorage:TransferContainer(newPortableStorage);
            end
        end
    end

    self.Loadouts[activeLoadout] = loadout;
    Debugger:StudioLog("LoadoutSaves:Save", self);
    
	for storageId, storage: Storage in pairs(gameSave.Storages) do
		storage:Wipe();
	end

end

return LoadoutSaves;