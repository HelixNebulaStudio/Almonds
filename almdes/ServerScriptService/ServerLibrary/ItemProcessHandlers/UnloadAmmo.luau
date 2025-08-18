local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

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

Handler.RequestActions = {"unloadammorequest"}
function Handler:ClientRequest(action, packet, rPacket)
    local itemProcessor = self.ItemProcessor;
    local player = self.Player;

    if action == "unloadammorequest" then
		local siid = packet.StorageItemId;
		local storageId = packet.StorageId;

		local storage = modStorage.Get(storageId, player);
		local storageItem = storage:Find(siid);

		if storageItem == nil then
			return rPacket;
		end

        local profile: ProfileAlmdes = shared.modProfile:Get(player);
		local playerClass: PlayerClass = shared.modPlayers.get(player);
		local wieldComp: WieldComp = playerClass.WieldComp;
		
		local equipmentClass: EquipmentClass = wieldComp:GetEquipmentClass(siid, storageItem.ItemId, storageItem);

		local configurations = equipmentClass.Configurations;

		local itemId = configurations.AmmoType;
		local quantity = storageItem:GetValues("A") or configurations.AmmoLimit;

		if quantity > 0 then
			storageItem:SetValues("A", 0);
			storageItem:Sync("A");

			local newStorageItem = {ItemId=itemId; Quantity=quantity;} :: StorageItem;
			local rPacket = profile.ActiveInventory:InsertRequest(newStorageItem);
			
			rPacket.Success = true;
			
		else
			shared.Notify(player, "Weapon is empty.", "Negative");
			
		end

		return rPacket;

    end

    return rPacket;
end

return Handler;