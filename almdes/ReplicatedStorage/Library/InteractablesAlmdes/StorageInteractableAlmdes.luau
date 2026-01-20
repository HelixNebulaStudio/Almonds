local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local localPlayer = game.Players.LocalPlayer;

local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibraryAlmdes);
local remoteRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManagerAlmdes);

local interactablePackage = {};
--==
function interactablePackage.init(super) -- Server/Client
    local remoteStorageService = remoteRemotesManager:Get("StorageService");

    local StorageAlmdes = super.newPackage{
		Name = "StorageAlmdes";
        Type = "Storage";

        Values = {
            OpenSound = "";
        };
    };
    
    function StorageAlmdes.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        StorageAlmdes.TypePackage.BindPrompt(interactable, info);
        -- Defaulting to can interact = true;
        if RunService:IsServer() then return end;

        local clientData = info.ClientData;
        if clientData == nil then return; end;

        local modData = shared.require(localPlayer:WaitForChild("DataModule"));

        local keyRequired = interactable.Values.KeyRequired;
        if keyRequired then
            local itemLib = modItemsLibrary:Find(keyRequired);

            local hasKey = false;
            local keyCount = modData.CountItemIdOnCharacter(keyRequired);
            if keyCount > 0 then
                hasKey = true;
            end

            if not hasKey then
                interactable.CanInteract = false;
                interactable.Label = `{itemLib.Name} Required`;
                return;
            end

            interactable.Label = `Use {itemLib.Name} to open`;
            interactable.CanInteract = true;
        end
    end

    function StorageAlmdes.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        local rPacket = remoteStorageService:InvokeServer({
            Action = "RequestUnlock";
            StorageId = interactable.Values.StorageId;
        });
        Debugger:StudioLog("rPacket", rPacket);

        if not rPacket.Success then return end;
        StorageAlmdes.TypePackage.BindInteract(interactable, info);
    end

    super.registerPackage(StorageAlmdes);
end

return interactablePackage;

