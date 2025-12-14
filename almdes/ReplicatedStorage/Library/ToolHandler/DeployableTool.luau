local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local localPlayer = game.Players.LocalPlayer;
local camera = workspace.CurrentCamera;

local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modToolHandler = shared.require(game.ReplicatedStorage.Library.ToolHandler);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modDoors = shared.require(game.ReplicatedStorage.Entity.Doors);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modToolsLibrary = shared.require(game.ReplicatedStorage.Library.ToolsLibraryAlmdes);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);


local PLACEMENT_COLORS = {
	Placable = Color3.fromRGB(124, 161, 200);
	Invalid = Color3.fromRGB(200, 124, 124);
}

local DEPLOYABLE_PREFABS;
local DEPLOYABLE_HANDLER_MODULES;
local deployableCounter = 0;


local worldRayParams = RaycastParams.new();
worldRayParams.FilterType = Enum.RaycastFilterType.Include;
worldRayParams.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain;};

local toolHandler = modToolHandler.new();
--==

function toolHandler.onRequire()
    remoteToolInputHandler = modRemotesManager:Get("ToolInputHandler");

	DEPLOYABLE_PREFABS = game.ReplicatedStorage.Prefabs:WaitForChild("Deployables");
	DEPLOYABLE_HANDLER_MODULES = game.ReplicatedStorage.Library:WaitForChild("DeployableHandlers");

	if RunService:IsServer() then
    	serverPrefabs = game.ServerStorage:WaitForChild("Prefabs"):WaitForChild("Objects");

	elseif RunService:IsClient() then
		modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule"));

	end
end

function toolHandler.Init(handler: ToolHandlerInstance)
end

function toolHandler.Equip(handler: ToolHandlerInstance)
	handler:LoadWieldConfig();
	Debugger:Warn(`Equip ({handler.WieldComp.ItemId})`);
end


if RunService:IsClient() then -- MARK: Client
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
		
		local toolPackage = handler.ToolPackage;
		local animations = toolPackage.Animations;

		local configurations: ConfigVariable = equipmentClass.Configurations;
		local properties: PropertiesVariable<{}> = equipmentClass.Properties;
		local binds = handler.Binds;

		characterProperties.HideCrosshair = true;
		characterProperties.UseViewModel = false;

		local mainToolModel = handler.MainToolModel;
		local mainHandle = mainToolModel.PrimaryPart;
		
		local deployableHandler = nil;
		local deployableHandlerModule = DEPLOYABLE_HANDLER_MODULES:FindFirstChild(configurations.DeployableType);
		if deployableHandlerModule then
			deployableHandler = shared.require(deployableHandlerModule);
		end

		local templatePlacementPrefab: Model;
		if configurations.UseToolModelItemId then
			local toolPackageOfToolModel = modToolsLibrary.get(configurations.UseToolModelItemId);
			templatePlacementPrefab = toolPackageOfToolModel.Prefab;

		elseif DEPLOYABLE_PREFABS:FindFirstChild(itemId) and DEPLOYABLE_PREFABS[itemId] then
			local skinId = "Default";
			local matchingSkins = {};
			for _, obj in pairs(DEPLOYABLE_PREFABS[itemId]:GetChildren()) do
				if obj.Name:sub(1, #skinId) == skinId then
					table.insert(matchingSkins, obj.Name);
				end
			end
			templatePlacementPrefab = DEPLOYABLE_PREFABS[itemId]:FindFirstChild(matchingSkins[math.random(1, 2)] or skinId);
		end

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
		
		local activeHightlightModel = nil;
		handler.Garbage:Tag(function()
			activeHightlightModel:Destroy();
			activeHightlightModel = nil;
		end);

		local activePlacementColor = nil;
		local function setHighlightColor(color)
			if activeHightlightModel == nil then return end;
			if activePlacementColor == color then return end;
			activePlacementColor = color;

			for _, obj in pairs(activeHightlightModel:GetDescendants()) do
				if not obj:IsA("BasePart") then continue end;
				if obj.CanQuery == false and obj.Transparency == 1 then continue end;
				obj.Anchored = true;
				obj.CanCollide = false;
				obj.CanQuery = false;
				obj.Transparency = 0.8;
				obj.Material = Enum.Material.Neon;
				obj.Color = color;
			end
		end

		properties.RotY = 0;
		binds["KeyRotate"] = function()
			if properties.RotY + 1 >= 4 then
				properties.RotY = 0;
			else
				properties.RotY = properties.RotY + 1;
			end
		end

		local interactProxy: InteractableInstance = nil;
		local isCfLocked = false;
		RunService:BindToRenderStep("ToolRender", Enum.RenderPriority.Character.Value, function()
			if not characterProperties.CanAction then
				activeHightlightModel.Parent = script;
				characterProperties.ProxyInteractable = nil;
				return;
			end
			local aimRayHit = characterProperties.InteractRayHit;
			local aimPoint = characterProperties.InteractAimPoint;
			local aimNormal = characterProperties.InteractAimNormal;

			if activeHightlightModel == nil then
				activeHightlightModel = templatePlacementPrefab:Clone();
				setHighlightColor(PLACEMENT_COLORS.Invalid);

				interactProxy = modInteractables.newProxy("Deployable");
				interactProxy.Part = activeHightlightModel.PrimaryPart;
				interactProxy.CanInteract = false;
				interactProxy.InteractDuration = 1;

				function interactProxy.BindInteract(interactable: InteractableInstance, info: InteractInfo)
					Debugger:Warn(`Build {itemId}`);
					remoteToolInputHandler:FireServer(modRemotesManager.Compress({
						Action = "action";
						ActionIndex = 1;
						Siid = storageItem.ID;
						ProxyValues = interactProxy.Values.Raw;
					}));
				end

				function interactProxy.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
					isCfLocked = characterProperties.InteractAlpha > 0;
				end

				handler.Garbage:Tag(function()
					(interactProxy::any).Part = nil;
					characterProperties.ProxyInteractable = nil;
				end)
			end

			--MARK: ToolRender socket
			local socketInteractConfig: Configuration = playerClass.Properties.RayHitInteractable;
			if socketInteractConfig and socketInteractConfig:GetAttribute("_Name") == "DeployableSocket" then
				activeHightlightModel.Parent = camera;
				characterProperties.ProxyInteractable = interactProxy;

				local socketInteractable = modInteractables.getOrNew(socketInteractConfig);
				local attachPoint: Attachment = socketInteractable.Values.AttachmentPoint;

				local interactPart = socketInteractable.Part;
				if configurations.ResizeToFit and interactPart then
					local newSize = interactPart.Size;
					activeHightlightModel.PrimaryPart.Size = Vector3.new(
						math.abs(newSize.X), 
						math.abs(newSize.Y), 
						math.abs(newSize.Z)
					);
				end

				local placeCf: CFrame = attachPoint.WorldCFrame;
				placeCf = placeCf * CFrame.Angles(0, properties.RotY* math.pi/2, 0);

				activeHightlightModel:PivotTo(placeCf);

				local isPlaceable = true;
				if socketInteractable.Variant ~= configurations.DeployableType then
					isPlaceable = false;
				elseif socketInteractable.Values.ActiveDeployable.Value ~= nil then
					isPlaceable = false;
				end

				if isPlaceable then
					
					interactProxy.Values.PrefabName = activeHightlightModel.Name;
					interactProxy.Values.SocketConfig = socketInteractConfig;
					interactProxy.Values.RotationY = properties.RotY;
					interactProxy.Values.AimRayHit = aimRayHit;
					interactProxy.Values.AimPoint = aimPoint;
					
					setHighlightColor(PLACEMENT_COLORS.Placable);
					interactProxy.CanInteract = true;
					interactProxy.Label = `Attach`;
			
				else
					setHighlightColor(PLACEMENT_COLORS.Invalid);
					interactProxy.CanInteract = false;
					interactProxy.Label = `Can't attach here`;

				end


			--MARK: ToolRender free 
			elseif aimRayHit then

				local hitDeployableModel = aimRayHit.Parent;
				while hitDeployableModel:IsDescendantOf(workspace.Environment.Game) do
					if hitDeployableModel:HasTag("Deployable") then break; end;
					hitDeployableModel = hitDeployableModel.Parent;
				end
				if hitDeployableModel and not hitDeployableModel:HasTag("Deployable") then
					hitDeployableModel = nil;
				end

				activeHightlightModel.Parent = camera;
				characterProperties.ProxyInteractable = interactProxy;

				local lookVector = camera.CFrame.LookVector:Cross(aimNormal);
				local placeCf: CFrame = CFrame.lookAlong(aimPoint, lookVector, aimNormal)
										* CFrame.Angles(0, math.pi/2, 0);
				
				if configurations.PlacementOffset then
					placeCf = placeCf * configurations.PlacementOffset;
				end

				local isPlaceable = true;
				local placeableLabel = `Build`;
				local invalidPlaceReason = "Invalid placement";

				if deployableHandler and deployableHandler.BindDeployablePlacement then
					local packet = {
						HitDeployableModel = hitDeployableModel;
						PlaceCFrame = placeCf;

						AimRayHit = aimRayHit;
						AimPoint = aimPoint;

						IsPlaceable = nil;
						InvalidReason = nil;
						PlaceableLabel = nil;
					};
					deployableHandler.BindDeployablePlacement(handler, packet);
					placeCf = packet.PlaceCFrame;

					if packet.IsPlaceable == false then
						isPlaceable = false;
						invalidPlaceReason = packet.InvalidReason or invalidPlaceReason;
					else
						placeableLabel = packet.PlaceableLabel or placeableLabel;
					end
				end

				placeCf = placeCf * CFrame.Angles(0, properties.RotY* math.pi/2, 0);

				if localPlayer:DistanceFromCharacter(placeCf.Position) > 15 then
					isPlaceable = false;
				end

				local placeNormalLimits = configurations.PlaceNormalLimits;
				if isPlaceable and placeNormalLimits then
					local groundAngle = math.acos(Vector3.yAxis:Dot(aimNormal));
					if groundAngle < placeNormalLimits.Min or groundAngle > placeNormalLimits.Max then
						isPlaceable = false;
						invalidPlaceReason = `Surface is too steep`;
					end
				end

				if isCfLocked == false or isPlaceable == false then
					activeHightlightModel:PivotTo(placeCf);
				end

				if isPlaceable then
					interactProxy.Values.PrefabName = activeHightlightModel.Name;
					interactProxy.Values.PlaceCFrame = activeHightlightModel:GetPivot();
					interactProxy.Values.HitDeployableModel = hitDeployableModel;
					interactProxy.Values.RotationY = properties.RotY;

					interactProxy.Values.AimRayHit = aimRayHit;
					interactProxy.Values.AimPoint = aimPoint;
					
					setHighlightColor(PLACEMENT_COLORS.Placable);
					interactProxy.CanInteract = true;
					interactProxy.Label = placeableLabel;
			
				else
					setHighlightColor(PLACEMENT_COLORS.Invalid);
					interactProxy.CanInteract = false;

					if invalidPlaceReason then
						interactProxy.Label = invalidPlaceReason;
					else
						interactProxy.Label = `Can't Place Here`;
					end
				end

			else
				activeHightlightModel.Parent = script;
				characterProperties.ProxyInteractable = nil;
			end
		end);
	end

	function toolHandler.ClientUnequip(handler: ToolHandlerInstance)
	end

elseif RunService:IsServer() then -- MARK: Server

	--MARK: spawnDeployable
	function toolHandler.spawnDeployable(itemId, prefabName, placeCf, params)
		local itemLib = modItemsLibrary:Find(itemId);
		local configurations = params.Configurations or {};
		local socketInteractable: InteractableInstance = params.SocketInteractable;

		local templatePlacementPrefab;
		if configurations.UseToolModelItemId then
			local toolPackageOfToolModel = modToolsLibrary.get(configurations.UseToolModelItemId);
			templatePlacementPrefab = toolPackageOfToolModel.Prefab;

		else
			local prefabsList = DEPLOYABLE_PREFABS:FindFirstChild(itemId);
			if prefabsList == nil then
				Debugger:Warn("Missing deployablePrefab:", itemId);
				return;
			end

			local skinId = "Default";
			if prefabName == nil then
				local matchingSkins = {};
				for _, obj in pairs(prefabsList:GetChildren()) do
					if obj.Name:sub(1, #skinId) == skinId then
						table.insert(matchingSkins, obj.Name);
					end
				end
				prefabName = matchingSkins[math.random(1, #matchingSkins)];
			end

			templatePlacementPrefab = prefabsList:FindFirstChild(prefabName);

		end

		if templatePlacementPrefab == nil then
			Debugger:Warn("Missing templatePlacementPrefab.", itemId);
			return;
		end

		local new = templatePlacementPrefab:Clone();
		new.Name = `{itemId}$u{deployableCounter}`;
		new:PivotTo(placeCf);
		new:AddTag("Deployable");
		new.Parent = workspace.Environment.Game;

		local destructibleConfig: Configuration = modDestructibles.createDestructible();
		destructibleConfig.Parent = new;
		local newDestructible: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);
		newDestructible.DebrisName = itemId;

		newDestructible.OnDestroy:Connect(function()
			for _, obj in pairs(new:GetChildren()) do
				if obj:IsA("Configuration") then
					obj:Destroy();
				end
			end
		end)

		if configurations.ResizeToFit and socketInteractable and socketInteractable.Part then
			local newSize = socketInteractable.Part.Size;
			new.PrimaryPart.Size = Vector3.new(math.abs(newSize.X), math.abs(newSize.Y), math.abs(newSize.Z));
		end

		if configurations.IsDoorEntity then
			local doorConfig = modDoors.createDoor();
			doorConfig.Parent = new;

		end

		if new:FindFirstChild("WieldConfig") then
			new.WieldConfig:Destroy();
		end

		local interactConfig;
		local newInteractable: InteractableInstance;

		if configurations.InteractableName then
			interactConfig = modInteractables.createInteractable(configurations.InteractableName);
			interactConfig:SetAttribute("_Variant", itemId);
			interactConfig.Parent = new;

			newInteractable = modInteractables.getOrNew(interactConfig);
		end

		if configurations.InteractableName == "Storage" then
			local storagePresetId = configurations.StoragePresetId;

			interactConfig:SetAttribute("StorageId", `{itemId}$u{deployableCounter}`);
			interactConfig:SetAttribute("StorageName", itemLib.Name);
			interactConfig:SetAttribute("StoragePresetId", storagePresetId);
			
			if newInteractable then
				newInteractable:SetPermissions("CanInteract", true);
			end
		end

		if socketInteractable and socketInteractable.Values.ActiveDeployable then
			socketInteractable.Values.ActiveDeployable.Value = new;
			new:GetPropertyChangedSignal("Parent"):Once(function()
				if new.Parent == workspace.Environment.Game then return end;
				socketInteractable.Values.ActiveDeployable.Value = nil;
			end)
		end

		if params.AddBlockade then
			local blockadeId = params.AddBlockade;

			local blockadeFolder = serverPrefabs:FindFirstChild("DefaultBlockades");
			if blockadeFolder then
				local newBlockade: Model = blockadeFolder[blockadeId]:Clone();
				newBlockade.Name = "Blockade";
				newBlockade:PivotTo(new:GetPivot() * CFrame.new(0, (socketInteractable and socketInteractable.Part.Size.Y/2) or 0, 0));
				newBlockade.Parent = new;
				
				local blkDestructibleModule = newBlockade:WaitForChild("Destructible");
				local blkDestructible: DestructibleInstance = modDestructibles.getOrNew(blkDestructibleModule);
				blkDestructible.HealthComp:SetMaxHealth(200);
				blkDestructible.HealthComp:SetHealth(200);

				newDestructible.OnDestroy:Connect(function()
					newDestructible.HealthComp:SetIsDead(true);
				end)
			end
		end

		local deployableHandler = nil;
		local deployableHandlerModule = DEPLOYABLE_HANDLER_MODULES:FindFirstChild(configurations.DeployableType);
		if deployableHandlerModule then
			deployableHandler = shared.require(deployableHandlerModule);
		end
		if deployableHandler and deployableHandler.BindSpawnDeployable then
			params.DeployableModel = new;
			params.NewInteractable = newInteractable;
			params.NewDestructible = newDestructible;
			deployableHandler.BindSpawnDeployable(nil, params);
		end
		
		task.spawn(function()
			local outsideExposureCFrame = nil;

			local originCf = placeCf;
			local angStep = math.pi/3;
			for a=1, 6 do
				local outwardCf = originCf * CFrame.Angles(0, angStep*a, 0) * CFrame.Angles(math.rad(45), 0, 0) * CFrame.new(0, 3, 0);
				local upwardCf = outwardCf * CFrame.Angles(math.rad(-30), 0, 0);
				local dir = upwardCf.UpVector * 32;
				local rayResult = workspace:Raycast(outwardCf.Position, dir, worldRayParams);
				
				-- local rayDbPart = Debugger:Ray(
				-- 	Ray.new(outwardCf.Position, dir), 
				-- 	rayResult and rayResult.Instance or nil, 
				-- 	rayResult and rayResult.Position or nil, 
				-- 	rayResult and rayResult.Normal or nil
				-- );
				-- rayDbPart.Name = `ray{a}`;
				-- game.Debris:AddItem(rayDbPart, 60);

				if rayResult == nil then
					outsideExposureCFrame = upwardCf;
					break;
				end
			end
			
			new:SetAttribute("OutsideExposureCFrame", outsideExposureCFrame);
		end)

		return new;
	end

	function toolHandler.ActionEvent(handler: ToolHandlerInstance, packet)
		local characterClass: CharacterClass = handler.CharacterClass;
		local actionIndex = packet.ActionIndex;

		local healthComp: HealthComp = characterClass.HealthComp;
		if healthComp.IsDead then return end;
	
		local wieldComp: WieldComp = characterClass.WieldComp;
		local statusComp: StatusComp = characterClass.StatusComp;

		local equipmentClass: EquipmentClass =  handler.EquipmentClass;
		local configurations = equipmentClass.Configurations;
		local properties = equipmentClass.Properties;

		local storageItem: StorageItem = handler.StorageItem;
		local itemId = storageItem.ItemId;
		local itemLib = storageItem.Library;

		local deployableHandler = nil;
		local deployableHandlerModule = DEPLOYABLE_HANDLER_MODULES:FindFirstChild(configurations.DeployableType);
		if deployableHandlerModule then
			deployableHandler = shared.require(deployableHandlerModule);
		end

		if actionIndex == 1 then
			local proxyValues = packet.ProxyValues;
			local placeCf;

			local interactable: InteractableInstance;
			local aimInteractConfig = proxyValues.SocketConfig;
			local hitDeployableModel = proxyValues.HitDeployableModel;
			local rotationY = proxyValues.RotationY or 0;

			local aimRayHit = proxyValues.AimRayHit;
			local aimPoint = proxyValues.AimPoint;

			local isPlaceable = true;
			local placementPacket = {
				CharacterClass = characterClass;
				PlaceCFrame = proxyValues.PlaceCFrame;
				HitDeployableModel = hitDeployableModel;

				AimRayHit = aimRayHit;
				AimPoint = aimPoint;

				IsPlaceable = nil;
				InvalidReason = nil;
			};

			if aimInteractConfig
			and aimInteractConfig:IsA("Configuration")
			and aimInteractConfig:GetAttribute("_Name") == "DeployableSocket" then
				interactable = modInteractables.getOrNew(aimInteractConfig);
				local attachPoint: Attachment = interactable.Values.AttachmentPoint;
				placeCf = attachPoint.WorldCFrame *  CFrame.Angles(0, rotationY * math.pi/2, 0);
				placementPacket.AttachPoint = attachPoint;

			elseif hitDeployableModel then
				if deployableHandler and deployableHandler.BindDeployablePlacement then
					deployableHandler.BindDeployablePlacement(handler, placementPacket);
					placeCf = placementPacket.PlaceCFrame;

					if placementPacket.IsPlaceable == false then
						isPlaceable = false;
					end
				end

			else
				placeCf = proxyValues.PlaceCFrame;
			end

			if isPlaceable == false then
				Debugger:Warn("Not placeable.", placementPacket.InvalidReason or "unknown reason");
				return;
			end

			if placeCf == nil then
				Debugger:Warn("Missing PlaceCFrame.", proxyValues);
				return;
			end

			deployableCounter = deployableCounter +1;

			local prefabName = proxyValues.PrefabName;

			placementPacket.CharacterClass = characterClass;
			placementPacket.Configurations = configurations;
			placementPacket.SocketInteractable = interactable;
			local new = toolHandler.spawnDeployable(itemId, prefabName, placeCf, placementPacket);
			if new == nil then
				Debugger:Warn(`Fail to spawn deployable {itemId}:{prefabName}.`);
				return;
			end

			Debugger:StudioLog(`Build {itemLib.Name}`, packet);
			if characterClass.ClassName == "PlayerClass" then
				local playerClass: PlayerClass = characterClass :: PlayerClass;
				local player: Player = playerClass:GetInstance();
				local profile: ProfileAlmdes = shared.modProfile:Get(player);

				local inventory: Storage = profile.ActiveInventory;
				if storageItem.Quantity == 1 then
					wieldComp:Unequip();
				end
				inventory:Remove(storageItem.ID, 1);
				shared.Notify(player, `1 {itemLib.Name} removed from your Inventory.`, "Negative");
			end

			if configurations.CollectionTags then
				for a=1, #configurations.CollectionTags do
					new:AddTag(configurations.CollectionTags[a]);
				end
			end
		end

	end
end

return toolHandler;