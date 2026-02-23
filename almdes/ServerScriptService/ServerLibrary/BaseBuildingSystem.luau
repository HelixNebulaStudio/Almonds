local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modBuildingPlans = shared.require(game.ReplicatedStorage.Library.BuildingPlans);

local foundationRayParams = RaycastParams.new();
foundationRayParams.FilterType = Enum.RaycastFilterType.Include;
foundationRayParams.IgnoreWater = true;

--
local BaseSystem = {};
BaseSystem.__index = BaseSystem;

local Foundation = {};
Foundation.__index = Foundation;

--
BaseSystem.Foundation = Foundation;
BaseSystem.Bases = {};
--==

function BaseSystem.onRequire()

    local remoteBuildingPlan = modRemotesManager:Get("BuildingPlan");
    function remoteBuildingPlan.OnServerInvoke(player, action, paramPacket)
        local returnPacket = {};
        if action == "loadfoundation" then
            local foundationPart = paramPacket.FoundationPart;
            return Foundation:Load(foundationPart);
            
        elseif action == "setplaceholder" then
            local foundationPart = paramPacket.FoundationPart;
            local foundationCf = foundationPart.CFrame;
            local gridPoint = paramPacket.GridPoint;
            
            local foundationData = Foundation:Load(foundationPart);
            if foundationData == nil then return returnPacket end;
            
			local buildingModel = modBuildingPlans.getBuilding(foundationPart);
            local baseObject = BaseSystem:Get(buildingModel);
            
            -- local territoryGroup = modTerritory:GetByFolder(foundationPart.Parent);
            -- if territoryGroup and territoryGroup.Cupboard then
            -- 	if territoryGroup:GetPlayer(player) == nil then
            -- 		Debugger:Log(player,"No building privilege in this territory.")
            -- 		shared.Notify(player, "No building privilege in this territory.", "Negative");
                    
            -- 		returnPacket.PlayerData = foundationData.Players[player];
            -- 		return returnPacket;
            -- 	end
            -- end
            
            foundationData:SetPlaceholder(player, gridPoint, paramPacket.SetValue, paramPacket.BuildingData);
            returnPacket.PlayerData = foundationData.Players[player];
            
            return returnPacket;

        elseif action == "build" then
            local foundationPart = paramPacket.FoundationPart;
			local selectedGridPoint = paramPacket.SelectedGridPoint;

			if foundationPart == nil then return end;
			if selectedGridPoint == nil then return end;
            Debugger:Log("build data ", foundationPart, selectedGridPoint);

			local buildingModel = modBuildingPlans.getBuilding(foundationPart);
            local foundationData = Foundation:Load(foundationPart);
            local baseObject = BaseSystem:Get(buildingModel);

            -- local territoryGroup = modTerritory:GetByFolder(foundationPart.Parent);
            -- if territoryGroup and territoryGroup.Cupboard then
            -- 	if territoryGroup:GetPlayer(player) == nil then
            -- 		shared.Notify(player, "No building privilege in this territory.", "Negative");
            -- 		returnPacket.PlayerData = foundationData.Players[player];
            -- 		return returnPacket;
            -- 	end
            -- end
            
            local gridIndex, gridData = foundationData:GetGridPoint(selectedGridPoint);
            local gridPoint = gridData.Point;
            local gridType = gridData.Type;
            
            local playerData = foundationData.Players[player];
            if playerData == nil then return end;
            
            local placeholderData = playerData.Placeholder[gridPoint];
            local buildingData = placeholderData.BuildingData;
            
            local buildLib = modBuildingPlans.BuildingCost[buildingData.Type];
            Debugger:Log("compLib", buildLib);
            
            local profile = shared.modProfile:Get(player);
            local playerSave = profile:GetActiveSave();
            local inventory = playerSave.Inventory;

            local total, itemList = inventory:ListQuantity(buildLib.ItemId, buildLib.Amount);

            if total < buildLib.Amount then
                shared.Notify(player, "Insufficient resources.", "Negative");
                return;
            end
            
            local itemLib = modItemsLibrary:Find(buildLib.ItemId);
            for a=1, #itemList do
                inventory:Remove(itemList[a].ID, itemList[a].Quantity);
                shared.Notify(player, `{buildLib.Amount} {itemLib.Name} removed from your Inventory.`, "Negative");
            end
            
			local buildOptionInfo = modBuildingPlans.BuildOptionInfo[buildingData.Type];
			if buildOptionInfo == nil then return end;

			local placeholderTemplate = buildOptionInfo.Template;

            local newPlan = placeholderTemplate.new{
				FoundationPart = foundationPart;
			};
            for k, v in pairs(buildingData) do
                newPlan[k] = v;
            end
            newPlan.Model.Name = "BuildingPart";
            newPlan:SetParent(baseObject.PlayerStructures);
            local newBuild = newPlan:Build(baseObject.Id);
            
            -- Save component to grid;
            gridData.Component = newBuild.Id;
            
            newBuild.Model.Destroying:Connect(function()
                gridData.Component = nil;
                Debugger:Log("Clearing wallComponent from grid", gridData);
            end)
            
            playerData.Placeholder[gridPoint] = nil;
            
            returnPacket.PlayerData = foundationData.Players[player];

            return returnPacket;
        end

		return;
    end

    game.Players.PlayerRemoving:Connect(function(player)
        for _, foundationData in pairs(Foundation.Foundations) do
            for p, _ in pairs(foundationData.Players) do
                if not p:IsDescendantOf(game.Players) then
                    foundationData.Players[p] = nil;
                end
            end
        end
    end)
end

function BaseSystem.new(buildingModel)
	local self = {
		Id = buildingModel.Name;
		
		Model = buildingModel;
		Foundations = {};
		Structures = {};
	};
	
	setmetatable(self, BaseSystem);
	
	self.PlayerStructures = buildingModel:FindFirstChild("PlayerStructures");
	if self.PlayerStructures == nil then
		local structuresFolder = Instance.new("Folder");
		structuresFolder.Name = "PlayerStructures";
		structuresFolder.Parent = buildingModel;

		self.PlayerStructures = structuresFolder;
	end
	
	self.Bases[buildingModel.Name] = self;
	return self;
end

function BaseSystem:Get(buildingModel)
	if buildingModel == nil then return end;
	if self.Bases[buildingModel.Name] == nil then
		BaseSystem.new(buildingModel);
	end
	return self.Bases[buildingModel.Name]
end

--
Foundation.Counter = 1;
Foundation.Foundations = {};
Foundation.GridSize = 14;

--== Script;
function Foundation.new(part)
	local self = {
		Index = Foundation.Counter;
		Part = part;
		GridData = {};
		Players = {};
	};
	
	Foundation.Counter = Foundation.Counter + 1;
	part:SetAttribute("Index", self.Index);
	
	setmetatable(self, Foundation);
	self.Foundations[self.Index] = self;
	
	return self;
end

function Foundation:Get(index)
	return self.Foundations[index];
end

function Foundation:GetGridPoint(point)
	for a=1, #self.GridData do
		local gridData = self.GridData[a];
		
		if gridData.Point == point then
			return a, gridData;
		end
	end
	
	Debugger:Log("Could not find grid point: ", point);
    return;
end

function Foundation:Load(foundationPart)
	if not foundationPart:IsA("BasePart") or modBuildingPlans.isFoundation(foundationPart) then
		return;
	end
	if foundationPart.Size.X <= 16 and foundationPart.Size.Z <= 16 then
		Debugger:Log("Foundation too small.");
		return;
	end
		
	local index = foundationPart:GetAttribute("Index");
	local foundationObj = self:Get(index);
	
	if index and foundationObj then
		return foundationObj;
	end
	
	local buildingModel = modBuildingPlans.getBuilding(foundationPart);
	local baseObject = BaseSystem:Get(buildingModel);
	local newFoundation = Foundation.new(foundationPart);
	table.insert(baseObject.Foundations, newFoundation);
	
	local foundationSize = foundationPart.Size - Vector3.new(1, 0, 1);
	local foundationTopY = foundationSize.Y/2;
	local rootCFrame = foundationPart.CFrame + Vector3.new(0, foundationTopY, 0);

	if foundationPart:GetAttribute("GridOffset") then
		rootCFrame = rootCFrame + foundationPart:GetAttribute("GridOffset");
	end
	if foundationPart:GetAttribute("GridPadding") then
		foundationSize = foundationSize - foundationPart:GetAttribute("GridPadding");
	end

	local gridArea = Vector3.new(math.ceil((foundationSize.X)/2)*2, 0, math.ceil((foundationSize.Z)/2)*2);
	
	local gridSize = Foundation.GridSize;
	local halfGrid = gridSize/2;
	
	local gridMin = -Vector3.new(math.ceil(gridArea.X/2/halfGrid)*halfGrid, 0, math.ceil(gridArea.Z/2/halfGrid)*halfGrid);
	local gridMax = Vector3.new(math.ceil(gridArea.X/2/halfGrid)*halfGrid, 0, math.ceil(gridArea.Z/2/halfGrid)*halfGrid);
	
	local xMod, zMod = 0, 0;
	local xMax, zMax = (gridMax.X-gridMin.X)/halfGrid +1, (gridMax.Z-gridMin.Z)/halfGrid +1;
	
	local debugModel;
	if script:GetAttribute("Debug") == true and RunService:IsStudio() then
		debugModel = Instance.new("Model");
		debugModel.Parent = workspace;
		
		Debugger:PointPart(rootCFrame:PointToWorldSpace(gridMin)).Color = Color3.fromRGB(91, 75, 16);
		Debugger:PointPart(rootCFrame:PointToWorldSpace(gridMax)).Color = Color3.fromRGB(0, 255, 0);
		
		--Debugger:Log("gridArea", gridArea, "gridDiv", gridDiv, " gridSize", gridSize);
		
		local originDpPoint = Debugger:PointPart(rootCFrame:PointToWorldSpace(Vector3.zero));
		originDpPoint.Color = Color3.fromRGB(133, 253, 255);
		originDpPoint.Size = Vector3.new(0.3, 0.3, 0.3);
		originDpPoint.Parent = debugModel;
	end
	
	local xMinEnabled, xMaxEnabled = foundationPart:GetAttribute("XMinEnabled") == true, foundationPart:GetAttribute("XMaxEnabled") == true;
	local zMinEnabled, zMaxEnabled = foundationPart:GetAttribute("ZMinEnabled") == true, foundationPart:GetAttribute("ZMaxEnabled") == true;
	
	for x=gridMin.X, gridMax.X, halfGrid do
		xMod = xMod +1;
		zMod = 0;
		
		for z=gridMin.Z, gridMax.Z, halfGrid do
			zMod = zMod +1;
				
			local floorPoint = Vector3.new(x, 0, z);
			local gridType = nil;
			local enabled = true;
			
			if xMod%2==0 and zMod%2 == 0 then
				gridType = 1;
				
			elseif xMod%2==0 and zMod%2 ~= 0 then
				gridType = 2;

				if zMod == 1 and not zMinEnabled then enabled = false; end
				if zMod == zMax and not zMaxEnabled then enabled = false; end
				
			elseif xMod%2~=0 and zMod%2 == 0 then
				gridType = 3;

				if xMod == 1 and not xMinEnabled then enabled = false; end
				if xMod == xMax and not xMaxEnabled then enabled = false; end
				
			else
				gridType = 4;
				
			end
			
			if gridType then
				if script:GetAttribute("Debug") == true and RunService:IsStudio() then
					local debugPoint = Debugger:PointPart(rootCFrame:ToWorldSpace(CFrame.new(floorPoint)));
					debugPoint.Name = x..","..z;
					debugPoint.Parent = debugModel;
					
					if gridType == 1 then
						debugPoint.Color = Color3.fromRGB(122, 255, 61);
						
					elseif gridType == 2 then
						debugPoint.Shape = Enum.PartType.Block;
						debugPoint.Size = Vector3.new(1, 0.1, 0.1);
						
						if enabled then
							debugPoint.Color = Color3.fromRGB(43, 82, 255);
						else
							debugPoint.Color = Color3.fromRGB(91, 91, 91);
						end
						
					elseif gridType == 3 then
						debugPoint.Shape = Enum.PartType.Block;
						debugPoint.Size = Vector3.new(0.1, 0.1, 1);

						if enabled then
							debugPoint.Color = Color3.fromRGB(255, 0, 0);
						else
							debugPoint.Color = Color3.fromRGB(91, 91, 91);
						end
						
					elseif gridType == 4 then
						debugPoint.Color = Color3.fromRGB(91, 91, 91);
					end
					
					if xMod == 1 and zMod == 1 then
						debugPoint.Color = Color3.fromRGB(212, 85, 189);
					end
				end
				
				if enabled then
					table.insert(newFoundation.GridData, {Point=floorPoint; Type=gridType;});
				end
			end
		end
	end
	
	newFoundation.GridArea = gridArea;
	newFoundation.GridSize = gridSize;
	foundationPart:SetAttribute("GridSize", gridSize);
	
	return newFoundation;
end

function Foundation:SetPlaceholder(player, gridPoint, action, buildingData)
	local dataIndex, gridPointData = self:GetGridPoint(gridPoint);
	
	if gridPointData == nil then 
        Debugger:Warn("Missing GridPointData");
        return;
    end
	gridPoint = gridPointData.Point;
	
	local gridType = gridPointData.Type;
	
	local gridSize = Foundation.GridSize;
	local halfGrid = gridSize/2;
	
	local playerData = self.Players[player] or {};
	self.Players[player] = playerData
	
	if playerData.Placeholder == nil then
		playerData.Placeholder = {};
	end
	
	if action == "set" then
		if gridPointData.Component then
            Debugger:Log("Component attached : ", gridPointData.Component);
            return;
        end;
		
		local foundationPart = self.Part;
		local foundationCf = foundationPart.CFrame;
		if foundationPart:GetAttribute("GridOffset") then
			foundationCf = foundationCf + foundationPart:GetAttribute("GridOffset");
		end
		
		local foundationSize = foundationPart.Size;
		if foundationPart:GetAttribute("GridPadding") then
			foundationSize = foundationSize - foundationPart:GetAttribute("GridPadding");
		end
		local worldGridPoint = foundationCf:PointToWorldSpace(gridPoint) + Vector3.new(0, foundationSize.Y/2, 0);
		
		foundationRayParams.FilterDescendantsInstances = modBuildingPlans.getFoundations();

		local buildOptionInfo = modBuildingPlans.BuildOptionInfo[buildingData.Type];
		if buildOptionInfo == nil then return end;

		local buildingScene = modBuildingPlans.getBuildingScene(foundationPart);

		local placeholderTemplate = buildOptionInfo.Template;
		local checkResult = placeholderTemplate:CheckPlaceholder{
			BuildingScene = buildingScene;
			FoundationCFrame = foundationCf;
			FoundationSize = foundationSize;
			GridSize = gridSize;
			WorldGridPoint = worldGridPoint;
		};
		if not checkResult.IsValid then Debugger:Warn("Invalid placement."); return end;

		local scanInfo = checkResult.ScanInfo;

		local placeholder = {
			Type = buildingData.Type;
		};

		scanInfo.FoundationCFrame = foundationCf;
		scanInfo.GridSize = gridSize;
		scanInfo.GridType = gridType;
		scanInfo.AimPoint = buildingData.AimPoint;
		scanInfo.WorldGridPoint = worldGridPoint;
		placeholderTemplate.UpdatePlaceholder(placeholder, scanInfo);

		playerData.Placeholder[gridPoint] = {
			Point = gridPoint; 
			BuildingData = placeholder; 
			Index = dataIndex;
		};
		Debugger:Log("Placeholder Set", playerData.Placeholder[gridPoint]);
		
	elseif action == "unset" then
		playerData.Placeholder[gridPoint] = nil;
		
	end
end

return BaseSystem;