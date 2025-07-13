local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modDeconstructLibrary = require(game.ReplicatedStorage.Library.DeconstructLibrary);
local modDropRateCalculator = shared.require(game.ReplicatedStorage.Library.DropRateCalculator);


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
	
	self.Queue:SetConcurrency(2);
	return self;
end

Handler.RequestActions = {"deconstructrequest"}
function Handler:ClientRequest(action, packet, rPacket)
    local itemProcessor = self.ItemProcessor;
    local player = self.Player;

    if action == "deconstructrequest" then
		Debugger:Log("Request", action, packet, rPacket);
        local siid = packet.Siid;
        
        local storageItem: StorageItem?, storage: Storage? = modStorage.FindIdFromStorages(siid, player);
        if storageItem == nil then
            rPacket.FailMsg = `{siid} not found.`;
            return rPacket;
        end

		local exist = false;
		for a=1, #self.Queue do
			local processData = self.Queue[a];
			if processData.Id == siid then
				exist = true;
				break;
			end
		end
		if exist then
			rPacket.FailMsg = "Already deconstructing.";
			return rPacket;
		end

        local itemId = storageItem.ItemId;
        local deconstructLib = modDeconstructLibrary:Find(itemId);
        if deconstructLib == nil then
            rPacket.FailMsg = `{itemId} is not deconstructable.`;
            return rPacket;
        end;
        
        local processData = itemProcessor.newProcessData();
        processData.meta.StorageItem = storageItem;
        processData.meta.Storage = storage;

        processData.Type = itemProcessor.ProcessTypes.ItemDeconstruct;
        processData.Id = siid;
        processData.Duration = deconstructLib.Duration or 5;

        itemProcessor:AddProcess(processData);
        
        rPacket.Success = true;
        rPacket.Data = itemProcessor;
    end

    return rPacket;
end

function Handler:BindProcessComplete(processData)
	local itemProcessor = self.ItemProcessor;
	local storageItem = processData.meta.StorageItem;
	local storage = processData.meta.Storage;

	local siid = processData.Id;

	local targetStorageItem, targetStorage = modStorage.FindIdFromStorages(siid, itemProcessor.Player);
	if targetStorage ~= storage or targetStorageItem ~= storageItem then
		Debugger:Log("Deconstruct cancelled ", siid, targetStorage ~= storage, targetStorageItem ~= storageItem);
		return;
	end;

	Debugger:Log("Deconstruct complete", siid, targetStorageItem, targetStorage);

	modStorage.ConsumeList{
		{Storage=storage; Item=storageItem; Amount=1;};
	};
	
	local deconstructItemId = storageItem.ItemId;
	local deconstructLib = modDeconstructLibrary:Find(deconstructItemId);
	local deconstructItemLib = modItemsLibrary:Find(deconstructItemId);
	
	local products = modDropRateCalculator.RollDrop(deconstructLib);
	
	if products == nil or #products < 0 then
		Debugger:StudioLog("No products");
		return;
	end
	
	for b=1, #products do
		local item = products[b];
		local itemId = item.ItemId;
		local itemLib = modItemsLibrary:Find(itemId);

		local quantity = item.Quantity or 1;
		if typeof(item.Quantity) == "table" then
			quantity = math.random(item.Quantity.Min, item.Quantity.Max);
		end

		local newStorageItem = {ItemId=itemId; Quantity=quantity;};
		local rPacket = storage:InsertRequest(newStorageItem);
		if rPacket.Success then
			if storage.Player then
				shared.Notify(
					storage.Player, 
					`You received {quantity} {itemLib.Name} from deconstructing {deconstructItemLib.Name}.`, 
					"Positive"
				);
			end
		end
	end
end

return Handler;