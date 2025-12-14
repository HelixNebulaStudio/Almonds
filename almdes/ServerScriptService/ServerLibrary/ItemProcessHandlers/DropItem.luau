local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);

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
	
	self.Queue:SetConcurrency(2);
	return self;
end

Handler.RequestActions = {"dropitemrequest"}
function Handler:ClientRequest(action, packet, rPacket)
    local itemProcessor = self.ItemProcessor;
    local player = self.Player;

    if action == "dropitemrequest" then
		local storageItemId = packet.StorageItemId;
		local storageId = packet.StorageId;
		
		local storage = modStorage.Get(storageId, player);
		local storageItem = storage:Find(storageItemId);
		if storageItem == nil then return rPacket; end;

		local clonedStorageItem: StorageItem = storageItem:Clone();
		
		local playerClass: PlayerClass = shared.modPlayers.get(player);
		local rootCFrame = playerClass:GetCFrame();
		
		storage:Remove(storageItem.ID, storageItem.Quantity);

		modItemDrops.spawn{
			StorageItem = clonedStorageItem;
			SpawnCFrame = (rootCFrame + rootCFrame.LookVector);
			DespawnDuration = false;
			DisableTouchPickup = true;
		};
		
		rPacket.Success = true;
		
		return rPacket;
    end

    return rPacket;
end

return Handler;