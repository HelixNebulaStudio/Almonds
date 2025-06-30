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


return modStoragePresetsLibrary;