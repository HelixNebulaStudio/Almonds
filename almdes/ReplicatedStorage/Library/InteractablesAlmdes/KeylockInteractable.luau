local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modStorageItem = shared.require(game.ReplicatedStorage.Library.StorageItem);

local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local Keylock = {
		Name = "Keylock";
        Type = "Button";

        InteractDuration = 1;
    };

    function Keylock.new(interactable: InteractableInstance, npcName: string)
        local config = interactable.Config;

        interactable:SetPermissions("CanInteract", false);
    end

    -- When interacting with interactable.
    function Keylock.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        interactable.TypePackage.BindInteract(interactable, info);
        if info.Action == "Client" or RunService:IsClient() then return end;
        
        local userName = nil;
        if info.Player then
            userName = info.Player.Name;
        elseif info.NpcClass then
            userName = info.NpcClass.Name;
        end
        if interactable:HasPermissions("CanInteract", userName) == false then
            Debugger:Warn(`{userName} does not have permission to create key.`);
            return;
        end

        if info.Player then
            local player: Player = info.Player;
            local profile: ProfileAlmdes = shared.modProfile:Get(player);
            local inventory = profile.ActiveInventory;

            local fulfill, resultList = shared.modStorage.fulfillList(player, {
                {Type="Item"; ItemId="metal"; Amount=20};
            });
            if not fulfill then
                shared.Notify(player, "Insufficient Resources.", "Negative");
                return;
            end;

            shared.modStorage.consumeList(resultList);

            shared.Notify(info.Player, "You created a key.", "Positive");
            local keyId = interactable.Values.KeylockId;
            local keyStorageItem: StorageItem = modStorageItem.new(nil, "lockkey", {
                Values = {
                    KeyId = keyId;
                }
            });
            
            inventory:InsertRequest(keyStorageItem);
        end
    end
    
    -- When interactable pops up on screen.
    function Keylock.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        local config = interactable.Config;
        local userName = nil;
        if info.Player then
            userName = info.Player.Name;
        elseif info.NpcClass then
            userName = info.NpcClass.Name;
        end
        if interactable:HasPermissions("CanInteract", userName) == false then
            interactable.CanInteract = false;
            interactable.Label = `This is locked by someone else`;
            return;
        end

        interactable.CanInteract = true;
        interactable.Label = `Create Key (20 metal)`;
    end

    super.registerPackage(Keylock);
end

return interactablePackage;

