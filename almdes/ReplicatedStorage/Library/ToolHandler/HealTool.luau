local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modToolHandler = shared.require(game.ReplicatedStorage.Library.ToolHandler);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local toolHandler = modToolHandler.new();
--==
function toolHandler.onRequire()
    remoteToolInputHandler = modRemotesManager:Get("ToolInputHandler");

	if RunService:IsServer() then
        shared.modEventService:OnInvoked("Tools_BindHealTool", function(eventPacket: EventPacket, ...)
            local action, handler, toCharacterClass = ...;

            if action == "UseComplete" then
                local equipmentClass: EquipmentClass = handler.EquipmentClass;
                local configurations = equipmentClass.Configurations;
                local properties = equipmentClass.Properties;

                local healAmount = configurations.HealAmount;

                local statusComp: StatusComp = toCharacterClass.StatusComp;

                local newHealAmount = healAmount;

                local comfortStatus: StatusClassInstance = statusComp:GetOrDefault("Comfort");
                if comfortStatus and comfortStatus.Values.CurValue < 50 then
                    local comfortRatio = math.clamp(comfortStatus.Values.CurValue / 50, 0, 1);
                    newHealAmount = newHealAmount * comfortRatio;
                end

                properties.HealAmount = math.max(newHealAmount, 10);
            end
        end)

	elseif RunService:IsClient() then
		modCameraUtil = shared.require(game.ReplicatedStorage.Library.Util.CameraUtil);
		modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);

	end
end

function toolHandler.Init(handler: ToolHandlerInstance)
end

function toolHandler.Equip(handler: ToolHandlerInstance)
	handler:LoadWieldConfig();
end


if RunService:IsClient() then -- MARK: Client
	function toolHandler.ClientEquip(handler: ToolHandlerInstance)
		local modCharacter = modData:GetModCharacter();
		
		local mouseProperties = modCharacter.MouseProperties;
		local characterProperties = modCharacter.CharacterProperties;

		local toolPackage = handler.ToolPackage;
		local equipmentClass: EquipmentClass = handler.EquipmentClass;
		local toolAnimator: ToolAnimator = handler.ToolAnimator;
		local storageItem: StorageItem = handler.StorageItem;
	
		local siid = storageItem.ID;
		local itemId = storageItem.ItemId;
		
		local animations = toolPackage.Animations;
		
	
		local configurations = equipmentClass.Configurations;
		local properties = equipmentClass.Properties;

		local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
		local humanoid = playerClass.Humanoid;

		local toolModel = handler.MainToolModel;
		local handle = toolModel and toolModel:WaitForChild("Handle") or nil;
		local trailEffect = handle and handle:FindFirstChild("BandageTrail") or nil;

		local startUseTick, progressBarTick;
		
		if storageItem.IsFake then
			properties.MockItem = true;
		end
		
		local mechanicsBarElement: InterfaceElement = modClientGuis.getElement("MechanicsBar");
		local function updateProgressionBar(p)
			p = p or 0;
			if progressBarTick == nil or tick()-progressBarTick > 0.1 then
				progressBarTick = tick();

				if mechanicsBarElement then
					mechanicsBarElement.ProgressValue = p;
					mechanicsBarElement.ProgressType = "Eating";
				end
			end
		end
		
		local function reset()
			startUseTick = nil;
			progressBarTick = nil;
			updateProgressionBar();
		end
		
		toolAnimator:LoadAnimations(animations, toolPackage.DefaultAnimatorState, handler.Prefabs);
		toolAnimator:Play("Core");

		characterProperties.HideCrosshair = true;
		characterProperties.UseViewModel = false;
		
		properties.UseDuration = configurations.UseDuration;

		local isWounded = false;
        local isTargetDead = false;

		local function useStart()
			properties.UseDuration = configurations.UseDuration;
			
			shared.modEventService:ClientInvoke("Tools_BindHealTool", {SendBy=localPlayer;}, "UseStart", handler);
			
            if isTargetDead then
				properties.UseDuration = properties.UseDuration * 3;
			elseif isWounded then
				properties.UseDuration = properties.UseDuration * 2;
			end
		end

		local minRad = math.pi*2;
		local lastScan, prevHealingChar = tick(), nil;
		local activateMethod = nil;


		local healProxyInteract = modInteractables.newProxy();
		healProxyInteract.CanInteract = false;

		handler.Garbage:Tag(function()
			if characterProperties.ProxyInteractable == healProxyInteract then
				characterProperties.ProxyInteractable = nil;
			end
		end)

		local function interactActivate(activateMethod)
			remoteToolInputHandler:FireServer(modRemotesManager.Compress{
				Siid = siid;
				Action = "action";
				ActionIndex = activateMethod;
				TargetCharacter = activateMethod == 2 and healProxyInteract.TargetCharacter or localPlayer.Character;
			});
		end
		
		function healProxyInteract:OnStartInteract()
			if not characterProperties.CanAction then return end;
			useStart()
			self.InteractDuration = properties.UseDuration;
			interactActivate(1);
		end
	
		function healProxyInteract:OnInteracted(library)
			if not characterProperties.CanAction then return end;
			interactActivate(2);
		end

		function healProxyInteract.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
		end

		local healthWindow: InterfaceWindow = modClientGuis.getWindow("HealthWindow");
		RunService:BindToRenderStep("ToolRender", Enum.RenderPriority.Character.Value, function()
			if healthWindow then
				local hpRatio = (humanoid.Health+configurations.HealAmount)/humanoid.MaxHealth;
				healthWindow.Properties.PreviewVisible = true;
				healthWindow.Properties.PreviewBorderSize = 2;
				healthWindow.Properties.PreviewSize = UDim2.new(math.clamp(hpRatio, 0, 1), 0, 1, 0);
			end

			if mouseProperties.Mouse1Down then
				activateMethod = 1;
			elseif activateMethod == 1 then
				activateMethod = nil;
			end
			if activateMethod == nil and characterProperties.InteractionActive then
				activateMethod = 2;
			elseif activateMethod == 2 and not characterProperties.InteractionActive then
				activateMethod = nil;
			end

			local active = false;
			local function stop()
				toolAnimator:Stop("Use");
				toolAnimator:Stop("UseOthers");
				if trailEffect then trailEffect.Enabled = false; end
				reset();
			end
			
			if not characterProperties.CanAction then
				stop();
				return;
			end
	
			if tick()-lastScan >= 0.2 then
				lastScan = tick();
	
				local targetCharacter, targetRad;
				if characterProperties.CanAction and activateMethod ~= 1 then
					targetCharacter, targetRad = modCameraUtil.GetClosestCharacterToCamera(minRad, function(char: Model)
						local hasReviveInteractConfig = false;
                        for _, c in pairs(char:GetChildren()) do
                            if c:HasTag("Interactable") == nil or c:GetAttribute("_Name") ~= "Revive" then continue end;
                            hasReviveInteractConfig = true;
                            break;
                        end
                        return not hasReviveInteractConfig;
					end);
				end
	
				if targetCharacter then
					if targetCharacter ~= prevHealingChar then
						reset();
					end
					prevHealingChar = targetCharacter;
	
					healProxyInteract.TargetCharacter = targetCharacter;
					if activateMethod then
						healProxyInteract.Label = `Healing {healProxyInteract.TargetCharacter.Name}...`;
					else
						healProxyInteract.Label = `Heal {targetCharacter.Name}`;
					end
					healProxyInteract.InteractDuration = properties.UseDuration;
					local interactPart = modInteractables.getInteractPart(targetCharacter.PrimaryPart);
					healProxyInteract.Part = interactPart or targetCharacter.PrimaryPart;
					healProxyInteract.CanInteract = true;
	
					characterProperties.ProxyInteractable = healProxyInteract;
                    isTargetDead = targetCharacter:GetAttribute("IsDead") == true;
	
				else
					healProxyInteract.Player = nil;
					healProxyInteract.CanInteract = false;
	
					characterProperties.ProxyInteractable = nil;
				end
			end
			if activateMethod == 2 and healProxyInteract.Player == nil then 
				activateMethod = nil;
			end;
			
			if activateMethod then
				if activateMethod == 1 then
					local track = toolAnimator:GetPlaying("Use");
					if track == nil then
						track = toolAnimator:Play("Use");
					end
				elseif activateMethod == 2 then
					local track = toolAnimator:GetPlaying("UseOthers");
					if track == nil then
						track = toolAnimator:Play("UseOthers");
					end
				end
				if trailEffect then trailEffect.Enabled = true; end
				
				if startUseTick == nil then
					updateProgressionBar();
					startUseTick = tick();
	
					isWounded = playerClass.StatusComp:GetOrDefault("Wounded") ~= nil;

					useStart();

					remoteToolInputHandler:FireServer(modRemotesManager.Compress{
						Siid = storageItem.ID;
						Action = "action";
						ActionIndex = 1;
					});
	
					active = true;
	
				else
					if not isWounded and playerClass.Properties.Wounded ~= nil then
						active = false;
					end
					
					local progress = 0;
					if activateMethod == 1 then
						progress = (tick()-startUseTick) / properties.UseDuration;
					elseif activateMethod == 2 then
						progress = characterProperties.InteractAlpha;
					end
					active = true;
					
					updateProgressionBar(progress);
					if progress >= 1 then
						active = false;
						reset();
						remoteToolInputHandler:FireServer(modRemotesManager.Compress{
							Siid = siid;
							Action = "action";
							ActionIndex = 2;
							TargetCharacter = localPlayer.Character;
						});
					end
				end
			end
			if not active then
				stop();
			end

		end);

		handler.Garbage:Tag(function()
			task.wait();
			if healthWindow then
				healthWindow.Properties.PreviewVisible = false;
			end
		end)
	end



elseif RunService:IsServer() then -- MARK: Server

	function toolHandler.ServerEquip(handler: ToolHandlerInstance)
		local equipmentClass: EquipmentClass = handler.EquipmentClass;
		local toolAnimator: ToolAnimator = handler.ToolAnimator;

		local toolPackage = handler.ToolPackage;

		local animations = toolPackage.Animations;
		local audio = toolPackage.Audio;

		local configurations = equipmentClass.Configurations;
		local properties = equipmentClass.Properties;

		
		--MARK: Npc equip
		if handler.CharacterClass.ClassName ~= "NpcClass" then return end;

		local npcClass: NpcClass = handler.CharacterClass :: NpcClass;
		local mainToolModel = handler.MainToolModel;

		toolAnimator:LoadAnimations(animations, toolPackage.DefaultAnimatorState, handler.Prefabs);
		toolAnimator:Play("Core");
	end

	function toolHandler.ActionEvent(handler: ToolHandlerInstance, packet)
		local byCharacterClass: CharacterClass = handler.CharacterClass;
		local byHealthComp: HealthComp = byCharacterClass.HealthComp;

		local actionIndex = packet.ActionIndex;
		
		local targetCharacter = packet.TargetCharacter or byCharacterClass.Character;
		local toHealthComp: HealthComp? = modHealthComponent.getByModel(targetCharacter);
		if toHealthComp == nil then return end;
		if byHealthComp.IsDead then return end;
	
		local toCharacterClass: CharacterClass = toHealthComp.CompOwner :: CharacterClass; 
            -- Note ActionIndex == 1, toCharacterClass defaults to byCharacterClass 

		local equipmentClass: EquipmentClass = handler.EquipmentClass;
		local configurations = equipmentClass.Configurations;
		local properties = equipmentClass.Properties;
		
		local players = {};
		if byCharacterClass.ClassName == "PlayerClass" then
			table.insert(players, (byCharacterClass :: PlayerClass):GetInstance());
		end
		if toCharacterClass.ClassName == "PlayerClass" then
			table.insert(players, (toCharacterClass :: PlayerClass):GetInstance());
		end

		local storageItem: StorageItem = handler.StorageItem;

		if actionIndex == 1 then
			properties.LastFire = tick();
			properties.UseDuration = configurations.UseDuration;

			shared.modEventService:ServerInvoke("Tools_BindHealTool", {ReplicateTo=players}, "UseStart", handler, toCharacterClass);
			
            if byCharacterClass.StatusComp:GetOrDefault("Wounded") then
				properties.UseDuration = properties.UseDuration * 2;
			end
	
		elseif actionIndex == 2 then
			local useDuration = properties.UseDuration;
	
            if toCharacterClass.HealthComp.IsDead then
				useDuration = useDuration * 3;
            end

			local lapsed = tick() - properties.LastFire;
			local inValidTimeRange = lapsed >= useDuration-0.5 and lapsed <= useDuration+0.5;
	
			if not inValidTimeRange then
				Debugger:Warn("TimeLapsed invalid", inValidTimeRange, "useDuration", useDuration, "lapsed", lapsed);
				return;
			end
			
			if storageItem and storageItem.Quantity <= 0 then Debugger:Warn("Insufficient quantity"); return end;

			properties.HealAmount = configurations.HealAmount;
			local event = shared.modEventService:ServerInvoke("Tools_BindHealTool", {ReplicateTo=players}, "UseComplete", handler, toCharacterClass);
			if event.Cancelled then return end;

			local healAmount = properties.HealAmount;

            if toHealthComp.IsDead then
                if toCharacterClass.ClassName == "PlayerClass" then
                    (toCharacterClass :: PlayerClass):Revive(byCharacterClass);

                else
                    Debugger:Warn(`Can not revive npc.`);
                    return;
                end
            end

			toHealthComp:TakeDamage(DamageData.new{
				Damage = -healAmount;
				DamageBy = byCharacterClass;

				StorageItem = storageItem;
				DamageType = "Heal";
				
				CanOverHeal = true;
			});


			if handler.StorageItem.Quantity == 1 then
				byCharacterClass.WieldComp:Unequip();
			end
		
			if byCharacterClass.ClassName == "PlayerClass" then
				local player = (byCharacterClass :: PlayerClass):GetInstance();
				local profile = shared.modProfile:Get(player);
				local inventory = profile.ActiveInventory;
				
				inventory:Remove(handler.StorageItem.ID, 1);
				local itemLib = handler.StorageItem.Library;
				shared.Notify( player, ("1 $Item removed from your Inventory."):gsub("$Item", itemLib.Name), "Negative");
			end

		end
	end

	--MARK: Server (Npc) Use
	function toolHandler.UseRequest(handler: ToolHandlerInstance)
		local wieldComp: WieldComp = handler.WieldComp;
		local characterClass: CharacterClass = handler.CharacterClass;
		local healthComp: HealthComp = characterClass.HealthComp;

		local properties = handler.EquipmentClass.Properties;
		local toolAnimator: ToolAnimator = handler.ToolAnimator;

		if properties.Active == true then return end;
		properties.Active = true;

		toolAnimator:Play("Use");

		handler.ActionEvent(handler, {
			ActionIndex = 1;
		});
		task.delay(properties.UseDuration, function()
			if wieldComp.EquipmentClass ~= handler.EquipmentClass or healthComp.IsDead then 
				properties.Active = false;
				return;
			end;

			handler.ActionEvent(handler, {
				ActionIndex = 2;
			});
			toolAnimator:Stop("Use");
			properties.Active = false;
		end);
	end

end

return toolHandler;