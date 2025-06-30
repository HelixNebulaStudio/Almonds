local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modCrates = shared.require(game.ReplicatedStorage.Library.Crates);
local modScheduler = shared.require(game.ReplicatedStorage.Library.Scheduler);

local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);

local WorldLoot = {};
WorldLoot.__index = WorldLoot;
WorldLoot.Scheduler = nil;

WorldLoot.LootSpawnMetaData = {};
WorldLoot.LootCounter = 0;
--==

function WorldLoot:RequestSpawn()
	local lootCrates = CollectionService:GetTagged("LootCrates");
    local lootSpawnAttList = CollectionService:GetTagged("LootSpawn");

	if #lootSpawnAttList < 0 then 
        Debugger:Warn("No loot spawns."); 
        return; 
    end;
	
	local playersList = game.Players:GetPlayers();
	local numOfPlayers = math.max(#playersList, 1);

    for a=#lootCrates, numOfPlayers*4 do
        local rewards = modCrates.GenerateRewards("envlootcrate");
        if #rewards <= 0 then continue end;

        local curTick = tick();

        -- Pick Spawn
        local pickedSpawn;
        repeat
            if #lootSpawnAttList <= 0 then break; end;

            local spawnAtt = table.remove(lootSpawnAttList, math.random(1, #lootSpawnAttList));
            if spawnAtt == nil then break; end;

            local lootSpawnMetaData = WorldLoot.LootSpawnMetaData[spawnAtt];
            if lootSpawnMetaData and lootSpawnMetaData.SpawnCooldown > curTick then continue end;
            if lootSpawnMetaData and lootSpawnMetaData.LootCrate then continue end;

            lootSpawnMetaData = {
                SpawnCooldown = curTick + 60;
                LootCrate = nil;
            };
            WorldLoot.LootSpawnMetaData[spawnAtt] = lootSpawnMetaData;

            pickedSpawn = spawnAtt;
            
            break;
        until not true;
        if pickedSpawn == nil then continue end;

        local crateModel: Model;
        local interactable: InteractableInstance;
        local storage: Storage;

        crateModel, interactable, storage = modCrates.Create(
            "envlootcrate", 
            pickedSpawn.WorldCFrame * CFrame.Angles(0, math.rad(180), 0)
        );

        for b=1, #rewards do
            local item = rewards[b];
            local itemId = item.ItemId;
            local quantity = 1;

            if type(item.Quantity) == "table" then
                quantity = math.random(item.Quantity.Min, item.Quantity.Max);
            elseif item.Quantity then
                quantity = item.Quantity;
            end

            storage:Add(itemId, {Quantity=quantity;});
        end
        
        local looted = false;
        storage.OnChanged:Connect(function()
            if #rewards > storage:Loop() and not looted then
                looted = true;
                
                task.delay(60, function()
                    Debugger:Log("Despawn storage ", storage.Id);
                    storage:Destroy();

                    storage:Loop(function(storageItem: StorageItem)
                        modItemDrops.Spawn(
                            {
                                Type = "Custom";
                                ItemId = storageItem.ItemId;
                                StorageItem = storageItem;
                            }, 
                            pickedSpawn.WorldCFrame + Vector3.new(0, 1, 0), nil, 
                            60
                        );
                    end)
                end)
            end
        end)
        
        WorldLoot.LootSpawnMetaData[pickedSpawn].LootCrate = crateModel;
        crateModel.Destroying:Connect(function()
            WorldLoot.LootSpawnMetaData[pickedSpawn].LootCrate = nil;
        end)

        WorldLoot.LootCounter = WorldLoot.LootCounter + 1;
        crateModel.Name = `loot{WorldLoot.LootCounter}`
        
        CollectionService:AddTag(crateModel, "LootCrates");
        Debugger:Log("Spawnned loot", storage.Id);
    end
end

function WorldLoot.init()
    if WorldLoot.Scheduler == nil then
        WorldLoot.Scheduler = modScheduler.new("WorldLoot", 1);

        local function spawnRequestSchedule()
            WorldLoot:RequestSpawn();
            WorldLoot.Scheduler:ScheduleFunction(spawnRequestSchedule, tick()+1);
        end
        spawnRequestSchedule();
    end

    CollectionService:GetInstanceRemovedSignal("LootSpawn"):Connect(function(instance)
        WorldLoot.LootSpawnMetaData[instance] = nil;
    end);
end

return WorldLoot;