local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modBuildingPlans = shared.require(game.ReplicatedStorage.Library.BuildingPlans);

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
	local remoteBuildingPlan = modRemotesManager:Get("BuildingPlan");

    local ConstructBuilding = {
		Name = "ConstructBuilding";
        Type = "ConstructBuilding";

        IndicatorPresist = false;
        InteractableRange = 10;
        InteractDuration = 1;
    };

    function ConstructBuilding.new(interactable: InteractableInstance, npcName: string)
        local config = interactable.Config;
        local variant = interactable.Variant;

        interactable.CanInteract = true;
        interactable.Label = `Construct {variant}`;
    end

    -- When interacting with interactable.
    function ConstructBuilding.BindInteract(interactable: InteractableInstance, info: InteractInfo)
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
    function ConstructBuilding.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        local compLib = modBuildingPlans.BuildingCost[interactable.Variant];
        local itemLib = modItemsLibrary:Find(compLib.ItemId);

        interactable.CanInteract = true;
        interactable.Label = `Construct {interactable.Variant} ({compLib.Amount} {itemLib.Name})`;
    end

    super.registerPackage(ConstructBuilding);
end

return interactablePackage;

