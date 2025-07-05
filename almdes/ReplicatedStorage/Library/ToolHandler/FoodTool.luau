local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modToolHandler = shared.require(game.ReplicatedStorage.Library.ToolHandler);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local toolHandler: ToolHandler = modToolHandler.new();
--==

function toolHandler.onRequire()
    remoteToolInputHandler = modRemotesManager:Get("ToolInputHandler");

	if RunService:IsServer() then
		
	elseif RunService:IsClient() then
		modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);

	end
end

function toolHandler.Init(handler: ToolHandlerInstance)
end

function toolHandler.Equip(handler: ToolHandlerInstance)
	local equipmentClass: EquipmentClass = handler.EquipmentClass;

	local configurations = equipmentClass.Configurations;
	local properties = equipmentClass.Properties;

	handler:LoadWieldConfig();
	Debugger:Warn(`Equip ({handler.WieldComp.ItemId})`);
end


if RunService:IsClient() then -- MARK: Client
	function toolHandler.ClientEquip(handler: ToolHandlerInstance)
		local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
		local humanoid: Humanoid = playerClass.Humanoid;

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
	
		characterProperties.HideCrosshair = true;
		characterProperties.UseViewModel = false;

		local startUseTick;
		local function reset()
			startUseTick = nil;
		end
		
		local mainToolModel = handler.MainToolModel;
		local handle = mainToolModel and mainToolModel:WaitForChild("Handle") or nil;
		
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
		
		RunService:BindToRenderStep("ToolRender", Enum.RenderPriority.Character.Value, function()
			if mouseProperties.Mouse1Down and characterProperties.CanAction then
				local track = toolAnimator:GetPlaying("Use");
				if track == nil then
					track = toolAnimator:Play("Use", {
						PlayLength = configurations.UseDuration;
					});
				end

				if startUseTick == nil then
					startUseTick = tick();
					remoteToolInputHandler:FireServer(modRemotesManager.Compress({
						Action = "action";
						Siid = siid;
						ActionIndex = 1;
					}));
					
				else
					local progress = (tick()-startUseTick)/configurations.UseDuration;
					if progress >= 1 then
						mouseProperties.Mouse1Down = false;
						reset();
						remoteToolInputHandler:FireServer(modRemotesManager.Compress({
							Action = "action";
							Siid = siid;
							ActionIndex = 2;
						}));
					end
					
				end
			else
				toolAnimator:Stop("Use");
				reset();
			end
		end);
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
			properties.LastFire = tick();
			
		elseif actionIndex == 2 then
			local itemId = storageItem.ItemId;
			local itemLib = modItemsLibrary:Find(itemId);
			
			local useDuration = configurations.UseDuration;
			
			local lapsed = tick() - properties.LastFire;
			local inValidTimeRange = lapsed >= useDuration-0.5 and lapsed <= useDuration+0.5;
			if inValidTimeRange == false then
				Debugger:Warn("TimeLapsed invalid", inValidTimeRange, "configurations.UseDuration", configurations.UseDuration, "useDuration", useDuration);
				return;
			end

			if storageItem and storageItem.Quantity <= 0 then return end;

			if configurations.EffectType == "Food" then
				if configurations.Calories then
					local hungerStatus: StatusClassInstance = statusComp:GetOrDefault("Hunger");
					hungerStatus:Func("SetValue", hungerStatus.Values.CurValue + configurations.Calories);
				end
				if configurations.Hydration then
					local thirstStatus: StatusClassInstance = statusComp:GetOrDefault("Thirst");
					thirstStatus:Func("SetValue", thirstStatus.Values.CurValue + configurations.Hydration);
				end

			end
	
			characterClass.WieldComp:Unequip();

			if characterClass.ClassName == "PlayerClass" then
				local player = (characterClass :: PlayerClass):GetInstance();
				local profile = shared.modProfile:Get(player);
				local inventory = profile.ActiveInventory;

				inventory:Remove(handler.StorageItem.ID, 1);
				shared.Notify(player, `{itemLib.Name} removed from your Inventory.`, "Negative");
			end
		end

	end
end

return toolHandler;