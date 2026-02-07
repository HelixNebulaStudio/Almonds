local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local gameBuildings = workspace.Environment.Game.Buildings;

local BuildingsSystem = {};
BuildingsSystem.__index = BuildingsSystem;

BuildingsSystem.Foundations = {};
--==

function BuildingsSystem.onRequire()
    for _, buildingModel in pairs(gameBuildings:GetChildren()) do
        local foundations = buildingModel:WaitForChild("Foundations");
        table.insert(BuildingsSystem.Foundations, foundations);
    end
    gameBuildings.ChildAdded:Connect(function(buildingModel)
        local foundations = buildingModel:WaitForChild("Foundations");
        table.insert(BuildingsSystem.Foundations, foundations);
    end)
end

function BuildingsSystem.isFoundation(part)
    for _, foundationsFolder in pairs(BuildingsSystem.Foundations) do
        if not foundationsFolder:IsAncestorOf(part) then
            return false;
        end
    end
    return true;
end

function BuildingsSystem.getFoundations()
    return BuildingsSystem.Foundations;
end

function BuildingsSystem.getBuilding(foundationPart)
    local foundationsFolder = foundationPart.Parent;
    return foundationsFolder.Parent;
end

function BuildingsSystem.getBuildingScene(foundationPart)
    local buildingScenes = {workspace.Environment.Game;};

    local buildingModel = BuildingsSystem.getBuilding(foundationPart);
    
    local buildingScene = buildingModel.Scene;
    table.insert(buildingScenes, buildingScene);

    return buildingScenes; 
end

return BuildingsSystem;