local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;
local camera = workspace.CurrentCamera;

local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modToolHandler = shared.require(game.ReplicatedStorage.Library.ToolHandler);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modWallPlanTemplate = shared.require(game.ReplicatedStorage.Library.WallPlanTemplate);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);


local toolHandler: ToolHandler = modToolHandler.new();

local raycastParams, foundationRayParams;
--==

function toolHandler.onRequire()
    remoteToolInputHandler = modRemotesManager:Get("ToolInputHandler");
	remoteBuildingPlan = modRemotesManager:Get("BuildingPlan");

	local gameFoundations = workspace.Environment:WaitForChild("Game"):WaitForChild("Foundations");

	raycastParams = RaycastParams.new();
	raycastParams.FilterType = Enum.RaycastFilterType.Include;
	raycastParams.IgnoreWater = true;
	raycastParams.CollisionGroup = "Raycast";

	foundationRayParams = RaycastParams.new();
	foundationRayParams.FilterType = Enum.RaycastFilterType.Include;
	foundationRayParams.IgnoreWater = true;
	foundationRayParams.FilterDescendantsInstances = {gameFoundations};

	if RunService:IsServer() then
		
	elseif RunService:IsClient() then
		modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);

	end
end

function toolHandler.Init(handler: ToolHandlerInstance)
end

function toolHandler.Equip(handler: ToolHandlerInstance)
	handler:LoadWieldConfig();
	Debugger:Warn(`Equip ({handler.WieldComp.ItemId})`);
end


if RunService:IsClient() then -- MARK: Client
	local foundationObjects = {};
	local foundationRequested = {};

	function toolHandler.ClientEquip(handler: ToolHandlerInstance)
		local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);

		local modCharacter = modData:GetModCharacter();
		local mouseProperties = modCharacter.MouseProperties;
		local characterProperties = modCharacter.CharacterProperties;

		local storageItem: StorageItem = handler.StorageItem;
		local equipmentClass: EquipmentClass = handler.EquipmentClass;
		local toolAnimator: ToolAnimator = handler.ToolAnimator;
	
		local siid = storageItem.ID;
		local itemId = storageItem.ItemId;
		local itemLib = storageItem.Library;
		
		local toolPackage = handler.ToolPackage;
		local animations = toolPackage.Animations;

		local configurations: ConfigVariable = equipmentClass.Configurations;
		local properties: PropertiesVariable<{}> = equipmentClass.Properties;

		local mainToolModel = handler.MainToolModel;
		local handle = mainToolModel and mainToolModel:WaitForChild("Handle") or nil;

		local buildingPlanWindow: InterfaceWindow = modClientGuis.getWindow("BuildingPlan");
		--==

		characterProperties.HideCrosshair = true;
		characterProperties.UseViewModel = false;

		
		toolAnimator:LoadAnimations(animations, toolPackage.DefaultAnimatorState, handler.Prefabs);
		toolAnimator:Play("Core");
        if toolPackage.Animations.Load then
            toolAnimator:Play("Load", {
                FadeTime=0;
            });
            if toolPackage.OnAnimationPlay then
                task.defer(function()
                    toolPackage.OnAnimationPlay("Load", handler, mainToolModel);
                end)
            end
        end

		if toolPackage.ToolWindow then
			local quickButton = modClientGuis.ActiveInterface:NewQuickButton(itemLib.Name, nil, itemLib.Icon);
			quickButton.Name = toolPackage.ToolWindow;
			quickButton.LayoutOrder = 999;
			quickButton:WaitForChild("BkFrame").Visible = true;
			modClientGuis.ActiveInterface:ConnectQuickButton(quickButton, "KeyInteract");
			
			handler.Garbage:Tag(function()
				quickButton:Destroy();
				modClientGuis.toggleWindow(toolPackage.ToolWindow, false);
			end);
		end

		
		local placeholderCache = {};
		local loadedPlaceholderCache = false;
	
		local function clearPlaceholders()
			for _, obj in pairs(camera:GetChildren()) do
				if obj:IsA("Model") and obj.Name == "PlaceholderWall" then
					game.Debris:AddItem(obj, 0);
				end
			end
			for _, obj in pairs(workspace.Interactables:GetChildren()) do
				if obj:IsA("Model") and obj.Name == "PlaceholderWall" then
					game.Debris:AddItem(obj, 0);
				end
			end
		end
		clearPlaceholders();

		local placeholderWall = nil;
		local selectedFoundationPart, selectedGridPoint;
		local function updatePlaceholders()
			if selectedFoundationPart == nil or selectedFoundationPart:GetAttribute("Index") == nil then return end;
			local foundationData = foundationObjects[selectedFoundationPart:GetAttribute("Index")];
			if foundationData == nil then return end;
			
			local foundationCf = selectedFoundationPart.CFrame;
			
			local playerData = foundationData.Players[localPlayer];
			if playerData then
				clearPlaceholders();
				
				if playerData.Placeholder then
					for _, holderData in pairs(playerData.Placeholder) do
						local newWallPlan = modWallPlanTemplate.new();
						for k, v in pairs(holderData.BuildingData) do
							newWallPlan[k] = v;
						end
						newWallPlan.Model.Name = "PlaceholderWall";
						newWallPlan:SetParent(workspace.Interactables);
						newWallPlan:SetTransparency(0.5);
						newWallPlan:Update();
						
						newWallPlan.FoundationPart = selectedFoundationPart;
						newWallPlan.GridPoint = holderData.Point;
						
						placeholderCache[holderData.Point] = newWallPlan;
						newWallPlan:AddInteractable();
					end
				end
			end
		end

		local function clearActivePlaceholder()
			if placeholderWall then
				placeholderWall:SetParent(nil);
			end
		end

		local prevBuildOption, prevSelectedPlaceholder;
		RunService:BindToRenderStep("ToolRender", Enum.RenderPriority.Character.Value, function()
			if not characterProperties.CanAction then
				characterProperties.ProxyInteractable = nil;
				return;
			end
			raycastParams.FilterDescendantsInstances = {workspace.Environment;};
			
			local aimOrigin = characterProperties.InteractAimOrigin;
			local aimDirection = characterProperties.InteractAimDirection;

			local cameraDistance = localPlayer:DistanceFromCharacter(characterProperties.InteractAimOrigin);
			local raycastResult = workspace:Raycast(characterProperties.InteractAimOrigin, aimDirection*(cameraDistance+10), raycastParams)
			local rayHit, rayPoint;
			
			if raycastResult then 
				rayHit = raycastResult.Instance;
				rayPoint = raycastResult.Position;
			else
				rayPoint = characterProperties.InteractAimOrigin + aimDirection*(cameraDistance+10); 
			end;

			local targetPoint = Vector3.new(rayPoint.X, handle.Position.Y, rayPoint.Z);
			
			local targetFloor = workspace:Raycast(targetPoint, Vector3.new(0, -14, 0), foundationRayParams);
			if targetFloor == nil then return; end;

			local foundationPart = targetFloor.Instance;
			local foundationIndex = foundationPart:GetAttribute("Index");
			local foundationData = foundationIndex and foundationObjects[foundationIndex] or nil;
			
			if foundationPart ~= selectedFoundationPart then
				Debugger:Log("Foundation changed");
				foundationData = nil;
				selectedFoundationPart = foundationPart;
				foundationRequested[foundationPart] = nil;
				updatePlaceholders();
				return;
			end

			if foundationData == nil then
				selectedFoundationPart = nil;
				if foundationRequested[foundationPart] == nil or tick()-foundationRequested[foundationPart] >= 3 then
					foundationRequested[foundationPart] = tick();
					
					local foundationObj = remoteBuildingPlan:InvokeServer("loadfoundation", {FoundationPart=foundationPart});
					if foundationObj then
						foundationObjects[foundationObj.Index] = foundationObj;
						foundationRequested[foundationPart] = nil;
					end
				end
				return;
			end
			
			if handler.Binds["UpdatePlaceholders"] == nil then
				handler.Binds["UpdatePlaceholders"] = function(returnPacket)
					foundationData.Players[localPlayer] = returnPacket.PlayerData;
					updatePlaceholders();
				end;
			end

			selectedFoundationPart = foundationPart;

			if selectedFoundationPart and not loadedPlaceholderCache then
				updatePlaceholders();
				loadedPlaceholderCache = true;
			end
			
			local foundationCf = foundationPart.CFrame;
			local halfGrid = foundationData.GridSize/2;
			
			local objSpace = foundationCf:PointToObjectSpace(targetFloor.Position);
			local gridPoint = Vector3.new(math.round(objSpace.X/halfGrid)*halfGrid, 0, math.round(objSpace.Z/halfGrid)*halfGrid);
			
			local gridPointData = nil
			for a=1, #foundationData.GridData do
				local data = foundationData.GridData[a];
				
				if data.Point == gridPoint then
					gridPointData = data;
					break;
				end
			end
			
			if gridPointData == nil then return end;
			gridPoint = gridPointData.Point;
			local gridType = gridPointData.Type;

			if gridType == 2 then
				selectedGridPoint = gridPoint;

			elseif gridType == 3 then
				selectedGridPoint = gridPoint;

			else
				selectedGridPoint = nil;

			end
			
			local placeholderData = selectedGridPoint and placeholderCache[selectedGridPoint] or nil;
			if prevSelectedPlaceholder ~= placeholderData then
				for _, phD in pairs(placeholderCache) do
					phD:SetColor();
				end
			end
			prevSelectedPlaceholder = placeholderData;
			
			if selectedGridPoint == nil then clearActivePlaceholder(); return end;
			
			if placeholderData then
				placeholderData:SetColor("red");
				clearActivePlaceholder();
				return;
			end;
			
			local worldGridPoint = foundationCf:PointToWorldSpace(gridPoint + Vector3.new(0, objSpace.Y, 0));
			
			local floorRay = workspace:Raycast(worldGridPoint+Vector3.new(0, 1, 0), Vector3.new(0, -4, 0), foundationRayParams);
			local ceilRay = workspace:Raycast(worldGridPoint+Vector3.new(0, 1, 0), Vector3.new(0, 18, 0), foundationRayParams);

			if floorRay and ceilRay then
				--local dirAngle = math.round(math.deg(-math.atan2(camera.CFrame.LookVector.X, -camera.CFrame.LookVector.Z))/45)*45;
				
				local curFoundationPart = floorRay.Instance;
				local curFoundationIndex = curFoundationPart:GetAttribute("Index");
				local curFoundationData = curFoundationIndex and foundationObjects[curFoundationIndex] or nil;
				
				if curFoundationData == nil then return end;

				if placeholderWall == nil then
					placeholderWall = modWallPlanTemplate.new();
					placeholderWall:ToggleBillboard(true);
				end
				
				local buildOption = buildingPlanWindow and buildingPlanWindow.Binds.ActiveBuildId or "Wall";
				
				if prevBuildOption ~= buildOption then
					prevBuildOption = buildOption;
					placeholderWall:SetType(buildOption);
					placeholderWall:SetTransparency(0.5);
				end
				
				local floorPoint = floorRay.Position;
				local ceilPoint = ceilRay.Position;
				local wallHeight = ceilPoint.Y-floorPoint.Y;
				
				local wallPosition = floorPoint + Vector3.new(0, wallHeight/2, 0);
				
				placeholderWall.FloorPoint = floorPoint;
				placeholderWall.Size = Vector3.new(curFoundationData.GridSize, math.ceil(wallHeight*10)/10, 2.01);
				
				if gridType == 2 then
					placeholderWall:SetParent(camera);
					placeholderWall.CFrame = CFrame.new(wallPosition) * foundationCf.Rotation:ToWorldSpace(CFrame.Angles(0, math.rad(0), 0));
					
				elseif gridType == 3 then
					placeholderWall:SetParent(camera);
					placeholderWall.CFrame = CFrame.new(wallPosition) * foundationCf.Rotation:ToWorldSpace(CFrame.Angles(0, math.rad(90), 0));

				else
					placeholderWall:SetParent(nil);
				end
				
				local wallCframe = placeholderWall.CFrame;
				
				local innerClampA = wallCframe + wallCframe.RightVector * halfGrid;
				local innerClampB = wallCframe + wallCframe.RightVector * -halfGrid;
				local innerTarget = modVector.PointBetweenAB(innerClampA.Position, innerClampB.Position, targetFloor.Position);

				placeholderWall.RPoint = innerClampA;
				placeholderWall.LPoint = innerClampB;
				
				--Inputs;
				placeholderWall.TargetFloor = targetFloor.Position;
				placeholderWall.InnerPoint = innerTarget;
				placeholderWall.MouseYDeg = math.deg(mouseProperties.Y);
				
				placeholderWall:Update();
				
			else
				clearActivePlaceholder();
				
			end
		end);


		handler.Binds["KeyFire"] = function()
			if selectedGridPoint == nil then return end;
			if selectedFoundationPart == nil then return end;
			
			local placeholderData = placeholderCache[selectedGridPoint];
			
			local foundationIndex = selectedFoundationPart:GetAttribute("Index");
			local foundationData = foundationIndex and foundationObjects[foundationIndex] or nil;

			local setValue;
			if placeholderData == nil then
				placeholderCache[selectedGridPoint] = placeholderWall:Clone("PlaceholderWall");
				placeholderCache[selectedGridPoint]:SetParent(workspace.Interactables);
				setValue = "set";
				
				modAudio.PlayReplicated("Writing", handle);
				
			else
				placeholderData:Destroy();
				placeholderCache[selectedGridPoint] = nil;
				setValue = "unset";
				
			end
			
			local returnPacket = remoteBuildingPlan:InvokeServer("setplaceholder", {
				FoundationPart=selectedFoundationPart; 
				GridPoint=selectedGridPoint;
				SetValue=setValue;
				BuildingData=placeholderCache[selectedGridPoint];
			});
			if returnPacket and returnPacket.PlayerData then
				foundationData.Players[localPlayer] = returnPacket.PlayerData;
				updatePlaceholders();
				
			else
				placeholderCache[selectedGridPoint]:Destroy();
				placeholderCache[selectedGridPoint] = nil;
				
			end
		end

		handler.Garbage:Tag(function()
			clearPlaceholders();
			
			if placeholderWall then placeholderWall:Destroy(); end
			for key, cachePart in pairs(placeholderCache) do
				placeholderCache[key] = nil;
			end
		end)
	end

	function toolHandler.ClientUnequip(handler: ToolHandlerInstance)
		
	end


elseif RunService:IsServer() then -- MARK: Server
	function toolHandler.ActionEvent(handler: ToolHandlerInstance, packet)
		local characterClass: CharacterClass = handler.CharacterClass;
		local actionIndex = packet.ActionIndex;

		local healthComp: HealthComp = characterClass.HealthComp;
		if healthComp.IsDead then return end;
	
		local statusComp: StatusComp = characterClass.StatusComp;

		local equipmentClass: EquipmentClass =  handler.EquipmentClass;
		local configurations = equipmentClass.Configurations;
		local properties = equipmentClass.Properties;

		local storageItem: StorageItem = handler.StorageItem;

		if actionIndex == 1 then
		end
	end
end

return toolHandler;