local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local localPlayer = game.Players.LocalPlayer;
local camera = workspace.CurrentCamera;

local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modToolHandler = shared.require(game.ReplicatedStorage.Library.ToolHandler);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modDoors = shared.require(game.ReplicatedStorage.Entity.Doors);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);


local PLACEMENT_COLORS = {
	Placable = Color3.fromRGB(124, 161, 200);
	Invalid = Color3.fromRGB(200, 124, 124);
}

local DEPLOYABLE_PREFABS;
local DEPLOYABLE_HANDLER_MODULES;
local deployableCounter = 0;

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

		local toolPrefab = toolPackage.Prefab;

		local mainToolModel = handler.MainToolModel;
		local handle = mainToolModel and mainToolModel:WaitForChild("Handle") or nil;
		
		local deployableHandler = nil;
		local deployableHandlerModule = DEPLOYABLE_HANDLER_MODULES:FindFirstChild(configurations.DeployableType);
		if deployableHandlerModule then
			deployableHandler = shared.require(deployableHandlerModule);
		end

		local templatePlacementPrefab: Model;
		if DEPLOYABLE_PREFABS:FindFirstChild(itemId) and DEPLOYABLE_PREFABS[itemId] then
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
				interactProxy.Part = activeHightlightModel:WaitForChild("PrimaryPart");
				interactProxy.CanInteract = false;
				interactProxy.InteractDuration = 1;

				function interactProxy.BindInteract(interactable: InteractableInstance, info: InteractInfo)
					Debugger:Warn(`Build {itemId}`);
					remoteToolInputHandler:FireServer(modRemotesManager.Compress({
						Action = "action";
						ActionIndex = 1;
						Siid = storageItem.ID;
						ProxyValues = interactProxy.Values;
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

			local aimInteractConfig: Configuration = playerClass.Properties.RayHitInteractable;
			if aimInteractConfig and aimInteractConfig:GetAttribute("_Name") == "DeployableSocket" then
				activeHightlightModel.Parent = camera;
				characterProperties.ProxyInteractable = interactProxy;

				local interactable = modInteractables.getOrNew(aimInteractConfig);
				local attachPoint: Attachment = interactable.Values.AttachmentPoint;

				local interactPart = interactable.Part;
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
				if interactable.Variant ~= configurations.DeployableType then
					isPlaceable = false;
				elseif interactable.Values.ActiveDeployable.Value ~= nil then
					isPlaceable = false;
				end

				if isPlaceable then
					interactProxy.Values = {
						PrefabName = activeHightlightModel.Name;
						SocketConfig = aimInteractConfig;
						RotationY = properties.RotY;
					};
					setHighlightColor(PLACEMENT_COLORS.Placable);
					interactProxy.CanInteract = true;
					interactProxy.Label = `Attach`;
			
				else
					setHighlightColor(PLACEMENT_COLORS.Invalid);
					interactProxy.CanInteract = false;
					interactProxy.Label = `Can't Attach Here`;
				end


			elseif aimRayHit then

				local deployableModel = aimRayHit.Parent;
				while deployableModel:IsDescendantOf(workspace.Environment.Game) do
					if deployableModel:HasTag("Deployable") then break; end;
					deployableModel = deployableModel.Parent;
				end
				if deployableModel and not deployableModel:HasTag("Deployable") then
					deployableModel = nil;
				end

				activeHightlightModel.Parent = camera;
				characterProperties.ProxyInteractable = interactProxy;

				local lookVector = camera.CFrame.LookVector:Cross(aimNormal);
				local placeCf: CFrame = CFrame.lookAlong(aimPoint, lookVector, aimNormal)
										* CFrame.Angles(0, math.pi/2, 0);
				
				if configurations.PlacementOffset then
					placeCf = placeCf * configurations.PlacementOffset;
				end

				if deployableHandler and deployableHandler.BindDeployablePlacement then
					local packet = {
						DeployableModel = deployableModel;
						PlaceCFrame = placeCf;
					};
					deployableHandler.BindDeployablePlacement(handler, packet);
					placeCf = packet.PlaceCFrame;
				end

				placeCf = placeCf * CFrame.Angles(0, properties.RotY* math.pi/2, 0);

				local isPlaceable = true;
				if localPlayer:DistanceFromCharacter(placeCf.Position) > 15 then
					isPlaceable = false;
				end

				if isCfLocked == false or isPlaceable == false then
					activeHightlightModel:PivotTo(placeCf);
				end

				if isPlaceable then
					interactProxy.Values = {
						PrefabName = activeHightlightModel.Name;
						PlaceCFrame = activeHightlightModel:GetPivot();
						DeployableModel = deployableModel;
						RotationY = properties.RotY;
					};
					setHighlightColor(PLACEMENT_COLORS.Placable);
					interactProxy.CanInteract = true;
					interactProxy.Label = `Build`;
			
				else
					setHighlightColor(PLACEMENT_COLORS.Invalid);
					interactProxy.CanInteract = false;
					interactProxy.Label = `Can't Place Here`;
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
		local interactable = params.Interactable;

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

		local templatePlacementPrefab = prefabsList:FindFirstChild(prefabName);
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
		local deployDestructible: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);

		deployDestructible.OnDestroy:Connect(function()
			for _, obj in pairs(new:GetChildren()) do
				if obj:IsA("Configuration") then
					obj:Destroy();
				end
			end
		end)

		if configurations.ResizeToFit and interactable and interactable.Part then
			local newSize = interactable.Part.Size;
			new.PrimaryPart.Size = Vector3.new(math.abs(newSize.X), math.abs(newSize.Y), math.abs(newSize.Z));
		end

		if configurations.IsDoorEntity then
			local doorConfig = modDoors.createDoor();
			doorConfig.Parent = new;

		end

		local interactConfig;
		if configurations.InteractableName then
			interactConfig = modInteractables.createInteractable(configurations.InteractableName);
			interactConfig.Parent = new;
		end

		if configurations.InteractableName == "Storage" then
			local storagePresetId = configurations.StoragePresetId;

			interactConfig:SetAttribute("StorageId", `{itemId}$u{deployableCounter}`);
			interactConfig:SetAttribute("StorageName", itemLib.Name);
			interactConfig:SetAttribute("StoragePresetId", storagePresetId);
			
			if interactable then
				interactable:SetPermissions("CanInteract", true);
			end
		end

		if interactable and interactable.Values.ActiveDeployable then
			interactable.Values.ActiveDeployable.Value = new;
			new:GetPropertyChangedSignal("Parent"):Once(function()
				if new.Parent == workspace.Environment.Game then return end;
				interactable.Values.ActiveDeployable.Value = nil;
			end)
		end

		if params.AddBlockade then
			local blockadeId = params.AddBlockade;

			local blockadeFolder = serverPrefabs:FindFirstChild("DefaultBlockades");
			if blockadeFolder then
				local newBlockade: Model = blockadeFolder[blockadeId]:Clone();
				newBlockade.Name = "Blockade";
				newBlockade:PivotTo(new:GetPivot() * CFrame.new(0, (interactable and interactable.Part.Size.Y/2) or 0, 0));
				newBlockade.Parent = new;
				
				local blkDestructibleModule = newBlockade:WaitForChild("Destructible");
				local blkDestructible: DestructibleInstance = modDestructibles.getOrNew(blkDestructibleModule);
				blkDestructible.HealthComp:SetMaxHealth(200);
				blkDestructible.HealthComp:SetHealth(200);

				deployDestructible.OnDestroy:Connect(function()
					deployDestructible.HealthComp:SetIsDead(true);
				end)
			end
		end


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
			local deployableModel = proxyValues.DeployableModel;
			local rotationY = proxyValues.RotationY or 0;

			Debugger:Warn(`rotationY: {rotationY}`);

			local placementPacket = {
				DeployableModel = deployableModel;
				PlaceCFrame = placeCf;
			};

			if aimInteractConfig
			and aimInteractConfig:IsA("Configuration")
			and aimInteractConfig:GetAttribute("_Name") == "DeployableSocket" then
				interactable = modInteractables.getOrNew(aimInteractConfig);
				local attachPoint: Attachment = interactable.Values.AttachmentPoint;
				placeCf = attachPoint.WorldCFrame *  CFrame.Angles(0, rotationY * math.pi/2, 0);
				placementPacket.AttachPoint = attachPoint;

			elseif deployableModel then
				if deployableHandler and deployableHandler.BindDeployablePlacement then
					deployableHandler.BindDeployablePlacement(handler, placementPacket);
					placeCf = placementPacket.PlaceCFrame;
				end

			else
				placeCf = proxyValues.PlaceCFrame;
			end


			if placeCf == nil then
				Debugger:Warn("Missing PlaceCFrame.", proxyValues);
				return;
			end

			deployableCounter = deployableCounter +1;

			local prefabName = proxyValues.PrefabName;

			local new = toolHandler.spawnDeployable(itemId, prefabName, placeCf, {
				Configurations = configurations;
				Interactable = interactable;
			});
			if deployableHandler and deployableHandler.BindSpawnDeployable then
				deployableHandler.BindSpawnDeployable(handler, {
					PlacementData = placementPacket;
					DeployableModel = new;
				});
			end

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

			if configurations.NewInteractable then
				local newInteractConfig = modInteractables.createInteractable(configurations.NewInteractable);
				newInteractConfig.Parent = new;
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