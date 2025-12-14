local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modRecipeLibrary = shared.require(game.ReplicatedStorage.Library.RecipeLibrary);
local modDropRateCalculator = shared.require(game.ReplicatedStorage.Library.DropRateCalculator);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local PROCESSTYPE = script.Name;

local Handler = {};
Handler.__index = Handler;
--==
function Handler.onRequire()
    modStorage = shared.modStorage;
end

function Handler.new(itemProccessor)
	local meta = {};
	meta.__index = meta;
	meta.ItemProcessor = itemProccessor;
    meta.Player = itemProccessor.Player;
	
	local self = {
		Queue = itemProccessor.Queue.new();
	};

	setmetatable(self, meta);
	setmetatable(meta, Handler);
	return self;
end

Handler.RequestActions = {"craftrequest"; "cancelcraft"};
function Handler:ClientRequest(action, packet, rPacket)
    local itemProcessor = self.ItemProcessor;
    local player = self.Player;

    local playerClass: PlayerClass = shared.modPlayers.get(player);

    local profile: ProfileAlmdes = shared.modProfile:Get(player);
    local gameSave: GameSaveAlmdes = profile:GetActiveSave() :: GameSaveAlmdes;

    if action == "craftrequest" then
		Debugger:Log("Request", action, packet, rPacket);
        local recipeId = packet.RecipeId;
        
        local recipeLib = modRecipeLibrary:Find(recipeId);
        if recipeLib == nil then 
            rPacket.FailMsg = "Recipe not found.";
            return rPacket;
        end;
        
        if recipeLib.Workbench then
            local workbenchStatus: StatusClassInstance? = playerClass.StatusComp:GetOrDefault("Workbench");
            local wbInteractable: InteractableInstance = workbenchStatus and workbenchStatus.Values.ActiveInteractable;
            if wbInteractable == nil or wbInteractable.Variant ~= recipeLib.Workbench then
                rPacket.FailMsg = "Invalid workbench.";
                return rPacket;
            end 
        end

        if #self.Queue > 5 then
            rPacket.FailMsg = "Queue is full.";
            shared.Notify(player, "Crafting queue is full!", "Negative");
            return rPacket;
        end

        local fulfill, resultList = modStorage.FulfillList(player, recipeLib.Recipe);
        if not fulfill then
            Debugger:Log("NeedList", resultList);
            shared.Notify(player, "Insufficient Resources.", "Negative");
            return rPacket;
        end;

        modStorage.ConsumeList(resultList);

        local processData = itemProcessor.newProcessData();
        processData.meta.Storage = gameSave.Inventory;

        processData.Type = itemProcessor.ProcessTypes[PROCESSTYPE];
        processData.Id = recipeId;
        processData.Duration = recipeLib.Duration or 5;

        itemProcessor:AddProcess(processData);
        
        rPacket.Success = true;
        rPacket.Data = itemProcessor;

    elseif action == "cancelcraft" then
        Debugger:Log("Cancel", action, packet, rPacket);
        local addTick = packet.AddTick;

        local processData = itemProcessor:RemoveProcess(PROCESSTYPE, addTick);
        if processData == nil or processData.Complete then
            rPacket.FailMsg = `Process not found or completed.`;
            return rPacket;
        end

        local storage: Storage = itemProcessor.Storage;
        local recipeLib = modRecipeLibrary:Find(processData.Id);

        for a=1, #recipeLib.Recipe do
            local rInfo = recipeLib.Recipe[a];
            if rInfo.Type ~= "Item" then continue end;
            
            local rItemId = rInfo.ItemId;
            local quantity = (rInfo.Amount or 1);
            local storageItem = {ItemId=rItemId; Quantity=quantity;} :: StorageItem;
            local _insertRPacket = storage:InsertRequest(storageItem);
        end

        rPacket.Success = true;
        rPacket.Data = itemProcessor;
    end

    return rPacket;
end

function Handler:BindProcessStart(processData)
	local storage = processData.meta.Storage;

    local targetPart;
    if storage.Player then
        local playerClass: PlayerClass = shared.modPlayers.get(storage.Player);
        targetPart = playerClass.Head;
    end

    if targetPart == nil then return end;
    local snd = modAudio.Play("Crafting1", targetPart);
    snd.PlaybackSpeed = math.random(95, 105)/100;
end

function Handler:BindProcessComplete(processData)
	local storage = processData.meta.Storage;

    local itemId = processData.Id;

    local recipeLib = modRecipeLibrary:Find(itemId);
    if recipeLib == nil then return end;

    local itemLib = modItemsLibrary:Find(itemId);

    if storage.Player then
        shared.Notify(storage.Player, `You crafted {recipeLib.Amount or "a"} {itemLib.Name}.`, "Positive");
    end

    local quantity = (recipeLib.Amount or 1);
    local storageItem = {ItemId=itemId; Quantity=quantity;};

    local insertRPacket = storage:InsertRequest(storageItem);
    Debugger:StudioLog("insertRPacket", insertRPacket);
end

return Handler;