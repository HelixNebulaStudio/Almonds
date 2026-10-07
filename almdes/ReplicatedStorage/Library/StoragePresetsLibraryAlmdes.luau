local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modStoragePresetsLibrary = shared.require(game.ReplicatedStorage.Library.StoragePresetsLibrary);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibraryAlmdes);
local modStorageItem = shared.require(game.ReplicatedStorage.Library.StorageItem);

local modBoolString = shared.require(game.ReplicatedStorage.Library.Util.BoolString);

--MARK: Inventory Storage Preset
local inventoryStoragePreset = {
	Name = "Inventory";
    Configuration = {
        Persistent=true;
        Size = 12;
        MaxSize = 12;
    };
    GunSlot = {1;2;};
    DesignatedSlots = {
        [1] = {TagBoolString = "Gun"; FailMsg = "Gun slot is only for guns.";};
        [2] = {TagBoolString = "Gun"; FailMsg = "Gun slot is only for guns.";};
        [3] = {TagBoolString = "Melee"; FailMsg = "Melee slot is only for melees.";};
        ["*"] = {TagBoolString = "!(Gun|Melee)"; FailMsg = "Weapons does not fit in your inventory.";};
    };
};

function inventoryStoragePreset.BindStorageCheck(packet)
	local dragStorageItem = packet.DragStorageItem;
	local targetIndex = packet.TargetIndex;

    local designatedSlotInfo = inventoryStoragePreset.DesignatedSlots[targetIndex]
                            or inventoryStoragePreset.DesignatedSlots["*"];
    if designatedSlotInfo then
        local checkBsFunc = designatedSlotInfo.TagBsCheckFunc;
        if checkBsFunc == nil then
            checkBsFunc = modBoolString.newTestFunction(designatedSlotInfo.TagBoolString);
            designatedSlotInfo.TagBsCheckFunc = checkBsFunc;
        end
    
        local itemLib = modItemsLibrary:Find(dragStorageItem.ItemId);
        local isAllowed = checkBsFunc(itemLib.Tags or {});

        if isAllowed then
            packet.Allowed = true;
			return packet;
        else
            packet.FailMsg = designatedSlotInfo.FailMsg or `Not allowed ({designatedSlotInfo.TagBoolString}).`;
        end

    else
        packet.Allowed = true;
        return packet;
    end

	packet.Allowed = false;
	return packet;
end

function inventoryStoragePreset.BindGetEmptySlotData(selfStorageInterface: StorageInterface, itemSlotB: ItemSlot?)
    local itemLib = itemSlotB and itemSlotB.Library;
    if itemLib == nil then
        return nil;
    end;

	for index=selfStorageInterface.StartIndex, selfStorageInterface.EndIndex do
        local slot = selfStorageInterface.Slots[index];
        if slot.ItemSlot ~= nil or slot.Frame == nil or slot.Frame.Visible == false then continue end;

        local designatedSlotInfo = inventoryStoragePreset.DesignatedSlots[index]
                                or inventoryStoragePreset.DesignatedSlots["*"];
        if designatedSlotInfo then
            local checkBsFunc = designatedSlotInfo.TagBsCheckFunc;
            if checkBsFunc == nil then
                checkBsFunc = modBoolString.newTestFunction(designatedSlotInfo.TagBoolString);
                designatedSlotInfo.TagBsCheckFunc = checkBsFunc;
            end

            local isAllowed = checkBsFunc(itemLib.Tags or {});
            if not isAllowed then
                continue;
            end
        end
		
        return slot;
	end

    return;
end

function inventoryStoragePreset.BindInit(storage: Storage)
    Debugger:Warn(`Init inventory`);
end
modStoragePresetsLibrary:Replace("Inventory", inventoryStoragePreset);


modStoragePresetsLibrary:Replace("Clothing", {
	Name = "Clothing";
    Configuration = {
        Persistent=true;
        Size = 5;
        MaxSize = 5;
    };
});

modStoragePresetsLibrary:Add{
	Id = "keychain";
    Name = "Key Chain";
    Configuration = {
        Persistent = true;
        Size = 5;
        Settings = {
            ScaleByContent = true;
        }
    };
};

modStoragePresetsLibrary:Add{
	Id = "deathpack";
    Name = "Death Pack";
    PublicStorage = true;
    Configuration = {
        Persistent = false;
        Settings = {
            WithdrawalOnly = true;
            DestroyOnEmpty = false;
        }
    };
    CreateStorage=true;
};

modStoragePresetsLibrary:Add{
	Id = "envlootcrate";
    Name = "Crate";
    PublicStorage = true;
    Configuration = {
        Persistent = false;
        Settings = {
            WithdrawalOnly = true;
            DestroyOnEmpty = false;
            ScaleByContent = true;
        }
    };
    CreateStorage=true;
};

modStoragePresetsLibrary:Add{
	Id = "rewardcrate";
    Name = "Crate";
    PublicStorage = true;
    Configuration = {
        Persistent = false;
        Settings = {
            WithdrawalOnly = true;
            DestroyOnEmpty = false;
            ScaleByContent = true;
        }
    };
    CreateStorage=true;
};

modStoragePresetsLibrary:Add{
	Id = "npcinventory";
    Name = "Inventory";
    PublicStorage = true;
    Configuration = {
        Persistent = false;
        Settings = {
            WithdrawalOnly = true;
            DestroyOnEmpty = false;
            ScaleByContent = true;
        }
    };
    CreateStorage=true;
};


--MARK: Clothing
modStoragePresetsLibrary:Add{
	Id = "ammopouch";
	Name = "Ammo Pouch";
    PublicStorage = true;
    Configuration = {
        Persistent=true;
        Size = 6;
        MaxSize = 6;
    };
    CreateStorage=true;
};

modStoragePresetsLibrary:Add{
	Id = "dufflebag";
	Name = "Duffle Bag";
    PublicStorage = true;
    Configuration = {
        Persistent=true;
        Size = 12;
        MaxSize = 12;
    };
    CreateStorage=true;
};

modStoragePresetsLibrary:Add{
	Id = "survivorsbackpack";
	Name = "Survivor's Backpack";
    PublicStorage = true;
    Configuration = {
        Persistent=true;
        Size = 18;
        MaxSize = 18;
    };
    CreateStorage=true;
};

modStoragePresetsLibrary:Add{
	Id = "tacticalvest";
	Name = "Tactical Vest";
    PublicStorage = true;
    Configuration = {
        Persistent=true;
        Size = 6;
        MaxSize = 6;
    };
    CreateStorage=true;
};


--MARK: Structures
modStoragePresetsLibrary:Replace("crate", {
	Name = "Crate";
    PublicStorage = true;
    Configuration = {
        Persistent=true;
        Size = 10;
        MaxSize = 10;
    };
    CreateStorage=true;
});

modStoragePresetsLibrary:Replace("largecrate", {
	Name = "Large Crate";
    PublicStorage = true;
    Configuration = {
        Persistent=true;
        Size = 30;
        MaxSize = 30;
    };
    CreateStorage=true;
});

modStoragePresetsLibrary:Add{
	Id = "furnace";
	Name = "Furnace";
    PublicStorage = true;
    Configuration = {
        Persistent=true;
        Size = 6;
        MaxSize = 6;
    };
    CreateStorage=true;
};

modStoragePresetsLibrary:Add{
	Id = "centralweapons";
	Name = "Weapons Locker";
    Configuration = {
        Persistent = true;
        Size = 10;
        MaxSize = 10;
    };
};

modStoragePresetsLibrary:Add{
	Id = "centralgeneral";
	Name = "Stash";
    Configuration = {
        Persistent = true;
        Size = 40;
        MaxSize = 40;
    };
};


return modStoragePresetsLibrary;