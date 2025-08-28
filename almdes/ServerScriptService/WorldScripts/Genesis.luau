local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

if RunService:IsServer() then
end


local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassAlmdes).new();
--==

function WorldCore.onRequire()
    if RunService:IsServer() then
        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            local profile: ProfileAlmdes = shared.modProfile:WaitForProfile(player) :: ProfileAlmdes;
            if profile == nil then return end;

            Debugger:Warn(`{player.Name} has joined the world!`);
        end, 999);

        local modWorldEvents = shared.require(game.ServerScriptService.ServerLibrary.WorldEvents);
        modWorldEvents.GlobalProperties.Tutorial = true;
    end

    shared.modEventService:OnInvoked("Interactables_BindButtonInteract", function(eventPacket: EventPacket, ...)
        local interactable: InteractableInstance = ...;
        local variantId = interactable.Variant;

        Debugger:StudioLog("Interactables_BindButtonInteract eventPacket", eventPacket, "interactable", interactable);
    end)
end


return WorldCore;