local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;
local camera = workspace.CurrentCamera;

local modToolHandler = shared.require(game.ReplicatedStorage.Library.ToolHandler);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modBuildingPlans = shared.require(game.ReplicatedStorage.Library.BuildingPlans);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local toolHandler = modToolHandler.new();

local BuildOptionInfo = modBuildingPlans.BuildOptionInfo;

local raycastParams;
--==

function toolHandler.onRequire()
	remoteBuildingPlan = modRemotesManager:Get("BuildingPlan");

	raycastParams = RaycastParams.new();
	raycastParams.FilterType = Enum.RaycastFilterType.Include;
	raycastParams.IgnoreWater = true;
	raycastParams.CollisionGroup = "Raycast";
	
	templateGenericBillboard = game.ReplicatedStorage.Prefabs.Misc:WaitForChild("GenericBillboard");

	if RunService:IsServer() then
		
	elseif RunService:IsClient() then
		modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);

		alignHitboxFolder = Instance.new("Folder");
		alignHitboxFolder.Name = "AlignHitboxes";
		alignHitboxFolder.Parent = workspace.CurrentCamera;
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

	function toolHandler.UpdatePlaceholderPlans(foundationIndex, playerData)
		local foundationData = foundationIndex and foundationObjects[foundationIndex] or nil;
		foundationData.Players[localPlayer] = playerData;

		local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
		local wieldComp = playerClass.WieldComp;
		if wieldComp.ItemId == "buildingplan" 
		and wieldComp.ToolHandler
		and wieldComp.ToolHandler.Binds.UpdatePlaceholders then
			wieldComp.ToolHandler.Binds.UpdatePlaceholders();
		end
	end

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
				if obj:IsA("Model") and obj.Name == "PlaceholderModel" then
					game.Debris:AddItem(obj, 0);
				end
			end
			for _, obj in pairs(workspace.Interactables:GetChildren()) do
				if obj:IsA("Model") and obj.Name == "PlaceholderModel" then
					game.Debris:AddItem(obj, 0);
				end
			end
			alignHitboxFolder:ClearAllChildren();
		end
		clearPlaceholders();

		local activePlaceholder = nil;
		
		local selectedFoundationPart, selectedGridPoint;
		local function updatePlaceholders()
			if selectedFoundationPart == nil or selectedFoundationPart:GetAttribute("Index") == nil then return end;
			local foundationData = foundationObjects[selectedFoundationPart:GetAttribute("Index")];
			if foundationData == nil then return end;
			
			local foundationCf = selectedFoundationPart.CFrame;
			
			local playerData = foundationData.Players[localPlayer];
			if playerData == nil then return end;
			clearPlaceholders();
			
			if playerData.Placeholder then
				for _, holderData in pairs(playerData.Placeholder) do
					local buildOptionInfo = BuildOptionInfo[holderData.BuildingData.Type];
					if buildOptionInfo == nil then continue end;

					local placeholderTemplate = BuildOptionInfo[holderData.BuildingData.Type].Template;
					
					local newPlan = placeholderTemplate.new{
						FoundationPart = selectedFoundationPart;
					};
					for k, v in pairs(holderData.BuildingData) do
						newPlan[k] = v;
					end
					newPlan.Model.Name = "PlaceholderModel";
					newPlan:SetParent(workspace.Interactables);
					newPlan:SetTransparency(0.5);
					newPlan:Update();
					
					newPlan.FoundationPart = selectedFoundationPart;
					newPlan.GridPoint = holderData.Point;
					
					placeholderCache[holderData.Point] = newPlan;
					newPlan:AddInteractable();
				end
			end
		end
		handler.Binds["UpdatePlaceholders"] = updatePlaceholders;

		local function clearActivePlaceholder()
			if activePlaceholder then
				activePlaceholder:SetParent(nil);
			end
		end

		local highlighterPart = Instance.new("Part");
		highlighterPart.Name = "HighlighterPart";
		highlighterPart.Anchored = true;
		highlighterPart.CanCollide = false;
		highlighterPart.CanQuery = false;
		highlighterPart.Transparency = 1
		highlighterPart.Color = Color3.fromRGB(124, 161, 200);
		highlighterPart.Size = Vector3.new(0.5, 0.5, 0.5);
		highlighterPart.Material = Enum.Material.Neon;
		highlighterPart.TopSurface = Enum.SurfaceType.Smooth;
		highlighterPart.BottomSurface = Enum.SurfaceType.Smooth;
		highlighterPart.Parent = script;

		local templateAlignHitbox = highlighterPart:Clone();
		local highlightInfoBillboard = templateGenericBillboard:Clone();
		highlightInfoBillboard.Adornee = highlighterPart;
		highlightInfoBillboard.ExtentsOffsetWorldSpace = Vector3.new(0, 3, 0);
		highlightInfoBillboard.Parent = highlighterPart;

		local highlightLabel = highlightInfoBillboard:WaitForChild("TextLabel");
		highlightLabel.Text = "";

		handler.Binds.HighlighterPart = highlighterPart;

		local foundationRayParams = RaycastParams.new();
		foundationRayParams.FilterType = Enum.RaycastFilterType.Include;
		foundationRayParams.IgnoreWater = true;
		foundationRayParams.FilterDescendantsInstances = modBuildingPlans.getFoundations();

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
			local raycastResult = workspace:Raycast(
				characterProperties.InteractAimOrigin, 
				aimDirection * (cameraDistance+10), 
				raycastParams
			);
			local rayHit, rayPoint;
			
			if raycastResult then 
				rayHit = raycastResult.Instance;
				rayPoint = raycastResult.Position;
			else
				rayPoint = characterProperties.InteractAimOrigin + aimDirection*(cameraDistance+10); 
			end;

			local targetPoint = Vector3.new(rayPoint.X, handle.Position.Y, rayPoint.Z);
			local targetFloorRayResult = workspace:Raycast(targetPoint, Vector3.new(0, -14, 0), foundationRayParams);

			local foundationPart;
			if targetFloorRayResult then
				foundationPart = targetFloorRayResult.Instance;
			else
				foundationPart = handler.Binds.ActiveFoundation;
			end
			if foundationPart == nil then return; end;
			handler.Binds.ActiveFoundation = foundationPart;

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
						clearPlaceholders();
						foundationObjects[foundationObj.Index] = foundationObj;
						foundationRequested[foundationPart] = nil;
						updatePlaceholders();
					end
				end
				return;
			end
			
			selectedFoundationPart = foundationPart;

			if selectedFoundationPart and not loadedPlaceholderCache then
				updatePlaceholders();
				loadedPlaceholderCache = true;
			end
			
			local foundationCf = foundationPart.CFrame;
			if foundationPart:GetAttribute("GridOffset") then
				foundationCf = foundationCf + foundationPart:GetAttribute("GridOffset");
			end

			local halfGrid = foundationData.GridSize/2;
			local gridPointData = nil;


			--MARK: Load hitboxes
			local buildOption = buildingPlanWindow and buildingPlanWindow.Binds.ActiveBuildId or "Wall";

			local buildOptionInfo = BuildOptionInfo[buildOption];
			if buildOptionInfo == nil then return end;

			local foundationSurfaceY = foundationPart.Size.Y/2;
			local aimCf = CFrame.lookAlong(playerClass:GetCFrame().Position, aimDirection);
			for a=1, #foundationData.GridData do
				local data = foundationData.GridData[a];
				if data.GridHitbox then
					local compatibleType = table.find(buildOptionInfo.GridTypes, data.Type) ~= nil;

					local dir = (data.GridHitbox.Position - aimCf.Position).Unit;
					local isInFront = aimCf.LookVector:Dot(dir) > 0;

					local isValid = compatibleType and isInFront;
					data.GridHitbox.Transparency = isValid and 1 or 1;
					data.GridHitbox.CanQuery = isValid;
				end
				if data.GridHitbox and alignHitboxFolder:IsAncestorOf(data.GridHitbox) then continue end;

				local gridType = data.Type;
				local worldGridPoint = foundationCf:PointToWorldSpace(data.Point + Vector3.new(0, foundationSurfaceY, 0));

				local alignHitbox = templateAlignHitbox:Clone();
				alignHitbox.CFrame = CFrame.new(worldGridPoint) * foundationCf.Rotation;
				alignHitbox.Name = gridType;
				if gridType == 1 then
					alignHitbox.Color = Color3.fromRGB(150, 150, 150);
					alignHitbox.Size = Vector3.new(halfGrid*2, 0.5, halfGrid*2);

				elseif gridType == 2 then
					alignHitbox.Color = Color3.fromRGB(70, 81, 129);
					alignHitbox.Size = Vector3.new(halfGrid*2, halfGrid, 0.5);
					alignHitbox.CFrame *= CFrame.new(0, halfGrid, 0);

				elseif gridType == 3 then
					alignHitbox.Color = Color3.fromRGB(124, 54, 54);
					alignHitbox.Size = Vector3.new(0.5, halfGrid, halfGrid*2);
					alignHitbox.CFrame *= CFrame.new(0, halfGrid, 0);

				else
					alignHitbox.Color = Color3.fromRGB(50, 50, 50);
					alignHitbox.Size = Vector3.one * 0.1;

				end

				alignHitbox.Parent = alignHitboxFolder;
				data.GridHitbox = alignHitbox;
			end
			

			local gridHitboxRayParams = RaycastParams.new();
			gridHitboxRayParams.FilterType = Enum.RaycastFilterType.Include;
			gridHitboxRayParams.IgnoreWater = true;
			gridHitboxRayParams.FilterDescendantsInstances = {alignHitboxFolder};

			local gridHitboxRaycastResult = workspace:Raycast(
				characterProperties.InteractAimOrigin, 
				aimDirection * (cameraDistance+10), 
				gridHitboxRayParams
			);
			local aimPoint = gridHitboxRaycastResult and gridHitboxRaycastResult.Position;
			if aimPoint == nil then
				aimPoint = characterProperties.InteractAimOrigin + aimDirection*(cameraDistance+16);
			end

			if gridHitboxRaycastResult then
				local hitInstance = gridHitboxRaycastResult.Instance;
				for a=1, #foundationData.GridData do
					local data = foundationData.GridData[a];
					if data.GridHitbox == hitInstance then
						gridPointData = data;
						break;
					end
				end
			end


			if gridPointData == nil then return end;
			local gridPoint = gridPointData.Point;
			selectedGridPoint = gridPoint;

			local worldGridPoint = foundationCf:PointToWorldSpace(gridPoint + Vector3.new(0, foundationSurfaceY, 0));
			local gridType = gridPointData.Type;

			highlighterPart.CFrame = CFrame.new(worldGridPoint);
			highlighterPart.Parent = camera;
			highlightLabel.Text = `GridType {gridType}`;
			
			local placeholderData = placeholderCache[selectedGridPoint] or nil;
			if prevSelectedPlaceholder ~= placeholderData then
				for _, phD in pairs(placeholderCache) do
					phD:SetColor();
				end
			end
			prevSelectedPlaceholder = placeholderData;
			
			if placeholderData then
				placeholderData:SetColor("red");
				clearActivePlaceholder();
				return;
			end;
			
			local isValidPlace = false;
			local scanInfo = {
				FoundationPart = nil;
			};

			local placeholderTemplate = buildOptionInfo.Template;

			if placeholderTemplate.CheckPlaceholder then
				local buildingScene = modBuildingPlans.getBuildingScene(selectedFoundationPart);

				local checkResult = placeholderTemplate:CheckPlaceholder{
					BuildingScene = buildingScene;
					GridSize = foundationData.GridSize;
					WorldGridPoint = worldGridPoint;
					FoundationCFrame = foundationCf;
					FoundationSize = selectedFoundationPart.Size;
				};

				if checkResult.IsValid then
					isValidPlace = true;
					scanInfo = checkResult.ScanInfo;
				end
			end

			if isValidPlace then
				local curFoundationIndex = selectedFoundationPart:GetAttribute("Index");
				local curFoundationData = curFoundationIndex and foundationObjects[curFoundationIndex] or nil;
				if curFoundationData == nil then return end;

				local placeholder = activePlaceholder;
				if placeholder == nil or placeholder.ClassName ~= placeholderTemplate.ClassName then
					if placeholder then
						placeholder:Destroy();
					end
					placeholder = placeholderTemplate.new{
						FoundationPart = selectedFoundationPart;
					};
					activePlaceholder = placeholder;
					placeholder:ToggleBillboard(true);
				end
				
				if prevBuildOption ~= buildOption then
					prevBuildOption = buildOption;
					placeholder:SetType(buildOption);
					placeholder:SetTransparency(0.5);
				end
				
				if scanInfo.FoundationPart == nil then
					scanInfo.FoundationPart = selectedFoundationPart;
				end
				scanInfo.FoundationCFrame = foundationCf;
				scanInfo.FoundationSize = selectedFoundationPart.Size;
				scanInfo.GridSize = curFoundationData.GridSize;
				scanInfo.GridType = gridType;
				scanInfo.AimPoint = aimPoint;
				scanInfo.WorldGridPoint = worldGridPoint;

				placeholder:UpdatePlaceholder(scanInfo);
				placeholder:SetParent(camera);
				placeholder:Update();


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
				placeholderCache[selectedGridPoint] = activePlaceholder:Clone("PlaceholderModel");
				placeholderCache[selectedGridPoint]:SetParent(workspace.Interactables);
				setValue = "set";
				
				modAudio.PlayReplicated("Writing", handle);
				
			else
				placeholderData:Destroy();
				placeholderCache[selectedGridPoint] = nil;
				setValue = "unset";
				
			end
			
			local returnPacket = remoteBuildingPlan:InvokeServer("setplaceholder", {
				FoundationPart = selectedFoundationPart; 
				GridPoint = selectedGridPoint;
				SetValue = setValue;
				BuildingData = placeholderCache[selectedGridPoint];
			});
			if returnPacket and returnPacket.PlayerData then
				toolHandler.UpdatePlaceholderPlans(foundationIndex, returnPacket.PlayerData);
				updatePlaceholders();
				
			else
				placeholderCache[selectedGridPoint]:Destroy();
				placeholderCache[selectedGridPoint] = nil;
				
			end
		end

		handler.Garbage:Tag(function()
			clearPlaceholders();
			
			if activePlaceholder then
				activePlaceholder:Destroy();
				activePlaceholder = nil;
			end
			for key, cachePart in pairs(placeholderCache) do
				placeholderCache[key] = nil;
			end
		end)
	end

	function toolHandler.ClientUnequip(handler: ToolHandlerInstance)
		handler.Binds.ActiveFoundation = nil;
		handler.Binds.HighlighterPart.Parent = script;
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