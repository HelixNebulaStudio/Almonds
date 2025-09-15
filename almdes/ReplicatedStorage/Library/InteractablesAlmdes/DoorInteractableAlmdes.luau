local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local DoorAlmdes = {
		Name = "DoorAlmdes";
        Type = "Door";

        IndicatorPresist = false;
        InteractableRange = 24;
    };

    function DoorAlmdes.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Action == "Client" or RunService:IsClient() then
            interactable.TypePackage.BindInteract(interactable, info);
            return;
        end;

        local keyId = interactable.Values.KeylockId;
        if keyId ~= nil then
            local hasKey = false;

            local player: Player? = info.Player;
            if player then
                local lockKeyList, _lockKeysCount = shared.modStorage.listItemIdFromStorages("lockkey", player);

                for a=1, #lockKeyList do
                    local storageItem: StorageItem = lockKeyList[a].Item;

                    if storageItem.Values.KeyId == keyId then
                        hasKey = true;
                        break;
                    end
                end
            end
            
            if not hasKey then
                return 
            end;
        end;

        interactable.TypePackage.BindInteract(interactable, info);
    end
    
    function DoorAlmdes.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        interactable.TypePackage.BindPrompt(interactable, info);
        if RunService:IsServer() then return end;

        local clientData = info.ClientData;
        if clientData == nil then return end;

        local keyId = interactable.Values.KeylockId;
        if keyId == nil then return end;

        local hasKey = false;
        local allLockKeys = clientData.ListItemIdFromCharacter("lockkey");
        for siid, lockKey: StorageItem in ipairs(allLockKeys) do
            if lockKey.Values.KeyId == keyId then
                hasKey = true;
                break;
            end
        end

        if not hasKey then
            interactable.CanInteract = false;
            interactable.Label = `This door is locked with key #{keyId}`;
        else
            interactable.CanInteract = true;
            interactable.Label = `Open with key #{keyId}`;
        end
    end

    super.registerPackage(DoorAlmdes);
end

return interactablePackage;

