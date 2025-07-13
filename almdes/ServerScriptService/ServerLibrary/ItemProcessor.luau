local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modScheduler = shared.require(game.ReplicatedStorage.Library.Scheduler);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManagerAlmdes);
local modStrings = shared.require(game.ReplicatedStorage.Library.Util.Strings);

local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);

local ItemProcessor = {};
ItemProcessor.__index = ItemProcessor;
ItemProcessor.ProcessCount = 0;

ItemProcessor.ProcessTypes = {};
ItemProcessor.RequestActionHandlers = {};
ItemProcessor.ProcessHandlers = {};
--==

local Queue = {};
Queue.__index = Queue;

function Queue.new()
    local meta = {
        Concurrency = 1;
    };

    function meta:__index(key)
        if key == "meta" then
            return meta;
        end
        local v = rawget(self, key);
        if v ~= nil then
            return v;
        end

        return meta[key];
    end

    local self = {};

    setmetatable(self, meta);
    setmetatable(meta, Queue);
    return self;
end

function Queue:SetConcurrency(concurrency)
    self.meta.Concurrency = concurrency;
end

function Queue:Add(processData)
    table.insert(self, processData);
end

function Queue:Process()
    local list = self;
    if #list == 0 then return end;

    local concur = self.Concurrency;
    if concur <= 0 then return end;

    local curServerTick = workspace:GetServerTimeNow();
    for a=1, #list do
        local processData = list[a];
        if a > concur then
            processData.QueueIndex = a-concur;
            processData.EndTick = nil;
            continue;
        end

        processData.QueueIndex = nil;
        if processData.EndTick == nil then
            processData.EndTick = curServerTick + processData.Duration;
        elseif curServerTick > processData.EndTick then
            processData.Complete = true;
        end
    end
end
ItemProcessor.Queue = Queue;

function ItemProcessor.onRequire()
    remoteItemProcessor = modRemotesManager:Get("ItemProcessor");

    for _, module in pairs(game.ServerScriptService.ServerLibrary.ItemProcessHandlers:GetChildren()) do
        local handler = shared.require(module);
        
        local processKey = module.Name;
        local processType = modStrings.ExtractUppercase(processKey);
        ItemProcessor.ProcessTypes[processKey] = processType;

        for _, k in pairs(handler.RequestActions) do
            ItemProcessor.RequestActionHandlers[k] = processType;
        end

        ItemProcessor.ProcessHandlers[processType] = handler;
    end

    function remoteItemProcessor.OnServerInvoke(player, action, packet)
        local profile: ProfileAlmdes = shared.modProfile:Get(player);
        local gameSave: GameSaveAlmdes = profile:GetActiveSave() :: GameSaveAlmdes;
        local itemProcessor = gameSave.ItemProcessor;
        
        local rPacket = {};
        
        -- if action == "dropitemrequest" then
        --     local storageItemId = packet.StorageItemId;
        --     local storageId = packet.StorageId;
            
        --     local storage = modStorage.Get(storageId, player);
        --     local storageItem = storage:Find(storageItemId);
            
        --     local isValid, invalidReason = modStorage.Validate(player, storageId, storageItemId);
        --     if not isValid then
        --         Debugger:Log("Invalid storage: ", invalidReason);
        --         return rPacket;
        --     end
            
            
        --     local playerClass = shared.modPlayers.get(player);
        --     local rootCFrame = playerClass.RootPart.CFrame;
            
        --     modItemDrops.Spawn(
        --         {Type="Custom"; ItemId=storageItem.ItemId; StorageItem=storageItem;}, 
        --         rootCFrame + rootCFrame.LookVector, nil, 300
        --     );
            
        --     storage:Remove(storageItem.ID, storageItem.Quantity);
        --     storage:Sync();
            
        --     rPacket.Success = true;
            
        --     return rPacket;
            
        -- elseif action == "unloadammorequest" then
        --     local storageItemId = packet.StorageItemId;
        --     local storageId = packet.StorageId;

        --     local storage = modStorage.Get(storageId, player);
        --     local storageItem = storage:Find(storageItemId);

        --     local isValid, invalidReason = modStorage.Validate(player, storageId, storageItemId);
        --     if not isValid then
        --         Debugger:Log("Invalid storage: ", invalidReason);
        --         return rPacket;
        --     end

        --     local weaponModule = profile:GetItemClass(storageItemId);
        --     if weaponModule == nil then
        --         Debugger:Log("Invalid weaponModule: ", storageItemId);
        --         return rPacket;
        --     end
        --     local configurations = weaponModule.Configurations;
            
        --     local itemId = configurations.AmmoType;
        --     local quantity = storageItem:GetValues("A") or configurations.AmmoLimit;
            
        --     if quantity > 0 then
        --         storage:SetValues(storageItemId, {A=0;});
        --         storage:SetValues(storageItemId, {UpdateAmmo=true;});

        --         local rPacket = profile.ActiveInventory:InsertRequest{ItemId=itemId; Quantity=quantity;};
        --         rPacket.Success = true;
                
        --     else
        --         shared.Notify(player, "Weapon is empty.", "Negative");
                
        --     end

        --     return rPacket;
            
        -- elseif action == "craftrequest" then
        --     local recipeId = packet.RecipeId;
            
        --     local recipeLib = modRecipeLibrary:Find(recipeId);
        --     if recipeLib == nil then return rPacket end;
            
        --     local unlockedRecipes = profile.GameSave.RecipesUnlocked;
        --     if recipeLib.Workbench ~= nil and unlockedRecipes[recipeId] == nil then return rPacket end;

        --     local fulfill, resultList = modStorage.FulfillList(player, recipeLib.Recipe);
        --     if not fulfill then Debugger:Log("NeedList", resultList) end;

        --     if not fulfill then
        --         shared.Notify(player, "Insufficient Resources.", "Negative");
        --         return rPacket;
        --     end;
            
        --     if itemProcessor.Queue.CraftRecipe and #itemProcessor.Queue.CraftRecipe > 5 then
        --         shared.Notify(player, "Crafting queue is full.", "Negative");
        --         return rPacket;
        --     end;
            
        --     modStorage.ConsumeList(resultList);
            
        --     itemProcessor:NewProcess("Queue", {
        --         Type=tostring(ProcessTypes.CraftRecipe);
        --         Id=recipeId;
        --         Duration=recipeLib.Duration or 1;
        --     })
            
        --     rPacket.Success = true;
        --     rPacket.Data = itemProcessor;
            
  
        -- elseif action == "unlockreciperequest" then
        --     local index = packet.Index;
        --     local recipeId = packet.RecipeId;

        --     local recipeLib = modRecipeLibrary:Find(recipeId);
        --     if recipeLib == nil then
        --         shared.Notify(player, "Invalid recipe.", "Negative");
        --         return rPacket;
        --     end;

        --     local unlockedRecipes = profile.GameSave.RecipesUnlocked;
        --     if unlockedRecipes[recipeId] ~= nil then
        --         shared.Notify(player, "Already unlocked.", "Negative");
        --         return rPacket;
        --     end;
            
        --     if packet.WorkbenchPart == nil or not packet.WorkbenchPart:HasTag("Workbench") then
        --         shared.Notify(player, "Missing Workbench.", "Negative");
        --         return rPacket;
        --     end

        --     local wbSeed = profile.GameSave.WorkbenchSeed;
        --     local list = modRecipeLibrary:GetTechTree(wbSeed);
            
            
        --     local refundList = {};
        --     local recipeList = recipeLib.Recipe;
        --     local consumeRatio = math.clamp((math.random() ^ (1/2) + 0.1), 0.1, 1);
            
        --     Debugger:Log("GetTechTree", list, " consumeRatio", consumeRatio, " recipeList", recipeList);
            
        --     for a=1, #recipeList do
        --         local recipeItem = recipeList[a];
        --         if recipeItem.Type == "Item" then
        --             local returnAmt = math.max(math.floor(recipeItem.Amount * consumeRatio), 1);
        --             table.insert(refundList, {ItemId=recipeItem.ItemId; Quantity=returnAmt;});
        --         end
        --     end
            
        --     local fulfill, resultList = modStorage.FulfillList(player, recipeList);
        --     if not fulfill then Debugger:Log("NeedList", resultList) end;

        --     if not fulfill then
        --         shared.Notify(player, "Insufficient Resources.", "Negative");
        --         return rPacket;
        --     end;

        --     modStorage.ConsumeList(resultList);
            
        --     local meta = {};
        --     meta.__index = meta;
            
        --     meta.RefundList=refundList;
        --     meta.ConsumeRatio=consumeRatio;
            
        --     itemProcessor:NewProcess("Concurrent", setmetatable({
        --         Type=tostring(ProcessTypes.UnlockRecipe);
        --         Id=recipeId;
        --         Duration=recipeLib.Duration or 1;
        --     }, meta));

        --     rPacket.Success = true;
        --     rPacket.Data = itemProcessor;
            
            
        -- end
        
        if action == "sync" then
            itemProcessor:ProcessQueues();

            rPacket.Success = true;
            rPacket.Data = itemProcessor;
        end
        
        local requestHandlerProcessType = itemProcessor.RequestActionHandlers[action];
        if requestHandlerProcessType then
            local handler = itemProcessor.Handlers[requestHandlerProcessType];
            rPacket = handler:ClientRequest(action, packet, rPacket);
        end

        return rPacket;
    end
end

function ItemProcessor.new()
	local meta = {};
	meta.__index = meta;
	
	meta.Player = nil;
	meta.Storage = nil;

    meta.Handlers = {};

    local self = {
        Queues = {};
    };

    setmetatable(self, meta);
    setmetatable(meta, ItemProcessor);

    return self;
end

function ItemProcessor:Setup(player, storage)
    local meta = getmetatable(self);

    meta.Player = player;
    meta.Storage = storage;
    meta.Scheduler = modScheduler.new(`{player}ItemProcessor`, 1/10);

    for pType, handler in pairs(ItemProcessor.ProcessHandlers) do
        local newHandler = handler.new(self);
        meta.Handlers[pType] = newHandler;
        self.Queues[pType] = newHandler.Queue;
    end
end

function ItemProcessor:Destroy()
    self.Player = nil;
    self.Storage = nil;
    self.Scheduler:Destroy();
end

function ItemProcessor.newProcessData()
    local meta = {};

    function meta:__index(key)
        if key == "meta" then
            return meta;
        end
        return rawget(self, key);
    end

    return setmetatable({}, meta);
end


function ItemProcessor:AddProcess(processData)
	local curServerTime = workspace:GetServerTimeNow();
	local processType = processData.Type;

    local handler = self.Handlers[processType];
    local processQueue = handler.Queue;

    ItemProcessor.ProcessCount = ItemProcessor.ProcessCount + 1;
    processData.Num = ItemProcessor.ProcessCount;
    processData.AddTick = curServerTime;

    processQueue:Add(processData);

    self:ProcessQueues();
end

function ItemProcessor:ProcessQueues()
    local nextClosestTick = math.huge;
    local nextClosestProcessData = nil;

    for _, queue in pairs(self.Queues) do
        queue:Process();

        local concur = queue.Concurrency;
        local a = 1;
        for _=1, #queue do
            local processData = queue[a];
            if a > concur then
                continue;
            end
            if processData.Complete ~= true then 
                a = a+1;
                continue;
            end;

            processData = table.remove(queue, a);

            task.spawn(function()
                local handler = self.Handlers[processData.Type];
                if handler.BindProcessComplete then
                    handler:BindProcessComplete(processData);
                end
            end)
        end
        for a=1, #queue do
            local processData = queue[a];
            if processData.EndTick == nil then continue end;
            nextClosestTick = math.min(nextClosestTick, processData.EndTick);
            nextClosestProcessData = processData;
        end
    end

    if nextClosestProcessData == nil then return end;
    local processData = nextClosestProcessData;

    local duration = processData.Duration;
    self.Scheduler:ScheduleFunction(function()
        self:ProcessQueues();
    end, tick() + duration);

    self:Sync();
end

function ItemProcessor:Sync()
	if self.Storage.Player == nil then return end;

	self.Tick = tick();
	task.spawn(function()
		remoteItemProcessor:InvokeClient(self.Player, "sync", {
			Data = self;
		});
	end);
end

return ItemProcessor;