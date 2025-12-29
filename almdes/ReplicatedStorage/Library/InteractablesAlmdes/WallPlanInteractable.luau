local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modWallPlanTemplate = shared.require(game.ReplicatedStorage.Library.WallPlanTemplate);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
	local remoteBuildingPlan = modRemotesManager:Get("BuildingPlan");

    local WallPlan = {
		Name = "WallPlan";
        Type = "WallPlan";

        IndicatorPresist = false;
        InteractableRange = 10;
        InteractDuration = 1;
    };

    function WallPlan.new(interactable: InteractableInstance, npcName: string)
        local config = interactable.Config;
        local variant = interactable.Variant;

        interactable.CanInteract = true;
        interactable.Label = `Construct {variant}`;
    end

    -- When interacting with interactable.
    function WallPlan.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;

        local playerClass: PlayerClass = shared.modPlayers.get(info.Player);
        if playerClass == nil then return end;

        local foundationPart = interactable.Values.FoundationPart;
        local returnPacket = remoteBuildingPlan:InvokeServer("build", {
            FoundationPart = foundationPart;
            SelectedGridPoint = interactable.Values.GridPoint;
        });
        if returnPacket and returnPacket.PlayerData then
            local buildingPlanToolHandler = shared.require(game.ReplicatedStorage.Library.ToolHandler.BuildingPlan);
            buildingPlanToolHandler.UpdatePlaceholderPlans(foundationPart:GetAttribute("Index"), returnPacket.PlayerData);
        end
    end
    
    -- When interactable pops up on screen.
    function WallPlan.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        local compLib = modWallPlanTemplate.BuildingCost[interactable.Variant];
        local itemLib = modItemsLibrary:Find(compLib.ItemId);

        interactable.CanInteract = true;
        interactable.Label = `Construct {interactable.Variant} ({compLib.Amount} {itemLib.Name})`;
    end

    super.registerPackage(WallPlan);
end

return interactablePackage;

