local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modRegion = shared.require(game.ReplicatedStorage.Library.Region);
local modCrates = shared.require(game.ReplicatedStorage.Library.Crates);
local modOctree = shared.require(game.ReplicatedStorage.Library.Util.Octree);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);

if RunService:IsServer() then
	modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);
end

local eventPackage = {
	Id = "respawnables";
	Name = "Respawnables";

	StructuresOctree = nil;

	BindRespawnStructures = nil;
	BindRespawnLoot = nil;
};

--==

function eventPackage.onRequire()
	if RunService:IsClient() then return end;
	
	shared.modCommandsLibrary.bind{
		["respawnables"] = {
			Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
			Description = [[Respawnables commands
            
            /respawnables respawnstructures 
			/respawnables respawnloot
            ]];

			RequiredArgs = 0;
			UsageInfo = "/respawnables action";
			Function = function(player, args)
				local actionId = args[1];

				if actionId == "respawnstructures" then
					eventPackage.BindRespawnStructures();

				elseif actionId == "respawnloot" then
					eventPackage.BindRespawnLoot();
				end

				return true;
			end;
		};
	};
end

function eventPackage.newInstance(eventInstance: WorldEventInstance)
	Debugger:Warn(`newInstance {eventPackage.Id}`);

	local eventMap = eventInstance.TemplateEventMap;

	local globalProperties = eventInstance.WorldEvents.GlobalProperties;

	local scheduler: Scheduler = eventInstance.Scheduler;
	local properties: PropertiesVariable<{}> = eventInstance.Properties;
	local garbageHandler: GarbageHandler = eventInstance.Garbage;
	local publicData = eventInstance.Public;

	-- MARK: Structures
	local structuresOctree = modOctree.new();
	eventPackage.StructuresOctree = structuresOctree;

	local respawnableModels = eventMap:GetChildren();
	for a=1, #respawnableModels do
		local respawnableModel: Model = respawnableModels[a];
		if not respawnableModel:IsA("Model") then continue end;

		local structureName: string = (respawnableModel:WaitForChild("PackageLink") :: PackageLink).DefaultName;
		local modelPivot: CFrame = respawnableModel:GetPivot();

		structuresOctree:CreateNode(modelPivot.Position, {
			Name = structureName;
			Pivot = modelPivot;
			IsTutorialOnly = respawnableModel:HasTag("TutorialItem");
		});
		respawnableModel:Destroy();
	end

	Debugger:Warn(`WorldRespawnables: {#structuresOctree:GetAllNodes()}`);

	local respawnablesFolder: Folder = Instance.new("Folder");
	respawnablesFolder.Name = "respawnables";
	respawnablesFolder.Parent = workspace.Environment.Game:WaitForChild("Events");

	local structuresPrefabs = game.ServerStorage.Prefabs:WaitForChild("Structures");
	local function respawnStructures()
		for _, node in pairs(structuresOctree:GetAllNodes()) do
			local structureData = node:GetObject();
			if structureData.IsTutorialOnly and globalProperties.Tutorial == false then continue end;

			if structureData.Instance then continue end;

			local newModel = structuresPrefabs:FindFirstChild(structureData.Name);
			if newModel == nil then
				Debugger:Warn("Missing template structure prefab:", structureData.Name);
				continue;
			end

			newModel = newModel:Clone();
			newModel:PivotTo(structureData.Pivot);
			newModel.Parent = respawnablesFolder;

			if structureData.IsTutorialOnly then
				newModel:AddTag("TutorialItem");
			end

			newModel.Destroying:Connect(function()
				structureData.Instance = nil;
			end)
			structureData.Instance = newModel;
		end
	end

	globalProperties.OnChanged:Connect(function(k, v)
		if k ~= "StormState" then return end;
		if v == "Idle" then
			respawnStructures();
		end
	end)
	respawnStructures();
	eventPackage.BindRespawnStructures = respawnStructures;


	--MARK: Loot
	local lootSpawnsList = {};
	local lootCounter = 0;

	local function spawnLoot()
		local lootCrates = CollectionService:GetTagged("LootCrates");
		local lootSpawnAttList = CollectionService:GetTagged("LootSpawn");

		if #lootSpawnAttList < 0 then 
			Debugger:Warn("No loot spawns."); 
			return; 
		end;
		
		local playersList = game.Players:GetPlayers();
		local numOfPlayers = math.max(#playersList, 1);

		for a=#lootCrates, numOfPlayers*4 do
			local rewards = modCrates.GenerateRewards("envlootcrate");
			if #rewards <= 0 then continue end;

			local curTick = tick();

			-- Pick Spawn
			local pickedSpawnAtt;
			repeat
				if #lootSpawnAttList <= 0 then break; end;

				local spawnAtt = table.remove(lootSpawnAttList, math.random(1, #lootSpawnAttList));
				if spawnAtt == nil then break; end;

				if not workspace:IsAncestorOf(spawnAtt) then continue; end

				local loadSpawnMetaData = lootSpawnsList[spawnAtt];
				if loadSpawnMetaData and loadSpawnMetaData.SpawnCooldown > curTick then continue end;
				if loadSpawnMetaData and loadSpawnMetaData.LootCrate then continue end;

				lootSpawnsList[spawnAtt] = {
					SpawnCooldown = curTick + 60;
					LootCrate = nil;
				};

				pickedSpawnAtt = spawnAtt;
				
				break;
			until not true;
			if pickedSpawnAtt == nil then continue end;

			local crateModel: Model;
			local interactable: InteractableInstance;
			local storage: Storage;

			crateModel, interactable, storage = modCrates.create("envlootcrate", 
				pickedSpawnAtt.WorldCFrame * CFrame.Angles(0, math.rad(180), 0)
			);

			storage.Cache.EnvLootCrate = true;

			for b=1, #rewards do
				local item = rewards[b];
				local itemId = item.ItemId;
				local quantity = 1;

				if type(item.Quantity) == "table" then
					quantity = math.random(item.Quantity.Min, item.Quantity.Max);
				elseif item.Quantity then
					quantity = item.Quantity;
				end

				storage:Add(itemId, {Quantity=quantity;});
			end
			
			local isLooted = false;
			local isEmpty = false;
			local isDestroying = false;

			--MARK: Destructible
			local destructibleConfig: Configuration = modDestructibles.createDestructible();
			destructibleConfig.Parent = crateModel;
			local destructible: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);
			destructible.HealthComp:SetMaxHealth(200);
			destructible.HealthComp:SetHealth(200);

			destructible.OnDestroy:Connect(function()
				storage:Destroy();
				storage:Loop(function(storageItem: StorageItem)
					modItemDrops.spawn{
						ItemId = storageItem.ItemId;
						StorageItem = storageItem;
						SpawnCFrame = (pickedSpawnAtt.WorldCFrame + Vector3.new(0, 1, 0));
						DespawnDuration = false;
					};
				end);
			end)

			local parentDestructibleModule = pickedSpawnAtt.Parent and pickedSpawnAtt.Parent.Parent and pickedSpawnAtt.Parent.Parent:FindFirstChild("Destructible");
			if parentDestructibleModule then
				local parDestructible: DestructibleInstance = modDestructibles.getOrNew(parentDestructibleModule);
				parDestructible.OnDestroy:Connect(function()
					destructible.HealthComp:SetIsDead(true);
				end)
			end
			--==

			storage.OnChanged:Connect(function()
				local storeItemCount = storage:Loop();
				if storeItemCount <= 0 then
					isEmpty = true;
				end

				if isEmpty and not isDestroying then
					isDestroying = true;
					task.delay(2, function()
						destructible.HealthComp:SetIsDead(true);
					end)

				elseif #rewards > storeItemCount and not isLooted then
					isLooted = true;
					
					task.delay(30, function()
						if isDestroying then return end;
						destructible.HealthComp:SetIsDead(true);
					end)
				end
			end)
			
			lootSpawnsList[pickedSpawnAtt].LootCrate = crateModel;
			crateModel.Destroying:Connect(function()
				lootSpawnsList[pickedSpawnAtt].LootCrate = nil;
			end)

			lootCounter = lootCounter + 1;
			crateModel.Name = `loot$n{lootCounter}`

			CollectionService:AddTag(crateModel, "LootCrates");
		end
	end

	local function respawnLoot()
		if globalProperties.StormState == "Idle" then
			spawnLoot();
		end
		scheduler:ScheduleFunction(respawnLoot, tick()+10);
	end
	respawnLoot();
	eventPackage.BindRespawnLoot = spawnLoot;

    CollectionService:GetInstanceRemovedSignal("LootSpawn"):Connect(function(att)
        lootSpawnsList[att] = nil;
    end);

end


return eventPackage;