local modStoragePresetsLibrary = shared.require(game.ReplicatedStorage.Library.StoragePresetsLibrary);

modStoragePresetsLibrary:Replace("Inventory", {
	Name = "Inventory";
    Configuration = {
        Persistent=true;
        Size = 12;
        MaxSize = 12;
    };
});

modStoragePresetsLibrary:Replace("Clothing", {
	Name = "Clothing";
    Configuration = {
        Persistent=true;
        Size = 5;
        MaxSize = 5;
    };
});

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
});

modStoragePresetsLibrary:Replace("largecrate", {
	Name = "Large Crate";
    PublicStorage = true;
    Configuration = {
        Persistent=true;
        Size = 30;
        MaxSize = 30;
    };
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
};


return modStoragePresetsLibrary;