local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local BuildingPlans = {};

local RunService = game:GetService("RunService");

local gameBuildings = workspace.Environment.Game.Buildings;

BuildingPlans.__index = BuildingPlans;

local BuildOptionInfo = {
	Wall = {
		GridTypes = {2, 3};
        TemplateName = "WallPlanTemplate";
	};
	Doorway = {
		GridTypes = {2, 3};
        TemplateName = "WallPlanTemplate";
	};
	WallFrame = {
		GridTypes = {2, 3};
        TemplateName = "WallPlanTemplate";
	};
	WindowFrame = {
		GridTypes = {2, 3};
        TemplateName = "WallPlanTemplate";
	};
	Floor = {
		GridTypes = {1};
        TemplateName = "FloorPlanTemplate";
	};
    LStairs = {
        GridTypes = {1};
        TemplateName = "StairsPlanTemplate";
    }
};
BuildingPlans.BuildOptionInfo = BuildOptionInfo;

BuildingPlans.BuildingCost = {
    Wall = {ItemId ="wood"; Amount = 5;};
    Doorway = {ItemId = "wood"; Amount = 5;};
    WallFrame = {ItemId = "wood"; Amount = 5;};
    WindowFrame = {ItemId = "wood"; Amount = 5;};
	Floor = {ItemId = "wood"; Amount = 5;};
    LStairs = {ItemId = "wood"; Amount = 5;};
};

BuildingPlans.Foundations = {};
--==

function BuildingPlans.onRequire()
    for _, buildingModel in pairs(gameBuildings:GetChildren()) do
        local foundations = buildingModel:WaitForChild("Foundations");
        table.insert(BuildingPlans.Foundations, foundations);
    end
    gameBuildings.ChildAdded:Connect(function(buildingModel)
        local foundations = buildingModel:WaitForChild("Foundations");
        table.insert(BuildingPlans.Foundations, foundations);
    end)

    for _, ms in pairs(script:GetChildren()) do
        if not ms:IsA("ModuleScript") then continue end;

        local planTemplateClass = shared.require(ms, BuildingPlans);

        for _, info in pairs(BuildOptionInfo) do
            if info.TemplateName ~= ms.Name then continue end;
            info.Template = planTemplateClass;
        end 
    end
end

function BuildingPlans.isFoundation(part)
    for _, foundationsFolder in pairs(BuildingPlans.Foundations) do
        if not foundationsFolder:IsAncestorOf(part) then
            return false;
        end
    end
    return true;
end

function BuildingPlans.getFoundations()
    return BuildingPlans.Foundations;
end

function BuildingPlans.getBuilding(foundationPart)
    local foundationsFolder = foundationPart.Parent;
    return foundationsFolder.Parent;
end

function BuildingPlans.getBuildingScene(foundationPart)
    local buildingScenes = {workspace.Environment.Game;};

    local buildingModel = BuildingPlans.getBuilding(foundationPart);
    
    local buildingScene = buildingModel.Scene;
    table.insert(buildingScenes, buildingScene);

    return buildingScenes; 
end

return BuildingPlans;